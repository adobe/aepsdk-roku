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
        _message: "TS_SDK_integration",

        TS_beforeEach: sub()
            print "T_beforeEach"
        end sub,

        TS_afterEach: sub()
            print "T_afterEach"
        end sub,

        TC_SDK_setLogLevel_debug: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

            eventIdForSetLogLevel = adobeEdgeSdk._private.lastEventId

            version$ = adobeEdgeSdk.getVersion()

            ADB_assertTrue((_adb_retrieveTaskNode() <> invalid), LINE_NUM, "assert _adb_retrieveTaskNode")

            validator = {}
            validator[eventIdForSetLogLevel] = sub(debugInfo)
                _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                abc = "abc"
                ADB_assertTrue((abc <> "xyz"), LINE_NUM, " assert abc <> xyz")
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, " assert debugInfo <> invalid")
            end sub

            return validator
        end function,

        TC_SDK_setLogLevel_info: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.INFO)

            eventId = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventId] = sub(debugInfo)
                _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, " assert debugInfo <> invalid")
            end sub

            return validator
        end function
    }
end function
