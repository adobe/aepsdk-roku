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
    worker.queue("request_id", { xdm: {} }, 12345534)
    UTF_assertEqual(1, worker._queue.Count())
    expectedObj = {
        requestId: "request_id",
        xdmData: { xdm: {} },
        timestamp: 12345534
    }
    UTF_assertEqual(expectedObj, worker._queue[0])

end sub

