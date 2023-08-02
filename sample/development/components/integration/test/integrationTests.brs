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

        _testECID: "12345678901234567890123456789012345678",
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
            aepSdk = ADB_retrieveSDKInstance()
            ADB_resetSDK(aepSdk)
        end sub,

        TS_afterEach: sub()
            print "T_afterEach"
        end sub,

        TC_SDK_getVersion: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            version$ = aepSdk.getVersion()

            ADB_assertTrue((version$ = "1.0.0-alpha1"), LINE_NUM, "assert getVersion() = 1.0.0-alpha1")

            return invalid
        end function,

        TC_SDK_setLogLevel_debug: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()
            aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

            eventIdForSetLogLevel = aepSdk._private.lastEventId

            version$ = aepSdk.getVersion()

            ADB_assertTrue((_adb_retrieveTaskNode() <> invalid), LINE_NUM, "assert _adb_retrieveTaskNode")

            validator = {}
            validator[eventIdForSetLogLevel] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setLogLevel"), LINE_NUM, "assert debugInfo.apiName = setLogLevel")
                ADB_assertTrue((debugInfo.loglevel <> invalid and debugInfo.loglevel = 1), LINE_NUM, " assert  debugInfo.loglevel = 1")
            end sub

            return validator
        end function,

        TC_SDK_resetIdentities: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            aepSdk.setExperienceCloudId("test_ecid")
            eventIdForSetECID = aepSdk._private.lastEventId
            aepSdk.resetIdentities()
            eventIdForResetIdentities = aepSdk._private.lastEventId
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

        TC_SDK_updateConfiguration: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            aepSdk.updateConfiguration({
                "edge.configId": "test_configId_1",
            })
            eventIdForUpdateConfiguration1 = aepSdk._private.lastEventId
            aepSdk.updateConfiguration({
                "edge.configId": "test_configId_2",
                "edge.domain": "edge.com",
            })
            eventIdForUpdateConfiguration2 = aepSdk._private.lastEventId
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
                ADB_assertTrue((debugInfo.configuration.edge_domain = "edge.com"), LINE_NUM, "Expected: (edge.com) != Actual: (" + debugInfo.configuration.edge_domain + ")")
            end sub

            return validator
        end function,

        TC_SDK_sendEvent: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

            idMap = {
                "RIDA" : [
                    {
                        "id" : "test-ad-id",
                        "authenticatedState": "ambiguous",
                        "primary": false
                    }
                  ],
                "EMAIL" : [
                    {
                        "id" : "test@test.com",
                        "authenticatedState": "ambiguous",
                        "primary": false
                    }
                ]
            }

            aepSdk.sendEvent({ key: "value", "identityMap": idMap })

            eventIdForSendEvent = aepSdk._private.lastEventId

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

                xdmData = debugInfo.eventData
                ADB_assertTrue((xdmData <> invalid), LINE_NUM, "Event Data should not be invalid")
                ADB_assertTrue((xdmData.xdm <> invalid), LINE_NUM, "XDM data should not be invalid")
                ADB_assertTrue((xdmData.xdm.identityMap <> invalid), LINE_NUM, "XDM data should contain the identityMap")
                ADB_assertTrue((xdmData.xdm.timestamp <> invalid), LINE_NUM, "XDM data should contain valid timestamp")

                expectedXDMData = {"EMAIL":[{"authenticatedState":"ambiguous","id":"test@test.com","primary":false}],"RIDA":[{"authenticatedState":"ambiguous","id":"test-ad-id","primary":false}]}
                xdmDataJson = FormatJson(xdmData.xdm.identityMap)
                expectedXDMDataJson = FormatJson(expectedXDMData)
                ADB_assertTrue((xdmDataJson = expectedXDMDataJson), LINE_NUM, "Actual XDM data(" + xdmDataJson + ") != Expected XDM data(" + expectedXDMDataJson + ") ")

                ' Verify fetch ECID request
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, "assert networkRequests = 2")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].query.identity.fetch[0] = "ECID"), LINE_NUM, "assert networkRequests(1) is to fetch ECID")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")
                firstResponseJson = ParseJson(debugInfo.networkRequests[0].response.body)
                ADB_assertTrue((firstResponseJson.handle[0].payload[0].id <> invalid), LINE_NUM, "ECID should not be invalid")
                ADB_assertTrue((firstResponseJson.handle[0].payload[0].id = ecid), LINE_NUM, "Expected: (" + ecid + ") != Actual: (" + firstResponseJson.handle[0].payload[0].id + ")")
                ADB_assertTrue((firstResponseJson.requestId <> eventid), LINE_NUM, "assert response (1) verify request ID")

                ' Verify XDM data
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(2) is to send Edge event")
                ADB_assertTrue((Len(debugInfo.networkRequests[1].jsonObj.events[0].xdm.timestamp) > 10), LINE_NUM, "assert networkRequests(2) is to send Edge event with timestamp")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.identityMap.ECID <> invalid), LINE_NUM, "assert networkRequests(2) is to send Edge event with ecid")

                ' Verify identity map
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap <> invalid), LINE_NUM, "assert networkRequests(2) has identity map passed from the API")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap.EMAIL[0].id = "test@test.com"), LINE_NUM, "assert networkRequests(2) has identity map containing valid email id value")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap.EMAIL[0].authenticatedState = "ambiguous"), LINE_NUM, "assert networkRequests(2) has identity map containing EMAIL with authenticated state ambiguous")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap.EMAIL[0].primary = false), LINE_NUM, "assert networkRequests(2) has identity map containing EMAIL as not a primary id")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap.RIDA[0].id = "test-ad-id"), LINE_NUM, "assert networkRequests(2) has identity map containing valid RIDA id value")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap.RIDA[0].authenticatedState = "ambiguous"), LINE_NUM, "assert networkRequests(2) has identity map containing RIDA with authenticated state ambiguous")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.identityMap.RIDA[0].primary = false), LINE_NUM, "assert networkRequests(2) has identity map containing RIDA as not a primary id")

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

            aepSdk = ADB_retrieveSDKInstance()

            aepSdk.sendEvent({ key: "value1" })
            eventIdForFirstSendEvent = aepSdk._private.lastEventId

            aepSdk.sendEvent({ key: "value2" })
            eventIdForSecondSendEvent = aepSdk._private.lastEventId

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

            aepSdk = ADB_retrieveSDKInstance()

            aepSdk.sendEvent({ key: "value1" })
            eventIdForFirstSendEvent = aepSdk._private.lastEventId

            aepSdk.sendEvent({ key: "value2" })
            eventIdForSecondSendEvent = aepSdk._private.lastEventId

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)

            aepSdk.sendEvent({ key: "value3" })
            eventIdForThirdSendEvent = aepSdk._private.lastEventId

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

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)

            GetGlobalAA()._adb_integration_test_callback_result = invalid
            aepSdk.sendEvent({ key: "value" }, sub(context, result)
                GetGlobalAA()._adb_integration_test_callback_result = result
            end sub, {})

            eventIdForSendEvent = aepSdk._private.lastEventId

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

            aepSdk = ADB_retrieveSDKInstance()

            aepSdk.setExperienceCloudId(m._testECID)
            eventIdForSetExperienceCloudId = aepSdk._private.lastEventId

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

            aepSdk.sendEvent({ key: "value" })

            eventIdForSendEvent = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForSetExperienceCloudId] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = "12345678901234567890123456789012345678"), LINE_NUM, "assert ECID is persisted in Registry")
            end sub
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                ADB_assertTrue((ecid = "12345678901234567890123456789012345678"), LINE_NUM, "assert debugInfo.identity.ecid = 12345678901234567890123456789012345678")
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(1) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = "12345678901234567890123456789012345678"), LINE_NUM, "assert 12345678901234567890123456789012345678 is persisted in Registry")
            end sub

            return validator
        end function,

        TC_SDK_ecid_consistence: function() as dynamic

            ADB_persisteECIDInRegistry(m._testECID)

            aepSdk = ADB_retrieveSDKInstance()

            ADB_resetSDK(aepSdk)

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

            aepSdk.sendEvent({ key: "value" })

            eventIdForSendEvent = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = "12345678901234567890123456789012345678"), LINE_NUM, "assert ECID is persisted in Registry")
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))

                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(1) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")

                ecidInRegistry = ADB_getPersistedECID()
                ecid = debugInfo.identity.ecid
                ADB_assertTrue((ecid = "12345678901234567890123456789012345678"), LINE_NUM, "assert in-memory ECID is 12345678901234567890123456789012345678")
                ADB_assertTrue((ecidInRegistry = "12345678901234567890123456789012345678"), LINE_NUM, "assert persisted ECID is 12345678901234567890123456789012345678")
            end sub

            return validator
        end function,

    }

    instance.init()

    return instance
end function
