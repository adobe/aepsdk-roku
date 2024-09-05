' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeEach
sub TS_identityModule_BeforeEach()
    clearPersistedECID()
end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_init()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)
    identityModule = _adb_IdentityModule(identityState, edgeModule)
    UTF_assertNotInvalid(identityModule)
end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_bad_init()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityModule = _adb_IdentityModule({}, {}, {})
    UTF_assertInvalid(identityModule)

    identityModule = _adb_IdentityModule(_adb_ConfigurationModule(), invalid, invalid)
    UTF_assertInvalid(identityModule)

    identityModule = _adb_IdentityModule(invalid, edgeModule)
    UTF_assertInvalid(identityModule)

    ' 3rd param task is optional
    identityModule = _adb_IdentityModule(identityState, edgeModule, invalid)
    UTF_assertNotInvalid(identityModule)
end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_getECID_persistedECID_returnsECID()
    _adb_testUtil_persistECID("persistedECID")
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityModule = _adb_IdentityModule(identityState, edgeModule)
    UTF_assertEqual("persistedECID", identityModule.getECID())

end sub

' target: _adb_IdentityModule_getECID()
sub TC_adb_IdentityModule_getECID_ECIDNotPersisted_queriesECID()
    ' GetECID will queue a request with Edge Module when ECID is not persisted
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    edgeModule.queueEdgeRequest = function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string, requestType = m._REQUEST_TYPE_EDGE as string)
        GetGlobalAA().queueEdgeRequest_called = true
    end function

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    ' queries ECID from server
    identityModule.getECID()
    UTF_assertTrue(GetGlobalAA().queueEdgeRequest_called, "Edge Module queueEdgeRequest() was not called.")
end sub

' target: _adb_IdentityModule_getECIDAsync()
' @Test
sub TC_adb_IdentityModule_getECIDAsync_persistedECID_callsCallback()
    _adb_testUtil_persistECID("persistedECID")
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    getExperienceCloudIdAPIEvent = {
        "uuid": "test-uuid",
        "apiName": "getExperienceCloudId",
    }

    ecidCallback = function(ecid as string) as void
        GetGlobalAA().callbackCalled = true
        GetGlobalAA().ecidFromCallback = ecid
    end function

    identityModule.getECIDAsync(getExperienceCloudIdAPIEvent, ecidCallback)

    UTF_assertTrue(GetGlobalAA().callbackCalled, generateErrorMessage("Callback called", "true", "false"))
    UTF_assertEqual("persistedECID", GetGlobalAA().ecidFromCallback, generateErrorMessage("ECID from callback", "persistedECID", GetGlobalAA().ecidFromCallback))

    ' verify that the request event and callback are not cached
    UTF_assertEqual(0, identityModule._callbackMap.Count(), generateErrorMessage("Callback cached", "0", identityModule._callbackMap.Count()))
end sub

' target: _adb_IdentityModule_getECIDAsync()
' @Test
sub TC_adb_IdentityModule_getECIDAsync_ECIDnotPersisted_cachesCallback()

    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    edgeModule.queueEdgeRequest = function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string, requestType = m._REQUEST_TYPE_EDGE as string)
        GetGlobalAA().queuesEdgeRequest_called = true
    end function

    getExperienceCloudIdAPIEvent = {
        "uuid": "test-uuid",
        "apiName": "getExperienceCloudId",
    }

    ecidCallback = function(ecid as string) as void
        GetGlobalAA().callbackCalled = true
        GetGlobalAA().ecidFromCallback = ecid
    end function

    identityModule.getECIDAsync(getExperienceCloudIdAPIEvent, ecidCallback)

    UTF_assertTrue(GetGlobalAA().callbackCalled, generateErrorMessage("Callback called", "true", "false"))
    UTF_assertEqual(ecidCallback, identityModule._callbackMap[getExperienceCloudIdAPIEvent.uuid], generateErrorMessage("Callback cached", "true", "false"))
end sub

' target: _adb_IdentityModule_processResponseEvent()
' @Test
sub TC_adb_IdentityModule_processResponseEvent_updatesECID_callsPendingCallback()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityState.updateECID = function(ecid as string) as void
        GetGlobalAA().updateECID_called = true
        GetGlobalAA().updateECID_actualECID = ecid
    end function

    identityModule = _adb_IdentityModule(identityState, edgeModule)
    ' mock request event and callback
    identityModule._callbackMap["test-uuid"] = function(ecid as string) as void
        GetGlobalAA().callbackCalled = true
        GetGlobalAA().ecidFromCallback = ecid
    end function

    sampleEdgeResponse = getTestEdgeResponseIdentityEvent()

    identityModule.processResponseEvent(sampleEdgeResponse)

    UTF_assertTrue(GetGlobalAA().updateECID_called)
    UTF_assertEqual("ECID_FROM_EDGE_RESPONSE", GetGlobalAA().updateECID_actualECID, ADB_GenerateErrorMessage("ECID ", "ECID_FROM_EDGE_RESPONSE" ,GetGlobalAA().updateECID_actualECID))
    UTF_assertTrue(GetGlobalAA().callbackCalled)
    UTF_assertEqual("ECID_FROM_EDGE_RESPONSE", GetGlobalAA().ecidFromCallback, ADB_GenerateErrorMessage("ECID from callback", "ECID_FROM_EDGE_RESPONSE", GetGlobalAA().ecidFromCallback))
    UTF_assertEqual(0, identityModule._callbackMap.Count(), generateErrorMessage("Callback cached", "0", identityModule._callbackMap.Count()))
end sub

' target: _adb_IdentityModule_processResponseEvent()
' @Test
sub TC_adb_IdentityModule_processResponseEvent_noECIDInResponse()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    GetGlobalAA().updateECID_called = false
    identityState.updateECID = function(ecid as string) as void
        GetGlobalAA().updateECID_called = true
        UTF_fail("updateECID() should not be called when ECID is not in response.")
    end function

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    sampleEdgeResponse = getTestEdgeResponseEventWithoutIdentity()

    identityModule.processResponseEvent(sampleEdgeResponse)

    UTF_assertFalse(GetGlobalAA().updateECID_called)
end sub

' target: _adb_IdentityModule_processResponseEvent()
' @Test
sub TC_adb_IdentityModule_processResponseEvent_doesNotUpdateECIDIfAlreadyPresent()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityState._ecid = "ECID_ALREADY_PRESENT"

    GetGlobalAA().updateECID_called = false
    identityState.updateECID = function(ecid as string) as void
        GetGlobalAA().updateECID_called = true
        UTF_fail("updateECID() should not be called when ECID is already present.")
    end function

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    sampleEdgeResponse = getTestEdgeResponseIdentityEvent()
    identityModule.processResponseEvent(sampleEdgeResponse)

    UTF_assertFalse(GetGlobalAA().updateECID_called)
    UTF_assertEqual("ECID_ALREADY_PRESENT", identityState.getECID())
end sub

' target: _adb_IdentityModule_processResponseEvent()
' @Test
sub TC_adb_IdentityModule_processResponseEvent_invalidResponseEvent_ignored()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityState.updateECID = function(ecid as string) as void
        GetGlobalAA().updateECID_called = true
        UTF_fail("updateECID() should not be called when response event is not a valid Edge response.")
    end function

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    invalidResponseEvent = [
        {},
        "invalid event",
        invalid,
        123,
        true,
        _adb_EdgeResponseEvent("test", { "data missing code and message fields" : "invalid" })
    ]

    for each responseEvent in invalidResponseEvent
        identityModule.processResponseEvent(responseEvent)
        UTF_assertFalse(GetGlobalAA().updateECID_called)
    end for

end sub


' ********************************************* Helper Functions *********************************************
function getTestEdgeResponseIdentityEvent() as object
    data = {
    "requestId": "fe59f430-ccaa-4d79-b1e8-cecf785609a3",
    "handle": [
            {
            "payload": [
                {
                "id": "ECID_FROM_EDGE_RESPONSE",
                "namespace": {
                    "code": "ECID"
                }
                }
            ],
            "type": "identity:result"
            },
            {
            "payload": [
                {
                "scope": "EdgeNetwork",
                "hint": "or2",
                "ttlSeconds": 1800
                }
            ],
            "type": "locationHint:result"
            },
            {
            "payload": [
                {
                "collect": {
                    "val": "y"
                },
                "metadata": {
                    "time": "2024-08-30T22:31:45.925Z"
                }
                }
            ],
            "type": "consent:preferences"
            },
            {
            "payload": [
                {
                "key": "kndctr_972C898555E9F7BC7F000101_AdobeOrg_identity",
                "value": "CiY0OTU0NTQ4MjAxMDQ5NTcyNzIzMzMzMjg3Njc5OTI0NjY0OTM5MVISCNWDqquaMhABGAEqA09SMjAA8AHVg6qrmjI=",
                "maxAge": 34128000
                }
            ],
            "type": "state:store"
            }
        ]
    }

    edgeResponse = _adb_EdgeResponseEvent("test",  {
    code: 200,
    message: FormatJson(data)
    })

    return edgeResponse
end function

function getTestEdgeResponseEventWithoutIdentity() as object
    data = {
    "requestId": "fe59f430-ccaa-4d79-b1e8-cecf785609a3",
    "handle": [
            {
            "payload": [
                {
                "scope": "EdgeNetwork",
                "hint": "or2",
                "ttlSeconds": 1800
                }
            ],
            "type": "locationHint:result"
            },
            {
            "payload": [
                {
                "collect": {
                    "val": "y"
                },
                "metadata": {
                    "time": "2024-08-30T22:31:45.925Z"
                }
                }
            ],
            "type": "consent:preferences"
            },
            {
            "payload": [
                {
                "key": "kndctr_972C898555E9F7BC7F000101_AdobeOrg_identity",
                "value": "CiY0OTU0NTQ4MjAxMDQ5NTcyNzIzMzMzMjg3Njc5OTI0NjY0OTM5MVISCNWDqquaMhABGAEqA09SMjAA8AHVg6qrmjI=",
                "maxAge": 34128000
                }
            ],
            "type": "state:store"
            }
        ]
    }

    edgeResponse = _adb_EdgeResponseEvent("test",  {
    code: 200,
    message: FormatJson(data)
    })

    return edgeResponse
end function
