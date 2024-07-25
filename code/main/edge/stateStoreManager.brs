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

function _adb_StateStoreManager() as object

    return {
        _states: {},

        getStateStore: function() as object
            payload = []
            expiredStateStores = []

            for each stateName in m._states
                state = m._states[stateName]

                if state.isExpired()
                    _adb_logVerbose("_adb_StateStoreManager::getStateStore() - stateStore with key:(" + FormatJson(state.key) + ") is expired and will be deleted.")
                    expiredStateStores.push(stateName)
                    continue for
                end if

                payload.push(state.getPayload())
            end for

            m._deleteStateStore(expiredStateStores)

            _adb_logDebug("_adb_StateStoreManager::getStateStore() - returning active stateStores: (" + FormatJson(payload) + ").")
            return payload
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
            if _adb_isEmptyOrInvalidMap(payload)
                _adb_logDebug("_adb_StateStoreManager::setStateStore() - stateStore payload is empty or invalid.")
                return
            end if

            if _adb_isEmptyOrInvalidString(payload.key)
                _adb_logDebug("_adb_StateStoreManager::setStateStore() - payload key is empty or invalid.")
                return
            end if

            m._states[payload.key] = _adb_StateStore(payload)
            _adb_logDebug("_adb_StateStoreManager::setStateStore() - stateStore updated to: (" + FormatJson(m._states) + ").")

        end function,

        _deleteStateStore: function(stateNames as object) as void
            for each state in stateNames
                m._states.delete(state)
                _adb_logVerbose("_adb_StateStoreManager::_deleteStateStore() - stateStore with key:(" + FormatJson(state) + ") deleted.")
            end for

            _adb_logVerbose("_adb_StateStoreManager::_deleteStateStore() - stateStore updated to: (" + FormatJson(m._states) + ").")
        end function
    }

end function

function _adb_StateStore(payload as object) as object

    stateStore = {
        _payload: invalid,
        _expiryTimer: invalid,

        _init: function(payload as object) as void
            _adb_logVerbose("_adb_StateStore::init() - Intializing stateStore with payload: (" + FormatJson(m._payload) + ").")

            if _adb_isEmptyOrInvalidMap(payload)
                _adb_logDebug("_adb_StateStore::init() - stateStore payload is empty or invalid.")
                return
            end if

            m._payload = payload

            maxAge = m._payload.maxAge
            if _adb_isInvalidInt(maxAge)
                _adb_logDebug("_adb_StateStore::init() - Invalid payload.maxAge value:(" + FormatJson(maxAge) + "), using 0 as default value.")
                maxAge = 0
            end if

            m._expiryTimer = _adb_ExpiryTimer(maxAge * 1000)
        end function,

        getPayload: function() as dynamic
            if m.isExpired()
                _adb_logDebug("_adb_StateStore::getPayload() - state is expired returning invalid.")
                return invalid
            end if

            return m._payload
        end function,

        isExpired: function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
            if m._expiryTimer = invalid
                return true
            end if

            return m._expiryTimer.isExpired(currentTimeInMillis)
        end function
    }

    stateStore._init(payload)

    return stateStore
end function
