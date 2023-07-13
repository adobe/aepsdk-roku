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

    UTF_assertEqual(cons.CONFIGURATION.EDGE_CONFIG_ID, "edge.configId")
    UTF_assertEqual(cons.CONFIGURATION.EDGE_DOMAIN, "edge.domain")
end sub

' target: _adb_sdkVersion()
' @Test
sub TestCase_AdobeEdge_adb_sdkVersion()
    UTF_assertEqual(_adb_sdkVersion(), "1.0.0-alpha1")
end sub

' target: _adb_sdkVersion()
' @Test
sub TestCase_AdobeEdge_adb_serviceProvider()
    instance1 = _adb_serviceProvider()
    instance1.test = "test123"
    instance2 = _adb_serviceProvider()
    UTF_assertEqual(instance1.test, instance2.test)
    UTF_assertEqual(GetGlobalAA()._adb_serviceProvider_instance.test, instance1.test)
end sub

' target: _adb_isEmptyOrInvalidString()
' @Test
sub TestCase_AdobeEdge_adb_isEmptyOrInvalidString()
    UTF_assertTrue(_adb_isEmptyOrInvalidString(invalid))
    UTF_assertTrue(_adb_isEmptyOrInvalidString(""))
    UTF_assertFalse(_adb_isEmptyOrInvalidString("test"))
    UTF_assertTrue(_adb_isEmptyOrInvalidString(123))
    UTF_assertTrue(_adb_isEmptyOrInvalidString({}))
end sub

' target: _adb_optMapFromMap()
' @Test
sub TestCase_AdobeEdge_adb_optMapFromMap()
    UTF_assertEqual({ "key": "value" }, _adb_optMapFromMap({ "map": { "key": "value" } }, "map"))


    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": 1 }, "map"))
    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": "string" }, "map"))
    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": true }, "map"))
    UTF_assertEqual(invalid, _adb_optMapFromMap(invalid, "map1"))
    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": { "key": "value" } }, "map1"))

    UTF_assertEqual({}, _adb_optMapFromMap({ "map": { "key": "value" } }, "map1", {}))
    UTF_assertEqual(false, _adb_optMapFromMap({ "map": { "key": "value" } }, "map1", false))
    UTF_assertEqual("invalidMap", _adb_optMapFromMap({ "map": { "key": "value" } }, "map1", "invalidMap"))
end sub

' target: _adb_optStringFromMap()
' @Test
sub TestCase_AdobeEdge_adb_optStringFromMap()
    UTF_assertEqual("value", _adb_optStringFromMap({ "key": "value" }, "key"))

    UTF_assertEqual(invalid, _adb_optStringFromMap({ "key": 1 }, "key"))
    UTF_assertEqual(invalid, _adb_optStringFromMap({ "key": true }, "key"))
    UTF_assertEqual(invalid, _adb_optStringFromMap({ "key": "value" }, "key1"))
    UTF_assertEqual(invalid, _adb_optStringFromMap(invalid, "key1"))

    UTF_assertEqual("invalid", _adb_optStringFromMap({ "key": "value" }, "key1", "invalid"))
    UTF_assertEqual(false, _adb_optStringFromMap({ "key": "value" }, "key1", false))
    UTF_assertEqual({}, _adb_optStringFromMap({ "key": "value" }, "key1", {}))
end sub

' target: _adb_optIntFromMap()
' @Test
sub TestCase_AdobeEdge_adb_optIntFromMap()
    UTF_assertEqual(1, _adb_optIntFromMap({ "key": 1 }, "key"))

    UTF_assertEqual(invalid, _adb_optIntFromMap({ "key": "value" }, "key1"))
    UTF_assertEqual(invalid, _adb_optIntFromMap({ "key": true }, "key1"))
    UTF_assertEqual(invalid, _adb_optIntFromMap({ "key": 1 }, "key1"))
    UTF_assertEqual(invalid, _adb_optIntFromMap(invalid, "key1"))

    UTF_assertEqual(-1, _adb_optIntFromMap({ "key": "value" }, "key1", -1))
    UTF_assertEqual(false, _adb_optIntFromMap({ "key": "value" }, "key1", false))
    UTF_assertEqual("invalid", _adb_optIntFromMap({ "key": "value" }, "key1", "invalid"))
    UTF_assertEqual({}, _adb_optIntFromMap({ "key": "value" }, "key1", {}))
end sub
