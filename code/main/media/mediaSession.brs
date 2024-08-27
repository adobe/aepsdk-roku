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

function _adb_MediaSession(clientSessionId as string, configurationModule as object, sessionConfig as object, edgeModule as object) as object
    sessionObj = {
        _clientSessionId: invalid,

        ' session level configuration
        _sessionChannelName: invalid,
        _sessionAdPingInterval: invalid,
        _sessionMainPingInterval: invalid,

        ' external dependencies
        _configurationModule: invalid,
        _edgeRequestQueue: invalid,

        _isActive: true,

        _backendSessionId: invalid,
        _hitQueue: [],

        _idleStartTS: invalid,
        _isIdle: false,
        _isPlaying: false,
        _isInAd: false,
        _lastHit: invalid, ''' to track last event, ts, playhead, etc.
        _sessionStartHit: invalid, ''' used for idle restart and long session restart

        _MEDIA_PATH_PREFIX: "/va/v1/",
        _SESSION_IDLE_THRESHOLD_SEC: 30 * 60, ' 30 minutes in pause state
        _LONG_SESSION_THRESHOLD_SEC: 24 * 60 * 60, ' 24 hours

        _DEFAULT_PING_INTERVAL_SEC: 10, ' 10 seconds
        _MIN_MAIN_PING_INTERVAL_SEC: 10, ' 10 seconds
        _MAX_MAIN_PING_INTERVAL_SEC: 50, ' 50 seconds
        _MIN_AD_PING_INTERVAL_SEC: 1, ' 1 second
        _MAX_AD_PING_INTERVAL_SEC: 10, ' 10 seconds

        _MEDIA_EVENT_TYPE: _adb_InternalConstants().MEDIA.EVENT_TYPE,
        _PUBLIC_CONSTANTS: AdobeAEPSDKConstants()

        _RESPONSE_CODE_200: 200
        _RESPONSE_CODE_300: 300
        _ERROR_CODE_400: 400
        _ERROR_TYPE_VA_EDGE_400: "https://ns.adobe.com/aep/errors/va-edge-0400-400"
        _HANDLE_TYPE_SESSION_START: "media-analytics:new-session"

        _init: sub(clientSessionId as string, configurationModule as object, sessionConfig as object, edgeModule as object)
            m._clientSessionId = clientSessionId
            m._configurationModule = configurationModule
            m._edgeModule = edgeModule

            m._extractSessionConfiguration(sessionConfig)
        end sub,

        _extractSessionConfiguration: function(sessionConfig as object) as void
            SESSION_CONFIGURATION = AdobeAEPSDKConstants().MEDIA_SESSION_CONFIGURATION

            m._sessionChannelName = _adb_optStringFromMap(sessionConfig, SESSION_CONFIGURATION.CHANNEL)

            adInterval = _adb_optIntFromMap(sessionConfig, SESSION_CONFIGURATION.AD_PING_INTERVAL)
            mainInterval = _adb_optIntFromMap(sessionConfig, SESSION_CONFIGURATION.MAIN_PING_INTERVAL)

            if adInterval <> invalid and adInterval >= m._MIN_AD_PING_INTERVAL_SEC and adInterval <= m._MAX_AD_PING_INTERVAL_SEC then
                m._sessionAdPingInterval = adInterval
                _adb_logVerbose("MediaSession::_extractSessionConfiguration() - Setting ad ping interval as (" + FormatJson(m._sessionAdPingInterval) + ") seconds.")
            else
                m._sessionAdPingInterval = m._DEFAULT_PING_INTERVAL_SEC
                _adb_logVerbose("MediaSession::_extractSessionConfiguration() - Setting ad ping interval as default (" + FormatJson(m._DEFAULT_PING_INTERVAL_SEC) + ") seconds.")
            end if

            if mainInterval <> invalid and mainInterval >= m._MIN_MAIN_PING_INTERVAL_SEC and mainInterval <= m._MAX_MAIN_PING_INTERVAL_SEC then
                m._sessionMainPingInterval = mainInterval
                _adb_logVerbose("MediaSession::_extractSessionConfiguration() - Setting main ping interval as (" + FormatJson(m._sessionMainPingInterval) + ") seconds.")
            else
                m._sessionMainPingInterval = m._DEFAULT_PING_INTERVAL_SEC
                _adb_logVerbose("MediaSession::_extractSessionConfiguration() - Setting main ping interval as default (" + FormatJson(m._DEFAULT_PING_INTERVAL_SEC) + ") seconds.")
            end if

        end function,

        getClientsessionId: function() as string
            return m._clientSessionId
        end function,

        ''' Processes the mediaHit. Updates the playback state, ad state, idle state, etc.
        ''' Extracts the sessionStart data.
        ''' Detects and closes idle session, restarts idle session, restarts long running session.
        ''' Checks for ping interval.
        ''' Queues the mediaHit.
        process: function(mediaHit as object) as void
            if not m._isActive then
                ''' Restart if session was closed by idle timeout
                m._restartIdleSession(mediaHit)
                return
            end if

            m._updatePlaybackState(mediaHit)
            m._updateAdState(mediaHit)
            m._extractSessionStartData(mediaHit)

            m._closeIfIdle(mediaHit)
            m._restartIfLongRunningSession(mediaHit)

            ' Filter ping events which are proxy for timer
            if m._shouldQueue(mediaHit)
                m._queue(mediaHit)
            end if

        end function,

        ''' Dispatched the queued mediaHits to edgeRequestQueue
        tryDispatchMediaEvents: function() as void
            ' Process the queue and send the hits to edgeWorker
            while m._hitQueue.Count() <> 0
                hit = m._hitQueue.Shift()

                requestId = hit.requestId
                tsInMillis = hit.tsObject.tsInMillis
                eventData = hit.xdmData
                eventType = hit.eventType

                ' attach _id and timestamp in ISO format
                eventData.xdm["_id"] = _adb_generate_UUID()
                eventData.xdm["timestamp"] = hit.tsObject.tsInISO8601

                ' attach sessionId to events other than sessionStart
                if eventType = m._MEDIA_EVENT_TYPE.SESSION_START
                    eventData = m._attachMediaConfig(eventData)
                else
                    ''' Cannot send hit of type other than sessionStart if backendSessionId is not set.
                    if m._backendSessionId = invalid then
                        _adb_logVerbose("MediaSession::tryDispatchMediaEvents() - Cannot dispatch media event, backend session ID is not set.")
                        return
                    end if

                    ' attach sessionId to events other than sessionStart
                    eventData.xdm["mediaCollection"]["sessionID"] = m._backendSessionId
                end if

                eventNameTokens = eventType.tokenize(".") ''' ex: eventType =  media.sessionStart
                path = m._MEDIA_PATH_PREFIX + eventNameTokens[1] ''' ex: eventNameTokens[1] = sessionStart
                meta = {}

                m._edgeModule.queueEdgeRequest(requestId, eventData, tsInMillis, meta, path)
            end while
        end function,

        close: function(isAbort = false as boolean) as void
            if not m._isActive then
                _adb_logWarning("MediaSession::close() - Cannot close media session, there is no active session.")
                return
            end if

            m._isActive = false

            if isAbort then
                ' Drop the hits in the queue
                m._hitQueue = []
            else
                ' Dispatch all the hits in the queue
                m.tryDispatchMediaEvents()
            end if
        end function,

        getHitQueueSize: function() as object
            return m._hitQueue.Count()
        end function,

        ''' Queues media events which will then be dispatched to edgeRequestQueue
        _queue: function(mediaHit as object) as boolean
            if not m._isActive then
                _adb_logWarning("MediaSession::handleQueueEvent() - Cannot queue media event, media session (" + FormatJson(m._clientSessionId) + " is not active.")
                return false
            end if

            ' Create and add hit to queue for actual events or heartbeat pings
            m._hitQueue.push(mediaHit)
            m._lastHit = mediaHit
            m.tryDispatchMediaEvents()
            return true
        end function,

        ''' Handle the edge responses for the media events
        processEdgeResponse: function(responseEvent as object) as void
            if _adb_isEdgeResponseEvent(responseEvent) then
                try
                    requestId = responseEvent.parentId
                    if requestId = invalid then
                        _adb_logWarning("MediaSession::processEdgeResponse() - Invalid requestId in the edge response.")
                        return
                    end if

                    ''' only handle the response for sessionStart event
                    if m._sessionStartHit = invalid or m._sessionStartHit.requestId <> requestId
                        return
                    end if

                    eventData = responseEvent.data
                    if _adb_isEmptyOrInvalidMap(eventData) then
                        _adb_logWarning("MediaSession::processEdgeResponse() - Invalid eventData in the edge response.")
                        return
                    end if

                    responseCode = eventData.code
                    responseString = eventData.message

                    ''' Use constants
                    if responseCode >= m._RESPONSE_CODE_200 and responseCode < m._RESPONSE_CODE_300
                        responseObj = ParseJson(responseString)

                        ''' process the response handles
                        if not _adb_isEmptyOrInvalidArray(responseObj.handle) then
                            m._processEdgeResponseHandles(responseObj.handle)
                        end if

                        ''' process the error responses
                        if not _adb_isEmptyOrInvalidArray(responseObj.errors) then
                            m._processEdgeResponseErrors(responseObj.errors)
                        end if
                    else
                        ''' Should execute this code when there is a non-recoverable error for sessionStart request
                        ''' Abort the session
                        m.close(true)
                        _adb_logWarning("MediaSession::processEdgeResponse() - SessionStart request failed with unrecoverable error.")
                        return
                    end if
                catch exception
                    _adb_logError("MediaSession::processEdgeResponse() - Failed to process the edge media response, the exception message: " + exception.Message)
                end try
            end if
        end function

        _processEdgeResponseHandles: function(handleList as object) as void
            for each handle in handleList
                if _adb_stringEqualsIgnoreCase(handle.type, m._HANDLE_TYPE_SESSION_START)
                    payloadSessionId = handle.payload[0]["sessionId"]

                    if _adb_isEmptyOrInvalidString(payloadSessionId)
                        m.close(true)
                        _adb_logWarning("MediaSession::_processEdgeResponseHandles() - SessionStart request returned with empty or invalid sessionID.")
                        return
                    end if

                    ''' set the backendSessionId
                    m._backendSessionId = payloadSessionId
                    ''' dispatch queued events.
                    _adb_logVerbose("MediaSession::_processEdgeResponseHandles() - Dispatching queued hits as the SessionStart request returned with valid sessionID.")
                    m.tryDispatchMediaEvents()
                    ''' Exit since dont need to handle any other handle types
                    exit for
                end if
            end for
        end function

        _processEdgeResponseErrors: function(errorList as object) as void
            for each error in errorList
                if _adb_stringEqualsIgnoreCase(error.type, m._ERROR_TYPE_VA_EDGE_400)
                    ''' abort the session if sessionStart fails
                    m.close(true)
                    _adb_logError("MediaSession::_processEdgeResponseErrors() - Closing the session as the SessionStart request failed.")
                    ''' Exit since dont need to handle any other error types
                    exit for
                end if
            end for
        end function

        _shouldQueue: function(mediaHit as object) as boolean
            eventType = mediaHit.eventType

            ''' Should queue any event other than ping.
            if eventType <> m._MEDIA_EVENT_TYPE.PING or m._lastHit = invalid then
                return true
            end if

            pingInterval = m._getPingInterval(m._isInAd)

            ''' Should queue ping event if the duration between the last event and this ping event is greater than ping interval
            ''' If the duration is less than ping interval, then ignore the ping event
            currentHitTS = mediaHit.tsObject.tsInMillis
            lastHitTS = m._lastHit.tsObject.tsInMillis

            ''' Dispatch if ping interval has elapsed since last event was sent
            if (currentHitTS - lastHitTS) >= (pingInterval * 1000) then
                return true
            end if

            return false
        end function,

        _extractSessionStartData: function(mediaHit as object) as void
            if not _adb_stringEqualsIgnoreCase(mediaHit.eventType, m._MEDIA_EVENT_TYPE.SESSION_START)
                return
            end if

            m._sessionStartHit = mediaHit
        end function,

        ''' Called for sessionStart hit only
        _attachMediaConfig: function(xdmData as object) as object
            playerName = m._getPlayerName()
            channel = m._getChannelName()
            appVersion = m._getAppVersion()

            if not _adb_isEmptyOrInvalidString(playerName)
                xdmData.xdm["mediaCollection"]["sessionDetails"]["playerName"] = playerName
            end if

            if not _adb_isEmptyOrInvalidString(channel)
                xdmData.xdm["mediaCollection"]["sessionDetails"]["channel"] = channel
            end if

            if not _adb_isEmptyOrInvalidString(appVersion) then
                xdmData.xdm["mediaCollection"]["sessionDetails"]["appVersion"] = appVersion
            end if

            return xdmData
        end function,

        _updateAdState: function(mediaHit as object) as boolean
            eventType = mediaHit.eventType
            if eventType = m._MEDIA_EVENT_TYPE.AD_START
                m._isInAd = true

            else if eventType = m._MEDIA_EVENT_TYPE.AD_COMPLETE or eventType = m._MEDIA_EVENT_TYPE.AD_SKIP
                m._isInAd = false
            end if
        end function,

        _updatePlaybackState: function(mediaHit as object) as void
            eventType = mediaHit.eventType

            if eventType = m._MEDIA_EVENT_TYPE.PLAY
                m._isPlaying = true
                m._idleStartTS = invalid
            else if eventType = m._MEDIA_EVENT_TYPE.PAUSE_START or eventType = m._MEDIA_EVENT_TYPE.BUFFER_START
                m._isPlaying = false

                ''' Set the idle start timestamp if not set already
                if m._idleStartTS = invalid then
                    m._idleStartTS = mediaHit.tsObject.tsInMillis
                end if
            end if
        end function,

        _closeIfIdle: function(mediaHit as object) as void
            ' Check if the session is idle for >= 30 minutes
            if m._isPlaying or m._idleStartTS = invalid or m._isIdle then
                return
            end if

            idleTime = mediaHit.tsObject.tsInMillis - m._idleStartTS
            if idleTime >= m._SESSION_IDLE_THRESHOLD_SEC * 1000 then
                ''' Abort the Idle session
                m._isIdle = true
                m.process(m._createSessionEndHit(mediaHit))

                ''' set the session inactive
                m.close(true)
            end if
        end function,

        _restartIdleSession: function(mediaHit as object) as void
            eventType = mediaHit.eventType

            if m._isIdle and not m._isActive and eventType = m._MEDIA_EVENT_TYPE.PLAY
                m._resetForRestart()
                m.process(m._createSessionResumeHit(mediaHit))
                m.process(mediaHit)
            end if
        end function,

        _restartIfLongRunningSession: function(mediaHit as object) as void
            ''' Don't check for long running session if sessionStartHit is not set
            ''' Or if the event is sessionEnd, sessionComplete
            if m._sessionStartHit = invalid or mediaHit.eventType = m._MEDIA_EVENT_TYPE.SESSION_END or mediaHit.eventType = m._MEDIA_EVENT_TYPE.SESSION_COMPLETE then
                return
            end if

            sessionStartTS = m._sessionStartHit.tsObject.tsInMillis
            currentTS = mediaHit.tsObject.tsInMillis

            if currentTS - sessionStartTS >= m._LONG_SESSION_THRESHOLD_SEC * 1000 then
                ''' Abort the long running session
                '''m.process(sessionEnd)
                sessionEndHit = m._createSessionEndHit(mediaHit)
                m.process(sessionEndHit)

                m._resetForRestart()

                sessionStart = m._createSessionResumeHit(mediaHit)
                m.process(sessionStart)
                ''' the triggering hit will be processed after this returns
                ''' if the triggering hit is ping, it maybe dropped if the ping interval has not elapsed
                return
            end if
            ' Check if the session is long running >= 24 hours
        end function,

        _resetForRestart: function() as void
            m._lastHit = invalid
            m._idleStartTS = invalid
            m._backendSessionId = invalid
            m._isIdle = false
            m._isActive = true
        end function,

        _createSessionResumeHit: function(mediaHit as object) as object
            ''' Create deepcopy of sessionStartHit
            sessionResumeHit = parseJSON(formatJSON(m._sessionStartHit))

            sessionResumeHit.xdmData.xdm["mediaCollection"]["sessionDetails"]["hasResume"] = true
            sessionResumeHit.xdmData.xdm["mediaCollection"]["playhead"] = mediaHit.xdmData.xdm["mediaCollection"]["playhead"]
            sessionResumeHit.xdmData.xdm["timestamp"] = mediaHit.tsObject.tsInISO8601
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
                    },
                    "timestamp": mediaHit.tsObject.tsInISO8601
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
                return m._sessionAdPingInterval
            else
                return m._sessionMainPingInterval
            end if
        end function,

        _getAppVersion: function() as dynamic
            return m._configurationModule.getMediaAppVersion()
        end function,

        _getPlayerName: function() as dynamic
            return m._configurationModule.getMediaPlayerName()
        end function,

        _getChannelName: function() as dynamic
            if m._sessionChannelName <> invalid
                return m._sessionChannelName
            else
                return m._configurationModule.getMediaChannel()
            end if
        end function,
    }
    sessionObj._init(clientSessionId, configurationModule, sessionConfig, edgeModule)
    return sessionObj
end function
