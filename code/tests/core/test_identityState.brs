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
sub TS_identityState_BeforeEach()
    clearPersistedECID()
end sub

' @AfterEach
sub TS_identityState_AfterEach()
    clearPersistedECID()
end sub

' target: _init()
' @Test
sub TC_adb_IdentityState_init_noPersistedECID()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    UTF_assertNotInvalid(identityState, generateErrorMessage("identityState", "not invalid", "invalid"))
    UTF_assertInvalid(identityState._ecid, generateErrorMessage("identityState._ecid", "invalid", "not invalid"))
end sub

' target: _init()
' @Test
sub TC_adb_IdentityState_init_persistedECID()
    _adb_testUtil_persistECID("persistedECID")

    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    actualECID = identityState._ecid
    UTF_assertNotInvalid(identityState, generateErrorMessage("identityState", "not invalid", "invalid"))
    UTF_assertEqual("persistedECID", actualECID, generateErrorMessage("identityState._ecid", "persistedECID", actualECID))
end sub

' target: resetIdentities()
' @Test
sub TC_adb_IdentityState_resetIdentities()
    _adb_testUtil_persistECID("persistedECID")

    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    actualECID = identityState._ecid
    UTF_assertEqual("persistedECID", actualECID, generateErrorMessage("identityState._ecid", "persistedECID", actualECID))

    identityState.resetIdentities()

    actualECID = identityState._ecid
    UTF_assertInvalid(actualECID, generateErrorMessage("identityState._ecid", "invalid", "not invalid"))
end sub

' target: getECID()
' @Test
sub TC_adb_IdentityState_getECID_noPersistedECID()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    actualECID = identityState.getECID()
    UTF_assertInvalid(actualECID, generateErrorMessage("get ECID", "invalid", "not invalid"))
end sub

' target: getECID()
' @Test
sub TC_adb_IdentityState_getECID_persistedECID()
    _adb_testUtil_persistECID("persistedECID")

    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    actualECID = identityState.getECID()
    UTF_assertEqual("persistedECID", actualECID, generateErrorMessage("get ECID", "persistedECID", actualECID))
end sub

' target: updateECID()
' @Test
sub TC_adb_IdentityState_updateECID()
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    identityState.updateECID("test-ecid")

    actualECID = identityState._ecid
    UTF_assertEqual("test-ecid", actualECID, generateErrorMessage("identityState._ecid", "test-ecid", actualECID))
end sub

' target: updateECID()
' @Test
sub TC_adb_IdentityState_updateECID_invalidECID()
    _adb_testUtil_persistECID("persistedECID")
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    actualECID = identityState._ecid
    UTF_assertEqual("persistedECID", actualECID, generateErrorMessage("identityState._ecid", "test-ecid", actualECID))

    identityState.updateECID(invalid)
    actualECID = identityState._ecid
    UTF_assertInvalid(actualECID, generateErrorMessage("get ECID", "invalid", "not invalid"))
end sub

' target: updateECID()
' @Test
sub TC_adb_IdentityState_updateECID_emptyECID()
    _adb_testUtil_persistECID("persistedECID")
    configurationModule = _adb_ConfigurationModule()
    identityState = _adb_IdentityState()

    actualECID = identityState._ecid
    UTF_assertEqual("persistedECID", actualECID, generateErrorMessage("identityState._ecid", "test-ecid", actualECID))

    identityState.updateECID("")
    actualECID = identityState._ecid
    UTF_assertInvalid(actualECID, generateErrorMessage("get ECID", "invalid", "not invalid"))
end sub

