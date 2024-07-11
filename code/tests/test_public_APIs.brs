' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

'@BeforeAll
sub TS_public_APIs_BeforeAll()
    GetGlobalAA().TIMEOUT_MS = 101
end sub

' @BeforeEach
sub TS_public_APIs_BeforeEach()
    GetGlobalAA()._adb_public_api = invalid
    GetGlobalAA()._adb_main_task_node = {
        observeField: function(_arg1 as string, _arg2 as string) as void
        end function
    }
    sdkInstance = AdobeAEPSDKInit()
    GetGlobalAA()._adb_main_task_node["requestEvent"] = {}
    sdkInstance._private.cachedCallbackInfo = {}
    api = GetGlobalAA()._adb_public_api
    ' set callback timeout to 100ms for testing
    api._private.cons.CALLBACK_TIMEOUT_MS = 100
end sub

' @AfterAll
sub TS_public_APIs_TearDown()
    GetGlobalAA()._adb_public_api = invalid
    GetGlobalAA()._adb_main_task_node = invalid
end sub

' target: getVersion()
' @Test
sub TC_APIs_getVersion()
    sdkInstance = AdobeAEPSDKInit()
    UTF_assertEqual(sdkInstance.getVersion(), getTestSDKVersion())
end sub

' target: setLogLevel()
' @Test
sub TC_APIs_setLogLevel()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.setLogLevel(3)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SET_LOG_LEVEL)
    UTF_assertEqual(event.data, { level: 3 })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: setLogLevel()
' @Test
sub TC_APIs_setLogLevel_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.setLogLevel(5)
    sdkInstance.setLogLevel(-1)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(0, event.Count())
end sub

' target: shutdown()
' @Test
sub TC_APIs_shutdown()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance._private.cachedCallbackInfo["xxx"] = {
        "callback": function() as void
        end function
    }
    taskNode = GetGlobalAA()._adb_main_task_node

    sdkInstance.shutdown()

    UTF_assertEqual(taskNode.control, "DONE")
    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo, {})
    UTF_assertInvalid(GetGlobalAA()._adb_main_task_node)
    UTF_assertInvalid(GetGlobalAA()._adb_public_api)
end sub

' target: updateConfiguration()
' @Test
sub TC_APIs_updateConfiguration()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    configuration = { "edge.configId": "test-config-id" }
    sdkInstance.updateConfiguration(configuration)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SET_CONFIGURATION)
    UTF_assertEqual(event.data, configuration)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: updateConfiguration()
' @Test
sub TC_APIs_updateConfiguration_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.updateConfiguration("x")
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(0, event.Count())
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEvent()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    data = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            commerce: {}
        },
        "data": {
            "testKey": "testValue"
        },
        "config": {
            "datastreamIdOverride": "testDatastreamIdOverride",
            "datastreamConfigOverride": {
                "test": {
                    "testKey": "testValue"
                }
            }
        }
    }

    sdkInstance.sendEvent(data)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    expectedData = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            timestamp: event.timestamp,
            commerce: {}
        },
        "data": {
            "testKey": "testValue"
        },
        "config": {
            "datastreamIdOverride": "testDatastreamIdOverride",
            "datastreamConfigOverride": {
                "test": {
                    "testKey": "testValue"
                }
            }
        }
    }

    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SEND_EDGE_EVENT)
    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
    UTF_assertEqual(event.data, expectedData)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEventWithData()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    data = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            commerce: {}
        }
        "data": {
            "testKey": "testValue"
        }
    }

    sdkInstance.sendEvent(data)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    expectedData = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            timestamp: event.timestamp,
            commerce: {}
        },
        "data": {
            "testKey": "testValue"
        }
    }

    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SEND_EDGE_EVENT)
    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
    UTF_assertEqual(event.data, expectedData)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEvent_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.sendEvent("invalid event data")
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count())

    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEventWithData_invalidData()
    sdkInstance = AdobeAEPSDKInit()

    data = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            commerce: {}
        }
        "data": "Not a map"
    }

    sdkInstance.sendEvent(data)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count())

    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEvent_missingRequiredXDMData()
    sdkInstance = AdobeAEPSDKInit()
    data = {
        "data": {
            eventType: "commerce.orderPlaced",
            commerce: {}
        }
    }

    sdkInstance.sendEvent(data)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count())

    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEventWithCallback()
    sdkInstance = AdobeAEPSDKInit()

    data = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            commerce: {}
        },
        "data": {
            "testKey": "testValue"
        }
    }

    context = {
        content: "test"
    }
    callback_result = {
        "test": "test"
    }

    sdkInstance.sendEvent(data, sub(ctx, result)
        UTF_assertEqual({
            content: "test"
        }, ctx)
        UTF_assertEqual(result, {
            "test": "test"
        })
    end sub, context)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    callbackInfo = sdkInstance._private.cachedCallbackInfo[event.uuid]

    UTF_assertEqual(callbackInfo.context, context)
    UTF_AssertNotInvalid(callbackInfo.timestampInMillis)
    callbackInfo.cb(context, callback_result)
    UTF_assertEqual(event.apiName, "sendEvent")
    UTF_assertEqual(event.data, data)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: sendEvent()
' @Test
sub TC_APIs_sendEventWithCallback_timeout()
    sdkInstance = AdobeAEPSDKInit()

    data = {
        "xdm": {
            eventType: "commerce.orderPlaced",
            commerce: {}
        },
        "data": {
            "testKey": "testValue"
        }
    }

    context = {
        content: "test"
    }
    _callback_result = {
        "test": "test"
    }

    sdkInstance.sendEvent(data, sub(_ctx, _result)
        throw "should not be called"
    end sub, context)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    callbackInfo = sdkInstance._private.cachedCallbackInfo[event.uuid]

    UTF_assertEqual(callbackInfo.context, context)
    UTF_AssertNotInvalid(callbackInfo.timestampInMillis)

    UTF_assertEqual(event.apiName, "sendEvent")
    UTF_assertEqual(event.data, data)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
    requestId = event.uuid

    sleep(GetGlobalAA().TIMEOUT_MS)

    responseEvent = _adb_ResponseEvent(requestId, {})
    GetGlobalAA()._adb_main_task_node["responseEvent"] = responseEvent
    try
        _adb_handleResponseEvent()
        UTF_assertFalse(sdkInstance._private.cachedCallbackInfo.DoesExist(requestId))
    catch e
        UTF_fail(e.message)
    end try

end sub

' target: setExperienceCloudId()
' @Test
sub TC_APIs_setExperienceCloudId()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    test_id = "test-experience-cloud-id"
    sdkInstance.setExperienceCloudId(test_id)
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID)
    UTF_assertEqual(event.data, { ecid: test_id })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: getExperienceCloudId()
' @Test
sub TC_APIs_getExperienceCloudId()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    context = {
        content: "test"
    }
    callback_result = "testECID"

    sdkInstance.getExperienceCloudId(sub(ctx, result)
        UTF_assertEqual({
            content: "test"
        }, ctx)
        UTF_assertEqual(result, "testECID")
    end sub, context)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    callbackInfo = sdkInstance._private.cachedCallbackInfo[event.uuid]

    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.GET_EXPERIENCE_CLOUD_ID)
    UTF_assertInvalid(event.data)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
    UTF_assertEqual(callbackInfo.context, context)
    UTF_AssertNotInvalid(callbackInfo.timestampInMillis)
    callbackInfo.cb(context, callback_result)
end sub

' target: getExperienceCloudId()
' @Test
sub TC_APIs_getExperienceCloudId_callbackTimeout()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    context = {
        content: "test"
    }
    callback_result = "testECID"

    sdkInstance.getExperienceCloudId(sub(ctx, result)
        throw "should not be called"
    end sub, context)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    callbackInfo = sdkInstance._private.cachedCallbackInfo[event.uuid]

    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.GET_EXPERIENCE_CLOUD_ID)
    UTF_assertInvalid(event.data)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
    UTF_assertEqual(callbackInfo.context, context)
    UTF_AssertNotInvalid(callbackInfo.timestampInMillis)

    sleep(GetGlobalAA().TIMEOUT_MS)

    responseEvent = _adb_ResponseEvent(event.uuid, "testECID")
    GetGlobalAA()._adb_main_task_node["responseEvent"] = responseEvent
    try
        _adb_handleResponseEvent()
        UTF_assertFalse(sdkInstance._private.cachedCallbackInfo.DoesExist(event.uuid))
    catch e
        UTF_fail(e.message)
    end try

end sub

' target: createMediaSession()
' @Test
sub TC_APIs_createMediaSession()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    sessionId = sdkInstance._private.mediaSession.getClientSessionId()
    UTF_assertTrue(not _adb_isEmptyOrInvalidString(sessionId))
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.CREATE_MEDIA_SESSION)
    UTF_assertTrue(not _adb_isEmptyOrInvalidMap(event.data))
    UTF_assertEqual(event.data.clientSessionId, sessionId)
    UTF_assertTrue(not _adb_isEmptyOrInvalidMap(event.data.tsObject))

    UTF_assertEqual(event.data.xdmData, {
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    UTF_assertEqual({}, event.data.configuration)
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: createMediaSession()
' @Test
sub TC_APIs_createMediaSession_withConfiguration()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    }, {
        "config.channel": "channel_1"
    })
    sessionId = sdkInstance._private.mediaSession.getClientSessionId()
    UTF_assertTrue(not _adb_isEmptyOrInvalidString(sessionId))
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.CREATE_MEDIA_SESSION)
    UTF_assertTrue(not _adb_isEmptyOrInvalidMap(event.data))
    UTF_assertEqual(event.data.clientSessionId, sessionId)
    UTF_assertTrue(not _adb_isEmptyOrInvalidMap(event.data.tsObject))

    UTF_assertEqual(event.data.xdmData, {
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    UTF_assertEqual(event.data.configuration, {
        "config.channel": "channel_1"
    })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
end sub

' target: createMediaSession()
' @Test
sub TC_APIs_createMediaSession_invalidXDMData()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.start",

        }
    })
    UTF_assertTrue(_adb_isEmptyOrInvalidString(sdkInstance._private.mediaSession.getClientSessionId()))
    UTF_assertTrue(_adb_isEmptyOrInvalidMap(GetGlobalAA()._adb_main_task_node["requestEvent"]))

    sdkInstance.createMediaSession({
        "invalid_xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    UTF_assertTrue(_adb_isEmptyOrInvalidString(sdkInstance._private.mediaSession.getClientSessionId()))
    UTF_assertTrue(_adb_isEmptyOrInvalidMap(GetGlobalAA()._adb_main_task_node["requestEvent"]))

    sdkInstance.createMediaSession(invalid)
    UTF_assertTrue(_adb_isEmptyOrInvalidString(sdkInstance._private.mediaSession.getClientSessionId()))
    UTF_assertTrue(_adb_isEmptyOrInvalidMap(GetGlobalAA()._adb_main_task_node["requestEvent"]))
end sub

' target: createMediaSession()
' @Test
sub TC_APIs_createMediaSession_endPrevisouSession()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    sessionId = sdkInstance._private.mediaSession.getClientSessionId()
    UTF_assertTrue(not _adb_isEmptyOrInvalidString(sessionId))
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.data.clientSessionId, sessionId)

    sdkInstance._private.mediaSession.updateCurrentPlayhead(100)
    GetGlobalAA().xdmData = invalid
    sdkInstance.sendMediaEvent = sub(xdmData as object)
        GetGlobalAA().xdmData = xdmData
    end sub

    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })

    sessionId2 = sdkInstance._private.mediaSession.getClientSessionId()
    event2 = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertNotEqual(sessionId, sessionId2)
    UTF_assertEqual(event2.data.clientSessionId, sessionId2)

    ' GetGlobalAA().xdmData
    UTF_assertEqual(GetGlobalAA().xdmData, {
        "xdm": {
            "eventType": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 100,
            }
        }
    })

end sub

' target: sendMediaEvent()
' @Test
sub TC_APIs_sendMediaEvent()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    sessionId = sdkInstance._private.mediaSession.getClientSessionId()
    UTF_assertTrue(not _adb_isEmptyOrInvalidString(sessionId))

    sdkInstance.sendMediaEvent({
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10,
            }
        }
    })

    sessionId2 = sdkInstance._private.mediaSession.getClientSessionId()
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(sessionId, sessionId2)
    UTF_assertEqual(event.data.clientSessionId, sessionId)
    UTF_assertEqual(event.apiName, _internal_const.PUBLIC_API.SEND_MEDIA_EVENT)
    UTF_assertTrue(not _adb_isEmptyOrInvalidMap(event.data))
    UTF_assertTrue(not _adb_isEmptyOrInvalidMap(event.data.tsObject))
    UTF_assertEqual(event.data.xdmData, {
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10,
            }
        }
    })
    UTF_AssertNotInvalid(event.uuid)
    UTF_AssertNotInvalid(event.timestamp)
    UTF_assertEqual(10, sdkInstance._private.mediaSession.getCurrentPlayHead())

end sub

' target: sendMediaEvent()
' @Test
sub TC_APIs_sendMediaEvent_invalidXDMData()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    sessionId = sdkInstance._private.mediaSession.getClientSessionId()
    GetGlobalAA()._adb_main_task_node["requestEvent"] = {}
    sdkInstance.sendMediaEvent({
        "xdm": {
            "eventType": "media.invalid",
            "mediaCollection": {
                "playhead": 10,
            }
        }
    })

    sessionId2 = sdkInstance._private.mediaSession.getClientSessionId()
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(sessionId, sessionId2)
    UTF_assertTrue(_adb_isEmptyOrInvalidMap(event))
    UTF_assertEqual(0, sdkInstance._private.mediaSession.getCurrentPlayHead())

end sub

' target: sendMediaEvent()
' @Test
sub TC_APIs_sendMediaEvent_invalidSession()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    UTF_assertTrue(_adb_isEmptyOrInvalidString(sdkInstance._private.mediaSession.getClientSessionId()))

    sdkInstance.sendMediaEvent({
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10,
            }
        }
    })

    UTF_assertTrue(_adb_isEmptyOrInvalidString(sdkInstance._private.mediaSession.getClientSessionId()))
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertTrue(_adb_isEmptyOrInvalidMap(event))
    UTF_assertEqual(0, sdkInstance._private.mediaSession.getCurrentPlayHead())

end sub

' target: sendMediaEvent()
' @Test
sub TC_APIs_sendMediaEvent_sessionEnd()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.createMediaSession({
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",

        }
    })
    sessionId = sdkInstance._private.mediaSession.getClientSessionId()
    UTF_assertTrue(not _adb_isEmptyOrInvalidString(sessionId))

    sdkInstance.sendMediaEvent({
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10,
            }
        }
    })
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    UTF_assertEqual(event.data.clientSessionId, sessionId)
    UTF_assertEqual(10, sdkInstance._private.mediaSession.getCurrentPlayHead())

    sdkInstance.sendMediaEvent({
        "xdm": {
            "eventType": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 100,
            }
        }
    })
    UTF_assertEqual(0, sdkInstance._private.mediaSession.getCurrentPlayHead())
    UTF_assertFalse(sdkInstance._private.mediaSession.isActive())

end sub

' taget: _adb_ClientMediaSession()
' @Test
sub TC_adb_ClientMediaSession()
    session = _adb_ClientMediaSession()
    UTF_assertTrue(_adb_isEmptyOrInvalidString(session.getClientSessionId()))
    UTF_assertFalse(session.isActive())
    UTF_assertEqual(session.getCurrentPlayHead(), 0)

    'session start & get session id
    sessionId = session.startNewSession(-1)
    UTF_assertTrue(session.isActive())
    UTF_assertEqual(session.getClientSessionId(), sessionId)
    UTF_assertTrue(not _adb_isEmptyOrInvalidString(sessionId))
    UTF_assertTrue(sessionId.len() > 0)
    UTF_assertEqual(session.getCurrentPlayHead(), -1)

    ' update/get playhead
    session.updateCurrentPlayhead(100)
    UTF_assertEqual(session.getCurrentPlayHead(), 100)
    session.updateCurrentPlayhead(0)
    UTF_assertEqual(session.getCurrentPlayHead(), 0)
    session.updateCurrentPlayhead(-1)
    UTF_assertEqual(session.getCurrentPlayHead(), -1)

    'session end
    session.endSession()
    UTF_assertTrue(_adb_isEmptyOrInvalidString(session.getClientSessionId()))
end sub

' target: setConsent()
' @Test
sub TC_APIs_setConsent()
    _internal_const = _adb_InternalConstants()
    sdkInstance = AdobeAEPSDKInit()

    data = {
        "consent": [
            {
                "standard": "Adobe",
                "version": "2.0",
                "value": {
                    "collect": {
                        "val": "y"
                    },
                    "metadata": {
                        "time": "YYYY-03-17T15:48:42-07:00"
                    }
                }
            }
        ]
    }

    sdkInstance.setConsent(data)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]
    expectedData = {
       "consent": [
            {
                "standard": "Adobe",
                "version": "2.0",
                "value": {
                    "collect": {
                        "val": "y"
                    },
                    "metadata": {
                        "time": "YYYY-03-17T15:48:42-07:00"
                    }
                }
            }
        ]
    }

    UTF_assertEqual(event.apiName, "setConsent", generateErrorMessage("Api name", "setConsent", FormatJson(event.apiName)))
    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0, generateErrorMessage("Cached callback count", "0", FormatJson(sdkInstance._private.cachedCallbackInfo.Count())))
    UTF_assertEqual(event.data, expectedData, generateErrorMessage("event.data", FormatJson(expectedData), FormatJson(event.data)))
    UTF_AssertNotInvalid(event.uuid, generateErrorMessage("event.uuid", "not invalid", FormatJson(event.uuid)))
    UTF_AssertNotInvalid(event.timestamp, generateErrorMessage("event.timestamp", "not invalid", FormatJson(event.timestamp)))
end sub

' target: setConsent()
' @Test
sub TC_APIs_setConsent_invalid()
    sdkInstance = AdobeAEPSDKInit()
    sdkInstance.setConsent("invalid event data")
    event = GetGlobalAA()._adb_main_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count(), generateErrorMessage("Event count", "0", FormatJson(event.Count())))

    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0, generateErrorMessage("CachedCallback count", "0", FormatJson(sdkInstance._private.cachedCallbackInfo.Count())))
end sub

' target: setConsent()
' @Test
sub TC_APIs_setConsent_emptyConsentList()
    sdkInstance = AdobeAEPSDKInit()
    data = {
        "consents": []
    }

    sdkInstance.setConsent(data)

    event = GetGlobalAA()._adb_main_task_node["requestEvent"]

    UTF_assertEqual(0, event.Count(), generateErrorMessage("Event count", "0", FormatJson(event.Count())))

    UTF_assertEqual(sdkInstance._private.cachedCallbackInfo.Count(), 0, generateErrorMessage("CachedCallback count", "0", FormatJson(sdkInstance._private.cachedCallbackInfo.Count())))
end sub
