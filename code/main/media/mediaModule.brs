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

function _adb_MediaModule(configurationModule as object, identityModule as object) as object
    if _adb_isConfigurationModule(configurationModule) = false then
        _adb_logError("_adb_MediaModule() - configurationModule is not valid.")
        return invalid
    end if

    if _adb_isIdentityModule(identityModule) = false then
        _adb_logError("_adb_EdgeModule() - identityModule is not valid.")
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.media")

    module.Append({
        ' constants
        _CONSTANTS: _adb_InternalConstants(),

        ' external dependencies
        _configurationModule: configurationModule,
        _identityModule: identityModule,
        _edgeRequestWorker: _adb_EdgeRequestWorker(),
        _sessionManager: _adb_MediaSessionManager(),

        ' Event data example:
        ' {
        '     clientSessionId: "xx-xxxx-xxxx",
        '     timestampInISO8601: "2019-01-01T00:00:00.000Z",
        '     xdmData: { xdm: {} }
        '     configuration: { }
        ' }
        processEvent: sub(requestId as string, eventData as object, timestampInMillis as longinteger)
            mediaEventType = eventData.xdmData.xdm.eventType
            clientSessionId = eventData.clientSessionId
            timestampInISO8601 = eventData.timestampInISO8601

            if mediaEventType = m._CONSTANTS.MEDIA.SESSION_START_EVENT_TYPE then
                m._sessionStart(clientSessionId, eventData, timestampInISO8601, timestampInMillis)
            else
                m._actionInSession(requestId, clientSessionId, eventData, timestampInISO8601, timestampInMillis)
            end if
        end sub,

        _mediaConfigIsNotReady: function() as boolean
            ' appVersion is optional for sessionStart request
            return _adb_isEmptyOrInvalidString(m._configurationModule.getMediaChannel()) or _adb_isEmptyOrInvalidString(m._identityModule.getMediaPlayerName())
        end function,

        _sessionStart: sub(clientSessionId as string, eventData as object, timestampInISO8601 as string, timestampInMillis as longinteger)

            sessionConfig = eventData.configuration
            ' TODO: the session-level config should be merged with the global config, before the validation

            if m._mediaConfigIsNotReady() then
                _adb_logError("_sessionStart() - the media session is not created/started properly (missing the channel name or the player name).")
                return
            end if

            m._sessionManager.createNewSession(clientSessionId)
            ' TODO: add session-level config to the sessionManager
            ' m._sessionManager.createNewSession(sessionConfig,sessionConfig["config.mainpinginterval"],sessionConfig["config.adpinginterval"])

            xdmData = eventData.xdmData
            appVersion = m._identityModule.getMediaAppVersion()
            xdmData.xdm["_id"] = _adb_generate_UUID()
            xdmData.xdm["timestamp"] = timestampInISO8601
            xdmData.xdm["mediaCollection"]["sessionDetails"]["playerName"] = m._identityModule.getMediaPlayerName()
            xdmData.xdm["mediaCollection"]["sessionDetails"]["channel"] = m._configurationModule.getMediaChannel()
            if not _adb_isEmptyOrInvalidString(appVersion) then
                xdmData.xdm["mediaCollection"]["sessionDetails"]["appVersion"] = appVersion
            end if

            meta = {}
            ' TODO: sanitize the xdmData object before sending to the backend.

            ' For sessionStart request, the clientSessionId is used as the request id, then it can be used to retrieve the corresponding response data.
            m._edgeRequestWorker.queue(clientSessionId, xdmData, timestampInMillis, meta, m._CONSTANTS.MEDIA.SESSION_START_EDGE_REQUEST_PATH)
            m._kickRequestQueue()
        end sub,

        _actionInSession: sub(requestId as string, clientSessionId as string, eventData as object, timestampInISO8601 as string, timestampInMillis as longinteger)
            if not m._sessionManager.isSessionStarted(clientSessionId)
                ' If the client session id is not found, it means the sessionStart is not called/processed correctly.
                _adb_logError("_actionInSession() - the corresponding session is not started properly. This media event will be dropped.")
                return
            end if

            ' TODO: clean the previsou session info stroed in the session manager

            mediaEventType = eventData.xdmData.xdm.eventType

            if mediaEventType = m._CONSTANTS.MEDIA.SESSION_END_EVENT_TYPE
                m._sessionManager.deleteSession(clientSessionId)
            end if

            ' retrieve the session id and the location hint returned from the backend
            sessionId = m._sessionManager.getSessionId(clientSessionId)
            location = m._sessionManager.getLocation(clientSessionId)

            if _adb_isEmptyOrInvalidString(sessionId)
                m._sessionManager.queueMediaRequest(requestId, clientSessionId, eventData, timestampInISO8601, timestampInMillis)
                ' The sessionStart request may get a recoverable error, retry it.
                m._kickRequestQueue()
                return
            else
                path = _adb_EdgePathForEventType(mediaEventType, location, m._CONSTANTS.MEDIA.EVENT_TYPES)
                if not _adb_isEmptyOrInvalidString(path)
                    xdmData = eventData.xdmData
                    xdmData.xdm["_id"] = _adb_generate_UUID()
                    xdmData.xdm["timestamp"] = timestampInISO8601
                    xdmData.xdm["mediaCollection"]["sessionID"] = sessionId

                    meta = {}
                    ' TODO: sanitize the xdmData object before sending to the backend.
                    m._edgeRequestWorker.queue(requestId, xdmData, timestampInMillis, meta, path)
                    m._processQueuedRequests()
                else
                    _adb_logError("_actionInSession() - mediaEventName is invalid: " + mediaEventType)
                end if

            end if
        end sub,

        _kickRequestQueue: sub()
            responses = m._processQueuedRequests()
            ' the responses may include sessionStart response and media event response
            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) then
                    responseJson = edgeResponse.getresponsestring()
                    responseObj = ParseJson(responseJson)
                    requestId = responseObj.requestId
                    sessionId = ""
                    location = ""
                    ' udpate session id and location hint
                    for each handle in responseObj.handle
                        if handle.type = "media-analytics:new-session"
                            sessionId = handle.payload[0]["sessionId"]
                        else if handle.type = "locationHint:result"
                            for each payload in handle.payload
                                if payload["scope"] = "EdgeNetwork"
                                    location = payload["hint"]
                                end if
                            end for
                        end if
                    end for
                    ' if the session id is not empty, update the session id and process the queued requests
                    ' the location hint is optional, if it is empty, it will be ignored
                    if not _adb_isEmptyOrInvalidString(sessionId)
                        queuedMediaRequests = m._sessionManager.updateSessionIdAndGetQueuedRequests(requestId, sessionId, location)
                        for each mediaRequest in queuedMediaRequests
                            mediaEventType = mediaRequest.eventData.xdmData.xdm.eventType

                            meta = {}
                            path = _adb_EdgePathForEventType(mediaEventType, location, m._CONSTANTS.MEDIA.EVENT_TYPES)

                            if not _adb_isEmptyOrInvalidString(path)
                                xdmData = mediaRequest.eventData.xdmData
                                xdmData.xdm["_id"] = _adb_generate_UUID()
                                xdmData.xdm["timestamp"] = mediaRequest.timestampInISO8601
                                xdmData.xdm["mediaCollection"]["sessionID"] = sessionId

                                ' TODO: sanitize the xdmData object before sending to the backend.
                                m._edgeRequestWorker.queue(mediaRequest.requestId, xdmData, mediaRequest.timestampInMillis, meta, path)
                            else
                                _adb_logError("_actionInSession() - mediaEventName is invalid: " + mediaEventType)
                            end if
                        end for
                        m._kickRequestQueue()
                    end if
                end if
            end for
        end sub,

        _getEdgeConfig: function() as object
            configId = m._configurationModule.getConfigId()
            if _adb_isEmptyOrInvalidString(configId)
                return invalid
            end if
            ecid = m._identityModule.getECID()
            if _adb_isEmptyOrInvalidString(ecid)
                return invalid
            end if
            return {
                configId: configId,
                ecid: ecid,
                edgeDomain: m._configurationModule.getEdgeDomain()
            }
        end function,

        _processQueuedRequests: function() as dynamic
            responseEvents = []

            if not m._edgeRequestWorker.hasQueuedEvent()
                ' no requests to process
                return responseEvents
            end if

            edgeConfig = m._getEdgeConfig()
            if edgeConfig = invalid
                _adb_logVerbose("_processQueuedRequests() - Cannot send network request, invalid configuration.")
                return responseEvents
            end if

            responses = m._edgeRequestWorker.processRequests(edgeConfig.configId, edgeConfig.ecid, edgeConfig.edgeDomain)

            return responses
        end function,

        dump: function() as object
            return {
                requestQueue: m._edgeRequestWorker._queue
            }
        end function
    })
    return module
end function

function _adb_EdgePathForEventType(mediaEventType as string, location as string, supportedTypes as object) as dynamic

    if _adb_isStringInArray(mediaEventType, supportedTypes) then
        if _adb_isEmptyOrInvalidString(location) then
            return "/ee/va/v1/" + mediaEventType
        else
            return "/ee/" + location + "/va/v1/" + mediaEventType
        end if

    else
        _adb_logError("_adb_EdgePathForEventType(): unsupported event type - " + mediaEventType)
        return invalid
    end if

end function