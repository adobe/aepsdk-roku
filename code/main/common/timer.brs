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

' ************************************ MODULE: Timer ***************************************

function _adb_Timer(durationInMillis as longinteger, startTimeMillis = _adb_timestampInMillis() as longinteger) as object
    timer = {
        initTSInMillis: invalid,
        expiryTSInMillis: invalid,

        _init: function(durationInMillis as longinteger, startTimeMillis as longinteger) as void
            m.initTSInMillis = startTimeMillis
            m.expiryTSInMillis = m.initTSInMillis + durationInMillis
            _adb_logDebug("_adb_Timer::_init() - Timer initialized with duration: (" + FormatJson(durationInMillis) + ") and expiry time: (" + FormatJson(m.expiryTSInMillis) + ").")
        end function,

        isExpired: function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
            if m.expiryTSInMillis = invalid
                _adb_logVerbose("_adb_Timer::isExpired() - Timer not initialized.")
                return true
            end if

            if currentTimeInMillis > m.expiryTSInMillis
                _adb_logDebug("_adb_Timer::isExpired() - Timer expired at (" + FormatJson(currentTimeInMillis) + ").")
                return true
            end if

            return false
        end function
    }

    timer._init(durationInMillis, startTimeMillis)

    return timer
end function
