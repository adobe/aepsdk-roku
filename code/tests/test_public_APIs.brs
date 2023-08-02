' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeEach
sub TS_public_APIs_BeforeEach()
    GetGlobalAA()._adb_public_api = invalid
    GetGlobalAA()._adb_main_task_node = {
        observeField: function(_arg1 as string, _arg2 as string) as void
        end function
    }
    sdkInstance = AdobeAEPSDKInit()
    GetGlobalAA()._adb_main_task_node["requestEvent"] = {}
    sdkInstance._private.cachedCallbackInfo = {}
end sub

' @AfterAll
sub TS_public_APIs_TearDown()
    GetGlobalAA()._adb_public_api = invalid
    GetGlobalAA()._adb_main_task_node = invalid
end sub

' target: getVersion()
' @Test
sub TC_APIs_getVersion()
    sdkInstance = AdobeAEPSDKInit()
    UTF_assertEqual(sdkInstance.getVersion(), "1.0.0-alpha1")
end sub

' target: setLogLevel()
' @Test
sub TC_APIs_setLogLevel()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.setLogLevel(3)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SET_LOG_LEVEL)
    UTF_assertEqual(event.data, { level: 3 })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: setLogLevel()
' @Test
sub TC_APIs_setLogLevel_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.setLogLevel(5)
    sdkInstance.setLogLevel(-1)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(0, event.Count())
end sub

' target: shutdown()
' @Test
sub TC_APIs_shutdown()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance._private.cachedCallbackInfo["xxx"] = {
        "callback": function() as void
        end function
    }
    taskNode = GetGlobalAA()._adb_main_task_node

    sdkInstance.shutdown()

    UTF_assertEqual(taskNode.control, "DONE")
    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo, {})
    UTF_assertInvalid(GetGlobalAA()._adb_main_task_node)
    UTF_assertInvalid(GetGlobalAA()._adb_public_api)
end sub

' target: updateConfiguration()
' @Test
sub TC_APIs_updateConfiguration()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    configuration = { "edge.configId": "test-config-id" }
    sdkInstance.updateConfiguration(configuration)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SET_CONFIGURATION)
    UTF_assertEqual(event.data, configuration)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: updateConfiguration()
' @Test
sub TC_APIs_updateConfiguration_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.updateConfiguration("x")
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(0, event.Count())
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEvent()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    xdmData = {
        eventType: "commerce.orderPlaced",
        commerce: {
    } }
    sdkInstance.sendEvent(xdmData)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SEND_EDGE_EVENT)
    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
    UTF_assertEqual(event.data, { xdm: {
            eventType: "commerce.orderPlaced",
            timestamp: event.timestamp,
            commerce: {
    } } })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEvent_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.sendEvent("invalid xdm data")
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count())

    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEventWithCallback()
    sdkInstance = AdobeAEPSDKInit()
    ' configuration = { "edge.configId": "test-config-id" }
    xdmData = {
        eventType: "commerce.orderPlaced",
        commerce: {
    } }
    context = {
        content: "test"
    }
    callback_result = {
        "test": "test"
    }
    sdkInstance.sendEvent(xdmData, sub(ctx, result)
        UTF_assertEqual({
            content: "test"
        }, ctx)
        UTF_assertEqual(result, {
            "test": "test"
        })
    end sub, context)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    callbackInfo = sdkInstance._private.cachedCallbackInfo[event.uuid]

    UTF_assertEqual(callbackInfo.context, context)
    UTF_AssertNotInvalid(callbackInfo.timestampInMillis)
    callbackInfo.cb(context, callback_result)
    UTF_assertEqual(event.apiName, "sendEvent")
    UTF_assertEqual(event.data, { xdm: xdmData })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: setExperienceCloudId()
' @Test
sub TC_APIs_setExperienceCloudId()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    test_id = "test-experience-cloud-id"
    sdkInstance.setExperienceCloudId(test_id)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID)
    UTF_assertEqual(event.data, { ecid: test_id })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub
