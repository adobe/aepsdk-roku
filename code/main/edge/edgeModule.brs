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
    if module <> invalid and module.type = "com.adobe.module.edge" then
        return true
    end if
    return false
end function

function _adb_EdgeModule(configurationModule as object, identityModule as object) as object
    if _adb_isConfigurationModule(configurationModule) = false then
        _adb_logError("_adb_EdgeModule() - configurationModule is not valid.")
        return invalid
    end if

    if _adb_isIdentityModule(identityModule) = false = false then
        _adb_logError("_adb_EdgeModule() - identityModule is not valid.")
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.edge")
    module.Append({
        _configurationModule: configurationModule,
        _identityModule: identityModule,
        _edgeRequestWorker: _adb_EdgeRequestWorker(),

        processEvent: function(requestId as string, xdmData as object, timestampInMillis as integer) as dynamic
            m._edgeRequestWorker.queue(requestId, xdmData, timestampInMillis)
            return m.processQueuedRequests()
        end function,

        _getEdgeConfig: function() as object
            configId = m._configurationModule.getConfigId()
            if _adb_isEmptyOrInvalidString(configId)
                _adb_logVerbose("isReadyForRequest() - Confguration for edge.configId not found.")
                return invalid
            end if
            ecid = m._identityModule.getECID()
            if _adb_isEmptyOrInvalidString(ecid)
                _adb_logVerbose("isReadyForRequest() - ECID not set. Please verify the configuration.")
                return invalid
            end if
            return {
                configId: configId,
                ecid: ecid,
                edgeDomain: m._configurationModule.getEdgeDomain()
            }
        end function,

        processQueuedRequests: function() as dynamic
            responseEvents = []
            edgeConfig = m._getEdgeConfig()
            if m._edgeRequestWorker.hasQueuedEvent() and edgeConfig <> invalid then
                responses = m._edgeRequestWorker.processRequests(edgeConfig.configId, edgeConfig.ecid, edgeConfig.edgeDomain)
                if responses = invalid or Type(responses) <> "roArray" then
                    _adb_logError("processQueuedRequests() - not found valid edge response.")
                else
                    for each response in responses
                        responseEvents.Push({
                            uuid: response.requestId,
                            data: {
                                code: response.code,
                                message: response.message
                            }
                        })
                    end for
                end if
            end if
            return responseEvents
        end function,
    })
    return module
end function