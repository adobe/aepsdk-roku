' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_isInvalidInt()
' @Test
sub TC_adb_isInvalidInt_invalidInt()
    UTF_assertTrue(_adb_isInvalidInt(invalid), generateErrorMessage("isInvalidInt (invalid)", "true", "false"))
    UTF_assertTrue(_adb_isInvalidInt("123"), generateErrorMessage("isInvalidInt ("+Chr(34)+"123"+Chr(34)+")", "true", "false"))
    UTF_assertTrue(_adb_isInvalidInt({}), generateErrorMessage("isInvalidInt ({})", "true", "false"))
    UTF_assertTrue(_adb_isInvalidInt([]), generateErrorMessage("isInvalidInt ([])","true", "false"))
    UTF_assertTrue(_adb_isInvalidInt(true), generateErrorMessage("isInvalidInt (true)", "true", "false"))
    UTF_assertTrue(_adb_isInvalidInt(false), generateErrorMessage("isInvalidInt (false)", "true", "false"))
    UTF_assertTrue(_adb_isInvalidInt(1.23), generateErrorMessage("isInvalidInt (1.23)", "true", "false"))
    UTF_assertTrue(_adb_isInvalidInt(-1.23), generateErrorMessage("isInvalidInt (-1.23)", "true", "false"))
end sub

' target: _adb_isInvalidInt_false()
' @Test
sub TC_adb_isInvalidInt_validInt()
    UTF_assertFalse(_adb_isInvalidInt(123), generateErrorMessage("isInvalidInt (123)", "false", "true"))
    UTF_assertFalse(_adb_isInvalidInt(0), generateErrorMessage("isInvalidInt (0)", "false", "true"))
    UTF_assertFalse(_adb_isInvalidInt(-123), generateErrorMessage("isInvalidInt (-123)", "false", "true"))
    UTF_assertFalse(_adb_isInvalidInt(&HFF), generateErrorMessage("isInvalidInt Hex int (&HFF)", "false", "true"))
end sub
