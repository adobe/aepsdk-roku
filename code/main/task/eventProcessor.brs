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
        _consentModule: invalid,
        _mediaModule: invalid,
        _modulesRegisteredForResponseEvents: invalid,
        ' TODO add _modulesRegisteredForResetIdentitiesEvent: invalid,

        init: function() as void
            m._configurationModule = _adb_ConfigurationModule()
            m._identityModule = _adb_IdentityModule(m._configurationModule)
            m._edgeModule = _adb_EdgeModule(m._configurationModule, m._identityModule)
            m._consentModule = _adb_ConsentModule(m._configurationModule)
            m._mediaModule = _adb_MediaModule(m._configurationModule, m._edgeModule)
            m._modulesRegisteredForResponseEvents = [m._consentModule, m._mediaModule]
            ' enable debug mode if needed
            if m._isInDebugMode()
                _adb_serviceProvider().networkService._debugMode = true
            end if
        end function,

        handleEvent: function(event as dynamic) as void
            if _adb_isRequestEvent(event)
                _adb_logVerbose("EventProcessor::handleEvent() - Received request event:(" + chr(10) + FormatJson(event) + chr(10) + ")")

                try
                    ' processAdbRequest processes API events and queues edge requests for specific APIs, such as sendEvent, createMediaSession, sendMediaEvent etc.
                    m._processAdbRequestEvent(event)

                    ' processQueuedRequests handles queued edge requests by sending them, processing their responses, and dispatching them to registered modules.
                    ' It exits early if the API doesn't generate edge requests or if there are no queued requests.
                    ' Alternatively, if previously unsent queued requests exist (e.g., due to missing required configuration), it sends them and dispatches the corresponding response events.
                    m.processQueuedRequests()

                catch exception
                    _adb_logError("EventProcessor::handleEvent() - Failed to process the request event, the exception message: " + exception.Message)
                end try

                m._dumpDebugInfo(event, _adb_serviceProvider().loggingService, _adb_serviceProvider().networkService)
            else
                _adb_logWarning("EventProcessor::handleEvent() - Cannot handle event, invalid event: (" + chr(10) + FormatJson(event) + chr(10) + ")")
            end if

        end function,

        processQueuedRequests: function() as void
            responseEvents = m._edgeModule.processQueuedRequests()
            m._sendResponseEvents(responseEvents)
        end function

        _processAdbRequestEvent: function(event as dynamic) as void
            if event.apiName = m._CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT
                m._sendEvent(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_CONFIGURATION
                m._setConfiguration(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_LOG_LEVEL
                m._setLogLevel(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID
                m._setECID(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.GET_EXPERIENCE_CLOUD_ID
                m._getECID(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.RESET_IDENTITIES
                m._resetIdentities(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.RESET_SDK
                m._resetSDK(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SEND_MEDIA_EVENT
                m._handleMediaEvents(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.CREATE_MEDIA_SESSION
                m._handleCreateMediaSession(event)
            else if event.apiName = m._CONSTANTS.PUBLIC_API.SET_CONSENT
               m._setConsent(event)
            else
                _adb_logWarning("EventProcessor::handleEvent() - Cannot handle event, invalid event: " + FormatJson(event))
            end if
        end function,

        _handleCreateMediaSession: function(event as object) as void
            requestId = event.uuid
            data = event.data

            ' validate the event data
            if not m._isValidEventDataForSessionStartRequest(data)
                _adb_logError("EventProcessor::_handleCreateMediaSession() - Dropping the sessionStart media event, invalid data passed: (" + chr(10) + FormatJson(event) + chr(10) + ")" )
                return
            end if

            m._mediaModule.processEvent(requestId, data)
        end function,

        _handleMediaEvents: function(event as object) as void
            requestId = event.uuid
            data = event.data

            ' validate the event data
            if not m._isValidEventDataForMediaEventRequest(data)
                _adb_logError("EventProcessor::_handleMediaEvents() - Dropping the media event, invalid data passed: (" + chr(10) + FormatJson(event) + chr(10) + ")" )
                return
            end if

            m._mediaModule.processEvent(requestId, data)
        end function,

        _setLogLevel: function(event as object) as void
            logLevel = _adb_optIntFromMap(event.data, m._CONSTANTS.EVENT_DATA_KEY.LOG.LEVEL)
            if logLevel <> invalid
                loggingService = _adb_serviceProvider().loggingService
                loggingService.setLogLevel(logLevel)
                _adb_logInfo("EventProcessor::_setLogLevel() - Setting log level to (" + FormatJson(logLevel) + ")")
            else
                _adb_logWarning("EventProcessor::_setLogLevel() - Cannot set log level, level not found in event data.")
            end if
        end function,

        _resetIdentities: function(_event as object) as void
            _adb_logInfo("EventProcessor::_resetIdentities() - Resetting persisted identities.")
            m._identityModule.resetIdentities()
            ' Add handlers to each module and call those handlers from here.
        end function,

        _resetSDK: function(_event as object) as void
            _adb_logInfo("EventProcessor::_resetSDK() - Resetting SDK.")
            m.init()
        end function,

        _setConfiguration: function(event as object) as void
            if _adb_isEmptyOrInvalidMap(event.data)
                _adb_logWarning("EventProcessor::_setConfiguration() - Cannot set configuration, valid configuration not found in event data.")
                return
            end if

            m._configurationModule.updateConfiguration(event.data)

            _adb_logVerbose("EventProcessor::_setConfiguration() - Configuration updated: " + chr(10) + FormatJson(m._configurationModule.dump()))
        end function,

        _setECID: function(event as object) as void

            ecid = _adb_optStringFromMap(event.data, m._CONSTANTS.EVENT_DATA_KEY.ECID)
            if _adb_isEmptyOrInvalidString(ecid)
                _adb_logWarning("EventProcessor::_setECID() - Cannot set ECID, not found in event data.")
            else
                _adb_logDebug("EventProcessor::_setECID() - Setting ECID to: (" + ecid + ")")
                m._identityModule.updateECID(ecid)
            end if
        end function,

        _getECID: function(event as object) as void
            ecid = m._identityModule.getECID()

            _adb_logDebug("EventProcessor::_getECID() - Dispatching getECID response event with ECID: (" + FormatJson(ecid) + ")")
            ecidResponseEvent = _adb_IdentityResponseEvent(event.uuid, ecid)

            m._sendResponseEvent(ecidResponseEvent)
        end function,

        _sendEvent: function(event as object) as void
            _adb_logInfo("EventProcessor::_sendEvent() - Try sending event with uuid:(" + FormatJson(event.uuid) + ").")

            if not m._hasXDMData(event)
                _adb_logError("EventProcessor::_sendEvent() - Not sending event, XDM data is empty.")
                return
            end if

            requestId = event.uuid
            eventData = event.data
            timestampInMillis = event.timestampInMillis

            m._edgeModule.processEvent(requestId, eventData, timestampInMillis)
        end function,

        _setConsent: function(event as object) as void
            _adb_logInfo("EventProcessor::_setConsent() - Received set consent event with uuid:(" + FormatJson(event.uuid) + ").")

            m._consentModule.processEvent(event)
        end function,

        processQueuedRequests: function() as void
            responseEvents = m._edgeModule.processQueuedRequests()
            m._sendResponseEvents(responseEvents)
        end function

        _sendResponseEvent: function(event as object) as void
            _adb_logInfo("EventProcessor::_sendResponseEvent() - Sending response event: (" + chr(10) + FormatJson(event) + chr(10) + ")")

            if _adb_isResponseEvent(event)
                ''' for public API response events, we need to set the response event in task node
                m._dispatchResponseEventToTask(event)

                ''' for modules response events, we need to call handleResponseEvent
                m._dispatchResponseEventToRegisteredModules(m._modulesRegisteredForResponseEvents, event)
            else
                _adb_logError("EventProcessor::_sendResponseEvent() - Cannot send response event, invalid event:(" + chr(10) + FormatJson(event) + chr(10) + ")")
            end if
        end function,

        _dispatchResponseEventToTask: function(event as object) as void
            if m._task = invalid
                _adb_logError("EventProcessor::_dispatchResponseEventToTask() - Cannot send response event, task node instance is invalid.")
                return
            end if

            m._task[m._CONSTANTS.TASK.RESPONSE_EVENT] = event
        end function,

        _dispatchResponseEventToRegisteredModules: function(registeredModules as object, event as object) as void
            _adb_logVerbose("EventProcessor::_dispatchResponseEventToRegisteredModules() - Received response event:(" + chr(10) + FormatJson(event) + chr(10) + ")")

            ''' notify response events all the modules
            for each module in registeredModules
                ''' registered modules should have the method processResponseEvent
                module.processResponseEvent(event)
            end for

        end function,

        _sendResponseEvents: function(responseEvents as dynamic) as void
            if _adb_isEmptyOrInvalidArray(responseEvents)
                return
            end if

            for each event in responseEvents
                m._sendResponseEvent(event)
            end for
        end function,

        ''' TODO cleanup (clean up Media public API data and MediaModule)
        ''' Validates the event data for createMediaSession request event
        _isValidEventDataForSessionStartRequest: function(data as object) as boolean
            if data = invalid or _adb_isEmptyOrInvalidString(data.clientSessionId) or data.tsObject = invalid
                return false
            end if

            if data.xdmData = invalid or data.xdmData.xdm = invalid or data.xdmData.xdm.Count() = 0 or data.configuration = invalid
                return false
            end if

            return true
        end function,

        ''' TODO cleanup
        ''' Validates the event data for media events
        _isValidEventDataForMediaEventRequest: function(data as object) as boolean
            if data = invalid or _adb_isEmptyOrInvalidString(data.clientSessionId) or data.tsObject = invalid
                return false
            end if

            if data.xdmData = invalid or data.xdmData.xdm = invalid or data.xdmData.xdm.Count() = 0
                return false
            end if

            return true
        end function,

        _hasXDMData: function(event as object) as boolean
            return event <> invalid and event.DoesExist("data") and event.data.DoesExist("xdm") and event.data.xdm.Count() > 0
        end function,

        _dumpDebugInfo: function(event as object, loggingService as object, networkService as object) as void
            if not m._isInDebugMode()
                return
            end if

            debugInfo = {
                eventId: event.uuid,
                eventData: event.data,
                apiName: event.apiName
            }

            debugInfo.logLevel = loggingService.getLogLevel()
            debugInfo["configuration"] = m._configurationModule.dump()
            debugInfo["identity"] = m._identityModule.dump()
            debugInfo["edge"] = m._edgeModule.dump()
            debugInfo["consent"] = m._consentModule.dump()
            debugInfo["media"] = m._mediaModule.dump()
            debugInfo["networkRequests"] = networkService.dump()

            m._task.setField("debugInfo", debugInfo)
        end function,

        _isInDebugMode: function() as boolean
            if m._task <> invalid and m._task.hasField("debugInfo")
                return true
            end if
            return false
        end function,
    }

    eventProcessor.init()

    return eventProcessor
end function
