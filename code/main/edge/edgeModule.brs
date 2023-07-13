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

' ************************************ MODULE: edge ***************************************

function _adb_EdgeModule(stateManager as object) as object
    return {
        _edgeRequestWorker: _adb_EdgeRequestWorker(stateManager),

        sendEvent: function(requestId as string, xdmData as object, timestampInMillis as integer) as dynamic
            m._edgeRequestWorker.queue(requestId, xdmData, timestampInMillis)
            return m.processQueuedRequests()
        end function,

        processQueuedRequests: function() as dynamic
            responseEvents = []
            if m._edgeRequestWorker.isReadyToProcess() then
                responses = m._edgeRequestWorker.processRequests()
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
    }
end function