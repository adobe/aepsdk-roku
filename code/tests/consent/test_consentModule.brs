' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_ConsentModule()
' @Test
sub TC_adb_ConsentModule_init()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)

    consentModule = _adb_ConsentModule(consentState, edgeModule)
    UTF_assertTrue(_adb_isConsentModule(consentModule), generateErrorMessage("Consent module is valid", "yes", "no"))

    consentModule = _adb_ConsentModule(invalid, consentState)
    UTF_assertInvalid(consentModule, generateErrorMessage("Consent module", "invalid", "valid"))

    consentModule = _adb_ConsentModule(configurationModule, invalid)
    UTF_assertInvalid(consentModule, generateErrorMessage("Consent state", "invalid", "valid"))
end sub

' target: _adb_ConsentModule()
' @Test
sub TC_adb_ConsentModule_processEvent_withCollectConsent_queuesEdgeRequest()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)
    consentModule = _adb_ConsentModule(consentState, edgeModule)

    GetGlobalAA().setConsentEvent = {
        "uuid": "test-event",
        "data": {
            "consent": [
                {
                    "standard": "Adobe",
                    "version": "2.0",
                    "value": {
                        "collect": {
                            "val": "y"
                        },
                        "metadata": {
                            "time": "2021-03-17T15:48:42-07:00"
                        }
                    }
                }
            ]
        },
        "timestampInMillis": 0
    }

    GetGlobalAA().queueEdgeRequestCalled = false
    edgeModule.queueEdgeRequest = function(requestId as string, eventData as object, timestampInMillis as longinteger, options as object, path as string, requestType as string)
        GetGlobalAA().queueEdgeRequestCalled = true
        expectedConsentPayload = GetGlobalAA().setConsentEvent.data
        UTF_assertEqual( "test-event", requestId, generateErrorMessage("Request ID", "test-event", requestId))
        UTF_assertEqual(expectedConsentPayload, eventData, generateErrorMessage("Event data", expectedConsentPayload, eventData))
        UTF_assertEqual(0&, timestampInMillis, generateErrorMessage("Timestamp in millis", "0", timestampInMillis))
        UTF_assertEqual({}, options, generateErrorMessage("Options", "{}", options))
        UTF_assertEqual("/v1/privacy/set-consent", path, generateErrorMessage("Path", "/v1/privacy/set-consent", path))
        UTF_assertEqual("consent", requestType, generateErrorMessage("Request type", "consent", requestType))
    end function

    consentModule.processEvent(GetGlobalAA().setConsentEvent)
    UTF_assertNotInvalid(GetGlobalAA().setConsentEvent, generateErrorMessage("Consent event", "valid", "invalid"))
    UTF_assertTrue(GetGlobalAA().queueEdgeRequestCalled, generateErrorMessage("processEvent calls queueEdgeRequest", "true", "false"))
end sub

' target: _adb_ConsentModule()
' @Test
sub TC_adb_ConsentModule_processEvent_withoutCollectConsent_queuesEdgeRequest()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)
    consentModule = _adb_ConsentModule(consentState, edgeModule)

    GetGlobalAA().setConsentEvent = {
        "uuid": "test-event",
        "data": {
            "consent": [
                {
                    "standard": "Adobe",
                    "version": "2.0",
                    "value": {
                        "pushMessage": {
                            "val": "y"
                        },
                        "metadata": {
                            "time": "2021-03-17T15:48:42-07:00"
                        }
                    }
                }
            ]
        },
        "timestampInMillis": 0
    }

    GetGlobalAA().queueEdgeRequestCalled = false
    edgeModule.queueEdgeRequest = function(requestId as string, eventData as object, timestampInMillis as longinteger, options as object, path as string, requestType as string)
        GetGlobalAA().queueEdgeRequestCalled = true
        expectedConsentPayload = GetGlobalAA().setConsentEvent.data
        UTF_assertEqual( "test-event", requestId, generateErrorMessage("Request ID", "test-event", requestId))
        UTF_assertEqual(expectedConsentPayload, eventData, generateErrorMessage("Event data", expectedConsentPayload, eventData))
        UTF_assertEqual(0&, timestampInMillis, generateErrorMessage("Timestamp in millis", "0", timestampInMillis))
        UTF_assertEqual({}, options, generateErrorMessage("Options", "{}", options))
        UTF_assertEqual("/v1/privacy/set-consent", path, generateErrorMessage("Path", "/v1/privacy/set-consent", path))
        UTF_assertEqual("consent", requestType, generateErrorMessage("Request type", "consent", requestType))
    end function

    consentModule.processEvent(GetGlobalAA().setConsentEvent)
    UTF_assertNotInvalid(GetGlobalAA().setConsentEvent, generateErrorMessage("Consent event", "valid", "invalid"))
    UTF_assertTrue(GetGlobalAA().queueEdgeRequestCalled, generateErrorMessage("processEvent calls queueEdgeRequest", "true", "false"))
end sub

' target: _adb_ConsentModule()
' @Test
sub TC_adb_ConsentModule_processResponseEvent_validConsentHandle()

    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)

    GetGlobalAA().setCollectConsentCalled = false
    GetGlobalAA().setCollectConsentValue = invalid
    consentState.setCollectConsent = function(collectConsent as dynamic)
        GetGlobalAA().setCollectConsentCalled = true
        GetGlobalAA().setCollectConsentValue = collectConsent
    end function

    consentModule = _adb_ConsentModule(consentState, edgeModule)

    ' Mock edge response event
    edgeResponse = {
        "code": 200,
        "message": FormatJson({
            "requestId": "sessionStartRequestId",
            "handle": [
                {
                    "payload":[
                            {
                                "collect":{ "val":"y" },
                                "metadata":{ "time":"2024-07-30T23:46:02.089Z" }
                            }
                        ],
                    "type":"consent:preferences"
                },
                {
                    "payload": [
                        {
                            "key": "kndctr_EA0C49475E8AE1870A494023_AdobeOrg_cluster",
                            "value": "va6",
                            "maxAge": 1800
                        }
                    ],
                    "type": "state:store"
                }
            ]
        })
    }

    edgeResponseEvent = _adb_EdgeResponseEvent("consentPreferences", edgeResponse)
    consentModule.processResponseEvent(edgeResponseEvent)

    UTF_assertTrue(GetGlobalAA().setCollectConsentCalled, generateErrorMessage("setCollectConsent is called", "true", "false"))
    UTF_assertEqual("y", GetGlobalAA().setCollectConsentValue, generateErrorMessage("Collect consent value", "y", GetGlobalAA().setCollectConsentValue))
end sub

' target: _adb_ConsentModule()
' @Test
sub TC_adb_ConsentModule_processResponseEvent_missingConsentPreferencesHandle()

    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)

    GetGlobalAA().setCollectConsentCalled = false
    GetGlobalAA().setCollectConsentValue = invalid
    consentState.setCollectConsent = function(collectConsent as dynamic)
        GetGlobalAA().setCollectConsentCalled = true
        GetGlobalAA().setCollectConsentValue = collectConsent
    end function

    consentModule = _adb_ConsentModule(consentState, edgeModule)

    ' Mock edge response event
    edgeResponse = {
        "code": 200,
        "message": FormatJson({
            "requestId": "sessionStartRequestId",
            "handle": [
                {
                    "payload": [
                        {
                            "key": "kndctr_EA0C49475E8AE1870A494023_AdobeOrg_cluster",
                            "value": "va6",
                            "maxAge": 1800
                        }
                    ],
                    "type": "state:store"
                }
            ]
        })
    }

    edgeResponseEvent = _adb_EdgeResponseEvent("consentPreferences", edgeResponse)
    consentModule.processResponseEvent(edgeResponseEvent)

    UTF_assertFalse(GetGlobalAA().setCollectConsentCalled, generateErrorMessage("setCollectConsent is called", "false", "true"))
    UTF_assertInvalid(GetGlobalAA().setCollectConsentValue, generateErrorMessage("Collect consent value", "invalid", GetGlobalAA().setCollectConsentValue))
end sub

' target: _adb_ConsentModule()
' @Test
sub TC_adb_ConsentModule_processResponseEvent_invalidHandle()

    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)


    GetGlobalAA().setCollectConsentCalled = false
    GetGlobalAA().setCollectConsentValue = invalid
    consentState.setCollectConsent = function(collectConsent as dynamic)
        GetGlobalAA().setCollectConsentCalled = true
        GetGlobalAA().setCollectConsentValue = collectConsent
    end function

    consentModule = _adb_ConsentModule(consentState, edgeModule)

    ' Mock edge response event
    invalidEdgeResponse1 = {
        "code": 200,
        "message": FormatJson({
            "requestId": "sessionStartRequestId",
            "handle": [
                {
                    "payload":[
                            {
                                "collect":{ "val":"y" },
                                "metadata":{ "time":"2024-07-30T23:46:02.089Z" }
                            }
                        ],
                    "type":"consent:pref"
                }
            ]
        })
    }

    invalidEdgeResponse2 = {
        "code": 200,
        "message": FormatJson({
            "requestId": "sessionStartRequestId",
            "handle": [
                {
                    "payload":[
                            {
                                ' missing collect payload
                                "metadata":{ "time":"2024-07-30T23:46:02.089Z" }
                            }
                        ],
                    "type":"consent:preferences"
                }
            ]
        })
    }

    invalidEdgeResponse3 = {
        "code": 200,
        "message": FormatJson({
            "requestId": "sessionStartRequestId",
            "handle": [
                {
                    "collect":{ },
                    "type":"consent:preferences"
                }
            ]
        })
    }

    edgeResponseEvent1 = _adb_EdgeResponseEvent("consentPreferences", invalidEdgeResponse1)
    edgeResponseEvent2 = _adb_EdgeResponseEvent("consentPreferences", invalidEdgeResponse2)
    edgeResponseEvent3 = _adb_EdgeResponseEvent("consentPreferences", invalidEdgeResponse3)

    consentModule.processResponseEvent(edgeResponseEvent1)
    consentModule.processResponseEvent(edgeResponseEvent2)
    consentModule.processResponseEvent(edgeResponseEvent3)

    UTF_assertFalse(GetGlobalAA().setCollectConsentCalled, generateErrorMessage("setCollectConsent is called", "false", "true"))
    UTF_assertInvalid(GetGlobalAA().setCollectConsentValue, generateErrorMessage("Collect consent value", "invalid", GetGlobalAA().setCollectConsentValue))
end sub
