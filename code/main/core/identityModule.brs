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

function _adb_IdentityModule(identityState as object, edgeModule as object, task = invalid as object) as object
    if not _adb_isIdentityState(identityState)
        _adb_logError("IdentityModule::_adb_IdentityModule() - identityState is not valid.")
        return invalid
    end if

    if not _adb_isEdgeModule(edgeModule)
        _adb_logError("IdentityModule::_adb_IdentityModule() - edgeModule is not valid.")
        return invalid
    end if

    identityModule = _adb_AdobeObject("com.adobe.module.identity")

    identityModule.Append({
        _CONSTANTS: _adb_InternalConstants(),
        _IDENTITY_RESULT_HANDLE_TYPE: "identity:result",
        _STATE_STORE_HANDLE_TYPE: "state:store",
        _EDGE_REQUEST_PATH: "/v1/interact",
        _RESPONSE_CODE_200: 200,
        _RESPONSE_CODE_300: 300,
        _identityState: invalid,
        _edgeModule: invalid,
        _ecid: invalid,
        _identityRequestEventIds: [],
        _task: invalid,

        _init: function(identityState as object, edgeModule as object, task = invalid as object) as void
            _adb_logVerbose("IdentityModule::init() - Initializing identity module.")
            m._identityState = identityState
            m._edgeModule = edgeModule
            m._task = task
        end function,

        resetIdentities: function() as void
            _adb_logDebug("IdentityModule::resetIdentities() - Resetting identities.")
            m._identityState.resetIdentities()
        end function,

        setECID: function(ecid as dynamic) as void
            _adb_logDebug("IdentityModule::setECID() - Setting ECID:(" + FormatJson(ecid) + ")")
            m._identityState.updateECID(ecid)
        end function,

        getECID: function(event = invalid as object) as dynamic
            _adb_logDebug("IdentityModule::getECID() - getting ECID.")
            ecid = m._identityState.getECID()

            if not _adb_isEmptyOrInvalidMap(event) and not _adb_isEmptyOrInvalidString(event.uuid)
                ' Add the request event id to the list of events that are waiting for ECID
                ' Used to call the callback of the public API once the ECID is fetched
                m._identityRequestEventIds.push(event.uuid)
            end if

            if _adb_isEmptyOrInvalidString(ecid)
                _adb_logDebug("IdentityModule::getECID() - ECID not found in the cache, querying edge server to fetch ECID.")
                m._queryECID()
            else if not _adb_isEmptyOrInvalidString(m._identityRequestEventIds.GetEntry(0))
                ' If ECID is already set, dispatch the response event to the task
                _adb_logDebug("IdentityModule::getECID() - ECID found in the cache, dispatching response event to the task.")
                ecidResponseEvent = _adb_IdentityResponseEvent(m._identityRequestEventIds.Shift(), ecid)
                m._dispatchECIDResponseEventToTask(ecidResponseEvent)
            end if

            _adb_logVerbose("IdentityModule::getECID() - Returning ECID:(" + FormatJson(ecid) + ")")

            return ecid
        end function,

        _queryECID: function() as dynamic
            _adb_logInfo("IdentityModule::_queryECID() - Queuing request with edge to fetch ECID from server.")

            requestId = _adb_generate_UUID()
            m._edgeModule.queueEdgeRequest(requestId, m._getECIDQueryPayload(), _adb_timestampInMillis(), {}, m._EDGE_REQUEST_PATH)
        end function,

        processResponseEvent: function(responseEvent as object) as void
            try
                currentECID = m._identityState.getECID()
                if not _adb_isEmptyOrInvalidString(currentECID)
                    ' No need to process the response if the current ECID is already set
                    return
                end if

                ' ECID is not set, process the response to get the ECID
                remoteECID = m._extractECIDFromEdgeRespose(responseEvent)

                if _adb_isEmptyOrInvalidString(remoteECID)
                    _adb_logDebug("IdentityModule::processResponseEvent() - ECID not found in the edge response.")
                    return
                end if

                if _adb_isEmptyOrInvalidString(currentECID) or remoteECID <> currentECID
                    _adb_logDebug("IdentityModule::processResponseEvent() - Got ECID from Edge response. Updating ECID from: (" + FormatJson(currentECID) + ") to: (" + FormatJson(remoteECID) + ")")

                    m._identityState.updateECID(remoteECID)

                    ' Check if there are any events waiting for ECID
                    requestEventId = m._identityRequestEventIds.Shift()
                    if not _adb_isEmptyOrInvalidString(requestEventId)
                        ecidResponseEvent = _adb_IdentityResponseEvent(requestEventId, remoteECID)
                        m._dispatchECIDResponseEventToTask(ecidResponseEvent)
                    end if
                end if

            catch exception
                _adb_logError("IdentityModule::processResponseEvent() - Failed to process the edge response, the exception message: " + exception.Message)
            end try
        end function,

        _extractECIDFromEdgeRespose: function(responseEvent as object) as dynamic
            remoteECID = invalid
            if not _adb_isEdgeResponseEvent(responseEvent)
                return remoteECID
            end if

            _adb_logVerbose("IdentityModule::processResponseEvent() - Received response event:(" + chr(10) + FormatJson(responseEvent) + chr(10) + ")")
            eventData = responseEvent.data
            responseCode = eventData.code
            responseString = eventData.message

            if responseCode < m._RESPONSE_CODE_200 or responseCode >= m._RESPONSE_CODE_300
                return remoteECID
            end if

            responseJson = ParseJson(responseString)

            if _adb_isEmptyOrInvalidMap(responseJson)
                _adb_logError("IdentityModule::processResponseEvent() - Request to fetch ECID failed with response: (" + FormatJson(responseJson) + ")")
                return remoteECID
            end if

            handles = responseJson.handle
            if _adb_isEmptyOrInvalidArray(handles)
                return remoteECID
            end if

            for each handle in handles
                if _adb_isEmptyOrInvalidMap(handle)
                    continue for
                end if

                if _adb_stringEqualsIgnoreCase(handle.type, m._IDENTITY_RESULT_HANDLE_TYPE)
                    remoteECID = m._getEcidFromIdentityResultHandle(handle)
                    exit for
                else if _adb_stringEqualsIgnoreCase(handle.type, m._STATE_STORE_HANDLE_TYPE) and _adb_isEmptyOrInvalidString(remoteECID)
                    remoteECID = m._getEcidFromStateStoreHandle(handle)
                    ' not breaking here to check if ECID is present in identity:result handle
                end if
            end for

            return remoteECID
        end function,

        _getEcidFromIdentityResultHandle: function(handle as object) as dynamic
            ecid = invalid
            if _adb_isEmptyOrInvalidMap(handle) or _adb_isEmptyOrInvalidArray(handle.payload)
                return ecid
            end if

            for each payload in handle.payload
                if not _adb_isEmptyOrInvalidMap(payload.namespace) and _adb_stringEqualsIgnoreCase(payload.namespace.code, "ECID")
                    ecid = payload.id
                    exit for
                end if
            end for

            return ecid
        end function,

        _getEcidFromStateStoreHandle: function(handle as object) as dynamic
            ecid = invalid
            if _adb_isEmptyOrInvalidMap(handle) or _adb_isEmptyOrInvalidArray(handle.payload)
                return ecid
            end if

            for each payload in handle.payload
                if _adb_stringContains(payload.key, "_AdobeOrg_identity")
                    ecid = payload.value
                    exit for
                end if
            end for

            return ecid
        end function,

        _dispatchECIDResponseEventToTask: function(event as object) as void
            if m._task = invalid
                _adb_logError("IdentityModule::_dispatchResponseEventToTask() - Cannot send response event, task node instance is invalid.")
                return
            end if

            m._task[m._CONSTANTS.TASK.RESPONSE_EVENT] = event
        end function,

        _getECIDQueryPayload: function() as object
            jsonBody = {
                "query": {
                    "identity": {
                        "fetch": [
                            "ECID"
                        ]
                    }
                }
            }

            return jsonBody
        end function,

        dump: function() as object
            return {
                ecid: m._identityState.getECID(),
            }
        end function
    })

    identityModule._init(identityState, edgeModule, task)

    return identityModule
end function
