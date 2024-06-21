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
    consentModule = _adb_ConsentModule(configurationModule)
    UTF_assertTrue(_adb_isConsentModule(consentModule))

    consentModule = _adb_ConsentModule(invalid)
    UTF_assertInvalid(consentModule)
end sub

' target: _extractConsentFromConfiguration
' @Test
sub TC_adb_ConsentModule_extractConsentFromConfiguration_valid()

    configurationModule = _adb_ConfigurationModule()
    consentModule = _adb_ConsentModule(configurationModule)

    ADB_CONSTANTS = AdobeAEPSDKConstants()

    configuration = {}
    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
            "collect": {
                "val": "y"
            }
        }
    }

    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertEqual("y", actualCollectConsent, "expected: y, actual: " + FormatJson(actualCollectConsent))

    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
            "collect": {
                "val": "n"
            }
        }
    }

    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertEqual("n", actualCollectConsent, "expected: n, actual: " + FormatJson(actualCollectConsent))


    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
            "collect": {
                "val": "p"
            }
        }
    }

    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertEqual("p", actualCollectConsent, "expected: p, actual: " + FormatJson(actualCollectConsent))
end sub


' target: _extractConsentFromConfiguration
' @Test
sub TC_adb_ConsentModule_extractConsentFromConfiguration_invalid()

    configurationModule = _adb_ConfigurationModule()
    consentModule = _adb_ConsentModule(configurationModule)

    ADB_CONSTANTS = AdobeAEPSDKConstants()

    configuration = {}

    ''' case 1 default consent is not present
    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 2 default consent is empty
    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {}
    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 3 default consent does not have collect key
    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
        }
    }
    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 4 collect consent does not have val key
    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
            "collect": {
            }
        }
    }
    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 5 collect consent does not have val key
    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
            "collect": {
                "notVal": "y"
            }
        }
    }
    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 6 collect consent val is not valid
    configuration[ADB_CONSTANTS.CONFIGURATION.CONSENT_DEFAULT] = {
        "consents": {
            "collect": {
                "val": "pending"
            }
        }
    }

    configurationModule.updateConfiguration(configuration)
    actualCollectConsent = consentModule._extractCollectConsentValue(configurationModule.getDefaultConsent())
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))
end sub
