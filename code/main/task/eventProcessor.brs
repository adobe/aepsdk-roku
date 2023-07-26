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

' ******************************** MODULE: EventProcessor *********************************

function _adb_EventProcessor(task as object) as object
    eventProcessor = {
        _CONSTANTS: _adb_InternalConstants(),
        _task: task,
        _configurationModule: invalid,
        _identityModule: invalid,
        _edgeModule: invalid,

        init: function() as void
            m._configurationModule = _adb_ConfigurationModule()
            m._identityModule = _adb_IdentityModule(m._configurationModule)
            m._edgeModule = _adb_EdgeModule(m._configurationModule, m._identityModule)

            ' enable debug mode if needed
            if m._isInDebugMode()
                networkService = _adb_serviceProvider().networkService
                networkService._debugMode = true
            end if
        end function,

        handleEvent: function(event as dynamic) as void

            if _adb_isRequestEvent(event)
                _adb_logInfo("handleEvent() - handle event: " + FormatJson(event))

                try
                    m._processAdbRequestEvent(event)
                catch ex
                    _adb_logError("handleEvent() - Failed to process the request event, the exception message: " + ex.Message)
                end try

                if m._isInDebugMode()
                    m._dumpDebugInfo(event, _adb_serviceProvider().loggingService, _adb_serviceProvider().networkService)
                end if

            else
                _adb_logWarning("handleEvent() - event is invalid: " + FormatJson(event))
            end if
        end function,

        _isInDebugMode: function() as boolean
            if m._task <> invalid and m._task.hasField("debugInfo")
                return true
            end if
            return false
        end function,

        _dumpDebugInfo: function(event as object, loggingService as object, networkService as object) as void
            debugInfo = {
                eventId: event.uuid,
                apiName: event.apiName
            }

            debugInfo.logLevel = loggingService.getLogLevel()
            debugInfo["configuration"] = m._configurationModule.dump()
            debugInfo["identity"] = m._identityModule.dump()
            debugInfo["edge"] = m._edgeModule.dump()
            debugInfo["networkRequests"] = networkService.dump()

            m._task.setField("debugInfo", debugInfo)
        end function,

        _processAdbRequestEvent: function(event) as void
            if event.apiName = m._CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT
                m._sendEvent(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_CONFIGURATION
                m._setConfiguration(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_LOG_LEVEL
                m._setLogLevel(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID
                m._setECID(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.RESET_IDENTITIES
                m._resetIdentities(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.RESET_SDK
                m._resetSDK(event)
            else
                _adb_logWarning("handleEvent() - event is invalid: " + FormatJson(event))
            end if
        end function,

        _setLogLevel: function(event as object) as void
            logLevel = _adb_optIntFromMap(event.data, m._CONSTANTS.EVENT_DATA_KEY.LOG.LEVEL)
            if logLevel <> invalid
                loggingService = _adb_serviceProvider().loggingService
                loggingService.setLogLevel(logLevel)
                _adb_logInfo("_setLogLevel() - set log level: " + FormatJson(logLevel))
            else
                _adb_logWarning("_setLogLevel() - log level is not found in event data")
            end if
        end function,

        _resetIdentities: function(_event as object) as void
            _adb_logInfo("_resetIdentities() - Reset presisted Identities.")
            m._identityModule.resetIdentities()
        end function,

        _resetSDK: function(_event as object) as void
            _adb_logInfo("_resetSDK() - Reset SDK.")
            m.init()
        end function,

        _setConfiguration: function(event as object) as void
            _adb_logInfo("_setConfiguration() - set configuration")
            _adb_logVerbose("configuration before: " + FormatJson(m._configurationModule.dump()))
            m._configurationModule.updateConfiguration(event.data)
            _adb_logVerbose("configuration after: " + FormatJson(m._configurationModule.dump()))
        end function,

        _setECID: function(event as object) as void
            _adb_logInfo("_setECID() - Handle setECID.")

            ecid = _adb_optStringFromMap(event.data, m._CONSTANTS.EVENT_DATA_KEY.ECID)
            if ecid <> invalid
                m._identityModule.updateECID(ecid)
            else
                _adb_logWarning("_setECID() - ECID not found in event data.")
            end if
        end function,

        _hasXDMData: function(event as object) as boolean
            if event <> invalid and event.DoesExist("data") and event.data.DoesExist("xdm") and event.data.xdm.Count() > 0 then
                return true
            end if

            return false
        end function,

        _sendEvent: function(event as object) as void
            _adb_logInfo("_sendEvent() - Try sending event with uuid:(" + FormatJson(event.uuid) + ").")

            if not m._hasXDMData(event)
                _adb_logError("_sendEvent() - Not sending event, XDM data is empty.")
                return
            end if

            requestId = event.uuid
            xdmData = event.data
            timestampInMillis = event.timestampInMillis
            responseEvents = m._edgeModule.processEvent(requestId, xdmData, timestampInMillis)

            for each responseEvent in responseEvents
                m._sendResponseEvent(responseEvent)
            end for

        end function,

        processQueuedRequests: function() as void
            responseEvents = m._edgeModule.processQueuedRequests()
            m._sendResponseEvents(responseEvents)
        end function

        _sendResponseEvent: function(event as object) as void
            _adb_logInfo("_sendResponseEvent() - Send response event: (" + FormatJson(event) + ").")

            if m._task = invalid
                _adb_logError("_sendResponseEvent() - Cannot send response event, task node instance is invalid.")
                return
            end if

            if _adb_isResponseEvent(event)
                m._task[m._CONSTANTS.TASK.RESPONSE_EVENT] = event
            else
                _adb_logError("_sendResponseEvent() - the given event is invalid.")
            end if
        end function,

        _sendResponseEvents: function(responseEvents as dynamic) as void
            if not _adb_isArray(responseEvents)
                _adb_logError("_sendResponseEvents() - responseEvents is not an array.")
                return
            end if
            for each event in responseEvents
                m._sendResponseEvent(event)
            end for
        end function,
    }

    eventProcessor.init()

    return eventProcessor
end function