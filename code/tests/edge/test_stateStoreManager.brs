' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeEach
sub TS_StateStoreManager_BeforeEach()
    _adb_testUtil_clearPersistedStateStore()
end sub

' target: _adb_StateStoreManager()
' @Test
sub TC_adb_StateStoreManager_Init()
    stateStoreManager = _adb_StateStoreManager()

    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", "[]", actualStateStore))
end sub

' target: _adb_StateStoreManager()
' @Test
sub TC_adb_StateStoreManager_Init_stateStorePersisted_notExpired()
    stateStoreManager = _adb_StateStoreManager()

    ' Mock persisted state store
    stateStoreMap = {
        "kndctr_1234_AdobeOrg_cluster": {
            "payload" : {
                    key: "kndctr_1234_AdobeOrg_cluster",
                    value: "or2",
                    maxAge: 1800
                },
            "expiryTs": _adb_timestampInMillis() + 1000
        }

    }

    persistedStateStoreMapJson = FormatJson(stateStoreMap)

    _adb_testUtil_persistStateStore(persistedStateStoreMapJson)

    stateStoreManager._init()

    expectedStateStore = [
        {
            key: "kndctr_1234_AdobeOrg_cluster",
            value: "or2",
            maxAge: 1800
        }
    ]

    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual(expectedStateStore, actualStateStore, generateErrorMessage("State store", expectedStateStore, actualStateStore))
end sub

' target: _adb_StateStoreManager()
' @Test
sub TC_adb_StateStoreManager_Init_stateStorePersisted_expired()
    stateStoreManager = _adb_StateStoreManager()

    ' Mock persisted state store
    stateStoreMap = {
        "kndctr_1234_AdobeOrg_cluster": {
            "payload" : {
                    key: "kndctr_1234_AdobeOrg_cluster",
                    value: "or2",
                    maxAge: 1
                },
            "expiryTs": _adb_timestampInMillis() - 1000
        }
    }

    persistedStateStoreMapJson = FormatJson(stateStoreMap)

    _adb_testUtil_persistStateStore(persistedStateStoreMapJson)

    stateStoreManager._init()

    expectedStateStore = []

    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual(expectedStateStore, actualStateStore, generateErrorMessage("State store", expectedStateStore, actualStateStore))
end sub

' target: _adb_StateStoreManager_getStateStore()
' @Test
sub TC_adb_StateStoreManager_Init_stateStorePersisted_mixed()
    stateStoreManager = _adb_StateStoreManager()

    ' Mock persisted state store
    stateStoreMap = {
        "kndctr_1234_AdobeOrg_cluster": {
            "payload" : {
                    key: "kndctr_1234_AdobeOrg_cluster",
                    value: "or2",
                    maxAge: 1800
                },
            "expiryTs": _adb_timestampInMillis() + 1000
        },
        "kndctr_1234_AdobeOrg_cluster2": {
            "payload" : {
                    key: "kndctr_1234_AdobeOrg_cluster2",
                    value: "or3",
                    maxAge: 1
                },
            "expiryTs": _adb_timestampInMillis() - 1000
        },
        "kndctr_1234_AdobeOrg_cluster3": {
            "payload" : {
                    key: "kndctr_1234_AdobeOrg_cluster3",
                    value: "or4",
                    maxAge: 1800
                },
            "expiryTs": _adb_timestampInMillis() - 500
        },
        "kndctr_1234_AdobeOrg_cluster4": {
            "payload" : {
                    key: "kndctr_1234_AdobeOrg_cluster4",
                    value: "or5",
                    maxAge: 1800
                },
            "expiryTs": _adb_timestampInMillis() + 500
        }

    }

    persistedStateStoreMapJson = FormatJson(stateStoreMap)

    _adb_testUtil_persistStateStore(persistedStateStoreMapJson)

    stateStoreManager._init()

    expectedStateStore = [
        {
            key: "kndctr_1234_AdobeOrg_cluster",
            value: "or2",
            maxAge: 1800
        },
        {
            key: "kndctr_1234_AdobeOrg_cluster4",
            value: "or5",
            maxAge: 1800
        }
    ]

    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual(2, actualStateStore.count(), generateErrorMessage("State store", 2, actualStateStore.count()))
    UTF_assertTrue(_adb_testUtil_ArrayContains(actualStateStore, "kndctr_1234_AdobeOrg_cluster"), generateErrorMessage("State store", expectedStateStore, actualStateStore))
    UTF_assertTrue(_adb_testUtil_ArrayContains(actualStateStore, "kndctr_1234_AdobeOrg_cluster4"), generateErrorMessage("State store", expectedStateStore, actualStateStore))
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


' target: _adb_StateStoreManager_processStateStoreHandle()
' @Test
sub TC_adb_StateStoreManager_processStateStoreHandle_validHandle_maxAgeZeroOrless()
    stateStoreManager = _adb_StateStoreManager()

    handle = {
        payload: [
            {
                key: "kndctr_1234_AdobeOrg_cluster",
                value: "or2",
                maxAge: 0
            },
            {
                key: "kndctr_1234_AdobeOrg_cluster2",
                value: "or3",
                maxAge: -1
            }
        ],
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(handle)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertEqual([], actualStateStore, generateErrorMessage("State store", [], actualStateStore))

    persistedStateStoreMapJson = _adb_testUtil_getPersistedStateStore()
    UTF_assertEqual({}, persistedStateStoreMapJson, generateErrorMessage("Persisted state store", {}, persistedStateStoreMapJson))
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

    persistedStateStoreMapJson = _adb_testUtil_getPersistedStateStore()
    UTF_assertEqual(2, persistedStateStoreMapJson.count(), generateErrorMessage("Persisted state store", 2, persistedStateStoreMapJson.count()))
    UTF_assertEqual(persistedStateStoreMapJson["key2"].payload, expectedStateStore["key2"], generateErrorMessage("Persisted state store", expectedStateStore["key2"].payload, persistedStateStoreMapJson["key2"]))
    UTF_assertEqual(persistedStateStoreMapJson["key3"].payload, expectedStateStore["key3"], generateErrorMessage("Persisted state store", expectedStateStore["key3"].payload, persistedStateStoreMapJson["key3"]))
end sub
