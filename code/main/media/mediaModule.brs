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
                m._sessionStart(clientSessionId, sessionConfig, xdmData, tsObject)
                return
            end if

            if mediaEventType <> invalid and _adb_isStringInArray(mediaEventType, m._CONSTANTS.MEDIA.EVENT_TYPES)
                m._actionInSession(requestId, clientSessionId, xdmData, tsObject)
            else
                _adb_logError("processEvent() - media event type is invalid: " + FormatJson(mediaEventType))
            end if
        end sub,

        _mediaConfigIsNotReady: function() as boolean
            ' appVersion is optional for sessionStart request
            return _adb_isEmptyOrInvalidString(m._configurationModule.getMediaChannel()) or _adb_isEmptyOrInvalidString(m._configurationModule.getMediaPlayerName())
        end function,

        _sessionStart: sub(clientSessionId as string, sessionConfig as object, xdmData as object, tsObject as object)
            ' TODO: the session-level config should be merged with the global config, before the validation

            if m._mediaConfigIsNotReady() then
                _adb_logError("_sessionStart() - the media session is not created/started properly (missing the channel name or the player name).")
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
            ' TODO: sanitize the xdmData object before sending to the backend.

            ' For sessionStart request, the clientSessionId is used as the request id, then it can be used to retrieve the corresponding response data.
            m._edgeRequestWorker.queue(clientSessionId, [xdmData], tsObject.ts_inMillis, meta, m._CONSTANTS.MEDIA.SESSION_START_EDGE_REQUEST_PATH)
            m._kickRequestQueue()
        end sub,

        _actionInSession: sub(requestId as string, clientSessionId as string, xdmData as object, tsObject as object)
            if not m._sessionManager.isSessionStarted(clientSessionId)
                ' If the client session id is not found, it means the sessionStart is not called/processed correctly.
                ' TODO: we need to update this logic to handle the session timeout scenarios.
                _adb_logError("_actionInSession() - the corresponding session is not started properly. This media event will be dropped.")
                return
            end if

            mediaEventType = xdmData.xdm.eventType

            ' retrieve the session id and the location hint returned from the backend
            sessionId = m._sessionManager.getSessionId(clientSessionId)
            location = m._sessionManager.getLocation(clientSessionId)

            if mediaEventType = m._CONSTANTS.MEDIA.SESSION_END_EVENT_TYPE
                m._sessionManager.deleteSession(clientSessionId)
            end if

            if _adb_isEmptyOrInvalidString(sessionId)
                m._sessionManager.queueMediaRequest(requestId, clientSessionId, xdmData, tsObject)
                ' The sessionStart request may get a recoverable error, retry it.
                m._kickRequestQueue()
                return
            else
                m._handleMediaEvent(mediaEventType, requestId, sessionId, location, xdmData, tsObject)

            end if
        end sub,

        _kickRequestQueue: sub()
            responses = m._processQueuedRequests()
            ' the responses may include sessionStart response and media event response
            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) and not _adb_isEmptyOrInvalidString(edgeResponse.getresponsestring()) then
                    try
                        responseObj = ParseJson(edgeResponse.getresponsestring())
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
                    catch ex
                        _adb_logError("_kickRequestQueue() - Failed to process the edge media reqsponse, the exception message: " + ex.Message)
                    end try

                    ' if the session id is not empty, update the session id and process the queued requests
                    ' the location hint is optional, if it is empty, it will be ignored
                    if not _adb_isEmptyOrInvalidString(sessionId)
                        queuedMediaRequests = m._sessionManager.updateSessionIdAndGetQueuedRequests(requestId, sessionId, location)
                        for each mediaRequest in queuedMediaRequests
                            mediaEventType = mediaRequest.xdmData.xdm.eventType
                            m._handleMediaEvent(mediaEventType, mediaRequest.requestId, sessionId, location, mediaRequest.xdmData, mediaRequest.tsObject)
                        end for
                        m._kickRequestQueue()
                    end if
                end if
            end for
        end sub,

        _handleMediaEvent: sub(mediaEventType as string, requestId as string, sessionId as string, location as string, xdmData as object, tsObject as object)
            path = _adb_EdgePathForEventType(mediaEventType, location, m._CONSTANTS.MEDIA.EVENT_TYPES)
            if not _adb_isEmptyOrInvalidString(path)
                xdmData.xdm["_id"] = _adb_generate_UUID()
                xdmData.xdm["timestamp"] = tsObject.ts_inISO8601
                xdmData.xdm["mediaCollection"]["sessionID"] = sessionId

                meta = {}
                ' TODO: sanitize the xdmData object before sending to the backend.
                m._edgeRequestWorker.queue(requestId, [xdmData], tsObject.ts_inMillis, meta, path)
                m._kickRequestQueue()
            else
                _adb_logError("_handleMediaEvent() - mediaEventName is invalid: " + mediaEventType)
            end if
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
            ' TODO: update the dump info when adding the integration tests
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