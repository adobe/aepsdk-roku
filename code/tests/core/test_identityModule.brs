' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeEach
sub TS_identityModule_BeforeEach()
    clearPersistedECID()
end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_bad_init()
    identityModule = _adb_IdentityModule({})

    UTF_assertInvalid(identityModule)
end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_getECID_noSetECID_invalidConfiguration_returnsInvalid()
    identityModule = _adb_IdentityModule(_adb_ConfigurationModule())

    UTF_assertInvalid(identityModule._ecid)

    ' fetches ECID from server and returns
    generatedECID = identityModule.getECID()
    UTF_assertInvalid(generatedECID)

    ' verify if the ecid is persisted
    persistedECID = getPersistedECID()
    UTF_assertInvalid(identityModule._ecid)
    UTF_assertInvalid(persistedECID)

end sub

' target: _adb_IdentityModule()
' Note: Add actual configId and run this test
' @Ignore
sub TC_adb_IdentityModule_getECID_validConfiguration_fetchesECID()
    ' identityModule = _adb_IdentityModule()
    ' config = {
    '     "edge.configId": "<test-with-actual-config-id>"
    ' }
    ' identityModule.updateConfiguration(config)

    ' UTF_assertInvalid(identityModule._ecid)

    ' ' fetches ECID from server and returns
    ' generatedECID = identityModule.getECID()
    ' UTF_assertNotInvalid(generatedECID)

    ' ' verify if the ecid is persisted
    ' persistedECID = getPersistedECID()
    ' UTF_assertFalse(isEmptyOrInvalidString(identityModule._ecid))
    ' UTF_assertFalse(isEmptyOrInvalidString(persistedECID))

end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_updateECID_validString_updatesECID()
    identityModule = _adb_IdentityModule(_adb_ConfigurationModule())

    UTF_assertInvalid(identityModule._ecid)

    identityModule.updateECID("test-ecid")

    persistedECID = getPersistedECID()

    UTF_assertEqual("test-ecid", identityModule._ecid)
    UTF_assertNotInvalid(persistedECID)
    UTF_assertEqual("test-ecid", persistedECID)
end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_updateECID_invalid_deletesECID()
    identityModule = _adb_IdentityModule(_adb_ConfigurationModule())

    UTF_assertInvalid(identityModule._ecid)

    identityModule.updateECID("test-ecid")

    persistedECID = getPersistedECID()

    UTF_assertEqual("test-ecid", identityModule._ecid)
    UTF_assertNotInvalid(persistedECID)
    UTF_assertEqual("test-ecid", persistedECID)

    identityModule.updateECID(invalid)
    persistedECID = getPersistedECID()
    UTF_assertInvalid(identityModule._ecid)
    UTF_assertInvalid(persistedECID)

end sub

' target: _adb_IdentityModule()
' @Test
sub TC_adb_IdentityModule_resetIdentities_deletesECIDAndOtherIdentities()
    identityModule = _adb_IdentityModule(_adb_ConfigurationModule())

    UTF_assertInvalid(identityModule._ecid)

    identityModule.updateECID("test-ecid")

    persistedECID = getPersistedECID()

    UTF_assertEqual("test-ecid", identityModule._ecid)
    UTF_assertNotInvalid(persistedECID)
    UTF_assertEqual("test-ecid", persistedECID)

    identityModule.resetIdentities()
    persistedECID = getPersistedECID()
    UTF_assertInvalid(identityModule._ecid)
    UTF_assertInvalid(persistedECID)

end sub
