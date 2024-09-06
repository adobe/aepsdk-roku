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
        datastreamIdOverride: invalid,
        datasetIdOverride: invalid,
        originalSDKData: invalid,

        init: sub()
            test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
            m.configId = test_config.config_id
            m.datastreamIdOverride = test_config.datastream_id_override
            m.datasetIdOverride = test_config.dataset_id_override
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
            _adb_integrationTestUtil_reset()
            aepSdk = ADB_retrieveSDKInstance()
            ADB_resetSDK(aepSdk)
        end sub,

        TS_afterEach: sub()
            print "T_afterEach"
        end sub,

        TC_SDK_getVersion: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            version$ = aepSdk.getVersion()

            ADB_assertTrue((version$ = ADB_testSDKVersion()), LINE_NUM, "assert getVersion() = " + ADB_testSDKVersion())

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

        TC_SDK_getECID_validConfig_returnsECID: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)

            ecidInRegistry = ADB_getPersistedECID()
            ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, "assert ecid is not persisted in Registry")

            GetGlobalAA()._adb_integration_test_callback_result_ecid = invalid
            aepSdk.getExperienceCloudId(sub(_context, ecid)
                GetGlobalAA()._adb_integration_test_callback_result_ecid = ecid
            end sub, m)

            eventIdForGetECID = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForGetECID] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid

                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "getExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = getExperienceCloudId")

                eventData = debugInfo.eventData
                ADB_assertTrue((eventData = invalid), LINE_NUM, "Event Data should be invalid")

                ' Verify fetch ECID request since no ECID in persistence
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].query.identity.fetch[0] = "ECID"), LINE_NUM, "assert networkRequests(1) is to fetch ECID")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response (1) returns 200")
                firstResponseJson = ParseJson(debugInfo.networkRequests[0].response.body)
                ADB_assertTrue((firstResponseJson.handle[0].payload[0].id <> invalid), LINE_NUM, "ECID should not be invalid")
                ADB_assertTrue((firstResponseJson.handle[0].payload[0].id = ecid), LINE_NUM, "Expected: (" + ecid + ") != Actual: (" + firstResponseJson.handle[0].payload[0].id + ")")
                ADB_assertTrue((firstResponseJson.requestId <> eventid), LINE_NUM, "assert response (1) verify request ID")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, "assert ecid is persisted in Registry")

                actualEcidFromAPI = GetGlobalAA()._adb_integration_test_callback_result_ecid
                ADB_assertTrue((actualEcidFromAPI = ecid), LINE_NUM, "assert ecid returned by getExperienceCloudId is same as persisted ecid")

            end sub

            return validator
        end function,

        TC_SDK_getECID_configNotSet_returnsInvalid: function() as dynamic
            aepSdk = ADB_retrieveSDKInstance()


            ecidInRegistry = ADB_getPersistedECID()
            ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, "assert ecid is not persisted in Registry")

            GetGlobalAA()._adb_integration_test_callback_result_ecid = invalid
            aepSdk.getExperienceCloudId(sub(_context, ecid)
                GetGlobalAA()._adb_integration_test_callback_result_ecid = ecid
            end sub, m)

            eventIdForGetECID = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForGetECID] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "getExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = getExperienceCloudId")

                eventData = debugInfo.eventData
                ADB_assertTrue((eventData = invalid), LINE_NUM, "Event Data should be invalid")

                ' Verify fetch ECID request is not called as missing required configuration
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, "assert valid ecid is not persisted in Registry")

                actualEcidFromAPI = GetGlobalAA()._adb_integration_test_callback_result_ecid
                ADB_assertTrue((actualEcidFromAPI = invalid), LINE_NUM, "assert ecid returned by getExperienceCloudId is invalid")
            end sub

            return validator
        end function,

        TC_SDK_getECID_invalidConfig_returnsInvalid: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = "DummyDatastreamId"

            aepSdk.updateConfiguration(configuration)

            ecidInRegistry = ADB_getPersistedECID()
            ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, "assert ecid is not persisted in Registry")

            GetGlobalAA()._adb_integration_test_callback_result_ecid = invalid
            aepSdk.getExperienceCloudId(sub(_context, ecid)
                GetGlobalAA()._adb_integration_test_callback_result_ecid = ecid
            end sub, m)

            eventIdForGetECID = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForGetECID] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "getExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = getExperienceCloudId")

                eventData = debugInfo.eventData
                ADB_assertTrue((eventData = invalid), LINE_NUM, "Event Data should be invalid")

                ' Verify fetch ECID request since no ECID in persistence
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].query.identity.fetch[0] = "ECID"), LINE_NUM, "assert networkRequests(1) is to fetch ECID")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 400), LINE_NUM, "assert response (1) returns 200")
                firstResponseJson = ParseJson(debugInfo.networkRequests[0].response.body)
                ADB_assertTrue((firstResponseJson = invalid), LINE_NUM, "Response body is invalid")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = invalid), LINE_NUM, ADB_generateErrorMessage("assert ecid is not persisted in Registry", "invalid", ecidInRegistry))

                actualEcidFromAPI = GetGlobalAA()._adb_integration_test_callback_result_ecid
                ADB_assertTrue((actualEcidFromAPI = invalid), LINE_NUM, ADB_generateErrorMessage("assert ecid returned by getExperienceCloudId", "invalid", actualEcidFromAPI))
            end sub

            return validator
        end function,

        TC_SDK_getECID_afterSetECID: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)

            aepSdk.setExperienceCloudId("ECIDFromSetECIDAPI")

            GetGlobalAA()._adb_integration_test_callback_result_ecid = invalid
            aepSdk.getExperienceCloudId(sub(_context, ecid)
                GetGlobalAA()._adb_integration_test_callback_result_ecid = ecid
            end sub, m)

            eventIdForGetECID = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForGetECID] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid

                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "getExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = getExperienceCloudId")

                eventData = debugInfo.eventData
                ADB_assertTrue((eventData = invalid), LINE_NUM, "Event Data should be invalid")

                ' Verify fetch ECID request since no ECID in persistence
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, ADB_generateErrorMessage("assert ecid matches the ecid value persisted in Registry", ecid, ecidInRegistry))

                actualEcidFromAPI = GetGlobalAA()._adb_integration_test_callback_result_ecid
                ADB_assertTrue((actualEcidFromAPI = "ECIDFromSetECIDAPI"), LINE_NUM, ADB_generateErrorMessage("assert ecid returned by getExperienceCloudId is same as set by setExperienceCloudId", "ECIDFromSetECIDAPI", actualEcidFromAPI))
            end sub

            return validator
        end function,

        TC_SDK_getECID_ecidInPersistence: function() as dynamic
            ''' Mock ECID in persistence
            ADB_persistECIDInRegistry("AlreadyPresentECID")

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}
            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)

            GetGlobalAA()._adb_integration_test_callback_result_ecid = invalid
            aepSdk.getExperienceCloudId(sub(_context, ecid)
                GetGlobalAA()._adb_integration_test_callback_result_ecid = ecid
            end sub, m)

            eventIdForGetECID = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForGetECID] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid

                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "getExperienceCloudId"), LINE_NUM, "assert debugInfo.apiName = getExperienceCloudId")

                eventData = debugInfo.eventData
                ADB_assertTrue((eventData = invalid), LINE_NUM, "Event Data should be invalid")

                ' Verify no fetch ECID request is sent since ECID is in persistence
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, ADB_generateErrorMessage("assert ecid matches the ecid value persisted in Registry", ecid, ecidInRegistry))

                actualEcidFromAPI = GetGlobalAA()._adb_integration_test_callback_result_ecid
                ADB_assertTrue((actualEcidFromAPI = "AlreadyPresentECID"), LINE_NUM, "assert ecid returned by getExperienceCloudId is same as persisted ecid")
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


                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests = 1 [sendEvent]")

                networkRequest1 = debugInfo.networkRequests[0]
                jsonBody1 = networkRequest1.jsonObj

                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, "assert response (2) returns 200")

                secondResponseJson = ParseJson(networkRequest1.response.body)
                ADB_assertTrue((secondResponseJson.requestId = eventid), LINE_NUM, "assert response (2) verify request ID")

                ADB_assertTrue((jsonBody1.xdm.implementationDetails.name = "https://ns.adobe.com/experience/mobilesdk/roku"), LINE_NUM, "assert networkRequests(1) is to send Edge event with implementationDetails")

                ' since no ECID is present request should not have top level identity map generated by SDK
                ADB_assertTrue((jsonBody1.xdm.identityMap = invalid), LINE_NUM, "assert networkRequests(1) is to send Edge event without ecid")

                ' Verify XDM data
                ADB_assertTrue((jsonBody1.events[0].xdm.key = "value"), LINE_NUM, "assert networkRequests(2) is to send Edge event with xdm data")
                ADB_assertTrue((jsonBody1.events[0].data["testKey"] = "testValue"), LINE_NUM, "assert networkRequests(2) is to send Edge event with non-xdm data")
                ADB_assertTrue((Len(jsonBody1.events[0].xdm.timestamp) > 10), LINE_NUM, "assert networkRequests(2) is to send Edge event with timestamp")

                ' Verify custom identity map
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap <> invalid), LINE_NUM, "assert networkRequests(2) has identity map passed from the API")
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap.EMAIL[0].id = "test@test.com"), LINE_NUM, "assert networkRequests(2) has identity map containing valid email id value")
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap.EMAIL[0].authenticatedState = "ambiguous"), LINE_NUM, "assert networkRequests(2) has identity map containing EMAIL with authenticated state ambiguous")
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap.EMAIL[0].primary = false), LINE_NUM, "assert networkRequests(2) has identity map containing EMAIL as not a primary id")
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap.RIDA[0].id = "test-ad-id"), LINE_NUM, "assert networkRequests(2) has identity map containing valid RIDA id value")
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap.RIDA[0].authenticatedState = "ambiguous"), LINE_NUM, "assert networkRequests(2) has identity map containing RIDA with authenticated state ambiguous")
                ADB_assertTrue((jsonBody1.events[0].xdm.identityMap.RIDA[0].primary = false), LINE_NUM, "assert networkRequests(2) has identity map containing RIDA as not a primary id")

                ' ECID is extracted from the response and persisted in the registry
                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, ADB_generateErrorMessage("assert ecid matches the ecid value persisted in Registry", ecidInRegistry, ecid))
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
                queuedRequestId = debugInfo.edge.requestQueue[0]._requestId
                ADB_assertTrue((queuedRequestId = eventid), LINE_NUM, ADB_generateErrorMessage("eventID should match the queued request", eventid, queuedRequestId))
            end sub

            validator[eventIdForSecondSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                _ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 2), LINE_NUM, "assert requestQueue = 2")
                queuedRequestId = debugInfo.edge.requestQueue[1]._requestId
                ADB_assertTrue((queuedRequestId = eventid), LINE_NUM, ADB_generateErrorMessage("eventID should match the queued request", eventid, queuedRequestId))
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
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

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
                queuedRequestId = debugInfo.edge.requestQueue[0]._requestId
                ADB_assertTrue((queuedRequestId = eventid), LINE_NUM, ADB_generateErrorMessage("eventID should match the queued request", eventid, queuedRequestId))
                end sub

            validator[eventIdForSecondSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                _ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 0), LINE_NUM, "assert networkRequests = 0")
                ADB_assertTrue((debugInfo.edge.requestQueue <> invalid and debugInfo.edge.requestQueue.count() = 2), LINE_NUM, "assert requestQueue = 2")
                queuedRequestId = debugInfo.edge.requestQueue[1]._requestId
                ADB_assertTrue((queuedRequestId = eventid), LINE_NUM, ADB_generateErrorMessage("eventID should match the queued request", eventid, queuedRequestId))
            end sub

            ' updateConfiguration will also trigger processQueuedRequests so we will see network requests for all queued events
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, ADB_generateErrorMessage("Network requests sent ", 1, FormatJson(debugInfo.networkRequests.count())))

                networkRequest1 = debugInfo.networkRequests[0] ' sendEvent 1

                ' Triggered by updateConfiguration API which will process the queued events.
                ' Send event 1
                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, "assert response (1) returns 200")

                jsonObj1 = networkRequest1.jsonObj
                ADB_assertTrue((jsonObj1.events[0].xdm.key = "value1"), LINE_NUM, "assert networkRequest (1) is sent with correct xdm data.")
                ADB_assertTrue((jsonObj1.xdm.identityMap = invalid), LINE_NUM, "assert networkRequest (1) is to sent without ecid.")

                ' processQueuedRequests will not process further queued event (sendEvent 2) as ECID was not available for sendEvent 1
                ' and response of SendEvent 1 will set the ECID and we need to process the response so that sendEvent 2 and all the other subsequent requests will have the ECID.
                ' Send event 2 will be processed next time the processQueuedRequests is called
            end sub

            validator[eventIdForThirdSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid

                ' Both the requests are triggered by send Event 3
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 2), LINE_NUM, ADB_generateErrorMessage("Network requests sent ", 2, FormatJson(debugInfo.networkRequests.count())))

                ' Send event 2
                networkRequest1 = debugInfo.networkRequests[0] ' sendEvent 2
                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, "assert networkRequest (1) returns 200")

                jsonObj1 = networkRequest1.jsonObj
                ADB_assertTrue((jsonObj1.events[0].xdm.key = "value2"), LINE_NUM, "assert networkRequest (1) is to send Edge event")
                ADB_assertTrue((jsonObj1.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequest (1) is to send Edge event with ecid")

                ' Send event 3
                networkRequest2 = debugInfo.networkRequests[1] ' sendEvent 3
                ADB_assertTrue((networkRequest2.response.code = 200), LINE_NUM, "assert networkRequest (2) returns 200")

                jsonObj2 = networkRequest2.jsonObj
                ADB_assertTrue((jsonObj2.events[0].xdm.key = "value3"), LINE_NUM, "assert networkRequest (2) is has correct xdm data")
                ADB_assertTrue((jsonObj2.xdm.identityMap.ECID[0].id = ecid), LINE_NUM, "assert networkRequest (2) has ecid")

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
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, ADB_generateErrorMessage("Network requests sent ", 1, FormatJson(debugInfo.networkRequests.count())))

                networkRequest1 = debugInfo.networkRequests[0]
                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, ADB_generateErrorMessage("assert response (1) returns 200", 200, networkRequest1.response.code))

                jsonObj1 = networkRequest1.jsonObj
                ADB_assertTrue((jsonObj1.events[0].xdm.key = "value"), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with correct xdm data", "value", jsonObj1.events[0].xdm.key))

                responseJson1 = ParseJson(networkRequest1.response.body)

                ADB_assertTrue((responseJson1.requestId = eventid), LINE_NUM, ADB_generateErrorMessage("assert response (1) verify request ID", eventid, responseJson1.requestId))

                callbackResult = GetGlobalAA()._adb_integration_test_callback_result
                ADB_assertTrue((callbackResult.code = 200), LINE_NUM, ADB_generateErrorMessage("assert callback received code", 200, callbackResult.code))
                ADB_assertTrue((not _adb_isEmptyOrInvalidString(callbackResult.message)), LINE_NUM, ADB_generateErrorMessage("assert callback received message", "not empty or invalid", callbackResult.message))
            end sub

            return validator
        end function,

        TC_SDK_sendEventWithDatastreamIdOverride: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

            data = {
                "xdm": {
                    "eventType": "integrationTest.run",
                    "_obumobile5": {
                      "page" : {
                        "name": "RokuIntegrationTest(TC_SDK_sendEventWithDatastreamIdOverride)"
                      }
                    }
                },
                "data": {
                    "testKey": "testValue"
                },
                "config": {
                    "datastreamIdOverride": m.datastreamIdOverride
                }
            }
            aepSdk.sendEvent(data)

            eventIdForSendEvent = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, ADB_generateErrorMessage("API name", "setConfiguration", debugInfo.apiName))
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, ADB_generateErrorMessage("assert edge_configid is valid", "valid", debugInfo.configuration.edge_configid))
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid

                test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
                configId = test_config.config_id
                datastreamIdOverride = test_config.datastream_id_override

                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, ADB_generateErrorMessage("assert debugInfo.apiName", "sendEvent", debugInfo.apiName))

                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, ADB_generateErrorMessage("Network requests sent ", 1, FormatJson(debugInfo.networkRequests.count())))

                networkRequest1 = debugInfo.networkRequests[0]

                ' Verify URL contains datastreamIdOverride
                ADB_assertTrue((networkRequest1.url.Instr("configId="+datastreamIdOverride) > 0), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) url contains datastreamIdOverride value", "configId="+datastreamIdOverride, networkRequest1.url))
                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, ADB_generateErrorMessage("assert response code for network request (1)", 200, networkRequest1.response.code))

                firstResponseJson = ParseJson(networkRequest1.response.body)
                ADB_assertTrue((firstResponseJson.requestId = eventid), LINE_NUM, ADB_generateErrorMessage("assert response (1) verify request ID", eventid, firstResponseJson.requestId))

                ' Verify XDM data
                jsonObj1 = networkRequest1.jsonObj
                actualEventType = jsonObj1.events[0].xdm.eventType
                ADB_assertTrue((actualEventType = "integrationTest.run"), LINE_NUM, ADB_generateErrorMessage("XDM page data", "integrationTest.run", actualEventType))

                expectedPageDataXDM = {
                    "page" : {
                        "name": "RokuIntegrationTest(TC_SDK_sendEventWithDatastreamIdOverride)"
                    }
                }
                expectedPageDataXDMJson = FormatJson(expectedPageDataXDM)
                actualPageDataXDMJson = FormatJson(jsonObj1.events[0].xdm["_obumobile5"])
                ADB_assertTrue((actualPageDataXDMJson = expectedPageDataXDMJson), LINE_NUM, ADB_generateErrorMessage("Actual page data XDM", expectedPageDataXDMJson, actualPageDataXDMJson))

                ADB_assertTrue((jsonObj1.events[0].data["testKey"] = "testValue"), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with correct xdm data", "testValue", jsonObj1.events[0].data["testKey"]))
                ADB_assertTrue((Len(jsonObj1.events[0].xdm.timestamp) > 10), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with timestamp", "timestamp > 10", jsonObj1.events[0].xdm.timestamp))
                ADB_assertTrue((jsonObj1.xdm.identityMap = invalid), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent without ecid/identityMap", "invalid", jsonObj1.xdm.identityMap))
                ADB_assertTrue((jsonObj1.xdm.implementationDetails.name = "https://ns.adobe.com/experience/mobilesdk/roku"), LINE_NUM, "assert networkRequests(2) is to send Edge event with implementationDetails")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, ADB_generateErrorMessage("assert ecid matches the ecid value persisted in Registry", ecidInRegistry, ecid))

                ' Verify meta map
                expectedMeta = {
                    "sdkConfig": {
                        "datastream": {
                            "original": configId
                        }
                    }
                }

                expectedMetaJson = FormatJson(expectedMeta)
                actualMetaJson = FormatJson(jsonObj1.meta)
                ADB_assertTrue((actualMetaJson = actualMetaJson), LINE_NUM, ADB_generateErrorMessage("Assert metadata", expectedMetaJson, actualMetaJson))
            end sub

            return validator
        end function,

        TC_SDK_sendEventWithDatastreamConfigOverride: function() as dynamic

            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

            data = {
                "xdm": {
                    "eventType": "integrationTest.run",
                    "_obumobile5": {
                      "page" : {
                        "name": "RokuIntegrationTest(TC_SDK_sendEventWithDatastreamConfigOverride)"
                      }
                    }
                },
                "data": {
                    "testKey": "testValue"
                },
                "config": {
                    "datastreamConfigOverride" : {
                        "com_adobe_experience_platform": {
                          "datasets": {
                            "event": {
                              "datasetId": m.datasetIdOverride
                            }
                          }
                        }
                      }
                }
            }
            aepSdk.sendEvent(data)

            eventIdForSendEvent = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, ADB_generateErrorMessage("API name", "setConfiguration", debugInfo.apiName))
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, ADB_generateErrorMessage("assert edge_configid is valid", "valid", debugInfo.configuration.edge_configid))
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid

                test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
                configId = test_config.config_id
                datasetIdOverride = test_config.dataset_id_override

                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, ADB_generateErrorMessage("assert debugInfo.apiName", "sendEvent", debugInfo.apiName))

                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, ADB_generateErrorMessage("Network requests sent ", 1, FormatJson(debugInfo.networkRequests.count())))

                networkRequest1 = debugInfo.networkRequests[0]
                ' Verify URL contains datastreamIdOverride
                ADB_assertTrue((networkRequest1.url.Instr("configId="+configId) > 0), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) url contains datastreamIdOverride value", "configId="+configId, networkRequest1.url))

                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, ADB_generateErrorMessage("assert response code for network request (1)", 200, networkRequest1.response.code))
                firstResponseJson = ParseJson(networkRequest1.response.body)
                ADB_assertTrue((firstResponseJson.requestId = eventid), LINE_NUM, ADB_generateErrorMessage("assert response (1) verify request ID", eventid, firstResponseJson.requestId))

                ' Verify XDM data
                jsonObj1 = networkRequest1.jsonObj
                actualEventType = jsonObj1.events[0].xdm.eventType
                ADB_assertTrue((actualEventType = "integrationTest.run"), LINE_NUM, ADB_generateErrorMessage("XDM page data", "integrationTest.run", actualEventType))

                expectedPageDataXDM = {
                    "page" : {
                        "name": "RokuIntegrationTest(TC_SDK_sendEventWithDatastreamConfigOverride)"
                    }
                }
                actualPageDataXDMJson = FormatJson(jsonObj1.events[0].xdm["_obumobile5"])
                expectedPageDataXDMJson = FormatJson(expectedPageDataXDM)
                ADB_assertTrue((actualPageDataXDMJson = expectedPageDataXDMJson), LINE_NUM, ADB_generateErrorMessage("Actual page data XDM", expectedPageDataXDMJson, actualPageDataXDMJson))

                ADB_assertTrue((jsonObj1.events[0].data["testKey"] = "testValue"), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with correct xdm data", "testValue", jsonObj1.events[0].data["testKey"]))
                ADB_assertTrue((Len(jsonObj1.events[0].xdm.timestamp) > 10), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with timestamp", "timestamp > 10", jsonObj1.events[0].xdm.timestamp))
                ADB_assertTrue((jsonObj1.xdm.identityMap = invalid), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent without ecid/identityMap", "invalid", jsonObj1.xdm.identityMap))
                ADB_assertTrue((jsonObj1.xdm.implementationDetails.name = "https://ns.adobe.com/experience/mobilesdk/roku"), LINE_NUM, "assert networkRequests(2) is to send Edge event with implementationDetails")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, ADB_generateErrorMessage("assert ecid matches the ecid value persisted in Registry", ecidInRegistry, ecid))

                ' Verify meta map
                expectedMeta = {
                    "configOverrides":{
                        "com_adobe_experience_platform": {
                            "datasets": {
                                "event": {
                                    "datasetId": datasetIdOverride
                                }
                            }
                        }
                    }
                }

                expectedMetaJson = FormatJson(expectedMeta)
                actualMetaJson = FormatJson(jsonObj1.meta)
                ADB_assertTrue((actualMetaJson = actualMetaJson), LINE_NUM, ADB_generateErrorMessage("Assert metadata", expectedMetaJson, actualMetaJson))
            end sub

            return validator
        end function,

        TC_SDK_sendEventWithDatastreamIdAndConfigOverride: function() as dynamic
            aepSdk = ADB_retrieveSDKInstance()

            ADB_CONSTANTS = AdobeAEPSDKConstants()

            configuration = {}

            configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = m.configId

            aepSdk.updateConfiguration(configuration)
            eventIdForUpdateConfiguration = aepSdk._private.lastEventId

            data = {
                "xdm": {
                    "eventType": "integrationTest.run",
                    "_obumobile5": {
                      "page" : {
                        "name": "RokuIntegrationTest(TC_SDK_sendEventWithDatastreamIdAndConfigOverride)"
                      }
                    }
                },
                "data": {
                    "testKey": "testValue"
                },
                "config": {
                    "datastreamIdOverride": m.datastreamIdOverride,
                    "datastreamConfigOverride" : {
                        "com_adobe_experience_platform": {
                          "datasets": {
                            "event": {
                              "datasetId": m.datasetIdOverride
                            }
                          }
                        }
                      }
                }
            }
            aepSdk.sendEvent(data)

            eventIdForSendEvent = aepSdk._private.lastEventId

            validator = {}
            validator[eventIdForUpdateConfiguration] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "setConfiguration"), LINE_NUM, ADB_generateErrorMessage("API name", "setConfiguration", debugInfo.apiName))
                ADB_assertTrue((debugInfo.configuration.edge_configid <> invalid and Len(debugInfo.configuration.edge_configid) > 10), LINE_NUM, ADB_generateErrorMessage("assert edge_configid is valid", "valid", debugInfo.configuration.edge_configid))
            end sub

            validator[eventIdForSendEvent] = sub(debugInfo)
                ' _adb_logInfo("start to validate setLogLevel operation with debugInfo: " + FormatJson(debugInfo))
                ecid = debugInfo.identity.ecid
                eventid = debugInfo.eventid

                test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
                configId = test_config.config_id
                datastreamIdOverride = test_config.datastream_id_override
                datasetIdOverride = test_config.dataset_id_override

                ADB_assertTrue((debugInfo <> invalid and debugInfo.apiName = "sendEvent"), LINE_NUM, "assert debugInfo.apiName = sendEvent")

                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, ADB_generateErrorMessage("Network requests sent ", 1, FormatJson(debugInfo.networkRequests.count())))

                networkRequest1 = debugInfo.networkRequests[0]

                ' Verify URL contains datastreamIdOverride
                ADB_assertTrue((networkRequest1.url.Instr("configId="+datastreamIdOverride) > 0), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) url contains datastreamIdOverride value", "configId="+datastreamIdOverride, networkRequest1.url))
                ADB_assertTrue((networkRequest1.response.code = 200), LINE_NUM, ADB_generateErrorMessage("assert response code for network request (1)", 200, networkRequest1.response.code))

                firstResponseJson = ParseJson(networkRequest1.response.body)
                ADB_assertTrue((firstResponseJson.requestId = eventid), LINE_NUM, ADB_generateErrorMessage("assert response (1) verify request ID", eventid, firstResponseJson.requestId))

                ' Verify XDM data
                jsonObj1 = networkRequest1.jsonObj
                actualEventType = jsonObj1.events[0].xdm.eventType
                ADB_assertTrue((actualEventType = "integrationTest.run"), LINE_NUM, ADB_generateErrorMessage("XDM page data", "integrationTest.run", actualEventType))

                expectedPageDataXDM = {
                    "page" : {
                        "name": "RokuIntegrationTest(TC_SDK_sendEventWithDatastreamIdAndConfigOverride)"
                    }
                }

                expectedPageDataXDMJson = FormatJson(expectedPageDataXDM)
                actualPageDataXDMJson = FormatJson(jsonObj1.events[0].xdm["_obumobile5"])
                ADB_assertTrue((actualPageDataXDMJson = expectedPageDataXDMJson), LINE_NUM, ADB_generateErrorMessage("Actual page data XDM", expectedPageDataXDMJson, actualPageDataXDMJson))

                ADB_assertTrue((jsonObj1.events[0].data["testKey"] = "testValue"), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with correct xdm data", "testValue", jsonObj1.events[0].data["testKey"]))
                ADB_assertTrue((Len(jsonObj1.events[0].xdm.timestamp) > 10), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent with timestamp", "timestamp > 10", jsonObj1.events[0].xdm.timestamp))
                ADB_assertTrue((jsonObj1.xdm.identityMap = invalid), LINE_NUM, ADB_generateErrorMessage("assert networkRequest (1) is sent without ecid/identityMap", "invalid", jsonObj1.xdm.identityMap))
                ADB_assertTrue((jsonObj1.xdm.implementationDetails.name = "https://ns.adobe.com/experience/mobilesdk/roku"), LINE_NUM, "assert networkRequests(2) is to send Edge event with implementationDetails")

                ecidInRegistry = ADB_getPersistedECID()
                ADB_assertTrue((ecidInRegistry = ecid), LINE_NUM, ADB_generateErrorMessage("assert ecid matches the ecid value persisted in Registry", ecidInRegistry, ecid))

                ' Verify meta map
                expectedMeta = {
                    "configOverrides":{
                        "com_adobe_experience_platform": {
                            "datasets": {
                                "event": {
                                    "datasetId": datasetIdOverride
                                }
                            }
                        }
                    }
                    "sdkConfig": {
                        "datastream": {
                            "original": configId
                        }
                    }
                }

                expectedMetaJson = FormatJson(expectedMeta)
                actualMetaJson = FormatJson(jsonObj1.meta)
                ADB_assertTrue((actualMetaJson = actualMetaJson), LINE_NUM, ADB_generateErrorMessage("Assert metadata", expectedMetaJson, actualMetaJson))
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

            ADB_persistECIDInRegistry(m._testECID)

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
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, ADB_generateErrorMessage("Number of network requests", 1, FormatJson(debugInfo.networkRequests.count())))

                ' ECID is no longer fetched explicitly
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.eventType = "media.sessionStart"), LINE_NUM, "assert eventType = media.sessionStart")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.playhead = 0), LINE_NUM, "assert playhead = 0")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm._id <> invalid), LINE_NUM, "assert _id <> invalid")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.appVersion = "1.0.0"), LINE_NUM, "assert appVersion = 1.0.0")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.channel = "channel_test"), LINE_NUM, "assert channel = channel_test")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.contentType = "vod"), LINE_NUM, "assert contentType = vod")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.friendlyName = "test_media_name"), LINE_NUM, "assert friendlyName = test_media_name")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.hasResume = false), LINE_NUM, "assert hasResume = false")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.length = 100), LINE_NUM, "assert length = 100")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.name = "test_media_id"), LINE_NUM, "assert name = test_media_id")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.playerName = "player_test"), LINE_NUM, "assert playerName = player_test")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.streamType = "video"), LINE_NUM, "assert streamType = video")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.xdm.identityMap = invalid), LINE_NUM, "assert IdentityMap is not included in the request as ECID is not available")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.xdm.implementationDetails <> invalid), LINE_NUM, "assert include implementationDetails")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response code = 200")

                ADB_assertTrue((debugInfo.networkRequests[0].url.StartsWith("https://edge.adobedc.net/ee/va/v1/sessionStart?configId=")), LINE_NUM, "assert url")

                ADB_assertTrue((debugInfo.networkRequests[0].response.body.Instr(debugInfo.media.backendSessionId) > 0), LINE_NUM, "assert backendSessionId is extracted correctly")
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
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert networkRequests.count() = 2")

                ' the First request is to fetch ECID
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.eventType = "media.sessionStart"), LINE_NUM, "assert eventType = media.sessionStart")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.playhead = 0), LINE_NUM, "assert playhead = 0")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm._id <> invalid), LINE_NUM, "assert _id <> invalid")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.appVersion = "1.0.0"), LINE_NUM, "assert appVersion = 1.0.0")
                ' session level config should be used
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.channel = "test_channel_session"), LINE_NUM, "assert channel = test_channel_session")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.contentType = "vod"), LINE_NUM, "assert contentType = vod")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.friendlyName = "test_media_name"), LINE_NUM, "assert friendlyName = test_media_name")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.hasResume = false), LINE_NUM, "assert hasResume = false")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.length = 100), LINE_NUM, "assert length = 100")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.name = "test_media_id"), LINE_NUM, "assert name = test_media_id")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.playerName = "player_test"), LINE_NUM, "assert playerName = player_test")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.events[0].xdm.mediaCollection.sessionDetails.streamType = "video"), LINE_NUM, "assert streamType = video")

                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.xdm.identityMap = invalid), LINE_NUM, "assert IdentityMap is not included in the request as ECID is not available")
                ADB_assertTrue((debugInfo.networkRequests[0].jsonObj.xdm.implementationDetails <> invalid), LINE_NUM, "assert include implementationDetails")
                ADB_assertTrue((debugInfo.networkRequests[0].response.code = 200), LINE_NUM, "assert response code = 200")

                ADB_assertTrue((debugInfo.networkRequests[0].url.StartsWith("https://edge.adobedc.net/ee/va/v1/sessionStart?configId=")), LINE_NUM, "assert url")

                ADB_assertTrue((debugInfo.networkRequests[0].response.body.Instr(debugInfo.media.backendSessionId) > 0), LINE_NUM, "assert backendSerssionId is extracted correctly")
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
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert requests = 1 [createMediaSession]")

                ADB_assertTrue((debugInfo.networkRequests[0].response.body.Instr(debugInfo.media.backendSessionId) > 0), LINE_NUM, "assert backendSerssionId is extracted correctly")
            end sub

            validator[eventIdForSendMediaEvent] = sub(debugInfo)
                ADB_assertTrue((debugInfo.networkRequests <> invalid and debugInfo.networkRequests.count() = 1), LINE_NUM, "assert requests = 1 [sendMediaEvent]")

                networkRequest1 = debugInfo.networkRequests[0]
                jsonObj1 = networkRequest1.jsonObj
                ADB_assertTrue((jsonObj1.events[0].xdm._id <> invalid), LINE_NUM, "assert _id <> invalid")
                ADB_assertTrue((jsonObj1.events[0].xdm.eventType = "media.play"), LINE_NUM, "assert eventType = media.play")
                ADB_assertTrue((jsonObj1.events[0].xdm.mediaCollection.playhead = 123), LINE_NUM, "assert playhead = 123")
                ADB_assertTrue((jsonObj1.events[0].xdm.mediaCollection.sessionID = debugInfo.media.backendSessionId), LINE_NUM, "assert sessionID = backendSessionId")

                ADB_assertTrue((jsonObj1.xdm.identityMap.ECID <> invalid), LINE_NUM, "assert include ECID in identityMap")
                ADB_assertTrue((jsonObj1.xdm.implementationDetails <> invalid), LINE_NUM, "assert include implementationDetails")

                ADB_assertTrue((networkRequest1.response.code = 204), LINE_NUM, "assert response code = 204")

                locationHint = ADB_getPersistedLocationHint()
                ' first edge request will set the location hint
                ADB_assertTrue(not (_adb_isEmptyOrInvalidString(locationHint.value)), LINE_NUM, "assert locationHint is not invalid")

                expectedURLPrefix = "https://edge.adobedc.net/ee/" + locationHint.value + "/va/v1/play?configId="
                actualURL = networkRequest1.url

                ADB_assertTrue(actualURL.StartsWith(expectedURLPrefix), LINE_NUM, ADB_generateErrorMessage("url starts with:", expectedURLPrefix, actualURL))
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

