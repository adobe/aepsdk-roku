' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeAll
sub TS_consentState_SetUp()
    clearPersistedCollectConsent()
end sub

' @BeforeEach
sub TS_consentState_BeforeEach()
    clearPersistedCollectConsent()
end sub

' @AfterAll
sub TS_consentState_TearDown()
    clearPersistedCollectConsent()
end sub

' target: _adb_ConsentState()
' @Test
sub TC_adb_ConsentState_init()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    actualCollectConsent = consentState.getCollectConsent()
    UTF_assertInvalid(actualCollectConsent, generateErrorMessage("Collect consent value", invalid, actualCollectConsent))
end sub

' target: _extractConsentFromConfiguration
' @Test
sub TC_adb_ConsentState_extractConsentFromConfiguration_valid()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    config = {
        "consent.default" : {
            "consents": {
                "collect": {
                    "val": "y"
                }
            }
        }
    }

    configurationModule.updateConfiguration(config)

    actualCollectConsent = consentState._getCollectConsentFromConfiguration()
    UTF_assertEqual("y", actualCollectConsent, "expected: y, actual: " + FormatJson(actualCollectConsent))

    config = {
        "consent.default" : {
            "consents": {
                "collect": {
                    "val": "n"
                }
            }
        }
    }

    configurationModule.updateConfiguration(config)

    actualCollectConsent = consentState._getCollectConsentFromConfiguration()
    UTF_assertEqual("n", actualCollectConsent, "expected: n, actual: " + FormatJson(actualCollectConsent))


    config = {
        "consent.default" : {
            "consents": {
                "collect": {
                    "val": "p"
                }
            }
        }
    }

    configurationModule.updateConfiguration(config)

    actualCollectConsent = consentState._getCollectConsentFromConfiguration()
    UTF_assertEqual("p", actualCollectConsent, "expected: p, actual: " + FormatJson(actualCollectConsent))
end sub


' target: _extractConsentFromConfiguration
' @Test
sub TC_adb_ConsentState_extractConsentFromConfiguration_invalid()

    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)

    ADB_CONSTANTS = AdobeAEPSDKConstants()


    ''' case 1 default consent is not present
    consentMap = invalid
    actualCollectConsent = consentState._extractCollectConsentValueFromConfig(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 2 default consent is empty
    consentMap = {}
    actualCollectConsent = consentState._extractCollectConsentValueFromConfig(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 3 default consent does not have collect key
    consentMap = {
        "consents": {
        }
    }

    actualCollectConsent = consentState._extractCollectConsentValueFromConfig(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 4 collect consent does not have val key
    consentMap = {
        "consents": {
            "collect": {
            }
        }
    }

    actualCollectConsent = consentState._extractCollectConsentValueFromConfig(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 5 collect consent does not have val key
    consentMap = {
        "consents": {
            "collect": {
                "notVal": "y"
            }
        }
    }

    actualCollectConsent = consentState._extractCollectConsentValueFromConfig(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))
end sub


' target: _adb_ConsentState()
' @Test
sub TC_adb_ConsentState_setCollectConsent_cachesAndPersists()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)

    consentValues = [
        "y",
        "n",
        "p",
        "pending"
        "yes"
    ]

    for each consentValue in consentValues
        consentState.setCollectConsent(consentValue)

        consentValueFromAPI = consentState.getCollectConsent()
        persistedConsent = getPersistedCollectConsent()
        cachedConsent = consentState._collectConsent
        UTF_assertEqual(consentValue, consentValueFromAPI, generateErrorMessage("Collect consent value using getCollectConsent", consentValue, consentValueFromAPI))
        UTF_assertEqual(consentValue, cachedConsent, generateErrorMessage("Collect consent value in memory", consentValue, cachedConsent))
        UTF_assertEqual(consentValue, persistedConsent, generateErrorMessage("Collect consent value in persistence", consentValue, persistedConsent))
    end for

end sub

' target: _adb_ConsentState()
' @Test
sub TC_adb_ConsentState_getCollectConsent_cached_returnsCachedValue()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    ' mock the cached value
    consentState._collectConsent = "n"

    persistedConsent = getPersistedCollectConsent()
    actualCollectConsent = consentState.getCollectConsent()
    cachedCollectConsent = consentState._collectConsent
    UTF_assertEqual("n", actualCollectConsent, generateErrorMessage("Collect consent value", "n", actualCollectConsent))
    UTF_assertInvalid(persistedConsent, generateErrorMessage("Collect consent value in persistence", "invalid", persistedConsent))
    UTF_assertEqual("n", cachedCollectConsent, generateErrorMessage("Collect consent value in memory", "n", cachedCollectConsent))
end sub

' target: _adb_ConsentState()
' @Test
sub TC_adb_ConsentState_getCollectConsent_notCached_returnsPersistedValue()
    configurationModule = _adb_ConfigurationModule()
    ' mock the persisted value
    persistCollectConsent("y")

    consentState = _adb_ConsentState(configurationModule)

    persistedConsent = getPersistedCollectConsent()
    actualCollectConsent = consentState.getCollectConsent()
    cachedCollectConsent = consentState._collectConsent
    UTF_assertEqual("y", actualCollectConsent, generateErrorMessage("Collect consent value", "y", actualCollectConsent))
    UTF_assertEqual("y", persistedConsent, generateErrorMessage("Collect consent value in persistence", "y", persistedConsent))
    UTF_assertEqual("y", cachedCollectConsent, generateErrorMessage("Collect consent value in memory", "y", cachedCollectConsent))
end sub

' target: _adb_ConsentState()
' @Test
sub TC_adb_ConsentState_getCollectConsent_notPersisted_fetchesFromConfig()
    configurationModule = _adb_ConfigurationModule()
    config = {
        "consent.default" : {
            "consents": {
                "collect": {
                    "val": "p"
                }
            }
        }
    }

    configurationModule.updateConfiguration(config)

    consentState = _adb_ConsentState(configurationModule)

    actualCollectConsent = consentState.getCollectConsent()
    cachedCollectConsent = consentState._collectConsent
    UTF_assertEqual("p", actualCollectConsent, generateErrorMessage("Collect consent value", "p", actualCollectConsent))
    UTF_assertEqual("p", cachedCollectConsent, generateErrorMessage("Collect consent value in memory", "p", cachedCollectConsent))
end sub

' target: _adb_ConsentState()
' @Test
sub TC_adb_ConsentState_getCollectConsent_notPersisted_notInConfig_returnsInvalid()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)

    actualCollectConsent = consentState.getCollectConsent()
    cachedCollectConsent = consentState._collectConsent
    persistedCollectConsent = getPersistedCollectConsent()
    UTF_assertInvalid(actualCollectConsent, generateErrorMessage("Collect consent value", "invalid", actualCollectConsent))
    UTF_assertInvalid(cachedCollectConsent, generateErrorMessage("Collect consent value in memory", "invalid", cachedCollectConsent))
    UTF_assertInvalid(persistedCollectConsent, generateErrorMessage("Collect consent value in persistence", "invalid", persistedCollectConsent))
end sub
