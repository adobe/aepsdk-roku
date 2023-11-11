' ********************** Copyright 2023 Adobe. All rights reserved. **********************
 ' *
 ' * This file is licensed to you under the Apache License, Version 2.0 (the "License");
 ' * you may not use this file except in compliance with the License. You may obtain a copy
 ' * of the License at http://www.apache.org/licenses/LICENSE-2.0
 ' *
 ' * Unless required by applicable law or agreed to in writing, software distributed under
 ' * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 ' * OF ANY KIND, either express or implied. See the License for the specific language
 ' * governing permissions and limitations under the License.
 ' *
 ' *****************************************************************************************

 ' ***************************** MODULE: MediaSession *******************************

 function _adb_MediaSession(id as string, configurationModule as object, sessionConfig as object, edgeRequestQueue as object) as object
     return {
        _id: id,
        _sessionConfig: sessionConfig,
        _configurationModule: configurationModule,
        _edgeRequestQueue: edgeRequestQueue,
        _isActive: true,

        _backendSessionId: invalid,
        _hitQueue: [],

        _idleStartTS: invalid,
        _isPlaying: false,
        _isInAd: false,
        _lastHit: invalid, ''' to track last event, ts, playhead, etc.
        _sessionStartHit: invalid, ''' used for idle restart and long session restart

        _MEDIA_PATH_PREFIX: "/ee/va/v1/",
        _SESSION_IDLE_THRESHOLD_SEC: 10 * 60, ' 30 minutes in pause state
        _LONG_SESSION_THRESHOLD_SEC: 24 * 60 * 60, ' 24 hours

        _DEFAULT_PING_INTERVAL_SEC: 10, ' 10 seconds
        _MIN_MAIN_PING_INTERVAL_SEC: 10, ' 10 seconds
        _MAX_MAIN_PING_INTERVAL_SEC: 50, ' 50 seconds
        _MIN_AD_PING_INTERVAL_SEC: 1, ' 1 second
        _MAX_AD_PING_INTERVAL_SEC: 10, ' 10 seconds

        _MEDIA_EVENT_TYPE: _adb_InternalConstants().MEDIA.EVENT_TYPE,
        _PUBLIC_CONSTANTS: AdobeAEPSDKConstants()

        _SUCCESS_CODE: 200
        _ERROR_CODE_400: 400
        _ERROR_TYPE_VA_EDGE_400: "https://ns.adobe.com/aep/errors/va-edge-0400-400"
        _HANDLE_TYPE_SESSION_START: "media-analytics:new-session"

        process: function(mediaHit as object) as void
            if not m._isActive then
                ''' Restart if session was closed by idle timeout
                m._restartIdleSession(mediaHit)
                return
            end if

            m._updateAdState(mediaHit)
            m._updatePlaybackState(mediaHit)
            m._extractSessionStartData(mediaHit)

            m._closeIfIdle(mediaHit)
            m._restartIfLongRunningSession(mediaHit)

            ' TODO Filter ping events which are proxy for timer
            if not m._shouldQueue(mediaHit)
                return
            end if

        end function,

        _queue: function(mediaHit as object) as void
            if not _isActive then
                _adb_logWarning("handleQueueEvent() - Cannot queue media event, media session (" + FormatJson(_id) + " is not active.")
                return
            end if

            ' Create and add hit to queue for actual events or heartbeat pings
            m._hitQueue.append(mediaHit)
            m._lastHit = mediaHit
            m.dispatchMediaEvents()
        end function,

        tryDispatchMediaEvents: function() as void
            ' Process the queue and send the hits to edgeWorker
            while m._hitQueue.Count() <> 0
                hit = m._hitQueue.Shift()
                requestId = hit.requestId
                tsInMillis = hit.tsObject.tsInMillis
                xdmData = hit.xdmData
                eventType = hit.eventType

                ' attach _id and timestamp in ISO format
                xdmData.xdm["_id"] = _adb_generate_UUID()
                xdmData.xdm["timestamp"] = hit.tsObject.tsInISO8601

                ' attach sessionId to events other than sessionStart
                if eventType = m._MEDIA_EVENT_TYPE.SESSION_START
                    xdmData = m._attachMediaConfig(xdmData)
                    xdmData = m._updateChannelFromSessionConfig(xdmData)

                else
                    ''' Cannot send hit of type other than sessionStart if backendSessionId is not set.
                    if m._backendSessionId = invalid then
                        _adb_logError("processQueuedEvents() - Cannot queue media event, backend session ID is not set.")
                        return
                    end if

                    ' attach sessionId to events other than sessionStart
                    xdmData.xdm["mediaCollection"]["sessionID"] = m._backendSessionId
                end if


                xdm = [xdmData]
                path = m._MEDIA_PATH_PREFIX + eventType
                meta = {}

                m._edgeRequestQueue.add(requestId, xdm, tsInMillis, meta, path)
                m._processEdgeRequestQueue()
            end while
        end function,

        close: function(isAbort = false as boolean) as void
            if not m._isActive then
                _adb_logWarning("close() - Cannot close media session, there is no active session.")
                return
            end if

            _isActive = false

            if isAbort then
                ' Drop the hits in the queue
                _hitQueue = []
            else
                ' Dispatch all the hits in the queue
                m.tryDispatchMediaEvents()
            end if
        end function,

        getHitQueueSize: function() as object
            return m._hitQueue.Count()
        end function,

        handleError: function(requestId as string, error as object) as void
            ' TODO Handle error
            ' Drop the hits and mark session inactive if error with sessionStart
        end function,

        _resetForRestart: function() as void
            m._idleStartTS = invalid
            m._backendSessionId = invalid
            m._isIdle = false
            m._isActive = true
        end function,

        _updateAdState: function(mediaHit as object) as boolean
            eventType = mediaHit.eventType
            if eventType = m._MEDIA_EVENT_TYPE.AD_START
                m._isInAd = true
            else if eventType = m._MEDIA_EVENT_TYPE.AD_COMPLETE or eventType = m._MEDIA_EVENT_TYPE.AD_SKIP
                m._isInAd = false
            end if
        end function,

        _shouldQueue: function(mediaHit as object) as boolean
            pingInterval = m._getPingInterval(m._isInAd)

            eventType = mediaHit.eventType

            ''' Should queue any event other than ping.
            if eventType <> m._MEDIA_EVENT_TYPE.PING
                return true
            end if

            ''' Should queue ping event if the duration between the last event and this ping event is greater than ping interval
            ''' If the duration is less than ping interval, then ignore the ping event
            currentHitTS = mediaHit.tsObject.tsInMillis
            lastHitTS = m._lastHit.tsObject.tsInMillis

            ''' Dispatch if ping interval has elapsed since last event was sent
            if (currentHitTS - lastHitTS) < (pingInterval * 1000) then
                return true
            end if

            return false
        end function,

        _updatePlaybackState: function(mediaHit as object) as void
            eventType = mediaHit.eventType

            if eventType = m._MEDIA_EVENT_TYPE.PLAY
                m._isPlaying = true
                m._idleStartTS = invalid
            else if eventType = m._MEDIA_EVENT_TYPE.PAUSE or eventType = m._MEDIA_EVENT_TYPE.SEEK or eventType = m._MEDIA_EVENT_TYPE.BUFFER
                m._isPlaying = false

                ''' Set the idle start timestamp if not set already
                if m._idleStartTS = invalid then
                    m._idleStartTS = _adb_TimestampObject().tsInMillis
                end if
            end if
        end function,

        _extractSessionStartData: function(mediaHit as object) as void
            if mediaHit.eventType <> m._MEDIA_EVENT_TYPE.SESSION_START
                return
            end if

            m._sessionStartHit = mediaHit
        end function,

        _attachMediaConfig: function(xdmData as object) as object
            xdmData.xdm["mediaCollection"]["sessionDetails"]["playerName"] = m._configurationModule.getMediaPlayerName()
            xdmData.xdm["mediaCollection"]["sessionDetails"]["channel"] = m._configurationModule.getMediaChannel()

            appVersion = m._configurationModule.getMediaAppVersion()
            if not _adb_isEmptyOrInvalidString(appVersion) then
                xdmData.xdm["mediaCollection"]["sessionDetails"]["appVersion"] = appVersion
            end if
        end function,

        _updateChannelFromSessionConfig: function(xdmData as object) as object
            if sessionConfig =  invalid then
                return xdmData
            end if

            channel = m._sessionConfig["channel"] ''' TODO update with constant
            if not _adb_isEmptyOrInvalidString(channel) then
                xdmData.xdm["mediaCollection"]["sessionDetails"]["channel"] = channel
            end if
        end function,

        ''' TODO verify this
        _processEdgeRequestQueue: function() as void
            ' Process the queue and send the hits to edgeWorker
            ' EdgeRequestQueue.process and handle the responses
            responses = m._edgeRequestQueue.processRequests()
            ' the responses may include sessionStart response and media event response
            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) then
                    try

                        requestId = edgeResponse.requestId
                        responseCode = edgeResponse.getResponseCode()
                        responseString = edgeResponse.getResponseString()
                        responseObj = ParseJson(responseString)

                        ''' only handle the response for sessionStart event
                        if m._sessionStartHit.requestId = requestId then
                            ''' Use constants
                            if responseCode = m._SUCCESS_CODE
                                for each handle in responseObj.handle
                                    if handle.type = m._HANDLE_TYPE_SESSION_START
                                        m._backendSessionId = handle.payload[0]["sessionId"]
                                        ''' dispatch queued events.
                                        m.tryDispatchMediaEvents()
                                    end if
                                end for
                            else if responseCode = m._ERROR_CODE_400
                                for each error in responseObj.errors
                                    if error.type = m._ERROR_TYPE_VA_EDGE_400
                                        ''' abort the session if sessionStart fails
                                        m.close(true)
                                    end if
                                end for
                            end if
                        else
                            ''' TODO handle 404 error response for media event
                        end if
                    catch ex
                        _adb_logError("_kickRequestQueue() - Failed to process the edge media reqsponse, the exception message: " + ex.Message)
                    end try
                end if
            end for
        end function,

        _closeIfIdle: function(mediaHit as object) as boolean
            ' Check if the session is idle for >= 30 minutes
            if m._isPlaying or m._idleStartTS <> invalid then
                return false
            end if

            idleTime = _adb_TimestampObject().tsInMillis - m._idleStartTS
            if idleTime >= m._SESSION_IDLE_THRESHOLD_SEC * 1000 then
                ''' Abort the Idle session
                m.process(m._createSessionEndHit(mediaHit))

                ''' set the session inactive and idle
                m._isIdle = true
                m.close(true)
            end if
        end function,

        _restartIdleSession: function(mediaHit as object) as void
            eventType = mediaHit.eventType

            if m._isIdle and not m._isActive and eventType = m._MEDIA_EVENT_TYPE.PLAY
                m._resetForRestart()

                ''' TODO set resumed flag to true in sessionStart XDM
                ''' Update ts and playhead in sessionStart XDM using mediahit
                ''' Update ts and playhead in sessionStart XDM using mediahit
                ''' update requestID with new UUID string
                m.process(m._createSessionResumeHit(mediaHit))
                m.process(mediaHit)
            end if
        end function,

        _restartIfLongRunningSession: function(mediaHit as object) as void
            if m._sessionStartHit = invalid then
                return
            end if

            sessionStartTS = m._sessionStartHit.tsObject.tsInMillis
            currentTS = mediaHit.tsObject.tsInMillis

            if currentTS - sessionStartTS >= m._LONG_SESSION_THRESHOLD_SEC * 1000 then
                ''' Abort the long running session
                '''m.process(sessionEnd)
                m.process(m._createSessionEndHit(mediaHit))

                m._resetForRestart()

                m.process(m._createSessionResumeHit(mediaHit))
            end if
            ' Check if the session is long running >= 24 hours
        end function,

        _createSessionResumeHit: function(mediaHit as object) as object
            sessionResumeHit = m._sessionStartHit

            sessionResumeHit.xdmData.xdm["mediaCollection"]["sessionDetails"]["hasResume"] = true
            sessionResumeHit.xdmData.xdm["mediaCollection"]["playhead"] = mediaHit.xdmData.xdm["mediaCollection"]["playhead"]
            sessionResumeHit.tsObject = mediaHit.tsObject
            sessionResumeHit.requestId = _adb_generate_UUID()

            return sessionResumeHit
        end function,

        _createSessionEndHit: function(mediaHit as object) as object
            xdmData = {
                "xdm": {
                    "eventType": m._MEDIA_EVENT_TYPE.SESSION_END,
                    "mediaCollection": {
                        "playhead": mediaHit.xdmData.xdm["mediaCollection"]["playhead"],
                    }
                }
            }

            sessionEndHit = {
                "xdmData": xdmData,
                "tsObject": mediaHit.tsObject,
                "requestId": _adb_generate_UUID(),
                "eventType": "media.sessionEnd"
            }

            return sessionEndHit
        end function,

        _getPingInterval: function(isAd = false as boolean) as integer
            if isAd then
                interval =  m._sessionConfig[m._PUBLIC_CONSTANTS.MEDIA_SESSION_CONFIGURATION.AD_PING_INTERVAL]
                if interval = invalid then
                    interval = m._DEFAULT_PING_INTERVAL_SEC
                else if interval >= m._MIN_AD_PING_INTERVAL_SEC and interval <= m._MAX_AD_PING_INTERVAL_SEC then
                    _adb_logVerbose("getPingInterval() - Setting ad ping interval as " + interval + " seconds.")
                    return interval
                end if
            else
                interval = m._sessionConfig[m._PUBLIC_CONSTANTS.MEDIA_SESSION_CONFIGURATION.MAIN_PING_INTERVAL]
                if interval = invalid then
                    interval = m._DEFAULT_PING_INTERVAL_SEC
                else if interval >= m._MIN_MAIN_PING_INTERVAL_SEC and interval <= m._MAX_MAIN_PING_INTERVAL_SEC then
                    _adb_logVerbose("getPingInterval() - Setting main ping interval as " + interval + " seconds.")
                    return interval
                end if
            end if
        end function,
     }
 end function
