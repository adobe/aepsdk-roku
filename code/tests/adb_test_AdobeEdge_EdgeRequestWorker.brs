' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeAll
sub AdobeEdgeTestSuite_EdgeRequestWorker_SetUp()
    print "AdobeEdgeTestSuite_EdgeRequestWorker_SetUp"
end sub

' @BeforeEach
sub AdobeEdgeTestSuite_EdgeRequestWorker_BeforeEach()
end sub

' @AfterAll
sub AdobeEdgeTestSuite_EdgeRequestWorker_TearDown()
    print "AdobeEdgeTestSuite_EdgeRequestWorker_TearDown"
end sub

' target: _adb_EdgeRequestWorker()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_init()
    worker = _adb_EdgeRequestWorker({})
    UTF_AssertNotInvalid(worker)
end sub

' target: _adb_EdgeRequestWorker()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_init_invalid()
    worker = _adb_EdgeRequestWorker(invalid)
    UTF_assertInvalid(worker)
end sub

' target: isReadyToProcess()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_isReadyToProcess()
    worker = _adb_EdgeRequestWorker({})
    worker._queue = []
    UTF_assertFalse(worker.isReadyToProcess())
    worker._queue.Push({})
    UTF_assertTrue(worker.isReadyToProcess())
    worker._queue.Shift()
    UTF_assertFalse(worker.isReadyToProcess())
end sub

' target: queue()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_queue()
    worker = _adb_EdgeRequestWorker({})
    worker._queue = []
    worker.queue("request_id", { xdm: {} }, 12345534)
    UTF_assertEqual(1, worker._queue.Count())
    expectedObj = {
        requestId: "request_id",
        xdmData: { xdm: {} },
        timestamp: 12345534
    }
    UTF_assertEqual(expectedObj, worker._queue[0])

end sub

' target: queue()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_queue_bad_input()
    worker = _adb_EdgeRequestWorker({})
    worker._queue = []
    worker.queue("request_id", { xdm: {} }, -1)
    worker.queue("request_id", {}, 12345534)
    worker.queue("request_id", invalid, 12345534)
    worker.queue("request_id", 999, 12345534)
    worker.queue("request_id", "invalid object", 12345534)
    worker.queue("", { xdm: {} }, 12345534)
    UTF_assertEqual(0, worker._queue.Count())
end sub

' target: queue()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_queue_limit()
    worker = _adb_EdgeRequestWorker({})
    worker._queue = []
    worker._queue_size_max = 2
    worker.queue("request_id", { xdm: {} }, 12345534)
    worker.queue("request_id", { xdm: {} }, 12345535)
    worker.queue("request_id", { xdm: {} }, 12345536)
    UTF_assertEqual(2, worker._queue.Count())
end sub

' target: clear()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_clear()
    worker = _adb_EdgeRequestWorker({})
    worker._queue = []
    worker.queue("request_id", { xdm: {} }, 12345534)
    worker.queue("request_id", { xdm: {} }, 12345535)
    worker.queue("request_id", { xdm: {} }, 12345536)
    UTF_assertEqual(3, worker._queue.Count())
    worker.clear()
    UTF_assertEqual(0, worker._queue.Count())
end sub

' target: _processRequest()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequest()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count())
        UTF_assertNotInvalid(jsonObj.xdm)
        expectedXdmObj = {
            identitymap: {
                ecid: [
                    {
                        authenticatedstate: "ambiguous",
                        id: "ecid_test",
                        primary: true
                    }
                ]
            },
            implementationdetails: {
                environment: "app",
                name: "https://ns.adobe.com/experience/mobilesdk/roku",
                version: "1.0.0-alpha1"
            }
        }
        UTF_assertEqual(expectedXdmObj, jsonObj.xdm)
        UTF_assertNotInvalid(jsonObj.events)
        expectedEventsArray = [
            {
                xdm: {
                    key: "value"
                }
            }
        ]
        UTF_assertEqual(expectedEventsArray, jsonObj.events, "validate the xdm data")
        return {
            statusCode: 200,
            body: "response body"
        }
    end function

    worker = _adb_EdgeRequestWorker({})
    result = worker._processRequest({ xdm: { key: "value" } }, "ecid_test", "config_id", "request_id", invalid)

    UTF_assertEqual("request_id", result.requestId)
    UTF_assertEqual(200, result.statusCode)
    UTF_assertEqual("response body", result.body)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: _processRequest()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequest_invalid_response()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id&requestId=request_id", url)
        UTF_assertEqual(2, jsonObj.Count())
        UTF_assertNotInvalid(jsonObj.xdm)
        UTF_assertNotInvalid(jsonObj.events)
        return invalid
    end function

    worker = _adb_EdgeRequestWorker({})
    result = worker._processRequest({ xdm: { key: "value" } }, "ecid_test", "config_id", "request_id", invalid)

    UTF_assertInvalid(result)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequests()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        if url.Instr("request_id_1") > 0 then
            return {
                code: 200,
                message: "response body 1"
            }
        end if
        if url.Instr("request_id_2") > 0 then
            return {
                code: 200,
                message: "response body 2"
            }
        end if
    end function
    stateManager = _adb_stateManager()
    stateManager._edge_configId = "config_id"
    stateManager._edge_domain = invalid
    stateManager._ecid = "ecid_test"
    worker = _adb_EdgeRequestWorker(stateManager)
    worker.queue("request_id_1", { xdm: { key: "value" } }, 12345534)
    worker.queue("request_id_2", { xdm: { key: "value" } }, 12345534)
    responseArray = worker.processRequests()

    UTF_assertEqual(2, responseArray.Count())
    ' queued reqeust shoudl be processed in order
    UTF_assertEqual("request_id_1", responseArray[0].requestId)
    UTF_assertEqual("request_id_2", responseArray[1].requestId)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequests_empty_queue()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_fail("should not be called")
        return invalid
    end function

    stateManager = _adb_stateManager()
    stateManager._edge_configId = "config_id"
    stateManager._edge_domain = invalid
    stateManager._ecid = "ecid_test"
    worker = _adb_EdgeRequestWorker(stateManager)
    result = worker.processRequests()
    UTF_assertInvalid(result)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub

' target: processRequests()
' @Test
sub TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequests_recoverable_error()
    cachedFuntion = _adb_serviceProvider().networkService.syncPostRequest
    _adb_serviceProvider().networkService.syncPostRequest = function(url as string, jsonObj as object, headers = [] as object) as object
        UTF_assertEqual(0, headers.Count())
        UTF_assertNotInvalid(url)
        UTF_assertNotInvalid(jsonObj)
        if url.Instr("request_id_1") > 0 then
            return {
                code: 200,
                message: "response body 1"
            }
        end if
        if url.Instr("request_id_2") > 0 then
            return {
                code: 408,
                message: "response body 2"
            }
        end if
        if url.Instr("request_id_3") > 0 then
            return {
                code: 200,
                message: "response body 3"
            }
        end if
    end function
    stateManager = _adb_stateManager()
    stateManager._edge_configId = "config_id"
    stateManager._edge_domain = invalid
    stateManager._ecid = "ecid_test"
    worker = _adb_EdgeRequestWorker(stateManager)
    worker.queue("request_id_1", { xdm: { key: "value" } }, 12345534)
    worker.queue("request_id_2", { xdm: { key: "value" } }, 12345534)
    worker.queue("request_id_3", { xdm: { key: "value" } }, 12345534)
    responseArray = worker.processRequests()

    UTF_assertEqual(1, responseArray.Count())
    ' queued reqeust shoudl be processed in order
    UTF_assertEqual("request_id_1", responseArray[0].requestId)

    UTF_assertEqual(2, worker._queue.Count())

    UTF_assertEqual("request_id_2", worker._queue[0].requestId)

    _adb_serviceProvider().networkService.syncPostRequest = cachedFuntion
end sub