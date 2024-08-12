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

' ************************************ MODULE: StateStoreManager ***************************************

function _adb_StateStoreManager() as object

    return {
        _stateStoreMap: {},

        getStateStore: function() as object
            stateStorePayload = []
            expiredStateStoreEntries = []

            for each stateName in m._stateStoreMap
                stateStoreEntry = m._stateStoreMap[stateName]

                if stateStoreEntry.isExpired()
                    _adb_logVerbose("_adb_StateStoreManager::getStateStore() - stateStore with key:(" + FormatJson(stateName) + ") is expired and will be deleted.")
                    expiredStateStoreEntries.push(stateName)
                    continue for
                end if

                stateStorePayload.push(stateStoreEntry.getPayload())
            end for

            m._deleteStateStoreEntries(expiredStateStoreEntries)

            _adb_logDebug("_adb_StateStoreManager::getStateStore() - returning active stateStores: (" + FormatJson(stateStorePayload) + ").")
            return stateStorePayload
        end function,

        processStateStoreHandle: function(handle as object) as void
            _adb_logVerbose("_adb_StateStoreManager::processStateStoreHandle() - Extracting state store from the response handle(" + FormatJson(handle) + ")." )

            if _adb_isEmptyOrInvalidMap(handle) or _adb_isEmptyOrInvalidArray(handle.payload)
                return
            end if

            for each payload in handle.payload
                m._addToStateStore(payload)
            end for

        end function,

        _addToStateStore: function(payload as object) as void
            _adb_logDebug("_adb_StateStoreManager::_addToStateStore() - Adding payload: (" + FormatJson(payload) + ") to the stateStore.")
            if _adb_isEmptyOrInvalidMap(payload)
                _adb_logDebug("_adb_StateStoreManager::_addToStateStore() - stateStore payload is empty or invalid.")
                return
            end if

            if _adb_isEmptyOrInvalidString(payload.key)
                _adb_logDebug("_adb_StateStoreManager::_addToStateStore() - payload key is empty or invalid.")
                return
            end if

            m._stateStoreMap[payload.key] = _adb_StateStoreEntry(payload)
        end function,

        _deleteStateStoreEntries: function(stateNames as object) as void
            for each stateName in stateNames
                m._stateStoreMap.delete(stateName)
                _adb_logVerbose("_adb_StateStoreManager::_deleteStateStoreEntries() - stateStore with key:(" + FormatJson(stateName) + ") deleted.")
            end for

            _adb_logVerbose("_adb_StateStoreManager::_deleteStateStoreEntries() - stateStore updated to: (" + FormatJson(m._stateStoreMap) + ").")
        end function
    }

end function

function _adb_StateStoreEntry(payload as object) as object

    stateStoreEntry = {
        _payload: invalid,
        _timer: invalid,

        _init: function(payload as object) as void
            _adb_logVerbose("_adb_StateStoreEntry::init() - Intializing stateStore with payload: (" + FormatJson(payload) + ").")

            if _adb_isEmptyOrInvalidMap(payload)
                _adb_logDebug("_adb_StateStoreEntry::init() - stateStore payload is empty or invalid.")
                return
            end if

            m._payload = payload

            maxAge = m._payload.maxAge
            if _adb_isInvalidInt(maxAge)
                _adb_logDebug("_adb_StateStoreEntry::init() - Invalid payload.maxAge value:(" + FormatJson(maxAge) + "), using 0 as default value.")
                maxAge = 0
            end if

            m._timer = _adb_Timer(maxAge * 1000&)
        end function,

        getPayload: function() as dynamic
            if m.isExpired()
                _adb_logDebug("_adb_StateStoreEntry::getPayload() - state is expired returning invalid.")
                return invalid
            end if

            return m._payload
        end function,

        isExpired: function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
            if m._timer = invalid
                return true
            end if

            return m._timer.isExpired(currentTimeInMillis)
        end function
    }

    stateStoreEntry._init(payload)

    return stateStoreEntry
end function
