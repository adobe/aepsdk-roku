' ********************** Copyright 2024 Adobe. All rights reserved. **********************
' *
' * This file is licensed to you under the Apache License, Version 2.0 (the "License");
' * you may not use this file except in compliance with the License. You may obtain a copy
' * of the License at http://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software distributed under
' * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' * OF ANY KIND, either express or implied. See the License for the specific language
' * governing permissions and limitations under the License.
' *
' *****************************************************************************************

' ************************************ MODULE: Consent ***************************************

function _adb_isConsentModule(module as object) as boolean
    return (module <> invalid and module.type = "com.adobe.module.consent")
end function

function _adb_ConsentModule(configurationModule as object) as object
    if not _adb_isConfigurationModule(configurationModule) then
        _adb_logError("ConsentModule::_adb_ConsentModule() - configurationModule is not valid.")
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.consent")
    module.Append({
        ''' TODO: Update the path
        _CONSENT_REQUEST_PATH: "/ee/v1/interact",
        _configurationModule: configurationModule,
        _collectConsent: invalid,

        ''' TODO
        setConsent: function(consent as object) as void
            ''' Send the consent update request to Edge
            ''' Update the collect consent in persistence based on the edge request response
        end function,

        ''' TODO
        _getCollectConsent: function() as string
            ''' TODO:
            ''' check if consent is udpated and persisted and use that value
            ''' if not, get the default value from the configuration
            ''' if both not available, return 'y'
            ''' return y|p|n

            return "y"
        end function,

        ''' usage: collectConsent = m._extractCollectConsentValue(m._configurationModule.getConsent())
        _extractCollectConsentValue: function(consentMap as object) as dynamic
            consentConfig = m._configurationModule.getDefaultConsent()

            if _adb_isEmptyOrInvalidMap(consentConfig) then
                return invalid
            end if

            consentList = consentConfig["consents"]
            if _adb_isEmptyOrInvalidMap(consentList) then
                return invalid
            end if

            collectConsent = consentList["collect"]
            if _adb_isEmptyOrInvalidMap(collectConsent) then
                return invalid
            end if

            collectConsentValue = collectConsent["val"]
            if not m._isValidConsentValue(collectConsentValue) then
                return invalid
            end if

            return collectConsentValue
        end function,

        _isValidConsentValue: function(consentValue as dynamic) as boolean
            if _adb_isEmptyOrInvalidString(consentValue) then
                return false
            end if

            return (consentValue = "y" or consentValue = "p" or consentValue = "n")
        end function,

        ''' TODO
        _processConsentResponse: function(response as object) as void
            ''' Process the response from Edge for the consent update request
            ''' Update the collect consent in persistence based on the edge request response
        end function,

        ''' TODO
        _saveCollectConsent: function(consentValue as string) as void
            ''' Save the collect consent in persistence
            ''' y|p|n
        end function,

        ''' TODO
        _getCollectConsentFromPersistence: function() as string
            ''' Get the collect consent from persistence
            ''' y|p|n
        end function,

        dump: function() as object
            return {

            }
        end function
    })
    return module
end function
