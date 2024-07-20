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

' ******************************* MODULE: EdgeResponseManager *******************************

function _adb_EdgeResponseManager() as object
    return {
        _LOCATION_HINT_HANDLE_TYPE: "locationHint:result",
        _STATE_STORE_HANDLE_TYPE: "state:store",
        _locationHintManager: _adb_LocationHintManager(),
        _stateStoreManager: _adb_StateStoreManager(),

        getLocationHint: function() as dynamic
            return m._locationHintManager.getLocationHint()
        end function,

        getStateStore: function() as object
            return m._stateStoreManager.getStateStore()
        end function,

        processResponse: function(edgeResponse as object) as void
            _adb_logVerbose("EdgeResponseManager::processResponse() - Processing response: (" + FormatJson(edgeResponse) + ").")

            try
                responseString = edgeResponse.getResponseString()
                responseJson = ParseJson(responseString)
                if _adb_isEmptyOrInvalidMap(responseJson)
                    _adb_logError("EdgeResponseManager::_processResponseOnSuccess() - Failed to parse response: (" + FormatJson(responseString) + ")")
                    return
                end if

                handles = responseJson.handle
                if _adb_isEmptyOrInvalidArray(handles)
                    _adb_logVerbose("EdgeResponseManager::_processResponseOnSuccess() - Empty handles in the response.")
                    return
                end if

                for each handle in handles
                    if _adb_isEmptyOrInvalidMap(handle)
                        continue for
                    end if

                    if handle.type = m._LOCATION_HINT_HANDLE_TYPE
                        m._locationHintManager.processLocationHintHandle(handle)
                    else if handle.type = m._STATE_STORE_HANDLE_TYPE
                        m._stateStoreManager.processStateStoreHandle(handle)
                    end if
                end for
            catch exception
                _adb_logError("EdgeResponseManager::_processResponseOnSuccess() - Failed to handle edge response: (" + FormatJson(responseString) + ")")
            end try
        end function
    }

end function
