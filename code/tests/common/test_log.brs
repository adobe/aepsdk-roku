' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

'@BeforeAll
sub TS_logUtils_SetUp()
    GetGlobalAA().loggingService_verbose_is_called = false
    GetGlobalAA().loggingService_debug_is_called = false
    GetGlobalAA().loggingService_info_is_called = false
    GetGlobalAA().loggingService_warning_is_called = false
    GetGlobalAA().loggingService_error_is_called = false
end sub

' @BeforeEach
sub TS_logUtils_BeforeEach()
    GetGlobalAA().loggingService_verbose_is_called = false
    GetGlobalAA().loggingService_debug_is_called = false
    GetGlobalAA().loggingService_info_is_called = false
    GetGlobalAA().loggingService_warning_is_called = false
    GetGlobalAA().loggingService_error_is_called = false
end sub

' @AfterAll
sub TS_logUtils_TearDown()
    GetGlobalAA()._adb_serviceProvider_instance = invalid
end sub

' target: _adb_logError()
' @Test
sub TC_adb_logError()
    _adb_serviceProvider().loggingService.error = function(message)
        GetGlobalAA().loggingService_error_is_called = true
        UTF_assertEqual("error message", message)
    end function
    _adb_logError("error message")
    UTF_assertTrue(GetGlobalAA().loggingService_error_is_called)

end sub

' target: _adb_logWarning()
' @Test
sub TC_adb_logWarning()
    _adb_serviceProvider().loggingService.warning = function(message)
        GetGlobalAA().loggingService_warning_is_called = true
        UTF_assertEqual("warning message", message)
    end function
    _adb_logWarning("warning message")
    UTF_assertTrue(GetGlobalAA().loggingService_warning_is_called)
end sub

' target: _adb_logInfo()
' @Test
sub TC_adb_logInfo()
    _adb_serviceProvider().loggingService.info = function(message)
        GetGlobalAA().loggingService_info_is_called = true
        UTF_assertEqual("info message", message)
    end function
    _adb_logInfo("info message")
    UTF_assertTrue(GetGlobalAA().loggingService_info_is_called)
end sub

' target: _adb_logDebug()
' @Test
sub TC_adb_logDebug()
    _adb_serviceProvider().loggingService.debug = function(message)
        GetGlobalAA().loggingService_debug_is_called = true
        UTF_assertEqual("debug message", message)
    end function
    _adb_logDebug("debug message")
    UTF_assertTrue(GetGlobalAA().loggingService_debug_is_called)
end sub

' target: _adb_logVerbose()
' @Test
sub TC_adb_logVerbose()
    _adb_serviceProvider().loggingService.verbose = function(message)
        GetGlobalAA().loggingService_verbose_is_called = true
        UTF_assertEqual("verbose message", message)
    end function
    _adb_logVerbose("verbose message")
    UTF_assertTrue(GetGlobalAA().loggingService_verbose_is_called)
end sub