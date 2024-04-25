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
        _RETRY_WAIT_TIME_MS: 30000, ' 30 seconds
        _INVALID_WAIT_TIME: -1,
        _lastFailedRequestTS: -1,
        _queue: [],
        _queue_size_max: 50,

        ' ------------------------------------------------------------------------------------------------
        ' Queue the Edge request.
        '
        ' @param requestId          - the request id
        ' @param xdmEvents          - an array of the XDM events
        ' @param timestampInMillis  - the timestamp in millis used to compute when to retry failed requets
        ' @param meta               - the meta data
        ' @param path               - if it's not empty, overwrite the Edge path with the given value
        '
        ' @return void
        ' ------------------------------------------------------------------------------------------------
        queue: function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string) as void
            if meta = invalid
                meta = {}
            end if

            if _adb_isEmptyOrInvalidString(requestId)
                _adb_logDebug("EdgeRequestWorker::queue() - Cannot queue request, requestId is invalid")
                return
            end if

            if _adb_isEmptyOrInvalidMap(eventData)
                _adb_logDebug("EdgeRequestWorker::queue() - Cannot queue request, eventData object is invalid")
                return
            end if

            if timestampInMillis <= 0
                _adb_logDebug("EdgeRequestWorker::queue() - Cannot queue request, timestampInMillis is invalid")
                return
            end if

            requestEntity = {
                requestId: requestId,
                eventData: eventData,
                timestampInMillis: timestampInMillis,
                path: path,
                meta: meta
            }
            ' remove the oldest entity if reaching the limit
            if m._queue.count() >= m._queue_size_max
                _adb_logDebug("EdgeRequestWorker::queue() - No of queued hits exceeds the maximum queue size (" + StrI(m._queue_size_max) + "). Removing the oldest hit.")
                m._queue.Shift()
            end if
            m._queue.Push(requestEntity)

            ''' force retry the hits by disabling wait
            m._lastFailedRequestTS = m._INVALID_WAIT_TIME
        end function,

        ' Check if there is any queued Edge request.
        hasQueuedEvent: function() as boolean
            return m._queue.count() > 0
        end function,

        ' ------------------------------------------------------------------------------------------
        '
        ' Process the queued Edge requests with the given configuration.
        ' When recoverable error happens, the request will be retried after 30 seconds.
        '
        ' @param configId               - a string of the config id
        ' @param ecid                   - a string of ECID
        ' @param edgeDomain (optional)  - a stirng of the customer Edge domain, the default value is invalid if not provided
        '
        ' @return an array of EdgeResponse objects
        ' ------------------------------------------------------------------------------------------
        processRequests: function(configId as string, ecid as string, edgeDomain = invalid as dynamic) as dynamic
            responseArray = []
            while m.hasQueuedEvent()

                currTS = _adb_timestampInMillis()
                if (m._lastFailedRequestTS <> m._INVALID_WAIT_TIME) and ((currTS - m._lastFailedRequestTS) < m._RETRY_WAIT_TIME_MS)
                    ' Wait for 30 seconds before retrying the hit failed with recoverable error.
                    exit while
                end if

                ' grab oldest hit in the queue
                requestEntity = m._queue.Shift()

                eventData = requestEntity.eventData
                requestId = requestEntity.requestId
                meta = requestEntity.meta
                path = requestEntity.path

                networkResponse = m._processRequest(eventData, ecid, configId, requestId, path, meta, edgeDomain)
                if not _adb_isNetworkResponse(networkResponse)
                    _adb_logError("EdgeRequestWorker::processRequests() - Edge request dropped. Response is invalid.")
                    ' drop the request
                    continue while
                end if

                _adb_logVerbose("EdgeRequestWorker::processRequests() - Request with id:(" + FormatJson(requestId) + ") response: " + networkResponse.toString())

                if networkResponse.isSuccessful()
                    edgeResponse = _adb_EdgeResponse(requestId, networkResponse.getResponseCode(), networkResponse.getResponseString())
                    responseArray.Push(edgeResponse)
                    ' Request sent out successfully
                    m._lastFailedRequestTS = m._INVALID_WAIT_TIME
                    _adb_logVerbose("EdgeRequestWorker::processRequests() - Edge request with id (" + FormatJson(requestId) + ") was sent successfully code (" + FormatJson(networkResponse.getResponseCode()) + ").")
                else if networkResponse.isRecoverable()
                    m._lastFailedRequestTS = _adb_timestampInMillis()
                    _adb_logWarning("EdgeRequestWorker::processRequests() - Edge request with id (" + FormatJson(requestId) + ") failed with recoverable error code (" + FormatJson(networkResponse.getResponseCode()) + "). Request will be retried after (" + FormatJson(m._RETRY_WAIT_TIME_MS) + ") ms.")
                    m._queue.Unshift(requestEntity)
                    exit while
                else
                    edgeResponse = _adb_EdgeResponse(requestId, networkResponse.getResponseCode(), networkResponse.getResponseString())
                    responseArray.Push(edgeResponse)
                    _adb_logError("EdgeRequestWorker::processRequests() - Failed to send Edge request with id (" + FormatJson(requestId) + ") code (" + FormatJson(networkResponse.getResponseCode()) + ") response:(" + networkResponse.toString() + ")")
                end if
            end while
            return responseArray
        end function,

        _processRequest: function(eventData as object, ecid as string, datastreamId as string, requestId as string, path as string, meta as object, edgeDomain as dynamic) as object
            if not _adb_isEmptyOrInvalidMap(eventData.config)
                config = eventData.config
                sdkConfig = invalid
                configOverrides = invalid

                if _adb_isEmptyOrInvalidMap(meta)
                    meta = {}
                end if

                if not _adb_isEmptyOrInvalidString(config.datastreamIdOverride)
                    ''' Genrate sdkConfig payload with original datastreamId
                    sdkConfig = m._getSdkConfigPayload(datastreamId)
                    meta["sdkConfig"] = sdkConfig

                    ''' Override the datastreamId
                    datastreamId = config.datastreamIdOverride
                end if

                if not _adb_isEmptyOrInvalidMap(config.datastreamConfigOverride)
                    meta["configOverrides"] = config.datastreamConfigOverride
                end if

                ''' Remove config from eventData
                eventData.Delete("config")
            end if

            requestBody = m._createEdgeRequestBody(eventData, ecid, meta)

            url = _adb_buildEdgeRequestURL(datastreamId, requestId, path, edgeDomain)
            _adb_logVerbose("EdgeRequestWorker::_processRequest() - Processing Request with url:(" + chr(10) + FormatJson(url) + chr(10) + ") with payload:(" + chr(10) + FormatJson(requestBody) + chr(10) + ")")
            networkResponse = _adb_serviceProvider().networkService.syncPostRequest(url, requestBody)
            return networkResponse
        end function

        _createEdgeRequestBody: function(eventData as object, ecid as string, meta as object) as object
            requestBody = {
                "xdm": {
                    "identityMap": m._getIdentityMap(ecid),
                    "implementationDetails": _adb_ImplementationDetails()
                },
                "events": []
            }

            ''' Add eventData under events key as an array
            requestBody.events = [eventData]

            if not _adb_isEmptyOrInvalidMap(meta)
                requestBody.meta = meta
            end if

            return requestBody
        end function,

        _getSdkConfigPayload: function(originalDatastreamId as string) as object
            sdkConfig = {}
            sdkConfig.datastream = {}
            sdkConfig.datastream.original = originalDatastreamId
        return sdkConfig
        end function,

        _getIdentityMap: function(ecid as string) as object
            identityMap = {
                "ECID": [
                    {
                        "id": ecid,
                        "primary": false,
                        "authenticatedState": "ambiguous"
                    }
                ]
            }
            return identityMap
        end function,

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
    return (edgeResponse <> invalid and edgeResponse.type = "com.adobe.module.edge.response")
end function
