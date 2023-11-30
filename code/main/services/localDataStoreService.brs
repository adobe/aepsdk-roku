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

' **************************** MODULE: LocalDataStoreService ******************************

function _adb_LocalDataStoreService() as object
    return {

        ''' private internal variables
        _registry: CreateObject("roRegistrySection", "adb_aep_roku_sdk"),

        ''' public Functions
        writeValue: function(key as string, value as string) as void
            _adb_logVerbose("LocalDataStoreService::writeValue() - Write key:(" + key + ") value:(" + value + ") to registry.")
            m._registry.Write(key, value)
            sucess = m._registry.Flush()
            if not sucess then
                _adb_logError("LocalDataStoreService::writeValue() - Failed to write key:(" + key + ") value:(" + value + ") to registry.")
            end if
        end function,

        readValue: function(key as string) as dynamic
            _adb_logVerbose("LocalDataStoreService::readValue() - Read key:(" + key + ") from registry.")
            '''bug in roku - Exists returns true even if no key. value in that case is an empty string
            if m._registry.Exists(key) and m._registry.Read(key).Len() > 0
                _adb_logVerbose("LocalDataStoreService::readValue() - Found key:(" + key + ") with value:(" + m._registry.Read(key) + ") in registry.")
                return m._registry.Read(key)
            end if

            _adb_logVerbose("LocalDataStoreService::readValue() - key:(" + key + ") not found in registry.")
            return invalid
        end function,

        removeValue: function(key as string) as void
            _adb_logVerbose("LocalDataStoreService::removeValue() - Deleting key:(" + key + ") from registry.")
            m._registry.Delete(key)
            sucess = m._registry.Flush()
            if not sucess then
                _adb_logError("LocalDataStoreService::writeValue() - Failed to delete key:(" + key + ") from registry.")
            end if
        end function,
    }
end function
