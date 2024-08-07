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

function _adb_isConsentStateModule(obj as object) as boolean
    return (obj <> invalid and obj.type = "com.adobe.module.consentState")
end function

function _adb_ConsentState(configurationModule as object) as object
    if not _adb_isConfigurationModule(configurationModule) then
        _adb_logError("ConsentState::_adb_ConsentState() - configurationModule is not valid.")
        return invalid
    end if

    consentState = _adb_AdobeObject("com.adobe.module.consentState")
    consentState.Append({
        _configurationModule: invalid,
        _collectConsent: invalid,

        _init: sub(configurationModule as object)
            _adb_logVerbose("ConsentState::_init() - Initializing consent state.")
            m._configurationModule = configurationModule
            m.getCollectConsent()
        end sub,

        setCollectConsent: sub(collectConsent as dynamic)
            _adb_logVerbose("ConsentState::setCollectConsent() - Setting collect consent value to (" + FormatJson(collectConsent) + ").")

            m._saveCollectConsent(collectConsent)
        end sub,

        getCollectConsent: function() as dynamic
            _adb_logVerbose("ConsentState::getCollectConsent() - Getting collect consent value.")
            if m._collectConsent = invalid
                _adb_logVerbose("ConsentState::getCollectConsent() - Collect consent value not found in memory. Loading from persistence.")
                m._collectConsent = m._loadCollectConsent()
            end if

            if m._collectConsent = invalid
                _adb_logVerbose("ConsentState::getCollectConsent() - Collect consent value not found in persistence. Extracting from configuration.")
                m._collectConsent = m._getCollectConsentFromConfiguration()
            end if

            _adb_logVerbose("ConsentState::getCollectConsent() - Returning collect consent value: (" + FormatJson(m._collectConsent) + ")")
            return m._collectConsent
        end function

        _loadCollectConsent: function() as dynamic
            _adb_logVerbose("ConsentState::_loadCollectConsent() - Loading collect consent value from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            collectConsentValue = localDataStoreService.readValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.CONSENT_COLLECT)

            return collectConsentValue
        end function,

        _saveCollectConsent: function(collectConsentValue as dynamic) as void
            ''' cache the collect consent value
            m._collectConsent = collectConsentValue

            _adb_logVerbose("ConsentState::_saveCollectConsent() - Saving collect consent value " + FormatJson(collectConsentValue) + " in persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.writeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.CONSENT_COLLECT, collectConsentValue)
        end function,

        _deleteCollectConsent: function() as void
            _adb_logVerbose("ConsentState::_deleteCollectConsent() - Deleting collect consent value from persistence.")

            m._collectConsent = invalid

            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.removeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.CONSENT_COLLECT)
            return
        end function,

        _getCollectConsentFromConfiguration: function() as dynamic
            _adb_logVerbose("ConsentState::_getCollectConsentFromConfiguration() - Getting collect consent value from configuration.")
            defaultConsentConfiguration = m._configurationModule.getDefaultConsent()
            collectConsentValue = m._extractCollectConsentValueFromConfig(defaultConsentConfiguration)

            return collectConsentValue
        end function,

        _extractCollectConsentValueFromConfig: function(consentMap as object) as dynamic
            if _adb_isEmptyOrInvalidMap(consentMap) then
                return invalid
            end if

            consents = consentMap["consents"]
            if _adb_isEmptyOrInvalidMap(consents) then
                return invalid
            end if

            collectConsent = consents["collect"]
            if _adb_isEmptyOrInvalidMap(collectConsent) then
                return invalid
            end if

            collectConsentValue = collectConsent["val"]

            return collectConsentValue
        end function,
    })

    consentState._init(configurationModule)

    return consentState
end function
