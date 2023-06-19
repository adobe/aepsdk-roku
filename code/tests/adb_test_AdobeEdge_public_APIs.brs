' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeAll
sub AdobeEdgeTestSuite_public_APIs_SetUp()
    print "AdobeEdgeTestSuite_public_APIs_SetUp"
end sub

' @BeforeEach
sub AdobeEdgeTestSuite_public_APIs_BeforeEach()
    GetGlobalAA()._adb_public_api = invalid
    GetGlobalAA()._adb_edge_task_node = {
        observeField: function(arg1 as string, arg2 as string) as void
        end function
    }
    sdkInstance = AdobeSDKInit()
    GetGlobalAA()._adb_edge_task_node["requestEvent"] = {}
    sdkInstance._adb_internal.cachedCallbackInfo = {}
end sub

' @AfterAll
sub AdobeEdgeTestSuite_public_APIs_TearDown()
    print "AdobeEdgeTestSuite_public_APIs_TearDown"
end sub

' target: getVersion()
' @Test
sub TestCase_AdobeEdge_public_APIs_getVersion()
    sdkInstance = AdobeSDKInit()
    UTF_assertEqual(sdkInstance.getVersion(), "1.0.0-alpha1")
end sub

' target: setLogLevel()
' @Test
sub TestCase_AdobeEdge_public_APIs_setLogLevel()
    sdkInstance = AdobeSDKInit()
    sdkInstance.setLogLevel(3)
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, "setLogLevel")
    UTF_assertEqual(event.data, { level: 3 })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: setLogLevel()
' @Test
sub TestCase_AdobeEdge_public_APIs_setLogLevel_invalid()
    sdkInstance = AdobeSDKInit()
    sdkInstance.setLogLevel(5)
    sdkInstance.setLogLevel(-1)
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    UTF_assertEqual(0, event.Count())
end sub

' target: shutdown()
' @Test
sub TestCase_AdobeEdge_public_APIs_shutdown()
    sdkInstance = AdobeSDKInit()
    sdkInstance._adb_internal.cachedCallbackInfo["xxx"] = {
        "callback": function() as void
        end function
    }
    taskNode = GetGlobalAA()._adb_edge_task_node

    sdkInstance.shutdown()

    UTF_assertEqual(taskNode.control, "DONE")
    UTF_assertEqual(sdkInstance._adb_internal.cachedCallbackInfo, {})
    UTF_assertInvalid(GetGlobalAA()._adb_edge_task_node)
    UTF_assertInvalid(GetGlobalAA()._adb_public_api)
end sub

' target: updateConfiguration()
' @Test
sub TestCase_AdobeEdge_public_APIs_updateConfiguration()
    sdkInstance = AdobeSDKInit()
    configuration = { "edge.configId": "test-config-id" }
    sdkInstance.updateConfiguration(configuration)
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, "setConfiguration")
    UTF_assertEqual(event.data, configuration)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: updateConfiguration()
' @Test
sub TestCase_AdobeEdge_public_APIs_updateConfiguration_invalid()
    sdkInstance = AdobeSDKInit()
    configuration = { "edge.configId": "test-config-id" }
    sdkInstance.updateConfiguration("x")
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    UTF_assertEqual(0, event.Count())
end sub

' target: sendEdgeEvent()
' @Test
sub TestCase_AdobeEdge_public_APIs_sendEdgeEvent()
    sdkInstance = AdobeSDKInit()
    xdmData = {
        eventType: "commerce.orderPlaced",
        commerce: {
    } }
    sdkInstance.sendEdgeEvent(xdmData)
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, "sendEdgeEvent")
    UTF_assertEqual(sdkInstance._adb_internal.cachedCallbackInfo.Count(), 0)
    UTF_assertEqual(event.data, { xdm: xdmData })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: sendEdgeEvent()
' @Test
sub TestCase_AdobeEdge_public_APIs_sendEdgeEvent_invalid()
    sdkInstance = AdobeSDKInit()
    sdkInstance.sendEdgeEvent("invalid xdm data")
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count())

    UTF_assertEqual(sdkInstance._adb_internal.cachedCallbackInfo.Count(), 0)
end sub

' target: sendEdgeEvent()
' @Test
sub TestCase_AdobeEdge_public_APIs_sendEdgeEventWithCallback()
    sdkInstance = AdobeSDKInit()
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
    sdkInstance.sendEdgeEvent(xdmData, sub(ctx, result)
        UTF_assertEqual({
            content: "test"
        }, ctx)
        UTF_assertEqual(result, {
            "test": "test"
        })
    end sub, context)

    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    callbackInfo = sdkInstance._adb_internal.cachedCallbackInfo[event.uuid]

    UTF_assertEqual(callbackInfo.context, context)
    callbackInfo.cb(context, callback_result)
    UTF_assertEqual(event.apiName, "sendEdgeEvent")
    UTF_assertEqual(event.data, { xdm: xdmData })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: sendEdgeEventWithNonXdmData()
' @Test
sub TestCase_AdobeEdge_public_APIs_sendEdgeEventWithNonXdmData()
    ' sdkInstance = AdobeSDKInit()
    ' configuration = { "edge.configId": "test-config-id" }
    ' sdkInstance.updateConfiguration(configuration)
    ' event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    ' UTF_assertEqual(event.apiName, "setConfiguration")
    ' UTF_assertEqual(event.data, configuration)
    ' UTF_AssertNotInvalid(event.uuid)
    ' UTF_AssertNotInvalid(event.timestamp)
end sub

' target: setExperienceCloudId()
' @Test
sub TestCase_AdobeEdge_public_APIs_setExperienceCloudId()
    sdkInstance = AdobeSDKInit()
    test_id = "test-experience-cloud-id"
    sdkInstance.setExperienceCloudId(test_id)
    event = GetGlobalAA()._adb_edge_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, "setExperienceCloudId")
    UTF_assertEqual(event.data, { ecid: test_id })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub
