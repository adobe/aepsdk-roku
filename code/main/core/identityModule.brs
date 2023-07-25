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

' ******************************* MODULE: Identity ***********************************

function _adb_isIdentityModule(module as object) as boolean
    if module <> invalid and module.type = "com.adobe.module.identity" then
        return true
    end if
    return false
end function

function _adb_IdentityModule(configurationModule as object) as object
    if not _adb_isConfigurationModule(configurationModule) then
        return invalid
    end if
    module = _adb_AdobeObject("com.adobe.module.identity")
    module.Append({
        _configurationModule: configurationModule,
        _ecid: invalid,

        resetIdentities: function() as void
            m.updateECID(invalid)
        end function,

        getECID: function() as dynamic
            if m._ecid = invalid
                _adb_logVerbose("getECID() - ECID not found in cache, fetching it from presistence.")
                m._ecid = m._loadECID()
            end if

            if m._ecid = invalid
                _adb_logVerbose("getECID() - ECID not found in persistence, fetching it from service side.")
                remote_ecid = m._queryECID()
                if not _adb_isEmptyOrInvalidString(remote_ecid)
                    _adb_logVerbose("getECID() - Fetched ECID:(" + FormatJson(m._ecid) + ") from service side")
                    m.updateECID(remote_ecid)
                end if
            end if

            _adb_logDebug("getECID() - Returning ECID:(" + FormatJson(m._ecid) + ")")
            return m._ecid
        end function,

        updateECID: function(ecid as dynamic) as void
            if ecid <> invalid and ecid = m._ecid
                _adb_logVerbose("updateECID() - Not updating ECID. Same value is cached and persisted.")
                return
            end if
            if ecid = invalid
                _adb_logDebug("updateECID() - Deleting ECID.")
            end if
            _adb_logVerbose("updateECID() - Saving ECID:(" + FormatJson(ecid) + ") in cache and persistence.")
            m._ecid = ecid
            m._saveECID(m._ecid)
        end function,

        _loadECID: function() as dynamic
            _adb_logInfo("_loadECID() - Loading ECID from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            ecid = localDataStoreService.readValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID)

            if ecid = invalid
                _adb_logInfo("_loadECID() - Failed to load ECID from persistence, not found.")
            end if

            return ecid
        end function,

        _saveECID: function(ecid as dynamic) as void
            localDataStoreService = _adb_serviceProvider().localDataStoreService

            if ecid = invalid
                _adb_logDebug("_saveECID() - Removing ECID from persistence.")
                localDataStoreService.removeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID)
                return
            end if

            _adb_logVerbose("_saveECID() - Saving ECID:(" + FormatJson(ecid) + ") to presistence.")
            localDataStoreService.writeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID, ecid)
        end function,

        _queryECID: function() as dynamic
            _adb_logInfo("_queryECID() - Fetching ECID from service side.")
            configId = m._configurationModule.getConfigId()
            edgeDomain = m._configurationModule.getEdgeDomain()

            if _adb_isEmptyOrInvalidString(configId)
                _adb_logError("_queryECID() - Unable to fetch ECID from service side, invalid configuration.")
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
            networkResponse = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)

            if not _adb_isNetworkResponse(networkResponse)
                _adb_logError("processRequests() - Edge response is invalid.")
                return invalid
            end if

            if networkResponse.isSuccessful() and networkResponse.getResponseString() <> invalid
                responseJson = ParseJson(networkResponse.getResponseString())
                if responseJson <> invalid and responseJson.handle[0] <> invalid and responseJson.handle[0].payload[0] <> invalid
                    _adb_logVerbose("_queryECID() - Received response with payload: (" + FormatJson(responseJson) + ").")
                    remote_ecid = responseJson.handle[0].payload[0].id
                    return remote_ecid
                else
                    _adb_logError("_queryECID() - Error extracting ECID, invalid response from server.")
                    return invalid
                end if
            else
                _adb_logError("_queryECID() - Error occured while quering ECID from service side. Please verify the edge configuration.The response code : " + FormatJson(responseJson.code))
                return invalid
            end if

        end function,

        dump: function() as object
            return {
                ecid: m._ecid,
            }
        end function
    })
    return module
end function