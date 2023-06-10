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
            ' EDGE_DOMAIN: "edgeDomain",
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
'
' @return instance as object : public API instance
'
' Example:
'
' m.adobeEdgeSdk = AdobeSDKInit()
'
' *****************************************************************************

function AdobeSDKInit() as object
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
            ' Call this function to shutdown the SDK and drop the further API calls.
            '
            ' ********************************

            shutdown: function() as void
                _adb_log_api("shutdown")
                ' STOP and restart it later?????
                GetGlobalAA()._adb_edge_task_node.control = "DONE"
                m._adb_internal.cachedCallbackInfo = {}
                GetGlobalAA()._adb_edge_task_node = invalid
                GetGlobalAA()._adb_public_api = invalid
                ' event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SHUTDOWN)
                ' m._adb_internal.dispatchEvent(event)
            end function,

            ' *********************************************************
            '
            ' Call this function before using any other public APIs.
            ' For example, if calling sendEdgeEvent() without a valid configuration in the SDK, the SDK will drop the Edge event.
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
            ' *********************************************************

            updateConfiguration: function(configuration as object) as void
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SET_CONFIGURATION, configuration)
                m._adb_internal.dispatchEvent(event)
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
                _adb_log_api("sendEdgeEvent")
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SEND_EDGE_EVENT, xdmData)
                ' store callback function
                callbackInfo = {}
                callbackInfo.cb = callback
                callbackInfo.context = context
                m._adb_internal.cachedCallbackInfo[event.uuid] = callbackInfo
                m._adb_internal.dispatchEvent(event)
            end function,

            ' ****************************************************************************************************
            '
            ' By default, the Edge SDK automatically generates an ECID (Experience Cloud ID) when first used.
            ' If the Edge SDK and the previous media SDK are running in the same channel, calling this function
            ' can keep both SDKs running with the same ECID.
            ' Call this function before using other public APIs. Otherwise, an automatically generated ECID will be assigned.
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
                _adb_log_api("setExperienceCloudId")
                data = {}
                data.ecid = ecid
                event = m._adb_internal.buildEvent(m._adb_internal.internalConstants.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID, data)
                m._adb_internal.dispatchEvent(event)
            end function

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

function _adb_default_callback(context, result) as void
end function