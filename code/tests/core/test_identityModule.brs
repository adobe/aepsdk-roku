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

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_getECID_API_persistedECID_DispatchesResponse()
    _adb_testUtil_persistECID("persistedECID")
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()
    consentState = _adb_ConsentState(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityState, consentState)

    identityModule = _adb_IdentityModule(identityState, edgeModule)

    identityModule._dispatchECIDResponseEventToTask = function(event as object) as void
        GetGlobalAA().dispatchECIDResponseEventToTask_called = true
        GetGlobalAA().dispatchECIDResponseEventToTask_actualEvent = event
    end function

    getExperienceCloudIdAPIEvent = {
        "uuid": "test-uuid",
        "apiName": "getExperienceCloudId",
    }

    UTF_assertEqual("persistedECID", identityModule.getECID(getExperienceCloudIdAPIEvent))

    actualIdentityResponseEvent = GetGlobalAA().dispatchECIDResponseEventToTask_actualEvent
    UTF_assertTrue(GetGlobalAA().dispatchECIDResponseEventToTask_called)
    UTF_assertEqual("persistedECID", actualIdentityResponseEvent.data)
    UTF_assertEqual("test-uuid", actualIdentityResponseEvent.parentId)
end sub


' target: _adb_IdentityModule()
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
