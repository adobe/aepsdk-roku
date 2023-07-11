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

' ******************************** MODULE: StateManager ***********************************

function _adb_StateManager() as object
    return {
        CONFIG_KEY: AdobeSDKConstants().CONFIGURATION,
        _edge_configId: invalid,
        _edge_domain: invalid,
        _ecid: invalid,
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

        resetIdentities: function() as void
            m.updateECID(invalid)
        end function,

        getECID: function() as dynamic
            if m._ecid = invalid
                _adb_log_verbose("getECID() - ECID not found in cache, fetching it from presistence.")
                m._ecid = m._loadECID()
            end if

            if m._ecid = invalid
                _adb_log_verbose("getECID() - ECID not found in persistence, fetching it from service side.")
                remote_ecid = m._queryECID()
                if not _adb_isEmptyOrInvalidString(remote_ecid)
                    _adb_log_verbose("getECID() - Fetched ECID:(" + FormatJson(m._ecid) + ") from service side")
                    m.updateECID(remote_ecid)
                end if
            end if

            _adb_log_debug("getECID() - Returning ECID:(" + FormatJson(m._ecid) + ")")
            return m._ecid
        end function,

        getConfigId: function() as dynamic
            return m._edge_configId
        end function,

        getEdgeDomain: function() as dynamic
            return m._edge_domain
        end function,

        updateECID: function(ecid as dynamic) as void
            if ecid <> invalid and ecid = m._ecid
                _adb_log_verbose("updateECID() - Not updating ECID. Same value is cached and persisted.")
                return
            end if
            if ecid = invalid
                _adb_log_debug("updateECID() - Deleting ECID.")
            end if
            _adb_log_verbose("updateECID() - Saving ECID:(" + FormatJson(ecid) + ") in cache and persistence.")
            m._ecid = ecid
            m._saveECID(m._ecid)
        end function,

        isReadyForRequest: function() as boolean
            configId = m.getConfigId()
            if _adb_isEmptyOrInvalidString(configId)
                _adb_log_verbose("isReadyForRequest() - Confguration for edge.configId not found.")
                return false
            end if
            ecid = m.getECID()
            if _adb_isEmptyOrInvalidString(ecid)
                _adb_log_verbose("isReadyForRequest() - ECID not set. Please verify the configuration.")
                return false
            end if
            return true
        end function,

        _loadECID: function() as dynamic
            _adb_log_info("_loadECID() - Loading ECID from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            ecid = localDataStoreService.readValue(_adb_internal_constants().LOCAL_DATA_STORE_KEYS.ECID)

            if ecid = invalid
                _adb_log_info("_loadECID() - Failed to load ECID from persistence, not found.")
            end if

            return ecid
        end function,

        _saveECID: function(ecid as dynamic) as void
            localDataStoreService = _adb_serviceProvider().localDataStoreService

            if ecid = invalid
                _adb_log_debug("_saveECID() - Removing ECID from persistence.")
                localDataStoreService.removeValue(_adb_internal_constants().LOCAL_DATA_STORE_KEYS.ECID)
                return
            end if

            _adb_log_verbose("_saveECID() - Saving ECID:(" + FormatJson(ecid) + ") to presistence.")
            localDataStoreService.writeValue(_adb_internal_constants().LOCAL_DATA_STORE_KEYS.ECID, ecid)
        end function,

        _queryECID: function() as dynamic
            _adb_log_info("_queryECID() - Fetching ECID from service side.")
            configId = m.getConfigId()
            edgeDomain = m.getEdgeDomain()

            if _adb_isEmptyOrInvalidString(configId)
                _adb_log_error("_queryECID() - Unable to fetch ECID from service side, invalid configuration.")
                return invalid
            end if

            url = _adb_buildEdgeRequestURL(configId, _adb_generate_UUID(), edgeDomain)
            jsonBody = {
                "events": [
                    {
                        "query": {
                            "identity": { "fetch": [
                                    "ECID"
                            ] }

                        }
                    }
                ]
            }
            response = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            if response.code >= 200 and response.code < 300 and response.message <> invalid
                responseJson = ParseJson(response.message)
                if responseJson <> invalid and responseJson.handle[0] <> invalid and responseJson.handle[0].payload[0] <> invalid
                    _adb_log_verbose("_queryECID() - Received response with payload: (" + FormatJson(responseJson) + ").")
                    remote_ecid = responseJson.handle[0].payload[0].id
                    return remote_ecid
                else
                    _adb_log_error("_queryECID() - Error extracting ECID, invalid response from server.")
                    return invalid
                end if
            else
                _adb_log_error("_queryECID() - Error occured while quering ECID from service side. Please verify the edge configuration.The response code : " + StrI(response.code))
                return invalid
            end if
        end function,

        dump: function() as object
            return {
                edge_configId: m._edge_configId,
                edge_domain: m._edge_domain,
                ecid: m._ecid
            }
        end function
    }
end function