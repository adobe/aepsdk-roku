' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_isInvalidString()
' @Test
sub TC_adb_isInvalidString()
    UTF_assertTrue(_adb_isInvalidString(invalid))
    UTF_assertTrue(_adb_isInvalidString(123))
    UTF_assertTrue(_adb_isInvalidString({}))
    UTF_assertTrue(_adb_isInvalidString([]))
    UTF_assertTrue(_adb_isInvalidString(true))
    UTF_assertTrue(_adb_isInvalidString(false))
end sub

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

' target: _adb_stringEqualsIgnoreCase()
' @Test
sub TC_adb_stringEqualsIgnoreCase()
    UTF_assertTrue(_adb_stringEqualsIgnoreCase("", ""), generateErrorMessage(Chr(34) + Chr(34) + " = " + Chr(34) + Chr(34), true, false))
    UTF_assertTrue(_adb_stringEqualsIgnoreCase("xyz", "xyz"), generateErrorMessage("xyz = xyz", true, false))
    UTF_assertTrue(_adb_stringEqualsIgnoreCase("XYZ", "xyz"), generateErrorMessage("XYZ = xyz", true, false))
    UTF_assertTrue(_adb_stringEqualsIgnoreCase("xyz", "XYZ"), generateErrorMessage("xyz = XYZ", true, false))
    UTF_assertTrue(_adb_stringEqualsIgnoreCase("xYz", "XyZ"), generateErrorMessage("xYz = XyZ", true, false))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase("xyz", "xy"), generateErrorMessage("xyz = xy", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase("xyz", "xy"), generateErrorMessage("xyz = xy", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase("xyz", ""), generateErrorMessage("xyz = ''", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase("", "xyz"), generateErrorMessage(Chr(34) + Chr(34) + " = " + "xyz", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase("xyz", invalid), generateErrorMessage("xyz = invalid", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase(invalid, "xyz"), generateErrorMessage("invalid = xyz", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase(invalid, invalid), generateErrorMessage("invalid = invalid", false, true))
    UTF_assertFalse(_adb_stringEqualsIgnoreCase("123", 123), generateErrorMessage("123 (string) = 123 (int)", false, true))
end sub

' target: _adb_stringEquals()
' @Test
sub TC_adb_stringEquals()
    UTF_assertTrue(_adb_stringEquals("", ""), generateErrorMessage(Chr(34) + Chr(34) + " = " + Chr(34) + Chr(34), true, false))
    UTF_assertTrue(_adb_stringEquals("xyz", "xyz"), generateErrorMessage("xyz = xyz", true, false))
    UTF_assertFalse(_adb_stringEquals("xyz", "XYZ"), generateErrorMessage("xyz = XYZ", false, true))
    UTF_assertFalse(_adb_stringEquals("xyz", "XyZ"), generateErrorMessage("xyz = XyZ", false, true))
    UTF_assertFalse(_adb_stringEquals("xyz", "xy"), generateErrorMessage("xyz = xy", false, true))
    UTF_assertFalse(_adb_stringEquals("xyz", ""), generateErrorMessage("xyz = ''", false, true))
    UTF_assertFalse(_adb_stringEquals("", "xyz"), generateErrorMessage(Chr(34) + Chr(34) + " = " + "xyz", false, true))
    UTF_assertFalse(_adb_stringEquals("xyz", invalid), generateErrorMessage("xyz = invalid", false, true))
    UTF_assertFalse(_adb_stringEquals(invalid, "xyz"), generateErrorMessage("invalid = xyz", false, true))
    UTF_assertFalse(_adb_stringEquals(invalid, invalid), generateErrorMessage("invalid = invalid", false, true))
    UTF_assertFalse(_adb_stringEquals("123", 123), generateErrorMessage("123 (string) = 123 (int)", false, true))
end sub
