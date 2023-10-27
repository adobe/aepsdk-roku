' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_isEmptyOrInvalidString()
' @Test
sub TC_adb_isEmptyOrInvalidString()
    UTF_assertTrue(_adb_isEmptyOrInvalidString(invalid))
    UTF_assertTrue(_adb_isEmptyOrInvalidString(""))
    UTF_assertFalse(_adb_isEmptyOrInvalidString("test"))
    UTF_assertTrue(_adb_isEmptyOrInvalidString(123))
    UTF_assertTrue(_adb_isEmptyOrInvalidString({}))
end sub

' target: _adb_isStringEndsWith()
' @Test
sub TC_adb_isStringEndsWith()
    UTF_assertTrue(_adb_isStringEndsWith("xyz", "z"))
    UTF_assertTrue(_adb_isStringEndsWith("xyz", "yz"))
    UTF_assertTrue(_adb_isStringEndsWith("xyz", "xyz"))
    UTF_assertTrue(_adb_isStringEndsWith("xyz&", "&"))
    UTF_assertTrue(_adb_isStringEndsWith("xyz&8", "8"))
    UTF_assertTrue(_adb_isStringEndsWith("xyz ", ""))
    UTF_assertTrue(_adb_isStringEndsWith("xyz", ""))
    UTF_assertFalse(_adb_isStringEndsWith("xyz", "y"))
    UTF_assertFalse(_adb_isStringEndsWith("x", "xyz"))
end sub
' target: _adb_isStringInArray()
' @Test
sub TC_adb_isStringInArray()
    UTF_assertTrue(_adb_isStringInArray("xyz", ["xyz", "abc"]))
    UTF_assertTrue(_adb_isStringInArray("xyz", ["xyz", 2, "abc"]))
    UTF_assertFalse(_adb_isStringInArray("xyz", ["xy", "abc"]))
    UTF_assertFalse(_adb_isStringInArray("xyz", []))
    UTF_assertFalse(_adb_isStringInArray("xyz", [1, 2, "3"]))
    UTF_assertFalse(_adb_isStringInArray("xyz", invalid))
    UTF_assertFalse(_adb_isStringInArray("xyz", { x: "xyz", y: "abc" }))
end sub
