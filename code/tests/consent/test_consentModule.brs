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

    consentMap = {
        "consents": {
            "collect": {
                "val": "y"
            }
        }
    }
    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertEqual("y", actualCollectConsent, "expected: y, actual: " + FormatJson(actualCollectConsent))

    consentMap = {
        "consents": {
            "collect": {
                "val": "n"
            }
        }
    }

    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertEqual("n", actualCollectConsent, "expected: n, actual: " + FormatJson(actualCollectConsent))


    consentMap = {
        "consents": {
            "collect": {
                "val": "p"
            }
        }
    }

    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertEqual("p", actualCollectConsent, "expected: p, actual: " + FormatJson(actualCollectConsent))
end sub


' target: _extractConsentFromConfiguration
' @Test
sub TC_adb_ConsentModule_extractConsentFromConfiguration_invalid()

    configurationModule = _adb_ConfigurationModule()
    consentModule = _adb_ConsentModule(configurationModule)

    ADB_CONSTANTS = AdobeAEPSDKConstants()


    ''' case 1 default consent is not present
    consentMap = invalid
    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 2 default consent is empty
    consentMap = {}
    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 3 default consent does not have collect key
    consentMap = {
        "consents": {
        }
    }

    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 4 collect consent does not have val key
    consentMap = {
        "consents": {
            "collect": {
            }
        }
    }

    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 5 collect consent does not have val key
    consentMap = {
        "consents": {
            "collect": {
                "notVal": "y"
            }
        }
    }

    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))

    ''' case 6 collect consent val is not valid
    consentMap = {
        "consents": {
            "collect": {
                "val": "pending"
            }
        }
    }

    actualCollectConsent = consentModule._extractCollectConsentValue(consentMap)
    UTF_assertInvalid(actualCollectConsent, "expected: Invalid, actual: " + FormatJson(actualCollectConsent))
end sub

' target: _isValidConsentValue
' @Test
sub TC_adb_ConsentModule_isValidConsentValue_valid()
    configurationModule = _adb_ConfigurationModule()
    consentModule = _adb_ConsentModule(configurationModule)

    validValues = [
        "y",
        "n",
        "p"
    ]

    for each value in validValues
        UTF_assertTrue(consentModule._isValidConsentValue(value), FormatJson(value) + " should be a valid consent value")
    end for
end sub

' target: _isValidConsentValue
' @Test
sub TC_adb_ConsentModule_isValidConsentValue_invalid()
    configurationModule = _adb_ConfigurationModule()

    consentModule = _adb_ConsentModule(configurationModule)

    invalidValues = [
        0,
        true,
        false,
        "yes",
        "pending",
        "invalid",
        "y1",
        "n1",
        "p1"
    ]

    for each value in invalidValues
        UTF_assertFalse(consentModule._isValidConsentValue(value), FormatJson(value) + " should not a valid consent value")
    end for

end sub
