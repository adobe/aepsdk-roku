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

' ******************************** MODULE: LoggingService *********************************

function _adb_LoggingService() as object
    return {
        ' (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
        _logLevel: 2, ' Default log level

        setLogLevel: function(logLevel as integer) as void
            m._logLevel = logLevel
        end function,

        error: function(message as string) as void
            m._adb_print("[ADB-EDGE][E] " + message)
        end function,

        verbose: function(message as string) as void
            if m._logLevel <= 0 then
                m._adb_print("[ADB-EDGE][V] " + message)
            end if
        end function,

        debug: function(message as string) as void
            if m._logLevel <= 1 then
                m._adb_print("[ADB-EDGE][D] " + message)
            end if
        end function,

        info: function(message as string) as void
            if m._logLevel <= 2 then
                m._adb_print("[ADB-EDGE][I] " + message)
            end if
        end function,

        warning: function(message as string) as void
            if m._logLevel <= 3 then
                m._adb_print("[ADB-EDGE][W] " + message)
            end if
        end function,

        _adb_print: function(message as string) as void
            print "[" + _adb_ISO8601_timestamp() + "]" + message
        end function
    }
end function
