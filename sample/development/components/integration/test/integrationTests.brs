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
    instance = {

        configId: invalid,

        init: sub()
            test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
            m.configId = test_config.config_id
            if _adb_isEmptyOrInvalidString(m.configId) then
                throw "Not found a valid config_id in test_config.json"
            end if
        end sub,

        TS_beforeEach: sub()
            ADB_clearPersistedECID()
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

            ADB_assertTrue((version$ = "1.0.0-alpha1"), LINE_NUM, "assert getVersion() = 1.0.0-alpha1")

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
        end function,

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
                ADB_assertTrue((debugInfo.identity.ecid = invalid), LINE_NUM, "assert ecid is invalid")
                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, "assert the persisted ecid is invalid")
            end sub

            return validator
        end function,

        TC_SDK_resetIdentities_withoutValidECID: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.resetIdentities()
            eventIdForResetIdentities = adobeEdgeSdk._private.lastEventId
            validator = {}
            validator[eventIdForResetIdentities] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "resetIdentities"), LINE_NUM, "assert debugInfo.apiName = resetIdentities")
                ADB_assertTrue((debugInfo.identity.ecid = invalid), LINE_NUM, "assert ecid is invalid")
                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, "assert the persisted ecid is invalid")
            end sub

            return validator
        end function,

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
        end function,

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
        end function,

        TC_SDK_updateConfiguration_wrongKey: function() as dynamic

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
        end function,

        TC_SDK_sendEvent: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

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
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
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

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, "assert ecid is persisted in Registry")
            end sub

            return validator
        end function,

        TC_SDK_sendEvent_withoutValidConfig: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.sendEvent({ key: "value1" })
            eventIdForFirstSendEvent = adobeEdgeSdk._private.lastEventId

            adobeEdgeSdk.sendEvent({ key: "value2" })
            eventIdForSecondSendEvent = adobeEdgeSdk._private.lastEventId

            validator = {}

            validator[eventIdForFirstSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 1), LINE_NUM, "assert requestQueue = 1")
                ADB_assertTrue((debugInfo.edge.requestQueue[0].requestId = eventid), LINE_NUM, "assert request ID is correct")
            end sub

            validator[eventIdForSecondSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 2), LINE_NUM, "assert requestQueue = 2")
                ADB_assertTrue((debugInfo.edge.requestQueue[1].requestId = eventid), LINE_NUM, "assert request ID is correct")
            end sub

            return validator
        end function,

        TC_SDK_sendEvent_provideValidConfigLater: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.sendEvent({ key: "value1" })
            eventIdForFirstSendEvent = adobeEdgeSdk._private.lastEventId

            adobeEdgeSdk.sendEvent({ key: "value2" })
            eventIdForSecondSendEvent = adobeEdgeSdk._private.lastEventId

            ADB_CONSTANTS = AdobeSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            adobeEdgeSdk.updateConfiguration(configuration)

            adobeEdgeSdk.sendEvent({ key: "value3" })
            eventIdForThirdSendEvent = adobeEdgeSdk._private.lastEventId

            validator = {}

            validator[eventIdForFirstSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 1), LINE_NUM, "assert requestQueue = 1")
                ADB_assertTrue((debugInfo.edge.requestQueue[0].requestId = eventid), LINE_NUM, "assert request ID is correct")
            end sub

            validator[eventIdForSecondSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 2), LINE_NUM, "assert requestQueue = 2")
                ADB_assertTrue((debugInfo.edge.requestQueue[1].requestId = eventid), LINE_NUM, "assert request ID is correct")
            end sub

            validator[eventIdForThirdSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))

                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 4), LINE_NUM, "assert networkRequests = 4")

                ' Fetch ECID
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].query.identity.fetch[0] = "ECID"), LINE_NUM, "assert networkRequests(1) is to fetch ECID")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")
                firstResponseJson = ParseJson(debugInfo.networkRequests[0].response.body)
                ADB_assertTrue((firstResponseJson.handle[0].payload[0].id = ecid), LINE_NUM, "assert response (1) verify ECID")
                ADB_assertTrue((firstResponseJson.requestId <> eventid), LINE_NUM, "assert response (1) verify request ID")

                ' Send event 1
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.key = "value1"), LINE_NUM, "assert networkRequests(2) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequests(2) is to send Edge event with ecid")
                secondResponseJson = ParseJson(debugInfo.networkRequests[1].response.body)
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response (2) returns 200")

                ' Send event 2
                ADB_assertTrue((debugInfo.networkRequests[2].jsonObj.events[0].xdm.key = "value2"), LINE_NUM, "assert networkRequests(3) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[2].jsonObj.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequests(3) is to send Edge event with ecid")
                secondResponseJson = ParseJson(debugInfo.networkRequests[2].response.body)
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response (3) returns 200")

                ' Send event 3
                ADB_assertTrue((debugInfo.networkRequests[3].jsonObj.events[0].xdm.key = "value3"), LINE_NUM, "assert networkRequests(4) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[3].jsonObj.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequests(4) is to send Edge event with ecid")
                secondResponseJson = ParseJson(debugInfo.networkRequests[3].response.body)
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response (4) returns 200")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, "assert ecid is persisted in Registry")
            end sub

            return validator
        end function,

        TC_SDK_sendEvent_withCallback: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            adobeEdgeSdk.updateConfiguration(configuration)

            GetGlobalAA()._adb_integration_test_callback_result = invalid
            adobeEdgeSdk.sendEvent({ key: "value" }, sub(context, result)
                GetGlobalAA()._adb_integration_test_callback_result = result
            end sub, {})

            eventIdForSendEvent = adobeEdgeSdk._private.lastEventId

            validator = {}

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, "assert networkRequests = 2")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")

                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(2) is to send Edge event")
                secondResponseJson = ParseJson(debugInfo.networkRequests[1].response.body)
                ADB_assertTrue((secondResponseJson.requestId = eventid), LINE_NUM, "assert response (2) verify request ID")
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response (2) returns 200")
                callbackResult = GetGlobalAA()._adb_integration_test_callback_result
                ADB_assertTrue((callbackResult.code = 200), LINE_NUM, "assert callback received 200 response")
                ADB_assertTrue((not _adb_isEmptyOrInvalidString(callbackResult.message)), LINE_NUM, "assert callback received response message")
            end sub

            return validator
        end function,

        TC_SDK_setExperienceCloudId: function() as dynamic

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            adobeEdgeSdk.setExperienceCloudId("test_ecid")
            eventIdForSetExperienceCloudId = adobeEdgeSdk._private.lastEventId

            ADB_CONSTANTS = AdobeSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            adobeEdgeSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = adobeEdgeSdk._private.lastEventId

            adobeEdgeSdk.sendEvent({ key: "value" })

            eventIdForSendEvent = adobeEdgeSdk._private.lastEventId

            validator = {}
            validator[eventIdForSetExperienceCloudId] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = "test_ecid"), LINE_NUM, "assert test_ecid is persisted in Registry")
            end sub
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                ADB_assertTrue((ecid = "test_ecid"), LINE_NUM, "assert debugInfo.identity.ecid = test_ecid")
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(1) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 400), LINE_NUM, "assert response (1) returns 200")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = "test_ecid"), LINE_NUM, "assert test_ecid is persisted in Registry")
            end sub

            return validator
        end function,

        TC_SDK_ecid_consistence: function() as dynamic

            ADB_persisteECIDInRegistry("test_ecid_x")

            adobeEdgeSdk = ADB_retrieveSDKInstance()

            ADB_resetSDK(adobeEdgeSdk)

            ADB_CONSTANTS = AdobeSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            adobeEdgeSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = adobeEdgeSdk._private.lastEventId

            adobeEdgeSdk.sendEvent({ key: "value" })

            eventIdForSendEvent = adobeEdgeSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = "test_ecid_x"), LINE_NUM, "assert test_ecid_x is persisted in Registry")
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))

                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(1) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 400), LINE_NUM, "assert response (1) returns 200")

                ecidInRegistry = ADB_getPersistedECID()
                ecid = debugInfo.identity.ecid
                ADB_assertTrue((ecid = "test_ecid_x"), LINE_NUM, "assert in-memory ecid is test_ecid_x")
                ADB_assertTrue((ecidInRegistry = "test_ecid_x"), LINE_NUM, "assert test_ecid_x is persisted in Registry")
            end sub

            return validator
        end function,

    }

    instance.init()

    return instance
end function
