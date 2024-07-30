' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_StateStoreManager()
' @Test
sub TC_adb_StateStoreManager_Init()
    stateStoreManager = _adb_StateStoreManager()

    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))
end sub

' target: _adb_StateStoreManager_processStateStoreHandle()
' @Test
sub TC_adb_StateStoreManager_processStateStoreHandle_validHandle()
    stateStoreManager = _adb_StateStoreManager()

    handle = {
        payload: [
            {
                key: "kndctr_1234_AdobeOrg_cluster",
                value: "or2",
                maxAge: 1800
            }
        ],
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(handle)
    actualStateStore = stateStoreManager.getStateStore()

    UTF_assertEqual(actualStateStore, handle.payload, generateErrorMessage("State store", handle.payload, actualStateStore))
end sub

' target: _adb_StateStoreManager_processStateStoreHandle()
' @Test
sub TC_adb_StateStoreManager_processStateStoreHandle_invalidHandle()
    stateStoreManager = _adb_StateStoreManager()

    stateStoreManager.processStateStoreHandle(invalid)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))

    stateStoreManager.processStateStoreHandle({})
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))

    invalidhandle = {
        ' missing payload list
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(invalidhandle)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))

    invalidhandle = {
        payload: [
            ' empty payload
        ],
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(invalidhandle)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))

    handlewithInvalidKey = {
        payload: [
            {
                key: invalid,
                value: "or2",
                maxAge: 1800
            }
        ],
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(handlewithInvalidKey)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))
end sub

sub TC_adb_StateStoreManager_deleteStateStore()
    stateStoreManager = _adb_StateStoreManager()

    stateStoreManager._states = {
        "key1": {
            key: "key1",
            value: "value1",
            maxAge: 1
        },
        "key2": {
            key: "key2",
            value: "value2",
            maxAge: 2
        },
        "key3": {
            key: "key3",
            value: "value3",
            maxAge: 3
        },
        "key4": {
            key: "key4",
            value: "value4",
            maxAge: 4
        }
    }

    expectedStateStore = {
        "key2": {
            key: "key2",
            value: "value2",
            maxAge: 2
        },
        "key3": {
            key: "key3",
            value: "value3",
            maxAge: 3
        }
    }

    stateStoreManager._deleteStateStore(["key1", "key4"])

    actualStateStore = stateStoreManager.getStateStore()

    UTF_assertEqual(expectedStateStore, actualStateStore, generateErrorMessage("State store", expectedStateStore, actualStateStore))
end sub

' target: _adb_StateStoreEntry()
' @Test
sub TC_adb_StateStoreEntry_init()
    payload = {
        key: "kndctr_1234_AdobeOrg_cluster",
        value: "or2",
        maxAge: 1800
    }
    stateStoreEntry = _adb_StateStoreEntry(payload)

    actualStateStoreEntry = stateStoreEntry.getPayload()

    UTF_assertEqual(payload, actualStateStoreEntry, generateErrorMessage("State store", payload, actualStateStoreEntry))
end sub

' target: _adb_StateStoreEntry()
' @Test
sub TC_adb_StateStoreEntry_invalidPayload()
    payload = {}
    stateStoreEntry = _adb_StateStoreEntry(payload)

    UTF_assertInvalid(stateStoreEntry.getPayload(), generateErrorMessage("State store", invalid, stateStoreEntry.getPayload()))
end sub

' target: _adb_StateStoreEntry()
' @Test
sub TC_adb_StateStoreEntry_invalidKey()
    payload = {
        key: invalid,
        value: "or2",
        maxAge: 1800
    }
    stateStoreEntry = _adb_StateStoreEntry(payload)

    UTF_assertEqual(payload, stateStoreEntry.getPayload(), generateErrorMessage("State store", payload, stateStoreEntry.getPayload()))
end sub

' target: _adb_StateStoreEntry()
' @Test
sub TC_adb_StateStoreEntry_isExpired_notExpired()
    payload = {
        key: "kndctr_1234_AdobeOrg_cluster",
        value: "or2",
        maxAge: 1800
    }

    stateStoreEntry = _adb_StateStoreEntry(payload)

    UTF_assertFalse(stateStoreEntry.isExpired(), "State store is expired.")
end sub

' target: _adb_StateStoreEntry()
' @Test
sub TC_adb_StateStoreEntry_isExpired_expired()
    payload = {
        key: "kndctr_1234_AdobeOrg_cluster",
        value: "or2",
        maxAge: 10
    }

    stateStoreEntry = _adb_StateStoreEntry(payload)
    expectedExpiryTS = stateStoreEntry._timer.expiryTSInMillis + (10 * 1000)

    UTF_assertTrue(stateStoreEntry.isExpired(expectedExpiryTS+1), "State store is not expired.")
end sub

' @Test
sub TC_adb_StateStoreEntry_noMaxAge()
    payload = {
        key: "kndctr_1234_AdobeOrg_cluster",
        value: "or2"
    }

    stateStoreEntry = _adb_StateStoreEntry(payload)
    expectedExpiryTS = stateStoreEntry._timer.initTSInMillis + (0 * 1000) ' default maxAge is 0

    actualExpiryTS = stateStoreEntry._timer.expiryTSInMillis
    UTF_assertEqual(expectedExpiryTS ,actualExpiryTS, generateErrorMessage("State store expiry timestamp", expectedExpiryTS, actualExpiryTS))
end sub
