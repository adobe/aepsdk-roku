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
    return (module <> invalid and module.type = "com.adobe.module.identity")
end function

function _adb_IdentityModule(configurationModule as object) as object
    if not _adb_isConfigurationModule(configurationModule) then
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.identity")

    module.Append({
        _EDGE_REQUEST_PATH: "/v1/interact",
        _configurationModule: configurationModule,
        _ecid: invalid,

        resetIdentities: function() as void
            m.updateECID(invalid)
        end function,

        getECID: function() as dynamic
            if _adb_isEmptyOrInvalidString(m._ecid)
                m._ecid = m._loadECID()
            end if

            if _adb_isEmptyOrInvalidString(m._ecid)
                m.updateECID(m._queryECID())
            end if

            _adb_logVerbose("IdentityModule::getECID() - Returning ECID:(" + FormatJson(m._ecid) + ")")
            return m._ecid
        end function,

        updateECID: function(ecid as dynamic) as void
            m._ecid = ecid
            if _adb_isEmptyOrInvalidString(m._ecid)
                _adb_logDebug("IdentityModule::updateECID() - Deleting ECID, updateECID() called with empty or invalid string value.")
                m._deleteECID()
            else
                _adb_logVerbose("IdentityModule::updateECID() - Saving ECID:(" + FormatJson(m._ecid) + ") in cache and persistence.")
                m._saveECID(m._ecid)
            end if

        end function,

        _loadECID: function() as dynamic
            _adb_logVerbose("IdentityModule::_loadECID() - Loading ECID from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            ecid = localDataStoreService.readValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID)

            return ecid
        end function,

        _saveECID: function(ecid as dynamic) as void
            _adb_logVerbose("IdentityModule::_saveECID() - Saving ECID:(" + FormatJson(ecid) + ") to presistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.writeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID, ecid)
        end function,

        _deleteECID: function() as void
            _adb_logVerbose("IdentityModule::_deleteECID() - Removing ECID from persistence.")
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.removeValue(_adb_InternalConstants().LOCAL_DATA_STORE_KEYS.ECID)
            return
        end function

        _queryECID: function() as dynamic
            _adb_logInfo("IdentityModule::_queryECID() - Fetching ECID from service side.")
            configId = m._configurationModule.getConfigId()
            edgeDomain = m._configurationModule.getEdgeDomain()

            if _adb_isEmptyOrInvalidString(configId)
                _adb_logError("IdentityModule::_queryECID() - Unable to fetch ECID from service side, invalid configuration.")
                return invalid
            end if

            url = _adb_buildEdgeRequestURL(configId, _adb_generate_UUID(), m._EDGE_REQUEST_PATH, invalid, edgeDomain)
            jsonBody = m._getECIDQueryPayload()
            networkResponse = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            remoteECID = m._getECIDFromQueryResponse(networkResponse)

            return remoteECID
        end function,

        _getECIDFromQueryResponse: function(networkResponse as dynamic) as dynamic
            if not _adb_isNetworkResponse(networkResponse)
                _adb_logError("IdentityModule::_getECIDFromQueryResponse() - Edge response is invalid.")
                return invalid
            end if

            responseJson = ParseJson(networkResponse.getResponseString())

            if _adb_isEmptyOrInvalidMap(responseJson) or not networkResponse.isSuccessful() or _adb_isEmptyOrInvalidString(networkResponse.getResponseString())
                _adb_logError("IdentityModule::_getECIDFromQueryResponse() - Request to fetch ECID failed with response: (" + FormatJson(responseJson) + ")")
                return invalid
            end if

            if _adb_isEmptyOrInvalidArray(responseJson.handle) or _adb_isEmptyOrInvalidArray(responseJson.handle[0].payload) or _adb_isEmptyOrInvalidString(responseJson.handle[0].payload[0].id)
                _adb_logError("IdentityModule::_getECIDFromQueryResponse() - Unable to parse ECID from the response: (" + FormatJson(responseJson) + ")")
                return invalid
            end if

            remoteECID = responseJson.handle[0].payload[0].id

            return remoteECID
        end function,

        _getECIDQueryPayload: function() as object
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

            return jsonBody
        end function,

        dump: function() as object
            return {
                ecid: m._ecid,
            }
        end function
    })
    return module
end function
