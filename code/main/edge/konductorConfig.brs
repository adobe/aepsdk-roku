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

' ******************************* MODULE: EdgeRequestWorker *******************************

function _adb_KonductorConfig() as object

    return {
        _stateStore: invalid,
        _locationHint: invalid,

        getStateStore: function() as object
            return m._stateStore
        end function,

        getLocationHint: function() as dynamic
            ' Extract location hint for  "scope": "EdgeNetwork"
            return m._locationHint
        end function,

        setStateStore: function(stateStore as object) as void
            if _adb_isEmptyOrInvalidArray(stateStore)
                _adb_logDebug("_adb_KonductorConfig::setStateStore() - stateStore is empty or invalid")
                return
            end if

            m._stateStore = stateStore
            _adb_logDebug("_adb_KonductorConfig::setStateStore() - stateStore set to: " + FormatJson(m._stateStore))
        end function,

        setLocationHint: function(locationHint as dynamic) as void
            if _adb_isEmptyOrInvalidString(locationHint)
                _adb_logDebug("_adb_KonductorConfig::setLocationHint() - locationHint is empty or invalid")
                return
            end if

            m._locationHint = locationHint
            _adb_logDebug("_adb_KonductorConfig::setLocationHint() - locationHint set to: " + m._locationHint)
        end function
    }

end function
