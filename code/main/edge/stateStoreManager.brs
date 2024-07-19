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
        _state: invalid,

        getState: function() as object
            return m._state
        end function,

        setStateStore: function(state as object) as void
            if _adb_isEmptyOrInvalidArray(state)
                _adb_logDebug("_adb_StateStoreManager::setStateStore() - stateStore is empty or invalid.")
                return
            end if

            m._state = state
            _adb_logDebug("_adb_StateStoreManager::setStateStore() - stateStore set to: (" + FormatJson(m._stateStore) + ").")
        end function,

        processStateStoreHandle: function(handle as object) as void
            _adb_logVerbose("_adb_StateStoreManager::processStateStoreHandle() - Extracting state store from the response handle(" + FormatJson(handle) + ")." )

            if _adb_isEmptyOrInvalidMap(handle) or _adb_isEmptyOrInvalidArray(handle.payload)
                return
            end if

            m.setStateStore(handle.payload)
        end function,
    }

end function
