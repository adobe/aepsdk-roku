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
        mediaChannel: invalid,
        mediaPlayerName: invalid,
        mediaAppVersion: invalid,

        init: sub()
            test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
            m.configId = test_config.config_id
            m.mediaChannel = "channel_test"
            m.mediaPlayerName = "player_test"
            m.mediaAppVersion = "1.0.0"
            if _adb_isEmptyOrInvalidString(m.configId) then
                throw "Not found a valid config_id in test_config.json"
            end if
            if _adb_isEmptyOrInvalidString(m.mediaChannel) then
                throw "Not found a valid edgemedia_channel in test_config.json"
            end if
            if _adb_isEmptyOrInvalidString(m.mediaPlayerName) then
                throw "Not found a valid edgemedia_playerName in test_config.json"
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

            version$ = aepSdk.getVersion()

            ADB_assertTrue((version$ = "1.1.0-alpha"), LINE_NUM, "assert getVersion() = 1.1.0-alpha")

            return invalid
        end function,

        TC_SDK_setLogLevel_debug: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()
            aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

            eventIdForSetLogLevel = aepSdk._private.lastEventId

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
                "RIDA": [
                    {
                        "id": "test-ad-id",
                        "authenticatedState": "ambiguous",
                        "primary": false
                    }
                ],
                "EMAIL": [
                    {
                        "id": "test@test.com",
                        "authenticatedState": "ambiguous",
                        "primary": false
                    }
                ]
            }

            data = {
                "xdm": {
                    key: "value",
                    "identityMap": idMap
                },
                "data": {
                    "testKey": "testValue"
                }
            }
            aepSdk.sendEvent(data)

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

                expectedXDMData = { "EMAIL": [{ "authenticatedState": "ambiguous", "id": "test@test.com", "primary": false }], "RIDA": [{ "authenticatedState": "ambiguous", "id": "test-ad-id", "primary": false }] }
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
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(2) is to send Edge event with xdm data")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].data["testKey"] = "testValue"), LINE_NUM, "assert networkRequests(2) is to send Edge event with non-xdm data")
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

            data1 = {
                "xdm": {
                    key: "value1"
                }
            }
            aepSdk.sendEvent(data1)
            eventIdForFirstSendEvent = aepSdk._private.lastEventId

            data2 = {
                "xdm": {
                    key: "value2"
                }
            }
            aepSdk.sendEvent(data2)
            eventIdForSecondSendEvent = aepSdk._private.lastEventId

            validator = {}

            validator[eventIdForFirstSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                _ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 1), LINE_NUM, "assert requestQueue = 1")
                ADB_assertTrue((debugInfo.edge.requestQueue[0].requestId = eventid), LINE_NUM, "assert request ID is correct")
            end sub

            validator[eventIdForSecondSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                _ecid = debugInfo.identity.ecid
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

            data1 = {
                "xdm": {
                    key: "value1"
                }
            }
            aepSdk.sendEvent(data1)
            eventIdForFirstSendEvent = aepSdk._private.lastEventId

            data2 = {
                "xdm": {
                    key: "value2"
                }
            }
            aepSdk.sendEvent(data2)
            eventIdForSecondSendEvent = aepSdk._private.lastEventId

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)

            data3 = {
                "xdm": {
                    key: "value3"
                }
            }
            aepSdk.sendEvent(data3)
            eventIdForThirdSendEvent = aepSdk._private.lastEventId

            validator = {}

            validator[eventIdForFirstSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                _ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 1), LINE_NUM, "assert requestQueue = 1")
                ADB_assertTrue((debugInfo.edge.requestQueue[0].requestId = eventid), LINE_NUM, "assert request ID is correct")
            end sub

            validator[eventIdForSecondSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                _ecid = debugInfo.identity.ecid
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
                _secondResponseJson = ParseJson(debugInfo.networkRequests[1].response.body)
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response (2) returns 200")

                ' Send event 2
                ADB_assertTrue((debugInfo.networkRequests[2].jsonObj.events[0].xdm.key = "value2"), LINE_NUM, "assert networkRequests(3) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[2].jsonObj.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequests(3) is to send Edge event with ecid")
                _thirdResponseJson = ParseJson(debugInfo.networkRequests[2].response.body)
                ADB_assertTrue((debugInfo.networkRequests[2].response.code = 200), LINE_NUM, "assert response (3) returns 200")

                ' Send event 3
                ADB_assertTrue((debugInfo.networkRequests[3].jsonObj.events[0].xdm.key = "value3"), LINE_NUM, "assert networkRequests(4) is to send Edge event")
                ADB_assertTrue((debugInfo.networkRequests[3].jsonObj.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequests(4) is to send Edge event with ecid")
                _fourthResponseJson = ParseJson(debugInfo.networkRequests[3].response.body)
                ADB_assertTrue((debugInfo.networkRequests[3].response.code = 200), LINE_NUM, "assert response (4) returns 200")

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

            data = {
                "xdm": {
                    key: "value"
                }
            }
            aepSdk.sendEvent(data, sub(_context, result)
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

            data = {
                "xdm": {
                    key: "value"
                }
            }
            aepSdk.sendEvent(data)

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
                _eventid = debugInfo.eventid
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

            data = {
                "xdm": {
                    key: "value"
                }
            }
            aepSdk.sendEvent(data)

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

                _eventid = debugInfo.eventid
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

        TC_SDK_createMediaSession: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = m.mediaChannel
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = m.mediaPlayerName
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = m.mediaAppVersion

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId
            aepSdk.createMediaSession({
                "xdm": {
                    "eventType": "media.sessionStart"
                    "mediaCollection": {
                        "playhead": 0,
                        "sessionDetails": {
                            "streamType": "video",
                            "friendlyName": "test_media_name",
                            "hasResume": false,
                            "name": "test_media_id",
                            "length": 100,
                            "contentType": "vod"
                        }
                    }
                }
            })
            eventIdForCreateMediaSession = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
                ADB_assertTrue((debugInfo.configuration.media_channel = "channel_test"), LINE_NUM, "assert media_channel is valid")
                ADB_assertTrue((debugInfo.configuration.media_playerName = "player_test"), LINE_NUM, "assert media_playerName is valid")
                ADB_assertTrue((debugInfo.configuration.media_appVersion = "1.0.0"), LINE_NUM, "assert media_appVersion is valid")
            end sub

            validator[eventIdForCreateMediaSession] = sub(debugInfo)
                clientSessionId = debugInfo.eventData.clientSessionId
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "createMediaSession"), LINE_NUM, "assert debugInfo.apiName = createMediaSession")
                ADB_assertTrue((clientSessionId = debugInfo.media.clientSessionId), LINE_NUM, "assert clientSessionId is stored correctly")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, "assert networkRequests.count() = 2")

                ' the First request is to fetch ECID
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.eventType = "media.sessionStart"), LINE_NUM, "assert eventType = media.sessionStart")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.playhead = 0), LINE_NUM, "assert playhead = 0")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm._id <> invalid), LINE_NUM, "assert _id <> invalid")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.appVersion = "1.0.0"), LINE_NUM, "assert appVersion = 1.0.0")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.channel = "channel_test"), LINE_NUM, "assert channel = channel_test")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.contentType = "vod"), LINE_NUM, "assert contentType = vod")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.friendlyName = "test_media_name"), LINE_NUM, "assert friendlyName = test_media_name")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.hasResume = false), LINE_NUM, "assert hasResume = false")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.length = 100), LINE_NUM, "assert length = 100")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.name = "test_media_id"), LINE_NUM, "assert name = test_media_id")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.playerName = "player_test"), LINE_NUM, "assert playerName = player_test")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.streamType = "video"), LINE_NUM, "assert streamType = video")

                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.identityMap.ECID <> invalid), LINE_NUM, "assert include ECID in identityMap")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.implementationDetails <> invalid), LINE_NUM, "assert include implementationDetails")
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response code = 200")

                ADB_assertTrue((debugInfo.networkRequests[1].url.StartsWith("https://edge.adobedc.net/ee/va/v1/sessionStart?configId=")), LINE_NUM, "assert url")

                ADB_assertTrue((debugInfo.networkRequests[1].response.body.Instr(debugInfo.media.backendSessionId) > 0), LINE_NUM, "assert backendSerssionId is extracted correctly")
            end sub

            return validator
        end function,

        TC_SDK_createMediaSessionWithConfig: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = m.mediaChannel
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = m.mediaPlayerName
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = m.mediaAppVersion

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId
            aepSdk.createMediaSession({
                "xdm": {
                    "eventType": "media.sessionStart"
                    "mediaCollection": {
                        "playhead": 0,
                        "sessionDetails": {
                            "streamType": "video",
                            "friendlyName": "test_media_name",
                            "hasResume": false,
                            "name": "test_media_id",
                            "length": 100,
                            "contentType": "vod"
                        }
                    }
                }
            }, {
                "config.channel": "test_channel_session",
                "config.adpinginterval": 5,
                "config.mainpinginterval": 35,
            })
            eventIdForCreateMediaSession = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
                ADB_assertTrue((debugInfo.configuration.media_channel = "channel_test"), LINE_NUM, "assert media_channel is valid")
                ADB_assertTrue((debugInfo.configuration.media_playerName = "player_test"), LINE_NUM, "assert media_playerName is valid")
                ADB_assertTrue((debugInfo.configuration.media_appVersion = "1.0.0"), LINE_NUM, "assert media_appVersion is valid")
            end sub

            validator[eventIdForCreateMediaSession] = sub(debugInfo)
                clientSessionId = debugInfo.eventData.clientSessionId
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "createMediaSession"), LINE_NUM, "assert debugInfo.apiName = createMediaSession")
                ADB_assertTrue((clientSessionId = debugInfo.media.clientSessionId), LINE_NUM, "assert clientSessionId is stored correctly")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, "assert networkRequests.count() = 2")

                ' the First request is to fetch ECID
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.eventType = "media.sessionStart"), LINE_NUM, "assert eventType = media.sessionStart")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.playhead = 0), LINE_NUM, "assert playhead = 0")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm._id <> invalid), LINE_NUM, "assert _id <> invalid")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.appVersion = "1.0.0"), LINE_NUM, "assert appVersion = 1.0.0")
                ' session level config should be used
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.channel = "test_channel_session"), LINE_NUM, "assert channel = test_channel_session")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.contentType = "vod"), LINE_NUM, "assert contentType = vod")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.friendlyName = "test_media_name"), LINE_NUM, "assert friendlyName = test_media_name")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.hasResume = false), LINE_NUM, "assert hasResume = false")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.length = 100), LINE_NUM, "assert length = 100")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.name = "test_media_id"), LINE_NUM, "assert name = test_media_id")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.playerName = "player_test"), LINE_NUM, "assert playerName = player_test")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.events[0].xdm.mediaCollection.sessionDetails.streamType = "video"), LINE_NUM, "assert streamType = video")

                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.identityMap.ECID <> invalid), LINE_NUM, "assert include ECID in identityMap")
                ADB_assertTrue((debugInfo.networkRequests[1].jsonObj.xdm.implementationDetails <> invalid), LINE_NUM, "assert include implementationDetails")
                ADB_assertTrue((debugInfo.networkRequests[1].response.code = 200), LINE_NUM, "assert response code = 200")

                ADB_assertTrue((debugInfo.networkRequests[1].url.StartsWith("https://edge.adobedc.net/ee/va/v1/sessionStart?configId=")), LINE_NUM, "assert url")

                ADB_assertTrue((debugInfo.networkRequests[1].response.body.Instr(debugInfo.media.backendSessionId) > 0), LINE_NUM, "assert backendSerssionId is extracted correctly")
            end sub

            return validator
        end function,

        TC_SDK_sendMediaEvent: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = m.mediaChannel
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = m.mediaPlayerName
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = m.mediaAppVersion

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId
            aepSdk.createMediaSession({
                "xdm": {
                    "eventType": "media.sessionStart"
                    "mediaCollection": {
                        "playhead": 0,
                        "sessionDetails": {
                            "streamType": "video",
                            "friendlyName": "test_media_name",
                            "hasResume": false,
                            "name": "test_media_id",
                            "length": 100,
                            "contentType": "vod"
                        }
                    }
                }
            })

            eventIdForCreateMediaSession = aepSdk._private.lastEventId

            aepSdk.sendMediaEvent({
                "xdm": {
                    "eventType": "media.play",
                    "mediaCollection": {
                        "playhead": 123,
                    }
                }
            })
            eventIdForSendMediaEvent = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
                ADB_assertTrue((debugInfo.configuration.media_channel = "channel_test"), LINE_NUM, "assert media_channel is valid")
                ADB_assertTrue((debugInfo.configuration.media_playerName = "player_test"), LINE_NUM, "assert media_playerName is valid")
                ADB_assertTrue((debugInfo.configuration.media_appVersion = "1.0.0"), LINE_NUM, "assert media_appVersion is valid")
            end sub

            validator[eventIdForCreateMediaSession] = sub(debugInfo)
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, "assert requests = 2")

                ADB_assertTrue((debugInfo.networkRequests[1].response.body.Instr(debugInfo.media.backendSessionId) > 0), LINE_NUM, "assert backendSerssionId is extracted correctly")
            end sub

            validator[eventIdForSendMediaEvent] = sub(debugInfo)
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert requests = 1")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm._id <> invalid), LINE_NUM, "assert _id <> invalid")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.eventType = "media.play"), LINE_NUM, "assert eventType = media.play")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.playhead = 123), LINE_NUM, "assert playhead = 123")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionID = debugInfo.media.backendSessionId), LINE_NUM, "assert sessionID = backendSessionId")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.xdm.identityMap.ECID <> invalid), LINE_NUM, "assert include ECID in identityMap")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.xdm.implementationDetails <> invalid), LINE_NUM, "assert include implementationDetails")

                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 204), LINE_NUM, "assert response code = 204")

                ADB_assertTrue((debugInfo.networkRequests[0].url.StartsWith("https://edge.adobedc.net/ee/va/v1/play?configId=")), LINE_NUM, "assert url")

            end sub

            return validator
        end function,

        TC_SDK_sendMediaEvent_sessionEnd: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = m.mediaChannel
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = m.mediaPlayerName
            configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = m.mediaAppVersion

            ADB_CONSTANTS = AdobeAEPSDKConstants()
            aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId
            aepSdk.createMediaSession({
                "xdm": {
                    "eventType": "media.sessionStart"
                    "mediaCollection": {
                        "playhead": 0,
                        "sessionDetails": {
                            "streamType": "video",
                            "friendlyName": "test_media_name",
                            "hasResume": false,
                            "name": "test_media_id",
                            "length": 100,
                            "contentType": "vod"
                        }
                    }
                }
            })
            aepSdk.sendMediaEvent({
                "xdm": {
                    "eventType": "media.sessionEnd",
                    "mediaCollection": {
                        "playhead": 100,
                    }
                }
            })
            eventIdForSessionEnd = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, "assert debugInfo.apiName = setConfiguration")
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, "assert edge_configid is valid")
                ADB_assertTrue((debugInfo.configuration.media_channel = "channel_test"), LINE_NUM, "assert media_channel is valid")
                ADB_assertTrue((debugInfo.configuration.media_playerName = "player_test"), LINE_NUM, "assert media_playerName is valid")
                ADB_assertTrue((debugInfo.configuration.media_appVersion = "1.0.0"), LINE_NUM, "assert media_appVersion is valid")
            end sub

            validator[eventIdForSessionEnd] = sub(debugInfo)
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendMediaEvent"), LINE_NUM, "assert debugInfo.apiName = sendMediaEvent")

                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests.count() = 1")

                ADB_assertTrue((debugInfo.media.clientSessionId = ""), LINE_NUM, "assert clientSessionId is empty")
                ADB_assertTrue((debugInfo.media.clientSessionId = ""), LINE_NUM, "assert clientSessionId is empty")
                ADB_assertTrue((debugInfo.media.existActiveSession = false), LINE_NUM, "assert no active session")
            end sub

            return validator
        end function,
    }

    instance.init()

    return instance
end function
