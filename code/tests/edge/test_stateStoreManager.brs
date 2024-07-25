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
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))
end sub

' target: _adb_StateStoreManager_stateStore()
' @Test
sub TC_adb_EdgeResponseManager_stateStore_valid()
    stateStoreManager = _adb_StateStoreManager()

    stateStore = [{ key: "value" }]

    stateStoreManager.setStateStore(stateStore)
    actualStateStore = stateStoreManager.getStateStore()

    UTF_assertEqual(actualStateStore, stateStore, generateErrorMessage("State store", stateStore, actualStateStore))
end sub

' target: _adb_StateStoreManager_stateStore()
' @Test
sub TC_adb_StateStoreManager_stateStore_invalid()
    stateStoreManager = _adb_StateStoreManager()

    stateStoreManager.setStateStore(invalid)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    stateStoreManager.setStateStore({})
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    stateStoreManager.setStateStore([])
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))
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
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    stateStoreManager.processStateStoreHandle({})
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    invalidhandle = {
        ' missing payload list
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(invalidhandle)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    invalidhandle = {
        payload: [
            ' empty payload
        ],
        type: "state:store"
    }

    stateStoreManager.processStateStoreHandle(invalidhandle)
    actualStateStore = stateStoreManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))
end sub
