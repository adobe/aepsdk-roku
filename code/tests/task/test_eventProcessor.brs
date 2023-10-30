' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

function _createMockedEventProcessor() as object
    return _adb_EventProcessor({
        hasField: function(_key as string) as boolean
            return false
        end function
    })
end function

' target: _setLogLevel()
' @Test
sub TC_adb_EventProcessor_handleEvent_setLogLevel()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    UTF_assertEqual(loggingService._logLevel, 1)

    eventProcessor = _createMockedEventProcessor()

    event = _adb_RequestEvent("setLogLevel", {
        level: 3
    })

    eventProcessor.handleEvent(event)
    UTF_assertEqual(loggingService._logLevel, 3)
end sub

' target: _setLogLevel()
' @Test
sub TC_adb_eventProcessor_handleEvent_setLogLevel_invalid()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    UTF_assertEqual(loggingService._logLevel, 1)

    eventProcessor = _createMockedEventProcessor()

    event = _adb_RequestEvent("setLogLevel", {
        invalid_key: 3
    })
    eventProcessor.handleEvent(event)
    UTF_assertEqual(loggingService._logLevel, 1)
end sub

' target: _resetIdentities()
' @Test
sub TC_adb_eventProcessor_handleEvent_resetIdentities()
    GetGlobalAA().reset_is_called = false

    eventProcessor = _createMockedEventProcessor()
    eventProcessor._identityModule.resetIdentities = function() as void
        GetGlobalAA().reset_is_called = true
    end function

    event = _adb_RequestEvent("resetIdentities", {})

    eventProcessor.handleEvent(event)

    UTF_assertTrue(GetGlobalAA().reset_is_called)
end sub

' target: _setConfiguration()
' @Test
sub TC_adb_eventProcessor_handleEvent_setConfiguration()
    GetGlobalAA().updateConfiguration_is_called = false

    eventProcessor = _createMockedEventProcessor()
    eventProcessor._configurationModule.updateConfiguration = function(data as object) as void
        GetGlobalAA().updateConfiguration_is_called = true
        UTF_assertEqual({
            edge: {
                configId: "config_id_test"
            }
        }, data)
    end function

    event = _adb_RequestEvent("setConfiguration", { edge: {
            configId: "config_id_test"
    } })
    eventProcessor.handleEvent(event)
    UTF_assertTrue(GetGlobalAA().updateConfiguration_is_called)
end sub

' target: _setECID()
' @Test
sub TC_adb_eventProcessor_handleEvent_setECID()
    GetGlobalAA().updateECID_is_called = false

    eventProcessor = _createMockedEventProcessor()
    eventProcessor._identityModule.updateECID = function(ecid as string) as void
        GetGlobalAA().updateECID_is_called = true
        UTF_assertEqual(ecid, "ecid_test")
    end function

    event = _adb_RequestEvent("setExperienceCloudId", {
        ecid: "ecid_test"
    })

    eventProcessor.handleEvent(event)
    UTF_assertTrue(GetGlobalAA().updateECID_is_called)
end sub

' target: _handleMediaEvents()
' @Test
sub TC_adb_eventProcessor_handleEvent_handleMediaEvents()
    GetGlobalAA().processEvent_is_called = false
    tsObj = _adb_TimestampObject()
    eventProcessor = _createMockedEventProcessor()
    eventProcessor._mediaModule.processEvent = function(requestId as string, data as object) as void
        GetGlobalAA().processEvent_is_called = true
        UTF_assertTrue(not _adb_isEmptyOrInvalidString(requestId))
        UTF_assertEqual(data.clientSessionId, "clientSessionId_test")
        UTF_assertEqual(data.tsObject, tsObj)
        UTF_assertEqual(data.xdmData, {
            "xdm": {
                "eventType": "media.sessionStart",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        })
    end function
    event = _adb_RequestEvent("sendMediaEvent", {
        clientSessionId: "clientSessionId_test",
        tsObject: tsObj,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        }
    })

    eventProcessor.handleEvent(event)
    UTF_assertTrue(GetGlobalAA().processEvent_is_called)
end sub

' target: _handleMediaEvents()
' @Test
sub TC_adb_eventProcessor_handleEvent_handleMediaEvents_invalid()
    GetGlobalAA().processEvent_is_called = false
    tsObj = _adb_TimestampObject()
    eventProcessor = _createMockedEventProcessor()
    eventProcessor._mediaModule.processEvent = function(requestId as string, data as object) as void
        GetGlobalAA().processEvent_is_called = true
    end function

    eventProcessor.handleEvent(_adb_RequestEvent("sendMediaEvent", {
        clientSessionId: "clientSessionId_test",
        tsObject: tsObj,
        xdmData: {
            "xdm": {}
        }
    }))
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)

    eventProcessor.handleEvent(_adb_RequestEvent("sendMediaEvent", {
        clientSessionId: "",
        tsObject: tsObj,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        }
    }))
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)

    eventProcessor.handleEvent(_adb_RequestEvent("sendMediaEvent", {
        clientSessionId: "clientSessionId_test",
        tsObject: invalid,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        }
    }))
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)
end sub

' target: _handleCreateMediaSession()
' @Test
sub TC_adb_eventProcessor_handleCreateMediaSession()
    GetGlobalAA().processEvent_is_called = false
    tsObj = _adb_TimestampObject()
    eventProcessor = _createMockedEventProcessor()
    eventProcessor._mediaModule.processEvent = function(requestId as string, data as object) as void
        GetGlobalAA().processEvent_is_called = true
        UTF_assertTrue(not _adb_isEmptyOrInvalidString(requestId))
        UTF_assertEqual(data.clientSessionId, "clientSessionId_test")
        UTF_assertEqual(data.tsObject, tsObj)
        UTF_assertEqual(data.xdmData, {
            "xdm": {
                "eventType": "media.sessionStart",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        })
        UTF_assertEqual(data.configuration, { "config.channel": "channel_test" })
    end function
    event = _adb_RequestEvent("createMediaSession", {
        clientSessionId: "clientSessionId_test",
        tsObject: tsObj,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        },
        configuration: { "config.channel": "channel_test" }
    })

    eventProcessor.handleEvent(event)
    UTF_assertTrue(GetGlobalAA().processEvent_is_called)
end sub

' target: _handleCreateMediaSession()
' @Test
sub TC_adb_eventProcessor_handleCreateMediaSession_invalid()
    GetGlobalAA().processEvent_is_called = false
    tsObj = _adb_TimestampObject()
    eventProcessor = _createMockedEventProcessor()
    eventProcessor._mediaModule.processEvent = function(requestId as string, data as object) as void
        GetGlobalAA().processEvent_is_called = true
    end function
    event = _adb_RequestEvent("createMediaSession", {
        clientSessionId: "",
        tsObject: tsObj,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        },
        configuration: { "config.channel": "channel_test" }
    })

    eventProcessor.handleEvent(event)
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)

    eventProcessor.handleEvent(_adb_RequestEvent("createMediaSession", {
        clientSessionId: "clientSessionId_test",
        tsObject: invalid,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        },
        configuration: { "config.channel": "channel_test" }
    }))
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)

    eventProcessor.handleEvent(_adb_RequestEvent("createMediaSession", {
        clientSessionId: "clientSessionId_test",
        tsObject: tsObj,
        xdmData: {},
        configuration: { "config.channel": "channel_test" }
    }))
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)

    eventProcessor.handleEvent(_adb_RequestEvent("createMediaSession", {
        clientSessionId: "clientSessionId_test",
        tsObject: tsObj,
        xdmData: {
            "xdm": {
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        },
        configuration: invalid
    }))
    UTF_assertTrue(not GetGlobalAA().processEvent_is_called)
end sub

' target: _hasXDMData()
' @Test
sub TC_adb_eventProcessor_hasXDMData()
    eventProcessor = _createMockedEventProcessor()
    UTF_assertFalse(eventProcessor._hasXDMData(invalid))
    UTF_assertFalse(eventProcessor._hasXDMData({}))
    UTF_assertFalse(eventProcessor._hasXDMData({ key: "value" }))
    UTF_assertFalse(eventProcessor._hasXDMData({ data: { xdm: {} } }))
    UTF_assertTrue(eventProcessor._hasXDMData({ data: { xdm: { key: "value" } } }))
end sub

' target: _sendEvent()
' @Test
sub TC_adb_eventProcessor_handleEvent_sendEvent()
    GetGlobalAA().processEvent_is_called = false

    eventProcessor = _createMockedEventProcessor()

    eventProcessor._edgeModule.processEvent = function(requestId as string, xdmData as object, timestampInMillis as integer) as void
        GetGlobalAA().processEvent_is_called = true
        UTF_assertEqual(requestId, "request_id_test")
        UTF_assertEqual(xdmData, { xdm: { key: "value" } })
        UTF_assertEqual(timestampInMillis, 12345678)
    end function

    event = _adb_RequestEvent("sendEvent", {
        xdm: {
            key: "value"
        }
    })

    event.uuid = "request_id_test"
    event.timestampInMillis = 12345678

    eventProcessor.handleEvent(event)
    UTF_assertTrue(GetGlobalAA().processEvent_is_called)
end sub

' target: _sendResponseEvent()
' @Test
sub TC_adb_eventProcessor_sendResponseEvent()
    eventProcessor = _createMockedEventProcessor()
    eventProcessor._task = { responseEvent: invalid }

    responseEvent = _adb_ResponseEvent("uuid", {
        code: 200,
        result: {}
    })
    eventProcessor._sendResponseEvent(responseEvent)

    UTF_assertEqual(eventProcessor._task.responseEvent, responseEvent)
end sub

' target: processQueuedRequests()
' @Test
sub TC_adb_eventProcessor_processQueuedRequests()
    GetGlobalAA()._sendResponseEvents_is_called = false

    eventProcessor = _createMockedEventProcessor()
    eventProcessor._edgeModule.processQueuedRequests = function() as dynamic
        array = []
        array.Push(_adb_ResponseEvent("request_id_test", {
            code: 200,
            message: "message_test"
        }))
        return array
    end function
    eventProcessor._sendResponseEvents = function(array as object) as void
        GetGlobalAA()._sendResponseEvents_is_called = true
        UTF_assertEqual(1, array.Count())
        UTF_assertEqual("request_id_test", array[0].parentId)
        UTF_assertEqual({
            code: 200,
            message: "message_test"
        }, array[0].data)
    end function
    eventProcessor.processQueuedRequests()
    UTF_assertTrue(GetGlobalAA()._sendResponseEvents_is_called)
end sub

' target: processQueuedRequests()
' @Test
sub TC_adb_eventProcessor_processQueuedRequests_multiple()
    GetGlobalAA()._sendResponseEvents_is_called = false

    eventProcessor = _createMockedEventProcessor()
    eventProcessor._edgeModule.processQueuedRequests = function() as dynamic
        array = []
        array.Push(_adb_ResponseEvent("request_id_test_1", {
            code: 200,
            message: "message_test 1"
        }))
        array.Push(_adb_ResponseEvent("request_id_test_2", {
            code: 200,
            message: "message_test 2"
        }))
        return array
    end function
    eventProcessor._sendResponseEvents = function(array as object) as void
        GetGlobalAA()._sendResponseEvents_is_called = true
        UTF_assertEqual(2, array.Count())
        UTF_assertEqual("request_id_test_1", array[0].parentId)
        UTF_assertEqual({
            code: 200,
            message: "message_test 1"
        }, array[0].data)
        UTF_assertEqual("request_id_test_2", array[1].parentId)
        UTF_assertEqual({
            code: 200,
            message: "message_test 2"
        }, array[1].data)
    end function
    eventProcessor.processQueuedRequests()
    UTF_assertTrue(GetGlobalAA()._sendResponseEvents_is_called)
end sub

' target: processQueuedRequests()
' @Test
sub TC_adb_eventProcessor_processQueuedRequests_bad_request()
    GetGlobalAA()._sendResponseEvents_is_called = false

    eventProcessor = _createMockedEventProcessor()
    eventProcessor._edgeModule.processQueuedRequests = function() as dynamic
        array = []
        return array
    end function
    eventProcessor._sendResponseEvents = function(array as object) as void
        GetGlobalAA()._sendResponseEvents_is_called = true
        UTF_assertEqual(0, array.Count())
    end function
    eventProcessor.processQueuedRequests()
    UTF_assertTrue(GetGlobalAA()._sendResponseEvents_is_called)
end sub

' target: init()
' @Test
sub TC_adb_eventProcessor_init()
    eventProcessor = _createMockedEventProcessor()
    UTF_AssertNotInvalid(eventProcessor._configurationModule)
    UTF_AssertNotInvalid(eventProcessor._identityModule)
    UTF_AssertNotInvalid(eventProcessor._edgeModule)
end sub
