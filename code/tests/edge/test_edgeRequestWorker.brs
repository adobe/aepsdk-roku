' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' ****************************** init tests ******************************

' target: _adb_EdgeRequestWorker()
' @Test
sub TC_adb_EdgeRequestWorker_init()
    worker = _adb_testUtil_getEdgeRequestWorker()
    UTF_AssertNotInvalid(worker)
end sub

' ****************************** hasQueuedEvent tests ******************************

' target: hasQueuedEvent()
' @Test
sub TC_adb_EdgeRequestWorker_hasQueuedEvent()
    worker = _adb_testUtil_getEdgeRequestWorker()
    worker._queue = []
    UTF_assertFalse(worker.hasQueuedEvent())
    worker._queue.Push({})
    UTF_assertTrue(worker.hasQueuedEvent())
    worker._queue.Shift()
    UTF_assertFalse(worker.hasQueuedEvent())
end sub

' ****************************** queue tests ******************************

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue()
    worker = _adb_testUtil_getEdgeRequestWorker()
    worker._queue = []
    timestampInMillis& = _adb_timestampInMillis()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: {} }, timestampInMillis&)

    worker.queue(edgeRequest)
    UTF_assertEqual(1, worker._queue.Count())
end sub

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue_notEdgeRequest_doesNotQueue()
    worker = _adb_testUtil_getEdgeRequestWorker()

    worker._queue = []


    worker.queue({})
    worker.queue({ "key": "value" })
    worker.queue(invalid)

    UTF_assertEqual(0, worker._queue.Count())
end sub

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue_limit()
    worker = _adb_testUtil_getEdgeRequestWorker()
    worker._queue = []
    worker._queue_size_max = 2

    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))

    UTF_assertEqual(2, worker._queue.Count())
end sub

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue_newRequest_after_RecoverableError_retriesImmediately()
    cachedFunction = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        if url.Instr("request_id_1") > 0 then
            return _adb_NetworkResponse(200, "response body 1")
        end if
        if url.Instr("request_id_2") > 0 then
            return _adb_NetworkResponse(408, "response body 2")
        end if
        if url.Instr("request_id_3") > 0 then
            return _adb_NetworkResponse(200, "response body 3")
        end if
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()

    worker.queue(_adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id_3", { xdm: { key: "value" } }, 12345534&))
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(1, responseArray.Count())
    ' queued reqeust should be processed in order
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())

    UTF_assertEqual(2, worker._queue.Count())
    UTF_assertNotInvalid(worker._queue[0], "Request should not be invalid")
    UTF_assertEqual("request_id_2", worker._queue[0].getRequestId())
    UTF_assertNotEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be set")

    ' Set the network to pass for the retry
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        return _adb_NetworkResponse(200, "response body")
    end function

    ' Request should be not be sent since < 30 seconds
    worker.queue(_adb_EdgeRequest("request_id_4", { xdm: { key: "value" } }, 12345534&))
    UTF_assertEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be reset to -1")

    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())
    UTF_assertEqual(3, responseArray.Count())
    UTF_assertEqual(0, worker._queue.Count())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFunction
end sub

' ****************************** clear tests ******************************

' target: clear()
' @Test
sub TC_adb_EdgeRequestWorker_clear()
    worker = _adb_testUtil_getEdgeRequestWorker()
    worker._queue = []
    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id", { xdm: {} }, 12345534&))
    UTF_assertEqual(3, worker._queue.Count())
    worker.clear()
    UTF_assertEqual(0, worker._queue.Count())
end sub

' ****************************** processRequest tests ******************************

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")
        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function



    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" } }, 12345534&)
    worker = _adb_testUtil_getEdgeRequestWorker()
    worker.queue(edgeRequest)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_customMeta_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")
        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")

        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
               "konductorTestConfig": "testValue"
            }

        UTF_assertEqual(expectedMetaObj, jsonObj.meta, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function


    worker = _adb_testUtil_getEdgeRequestWorker()

    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" } }, 12345534&)
    edgeRequest.setMeta({ "konductorTestConfig" : "testValue" })
    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_customDomain_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://testDomain/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")
        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()

    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" } }, 12345534&)
    edgeConfig = _adb_testUtil_getEdgeConfig()
    edgeConfig.edgeDomain = "testDomain"

    networkResponse = worker._processRequest(edgeConfig, edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_datastreamConfigOverride_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert configOverrides in under meta
        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
            configOverrides: {
                "test": {
                    "key": "value"
                }
            }
        }
        UTF_assertEqual(expectedMetaObj, jsonObj.meta, "Expected != actual (Meta object in the request)")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { "datastreamConfigOverride": {"test" : {"key": "value"}} } }, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_datastreamIdAndConfigOverride_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=datastreamIdOverride&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert configOverrides in under meta
        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
            "sdkConfig": {
                "datastream": {
                    "original": "test_config_id"
                }
            },
            "configOverrides": {
                "test": {
                    "key": "value"
                }
            }
        }
        UTF_assertEqual(expectedMetaObj, jsonObj.meta, "Expected != actual (Meta object in the request)")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { "datastreamIdOverride": "datastreamIdOverride", "datastreamConfigOverride": {"test" : {"key": "value"}} } }, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_overridesWithCustomMeta_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=datastreamIdOverride&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert configOverrides in under meta
        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
            "konductorTestConfig": {
                "key": "value"
            },
            "sdkConfig": {
                "datastream": {
                    "original": "test_config_id"
                }
            },
            "configOverrides": {
                "test": {
                    "key": "value"
                }
            }
        }
        UTF_assertEqual(expectedMetaObj, jsonObj.meta, "Expected != actual (Meta object in the request)")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { "datastreamIdOverride": "datastreamIdOverride", "datastreamConfigOverride": {"test" : {"key": "value"}} } }, 12345534&)
    edgeRequest.setMeta({ "konductorTestConfig" : {"key": "value"} })

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub


' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_datastreamIdOverride_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=datastreamIdOverride&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert sdkConfig in under meta
        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
            sdkConfig: {
                datastream: {
                    "original": "test_config_id"
                }
            }
        }

        UTF_assertEqual(expectedMetaObj, jsonObj.meta, "Expected != actual (Meta object in the request)")


        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { "datastreamIdOverride": "datastreamIdOverride"} }, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_invalidEventConfig_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert meta is not present
        UTF_assertInvalid(jsonObj.meta, "Meta object should be invalid")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { key1: "value1"} }, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_invalidDatastreamIdOverrideValue_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert meta is not present
        UTF_assertInvalid(jsonObj.meta, "Meta object should be invalid")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { "datastreamIdOverride": {"key1": "value1"} } }, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_invalidConfigOverrideValue_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert meta is not present
        UTF_assertInvalid(jsonObj.meta, "Meta object should be invalid")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }, config: { "datastreamConfigOverride": "invalidConfigOverrides" } }, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_validLocationHint_appendsLocationHintToRequestURL()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/locationHint/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ' Assert meta is not present
        UTF_assertInvalid(jsonObj.meta, "Meta object should be invalid")

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    edgeResponseManager = _adb_edgeResponseManager()
    ' mock location hint
    edgeResponseManager._locationHintManager.setLocationHint("locationHint")
    worker = _adb_testUtil_getEdgeRequestWorker(edgeResponseManager)
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }}, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)

    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_validStateStore_appendsStateStoreToMeta()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), generateErrorMessage("Request JSON body size", 3, jsonObj.Count()))
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "test_ecid",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: getTestSDKVersion()
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert meta is not present
        UTF_assertNotInvalid(jsonObj.meta, "Meta object should not be invalid")

        expectedMetaObj = {
               "state": {
                    "entries" : [
                        {
                            "key" : "StateName",
                            "value" : "StateValue",
                            "maxAge" : 1000
                        }
                    ]
               }
            }

        UTF_assertEqual(expectedMetaObj, jsonObj.meta, generateErrorMessage("Meta object in the request", expectedMetaObj, jsonObj.meta))

        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "Expected != actual (Events payload in the request)")
        return _adb_NetworkResponse(200, "response body")
    end function

    edgeResponseManager = _adb_edgeResponseManager()
    edgeResponseManager._stateStoreManager._addToStateStore({"key": "StateName", "maxAge" : 1000, "value": "StateValue"})

    worker = _adb_testUtil_getEdgeRequestWorker(edgeResponseManager)
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }}, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)
    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_invalid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=test_config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count())
        UTF_assertNotInvalid(jsonObj.xdm)
        UTF_assertNotInvalid(jsonObj.events)
        return invalid
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" }}, 12345534&)

    networkResponse = worker._processRequest(_adb_testUtil_getEdgeConfig(), edgeRequest)
    UTF_assertInvalid(networkResponse)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' ****************************** processRequests tests ******************************

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        if url.Instr("request_id_1") > 0 then
            return _adb_NetworkResponse(200, "response body 1")
        end if
        if url.Instr("request_id_2") > 0 then
            return _adb_NetworkResponse(200, "response body 2")
        end if
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&)
    worker.queue(edgeRequest1)
    worker.queue(edgeRequest2)

    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(2, responseArray.Count())
    ' queued request should be processed in order

    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[1]))
    UTF_assertEqual("request_id_2", responseArray[1].getRequestId())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_empty_queue()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(_url as string, _jsonObj as object, _headers = [] as object) as object
        UTF_fail("should not be called")
        return invalid
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()
    result = worker.processRequests(_adb_testUtil_getEdgeConfig())
    UTF_assertEqual(0, result.count())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_recoverableError_retriesAfterWaitTimeout()
    cachedFunction = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        if url.Instr("request_id_1") > 0 then
            return _adb_NetworkResponse(200, "response body 1")
        end if
        if url.Instr("request_id_2") > 0 then
            return _adb_NetworkResponse(408, "response body 2")
        end if
        if url.Instr("request_id_3") > 0 then
            return _adb_NetworkResponse(200, "response body 3")
        end if
    end function

    worker = _adb_testUtil_getEdgeRequestWorker()

    worker.queue(_adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&))
    worker.queue(_adb_EdgeRequest("request_id_3", { xdm: { key: "value" } }, 12345534&))
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(1, responseArray.Count())
    ' queued reqeust should be processed in order
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())

    UTF_assertEqual(2, worker._queue.Count())
    UTF_assertNotInvalid(worker._queue[0], "Request should not be invalid")
    UTF_assertEqual("request_id_2", worker._queue[0].getRequestId())
    UTF_assertNotEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be set")

    ' Set the network to pass for the retry
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        return _adb_NetworkResponse(200, "response body")
    end function

    ' Request should be not be sent since < 30 seconds
    worker._lastFailedRequestTS = worker._lastFailedRequestTS - 20000 ' Mock 20 seconds elapsed timer
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(0, responseArray.Count())
    UTF_assertEqual(2, worker._queue.Count())

    ' Request should be not be sent since < 30 seconds
    worker._lastFailedRequestTS = worker._lastFailedRequestTS - 9000 ' Mock 9 seconds elapsed timer (total 29 seconds)
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(0, responseArray.Count())
    UTF_assertEqual(2, worker._queue.Count())

    ' Request should be retried after 30 seconds
    worker._lastFailedRequestTS = worker._lastFailedRequestTS - 1000 ' Mock 1 second elapsed timer (total 30 seconds)
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(2, responseArray.Count())
    UTF_assertEqual(0, worker._queue.Count())
    UTF_assertEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be reset to -1")

    _adb_serviceProvider().networkService.syncPostRequest = cachedFunction
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_consentNo_dropsRequest()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(_url as string, _jsonObj as object, _headers = [] as object) as object
        UTF_fail("should not be called")
        return invalid
    end function

    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    consentState.setCollectConsent("n")
    worker = _adb_testUtil_getEdgeRequestWorker(_adb_EdgeResponseManager(), consentState)

    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&)

    worker._queue = [edgeRequest1, edgeRequest2]

    ' Verify when consent is no network requests are made and the queued requests are dropped
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())
    UTF_assertEqual(0, responseArray.Count(), generateErrorMessage("Response array count", 0, responseArray.Count()))
    UTF_assertEqual(0, worker._queue.Count(), generateErrorMessage("Queue count", 0, worker._queue.Count()))

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_consentYes_sendsRequests()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)

        return _adb_NetworkResponse(200, "response body")
    end function

    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    consentState.setCollectConsent("y")
    worker = _adb_testUtil_getEdgeRequestWorker(_adb_EdgeResponseManager(), consentState)

    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&)

    worker._queue = [edgeRequest1, edgeRequest2]

    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(2, responseArray.Count())
    ' queued request should be processed in order

    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[1]))
    UTF_assertEqual("request_id_2", responseArray[1].getRequestId())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_consentPending_queuesRequest()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(_url as string, _jsonObj as object, _headers = [] as object) as object
        UTF_fail("should not be called")
        return invalid
    end function

    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    consentState.setCollectConsent("p")
    worker = _adb_testUtil_getEdgeRequestWorker(_adb_EdgeResponseManager(), consentState)

    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&)

    worker._queue = [edgeRequest1, edgeRequest2]

    ' Verify when consent is pending (i.e it is not set to "y" or "n") network requests are not made and the queued requests are not dropped
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())
    UTF_assertEqual(0, responseArray.Count(), generateErrorMessage("Response array count", 0, responseArray.Count()))
    UTF_assertEqual(2, worker._queue.Count(), generateErrorMessage("Queue count", 0, worker._queue.Count()))

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_consentRequest_consentNo_sendsRequests()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)

        return _adb_NetworkResponse(200, "response body")
    end function

    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    consentState.setCollectConsent("n")
    worker = _adb_testUtil_getEdgeRequestWorker(_adb_EdgeResponseManager(), consentState)

    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest1.setRequestType("consent")
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&)
    edgeRequest2.setRequestType("consent")


    worker._consentQueue = [edgeRequest1, edgeRequest2]

    ' Verify when consent is no network requests are made and the queued requests are dropped
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())
    UTF_assertEqual(2, responseArray.Count(), generateErrorMessage("Response array count", 0, responseArray.Count()))
    UTF_assertEqual(0, worker._queue.Count(), generateErrorMessage("Queue count", 0, worker._queue.Count()))
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[1]))
    UTF_assertEqual("request_id_2", responseArray[1].getRequestId())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_consentRequest_consentYes_sendsRequests()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)

        return _adb_NetworkResponse(200, "response body")
    end function

    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    consentState.setCollectConsent("y")
    worker = _adb_testUtil_getEdgeRequestWorker(_adb_EdgeResponseManager(), consentState)

    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest1.setRequestType("consent")
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345534&)
    edgeRequest2.setRequestType("consent")

    worker._queue = [edgeRequest1, edgeRequest2]

    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())

    UTF_assertEqual(2, responseArray.Count())
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[1]))
    UTF_assertEqual("request_id_2", responseArray[1].getRequestId())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TC_adb_EdgeRequestWorker_processRequests_consentRequest_consentPending_sendsRequests()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)

        return _adb_NetworkResponse(200, "response body")
    end function

    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    consentState.setCollectConsent("p")
    worker = _adb_testUtil_getEdgeRequestWorker(_adb_EdgeResponseManager(), consentState)

    edgeRequest1 = _adb_EdgeRequest("request_id_1", { xdm: { key: "value" } }, 12345534&)
    edgeRequest1.setRequestType("consent")
    edgeRequest2 = _adb_EdgeRequest("request_id_2", { xdm: { key: "value" } }, 12345535&)
    edgeRequest2.setRequestType("consent")

    worker._consentQueue = [edgeRequest1, edgeRequest2]

    ' Verify when consent is pending (i.e it is not set to "y" or "n") network requests are not made and the queued requests are not dropped
    responseArray = worker.processRequests(_adb_testUtil_getEdgeConfig())
    UTF_assertEqual(2, responseArray.Count(), generateErrorMessage("Response array count", 0, responseArray.Count()))
    UTF_assertEqual(0, worker._queue.Count(), generateErrorMessage("Queue count", 0, worker._queue.Count()))
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[1]))
    UTF_assertEqual("request_id_2", responseArray[1].getRequestId())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub


' ****************************** _isBlockedByConsent tests ******************************
' target: _isBlockedByConsent()
' @Test
sub TC_adb_EdgeRequestWorker_isBlockedByConsent_returnsTrue()
    worker = _adb_testUtil_getEdgeRequestWorker()
    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    ' collect consent is set to "p"
    consentState.setCollectConsent("p")
    UTF_assertTrue(worker._isBlockedByConsent(consentState), generateErrorMessage("is blocked by consent (consent = p)", "true", "false"))

    ' collect consent is set to non-standard consent value"
    notStandardConsents = ["pending", "yes", "no", "true", "in"]
    for each consent in notStandardConsents
        consentState.setCollectConsent(consent)
        UTF_assertTrue(worker._isBlockedByConsent(consentState), generateErrorMessage("is blocked by consent (consent = " + FormatJson(consent) + ")", "true", "false"))
    end for
end sub

' target: _isBlockedByConsent()
' @Test
sub TC_adb_EdgeRequestWorker_isBlockedByConsent_returnsFalse()
    worker = _adb_testUtil_getEdgeRequestWorker()
    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    ' collect consent is set to "n"
    consentState.setCollectConsent("n")
    UTF_assertFalse(worker._isBlockedByConsent(consentState), generateErrorMessage("is blocked by consent (consent = n)", "false", "true"))

    ' collect consent is set to "y"
    consentState.setCollectConsent("y")
    UTF_assertFalse(worker._isBlockedByConsent(consentState), generateErrorMessage("is blocked by consent (consent = y)", "false", "true"))

    ' collect consent is set to ""
    consentState.setCollectConsent("")
    UTF_assertFalse(worker._isBlockedByConsent(consentState), generateErrorMessage("is blocked by consent (consent = emptyString)", "false", "true"))

    ' collect consent is not set
    consentState.setCollectConsent(invalid)
    UTF_assertFalse(worker._isBlockedByConsent(consentState), generateErrorMessage("is blocked by consent (consent = invalid)", "false", "true"))
end sub

' ****************************** _shouldQueueRequest tests ******************************
' target: _shouldQueueRequest()
' @Test
sub TC_adb_EdgeRequestWorker_shouldQueueRequest_returnsTrue()
    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" } }, 12345534&)
    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    ' collect consent is not set and is invalid
    UTF_assertTrue(worker._shouldQueueRequest(edgeRequest, consentState), generateErrorMessage("should queue request (conset = invalid)", "true", "false"))

    ' collect consent is set to ""
    consentState.setCollectConsent("")
    UTF_assertTrue(worker._shouldQueueRequest(edgeRequest, consentState), generateErrorMessage("should queue request (conset = emptyString)", "true", "false"))

    ' collect consent is set to "n" but the request is a consent request
    consentState.setCollectConsent("n")
    edgeRequest.setRequestType("consent")
    UTF_assertTrue(worker._shouldQueueRequest(edgeRequest, consentState), generateErrorMessage("should queue request (conset = n)", "true", "false"))

    ' reset the request type to edge
    edgeRequest.setRequestType("edge")

    ' collect consent is set to non 'n' value
    notNConsents = ["p", "pending", "yes", "y", "true", "in"]
    for each consent in notNConsents
        consentState.setCollectConsent(consent)
        UTF_assertTrue(worker._shouldQueueRequest(edgeRequest, consentState), generateErrorMessage("should queue request (conset = " + FormatJson(consent) + ")", "true", "false"))
    end for
end sub

' target: _shouldQueueRequest()
' @Test
sub TC_adb_EdgeRequestWorker_shouldQueueRequest_returnsFalse()
    worker = _adb_testUtil_getEdgeRequestWorker()
    edgeRequest = _adb_EdgeRequest("request_id", { xdm: { key: "value" } }, 12345534&)
    consentState = _adb_ConsentState(_adb_ConfigurationModule())

    ' collect consent is set to "n"
    consentState.setCollectConsent("n")
    UTF_assertFalse(worker._shouldQueueRequest(edgeRequest, consentState), generateErrorMessage("should queue request (conset = n)", "false", "true"))
end sub


' ****************************** Helper functions ******************************

function _adb_testUtil_getEdgeRequestWorker(edgeResponseManager = _adb_edgeResponseManager() as object, consentState = invalid as object) as object
    if not _adb_isConsentStateModule(consentState) then
        consentState = _adb_ConsentState(_adb_ConfigurationModule())
    end if
    return _adb_EdgeRequestWorker(edgeResponseManager, consentState)
end function

function _adb_testUtil_getEdgeConfig() as object
    return {
        configId: "test_config_id",
        ecid: "test_ecid",
        edgeDomain: invalid
    }
end function

