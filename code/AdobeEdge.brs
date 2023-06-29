' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' Return the Adobe SDK constants

function AdobeSDKConstants() as object
    return {
        CONFIGURATION: {
            EDGE_CONFIG_ID: "edge.configId",
            EDGE_DOMAIN: "edge.domain"
        },
        LOG_LEVEL: {
            VERBOSE: 0,
            DEBUG: 1,
            INFO: 2,
            WARNING: 3,
            ERROR: 4
        }
    }
end function

' *****************************************************************************
'
' Initialize the Adobe SDK and return the public API instance.
' The following variables are reserved to hold SDK instances in GetGlobalAA():
'   - GetGlobalAA()._adb_public_api
'   - GetGlobalAA()._adb_edge_task_node
'   - GetGlobalAA()._adb_serviceProvider_instance
'
' @return instance as object : public API instance
'
' Example:
'
' m.adobeEdgeSdk = AdobeSDKInit()
'
' *****************************************************************************

function AdobeSDKInit() as object

    if GetGlobalAA()._adb_public_api <> invalid then
        return GetGlobalAA()._adb_public_api
    end if

    _adb_log_debug("API: AdobeSDKInit() - Initializing the SDK.")
    ' create the edge task node
    if GetGlobalAA()._adb_edge_task_node = invalid then
        edgeTask = CreateObject("roSGNode", "AdobeEdgeTask")
        GetGlobalAA()._adb_edge_task_node = edgeTask
    end if

    if GetGlobalAA()._adb_edge_task_node = invalid
        _adb_log_debug("AdobeSDKInit() - Failed to initialize the SDK, task node is invalid.")
        return invalid
    end if

    ' create the public API instance
    if GetGlobalAA()._adb_public_api = invalid then
        GetGlobalAA()._adb_public_api = {

            ' ********************************
            '
            ' Return SDK version
            '
            ' @return version as string
            '
            ' ********************************

            getVersion: function() as string
                return _adb_sdk_version()
            end function,

            ' ********************************************************************************************************
            '
            ' Set log level
            '
            ' @param level as integer : the accepted values are (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
            '
            ' Example:
            '
            ' ADB_CONSTANTS = AdobeSDKConstants()
            ' m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)
            '
            ' ********************************************************************************************************

            setLogLevel: function(level as integer) as void
                _adb_log_debug("API: setLogLevel()")
                if(level < 0 or level > 4) then
                    _adb_log_error("setLogLevel() - Invalid log level:(" + StrI(level) + ").")
                    return
                end if
                ' event data: { "level": level }
                data = {}
                data[m._private.cons.EVENT_DATA_KEY.LOG.LEVEL] = level

                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SET_LOG_LEVEL, data)
                m._private.dispatchEvent(event)
            end function,

            ' ***********************************************************************
            '
            ' Call this function to shutdown the SDK and drop the further API calls.
            '
            ' ***********************************************************************

            shutdown: function() as void
                _adb_log_debug("API: shutdown()")
                ' stop the task node
                GetGlobalAA()._adb_edge_task_node.control = "DONE"
                ' clear the cached callback functions
                m._private.cachedCallbackInfo = {}
                ' clear global references
                GetGlobalAA()._adb_edge_task_node = invalid
                GetGlobalAA()._adb_public_api = invalid
            end function,

            ' ***********************************************************************
            '
            ' Call this function to reset the Adobe identities such as ECID from the SDK.
            '
            ' ***********************************************************************

            resetIdentities: function() as void
                _adb_log_debug("API: resetIdentities()")
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.RESET_IDENTITIES, invalid)
                m._private.dispatchEvent(event)
            end function,

            ' **********************************************************************************
            '
            ' Call this function before using any other public APIs.
            ' For example, if calling sendEvent() without a valid configuration in the SDK,
            ' the SDK will drop the Edge event.
            '
            ' @param configuration as object
            '
            ' Example:
            '
            ' ADB_CONSTANTS = AdobeSDKConstants()
            '
            ' configuration = {}
            ' configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = "<YOUR_CONFIG_ID>"
            ' configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = "<YOUR_DOMAIN_NAME>"
            '
            ' m.adobeEdgeSdk.updateConfiguration(configuration)
            '
            ' **********************************************************************************

            updateConfiguration: function(configuration as object) as void
                _adb_log_debug("API: updateConfiguration()")
                if type(configuration) <> "roAssociativeArray" then
                    _adb_log_error("updateConfiguration() - Cannot update configuration as the configuration is invalid.")
                    return
                end if
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SET_CONFIGURATION, configuration)
                m._private.dispatchEvent(event)
            end function,

            ' *************************************************************************************
            '
            ' Send event.
            '
            ' This function will automatically add an identity property, the Experience Cloud Identifier (ECID),
            ' to each Edge network request within the Experience event's "XDM IdentityMap".
            ' Also "ImplementationDetails" are automatically collected and are sent with every Experience Event.
            ' If you would like to include this information in your dataset, add the "Implementation Details"
            ' field group to the schema tied to your dataset.
            '
            ' @param data as object : xdm data
            ' @param [optional] callback as function(context, result) : handle Edge response
            ' @param [optional] context as dynamic : context to be passed to the callback function
            '
            ' Example 1:
            '
            ' m.adobeEdgeSdk.sendEvent({
            '   eventType: "commerce.orderPlaced",
            '   commerce: {
            '      .....
            '   }
            ' })
            '
            ' Example 2:
            '
            ' m.adobeEdgeSdk.sendEvent({
            '     eventType: "commerce.orderPlaced",
            '     commerce: {
            '        .....
            '     }
            '   }, sub(context, result)
            '     print "callback result: "
            '     print result
            '     print context
            '   end sub, context)
            '
            ' *************************************************************************************

            sendEvent: function(xdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
                _adb_log_debug("API: sendEvent()")
                if type(xdmData) <> "roAssociativeArray" then
                    _adb_log_error("sendEvent() - Cannot send event, invalid XDM data")
                    return
                end if
                ' event data: { "xdm": xdmData }
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SEND_EDGE_EVENT, {
                    xdm: xdmData
                })
                ' add a timestamp to the XDM data
                event.data.xdm.timestamp = event.timestamp
                if callback <> _adb_default_callback then
                    ' store callback function
                    callbackInfo = {
                        cb: callback,
                        context: context,
                        timestamp_in_millis: event.timestamp_in_millis
                    }
                    m._private.cachedCallbackInfo[event.uuid] = callbackInfo
                end if
                m._private.dispatchEvent(event)
            end function,

            ' ****************************************************************************************************
            '
            ' Note: Please do not call this API if you do not have both the Adobe Media SDK and the Edge SDK
            ' running in the same channel and you need to use the same ECID in both SDKs.
            '
            ' By default, the Edge SDK automatically generates an ECID (Experience Cloud ID) when first used.
            ' If the Edge SDK and the previous media SDK are running in the same channel, calling this function
            ' can keep both SDKs running with the same ECID.
            '
            ' Call this function before using other public APIs. Otherwise, an automatically generated ECID will be assigned.
            ' Whenever the ECID is changed in the Media SDK, this API needs to be called to synchronize it in both SDKs.
            '
            ' @param ecid as string : the ECID generated by the previous media SDK
            '
            ' Example:
            '
            ' mid_from_media_sdk = "0123456789"
            ' m.adobeEdgeSdk.setExperienceCloudId(mid_from_media_sdk)
            '
            ' ****************************************************************************************************

            setExperienceCloudId: function(ecid as string) as void
                _adb_log_debug("API: setExperienceCloudId()")
                if _adb_isEmptyOrInvalidString(ecid)
                    _adb_log_error("setExperienceCloudId() - Cannot set ECID, invalid ecid:(" + FormatJson(ecid) + ") passed.")
                    return
                end if
                ' event data: { "ecid": ecid }
                data = {}
                data[m._private.cons.EVENT_DATA_KEY.ecid] = ecid
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID, data)
                m._private.dispatchEvent(event)
            end function

            ' ********************************
            ' Add private memebers below
            ' ********************************
            _private: {
                ' constants
                cons: _adb_internal_constants(),
                ' ************************************
                '
                ' Build an Adobe Event
                '
                ' @param apiName : string
                ' @param data    : object
                ' @return event  : object
                '
                ' Example:
                ' event = {
                '   uuid: string,
                '   timestamp: string,
                '   apiName: string,
                '   data: object,
                '   timestamp_in_millis: integer,
                '   owner: string
                ' }
                ' ************************************
                buildEvent: function(apiName as string, data = {} as object) as object
                    return {
                        uuid: _adb_generate_UUID(),
                        timestamp: _adb_ISO8601_timestamp(),
                        apiName: apiName,
                        data: data,
                        timestamp_in_millis: _adb_timestampInMillis(),
                        owner: m.cons.EVENT_OWNER
                    }
                end function,
                ' dispatch events to the task node
                dispatchEvent: function(event as object) as void
                    _adb_log_debug("dispatchEvent() - Dispatching event:(" + FormatJson(event) + ")")
                    if m.taskNode = invalid then
                        _adb_log_debug("dispatchEvent() - Cannot dispatch public API event after shutdown(). Please initialze the SDK using AdobeSDKInit() API.")
                        return
                    end if

                    m.taskNode[m.cons.TASK.REQUEST_EVENT] = event
                end function,
                ' private memeber
                taskNode: GetGlobalAA()._adb_edge_task_node,
                ' API callbacks to be called later
                ' CallbackInfo = {cb: function, context: dynamic}
                cachedCallbackInfo: {},
            }

        }
        ' listen response events
        tmp_taskNode = GetGlobalAA()._adb_edge_task_node
        tmp_taskNode.observeField("responseEvent", "_adb_handle_response_event")
    end if

    ' start the event loop on task node
    GetGlobalAA()._adb_edge_task_node.control = "RUN"

    ' log error if instance is invalid
    _adb_public_api = GetGlobalAA()._adb_public_api
    if _adb_public_api = invalid
        _adb_log_debug("AdobeSDKInit() - Failed to initialize the SDK, public API instance is invalid")
        return invalid
    end if

    _adb_log_debug("AdobeSDKInit() - Successfully initialized the SDK")
    return GetGlobalAA()._adb_public_api
end function

' ****************************************************************************************************************************************
'                                              Below functions are for internal use only
' ****************************************************************************************************************************************

function _adb_default_callback(_context, _result) as void
end function

function _adb_generate_UUID() as string
    return CreateObject("roDeviceInfo").GetRandomUUID()
end function

function _adb_sdk_version() as string
    VERSION = "1.0.0-alpha1"
    return VERSION
end function

function _adb_internal_constants() as object
    return {
        PUBLIC_API: {
            SET_CONFIGURATION: "setConfiguration",
            SET_EXPERIENCE_CLOUD_ID: "setExperienceCloudId",
            RESET_IDENTITIES: "resetIdentities",
            SEND_EDGE_EVENT: "sendEvent",
            SET_LOG_LEVEL: "setLogLevel",
        },
        EVENT_DATA_KEY: {
            LOG: { LEVEL: "level" },
            ECID: "ecid",
        },
        LOCAL_DATA_STORE_KEYS: {
            ECID: "ecid"
        },
        TASK: {
            REQUEST_EVENT: "requestEvent",
            RESPONSE_EVENT: "responseEvent",
        },
        CALLBACK_TIMEOUT_MS: 5000,
        EVENT_OWNER: "adobe",
    }
end function

' ********** log utils ********
function _adb_log_error(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.error(message)
end function

function _adb_log_warning(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.warning(message)
end function

function _adb_log_info(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.info(message)
end function

function _adb_log_debug(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.debug(message)
end function

function _adb_log_verbose(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.verbose(message)
end function
' *****************************

' ********** response event observer **********
function _adb_handle_response_event() as void
    sdk = GetGlobalAA()._adb_public_api
    if sdk <> invalid then
        ' remove timeout callbacks
        timeout_ms = sdk._private.cons.CALLBACK_TIMEOUT_MS
        current_time = _adb_timestampInMillis()
        for each key in sdk._private.cachedCallbackInfo
            cachedCallback = sdk._private.cachedCallbackInfo[key]

            if cachedCallback <> invalid and ((current_time - cachedCallback.timestamp_in_millis) > timeout_ms)
                sdk._private.cachedCallbackInfo.Delete(key)
            end if
        end for

        responseEvent = sdk._private.taskNode[sdk._private.cons.TASK.RESPONSE_EVENT]
        if responseEvent <> invalid
            uuid = responseEvent.uuid

            _adb_log_debug("_adb_handle_response_event() - Received response event:" + FormatJson(responseEvent)+ " with uuid:" + FormatJson(uuid))
            if sdk._private.cachedCallbackInfo[uuid] <> invalid
                context = sdk._private.cachedCallbackInfo[uuid].context
                sdk._private.cachedCallbackInfo[uuid].cb(context, responseEvent)
                sdk._private.cachedCallbackInfo[uuid] = invalid
            else
                _adb_log_error("_adb_handle_response_event() - Not handling response event, callback not passed with the request event.")
            end if
        else
            _adb_log_error("_adb_handle_response_event() - Failed to handle response event, response event is invalid")
        end if
    else
        _adb_log_error("_adb_handle_response_event() - Failed to handle response event, SDK instance is invalid")
    end if
end function
' *********************************************

' ********** time utils ********
function _adb_ISO8601_timestamp() as string
    dateTime = createObject("roDateTime")
    return dateTime.toIsoString()
end function

function _adb_timestampInMillis() as integer
    dateTime = CreateObject("roDateTime")
    currMS = dateTime.GetMilliseconds()
    timeInSeconds = dateTime.AsSeconds()

    timeInMillis = timeInSeconds.ToStr()
    if currMS > 99
        timeInMillis = timeInMillis + currMS.ToStr()
    else if currMS > 9 and currMS < 100
        timeInMillis = timeInMillis + "0" + currMS.ToStr()
    else if currMS >= 0 and currMS < 10
        timeInMillis = timeInMillis + "00" + currMS.ToStr()
    end if

    return box(timeInMillis).ToInt()
end function
' *****************************

function _adb_task_node_EventProcessor(internalConstants as object, task as object) as object
    eventProcessor = {
        _ADB_CONSTANTS: internalConstants,
        _task: task,
        _stateManager: _adb_StateManager(),
        _edgeRequestWorker: invalid,

        init: function() as void
            m._edgeRequestWorker = _adb_EdgeRequestWorker(m._stateManager)
        end function

        handleEvent: function(event as dynamic) as void
            eventOwner = _adb_optStringFromMap(event, "owner", "unknown")

            if eventOwner = m._ADB_CONSTANTS.EVENT_OWNER
                _adb_log_info("handleEvent() - handle event: " + FormatJson(event))
                if event.apiname = m._ADB_CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT
                    m._sendEvent(event)
                else if event.apiname = m._ADB_CONSTANTS.PUBLIC_API.SET_CONFIGURATION
                    m._setConfiguration(event)
                else if event.apiname = m._ADB_CONSTANTS.PUBLIC_API.SET_LOG_LEVEL
                    m._setLogLevel(event)
                else if event.apiname = m._ADB_CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID
                    m._setECID(event)
                else if event.apiname = m._ADB_CONSTANTS.PUBLIC_API.RESET_IDENTITIES
                    m._resetIdentities(event)
                end if
            else
                _adb_log_warning("handleEvent() - event is invalid: " + FormatJson(event))
            end if
        end function,

        _setLogLevel: function(event as object) as void
            logLevel = _adb_optIntFromMap(event.data, m._ADB_CONSTANTS.EVENT_DATA_KEY.LOG.LEVEL)
            if logLevel <> invalid
                loggingService = _adb_serviceProvider().loggingService
                loggingService.setLogLevel(logLevel)
                _adb_log_info("_setLogLevel() - set log level: " + FormatJson(logLevel))
            else
                _adb_log_warning("_setLogLevel() - log level is not found in event data")
            end if
        end function,

        _resetIdentities: function(_event as object) as void
            _adb_log_info("_resetIdentities() - Reset presisted Identities.")
            m._stateManager.resetIdentities()
        end function,

        _setConfiguration: function(event as object) as void
            _adb_log_info("_setConfiguration() - set configuration")
            _adb_log_verbose("configuration before: " + FormatJson(m._stateManager.dump()))
            m._stateManager.updateConfiguration(event.data)
            _adb_log_verbose("configuration after: " + FormatJson(m._stateManager.dump()))
        end function,

        _setECID: function(event as object) as void
            _adb_log_info("_setECID() - Handle setECID.")

            ecid = _adb_optStringFromMap(event.data, m._ADB_CONSTANTS.EVENT_DATA_KEY.ECID)
            if ecid <> invalid
                m._stateManager.updateECID(ecid)
            else
                _adb_log_warning("_setECID() - ECID not found in event data.")
            end if
        end function,

        _hasXDMData: function(event as object) as boolean
            if event <> invalid and event.DoesExist("data") and event.data.DoesExist("xdm") and event.data.xdm.Count() > 0 then
                return true
            end if

            return false
        end function,

        _sendEvent: function(event as object) as void
            _adb_log_info("_sendEvent() - Try sending event with uuid:(" + FormatJson(event.uuid) + ").")

            if not m._hasXDMData(event)
                _adb_log_error("_sendEvent() - Not sending event, XDM data is empty.")
                return
            end if

            requestId = event.uuid
            xdmData = event.data

            m._edgeRequestWorker.queue(requestId, xdmData, event.timestamp_in_millis)
            m.processQueuedRequests()
        end function,

        processQueuedRequests: function() as void
            if m._edgeRequestWorker.isReadyToProcess() then
                responses = m._edgeRequestWorker.processRequests()
                if responses = invalid or Type(responses) <> "roArray"
                    _adb_log_error("processQueuedRequests() - not found valid edge response.")
                    return
                end if
                for each response in responses
                    m._sendResponseEvent({
                        uuid: response.requestId,
                        data: {
                            code: response.code,
                            message: response.message
                        }
                    })
                end for
            end if
        end function

        _sendResponseEvent: function(event as object) as void
            _adb_log_info("_sendResponseEvent() - Send response event: (" + FormatJson(event) + ").")
            if m._task = invalid
                _adb_log_error("_sendResponseEvent() - Cannot send response event, task node instance is invalid.")
                return
            end if
            m._task[m._ADB_CONSTANTS.TASK.RESPONSE_EVENT] = event
        end function,
    }

    eventProcessor.init()

    return eventProcessor
end function

function _adb_StateManager() as object
    return {
        CONFIG_KEY: AdobeSDKConstants().CONFIGURATION,
        _edge_configId: invalid,
        _edge_domain: invalid,
        _ecid: invalid,
        ' example config = {edge.configId:"1234567890", edge.domain:"xyz.net"}
        updateConfiguration: function(configuration as object) as void
            configId = _adb_optStringFromMap(configuration, m.CONFIG_KEY.EDGE_CONFIG_ID)
            domain = _adb_optStringFromMap(configuration, m.CONFIG_KEY.EDGE_DOMAIN)

            if not _adb_isEmptyOrInvalidString(configId)
                m._edge_configId = configId
            end if

            ' example domain: company.data.adobedc.net
            regexPattern = CreateObject("roRegex", "^((?!-)[A-Za-z0-9-]+(?<!-)\.)+[A-Za-z]{2,6}$", "")
            if not _adb_isEmptyOrInvalidString(domain) and regexPattern.isMatch(domain)
                m._edge_domain = domain
            end if
        end function,

        resetIdentities: function() as void
            m.updateECID(invalid)
        end function,

        getECID: function() as dynamic
            if m._ecid = invalid
                _adb_log_verbose("getECID() - ECID not found in cache, fetching it from presistence.")
                m._ecid = m._loadECID()
            end if

            if m._ecid = invalid
                _adb_log_verbose("getECID() - ECID not found in persistence, fetching it from service side.")
                remote_ecid = m._queryECID()
                if not _adb_isEmptyOrInvalidString(remote_ecid)
                    _adb_log_verbose("getECID() - Fetched ECID:(" + FormatJson(m._ecid) + ") from service side")
                    m.updateECID(remote_ecid)
                end if
            end if

            _adb_log_debug("getECID() - Returning ECID:(" + FormatJson(m._ecid) + ")")
            return m._ecid
        end function,

        getConfigId: function() as dynamic
            return m._edge_configId
        end function,

        getEdgeDomain: function() as dynamic
            return m._edge_domain
        end function,

        updateECID: function(ecid as dynamic) as void
            if ecid = invalid
                _adb_log_debug("updateECID() - Deleting ECID.")
            end if
            if ecid = m._ecid
                _adb_log_verbose("updateECID() - Not updating ECID. Same value is cached and persisted.")
                return
            end if
            _adb_log_verbose("updateECID() - Saving ECID:(" + FormatJson(ecid) + ") in cache and persistence.")
            m._ecid = ecid
            m._saveECID(m._ecid)
        end function,

        isReadyForRequest: function() as boolean
            configId = m.getConfigId()
            if _adb_isEmptyOrInvalidString(configId)
                _adb_log_verbose("isReadyForRequest() - Confguration for edge.configId not found.")
                return false
            end if
            ecid = m.getECID()
            if _adb_isEmptyOrInvalidString(ecid)
                _adb_log_verbose("isReadyForRequest() - ECID not set. Please verify the configuration.")
                return false
            end if
            return true
        end function,

        _loadECID: function() as dynamic
            _adb_log_info("_loadECID() - Loading ECID from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            ecid = localDataStoreService.readValue(_adb_internal_constants().LOCAL_DATA_STORE_KEYS.ECID)

            if ecid = invalid
                _adb_log_info("_loadECID() - Failed to load ECID from persistence, not found.")
            end if

            return ecid
        end function,

        _saveECID: function(ecid as dynamic) as void
            localDataStoreService = _adb_serviceProvider().localDataStoreService

            if ecid = invalid
                _adb_log_debug("_saveECID() - Removing ECID from persistence.")
                localDataStoreService.removeValue(_adb_internal_constants().LOCAL_DATA_STORE_KEYS.ECID)
                return
            end if

            _adb_log_verbose("_saveECID() - Saving ECID:(" + FormatJson(ecid) + ") to presistence.")
            localDataStoreService.writeValue(_adb_internal_constants().LOCAL_DATA_STORE_KEYS.ECID, ecid)
        end function,

        _queryECID: function() as dynamic
            _adb_log_info("_queryECID() - Fetching ECID from service side.")
            configId = m.getConfigId()
            edgeDomain = m.getEdgeDomain()

            if _adb_isEmptyOrInvalidString(configId)
                _adb_log_error("_queryECID() - Unable to fetch ECID from service side, invalid configuration.")
                return invalid
            end if

            url = _adb_buildEdgeRequestURL(configId, _adb_generate_UUID(), edgeDomain)
            jsonBody = {
                "events": [
                    {
                        "query": {
                            "identity": { "fetch": [
                                    "ECID"
                            ] }

                        }
                    }
                ]
            }
            response = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            if response.code >= 200 and response.code < 300 and response.message <> invalid
                responseJson = ParseJson(response.message)
                if responseJson <> invalid and responseJson.handle[0] <> invalid and responseJson.handle[0].payload[0] <> invalid
                    _adb_log_verbose("_queryECID() - Received response with payload: (" + FormatJson(responseJson) + ").")
                    remote_ecid = responseJson.handle[0].payload[0].id
                    return remote_ecid
                else
                    _adb_log_error("_queryECID() - Error extracting ECID, invalid response from server.")
                    return invalid
                end if
            else
                _adb_log_error("_queryECID() - Error occured while quering ECID from service side. Please verify the edge configuration.")
                return invalid
            end if
        end function,

        dump: function() as object
            return {
                edge_configId: m._edge_configId,
                edge_domain: m._edge_domain,
                ecid: m._ecid
            }
        end function
    }
end function

function _adb_serviceProvider() as object
    if GetGlobalAA()._adb_serviceProvider_instance = invalid then
        instance = {
            loggingService: {
                ' (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
                _logLevel: 2, ' Default log level

                setLogLevel: function(logLevel as integer) as void
                    m._logLevel = logLevel
                end function,

                error: function(message as string) as void
                    m._adb_print("[ADB-EDGE][E] " + message)
                end function,

                verbose: function(message as string) as void
                    if m._logLevel <= 0 then
                        m._adb_print("[ADB-EDGE][V] " + message)
                    end if
                end function,

                debug: function(message as string) as void
                    if m._logLevel <= 1 then
                        m._adb_print("[ADB-EDGE][D] " + message)
                    end if
                end function,

                info: function(message as string) as void
                    if m._logLevel <= 2 then
                        m._adb_print("[ADB-EDGE][I] " + message)
                    end if
                end function,

                warning: function(message as string) as void
                    if m._logLevel <= 3 then
                        m._adb_print("[ADB-EDGE][W] " + message)
                    end if
                end function,

                _adb_print: function(message as string) as void
                    print "[" + _adb_ISO8601_timestamp() + "]" + message
                end function
            },
            networkService: {
                ' **************************************************************
                '
                ' Sned POST request to the given URL with the given JSON object
                '
                ' @param url: the URL to send the request to
                ' @param jsonObj: the JSON object to send
                ' @param headers: the headers to send with the request
                ' @return the response object
                '
                ' **************************************************************
                syncPostRequest: function(url as string, jsonObj as object, headers = [] as object) as object
                    _adb_log_verbose("syncPostRequest() - Attempting to send request with url:(" + FormatJson(url) + ") and body:(" + FormatJson(jsonObj)+").")

                    request = CreateObject("roUrlTransfer")
                    port = CreateObject("roMessagePort")
                    request.SetPort(port)
                    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
                    ' request.InitClientCertificates()
                    request.SetUrl(url)
                    request.AddHeader("Content-Type", "application/json")
                    request.AddHeader("accept", "application/json")
                    request.AddHeader("Accept-Language", "en-US")
                    for each header in headers
                        request.AddHeader(header.key, header.value)
                    end for
                    ' request.EnableEncodings(true)
                    if (request.AsyncPostFromString(FormatJson(jsonObj)))
                        while (true)
                            msg = wait(0, port)
                            if (type(msg) = "roUrlEvent")
                                code = msg.GetResponseCode()
                                repMessage = msg.getString()
                                _adb_log_verbose("syncPostRequest() -  Sent edge request url:(" + FormatJson(url) + ") and body:(" + FormatJson(jsonObj) + ").")

                                return {
                                    code: code,
                                    message: repMessage
                                }
                            end if
                            if (msg = invalid)
                                _adb_log_verbose("syncPostRequest() - Failed to send edge request url:(" + FormatJson(url) + ") and body:(" + FormatJson(jsonObj) + ").")
                                request.AsyncCancel()
                                return invalid
                            end if
                        end while
                    end if
                    return invalid
                end function,
            },
            localDataStoreService: {
                ''' private internal variables
                _registry: CreateObject("roRegistrySection", "adb_edge_mobile"),

                ''' public Functions
                writeValue: function(key as string, value as string) as void
                    _adb_log_verbose("localDataStoreService::writeValue() - Write key:(" + key + ") value:(" + value + ") to registry.")
                    m._registry.Write(key, value)
                    m._registry.Flush()
                end function,
                readValue: function(key as string) as dynamic
                    _adb_log_verbose("localDataStoreService::readValue() - Read key:(" + key + ") from registry.")
                    '''bug in roku - Exists returns true even if no key. value in that case is an empty string
                    if m._registry.Exists(key) and m._registry.Read(key).Len() > 0
                        _adb_log_verbose("localDataStoreService::readValue() - Found key:(" + key + ") with value:(" + m._registry.Read(key) + ") in registry.")
                        return m._registry.Read(key)
                    end if


                    _adb_log_verbose("localDataStoreService::readValue() - key:(" + key + ") not found in registry.")
                    return invalid
                end function,

                removeValue: function(key as string) as void
                    _adb_log_verbose("localDataStoreService::removeValue() - Deleting key:(" + key + ") from registry.")
                    m._registry.Delete(key)
                    m._registry.Flush()
                end function,

                writeMap: function(name as string, map as dynamic) as dynamic
                    mapName = "adbmobileMap_" + name
                    mapRegistry = CreateObject("roRegistrySection", mapName)
                    _adb_log_debug("localDataStoreService::writeMap() - Writing to map:(" + mapName + ")")

                    if map <> invalid and map.Count() > 0
                        For each key in map
                            if map[key] <> invalid
                                _adb_log_debug("localDataStoreService::writeMap() - Writing [" + key + ":" + map[key] + "] to map: " + mapName)
                                mapRegistry.Write(key, map[key])
                                mapRegistry.Flush()
                            end if
                        end for
                    end if
                end function,

                readMap: function(name as string) as dynamic
                    mapName = "adbmobileMap_" + name
                    mapRegistry = CreateObject("roRegistrySection", mapName)
                    keyList = mapRegistry.GetKeyList()
                    result = {}
                    if keyList <> invalid
                        _adb_log_debug("localDataStoreService::readMap() - Reading from map:(" + mapName + ") with size:(" + keyList.Count().toStr() + ")")
                        For each key in keyList
                            result[key] = mapRegistry.Read(key)
                        end for
                    end if

                    return result
                end function

                readValueFromMap: function(name as string, key as string) as dynamic
                    mapName = "adbmobileMap_" + name
                    mapRegistry = CreateObject("roRegistrySection", mapName)
                    _adb_log_debug("localDataStoreService::readValueFromMap() - Reading value for key:(" + key + ") from map:(" + mapName + ")")
                    if mapRegistry.Exists(key) and mapRegistry.Read(key).Len() > 0
                        return mapRegistry.Read(key)
                    end if
                    _adb_log_debug("localDataStoreService::readValueFromMap() - No Value for key:(" + key + ") found in map:(" + mapName + ")")
                    return invalid
                end function,

                removeValueFromMap: function(name as string, key as string) as void
                    mapName = "adbmobileMap_" + name
                    mapRegistry = CreateObject("roRegistrySection", mapName)
                    _adb_log_debug("localDataStoreService::removeValueFromMap() - Removing key:(" + key + ") from map:(" + mapName + ")")
                    mapRegistry.Delete(key)
                    mapRegistry.Flush()
                end function,

                removeMap: function(name as string) as void
                    mapName = "adbmobileMap_" + name
                    mapRegistry = CreateObject("roRegistrySection", mapName)
                    _adb_log_debug("localDataStoreService::removeMap() - Deleting map:(" + mapName + ")")
                    keyList = mapRegistry.GetKeyList()
                    For each key in keyList
                        m.removeValueFromMap(mapName, key)
                    end for
                end function
            },
        }
        GetGlobalAA()["_adb_serviceProvider_instance"] = instance
    end if

    return GetGlobalAA()._adb_serviceProvider_instance
end function

' ********** Edge utils ********
function _adb_generate_implementation_details() as object
    return {
        "name": "https://ns.adobe.com/experience/mobilesdk/roku",
        "version": _adb_sdk_version(),
        "environment": "app"
    }
end function

function _adb_buildEdgeRequestURL(configId as string, requestId as string, edgeDomain = invalid as dynamic) as string
    scheme = "https://"
    host = "edge.adobedc.net"
    path = "/ee/v1/interact"
    query = "?configId=" + configId

    if not _adb_isEmptyOrInvalidString(edgeDomain)
        host = edgeDomain
    end if

    if not _adb_isEmptyOrInvalidString(requestId)
        query = query + "&requestId=" + requestId
    end if

    requestUrl = scheme + host + path + query

    _adb_log_debug("requestURL: (" + requestUrl + ")")
    return requestUrl
end function

function _adb_EdgeRequestWorker(stateManager as object) as object
    if stateManager = invalid
        _adb_log_debug("stateManager is invalid")
        return invalid
    end if
    instance = {
        _queue: [],
        _stateManager: stateManager
        _queue_size_max: 100,

        queue: function(requestId as string, xdmData as object, timestamp as integer) as void
            if _adb_isEmptyOrInvalidString(requestId)
                _adb_log_debug("[EdgeRequestWorker.queue()] requestId is invalid")
                return
            end if

            if isEmptyOrInvalidMap(xdmData)
                _adb_log_debug("[EdgeRequestWorker.queue()] xdmData is invalid")
                return
            end if

            if timestamp <= 0
                _adb_log_debug("[EdgeRequestWorker.queue()] timestamp is invalid")
                return
            end if

            requestEntity = {
                requestId: requestId,
                xdmData: xdmData,
                timestamp: timestamp
            }
            ' remove the oldest entity if reaching the limit
            if m._queue.count() >= m._queue_size_max
                m._queue.Shift()
            end if
            m._queue.Push(requestEntity)
        end function,

        isReadyToProcess: function() as boolean
            size = m._queue.count()

            if size = 0
                return false
            end if
            _adb_log_verbose("isReadyToProcess() - Request queue size:(" + FormatJson(size) + ")")

            if not m._stateManager.isReadyForRequest()
                return false
            end if

            _adb_log_verbose("isReadyToProcess() - Ready to process queued requests.")
            return true
        end function,

        processRequests: function() as dynamic
            responseArray = invalid
            while m._queue.count() > 0
                ' grab oldest hit in the queue
                requestEntity = m._queue.Shift()

                xdmData = requestEntity.xdmData
                requestId = requestEntity.requestId

                ecid = m._stateManager.getECID()
                configId = m._stateManager.getConfigId()
                edgeDomain = m._stateManager.getEdgeDomain()

                _adb_log_verbose("processRequests() - Using ECID:(" + FormatJson(ecid) +") and configId:(" + FormatJson(configId) + ")")
                if (not _adb_isEmptyOrInvalidString(ecid)) and (not _adb_isEmptyOrInvalidString(configId)) then
                    response = m._processRequest(xdmData, ecid, configId, requestId, edgeDomain)
                    if response = invalid
                        _adb_log_error("processRequests() - Edge request dropped. Response is invalid.")
                        ' drop the request
                    else
                        _adb_log_verbose("processRequests() - Request with id:(" + FormatJson(requestId) + ") code:(" + FormatJson(response.code) + ") message:(" + response.message + ")")
                        if response.code >= 200 and response.code <= 299 then
                            if responseArray = invalid
                                responseArray = []
                            end if
                            responseArray.Push(response)

                        else if response.code = 408 or response.code = 504 or response.code = 503
                            ' RECOVERABLE_ERROR_CODES = [408, 504, 503]
                            m._queue.Unshift(requestEntity)
                            exit while
                        else
                            ' drop the request
                            _adb_log_error("processRequests() - Edge request dropped. Response code:(" + response.code.toStr() + ") Response body:(" + response.message + ")")
                            exit while
                        end if
                    end if

                else
                    _adb_log_warning("processRequests() - Edge request skipped. ECID and/or configId not set.")
                    m._queue.Unshift(requestEntity)
                    exit while
                end if
            end while
            return responseArray
        end function,

        _processRequest: function(xdmData as object, ecid as string, configId as string, requestId as string, edgeDomain = invalid as dynamic) as object
            identityMap = {
                "ECID": [
                    {
                        "id": ecid,
                        "primary": true,
                        "authenticatedState": "ambiguous"
                    }
                ]
            }

            jsonBody = {
                "xdm": {
                    "identityMap": identityMap,
                    "implementationDetails": _adb_generate_implementation_details()
                },
                "events": []
            }

            ' Add customer provided xdmData
            jsonBody.events[0] = xdmData

            url = _adb_buildEdgeRequestURL(configId, requestId, edgeDomain)
            _adb_log_verbose("_processRequest() - Sending Request to url:(" + FormatJson(url) + ") with payload:(" + FormatJson(jsonBody) + ")")
            response = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            if response <> invalid
                response.requestId = requestId
            end if
            return response
        end function

        clear: function() as void
            m._queue.Clear()
        end function
    }

    return instance
end function
' *****************************

' ********** String utils ********
function _adb_isEmptyOrInvalidString(str as dynamic) as boolean
    if str = invalid or (type(str) <> "roString" and type(str) <> "String")
        return true
    end if

    if Len(str) = 0
        return true
    end if

    return false
end function

' ********** Map utils ********
function _adb_optMapFromMap(map as object, key as string, fallback = invalid as dynamic)
    if map = invalid
        return fallback
    end if

    if not map.DoesExist(key)
        return fallback
    end if

    ret = map[key]
    if type(ret) <> "roAssociativeArray"
        return fallback
    end if

    return ret

end function

function _adb_optStringFromMap(map as object, key as string, fallback = invalid as dynamic)
    if map = invalid
        return fallback
    end if

    if not map.DoesExist(key)
        return fallback
    end if

    ret = map[key]
    if type(ret) <> "roString" and type(ret) <> "String"
        return fallback
    end if

    return ret

end function

function _adb_optIntFromMap(map as object, key as string, fallback = invalid as dynamic)
    if map = invalid
        return fallback
    end if

    if not map.DoesExist(key)
        return fallback
    end if

    ret = map[key]
    if type(ret) <> "roInteger" and type(ret) <> "roInt"
        return fallback
    end if

    return ret

end function

function isEmptyOrInvalidMap(input as object) as boolean
    if input = invalid or type(input) <> "roAssociativeArray"
        return true
    end if

    if input.count() = 0
        return true
    end if

    return false
end function
