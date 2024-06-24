' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' ************************ Version Helpers ************************
function getTestSDKVersion() as string
    return "1.2.0"
end function

' ************************ Registry Helpers ************************
function clearPersistedECID() as void
    removeValue("ecid")
end function

function getPersistedECID() as dynamic
    persistedECID = readValueFromRegistry("ecid")
    return persistedECID
end function

function removeValue(key) as void
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    _registry.Delete(key)
    _registry.Flush()
end function

function readValueFromRegistry(key as string) as dynamic
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    if _registry.Exists(key) and _registry.Read(key).Len() > 0
        return _registry.Read(key)
    end if

    return invalid
end function

' ************************ Error Message Helper ************************
function generateErrorMessage(message as string, expected as string, actual as string) as string
    return message + " Expected: " + expected + " Actual: " + actual
end function

' ************************ String Helper ************************
function isEmptyOrInvalidString(str as dynamic) as boolean
    if str = invalid or (type(str) <> "roString" and type(str) <> "String")
        return true
    end if

    if Len(str) = 0
        return true
    end if

    return false
end function
