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

function _adb_EdgeRequestWorker() as object
    instance = {
        _queue: [],
        _queue_size_max: 50,

        queue: function(requestId as string, xdmData as object, timestampInMillis as longinteger) as void
            if _adb_isEmptyOrInvalidString(requestId)
                _adb_logDebug("[EdgeRequestWorker.queue()] requestId is invalid")
                return
            end if

            if _adb_isEmptyOrInvalidMap(xdmData)
                _adb_logDebug("[EdgeRequestWorker.queue()] xdmData is invalid")
                return
            end if

            if timestampInMillis <= 0
                _adb_logDebug("[EdgeRequestWorker.queue()] timestampInMillis is invalid")
                return
            end if

            requestEntity = {
                requestId: requestId,
                xdmData: xdmData,
                timestampInMillis: timestampInMillis
            }
            ' remove the oldest entity if reaching the limit
            if m._queue.count() >= m._queue_size_max
                m._queue.Shift()
            end if
            m._queue.Push(requestEntity)
        end function,

        hasQueuedEvent: function() as boolean
            size = m._queue.count()
            if size = 0
                return false
            end if
            _adb_logVerbose("hasQueuedEvent() - Request queue size:(" + FormatJson(size) + ")")
            return true
        end function,

        processRequests: function(configId as string, ecid as string, edgeDomain = invalid as dynamic) as dynamic
            responseArray = []
            while m._queue.count() > 0

                if _adb_isEmptyOrInvalidString(ecid) or _adb_isEmptyOrInvalidString(configId) then
                    _adb_logWarning("processRequests() - Edge request skipped. ECID and/or configId not set.")
                    exit while
                end if

                ' grab oldest hit in the queue
                requestEntity = m._queue.Shift()

                xdmData = requestEntity.xdmData
                requestId = requestEntity.requestId

                networkResponse = m._processRequest(xdmData, ecid, configId, requestId, edgeDomain)
                if not _adb_isNetworkResponse(networkResponse)
                    _adb_logError("processRequests() - Edge request dropped. Response is invalid.")
                    ' drop the request
                    continue while
                end if

                _adb_logVerbose("processRequests() - Request with id:(" + FormatJson(requestId) + ") response:(" + FormatJson(networkResponse) + ")")
                if networkResponse.isSuccessful()
                    ' TODO: add request id
                    edgeResponse = _adb_EdgeResponse(requestId, networkResponse.getResponseCode(), networkResponse.getResponseString())
                    responseArray.Push(edgeResponse)
                else if networkResponse.isRecoverable()
                    m._queue.Unshift(requestEntity)
                    exit while
                else
                    ' drop the request
                    _adb_logError("processRequests() - Edge request dropped due to unrecoverable error. Response:(" + FormatJson(networkResponse) + ")")
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
            networkResponse = _adb_serviceProvider().networkService.syncPostRequest(url, jsonBody)
            return networkResponse
        end function

        clear: function() as void
            m._queue.Clear()
        end function
    }

    return instance
end function


function _adb_EdgeResponse(requestId as string, code as integer, responseBody as string) as object
    networkResponse = _adb_AdobeObject("com.adobe.module.edge.response")
    networkResponse.Append({
        _requestId: requestId,
        _responseBody: responseBody,
        _responseCode: code,

        getRequestId: function() as string
            return m._requestId
        end function,

        getResponseCode: function() as integer
            return m._responseCode
        end function,

        getResponseString: function() as string
            return m._responseBody
        end function,

        toString: function() as string
            return "_requestId = " + m._requestId + " , _responseBody = " + m._responseBody + " , _responseCode = " + FormatJson(m._responseCode)
        end function,
    })
    return networkResponse
end function

function _adb_isEdgeResponse(edgeResponse as object) as boolean
    if edgeResponse <> invalid and edgeResponse.type = "com.adobe.module.edge.response" then
        return true
    end if
    return false
end function
