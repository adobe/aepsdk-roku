' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

function TS_SDK_integration() as object
    return {
        _message: "xxx",

        TS_beforeEach: sub()
            print "T_beforeEach"
        end sub,
        TS_setup: sub()
            print "T_setup"
        end sub,
        TS_teardown: sub()
            print "T_teardown"
        end sub,

        TC_SDK_init: function() as dynamic
            _adb_logWarning("T_SDK_init" + m._message)
            adobeEdgeSdk = AdobeSDKInit()
            ADB_CONSTANTS = AdobeSDKConstants()
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

            eventId = adobeEdgeSdk._private.lastEventId

            version$ = adobeEdgeSdk.getVersion()

            _adb_logWarning("lalala")
            ' debugInfo = ADB_retrieveDebugInof()
            xx = _adb_retrieveTaskNode().threadinfo()
            ' print xx
            ' print _adb_timestampInMillis()

            ' ADB_assertTrue((_adb_retrieveTaskNode() <> invalid), "assert _adb_retrieveTaskNode")
            ' if version$ <> "1.0.0" then
            '     throw "xxxxxx"
            ' end if

            validator = {}
            validator[eventId] = sub(debugInfo)
                abc = "abc"
                ADB_assertTrue((abc <> "xyz"), LINE_NUM, " assert abc <> xyz")
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, " assert debugInfo <> invalid")
            end sub

            return validator
        end function,

        TC_SDK_init_2: function() as dynamic
            _adb_logWarning("T_SDK_init_2" + m._message)
            adobeEdgeSdk = AdobeSDKInit()
            ADB_CONSTANTS = AdobeSDKConstants()
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.INFO)

            eventId = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventId] = sub(debugInfo)
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, " assert debugInfo <> invalid")
            end sub

            return validator
        end function
    }
end function
