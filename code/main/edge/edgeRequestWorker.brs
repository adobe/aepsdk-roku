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

function _adb_EdgeRequestWorker(edgeResponseManager as object, consentState as object) as object
    instance = {
        _RETRY_WAIT_TIME_MS: 30000, ' 30 seconds
        _COLLECT_CONSENT_NO: "n",
        _COLLECT_CONSENT_YES: "y",
        _INVALID_WAIT_TIME: -1,
        _lastFailedRequestTS: -1,
        _queue: [],
        _queue_size_max: 50,
        _edgeResponseManager: edgeResponseManager,
        _consentState: consentState,

        ' ------------------------------------------------------------------------------------------------
        ' Queue the Edge request.
        '
        ' @param requestId          - the request id
        ' @param eventData          - the data object containing xdm, non-xdm and config data
        ' @param timestampInMillis  - the timestamp in millis used to compute when to retry failed requets
        ' @param meta               - the meta data
        ' @param path               - if it's not empty, overwrite the Edge path with the given value
        '
        ' @return void
        ' ------------------------------------------------------------------------------------------------
        queue: function(edgeRequest as object) as void
            if not _adb_isValidEdgeRequest(edgeRequest)
                _adb_logError("EdgeRequestWorker::queue() - Invalid Edge request:(" + FormatJson(edgeRequest) + ").")
                return
            end if

            if not m._shouldQueueRequest(edgeRequest, m._consentState)
                _adb_logDebug("EdgeRequestWorker::queue() - Not queuing request with id:(" + FormatJson(edgeRequest.getRequestId()) + ") as collect consent is set to: (" + FormatJson(m._consentState.getCollectConsent()) + ").")
                return
            end if

            ' remove the oldest request if exceeds the queue limit
            if m._queue.count() >= m._queue_size_max
                _adb_logDebug("EdgeRequestWorker::queue() - Number of queued hits exceeds the maximum queue size (" + StrI(m._queue_size_max) + "). Removing the oldest hit.")
                m._queue.Shift()
            end if

            ' queue the request
            m._queue.Push(edgeRequest)

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
        processRequests: function(edgeConfig as object) as dynamic
            responseArray = []
            while m.hasQueuedEvent()

                if m._shouldWaitBeforeRetry()
                    ' Wait for 30 seconds before retrying the request
                    exit while
                end if

                ' grab oldest hit in the queue
                edgeRequest = m._queue.Shift()
                requestId = edgeRequest.getRequestId()

                if not m._shouldSendRequest(edgeRequest, m._consentState)
                    collectConsent = m._consentState.getCollectConsent()
                    if _adb_stringEqualsIgnoreCase(collectConsent, m._COLLECT_CONSENT_NO)
                        ' this should not be called as the request will be dropped in queue() method if consent is (n)
                        _adb_logDebug("EdgeRequestWorker::processRequests() - Not sending (" + FormatJson(edgeRequest) + ") request with id:(" + FormatJson(requestId) + ") will be dropped as collect consent is set to (" + FormatJson(collectConsent) + ").")
                        ' drop the request
                        continue while
                    else
                        m._queue.Unshift(edgeRequest) ' put the request back to the queue
                        _adb_logDebug("EdgeRequestWorker::processRequests() - Not sending (" + FormatJson(edgeRequest) + ") request with id:(" + FormatJson(requestId) + ") as collect consent is set to: (" + FormatJson(collectConsent) + ").")
                        ' exit the processing loop since the consent is not set to y
                        exit while
                    end if

                end if

                networkResponse = m._processRequest(edgeConfig, edgeRequest)
                edgeResponse = m._processResponse(networkResponse, edgeRequest)

                if _adb_isEdgeResponse(edgeResponse)
                    responseArray.Push(edgeResponse)
                end if

            end while

            return responseArray
        end function,

        _processResponse: function(networkResponse as object, originRequest as object) as object
            edgeResponse = invalid

            requestId = originRequest.getRequestId()

            if not _adb_isNetworkResponse(networkResponse)
                _adb_logError("EdgeRequestWorker::_processResponse() - Edge request with id:(" + FormatJson(requestId) + ") returned invalid response:(" + FormatJson(networkResponse) + ").")
                return invalid
            end if

            responseString = networkResponse.toString()
            responseCode = networkResponse.getResponseCode()
            responseBody = networkResponse.getResponseString()

            _adb_logVerbose("EdgeRequestWorker::_processResponse() - Edge request with id:(" + FormatJson(requestId) + ") response:(" + chr(10) + responseString + chr(10) + ").")

            if networkResponse.isSuccessful()
                ' Request sent out successfully
                m._lastFailedRequestTS = m._INVALID_WAIT_TIME
                edgeResponse = _adb_EdgeResponse(requestId, responseCode, responseBody)

                m._processResponseOnSuccess(edgeResponse)

                _adb_logVerbose("EdgeRequestWorker::_processResponse() - Successfully sent Edge request with id (" + FormatJson(requestId) + ") response code:(" + FormatJson(responseCode) + ").")
            else if networkResponse.isRecoverable()
                m._lastFailedRequestTS = _adb_timestampInMillis()

                ' Add the request back to the queue for retry
                m._queue.Unshift(originRequest)

                _adb_logWarning("EdgeRequestWorker::_processResponse() - Failed to send Edge request with id (" + FormatJson(requestId) + ") recoverable error code:(" + FormatJson(responseCode) + ") response:(" + responseBody + "). Request will be retried after (" + FormatJson(m._RETRY_WAIT_TIME_MS) + ") ms.")
            else
                m._lastFailedRequestTS = m._INVALID_WAIT_TIME
                edgeResponse = _adb_EdgeResponse(requestId, responseCode, responseBody)

                _adb_logError("EdgeRequestWorker::_processResponse() - Failed to send Edge request with id (" + FormatJson(requestId) + ") unrecoverable error code:(" + FormatJson(responseCode) + ") response:(" + responseString + ").")
            end if
            return edgeResponse
        end function,

        _shouldWaitBeforeRetry: function() as object
            if m._lastFailedRequestTS = m._INVALID_WAIT_TIME
                return false
            end if

            currTS = _adb_timestampInMillis()
            if (currTS - m._lastFailedRequestTS) >= m._RETRY_WAIT_TIME_MS
                return false
            end if

            return true
        end function,

        _processRequest: function(edgeConfig as object, edgeRequest as object) as object
            requestId = edgeRequest.getRequestId()
            eventData = edgeRequest.getEventData()
            requestType = edgeRequest.getRequestType()
            path = edgeRequest.getPath()
            meta = edgeRequest.getMeta()

            ecid = edgeConfig.ecid
            datastreamId = edgeConfig.configId
            edgeDomain = edgeConfig.edgeDomain

            stateStorePayload = m._edgeResponseManager.getStateStore()

            ' Append config overrides to meta if set in eventData.config
            meta = m._appendConfigOverridesToMeta(meta, eventData.config, datastreamId)

            ' Append statestore payload to meta
            meta = m._appendStateToMeta(meta, stateStorePayload)

            ' Get datastreamId to be used in the request. If datastreamIdOverride is set in eventData.config, use it. Otherwise, use the original datastreamId.
            datastreamId = m._getDatastreamId(eventData.config, datastreamId)

            ' Remove config from eventData
            eventData.Delete("config")

            if _adb_isEdgeConsentRequest(edgeRequest)
                requestBody = m._createConsentRequestBody(eventData, ecid, meta)
            else
                requestBody = m._createEdgeRequestBody(eventData, ecid, meta)
            end if

            locationHint = m._edgeResponseManager.getLocationHint()
            url = _adb_buildEdgeRequestURL(datastreamId, requestId, path, locationHint, edgeDomain)
            _adb_logVerbose("EdgeRequestWorker::_processRequest() - Processing " + FormatJson(requestType) + " Request with url:(" + chr(10) + FormatJson(url) + chr(10) + ") with payload:(" + chr(10) + FormatJson(requestBody) + chr(10) + ")")
            networkResponse = _adb_serviceProvider().networkService.syncPostRequest(url, requestBody)
            return networkResponse
        end function

        _getDatastreamId: function(config as object, originalDatastreamId as String) as string
            if _adb_isEmptyOrInvalidMap(config)
                return originalDatastreamId
            end if

            if not _adb_isEmptyOrInvalidString(config.datastreamIdOverride)
                return config.datastreamIdOverride
            end if

            return originalDatastreamId
        end function,

        _appendConfigOverridesToMeta: function(meta as object, config as object, originalDatastreamId) as object
            if _adb_isEmptyOrInvalidMap(meta)
                meta = {}
            end if

            if _adb_isEmptyOrInvalidMap(config)
                return meta
            end if

            if not _adb_isEmptyOrInvalidMap(config.datastreamConfigOverride)
                meta["configOverrides"] = config.datastreamConfigOverride
            end if

            if not _adb_isEmptyOrInvalidString(config.datastreamIdOverride)
                ''' Genrate sdkConfig payload with original datastreamId
                meta["sdkConfig"] = m._getSdkConfigPayload(originalDatastreamId)
            end if

            return meta
        end function,

        _appendStateToMeta: function(meta as object, state as object) as object
            if _adb_isEmptyOrInvalidMap(meta)
                meta = {}
            end if

            stateMetadata = {}
            if not _adb_isEmptyOrInvalidArray(state)
                stateMetadata["entries"] = state
            end if

            if not _adb_isEmptyOrInvalidMap(stateMetadata)
                meta["state"] = stateMetadata
            end if

            return meta
        end function,

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

            _adb_logVerbose("EdgeRequestWorker::_createEdgeRequestBody() - Created Edge request body: (" + FormatJson(requestBody) + ").")
            return requestBody
        end function,

        _createConsentRequestBody: function(consentData as object, ecid as string, meta as object) as object
            requestBody = {
                "query" : {
                    "consent" : {
                    "operation" : "update"
                    }
                },
                "xdm": {
                    "identityMap": m._getIdentityMap(ecid),
                    "implementationDetails": _adb_ImplementationDetails()
                },
                "consent": []
            }

            ''' consentData is an array of consents
            requestBody.consent = consentData.consent

            if not _adb_isEmptyOrInvalidMap(meta)
                requestBody.meta = meta
            end if

            _adb_logVerbose("EdgeRequestWorker::_createConsentRequestBody() - Created Consent request body: (" + FormatJson(requestBody) + ").")
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

        _processResponseOnSuccess: function(edgeResponse as object) as void
            m._edgeResponseManager.processResponse(edgeResponse)
        end function,

        _shouldQueueRequest: function(edgeRequest as object, consentState as object) as boolean
            collectConsent = consentState.getCollectConsent()

            if _adb_stringEqualsIgnoreCase(collectConsent, m._COLLECT_CONSENT_NO) and not _adb_isEdgeConsentRequest(edgeRequest)
                _adb_logVerbose("EdgeRequestWorker::_shouldQueue() - Collect consent value is set to (" + FormatJson(collectConsent) + "). The Edge request will be dropped.")
                return false
            end if

            _adb_logVerbose("EdgeRequestWorker::_shouldQueue() - Collect consent value is set to (" + FormatJson(collectConsent) + "). The Edge request will be queued and processed.")
            return true
        end function,

        _shouldSendRequest: function(edgeRequest as object, consentState as object) as boolean
            collectConsent = consentState.getCollectConsent()

            if _adb_isEmptyOrInvalidString(collectConsent)
                _adb_logVerbose("EdgeRequestWorker::_shouldSend() - Collect consent value is not set and is defaulted to collect consent (y). The request will be sent.")
                return true
            end if

            if _adb_isEdgeConsentRequest(edgeRequest)
                _adb_logVerbose("EdgeRequestWorker::_shouldSend() - Request type is Consent and will be sent.")
                return true
            end if

            if not _adb_stringEqualsIgnoreCase(collectConsent, m._COLLECT_CONSENT_YES)
                _adb_logVerbose("EdgeRequestWorker::_shouldSend() - Collect consent value is set to (" + FormatJson(collectConsent) + "). The Edge request will not be sent and will be queued till collect consent value is updated.")
                return false
            end if

            _adb_logVerbose("EdgeRequestWorker::_shouldSend() - Collect consent value is set to (" + FormatJson(collectConsent) + "). The Edge request will be sent.")
            return true
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
