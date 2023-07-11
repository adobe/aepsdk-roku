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

' *********************************** MODULE: public API **********************************

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

            _adb_log_debug("_adb_handle_response_event() - Received response event:" + FormatJson(responseEvent) + " with uuid:" + FormatJson(uuid))
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

