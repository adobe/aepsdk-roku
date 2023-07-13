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
        _registry: CreateObject("roRegistrySection", "adb_edge_mobile"),

        ''' public Functions
        writeValue: function(key as string, value as string) as void
            _adb_logVerbose("localDataStoreService::writeValue() - Write key:(" + key + ") value:(" + value + ") to registry.")
            m._registry.Write(key, value)
            m._registry.Flush()
        end function,
        readValue: function(key as string) as dynamic
            _adb_logVerbose("localDataStoreService::readValue() - Read key:(" + key + ") from registry.")
            '''bug in roku - Exists returns true even if no key. value in that case is an empty string
            if m._registry.Exists(key) and m._registry.Read(key).Len() > 0
                _adb_logVerbose("localDataStoreService::readValue() - Found key:(" + key + ") with value:(" + m._registry.Read(key) + ") in registry.")
                return m._registry.Read(key)
            end if


            _adb_logVerbose("localDataStoreService::readValue() - key:(" + key + ") not found in registry.")
            return invalid
        end function,

        removeValue: function(key as string) as void
            _adb_logVerbose("localDataStoreService::removeValue() - Deleting key:(" + key + ") from registry.")
            m._registry.Delete(key)
            m._registry.Flush()
        end function,

        writeMap: function(name as string, map as dynamic) as dynamic
            mapName = "adbmobileMap_" + name
            mapRegistry = CreateObject("roRegistrySection", mapName)
            _adb_logDebug("localDataStoreService::writeMap() - Writing to map:(" + mapName + ")")

            if map <> invalid and map.Count() > 0
                For each key in map
                    if map[key] <> invalid
                        _adb_logDebug("localDataStoreService::writeMap() - Writing [" + key + ":" + map[key] + "] to map: " + mapName)
                        mapRegistry.Write(key, map[key])
                        mapRegistry.Flush()
                    end if
                end for
            end if
        end function,

        readMap: function(name as string) as dynamic
            mapName = "adbmobileMap_" + name
            mapRegistry = CreateObject("roRegistrySection", mapName)
            keyList = mapRegistry.GetKeyList()
            result = {}
            if keyList <> invalid
                _adb_logDebug("localDataStoreService::readMap() - Reading from map:(" + mapName + ") with size:(" + keyList.Count().toStr() + ")")
                For each key in keyList
                    result[key] = mapRegistry.Read(key)
                end for
            end if

            return result
        end function

        readValueFromMap: function(name as string, key as string) as dynamic
            mapName = "adbmobileMap_" + name
            mapRegistry = CreateObject("roRegistrySection", mapName)
            _adb_logDebug("localDataStoreService::readValueFromMap() - Reading value for key:(" + key + ") from map:(" + mapName + ")")
            if mapRegistry.Exists(key) and mapRegistry.Read(key).Len() > 0
                return mapRegistry.Read(key)
            end if
            _adb_logDebug("localDataStoreService::readValueFromMap() - No Value for key:(" + key + ") found in map:(" + mapName + ")")
            return invalid
        end function,

        removeValueFromMap: function(name as string, key as string) as void
            mapName = "adbmobileMap_" + name
            mapRegistry = CreateObject("roRegistrySection", mapName)
            _adb_logDebug("localDataStoreService::removeValueFromMap() - Removing key:(" + key + ") from map:(" + mapName + ")")
            mapRegistry.Delete(key)
            mapRegistry.Flush()
        end function,

        removeMap: function(name as string) as void
            mapName = "adbmobileMap_" + name
            mapRegistry = CreateObject("roRegistrySection", mapName)
            _adb_logDebug("localDataStoreService::removeMap() - Deleting map:(" + mapName + ")")
            keyList = mapRegistry.GetKeyList()
            For each key in keyList
                m.removeValueFromMap(mapName, key)
            end for
        end function
    }
end function
