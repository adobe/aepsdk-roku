' ********************** Copyright 2023 Adobe. All rights reserved. **********************
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

' ********************************** MODULE: other utils **********************************

function _adb_isArray(input as dynamic) as boolean
    return input <> invalid and Type(input) = "roArray"
end function

function _adb_isEmptyOrInvalidArray(input as dynamic) as boolean
    if input = invalid or Type(input) <> "roArray"
        return true
    end if

    if input.count() = 0
        return true
    end if

    return false
end function

