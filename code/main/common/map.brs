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

' *********************************** MODULE: map utils ***********************************

function _adb_optMapFromMap(map as object, key as string, fallback = invalid as dynamic)
    if map = invalid
        return fallback
    end if

    if not map.DoesExist(key)
        return fallback
    end if

    ret = map[key]
    if type(ret) <> "roAssociativeArray"
        return fallback
    end if

    return ret

end function

function _adb_optStringFromMap(map as object, key as string, fallback = invalid as dynamic)
    if map = invalid
        return fallback
    end if

    if not map.DoesExist(key)
        return fallback
    end if

    ret = map[key]
    if type(ret) <> "roString" and type(ret) <> "String"
        return fallback
    end if

    return ret

end function

function _adb_optIntFromMap(map as object, key as string, fallback = invalid as dynamic)
    if map = invalid
        return fallback
    end if

    if not map.DoesExist(key)
        return fallback
    end if

    ret = map[key]
    if type(ret) <> "roInteger" and type(ret) <> "roInt"
        return fallback
    end if

    return ret

end function

function _adb_isEmptyOrInvalidMap(input as object) as boolean
    if input = invalid or type(input) <> "roAssociativeArray"
        return true
    end if

    if input.count() = 0
        return true
    end if

    return false
end function