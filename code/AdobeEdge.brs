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
            EDGE: "edge",
            CONFIG_ID: "configId",
            EDGE_DOMAIN: "edgeDomain",
            ' EDGE_ENVIRONMENT: "edgeEnvironment",
        },
        LOG_LEVEL: {
            VERBOSE: 0,
            DEBUG: 1,
            INFO: 2,
            WARNING: 3,
            ERROR: 4
        },
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

    _adb_log_debug("start to initialize the Adobe SDK")
    ' create the edge task node
    if GetGlobalAA()._adb_edge_task_node = invalid then
        edgeTask = CreateObject("roSGNode", "AdobeEdgeTask")
        if edgeTask = invalid then
            _adb_log_debug("AdobeSDKInit() failed")
            return invalid
        end if
        GetGlobalAA()._adb_edge_task_node = edgeTask
    end if

    if GetGlobalAA()._adb_edge_task_node = invalid
        _adb_log_debug("failed to initialize the SDK, task node is invalid")
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
                _adb_log_debug("API: setLogLevel")
                if(level < 0 or level > 4) then
                    _adb_log_error("invalid log level")
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
                _adb_log_debug("API: shutdown")
                ' stop the task node
                GetGlobalAA()._adb_edge_task_node.control = "DONE"
                ' clear the cached callback functions
                m._private.cachedCallbackInfo = {}
                ' clear global references
                GetGlobalAA()._adb_edge_task_node = invalid
                GetGlobalAA()._adb_public_api = invalid
            end function,

            ' **********************************************************************************
            '
            ' Call this function before using any other public APIs.
            ' For example, if calling sendEdgeEvent() without a valid configuration in the SDK,
            ' the SDK will drop the Edge event.
            '
            ' @param configuration as object
            '
            ' Example:
            '
            ' config = {
            '   edge = {
            '     configId: "123-abc-xyz"
            '   }
            ' }
            ' m.adobeEdgeSdk.updateConfiguration(config)
            '
            ' **********************************************************************************

            updateConfiguration: function(configuration as object) as void
                _adb_log_debug("API: updateConfiguration")
                if type(configuration) <> "roAssociativeArray" then
                    _adb_log_error("invalid configuration")
                    return
                end if
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SET_CONFIGURATION, configuration)
                m._private.dispatchEvent(event)
            end function,

            ' *************************************************************************************
            '
            ' Send edge event
            '
            ' @param data as object : xdm data
            ' @param [optional] callback as function(context, result) : handle Edge response
            ' @param [optional] context as dynamic : context to be passed to the callback function
            '
            ' Example 1:
            '
            ' m.adobeEdgeSdk.sendEdgeEvent({
            '   eventType: "commerce.orderPlaced",
            '   commerce: {
            '      .....
            '   }
            ' })
            '
            ' Example 2:
            '
            ' m.adobeEdgeSdk.sendEdgeEventWithCallback({
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

            sendEdgeEvent: function(xdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
                _adb_log_debug("API: sendEdgeEvent")
                if type(xdmData) <> "roAssociativeArray" then
                    _adb_log_error("invalid xdm data")
                    return
                end if
                ' event data: { "xdm": xdmData }
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SEND_EDGE_EVENT, {
                    xdm: xdmData
                })
                ' add a timestamp to the XDM data
                event.data.xdm.timestap = event.timestamp
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

            ' TDB
            sendEdgeEventWithNonXdmData: function(xdmData as object, nonXdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
                _adb_log_debug("API: sendEdgeEventWithNonXdmData")
                eventData = {
                    xdm: xdmData,
                    data: nonXdmData
                }
                event = m._private.buildEvent(m._private.cons.PUBLIC_API.SEND_EDGE_EVENT, eventData)
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
                _adb_log_debug("API: setExperienceCloudId")
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
                    _adb_log_debug("[dispatchEvent]: " + FormatJson(event))
                    m.taskNode[m.cons.TASK.REQUEST_EVENT] = event
                end function,
                ' private memeber
                taskNode: GetGlobalAA()._adb_edge_task_node,
                ' API callbacks to be called later
                ' CallbackInfo = {cb: function, context: dynamic}
                cachedCallbackInfo: {},
                ' private memeber
                config: {},
                ' log level
                logLevel: 4,
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
        _adb_log_debug("failed to initialize the SDK, public API is invalid")
        return invalid
    end if

    _adb_log_debug("successfully initialized the SDK")
    return GetGlobalAA()._adb_public_api
end function

' ****************************************************************************************************************************************
'                                              Below functions are for internal use only
' ****************************************************************************************************************************************

function _adb_default_callback(context, result) as void
end function

function _adb_generate_UUID() as string
    return CreateObject("roDeviceInfo").GetRandomUUID()
end function

function _adb_sdk_version() as string
    return "1.0.0-alpha1"
end function

function _adb_internal_constants() as object
    return {
        PUBLIC_API: {
            SET_CONFIGURATION: "setConfiguration",
            SET_EXPERIENCE_CLOUD_ID: "setExperienceCloudId",
            SYNC_IDENTIFIERS: "syncIdentifiers",
            SEND_EDGE_EVENT: "sendEdgeEvent",
            SET_LOG_LEVEL: "setLogLevel",
        },
        EVENT_DATA_KEY: {
            LOG: { LEVEL: "level" },
            ECID: "ecid",
        },
        STORAGE_KEY: {
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
            if current_time - sdk._private.cachedCallbackInfo[key].timestamp_in_millis > timeout_ms
                _adb_log_error("callback timeout, uuid: " + key)
                sdk._private.cachedCallbackInfo.Delete(key)
            end if
        end for

        responseEvent = sdk._private.taskNode[sdk._private.cons.TASK.RESPONSE_EVENT]
        if responseEvent <> invalid
            _adb_log_info("start to hanlde response event")
            _adb_log_debug("responseEvent:" + FormatJson(responseEvent))
            uuid = responseEvent.uuid
            if sdk._private.cachedCallbackInfo[uuid] <> invalid
                context = sdk._private.cachedCallbackInfo[uuid].context
                sdk._private.cachedCallbackInfo[uuid].cb(context, responseEvent)
                sdk._private.cachedCallbackInfo[uuid] = invalid
            else
                _adb_log_error("failed to handle response event, callback info is not found")
            end if
        else
            _adb_log_error("failed to handle response event, response event is invalid")
        end if
    else
        _adb_log_error("failed to handle response event, SDK instance is invalid")
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
        ADB_CONSTANTS: internalConstants,
        task: task,
        stateManager: _adb_StateManager(),
        networkService: _adb_serviceProvider().networkService,
        edgeRequestWorker: invalid,

        init: function() as void
            m.edgeRequestWorker = _adb_EdgeRequestWorker(m.stateManager)
        end function

        handleEvent: function(event as dynamic) as void
            if event.DoesExist("owner") and event.owner = m.ADB_CONSTANTS.EVENT_OWNER
                _adb_log_info("[handleEvent] - handle event: " + FormatJson(event))
                if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT
                    m._sendEvent(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_CONFIGURATION
                    m._setConfiguration(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_LOG_LEVEL
                    m._setLogLevel(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID
                    m._setECID(event)
                end if
            else
                _adb_log_warning("[handleEvent] - event is invalid: " + FormatJson(event))
            end if
        end function,

        _setLogLevel: function(event as object) as void
            if event.data.DoesExist(m.ADB_CONSTANTS.EVENT_DATA_KEY.LOG.LEVEL)
                logLevel = event.data[m.ADB_CONSTANTS.EVENT_DATA_KEY.LOG.LEVEL]
                loggingService = _adb_serviceProvider().loggingService
                loggingService.setLogLevel(logLevel)
                _adb_log_info("[_setLogLevel] - set log level: " + FormatJson(logLevel))
            else
                _adb_log_warning("[_setLogLevel] - log level is not found in event data")
            end if
        end function,

        _setConfiguration: function(event as object) as void
            _adb_log_info("[_setConfiguration] - set configuration")
            _adb_log_verbose("configuration before: " + FormatJson(m.stateManager.getAll()))
            m.stateManager.updateConfiguration(event.data)
            _adb_log_verbose("configuration after: " + FormatJson(m.stateManager.getAll()))
        end function,

        _setECID: function(event as object) as void
            _adb_log_info("[_setECID] - set ecid")
            if event.data.DoesExist(m.ADB_CONSTANTS.EVENT_DATA_KEY.ECID)
                ecid = event.data[m.ADB_CONSTANTS.EVENT_DATA_KEY.ECID]
                m._saveECID(ecid)
            else
                _adb_log_warning("[_setECID] - ecid is not found in event data")
            end if
        end function,

        _saveECID: function(ecid as string) as void
            _adb_log_info("[_saveECID] - save ecid")
            m.stateManager.updateECID(ecid)
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.writeValue(m.ADB_CONSTANTS.LOCAL_DATA_STORE_KEYS.ECID, ecid)
            _adb_log_verbose("save ecid to registry: " + FormatJson(ecid))
        end function,

        _queryECID: function() as string
            _adb_log_info("[_queryECID] - query ECID from service side")
            configId = m.stateManager.getConfigId()
            edgeDomain = m.stateManager.getEdgeDomain()
            url = _adb_buildEdgeRequestURL(configId, _adb_generate_UUID(), edgeDomain)
            jsonBody = {
                events: [
                    {
                        query: {
                            identity: { fetch: [
                                    "ECID"
                            ] }

                        }
                    }
                ]
            }
            response = m.networkService.syncPostRequest(url, jsonBody)
            responseJson = ParseJson(response.message)
            _adb_log_verbose("response json: " + response.message)
            return responseJson.handle[0].payload[0].id
        end function,

        _includXDMData: function(event as object) as boolean
            if event.count() <> 0 and event.data.DoesExist("xdm") and event.data.xdm.Count() > 0 then
                return true
            else
                return false
            end if
        end function,

        _sendEvent: function(event as object) as void
            _adb_log_info("[_sendEvent] - send event")

            if m._includXDMData(event) then
                _adb_log_verbose("Edge event includes xdm data, start to process.")
            else
                _adb_log_error("xdm data is empty, do not send event to edge")
                return
            end if

            ecid = m.stateManager.getECID()
            if ecid = invalid then
                ' fetch ecid from service side
                ecid = m._queryECID()
                if ecid = invalid then
                    _adb_log_error("failed to fetch ecid from service side")
                    ' return
                else
                    _adb_log_verbose("save ecid to registry")
                    m._saveECID(ecid)
                end if
            end if

            requestId = event.uuid
            configId = m.stateManager.getConfigId()
            edgeDomain = m.stateManager.getEdgeDomain()
            xdmData = event.data

            m.edgeRequestWorker.queue(requestId, xdmData, event.timestamp_in_millis, configId, ecid, edgeDomain)
            m.processQueuedRequests()
        end function,

        processQueuedRequests: function() as void
            if m.edgeRequestWorker.isReadyToProcess() then
                responses = m.edgeRequestWorker.processRequests()
                if Type(responses) = "roArray" then
                    for each response in responses
                        m._sendResponseEvent({
                            uuid: response.requestId,
                            data: {
                                code: response.code,
                                message: response.message
                            }
                        })
                    next
                else
                    m._sendResponseEvent(responses)
                end if
            end if
        end function

        _sendResponseEvent: function(event as object) as void
            _adb_log_info("[_sendResponseEvent] - send response event" + FormatJson(event))
            if m.task = invalid
                _adb_log_error("task instance is invalid, no task to send response event")
                return
            end if
            m.task[m.ADB_CONSTANTS.TASK.RESPONSE_EVENT] = event
        end function,

        _loadECID: function() as void
            _adb_log_info("[loadECID] - load ecid from storage")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            ecid = localDataStoreService.readValue(m.ADB_CONSTANTS.STORAGE_KEY.ECID)
            if ecid <> invalid and ecid <> ""
                m.stateManager.updateECID(ecid)
            end if
        end function,
    }

    eventProcessor.init()
    eventProcessor._loadECID()

    return eventProcessor
end function

function _adb_StateManager() as object
    return {
        CONFIG_KEY: AdobeSDKConstants().CONFIGURATION
        ' example : {configId:"1234567890", edgeDomain:"xyz"}
        _edge: {}
        ' example : ecid = "1234567890"
        _ecid: invalid,
        ' example : {edge: {configId:"1234567890", edgeDomain:"xyz"}}
        updateConfiguration: function(configuration as object) as void
            ' find edge configuration and save it
            if configuration.DoesExist(m.CONFIG_KEY.EDGE) and configuration.edge <> invalid then
                if configuration.edge.DoesExist(m.CONFIG_KEY.CONFIG_ID) and Type(configuration.edge[m.CONFIG_KEY.CONFIG_ID]) = "roString"
                    m._edge[m.CONFIG_KEY.CONFIG_ID] = configuration.edge[m.CONFIG_KEY.CONFIG_ID]
                end if
                if configuration.edge.DoesExist(m.CONFIG_KEY.EDGE_DOMAIN) and Type(configuration.edge[m.CONFIG_KEY.EDGE_DOMAIN]) = "roString"
                    m._edge[m.CONFIG_KEY.EDGE_DOMAIN] = configuration.edge[m.CONFIG_KEY.EDGE_DOMAIN]
                end if
            end if
        end function

        updateECID: function(ecid as string) as void
            m._ecid = ecid
        end function

        getAll: function() as object
            return {
                edge: m._edge,
                ecid: m._ecid
            }
        end function

        getECID: function() as dynamic
            return m._ecid
        end function

        getConfigId: function() as dynamic
            if m._edge.DoesExist(m.CONFIG_KEY.CONFIG_ID) then
                return m._edge[m.CONFIG_KEY.CONFIG_ID]
            else
                return invalid
            end if
        end function

        getEdgeDomain: function() as dynamic
            if m._edge.DoesExist(m.CONFIG_KEY.EDGE_DOMAIN) then
                return m._edge[m.CONFIG_KEY.EDGE_DOMAIN]
            else
                return invalid
            end if
        end function
    }
end function

function _adb_serviceProvider() as object
    if GetGlobalAA()._adb_serviceProvider_instance = invalid then
        instance = {
            loggingService: {
                ' (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
                _logLevel: 0,

                setLogLevel: function(logLevel as integer) as void
                    m._logLevel = logLevel
                end function,

                error: function(message as string) as void
                    m._adb_print("[ADB-EDGE] (e) " + message)
                end function,

                verbose: function(message as string) as void
                    if m._logLevel <= 0 then
                        m._adb_print("[ADB-EDGE] (v) " + message)
                    end if
                end function,

                debug: function(message as string) as void
                    if m._logLevel <= 1 then
                        m._adb_print("[ADB-EDGE] (d) " + message)
                    end if
                end function,

                info: function(message as string) as void
                    if m._logLevel <= 2 then
                        m._adb_print("[ADB-EDGE] (i) " + message)
                    end if
                end function,

                warning: function(message as string) as void
                    if m._logLevel <= 3 then
                        m._adb_print("[ADB-EDGE] (w) " + message)
                    end if
                end function,

                _adb_print: function(message as string) as void
                    print message
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
                                return {
                                    code: code,
                                    message: repMessage
                                }
                            end if
                            if (msg = invalid)
                                request.AsyncCancel()
                                return invalid
                            end if
                        end while
                    end if
                    return invalid
                end function,
                ' **************************************************************
                '
                ' Sned POST request to the given URL with the given JSON object
                '
                ' @param url: the URL to send the request to
                ' @param jsonObj: the JSON object to send
                ' @param headers: the headers to send with the request
                ' @param port: the port to send the response to
                ' @return the response object
                '
                ' **************************************************************
                asyncPostRequest: function(url as string, jsonObj as object, port as object, headers = [] as object) as void
                    ' network response will be sent to the port
                end function,
            },
            localDataStoreService: {
                ''' private internal variables
                _registry: CreateObject("roRegistrySection", "adb_edge_mobile"),

                ''' public Functions
                writeValue: function(key as string, value as string) as void
                    m._registry.Write(key, value)
                    m._registry.Flush()
                end function,
                readValue: function(key as string) as dynamic

                    '''bug in roku - Exists returns true even if no key. value in that case is an empty string
                    if m._registry.Exists(key) and m._registry.Read(key).Len() > 0
                        return m._registry.Read(key)
                    end if

                    return invalid
                end function,

                removeValue: function(key as string) as void
                    m._registry.Delete(key)
                    m._registry.Flush()
                end function,

                writeMap: function(mapName as string, map as dynamic) as dynamic
                    mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                    _adb_log_debug("Persistence - writeMap() writing to map: adbmobileMap_" + mapName)

                    if map <> invalid and map.Count() > 0
                        For each key in map
                            if map[key] <> invalid
                                _adb_log_debug("Persistence - writeMap() writing " + key + ":" + map[key] + " to map: adbmobileMap_" + mapName)
                                mapRegistry.Write(key, map[key])
                                mapRegistry.Flush()
                            end if
                        end for
                    end if
                end function,

                readMap: function(mapName as string) as dynamic
                    mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                    keyList = mapRegistry.GetKeyList()
                    result = {}
                    if keyList <> invalid
                        _adb_log_debug("Persistence - readMap() reading from map: adbmobileMap_" + mapName + " with size:" + keyList.Count().toStr())
                        For each key in keyList
                            result[key] = mapRegistry.Read(key)
                        end for
                    end if

                    return result
                end function

                readValueFromMap: function(mapName as string, key as string) as dynamic
                    mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                    _adb_log_debug("Persistence - readValueFromMap() reading Value for key:" + key + " from map: adbmobileMap_" + mapName)
                    if mapRegistry.Exists(key) and mapRegistry.Read(key).Len() > 0
                        return mapRegistry.Read(key)
                    end if
                    _adb_log_debug("Persistence - readValueFromMap() did not get Value for key:" + key + " from map: adbmobileMap_" + mapName)
                    return invalid
                end function,

                removeValueFromMap: function(mapName as string, key as string) as void
                    mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                    _adb_log_debug("Persistence - removeValueFromMap() removing key:" + key + " from map: adbmobileMap_" + mapName)
                    mapRegistry.Delete(key)
                    mapRegistry.Flush()
                end function,

                removeMap: function(mapName as string) as void
                    mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                    _adb_log_debug("Persistence - removeMap() deleting map: adbmobileMap_" + mapName)
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
        name: "https://ns.adobe.com/experience/mobilesdk/roku",
        version: _adb_sdk_version(),
        environment: "app"
    }
end function

function _adb_buildEdgeRequestURL(configId as string, requestId as string, edgeDomain = invalid as dynamic) as string
    if requestId.Len() < 1
        requestUrl = "https://edge.adobedc.net/ee/v1/interact?configId=" + configId
    end if
    requestUrl = "https://edge.adobedc.net/ee/v1/interact?configId=" + configId + "&requestId=" + requestId
    if edgeDomain = invalid
        return requestUrl
    end if
    return requestUrl.Replace("edge.adobedc.net", edgeDomain + ".data.adobedc.net")
end function

function _adb_EdgeRequestWorker(stateManager as object) as object
    instance = {
        _queue: [],
        _stateManager: stateManager
        _queue_size_max: 100,

        queue: function(requestId as string, xdmData as object, timestamp as integer, configId = invalid as dynamic, ecid = invalid as dynamic, edgeDomain = invalid as dynamic) as void
            requestEntity = {
                requestId: requestId,
                xdmData: xdmData,
                stamp: timestamp,
                configId: configId,
                ecid: ecid,
                edgeDomain: edgeDomain
            }
            ' remove the oldest entity if reaching the limit
            if m._queue.count() >= m._queue_size_max
                m._queue.Shift()
            end if
            m._queue.Push(requestEntity)
        end function,

        isReadyToProcess: function() as boolean
            return m._queue.count() > 0
        end function,

        processRequests: function() as dynamic
            responseArray = invalid
            while m._queue.count() > 0
                ' grab oldest hit in the queue
                requestEntity = m._queue.Shift()

                xdmData = requestEntity.xdmData
                ecid = requestEntity.ecid
                if ecid = invalid
                    ecid = m._stateManager.getECID()
                end if

                configId = requestEntity.configId
                if configId = invalid
                    configId = m._stateManager.getConfigId()
                end if

                requestId = requestEntity.requestId

                edgeDomain = requestEntity.edgeDomain
                if edgeDomain = invalid
                    edgeDomain = m._stateManager.getEdgeDomain()
                end if

                if ecid <> invalid and ecid.Len() > 0 and configId <> invalid and configId.Len() > 0 then
                    response = m._processRequest(xdmData, ecid, configId, requestId, edgeDomain)
                    ' TODO: handle response code properly
                    if response = invalid
                        _adb_log_error("Edge request dropped. Response is invalid.")
                        ' drop the request
                    else
                        _adb_log_verbose("response code : " + FormatJson(response.code))
                        _adb_log_verbose("response message :" + response.message)
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
                            _adb_log_error("Edge request dropped. Response code: " + response.code.toStr() + " Response body: " + response.message)
                            exit while
                        end if
                    end if

                else
                    _adb_log_warning("Edge request skipped. ECID and/or configId not set.")
                    exit while
                end if
            end while
            return responseArray
        end function,

        _processRequest: function(xdmData as object, ecid as string, configId as string, requestId as string, edgeDomain = invalid as dynamic) as object
            jsonBody = {
                xdm: {
                    identityMap: {
                        ECID: [
                            {
                                id: ecid,
                                primary: true,
                                authenticatedState: "ambiguous"
                            }
                        ]
                    },
                    implementationDetails: _adb_generate_implementation_details()
                },
                events: []
            }
            jsonBody.events[0] = xdmData
            url = _adb_buildEdgeRequestURL(configId, requestId, edgeDomain)
            _adb_log_verbose("request JSON: " + FormatJson(jsonBody))
            response = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            response.requestId = requestId
            return response
        end function

        clear: function() as void
            m._queue.Clear()
        end function
    }

    return instance
end function
' *****************************
