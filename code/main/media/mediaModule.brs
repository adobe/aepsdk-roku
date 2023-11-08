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

' *********************************** MODULE: Media ***************************************
function _adb_isMediaModule(module as object) as boolean
    return (module <> invalid and module.type = "com.adobe.module.media")
end function

function _adb_MediaModule(configurationModule as object, edgeRequestQueue as object) as object
    if _adb_isConfigurationModule(configurationModule) = false then
        _adb_logError("_adb_MediaModule() - configurationModule is not valid.")
        return invalid
    end if

    if _adb_isEdgeRequestQueue(edgeRequestQueue) = false then
        _adb_logError("_adb_MediaModule() - edgeRequestQueue is not valid.")
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.media")

    module.Append({
        ' constants
        _CONSTANTS: _adb_InternalConstants(),

        ' external dependencies
        _configurationModule: configurationModule,
        _edgeRequestQueue: edgeRequestQueue,
        _sessionManager: _adb_MediaSessionManager(),

        ' Event data example:
        ' {
        '     clientSessionId: "xx-xxxx-xxxx",
        '     tsObject: { ts_inISO8601: "2019-01-01T00:00:00.000Z", ts_inMillis: 1546300800000 },
        '     xdmData: { xdm: {} }
        '     configuration: { }
        ' }
        processEvent: sub(requestId as string, eventData as object)
            mediaEventType = eventData.xdmData.xdm.eventType
            clientSessionId = eventData.clientSessionId
            tsObject = eventData.tsObject
            xdmData = eventData.xdmData

            if mediaEventType = m._CONSTANTS.MEDIA.SESSION_START_EVENT_TYPE
                sessionConfig = eventData.configuration
                m._startSession(clientSessionId, sessionConfig, xdmData, tsObject)
                return
            end if

            if mediaEventType <> invalid and _adb_isStringInArray(mediaEventType, m._CONSTANTS.MEDIA.EVENT_TYPES)
                m._trackEventForSession(requestId, clientSessionId, xdmData, tsObject)
            else
                _adb_logError("processEvent() - media event type is invalid: " + FormatJson(mediaEventType))
            end if
        end sub,

        _isMediaConfigReady: function() as boolean
            ' appVersion is optional for sessionStart request
            if _adb_isEmptyOrInvalidString(m._configurationModule.getMediaChannel()) or _adb_isEmptyOrInvalidString(m._configurationModule.getMediaPlayerName())
                return false
            end if
            return true
        end function,

        _startSession: sub(clientSessionId as string, sessionConfig as object, xdmData as object, tsObject as object)
            ' TODO: validate and sanitize the sessionConfig
            ' TODO: the session-level config should be merged with the global config, before the validation

            if not m._isMediaConfigReady() then
                _adb_logError("_startSession() - the media session is not created/started properly (missing the channel name or the player name).")
                return
            end if

            m._sessionManager.createNewSession(clientSessionId)
            ' TODO: add session-level config to the sessionManager
            ' m._sessionManager.createNewSession(sessionConfig,sessionConfig["config.mainpinginterval"],sessionConfig["config.adpinginterval"])

            appVersion = m._configurationModule.getMediaAppVersion()
            xdmData.xdm["_id"] = _adb_generate_UUID()
            xdmData.xdm["timestamp"] = tsObject.ts_inISO8601
            xdmData.xdm["mediaCollection"]["sessionDetails"]["playerName"] = m._configurationModule.getMediaPlayerName()
            xdmData.xdm["mediaCollection"]["sessionDetails"]["channel"] = m._configurationModule.getMediaChannel()
            if not _adb_isEmptyOrInvalidString(appVersion) then
                xdmData.xdm["mediaCollection"]["sessionDetails"]["appVersion"] = appVersion
            end if

            meta = {}

            ' For sessionStart request, the clientSessionId is used as the request id, then it can be used to retrieve the corresponding response data.
            m._edgeRequestQueue.add(clientSessionId, [xdmData], tsObject.ts_inMillis, meta, m._CONSTANTS.MEDIA.SESSION_START_EDGE_REQUEST_PATH)
            m._kickRequestQueue()
        end sub,

        _trackEventForSession: sub(requestId as string, clientSessionId as string, xdmData as object, tsObject as object)
            if not m._sessionManager.isSessionStarted(clientSessionId)
                ' If the client session id is not found, it means the sessionStart is not called/processed correctly.
                ' TODO: we need to update this logic to handle the session timeout scenarios.
                _adb_logError("_trackEventForSession() - the corresponding session is not started properly. This media event will be dropped.")
                return
            end if

            mediaEventType = xdmData.xdm.eventType

            ' retrieve the session id returned from the backend
            sessionId = m._sessionManager.getSessionId(clientSessionId)

            if mediaEventType = m._CONSTANTS.MEDIA.SESSION_END_EVENT_TYPE
                m._sessionManager.deleteSession(clientSessionId)
            end if

            if _adb_isEmptyOrInvalidString(sessionId)
                m._sessionManager.queueMediaRequest(requestId, clientSessionId, xdmData, tsObject)
                ' The sessionStart request may get a recoverable error, retry it.
                m._kickRequestQueue()
                return
            else
                m._handleMediaEvent(mediaEventType, requestId, sessionId, xdmData, tsObject)

            end if
        end sub,

        _kickRequestQueue: sub()
            responses = m._edgeRequestQueue.processRequests()
            ' the responses may include sessionStart response and media event response
            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) and not _adb_isEmptyOrInvalidString(edgeResponse.getresponsestring()) then
                    try
                        responseObj = ParseJson(edgeResponse.getresponsestring())
                        requestId = responseObj.requestId
                        sessionId = ""
                        ' udpate session id
                        for each handle in responseObj.handle
                            if handle.type = "media-analytics:new-session"
                                sessionId = handle.payload[0]["sessionId"]
                            end if
                        end for
                    catch ex
                        _adb_logError("_kickRequestQueue() - Failed to process the edge media reqsponse, the exception message: " + ex.Message)
                    end try

                    ' if the session id is not empty, update the session id and process the queued requests
                    if not _adb_isEmptyOrInvalidString(sessionId)
                        queuedMediaRequests = m._sessionManager.updateSessionIdAndGetQueuedRequests(requestId, sessionId)
                        for each mediaRequest in queuedMediaRequests
                            mediaEventType = mediaRequest.xdmData.xdm.eventType
                            m._handleMediaEvent(mediaEventType, mediaRequest.requestId, sessionId, mediaRequest.xdmData, mediaRequest.tsObject)
                        end for
                        m._kickRequestQueue()
                    end if
                end if
            end for
        end sub,

        _handleMediaEvent: sub(mediaEventType as string, requestId as string, sessionId as string, xdmData as object, tsObject as object)
            path = "/ee/va/v1/" + mediaEventType
            if not _adb_isEmptyOrInvalidString(path)
                xdmData.xdm["_id"] = _adb_generate_UUID()
                xdmData.xdm["timestamp"] = tsObject.ts_inISO8601
                xdmData.xdm["mediaCollection"]["sessionID"] = sessionId

                meta = {}
                m._edgeRequestQueue.add(requestId, [xdmData], tsObject.ts_inMillis, meta, path)
                m._kickRequestQueue()
            else
                _adb_logError("_handleMediaEvent() - mediaEventName is invalid: " + mediaEventType)
            end if
        end sub,
    })
    return module
end function