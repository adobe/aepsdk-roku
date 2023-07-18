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
sub TS_AdobeSDKInit_SetUp()
    GetGlobalAA()._adb_main_task_node = invalid
    GetGlobalAA()._adb_public_api = invalid
end sub

' @AfterAll
sub TS_AdobeSDKInit_TearDown()
    GetGlobalAA()._adb_main_task_node = invalid
    GetGlobalAA()._adb_public_api = invalid
end sub

' target: singleton pattern
' @Test
sub TC_AdobeSDKInit_singleton()
    print "TC_AdobeSDKInit_singleton"
    GetGlobalAA()._adb_main_task_node = {
        observeField: function(_arg1 as string, _arg2 as string) as void
        end function
    }
    obj1 = AdobeSDKInit()
    obj1.test_id = "test123"
    obj2 = AdobeSDKInit()
    ' the SDK instance should be initialized only once
    UTF_assertEqual(obj1.test_id, obj2.test_id)
    ' GetGlobalAA()._adb_public_api should be used to store the singletion instance
    UTF_assertEqual(GetGlobalAA()._adb_public_api.test_id, obj1.test_id)
end sub

' target: initialize task node
' @Test
sub TC_AdobeSDKInit_initialize_task_node()
    print "TC_AdobeSDKInit_singleton"
    GetGlobalAA()._adb_main_task_node = {
        observeField: function(arg1 as string, arg2 as string) as void
            ' after the task node is created, the observeField function should be called
            UTF_assertEqual(arg1, "responseEvent")
            UTF_assertEqual(arg2, "_adb_handleResponseEvent")
        end function
    }
    sdkInstance = AdobeSDKInit()
    UTF_AssertNotInvalid(sdkInstance)
    ' the task node should be kicked off
    UTF_assertEqual(GetGlobalAA()._adb_main_task_node.control, "RUN")
end sub
