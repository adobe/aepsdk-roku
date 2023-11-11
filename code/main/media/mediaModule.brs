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
        '     tsObject: { tsInISO8601: "2019-01-01T00:00:00.000Z", tsInMillis: 1546300800000 },
        '     xdmData: { xdm: {} }
        '     configuration: { }
        ' }
        processEvent: sub(requestId as string, eventData as object)
            eventType = eventData.xdmData.xdm.eventType

            if not _adb_isValidMediaEvent(eventType) then
                _adb_logError("processEvent() - Cannot process media event (" + FormatJson(eventType) + "), media event type (" + FormatJson(eventType) + ") is invalid.")
                return
            end if

            if not m._hasValidConfig() then
                _adb_logError("processMediaEvents() - Cannot process media event (" + FormatJson(eventType) + "), missing required configuration.")
                return
            end if

            sessionConfig = eventData.configuration
            mediaHit = m._createMediaHit(requestId, eventType, eventData.xdmData, eventData.tsObject)

            if eventType = m._CONSTANTS.MEDIA.EVENT_TYPE.SESSION_START
                m._sessionManager.createSession(m._configurationModule, sessionConfig, m._edgeRequestQueue)
                m._sessionManager.queue(mediaHit)
            else if eventType = m._CONSTANTS.MEDIA.EVENT_TYPE.SESSION_END or eventType = m._CONSTANTS.MEDIA.EVENT_TYPE.SESSION_COMPLETE
                m._sessionManager.queue(mediaHit)
                m._sessionManager.endSession()
            else
                m._sessionManager.queue(mediaHit)
            end if

        end sub,

        _hasValidConfig: function() as boolean
            ' Check for required configuration values
            if _adb_isEmptyOrInvalidString(m._configurationModule.getMediaChannel()) or _adb_isEmptyOrInvalidString(m._configurationModule.getMediaPlayerName()) then
                return false
            end if

            return true
        end function,

        _createMediaHit: sub(requestId as string, eventType as string, xdmData as object, tsObject as object) as object
            mediaHit = {}
            mediaHit.requestId = requestId
            mediaHit.eventType = eventType
            mediaHit.xdmData = xdmData
            mediaHit.tsObject = tsObject
            return mediaHit
        end sub,
    })
    return module
end function
