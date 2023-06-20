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
sub AdobeEdgeTestSuite_SetUp()
    print "AdobeEdgeTestSuite_SetUp"
end sub

' @AfterAll
sub AdobeEdgeTestSuite_TearDown()
    print "AdobeEdgeTestSuite_TearDown"
end sub

' target: AdobeSDKConstants()
' @Test
sub TestCase_AdobeEdge_AdobeSDKConstants()
    cons = AdobeSDKConstants()
    UTF_assertEqual(cons.LOG_LEVEL.VERBOSE, 0)
    UTF_assertEqual(cons.LOG_LEVEL.DEBUG, 1)
    UTF_assertEqual(cons.LOG_LEVEL.INFO, 2)
    UTF_assertEqual(cons.LOG_LEVEL.WARNING, 3)
    UTF_assertEqual(cons.LOG_LEVEL.ERROR, 4)

    UTF_assertEqual(cons.CONFIGURATION.CONFIG_ID, "configId")
    UTF_assertEqual(cons.CONFIGURATION.EDGE_DOMAIN, "edgeDomain")
end sub

' target: _adb_generate_implementation_details()
' @Test
sub TestCase_AdobeEdge_adb_generate_implementation_details()
    implementationDetails = _adb_generate_implementation_details()
    UTF_assertEqual(implementationDetails["name"], "https://ns.adobe.com/experience/mobilesdk/roku")
    UTF_assertEqual(implementationDetails["version"], "roku sdk (1.0.0-alpha1)")
    UTF_assertEqual(implementationDetails["environment"], "app")
end sub

' target: _adb_sdk_version()
' @Test
sub TestCase_AdobeEdge_adb_sdk_version()
    UTF_assertEqual(_adb_sdk_version(), "1.0.0-alpha1")
end sub

' target: _adb_sdk_version()
' @Test
sub TestCase_AdobeEdge_adb_serviceProvider()
    instance1 = _adb_serviceProvider()
    instance1.test = "test123"
    instance2 = _adb_serviceProvider()
    UTF_assertEqual(instance1.test, instance2.test)
    UTF_assertEqual(GetGlobalAA()._adb_serviceProvider_instance.test, instance1.test)
end sub