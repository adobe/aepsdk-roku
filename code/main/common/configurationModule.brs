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

function _adb_ConfigurationModule() as object
    return {
        CONFIG_KEY: AdobeSDKConstants().CONFIGURATION,
        _edge_configId: invalid,
        _edge_domain: invalid,
        ' example config = {edge.configId:"1234567890", edge.domain:"xyz.net"}
        updateConfiguration: function(configuration as object) as void
            configId = _adb_optStringFromMap(configuration, m.CONFIG_KEY.EDGE_CONFIG_ID)
            domain = _adb_optStringFromMap(configuration, m.CONFIG_KEY.EDGE_DOMAIN)

            if not _adb_isEmptyOrInvalidString(configId)
                m._edge_configId = configId
            end if

            ' example domain: company.data.adobedc.net
            regexPattern = CreateObject("roRegex", "^((?!-)[A-Za-z0-9-]+(?<!-)\.)+[A-Za-z]{2,6}$", "")
            if not _adb_isEmptyOrInvalidString(domain) and regexPattern.isMatch(domain)
                m._edge_domain = domain
            end if
        end function,

        getConfigId: function() as dynamic
            return m._edge_configId
        end function,

        getEdgeDomain: function() as dynamic
            return m._edge_domain
        end function,

        dump: function() as object
            return {
                edge_configId: m._edge_configId,
                edge_domain: m._edge_domain
            }
        end function
    }
end function