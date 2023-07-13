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

' ******************************* MODULE: EdgeRequestWorker *******************************

function _adb_EdgeRequestWorker(stateManager as object) as object
    if stateManager = invalid
        _adb_logDebug("stateManager is invalid")
        return invalid
    end if
    instance = {
        _queue: [],
        _stateManager: stateManager
        _queue_size_max: 50,

        queue: function(requestId as string, xdmData as object, timestamp as integer) as void
            if _adb_isEmptyOrInvalidString(requestId)
                _adb_logDebug("[EdgeRequestWorker.queue()] requestId is invalid")
                return
            end if

            if _adb_isEmptyOrInvalidMap(xdmData)
                _adb_logDebug("[EdgeRequestWorker.queue()] xdmData is invalid")
                return
            end if

            if timestamp <= 0
                _adb_logDebug("[EdgeRequestWorker.queue()] timestamp is invalid")
                return
            end if

            requestEntity = {
                requestId: requestId,
                xdmData: xdmData,
                timestamp: timestamp
            }
            ' remove the oldest entity if reaching the limit
            if m._queue.count() >= m._queue_size_max
                m._queue.Shift()
            end if
            m._queue.Push(requestEntity)
        end function,

        isReadyToProcess: function() as boolean
            size = m._queue.count()

            if size = 0
                return false
            end if
            _adb_logVerbose("isReadyToProcess() - Request queue size:(" + FormatJson(size) + ")")

            if not m._stateManager.isReadyForRequest()
                return false
            end if

            _adb_logVerbose("isReadyToProcess() - Ready to process queued requests.")
            return true
        end function,

        processRequests: function() as dynamic
            responseArray = invalid
            while m._queue.count() > 0
                ' grab oldest hit in the queue
                requestEntity = m._queue.Shift()

                xdmData = requestEntity.xdmData
                requestId = requestEntity.requestId

                ecid = m._stateManager.getECID()
                configId = m._stateManager.getConfigId()
                edgeDomain = m._stateManager.getEdgeDomain()

                _adb_logVerbose("processRequests() - Using ECID:(" + FormatJson(ecid) + ") and configId:(" + FormatJson(configId) + ")")
                if (not _adb_isEmptyOrInvalidString(ecid)) and (not _adb_isEmptyOrInvalidString(configId)) then
                    response = m._processRequest(xdmData, ecid, configId, requestId, edgeDomain)
                    if response = invalid
                        _adb_logError("processRequests() - Edge request dropped. Response is invalid.")
                        ' drop the request
                    else
                        _adb_logVerbose("processRequests() - Request with id:(" + FormatJson(requestId) + ") code:(" + FormatJson(response.code) + ") message:(" + response.message + ")")
                        if response.code >= 200 and response.code <= 299 then
                            if responseArray = invalid
                                responseArray = []
                            end if
                            responseArray.Push(response)

                        else if response.code = 408 or response.code = 504 or response.code = 503
                            ' RECOVERABLE_ERROR_CODES = [408, 504, 503]
                            m._queue.Unshift(requestEntity)
                            exit while
                        else
                            ' drop the request
                            _adb_logError("processRequests() - Edge request dropped. Response code:(" + response.code.toStr() + ") Response body:(" + response.message + ")")
                            exit while
                        end if
                    end if

                else
                    _adb_logWarning("processRequests() - Edge request skipped. ECID and/or configId not set.")
                    m._queue.Unshift(requestEntity)
                    exit while
                end if
            end while
            return responseArray
        end function,

        _processRequest: function(xdmData as object, ecid as string, configId as string, requestId as string, edgeDomain = invalid as dynamic) as object
            identityMap = {
                "ECID": [
                    {
                        "id": ecid,
                        "primary": true,
                        "authenticatedState": "ambiguous"
                    }
                ]
            }

            jsonBody = {
                "xdm": {
                    "identityMap": identityMap,
                    "implementationDetails": _adb_ImplementationDetails()
                },
                "events": []
            }

            ' Add customer provided xdmData
            jsonBody.events[0] = xdmData

            url = _adb_buildEdgeRequestURL(configId, requestId, edgeDomain)
            _adb_logVerbose("_processRequest() - Sending Request to url:(" + FormatJson(url) + ") with payload:(" + FormatJson(jsonBody) + ")")
            response = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            if response <> invalid
                response.requestId = requestId
            end if
            return response
        end function

        clear: function() as void
            m._queue.Clear()
        end function
    }

    return instance
end function