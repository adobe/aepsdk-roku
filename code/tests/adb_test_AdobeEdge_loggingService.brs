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
sub AdobeEdgeTestSuite_loggingService_BeforeEach()
    print "AdobeEdgeTestSuite_loggingService_BeforeEach"
    GetGlobalAA()._adb_serviceProvider_instance = invalid
end sub

' @AfterAll
sub AdobeEdgeTestSuite_loggingService_TearDown()
    print "AdobeEdgeTestSuite_loggingService_TearDown"
end sub

' target: setLogLevel()
' @Test
sub TestCase_AdobeEdge_loggingService_logLevel()

    GetGlobalAA()._adb_test_last_called_method = ""

    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    func = loggingService._adb_print

    ' debug() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print1"
        UTF_assertEqual(message, "[ADB-EDGE-D] test-123")
    end function
    loggingService.debug("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print1")

    ' info() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print2"
        UTF_assertEqual(message, "[ADB-EDGE-I] test-123")
    end function
    loggingService.info("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print2")

    ' warning() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print3"
        UTF_assertEqual(message, "[ADB-EDGE-W] test-123")
    end function
    loggingService.warning("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print3")

    ' error() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print4"
        UTF_assertEqual(message, "[ADB-EDGE-E] test-123")
    end function
    loggingService.error("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print4")

    ' error() should not print message
    GetGlobalAA()._adb_test_last_called_method = "not_called"
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print5"
    end function
    loggingService.verbose("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "not_called")

    loggingService._adb_print = func
end sub

' target: setLogLevel()
' @Test
sub TestCase_AdobeEdge_loggingService_logLevel_default()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    UTF_assertEqual(loggingService._logLevel, 0)
end sub

' target: Log utility functions
' @Test
sub TestCase_AdobeEdge_loggingService_utility_functions()



    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(0)
    func = loggingService._adb_print

    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_printed_message = message
    end function

    ' _adb_log_verbose()
    GetGlobalAA()._adb_printed_message = ""
    _adb_log_verbose("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[ADB-EDGE-V] test-123")

    ' _adb_log_debug()
    GetGlobalAA()._adb_printed_message = ""
    _adb_log_debug("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[ADB-EDGE-D] test-123")

    ' _adb_log_info()
    GetGlobalAA()._adb_printed_message = ""
    _adb_log_info("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[ADB-EDGE-I] test-123")

    ' _adb_log_warning()
    GetGlobalAA()._adb_printed_message = ""
    _adb_log_warning("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[ADB-EDGE-W] test-123")

    ' _adb_log_error()
    GetGlobalAA()._adb_printed_message = ""
    _adb_log_error("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[ADB-EDGE-E] test-123")

    loggingService._adb_print = func
end sub
