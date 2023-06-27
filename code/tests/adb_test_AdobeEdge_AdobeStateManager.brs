' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


' @BeforeAll
sub TS_StateManager_SetUp()
    print "AdobeEdgeTestSuite_AdobeStateManager_SetUp"
end sub

' @BeforeEach
sub TS_StateaManager_BeforeEach()
    print "AdobeEdgeTestSuite_EventProcessor_BeforeEach"
    clearPersistedECID()
end sub

' @AfterAll
sub TS_StateManager_TearDown()
    print "AdobeEdgeTestSuite_AdobeStateManager_TearDown"
end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_init()
    stateManager = _adb_StateManager()
    UTF_assertInvalid(stateManager.getConfigId())
    UTF_assertInvalid(stateManager.getEdgeDomain())
end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_updateConfiguration_configId()
    stateManager = _adb_StateManager()
    stateManager.updateConfiguration({
        "edge.configId" : "testConfigId"
    })
    UTF_assertEqual(stateManager.getConfigId(), "testConfigId")
    UTF_assertInvalid(stateManager.getEdgeDomain())
end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_updateConfiguration_edgeDomain()
    stateManager = _adb_StateManager()
    stateManager.updateConfiguration({
        "edge.configId" : "testConfigId"
        "edge.domain" : "abc.net"
    })

    UTF_assertEqual(stateManager.getConfigId(), "testConfigId")
    UTF_assertEqual(stateManager.getEdgeDomain(), "abc.net")
end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_updateConfiguration_separateUpdates()
    stateManager = _adb_StateManager()
    stateManager.updateConfiguration({
        "edge.configId": "testConfigId"
    })
    stateManager.updateConfiguration({
        "edge.domain" : "abc.net"
    })
    UTF_assertEqual(stateManager.getConfigId(), "testConfigId")
    UTF_assertEqual(stateManager.getEdgeDomain(), "abc.net")
end sub


' target: _adb_StateManager()
' @Test
sub T_StateManager_updateConfiguration_invalidConfigurationKeys()
    stateManager = _adb_StateManager()
    invalidConfig = {
        "edgeDomain": "abc",
        "configId": "testConfigId"
     }
    stateManager.updateConfiguration(invalidConfig)
    UTF_assertInvalid(stateManager.getConfigId())
    UTF_assertInvalid(stateManager.getEdgeDomain())
end sub

sub T_StateManager_updateConfiguration_invalidConfigurationValues()
    stateManager = _adb_StateManager()
    invalidConfig = {
        "edge.configId" : ""
        "edge.domain" : ""
    }

    stateManager.updateConfiguration(invalidConfig)
    UTF_assertInvalid(stateManager.getConfigId())
    UTF_assertInvalid(stateManager.getEdgeDomain())

    invalidConfig = {
        "edge.configId" : invalid
        "edge.domain" : invalid
    }

    stateManager.updateConfiguration(invalidConfig)
    UTF_assertInvalid(stateManager.getConfigId())
    UTF_assertInvalid(stateManager.getEdgeDomain())

    invalidConfig = {
        "edge": {
            "configId" : "configId",
            "domain" : "domain"
        }
    }

    stateManager.updateConfiguration(invalidConfig)
    UTF_assertInvalid(stateManager.getConfigId())
    UTF_assertInvalid(stateManager.getEdgeDomain())
end sub


' target: _adb_StateManager()
' @Test
sub T_StateManager_getECID_noSetECID_invalidConfiguration_returnsInvalid()
    stateManager = _adb_StateManager()

    UTF_assertInvalid(stateManager._ecid)

    ' fetches ECID from server and returns
    generatedECID = stateManager.getECID()
    UTF_assertInvalid(generatedECID)

    ' verify if the ecid is persisted
    persistedECID = getPersistedECID()
    UTF_assertInvalid(stateManager._ecid)
    UTF_assertInvalid(persistedECID)

end sub

' target: _adb_StateManager()
' Note: Add actual configId and run this test
' @Ignore
sub T_StateManager_getECID_validConfiguration_fetchesECID()
    stateManager = _adb_StateManager()
    config = {
        "edge.configId": "<test-with-actual-config-id>"
      }
    stateManager.updateConfiguration(config)

    UTF_assertInvalid(stateManager._ecid)

    ' fetches ECID from server and returns
    generatedECID = stateManager.getECID()
    UTF_assertNotInvalid(generatedECID)

    ' verify if the ecid is persisted
    persistedECID = getPersistedECID()
    UTF_assertFalse(isEmptyOrInvalidString(stateManager._ecid))
    UTF_assertFalse(isEmptyOrInvalidString(persistedECID))

end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_updateECID_validString_updatesECID()
    stateManager = _adb_StateManager()

    UTF_assertInvalid(stateManager._ecid)

    stateManager.updateECID("test-ecid")

    persistedECID = getPersistedECID()

    UTF_assertEqual("test-ecid", stateManager._ecid)
    UTF_assertNotInvalid(persistedECID)
    UTF_assertEqual("test-ecid", persistedECID)
end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_updateECID_invalid_deletesECID()
    stateManager = _adb_StateManager()

    UTF_assertInvalid(stateManager._ecid)

    stateManager.updateECID("test-ecid")

    persistedECID = getPersistedECID()

    UTF_assertEqual("test-ecid", stateManager._ecid)
    UTF_assertNotInvalid(persistedECID)
    UTF_assertEqual("test-ecid", persistedECID)

    stateManager.updateECID(invalid)
    persistedECID = getPersistedECID()
    UTF_assertInvalid(stateManager._ecid)
    UTF_assertInvalid(persistedECID)

end sub

' target: _adb_StateManager()
' @Test
sub T_StateManager_resetIdentities_deletesECIDAndOtherIdentities()
    stateManager = _adb_StateManager()

    UTF_assertInvalid(stateManager._ecid)

    stateManager.updateECID("test-ecid")

    persistedECID = getPersistedECID()

    UTF_assertEqual("test-ecid", stateManager._ecid)
    UTF_assertNotInvalid(persistedECID)
    UTF_assertEqual("test-ecid", persistedECID)

    stateManager.resetIdentities()
    persistedECID = getPersistedECID()
    UTF_assertInvalid(stateManager._ecid)
    UTF_assertInvalid(persistedECID)

end sub


