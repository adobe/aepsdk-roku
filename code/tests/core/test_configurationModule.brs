' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_init()
    configurationModule = _adb_ConfigurationModule()
    UTF_assertInvalid(configurationModule.getConfigId())
    UTF_assertInvalid(configurationModule.getEdgeDomain())
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_configId()
    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration({
        "edge.configId": "testConfigId"
    })
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertInvalid(configurationModule.getEdgeDomain())
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_edgeDomain()
    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration({
        "edge.configId": "testConfigId"
        "edge.domain": "abc.net"
    })

    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_edgeDomain_invalidValues()
    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration({
        "edge.domain": "abc.net?"
    })
    UTF_assertInvalid(configurationModule.getEdgeDomain())

    configurationModule.updateConfiguration({
        "edge.domain": "https://abc.net"
    })
    UTF_assertInvalid(configurationModule.getEdgeDomain())

    configurationModule.updateConfiguration({
        "edge.domain": "abc.net/"
    })
    UTF_assertInvalid(configurationModule.getEdgeDomain())

    configurationModule.updateConfiguration({
        "edge.domain": "abc/net/path"
    })
    UTF_assertInvalid(configurationModule.getEdgeDomain())
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_separateUpdates()
    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration({
        "edge.configId": "testConfigId"
    })
    configurationModule.updateConfiguration({
        "edge.domain": "abc.net"
    })
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
end sub


' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_invalidConfigurationKeys()
    configurationModule = _adb_ConfigurationModule()
    invalidConfig = {
        "edgeDomain": "abc",
        "configId": "testConfigId"
    }
    configurationModule.updateConfiguration(invalidConfig)
    UTF_assertInvalid(configurationModule.getConfigId())
    UTF_assertInvalid(configurationModule.getEdgeDomain())
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_invalidConfigurationValues()
    configurationModule = _adb_ConfigurationModule()
    invalidConfig = {
        "edge.configId": ""
        "edge.domain": ""
    }

    configurationModule.updateConfiguration(invalidConfig)
    UTF_assertInvalid(configurationModule.getConfigId())
    UTF_assertInvalid(configurationModule.getEdgeDomain())

    invalidConfig = {
        "edge.configId": invalid
        "edge.domain": invalid
    }

    configurationModule.updateConfiguration(invalidConfig)
    UTF_assertInvalid(configurationModule.getConfigId())
    UTF_assertInvalid(configurationModule.getEdgeDomain())

    invalidConfig = {
        "edge": {
            "configId": "configId",
            "domain": "domain"
        }
    }

    configurationModule.updateConfiguration(invalidConfig)
    UTF_assertInvalid(configurationModule.getConfigId())
    UTF_assertInvalid(configurationModule.getEdgeDomain())
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_validMediaConfig()
    configurationModule = _adb_ConfigurationModule()
    config = {
        "edge.configId": "testConfigId"
        "edge.domain": "abc.net",
        "edgemedia.channel": "testChannel",
        "edgemedia.playerName": "testPlayerName",
        "edgemedia.appVersion": "1.1.0",

    }
    configurationModule.updateConfiguration(config)
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
    UTF_assertEqual(configurationModule.getMediaChannel(), "testChannel")
    UTF_assertEqual(configurationModule.getMediaPlayerName(), "testPlayerName")
    UTF_assertEqual(configurationModule.getMediaAppVersion(), "1.1.0")
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_overwrittingMediaConfig()
    configurationModule = _adb_ConfigurationModule()
    config = {
        "edge.configId": "testConfigId"
        "edge.domain": "abc.net",
        "edgemedia.channel": "testChannel",
        "edgemedia.playerName": "testPlayerName",
        "edgemedia.appVersion": "1.1.0",

    }
    configurationModule.updateConfiguration(config)
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
    UTF_assertEqual(configurationModule.getMediaChannel(), "testChannel")
    UTF_assertEqual(configurationModule.getMediaPlayerName(), "testPlayerName")
    UTF_assertEqual(configurationModule.getMediaAppVersion(), "1.1.0")
    configurationModule.updateConfiguration({
        "edgemedia.channel": "testChannel_001",
        "edgemedia.appVersion": "1.1.1",
    })
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
    UTF_assertEqual(configurationModule.getMediaChannel(), "testChannel_001")
    UTF_assertEqual(configurationModule.getMediaPlayerName(), "testPlayerName")
    UTF_assertEqual(configurationModule.getMediaAppVersion(), "1.1.1")
    configurationModule.updateConfiguration({
        "edgemedia.playerName": "",
        "edgemedia.appVersion": "",
    })
    ' updateConfiguration API doesn't support the deletion of the configuraiton values for now, so the values will not be updated
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
    UTF_assertEqual(configurationModule.getMediaChannel(), "testChannel_001")
    UTF_assertEqual(configurationModule.getMediaPlayerName(), "testPlayerName")
    UTF_assertEqual(configurationModule.getMediaAppVersion(), "1.1.1")
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_emptyMediaConfig()
    configurationModule = _adb_ConfigurationModule()
    config = {
        "edge.configId": "testConfigId"
        "edge.domain": "abc.net"
    }
    configurationModule.updateConfiguration(config)
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
    UTF_assertInvalid(configurationModule.getMediaChannel())
    UTF_assertInvalid(configurationModule.getMediaPlayerName())
    UTF_assertInvalid(configurationModule.getMediaAppVersion())
end sub

' target: adb_ConfigurationModule()
' @Test
sub TC_adb_ConfigurationModule_invalidMediaConfig()
    configurationModule = _adb_ConfigurationModule()
    config = {
        "edge.configId": "testConfigId"
        "edge.domain": "abc.net",
        "edgemedia.channel": "testChannel",
        "edgemedia.playerName": "testPlayerName",
        "edgemedia.appVersion": "1.1.0",
        "edgemedia.unsupportedKey": "unsupported",
        "edgemediaX.unsupported": "edgemediaX",
        "edgemediaY": "edgemediaY",
    }
    configurationModule.updateConfiguration(config)
    UTF_assertEqual(configurationModule.getConfigId(), "testConfigId")
    UTF_assertEqual(configurationModule.getEdgeDomain(), "abc.net")
    UTF_assertEqual(configurationModule.getMediaChannel(), "testChannel")
    UTF_assertEqual(configurationModule.getMediaPlayerName(), "testPlayerName")
    UTF_assertEqual(configurationModule.getMediaAppVersion(), "1.1.0")
end sub