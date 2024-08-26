' ********************** Copyright 2024 Adobe. All rights reserved. **********************
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

' ************************************ MODULE: StateStoreManager ***************************************

function _adb_StateStoreManager() as object

    stateStoreManager = {
        _stateStoreMap: {},

        _init: function() as void
            m._loadStateStoreObject()
            _adb_logVerbose("_adb_StateStoreManager::_init() - StateStoreManager initialized with stateStore: (" + FormatJson(m._stateStoreMap) + ").")
        end function,

        getStateStore: function() as object
            stateStorePayload = []
            expiredStateStoreEntries = []

            for each stateName in m._stateStoreMap
                stateStoreEntry = m._stateStoreMap[stateName]

                if m._isStateStoreEntryExpired(stateStoreEntry)
                    _adb_logVerbose("_adb_StateStoreManager::getStateStore() - stateStore with key:(" + FormatJson(stateName) + ") is expired and will be deleted.")
                    expiredStateStoreEntries.push(stateName)
                    continue for
                end if

                stateStorePayload.push(stateStoreEntry.payload)
            end for

            m._deleteStateStoreEntries(expiredStateStoreEntries)

            _adb_logDebug("_adb_StateStoreManager::getStateStore() - returning active stateStores: (" + FormatJson(stateStorePayload) + ").")
            return stateStorePayload
        end function,

        processStateStoreHandle: function(handle as object) as void
            _adb_logVerbose("_adb_StateStoreManager::processStateStoreHandle() - Extracting state store from the response handle(" + FormatJson(handle) + ")." )

            if _adb_isEmptyOrInvalidMap(handle) or _adb_isEmptyOrInvalidArray(handle.payload)
                return
            end if

            for each payload in handle.payload
                m._addToStateStore(payload)
            end for

            m._saveStateStoreObject()
        end function,

        _addToStateStore: function(payload as object, startTimeInMillis = _adb_timestampInMillis() as longinteger) as void
            if _adb_isEmptyOrInvalidMap(payload)
                _adb_logDebug("_adb_StateStoreManager::_addToStateStore() - stateStore payload is empty or invalid.")
                return
            end if

            if _adb_isEmptyOrInvalidString(payload.key)
                _adb_logDebug("_adb_StateStoreManager::_addToStateStore() - payload key is empty or invalid.")
                return
            end if

            maxAgeSeconds = payload.maxAge
            if not _adb_isPositiveWholeNumber(maxAgeSeconds)
                _adb_logDebug("_adb_StateStore::_setExpiryTime() - Invalid payload.maxAge value:(" + FormatJson(maxAgeSeconds) + "). Deleting the state store entry.")

                ' delete the state store entry if maxAge is 0 or less than 0
                m._deleteStateStoreEntries([payload.key])
                return
            end if

            _expiryTSInMillis& = startTimeInMillis + (maxAgeSeconds * 1000)

            stateStoreEntryName = payload.key
            m._stateStoreMap[stateStoreEntryName] = {
                payload: payload,
                expiryTS: _expiryTSInMillis&
            }

            _adb_logDebug("_adb_StateStoreManager::setStateStore() - stateStore updated to: (" + FormatJson(m._stateStoreMap) + ").")

        end function,

        _loadStateStoreObject: function() as void
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            stateStoreJsonString = localDataStoreService.readValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.STATE_STORE)

            try
                if not _adb_isEmptyOrInvalidString(stateStoreJsonString)
                    m._stateStoreMap = ParseJson(stateStoreJsonString)
                    _adb_logVerbose("_adb_StateStoreManager::_loadStateStoreObject() - Loaded stateStore from local data store: (" + FormatJson(m._stateStoreMap) + ").")
                end if
            catch exception
                _adb_logError("_adb_StateStoreManager::_loadStateStoreObject() - Failed to load stateStore from local data store, the exception message: " + exception.Message)
            end try
        end function,

        _saveStateStoreObject: function() as void
            stateStoreJsonString = FormatJson(m._stateStoreMap)

            _adb_logVerbose("_adb_StateStoreManager::_saveStateStoreObject() - Saving stateStore to local data store: (" + FormatJson(stateStoreJsonString) + ").")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.writeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.STATE_STORE, stateStoreJsonString)
        end function,

        _deleteStateStoreEntries: function(stateNames as object) as void
            for each stateName in stateNames
                m._stateStoreMap.delete(stateName)
                _adb_logVerbose("_adb_StateStoreManager::_deleteStateStoreEntries() - stateStore with key:(" + FormatJson(stateName) + ") deleted.")
            end for

            ' save the updated stateStore
            m._saveStateStoreObject()
            _adb_logVerbose("_adb_StateStoreManager::_deleteStateStoreEntries() - stateStore updated to: (" + FormatJson(m._stateStoreMap) + ").")
        end function

        _isStateStoreEntryExpired: function(stateStoreEntry as object, currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
            if not _adb_isPositiveWholeNumber(stateStoreEntry.expiryTS)
                return true
            end if

            return currentTimeInMillis > stateStoreEntry.expiryTS
        end function
    }

    stateStoreManager._init()

    return stateStoreManager
end function
