' ********************** Copyright 2022 Adobe. All rights reserved. **********************

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
            CONFIG_ID: "configId",
            EDGE_DOMAIN: "edgeDomain",
            EDGE_ENVIRONMENT: "edgeEnvironment",
            ' ORG_ID: "orgId", ?????
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
'
' @param configuration as object      : configuration for the SDK
' @param (optional) ecid as string    : experience cloud id
' @return instance as object          : public API instance
'
'
' Example:
'
' config = {
'   edge = {
'     configId: "0123456789"
'   }
' }
' m.adobeEdgeSdk = AdobeSDKInit(config)
'
' *****************************************************************************

function AdobeSDKInit(configuration as object, ecid = "" as string) as object
    ' create the edge task node
    _adb_log_api("start to initialize the Adobe SDK")
    if GetGlobalAA()._adb_edge_task_node = invalid then
        edgeTask = CreateObject("roSGNode", "AdobeEdgeTask")
        if edgeTask = invalid then
            _adb_log_api("AdobeSDKInit() failed")
            return invalid
        end if
        GetGlobalAA()._adb_edge_task_node = edgeTask
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
                return m._adb_internal.internalConstants.VERSION
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
                _adb_log_api("setLogLevel")
                data = {}
                data.level = level
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SET_LOG_LEVEL, data)
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************
            '
            ' Shut down the SDK
            '
            ' ********************************

            shutdown: function() as void
                _adb_log_api("shutdown")
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SHUTDOWN)
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************
            '
            ' Set configuration
            '
            ' @param configuration as object
            '
            ' ********************************

            setConfiguration: function(configuration as object) as void
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SET_CONFIGURATION, configuration)
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************
            '
            ' Send edge event
            '
            ' @param data as object : xdm data
            '
            ' Example:
            '
            ' m.adobeEdgeSdk.sendEdgeEvent({
            '   eventType: "commerce.orderPlaced",
            '   commerce: {
            '      .....
            '   }
            ' })
            '
            ' ********************************

            sendEdgeEvent: function(xdmData as object) as void
                _adb_log_api("sendEdgeEvent")
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SEND_EDGE_EVENT, xdmData)
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************************************************
            '
            ' Send edge event and handle the response
            '
            ' @param data as object : xdm data
            ' @param callback as function(context, result) : handle Edge response
            '
            ' Example:
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
            ' ********************************************************************

            sendEdgeEventWithCallback: function(data as object, callback as function, context = invalid as dynamic) as void
                _adb_log_api("sendEdgeEventWithCallback")
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SEND_EDGE_EVENT, data)
                ' store callback function
                callbackInfo = {}
                callbackInfo.cb = callback
                callbackInfo.context = context
                m._adb_internal.cachedCallbackInfo[event.uuid] = callbackInfo
                ' send event
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************************************************
            '
            ' Update identities
            '
            ' @param identifier as object : xmd identity map
            '
            ' Example:
            '
            ' m.adobeEdgeSdk.updateIdentities({
            '   Email: [
            '     {
            '       id: "user@example.com",
            '       authenticatedState: "authenticated",
            '       primary: false
            '     }
            '   ]
            ' })
            ' ********************************************************************

            updateIdentities: function(identifier as object) as void
                _adb_log_api("setIdentifier")
                data = {}
                data.identifier = identifier
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.UPDATE_IDENTITIES, data)
                m._adb_internal.dispatchEvent(event)
            end function,

            ' **********************************************************************
            '
            ' This is used to set the advertising identifier for the SDK
            '
            ' @param advertisingIdentifier as string : the advertising identifier
            '
            ' **********************************************************************
            setAdvertisingIdentifier: function(advertisingIdentifier as string) as void
                _adb_log_api("setAdvertisingIdentifier")
                data = {}
                data.aid = advertisingIdentifier
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SET_ADVERTISING_IDENTIFIER, data)
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************************************************
            '
            ' Retrieve identities (??????)
            '
            ' @param callback as function(context, result) : handle SDK response
            '
            ' ********************************************************************

            getIdentities: function(callback as function, context = invalid as dynamic) as void
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.GET_IDENTITIES, {})
                ' store callback function
                callbackInfo = {}
                callbackInfo.cb = callback
                callbackInfo.context = context
                m._adb_internal.cachedCallbackInfo[event.uuid] = callbackInfo
                ' send event
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ********************************
            ' Add private memebers below
            ' ********************************
            _adb_internal: {
                ' constants
                internalConstants: _adb_internal_constants(),
                ' build an Adobe Event
                ' @param apiName : string
                ' @param data    : object
                ' @return event  : object
                '
                ' Example:
                ' event = {
                '   uuid: string,
                '   timestamp: string,
                '   apiName: string,
                '   data: object
                ' }
                buildEvent: function(apiName as string, data = {} as object) as object
                    event = {
                        apiName: apiName,
                        data: data,
                    }
                    event.uuid = CreateObject("roDeviceInfo").GetRandomUUID()
                    event.timestamp = _adb_timestampInMillis()
                    return event
                end function,
                ' set experience cloud id
                setExperienceCloudId: function(ecid as string) as void
                    _adb_log_api("setExperienceCloudId")
                    data = {}
                    data.ecid = ecid
                    event = m.buildEvent(m.internalConstants.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID, data)
                    m.dispatchEvent(event)
                end function
                ' dispatch events to the task node
                dispatchEvent: function(event as object) as void
                    _adb_log_api("dispatchEvent: " + FormatJson(event))
                    m.taskNode[m.internalConstants.TASK.REQUEST_EVENT] = event
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
    _adb_public_api = GetGlobalAA()._adb_public_api
    if _adb_public_api = invalid
        _adb_log_api("failed to initialize the SDK")
        return invalid
    end if
    _adb_log_api("successfully initialized the SDK")
    ' set ecid if provided
    if ecid.len() > 0
        _adb_public_api._adb_internal.setExperienceCloudId(ecid)
    end if

    ' set configuration
    _adb_public_api.setConfiguration(configuration)

    return GetGlobalAA()._adb_public_api
end function

' ***************************************
' Below functions are internal use only
' ***************************************

function _adb_internal_constants() as object
    return {
        VERSION: "1.0.0-alpha.1",
        PUBLIC_API: {
            SET_CONFIGURATION: "setConfiguration",
            GET_IDENTITIES: "getIdentities",
            UPDATE_IDENTITIES: "updateIdentities",
            SET_ADVERTISING_IDENTIFIER: "setAdvertisingIdentifier",
            SET_EXPERIENCE_CLOUD_ID: "setExperienceCloudId",
            SYNC_IDENTIFIERS: "syncIdentifiers",
            SEND_EDGE_EVENT: "sendEdgeEvent",
            SHUTDOWN: "shutdown",
            SET_LOG_LEVEL: "setLogLevel",
        },
        TASK: {
            REQUEST_EVENT: "requestEvent",
            RESPONSE_EVENT: "responseEvent",
        },
    }
end function

function _adb_handle_response_event() as void
    sdk = GetGlobalAA()._adb_public_api
    if sdk <> invalid then
        responseEvent = sdk._adb_internal.taskNode["responseEvent"]
        if responseEvent <> invalid
            _adb_log_api("responseEvent:" + FormatJson(responseEvent))
            uuid = responseEvent.uuid
            if sdk._adb_internal.cachedCallbackInfo[uuid] <> invalid
                context = sdk._adb_internal.cachedCallbackInfo[uuid].context
                sdk._adb_internal.cachedCallbackInfo[uuid].cb(context, responseEvent)
                sdk._adb_internal.cachedCallbackInfo[uuid] = invalid
            end if
        end if
    end if
end function

function _adb_timestampInMillis() as string
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

    return timeInMillis
end function

function _adb_log_api(message as string) as void
    print "[ADB-EDGE API]" + message
end function