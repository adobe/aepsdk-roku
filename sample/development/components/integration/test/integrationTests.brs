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
            adobeEdgeSdk = ADB_retrieveSDKInstance()
            ADB_resetSDK(adobeEdgeSdk)
        end sub,

        TS_afterEach: sub()
            print "T_afterEach"
        end sub,

        TC_SDK_getVersion: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()

            version$ = adobeEdgeSdk.getVersion()

            ADB_assertTrue((version$ = "1.0.0"), LINE_NUM, "assert getVersion() = 1.0.0")

            return invalid
        end function,

        TC_SDK_setLogLevel_debug: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

            eventIdForSetLogLevel = adobeEdgeSdk._private.lastEventId

            version$ = adobeEdgeSdk.getVersion()

            ADB_assertTrue((_adb_retrieveTaskNode() <> invalid), LINE_NUM, "assert _adb_retrieveTaskNode")

            validator = {}
            validator[eventIdForSetLogLevel] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, "assert debugInfo.apiName = setLogLevel")
                ADB_assertTrue((debugInfo.loglevel <> invalid and debugInfo.loglevel = 1), LINE_NUM, " assert  debugInfo.loglevel = 1")
            end sub

            return validator
        end function,

        TC_SDK_setLogLevel_info: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.INFO)
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)
            adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.INFO)

            eventIdForSetLogLevel = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventIdForSetLogLevel] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, "assert debugInfo.apiName = setLogLevel")
                ADB_assertTrue((debugInfo.loglevel <> invalid and debugInfo.loglevel = 2), LINE_NUM, " assert  debugInfo.loglevel = 2")
            end sub

            return validator
        end function

        TC_SDK_resetIdentities: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.setExperienceCloudId("test_ecid")
            eventIdForSetECID = adobeEdgeSdk._private.lastEventId
            adobeEdgeSdk.resetIdentities()
            eventIdForResetIdentities = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventIdForSetECID] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = setExperienceCloudId")
                ADB_assertTrue((debugInfo.identity.ecid = "test_ecid" <> invalid), LINE_NUM, "assert ecid is test_ecid")
            end sub
            validator[eventIdForResetIdentities] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "resetIdentities"), LINE_NUM, "assert debugInfo.apiName = resetIdentities")
                ADB_assertTrue((debugInfo.identity.ecid = invalid <> invalid), LINE_NUM, "assert ecid is invalid")
            end sub

            return validator
        end function

        TC_SDK_updateConfiguration: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.updateConfiguration({
                "edge.configId": "test_configId_1",
                "edge.domain": "",
            })
            eventIdForUpdateConfiguration1 = adobeEdgeSdk._private.lastEventId
            adobeEdgeSdk.updateConfiguration({
                "edge.configId": "test_configId_2",
                "edge.domain": "",
            })
            eventIdForUpdateConfiguration2 = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventIdForUpdateConfiguration1] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid = "test_configId_1"), LINE_NUM, "assert edge_configid is test_configId_1")
                ADB_assertTrue((debugInfo.configuration.edge_domain = invalid), LINE_NUM, "assert edge_domain is invalid")
            end sub
            validator[eventIdForUpdateConfiguration2] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid = "test_configId_2"), LINE_NUM, "assert edge_configid is test_configId_2")
                ADB_assertTrue((debugInfo.configuration.edge_domain = invalid), LINE_NUM, "assert edge_domain is invalid")
            end sub

            return validator
        end function

        TC_SDK_updateConfiguration_seperateKey: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.updateConfiguration({
                "edge.configId": "test_configId_1",
                "edge.domain": "",
            })
            eventIdForUpdateConfiguration1 = adobeEdgeSdk._private.lastEventId
            adobeEdgeSdk.updateConfiguration({
                "edge.configId": "test_configId_2",
            })
            eventIdForUpdateConfiguration2 = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventIdForUpdateConfiguration1] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid = "test_configId_1"), LINE_NUM, "assert edge_configid is test_configId_1")
                ADB_assertTrue((debugInfo.configuration.edge_domain = invalid), LINE_NUM, "assert edge_domain is invalid")
            end sub
            validator[eventIdForUpdateConfiguration2] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid = "test_configId_2"), LINE_NUM, "assert edge_configid is test_configId_2")
                ADB_assertTrue((debugInfo.configuration.edge_domain = invalid), LINE_NUM, "assert edge_domain is invalid")
            end sub

            return validator
        end function
        TC_SDK_updateConfiguration_badKey: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.updateConfiguration({
                "edge.configId": "test_configId_1",
                "edge.domain": "",
            })
            eventIdForUpdateConfiguration1 = adobeEdgeSdk._private.lastEventId
            adobeEdgeSdk.updateConfiguration({
                "bad.key.edge.configId": "test_configId_2",
            })
            eventIdForUpdateConfiguration2 = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventIdForUpdateConfiguration1] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid = "test_configId_1"), LINE_NUM, "assert edge_configid is test_configId_1")
                ADB_assertTrue((debugInfo.configuration.edge_domain = invalid), LINE_NUM, "assert edge_domain is invalid")
            end sub
            validator[eventIdForUpdateConfiguration2] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid = "test_configId_1"), LINE_NUM, "assert edge_configid is test_configId_1")
                ADB_assertTrue((debugInfo.configuration.edge_domain = invalid), LINE_NUM, "assert edge_domain is invalid")
            end sub

            return validator
        end function

        TC_SDK_sendEvent: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()

            configuration = {}
            test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
            if test_config <> invalid and test_config.count() > 0
                configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = test_config.config_id
            end if
            adobeEdgeSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = adobeEdgeSdk._private.lastEventId

            adobeEdgeSdk.sendEvent({ key: "value" })

            eventIdForSendEvent = adobeEdgeSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, "assert networkRequests = 2")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].query.identity.fetch[0] = "ECID"), LINE_NUM, "assert networkRequests(1) is to fetch ECID")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")
                firstResponseJson = ParseJson(debugInfo.networkRequests[0].response.body)
                ADB_assertTrue((firstResponseJson.handle[0].payload[0].id = ecid), LINE_NUM, "assert response (1) verify ECID")
                ADB_assertTrue((firstResponseJson.requestId <> eventid), LINE_NUM, "assert response (1) verify request ID")

                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(2) is to send Edge event")
                ADB_assertTrue((Len(debugInfo.networkRequests[1].jsonObj.events[0].xdm.timestamp) > 10), LINE_NUM, "assert networkRequests(2) is to send Edge event with timestamp")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.identityMap.ECID <> invalid), LINE_NUM, "assert networkRequests(2) is to send Edge event with ecid")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.implementationDetails.name = "https://ns.adobe.com/experience/mobilesdk/roku"), LINE_NUM, "assert networkRequests(2) is to send Edge event with implementationDetails")
                secondResponseJson = ParseJson(debugInfo.networkRequests[1].response.body)
                ADB_assertTrue((secondResponseJson.requestId = eventid), LINE_NUM, "assert response (2) verify request ID")
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response (2) returns 200")
            end sub

            return validator
        end function
    }
end function
