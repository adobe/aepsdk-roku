' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: setLogLevel()
' @Test
sub TC_loggingService_logLevel()

    GetGlobalAA()._adb_test_last_called_method = ""

    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    func = loggingService._adb_print

    ' debug() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print1"
        UTF_assertEqual(message, "[AEPRokuSDK][D] test-123")
    end function
    loggingService.debug("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print1")

    ' info() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print2"
        UTF_assertEqual(message, "[AEPRokuSDK][I] test-123")
    end function
    loggingService.info("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print2")

    ' warning() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print3"
        UTF_assertEqual(message, "[AEPRokuSDK][W] test-123")
    end function
    loggingService.warning("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print3")

    ' error() should print message
    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print4"
        UTF_assertEqual(message, "[AEPRokuSDK][E] test-123")
    end function
    loggingService.error("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "_adb_print4")

    ' error() should not print message
    GetGlobalAA()._adb_test_last_called_method = "not_called"
    loggingService._adb_print = function(_message as string)
        GetGlobalAA()._adb_test_last_called_method = "_adb_print5"
    end function
    loggingService.verbose("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_test_last_called_method, "not_called")

    loggingService._adb_print = func
end sub

' target: setLogLevel()
' @Test
sub TC_loggingService_logLevel_default()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    UTF_assertEqual(loggingService._logLevel, 1)
end sub

' target: Log utility functions
' @Test
sub TC_loggingService_utility_functions()

    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(0)
    func = loggingService._adb_print

    loggingService._adb_print = function(message as string)
        GetGlobalAA()._adb_printed_message = message
    end function

    ' _adb_logVerbose()
    GetGlobalAA()._adb_printed_message = ""
    _adb_logVerbose("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[AEPRokuSDK][V] test-123")

    ' _adb_logDebug()
    GetGlobalAA()._adb_printed_message = ""
    _adb_logDebug("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[AEPRokuSDK][D] test-123")

    ' _adb_logInfo()
    GetGlobalAA()._adb_printed_message = ""
    _adb_logInfo("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[AEPRokuSDK][I] test-123")

    ' _adb_logWarning()
    GetGlobalAA()._adb_printed_message = ""
    _adb_logWarning("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[AEPRokuSDK][W] test-123")

    ' _adb_logError()
    GetGlobalAA()._adb_printed_message = ""
    _adb_logError("test-123")
    UTF_assertEqual(GetGlobalAA()._adb_printed_message, "[AEPRokuSDK][E] test-123")

    loggingService._adb_print = func
end sub
