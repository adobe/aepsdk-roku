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

' ************************************ MODULE: Edge ***************************************

function _adb_isEdgeModule(module as object) as boolean
    return (module <> invalid and module.type = "com.adobe.module.edge")
end function

function _adb_EdgeModule(configurationModule as object, identityModule as object) as object
    if _adb_isConfigurationModule(configurationModule) = false then
        _adb_logError("EdgeModule::_adb_EdgeModule() - configurationModule is not valid.")
        return invalid
    end if

    if _adb_isIdentityModule(identityModule) = false then
        _adb_logError("EdgeModule::_adb_EdgeModule() - identityModule is not valid.")
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.edge")
    module.Append({
        _EDGE_REQUEST_PATH: "/ee/v1/interact",
        _configurationModule: configurationModule,
        _identityModule: identityModule,
        _edgeRequestWorker: _adb_EdgeRequestWorker(),

        processEvent: function(requestId as string, eventData as object, timestampInMillis as longinteger) as dynamic
            m._edgeRequestWorker.queue(requestId, eventData, timestampInMillis, {}, m._EDGE_REQUEST_PATH)
            return m.processQueuedRequests()
        end function,

        createEdgeRequestQueue: function(name as string) as object
            return _adb_edgeRequestQueue(name, m)
        end function,

        _getEdgeConfig: function() as object
            configId = m._configurationModule.getConfigId()
            if _adb_isEmptyOrInvalidString(configId)
                return invalid
            end if
            ecid = m._identityModule.getECID()
            if _adb_isEmptyOrInvalidString(ecid)
                return invalid
            end if
            return {
                configId: configId,
                ecid: ecid,
                edgeDomain: m._configurationModule.getEdgeDomain()
            }
        end function,

        processQueuedRequests: function() as object
            responseEvents = []

            if not m._edgeRequestWorker.hasQueuedEvent()
                ''' no requests to process
                return responseEvents
            end if

            edgeConfig = m._getEdgeConfig()
            if edgeConfig = invalid
                return responseEvents
            end if

            responses = m._edgeRequestWorker.processRequests(edgeConfig.configId, edgeConfig.ecid, edgeConfig.edgeDomain)

            for each edgeResponse in responses
                if _adb_isEdgeResponse(edgeResponse) then
                    responseEvent = _adb_ResponseEvent(edgeResponse.getRequestId(), {
                        code: edgeResponse.getResponseCode(),
                        message: edgeResponse.getResponseString()
                    })
                    responseEvents.Push(responseEvent)
                end if
            end for


            return responseEvents
        end function,

        dump: function() as object
            return {
                requestQueue: m._edgeRequestWorker._queue
            }
        end function
    })
    return module
end function
