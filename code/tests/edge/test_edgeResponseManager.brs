' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_edgeResponseManager()
' @Test
sub TC_adb_EdgeResponseManager_Init()
    edgeResponseManager = _adb_edgeResponseManager()

    actualStateStore = edgeResponseManager.getStateStore()
    actualLocationHint = edgeResponseManager.getLocationHint()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
end sub

' target: _adb_EdgeResponseManager_stateStore()
' @Test
sub TC_adb_EdgeResponseManager_stateStore_valid()
    edgeResponseManager = _adb_edgeResponseManager()

    stateStore = [{ key: "value" }]
    edgeResponseManager._stateStoreManager.setStateStore(stateStore)
    UTF_assertEqual(stateStore, edgeResponseManager.getStateStore())
end sub

' target: _adb_EdgeResponseManager_stateStore()
' @Test
sub TC_adb_EdgeResponseManager_stateStore_invalid()
    edgeResponseManager = _adb_edgeResponseManager()

    edgeResponseManager._stateStoreManager.setStateStore(invalid)
    actualStateStore = edgeResponseManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    edgeResponseManager._stateStoreManager.setStateStore({})
    actualStateStore = edgeResponseManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid",actualStateStore))

    edgeResponseManager._stateStoreManager.setStateStore([])
    actualStateStore = edgeResponseManager.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))
end sub

' target: _adb_EdgeResponseManager_locationHint()
' @Test
sub TC_adb_EdgeResponseManager_locationHint_valid()
    edgeResponseManager = _adb_edgeResponseManager()

    locationHint = "locationHint"
    edgeResponseManager._locationHintManager.setLocationHint(locationHint)
    actualLocationHint = edgeResponseManager.getLocationHint()
    UTF_assertEqual(locationHint, edgeResponseManager.getLocationHint(), generateErrorMessage("Location hint", locationHint, actualLocationHint))
end sub

' target: _adb_EdgeResponseManager_locationHint()
' @Test
sub TC_adb_EdgeResponseManager_locationHint_invalid()
    edgeResponseManager = _adb_edgeResponseManager()

    edgeResponseManager._locationHintManager.setLocationHint(invalid)
    actualLocationHint = edgeResponseManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    edgeResponseManager._locationHintManager.setLocationHint("")
    actualLocationHint = edgeResponseManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
end sub
