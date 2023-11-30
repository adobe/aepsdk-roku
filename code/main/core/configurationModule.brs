' ********************** Copyright 2023 Adobe. All rights reserved. **********************
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

' ******************************* MODULE: Configuration ***********************************

function _adb_isConfigurationModule(module as object) as boolean
    return (module <> invalid and module.type = "com.adobe.module.configuration")
end function

function _adb_ConfigurationModule() as object
    module = _adb_AdobeObject("com.adobe.module.configuration")
    module.Append({
        _CONFIG_KEY: AdobeAEPSDKConstants().CONFIGURATION,
        ' edge configuration
        ' example: {"edge.configId":"1234567890", "edge.domain":"xyz.net"}
        _edge_configId: invalid,
        _edge_domain: invalid,
        ' media configuration
        ' example: {"edgemedia.channel":"channel_x", "edgemedia.playerName": "player_y", "edgemedia.appVersion": "1.0.0"}
        _media_channel: invalid,
        _media_playerName: invalid,
        _media_appVersion: invalid,

        updateConfiguration: function(configuration as object) as void

            ' update Edge configuration
            configId = _adb_optStringFromMap(configuration, m._CONFIG_KEY.EDGE_CONFIG_ID)
            if not _adb_isEmptyOrInvalidString(configId)
                m._edge_configId = configId
            end if

            '  example domain: company.data.adobedc.net
            domain = _adb_optStringFromMap(configuration, m._CONFIG_KEY.EDGE_DOMAIN)
            regexPattern = CreateObject("roRegex", "^((?!-)[A-Za-z0-9-]+(?<!-)\.)+[A-Za-z]{2,6}$", "")
            if not _adb_isEmptyOrInvalidString(domain) and regexPattern.isMatch(domain)
                m._edge_domain = domain
            end if

            ' update Media configuration
            channel = _adb_optStringFromMap(configuration, m._CONFIG_KEY.MEDIA_CHANNEL)
            if not _adb_isEmptyOrInvalidString(channel)
                m._media_channel = channel
            end if
            playerName = _adb_optStringFromMap(configuration, m._CONFIG_KEY.MEDIA_PLAYER_NAME)
            if not _adb_isEmptyOrInvalidString(playerName)
                m._media_playerName = playerName
            end if
            appVersion = _adb_optStringFromMap(configuration, m._CONFIG_KEY.MEDIA_APP_VERSION)
            if not _adb_isEmptyOrInvalidString(appVersion)
                m._media_appVersion = appVersion
            end if

        end function,

        getConfigId: function() as dynamic
            return m._edge_configId
        end function,

        getEdgeDomain: function() as dynamic
            return m._edge_domain
        end function,

        getMediaChannel: function() as dynamic
            return m._media_channel
        end function,

        getMediaPlayerName: function() as dynamic
            return m._media_playerName
        end function,

        getMediaAppVersion: function() as dynamic
            return m._media_appVersion
        end function,

        dump: function() as object
            return {
                edge_configId: m._edge_configId,
                edge_domain: m._edge_domain,
                media_channel: m._media_channel,
                media_playerName: m._media_playerName,
                media_appVersion: m._media_appVersion
            }
        end function
    })
    return module
end function
