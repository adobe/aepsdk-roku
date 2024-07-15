' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_konductorConfig()
' @Test
sub TC_adb_KonductorConfig_Init()
    konductorConfig = _adb_KonductorConfig()

    actualStateStore = konductorConfig.getStateStore()
    actualLocationHint = konductorConfig.getLocationHint()
    UTF_assertInvalid(konductorConfig.getStateStore(), generateErrorMessage("State store", "invalid", actualStateStore))
    UTF_assertInvalid(konductorConfig.getLocationHint(), generateErrorMessage("Location hint", "invalid", actualLocationHint))
end sub

' target: _adb_konductorConfig_stateStore()
' @Test
sub TC_adb_KonductorConfig_stateStore_valid()
    konductorConfig = _adb_KonductorConfig()

    stateStore = [{ key: "value" }]
    konductorConfig.setStateStore(stateStore)
    UTF_assertEqual(stateStore, konductorConfig.getStateStore())
end sub

' target: _adb_konductorConfig_stateStore()
' @Test
sub TC_adb_KonductorConfig_stateStore_invalid()
    konductorConfig = _adb_KonductorConfig()

    konductorConfig.setStateStore(invalid)
    actualStateStore = konductorConfig.getStateStore()
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))

    konductorConfig.setStateStore({})
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid",actualStateStore))

    konductorConfig.setStateStore([])
    UTF_assertInvalid(actualStateStore, generateErrorMessage("State store", "invalid", actualStateStore))
end sub

' target: _adb_konductorConfig_locationHint()
' @Test
sub TC_adb_KonductorConfig_locationHint_valid()
    konductorConfig = _adb_KonductorConfig()

    locationHint = "locationHint"
    konductorConfig.setLocationHint(locationHint)
    actualLocationHint = konductorConfig.getLocationHint()
    UTF_assertEqual(locationHint, konductorConfig.getLocationHint(), generateErrorMessage("Location hint", locationHint, actualLocationHint))
end sub

' target: _adb_konductorConfig_locationHint()
' @Test
sub TC_adb_KonductorConfig_locationHint_invalid()
    konductorConfig = _adb_KonductorConfig()

    konductorConfig.setLocationHint(invalid)
    actualLocationHint = konductorConfig.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    konductorConfig.setLocationHint("")
    actualLocationHint = konductorConfig.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
end sub
