' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_EdgeRequestWorker()
' @Test
sub TC_adb_EdgeRequestWorker_init()
    worker = _adb_EdgeRequestWorker()
    UTF_AssertNotInvalid(worker)
end sub

' target: hasQueuedEvent()
' @Test
sub TC_adb_EdgeRequestWorker_hasQueuedEvent()
    worker = _adb_EdgeRequestWorker()
    worker._queue = []
    UTF_assertFalse(worker.hasQueuedEvent())
    worker._queue.Push({})
    UTF_assertTrue(worker.hasQueuedEvent())
    worker._queue.Shift()
    UTF_assertFalse(worker.hasQueuedEvent())
end sub

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue()
    worker = _adb_EdgeRequestWorker()
    worker._queue = []
    timestampInMillis& = _adb_timestampInMillis()
    worker.queue("request_id", { xdm: {} }, timestampInMillis&, {}, "/ee/v1/interact")
    UTF_assertEqual(1, worker._queue.Count())
    expectedObj = {
        requestId: "request_id",
        meta: {},
        path: "/ee/v1/interact",
        eventData: { xdm: {} },
        timestampInMillis: timestampInMillis&
    }
    UTF_assertEqual(expectedObj, worker._queue[0])

end sub

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue_bad_input()
    worker = _adb_EdgeRequestWorker()
    worker._queue = []
    worker.queue("request_id", [{ xdm: {} }], -1, {}, "")
    worker.queue("request_id", [], 12345534, {}, "")
    worker.queue("request_id", invalid, 12345534, {}, "")
    worker.queue("request_id", 999, 12345534, {}, "")
    worker.queue("request_id", "invalid object", 12345534, {}, "")
    worker.queue("", [{ xdm: {} }], 12345534, {}, "")
    UTF_assertEqual(0, worker._queue.Count())
end sub

' target: queue()
' @Test
sub TC_adb_EdgeRequestWorker_queue_limit()
    worker = _adb_EdgeRequestWorker()
    worker._queue = []
    worker._queue_size_max = 2
    worker.queue("request_id", { xdm: {} }, 12345534, {}, "")
    worker.queue("request_id", { xdm: {} }, 12345535, {}, "")
    worker.queue("request_id", { xdm: {} }, 12345536, {}, "")
    UTF_assertEqual(2, worker._queue.Count())
end sub

' target: clear()
' @Test
sub TC_adb_EdgeRequestWorker_clear()
    worker = _adb_EdgeRequestWorker()
    worker._queue = []
    worker.queue("request_id", { xdm: {} }, 12345534, {}, "")
    worker.queue("request_id", { xdm: {} }, 12345535, {}, "")
    worker.queue("request_id", { xdm: {} }, 12345536, {}, "")
    UTF_assertEqual(3, worker._queue.Count())
    worker.clear()
    UTF_assertEqual(0, worker._queue.Count())
end sub

' target: _processRequest()
' @Test
sub TC_adb_EdgeRequestWorker_processRequest_valid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count(), "Expected != Actual (Number of headers)")
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", invalid, invalid)

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
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", { "konductorTestConfig" : "testValue"}, invalid)

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
        UTF_assertEqual("https://testDomain/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", invalid, "testDomain")

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
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(3, jsonObj.Count(), "Expected != Actual (Request json body size)")
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" }, config: { "datastreamConfigOverride": {"test" : {"key": "value"}} } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", invalid, invalid)

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
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert configOverrides in under meta
        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
            "sdkConfig": {
                "datastream": {
                    "original": "config_id"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" }, config: { "datastreamIdOverride": "datastreamIdOverride", "datastreamConfigOverride": {"test" : {"key": "value"}} } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", invalid, invalid)

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
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
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
                    "original": "config_id"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" }, config: { "datastreamIdOverride": "datastreamIdOverride", "datastreamConfigOverride": {"test" : {"key": "value"}} } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", { "konductorTestConfig" : {"key": "value"} }, invalid)

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
                        id: "ecid_test",
                        primary: false
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.1.0"
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm, "Expected != actual (Top level XDM object in the request)")

        ''' Assert sdkConfig in under meta
        UTF_assertNotInvalid(jsonObj.meta)
        expectedMetaObj = {
            sdkConfig: {
                datastream: {
                    "original": "config_id"
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

    worker = _adb_EdgeRequestWorker()
    networkResponse = worker._processRequest({ xdm: { key: "value" }, config: { "datastreamIdOverride": "datastreamIdOverride" } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", invalid, invalid)

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
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count())
        UTF_assertNotInvalid(jsonObj.xdm)
        UTF_assertNotInvalid(jsonObj.events)
        return invalid
    end function

    worker = _adb_EdgeRequestWorker()
    result = worker._processRequest({ xdm: { key: "value" } }, "ecid_test", "config_id", "request_id", "/ee/v1/interact", invalid, invalid)

    UTF_assertInvalid(result)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

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

    worker = _adb_EdgeRequestWorker()
    worker.queue("request_id_1", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    worker.queue("request_id_2", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")

    responseArray = worker.processRequests("config_id", "ecid_test")
    ' processRequests: function(configId as string, ecid as string, edgeDomain = invalid as dynamic) as dynamic

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

    worker = _adb_EdgeRequestWorker()
    result = worker.processRequests("config_id", "ecid_test")
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

    worker = _adb_EdgeRequestWorker()

    worker.queue("request_id_1", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    worker.queue("request_id_2", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    worker.queue("request_id_3", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    responseArray = worker.processRequests("config_id", "ecid_test")

    UTF_assertEqual(1, responseArray.Count())
    ' queued reqeust should be processed in order
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())

    UTF_assertEqual(2, worker._queue.Count())
    UTF_assertNotInvalid(worker._queue[0], "Request should not be invalid")
    UTF_assertEqual("request_id_2", worker._queue[0].requestId)
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
    responseArray = worker.processRequests("config_id", "ecid_test")

    UTF_assertEqual(0, responseArray.Count())
    UTF_assertEqual(2, worker._queue.Count())

    ' Request should be not be sent since < 30 seconds
    worker._lastFailedRequestTS = worker._lastFailedRequestTS - 9000 ' Mock 9 seconds elapsed timer (total 29 seconds)
    responseArray = worker.processRequests("config_id", "ecid_test")

    UTF_assertEqual(0, responseArray.Count())
    UTF_assertEqual(2, worker._queue.Count())

    ' Request should be retried after 30 seconds
    worker._lastFailedRequestTS = worker._lastFailedRequestTS - 1000 ' Mock 1 second elapsed timer (total 30 seconds)
    responseArray = worker.processRequests("config_id", "ecid_test")

    UTF_assertEqual(2, responseArray.Count())
    UTF_assertEqual(0, worker._queue.Count())
    UTF_assertEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be reset to -1")

    _adb_serviceProvider().networkService.syncPostRequest = cachedFunction
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

    worker = _adb_EdgeRequestWorker()

    worker.queue("request_id_1", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    worker.queue("request_id_2", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    worker.queue("request_id_3", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    responseArray = worker.processRequests("config_id", "ecid_test")

    UTF_assertEqual(1, responseArray.Count())
    ' queued reqeust should be processed in order
    UTF_assertTrue(_adb_isEdgeResponse(responseArray[0]))
    UTF_assertEqual("request_id_1", responseArray[0].getRequestId())

    UTF_assertEqual(2, worker._queue.Count())
    UTF_assertNotInvalid(worker._queue[0], "Request should not be invalid")
    UTF_assertEqual("request_id_2", worker._queue[0].requestId)
    UTF_assertNotEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be set")

    ' Set the network to pass for the retry
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        return _adb_NetworkResponse(200, "response body")
    end function

    ' Request should be not be sent since < 30 seconds
    worker.queue("request_id_4", { xdm: { key: "value" } }, 12345534, {}, "/ee/v1/interact")
    UTF_assertEqual(-1, worker._lastFailedRequestTS, "Failed Request TS should be reset to -1")

    responseArray = worker.processRequests("config_id", "ecid_test")
    UTF_assertEqual(3, responseArray.Count())
    UTF_assertEqual(0, worker._queue.Count())

    _adb_serviceProvider().networkService.syncPostRequest = cachedFunction
end sub
