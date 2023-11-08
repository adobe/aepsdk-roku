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

 function _adb_MediaSession(id as string, config as object, edgeRequestQueue as object) as object
     return {
        _id = id,
        _config: config,
        _edgeRequestQueue: edgeRequestQueue,

        _backendSessionId: invalid,
        _hitQueue: [],
        _isActive: true,
        _isIdle: false,

        _playbackState: 0, ''' 0 init, 1 play, 2 pause, 3 seek, 4 buffer (for idle tracking)

        _lastHit: invalid, ''' to track last event, ts, playhead, etc.
        _sessionStartRequestId: invalid,

        _MEDIA_PATH_PREFIX: "/ee/va/v1/",
        _SESSION_IDLE_THRESHOLD_SEC: 10 * 60, ' 30 minutes in pause state
        _LONG_SESSION_THRESHOLD_SEC: 24 * 60 * 60, ' 24 hours
        _DEFAULT_PING_INTERVAL_SEC: 10, ' 10 seconds

        handleQueueEvent: sub(requestId as string, eventType as string, xdmData as object, tsObject as object)
            if not _isActive then
                _adb_logError("handleQueueEvent() - Cannot queue media event, media session (" + FormatJson(_id) + " is not active.")
                return
            end if

            ' Check if session is idle or long running
            _isIdle()
            _isLongRunningSession()

            ' TODO Filter ping events which are proxy for timer
            if _isTimerPing(eventType, tsObject)
                return
            end if

            ' Create and add hit to queue for actual events or heartbeat pings
            mediaHit = _createMediaHit(requestId, eventType, xdmData, tsObject)
            m._hitQueue.append(mediaHit)
            m._lastHit = mediaHit
        end sub,

        _isTimerPing(eventType as string, tsObject as object) as boolean
            ' Check if the event is a timer ping
            ' If timer, just ignore the event
            ' Timer ping is (eventType = ping) and (ts - lastHit.ts < pingInterval)
        end sub,

        processQueuedEvents: sub()
            while _hitQueue.Count() <> 0
                hit = _hitQueue.Shift()
                requestId = hit.requestId
                tsInMillis = hit.tsObject.tsInMillis

                ' attach _id and timestamp in ISO format
                xdmData.xdm["_id"] = _adb_generate_UUID()
                xdmData.xdm["timestamp"] = hit.tsObject.tsInISO8601

                ' attach sessionId to events other than sessionStart
                if hit.eventType = m._CONSTANTS.MEDIA.EVENT_TYPE.SESSION_START
                    m._sessionStartRequestId = hit.requestId
                else
                    ' attach sessionId to events other than sessionStart
                    if _backendSessionId = invalid then
                        _adb_logError("processQueuedEvents() - Cannot queue media event, backend session ID is not set.")
                        return
                    end if

                    xdmData.xdm["mediaCollection"]["sessionID"] = backendSessionId
                end if


                xdm = [hit.xdmData]
                path = m._MEDIA_PATH_PREFIX + hit.eventType
                meta = {}

                m._edgeRequestQueue.add(requestId, xdm, tsInMillis, meta, path)
                m._processEdgeRequestQueue()
            end while
        end sub,

        handleSessionEnd: sub(isAbort as boolean = false)
            _isActive = false

            if isAbort then
                ' Drop the hits in the queue
                _hitQueue = []
            else
                ' Dispatch all the hits in the queue
                processQueuedEvents()
            end if
        end sub,

        getHitQueueSize: sub() as object
            ' Get the hit queue size
            return _hitQueue.Count()
        end sub,

        handleSessionUpdate: sub(backendSessionId as string)
            ' Handle backned session ID and append to all the low level media events
            _backendSessionId = backendSessionId
        end function,

        handleError: sub(requestId as string, error as object)
            ' Handle error
            ' Drop the hits and mark session inactive if error with sessionStart
        end sub,

        _createMediaHit: sub(requestId as string, eventType as string, xdmData as object, tsObject as object) as object
            mediaHit = {}
            mediaHit.requestId = requestId
            medioHit.eventType = eventType
            mediaHit.xdmData = xdmData
            mediaHit.tsObject = tsObject
            return mediaHit
        end sub,

        _processEdgeRequestQueue: sub()
            ' Process the queue and send the hits to edgeWorker
            ' EdgeRequestQueue.process and handle the responses
            responses = m._edgeRequestQueue.processRequests()
            ' the responses may include sessionStart response and media event response
            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) and not _adb_isEmptyOrInvalidString(edgeResponse.getresponsestring()) then
                    try
                        responseObj = ParseJson(edgeResponse.getresponsestring())
                        requestId = responseObj.requestId
                        ' udpate session id
                        for each handle in responseObj.handle
                            if handle.type = "media-analytics:new-session"
                                _backendSessionId = handle.payload[0]["sessionId"]
                            end if
                        end for
                    catch ex
                        _adb_logError("_kickRequestQueue() - Failed to process the edge media reqsponse, the exception message: " + ex.Message)
                    end try
                end if
                ''' TODO handle 404 error response for sessionStart
                ''' End the session and mark inactive
            end for
        end sub,

        _isIdle: sub() as boolean
            ' Check if the session is idle for >= 30 minutes
        end sub,

        _isLongRunningSession: sub() as boolean
            ' Check if the session is long running >= 24 hours
        end sub,

        _getPingInterval: sub(isAd as boolean = false) as integer
            ' Get the ping interval for the event type
            ' Calculate ping interval based on config and isAd flag
        end sub,
     }
 end function
