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

' ******************************* MODULE: Identity State ***********************************

function _adb_isIdentityState(module as object) as boolean
    return (module <> invalid and module.type = "com.adobe.module.identityState")
end function


function _adb_IdentityState() as object
    identityState = _adb_AdobeObject("com.adobe.module.identityState")

    identityState.Append({
        _ecid: invalid,

        _init: function() as void
            _adb_logVerbose("IdentityState::_init() - Initializing identity state.")
            m._loadECID()
        end function,

        resetIdentities: function() as void
            m.updateECID(invalid)
        end function,

        getECID: function() as dynamic
            if _adb_isEmptyOrInvalidString(m._ecid)
                m._loadECID()
            end if

            _adb_logVerbose("IdentityState::getECID() - Returning ECID:(" + FormatJson(m._ecid) + ")")
            return m._ecid
        end function,

        updateECID: function(ecid as dynamic) as void
            m._ecid = ecid
            if _adb_isEmptyOrInvalidString(m._ecid)
                _adb_logDebug("IdentityState::updateECID() - Deleting ECID, updateECID() called with empty or invalid string value.")
                m._deleteECID()
            else
                _adb_logVerbose("IdentityState::updateECID() - Saving ECID:(" + FormatJson(m._ecid) + ") in cache and persistence.")
                m._saveECID(m._ecid)
            end if

        end function,

        _loadECID: function() as dynamic
            _adb_logVerbose("IdentityState::_loadECID() - Loading ECID from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            ecid = localDataStoreService.readValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID)
            m._ecid = ecid
            return ecid
        end function,

        _saveECID: function(ecid as dynamic) as void
            _adb_logVerbose("IdentityState::_saveECID() - Saving ECID:(" + FormatJson(ecid) + ") to presistence.")
            m._ecid = ecid
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.writeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID, ecid)
        end function,

        _deleteECID: function() as void
            _adb_logVerbose("IdentityState::_deleteECID() - Removing ECID from persistence.")
            m._ecid = invalid
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.removeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID)
            return
        end function

        dump: function() as object
            return {
                ecid: m._ecid,
            }
        end function
    })

    identityState._init()

    return identityState
end function
