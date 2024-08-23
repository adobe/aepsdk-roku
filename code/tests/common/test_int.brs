' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_isValidInt()
' @Test
sub TC_adb_isValidInt_invalidInt()

    inputs = [
        invalid,
        "123",
        {},
        [],
        true,
        false,
        1.23,
        -1.23
    ]
    for each input in inputs
        UTF_assertFalse(_adb_isValidInt(input), generateErrorMessage("isValidInt ("+Chr(34)+FormatJson(input)+Chr(34)+")", "false", "true"))
    end for
end sub

' target: _adb_isValidInt()
' @Test
sub TC_adb_isValidInt_validInt()
    inputs = [
        123,
        0,
        -123,
        &HFF
    ]
    for each input in inputs
        UTF_assertTrue(_adb_isValidInt(input), generateErrorMessage("isValidInt ("+Chr(34)+FormatJson(input)+Chr(34)+")", "true", "false"))
    end for
end sub

' target: _adb_isValidLongInt()
' @Test
sub TC_adb_isValidLongInt_invalidLongInt()

    inputs = [
        invalid,
        "123",
        {},
        [],
        true,
        false,
        1.23,
        -1.23,
        123
    ]
    for each input in inputs
        UTF_assertFalse(_adb_isValidLongInt(input), generateErrorMessage("isValidLongInt ("+Chr(34)+FormatJson(input)+Chr(34)+")", "false", "true"))
    end for
end sub

' target: _adb_isValidLongInt()
' @Test
sub TC_adb_isValidLongInt_validLongInt()
    inputs = [
        123&,
        0&,
        -123&,
        &HFF&,
    ]
    for each input in inputs
        UTF_assertTrue(_adb_isValidLongInt(input), generateErrorMessage("isValidLongInt ("+Chr(34)+FormatJson(input)+Chr(34)+")", "true", "false"))
    end for
end sub

' target: _adb_isPositiveWholeNumber()
' @Test
sub TC_adb_isPositiveWholeNumber_invalid()

    inputs = [
        invalid,
        "123",
        {},
        [],
        true,
        false,
        1.23,
        -1.23,
        -1,
        -1&
    ]
    for each input in inputs
        UTF_assertFalse(_adb_isPositiveWholeNumber(input), generateErrorMessage("isPositiveNumber ("+Chr(34)+FormatJson(input)+Chr(34)+")", "false", "true"))
    end for
end sub

' target: _adb_isPositiveWholeNumber()
' @Test
sub TC_adb_isPositiveWholeNumber_valid()
    inputs = [
        123,
        1,
        &HFF,
        123&,
        &HFF&,
        0
    ]
    for each input in inputs
        UTF_assertTrue(_adb_isPositiveWholeNumber(input), generateErrorMessage("isPositiveNumber ("+Chr(34)+FormatJson(input)+Chr(34)+")", "true", "false"))
    end for
end sub
