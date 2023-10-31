' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_timestampInMillis()
' @Test
sub TC_adb_timestampInMillis()
    timestampInMillis = _adb_timestampInMillis()
    UTF_assertEqual("LongInteger", Type(timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertTrue(FormatJson(timestampInMillis).Len() > 12, "timestampInMillis should be longer than 12 digits")
end sub

' target: _adb_ISO8601_timestamp()
' @Test
sub TC_adb_ISO8601_timestamp()
    isoString = _adb_ISO8601_timestamp()
    regexPattern = CreateObject("roRegex", "^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(([+-]\d\d:\d\d)|Z)?$", "")
    UTF_assertFalse(_adb_isEmptyOrInvalidString(isoString))
    UTF_assertTrue(regexPattern.isMatch(isoString))
end sub
