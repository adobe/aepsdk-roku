' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


' @BeforeEach
sub AdobeEdgeTestSuite_EventProcessor_BeforeEach()
    print "AdobeEdgeTestSuite_EventProcessor_BeforeEach"
end sub

' @AfterAll
sub AdobeEdgeTestSuite_EventProcessor_TearDown()
    print "AdobeEdgeTestSuite_EventProcessor_TearDown"
end sub

' target: _setLogLevel()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    UTF_assertEqual(loggingService._logLevel, 1)

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.handleEvent({
        owner: "adobe",
        apiName: "setLogLevel",
        data: {
            level: 3
        },
        timestamp: "1234",
        uuid: "4567"
    })
    UTF_assertEqual(loggingService._logLevel, 3)
end sub

' target: _setLogLevel()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel_invalid()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    UTF_assertEqual(loggingService._logLevel, 1)

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.handleEvent({
        owner: "adobe",
        apiName: "setLogLevel",
        data: {
            invalid_key: 3
        },
        timestamp: "1234",
        uuid: "4567"
    })
    UTF_assertEqual(loggingService._logLevel, 1)
end sub

' target: _resetIdentities()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_resetIdentities()
    GetGlobalAA().reset_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.stateManager.reset = function() as void
        GetGlobalAA().reset_is_called = true
    end function

    eventProcessor.handleEvent({
        owner: "adobe",
        apiName: "resetIdentities",
        data: {}
    })

    UTF_assertTrue(GetGlobalAA().reset_is_called)
end sub

' target: _setConfiguration()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setConfiguration()
    GetGlobalAA().updateConfiguration_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.stateManager.updateConfiguration = function(data as object) as void
        GetGlobalAA().updateConfiguration_is_called = true
        UTF_assertEqual({
            edge: {
                configId: "config_id_test"
            }
        }, data)
    end function

    eventProcessor.handleEvent({
        owner: "adobe",
        apiName: "setConfiguration",
        data: {
            edge: {
                configId: "config_id_test"
            }
        }
    })
    UTF_assertTrue(GetGlobalAA().updateConfiguration_is_called)
end sub

' target: _setECID()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setECID()
    GetGlobalAA().updateECID_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.stateManager.updateECID = function(ecid as string) as void
        GetGlobalAA().updateECID_is_called = true
        UTF_assertEqual(ecid, "ecid_test")
    end function

    eventProcessor.handleEvent({
        owner: "adobe",
        apiName: "setExperienceCloudId",
        data: {
            ecid: "ecid_test"
        }
    })
    UTF_assertTrue(GetGlobalAA().updateECID_is_called)
end sub

' target: _hasXDMData()
' @Test
sub TestCase_AdobeEdge_EventProcessor_hasXDMData()
    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    UTF_assertFalse(eventProcessor._hasXDMData(invalid))
    UTF_assertFalse(eventProcessor._hasXDMData({}))
    UTF_assertFalse(eventProcessor._hasXDMData({ key: "value" }))
    UTF_assertFalse(eventProcessor._hasXDMData({ data: { xdm: {} } }))
    UTF_assertTrue(eventProcessor._hasXDMData({ data: { xdm: { key: "value" } } }))
end sub

' target: _sendEvent()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_sendEvent()
    GetGlobalAA().queue_is_called = false
    GetGlobalAA().processQueuedRequests_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})

    eventProcessor.edgeRequestWorker.queue = function(requestId as string, xdmData as object, timestamp as integer) as void
        GetGlobalAA().queue_is_called = true
        UTF_assertEqual(requestId, "request_id_test")
        UTF_assertEqual(xdmData, { xdm: { key: "value" } })
        UTF_assertEqual(timestamp, 12345678)
    end function

    eventProcessor.processQueuedRequests = function() as void
        GetGlobalAA().processQueuedRequests_is_called = true
    end function

    eventProcessor.handleEvent({
        owner: "adobe",
        apiName: "sendEdgeEvent",
        uuid: "request_id_test",
        timestamp_in_millis: 12345678,
        data: {
            xdm: {
                key: "value"
            }
        },
    })
    UTF_assertTrue(GetGlobalAA().queue_is_called)
    UTF_assertTrue(GetGlobalAA().processQueuedRequests_is_called)
end sub

' target: _sendResponseEvent()
' @Test
sub TestCase_AdobeEdge_EventProcessor_sendResponseEvent()
    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.task = { responseEvent: invalid }

    eventProcessor._sendResponseEvent({
        owner: "adobe",
        uuid: "uuid",
        data: {
            code: 200,
            result: {}
        }
    })
    UTF_assertEqual(eventProcessor.task.responseEvent, {
        owner: "adobe",
        uuid: "uuid",
        data: {
            code: 200,
            result: {}
        }
    })
end sub

' target: processQueuedRequests()
' @Test
sub TestCase_AdobeEdge_EventProcessor_processQueuedRequests()
    GetGlobalAA()._sendResponseEvent_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})

    eventProcessor.edgeRequestWorker.isReadyToProcess = function() as boolean
        return true
    end function

    eventProcessor.edgeRequestWorker.processRequests = function() as dynamic
        return [{
            requestId: "request_id_test",
            code: 200,
            message: "message_test",
        }]
    end function

    eventProcessor._sendResponseEvent = function(event as object) as void
        GetGlobalAA()._sendResponseEvent_is_called = true
        UTF_assertEqual({
            uuid: "request_id_test",
            data: {
                code: 200,
                message: "message_test",
            }
        }, event)
    end function
    eventProcessor.processQueuedRequests()
    UTF_assertTrue(GetGlobalAA()._sendResponseEvent_is_called)
end sub

' target: processQueuedRequests()
' @Test
sub TestCase_AdobeEdge_EventProcessor_processQueuedRequests_multiple_requests()
    GetGlobalAA()._adb_response_events = []

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})

    eventProcessor.edgeRequestWorker.isReadyToProcess = function() as boolean
        return true
    end function

    eventProcessor.edgeRequestWorker.processRequests = function() as dynamic
        return [{
            requestId: "request_id_test_1",
            code: 200,
            message: "message_test",
        }, {
            requestId: "request_id_test_2",
            code: 200,
            message: "message_test",
        }]
    end function

    eventProcessor._sendResponseEvent = function(event as object) as void
        list = GetGlobalAA()._adb_response_events
        list.Push(event)
    end function

    eventProcessor.processQueuedRequests()

    UTF_assertEqual(2, GetGlobalAA()._adb_response_events.Count())

    UTF_assertEqual({
        uuid: "request_id_test_1",
        data: {
            code: 200,
            message: "message_test",
        }
    }, GetGlobalAA()._adb_response_events[0])

    UTF_assertEqual({
        uuid: "request_id_test_2",
        data: {
            code: 200,
            message: "message_test",
        }
    }, GetGlobalAA()._adb_response_events[1])

    GetGlobalAA()._adb_response_events = []
end sub

' target: processQueuedRequests()
' @Test
sub TestCase_AdobeEdge_EventProcessor_processQueuedRequests_bad_request()
    GetGlobalAA()._sendResponseEvent_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})

    eventProcessor.edgeRequestWorker.isReadyToProcess = function() as boolean
        return true
    end function

    eventProcessor.edgeRequestWorker.processRequests = function() as dynamic
        return invalid
    end function

    eventProcessor._sendResponseEvent = function(event as object) as void
        GetGlobalAA()._sendResponseEvent_is_called = true
    end function

    UTF_assertFalse(GetGlobalAA()._sendResponseEvent_is_called)
end sub

' target: processQueuedRequests()
' @Test
sub TestCase_AdobeEdge_EventProcessor_processQueuedRequests_empty_queue()
    GetGlobalAA().processRequests_is_called = false

    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcessor.edgeRequestWorker.isReadyToProcess = function() as boolean
        return false
    end function
    eventProcessor.edgeRequestWorker.processRequests = function() as void
        GetGlobalAA().processRequests_is_called = true
    end function

    eventProcessor.processQueuedRequests()

    UTF_assertFalse(GetGlobalAA().processRequests_is_called)
end sub

' target: init()
' @Test
sub TestCase_AdobeEdge_EventProcessor_init()
    eventProcessor = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    UTF_assertEqual(eventProcessor.edgeRequestWorker._stateManager, eventProcessor.stateManager)
end sub