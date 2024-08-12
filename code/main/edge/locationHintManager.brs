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

' ************************************ MODULE: LocationHintManager ***************************************

function _adb_LocationHintManager() as object

    return {
        _DEFAULT_LOCATION_HINT_TTL_SEC: 1800,
        _EDGE_NETWORK_SCOPE: "edgenetwork",

        _locationHint: invalid,
        _timer: invalid,

        getLocationHint: function() as dynamic
            if m._isLocationHintExpired()
                _adb_logVerbose("_adb_LocationHintManager::getLocationHint() - Location hint expired or not set, returning invalid.")
                m._delete()
                return invalid
            end if

            _adb_logDebug("_adb_LocationHintManager::getLocationHint() - Returning locationHint: (" + FormatJson(m._locationHint) + ").")
            return m._locationHint
        end function,

        setLocationHint: function(locationHint as dynamic, ttlSeconds = invalid as dynamic) as boolean
            if _adb_isEmptyOrInvalidString(locationHint)
                _adb_logDebug("_adb_LocationHintManager::setLocationHint() - locationHint is empty or invalid.")
                return false
            end if

            locationHintChanged = locationHint <> m._locationHint

            m._locationHint = locationHint
            _adb_logDebug("_adb_LocationHintManager::setLocationHint() - locationHint set to: (" + m._locationHint + ").")

            m._setExpiryTime(ttlSeconds)

            return locationHintChanged
        end function

        processLocationHintHandle: function(handle as object) as void
            _adb_logVerbose("_adb_LocationHintManager::processLocationHintHandle() - Extracting location hint from the response handle (" + FormatJson(handle) + ")." )

            if _adb_isEmptyOrInvalidMap(handle) or _adb_isEmptyOrInvalidArray(handle.payload)
                return
            end if

            for each payload in handle.payload
                if _adb_isEmptyOrInvalidMap(payload)
                    continue for
                end if

                if _adb_stringEqualsIgnoreCase(payload.scope, m._EDGE_NETWORK_SCOPE)
                    m.setLocationHint(payload.hint, payload.ttlSeconds)
                end if

            end for
        end function,

        _setExpiryTime: function(ttlSeconds as dynamic) as void
            if _adb_isInvalidInt(ttlSeconds)
                _adb_logDebug("_adb_LocationHintManager::_setExpiryTime() - invalid ttlSeconds:(" + FormatJson(ttlSeconds) + "), using default ttl (" + FormatJson(m._DEFAULT_LOCATION_HINT_TTL_SEC) + ") seconds.")
                ttlSeconds = m._DEFAULT_LOCATION_HINT_TTL_SEC
            end if

            m._timer = _adb_Timer(ttlSeconds * 1000)
        end function,

        _isLocationHintExpired: function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
            if m._timer = invalid
                return true
            end if

            return m._timer.isExpired(currentTimeInMillis)
        end function,

        _delete: function() as void
            m._locationHint = invalid
            m._timer = invalid
        end function
    }

end function
