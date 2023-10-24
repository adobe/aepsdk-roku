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
        ' costants
        _MEDIA_EVENT_TYPES: ["play", "ping", "bitrateChange", "bufferStart", "pauseStart", "adBreakStart", "adStart", "adComplete", "adSkip", "adBreakComplete", "chapterStart", "chapterComplete", "chapterSkip", "error", "sessionEnd", "sessionComplete", "statesUpdate"],
        _SESSION_START_EVENT_TYPE: "media.sessionStart",
        _SESSION_START_EDGE_REQUEST_PATH: "/ee/va/v1/sessionStart",
        _CONSTANTS: _adb_InternalConstants(),
        ' external dependencies
        _configurationModule: configurationModule,
        _identityModule: identityModule,
        _edgeRequestWorker: _adb_EdgeRequestWorker(),
        _sessionManager: _adb_MediaSessionManager(),

        ' {
        '     clientSessionId: "xx-xxxx-xxxx",
        '     timestampInISO8601: "2019-01-01T00:00:00.000Z",
        '     param: { xdm: {} }
        ' }
        processEvent: sub(requestId as string, eventData as object, timestampInMillis as longinteger)
            mediaEventType = eventData.param.xdm.eventType
            clientSessionId = eventData.clientSessionId
            timestampInISO8601 = eventData.timestampInISO8601

            if mediaEventType = m._SESSION_START_EVENT_TYPE then
                m._sessionStart(requestId, clientSessionId, eventData, timestampInISO8601, timestampInMillis)
            else
                m._actionInSession(requestId, clientSessionId, eventData, timestampInISO8601, timestampInMillis)
            end if
        end sub,

        _sessionStart: sub(requestId as string, clientSessionId as string, eventData as object, timestampInISO8601 as string, timestampInMillis as longinteger)
            xdmData = eventData.param

            m._sessionManager.createNewSession(clientSessionId)
            meta = {}
            'https://edge.adobedc.net/ee/va/v1/sessionStart?configId=xx&requestId=xx
            mediaConfig = m._configurationModule.getMediaConfiguration()
            channel = mediaConfig["edgemedia.channel"]
            playerName = mediaConfig["edgemedia.playerName"]
            appVersion = mediaConfig["edgemedia.appVersion"]

            xdmData.xdm["_id"] = _adb_generate_UUID()
            xdmData.xdm["timestamp"] = timestampInISO8601
            xdmData.xdm["mediaCollection"]["sessionDetails"]["playerName"] = playerName
            xdmData.xdm["mediaCollection"]["sessionDetails"]["channel"] = channel
            xdmData.xdm["mediaCollection"]["sessionDetails"]["appVersion"] = appVersion
            'session start => (clientSessionId = requestId)
            m._edgeRequestWorker.queue(clientSessionId, xdmData, timestampInMillis, meta, m._SESSION_START_EDGE_REQUEST_PATH)
            m._kickRequestQueue()
        end sub,

        _actionInSession: sub(requestId as string, clientSessionId as string, eventData as object, timestampInISO8601 as string, timestampInMillis as longinteger)
            mediaEventType = eventData.param.xdm.eventType

            sessionId = m._sessionManager.getSessionId(clientSessionId)
            location = m._sessionManager.getLocation(clientSessionId)

            if _adb_isEmptyOrInvalidString(sessionId)
                m._kickRequestQueue()
                return
            else
                meta = {}
                path = _adb_EdgePathForEventType(mediaEventType, location, m._MEDIA_EVENT_TYPES)
                if _adb_isEmptyOrInvalidString(path)
                    _adb_logError("_actionInSession() - mediaEventName is invalid: " + mediaEventType)
                    return
                end if
                xdmData = eventData.param
                xdmData.xdm["_id"] = _adb_generate_UUID()
                xdmData.xdm["timestamp"] = timestampInISO8601
                xdmData.xdm["mediaCollection"]["sessionID"] = sessionId

                m._edgeRequestWorker.queue(requestId, xdmData, timestampInMillis, meta, path)
                m._kickRequestQueue()
            end if
        end sub,

        _kickRequestQueue: sub()
            responses = m.processQueuedRequests()
            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) then
                    ' udpate session id if needed
                    responseJson = edgeResponse.getresponsestring()
                    responseObj = ParseJson(responseJson)
                    requestId = responseObj.requestId
                    sessionId = ""
                    location = ""
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
                    if _adb_isEmptyOrInvalidString(sessionId) or _adb_isEmptyOrInvalidString(location)
                        _adb_logError("_kickRequestQueue() - sessionId and/or location is invalid.")
                        return
                    else
                        m._sessionManager.updateSessionIdAndGetQueuedData(requestId, sessionId, location)
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

        processQueuedRequests: function() as dynamic
            responseEvents = []

            if not m._edgeRequestWorker.hasQueuedEvent()
                ''' no requests to process
                return responseEvents
            end if

            edgeConfig = m._getEdgeConfig()
            if edgeConfig = invalid
                _adb_logVerbose("processQueuedRequests() - Cannot send network request, invalid configuration.")
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
        return "/ee/" + location + "/va/v1/" + mediaEventType
    else
        print "unsupported event type"
        return invalid
    end if

end function