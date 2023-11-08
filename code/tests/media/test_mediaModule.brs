' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_MediaModule()
' @Test
sub TC_adb_MediaModule_init()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    UTF_assertInvalid(_adb_MediaModule(edgeRequestQueue, configurationModule))
    UTF_assertInvalid(_adb_MediaModule(configurationModule, invalid))
    UTF_assertInvalid(_adb_MediaModule(invalid, edgeRequestQueue))
    UTF_assertInvalid(_adb_MediaModule(invalid, invalid))

end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_startSession()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_startSession_is_called = false
    GetGlobalAA()._adb_trackEventForSession_is_called = false
    mediaModule._startSession = sub(clientSessionId as string, sessionConfig as object, xdmData as object, tsObject as object)
        GetGlobalAA()._adb_startSession_is_called = true
        UTF_assertEqual("client_session_id", clientSessionId)
        UTF_assertEqual(xdmData, {
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
        UTF_assertEqual(sessionConfig, { "config.channel": "channel_1" })
    end sub
    mediaModule._trackEventForSession = sub(requestId as string, clientSessionId as string, xdmData as object, tsObject as object)
        GetGlobalAA()._adb_trackEventForSession_is_called = true
    end sub

    mediaModule.processEvent("request_id", {
        clientSessionId: "client_session_id",
        tsObject: _adb_TimestampObject(),
        xdmData: {
            "xdm": {
                "mediaCollection": {
                    "sessionDetails": {
                        "name": "name"
                    },
                    "playhead": 0,
                },
                "eventType": "media.sessionStart",

            }
        },
        configuration: { "config.channel": "channel_1" }
    })
    UTF_assertTrue(GetGlobalAA()._adb_startSession_is_called)
    UTF_assertTrue(not GetGlobalAA()._adb_trackEventForSession_is_called)
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_trackEventForSession()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_startSession_is_called = false
    GetGlobalAA()._adb_trackEventForSession_is_called = false
    mediaModule._startSession = sub(clientSessionId as string, sessionConfig as object, xdmData as object, tsObject as object)
        GetGlobalAA()._adb_startSession_is_called = true
    end sub
    mediaModule._trackEventForSession = sub(requestId as string, clientSessionId as string, xdmData as object, tsObject as object)
        GetGlobalAA()._adb_trackEventForSession_is_called = true
        UTF_assertEqual("client_session_id", clientSessionId)
        UTF_assertEqual("request_id", requestId)
        UTF_assertEqual(xdmData, {
            "xdm": {
                "eventType": "media.ping",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        })
    end sub

    mediaModule.processEvent("request_id", {
        clientSessionId: "client_session_id",
        tsObject: _adb_TimestampObject(),
        xdmData: {
            "xdm": {
                "eventType": "media.ping",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        }
    })
    UTF_assertTrue(not GetGlobalAA()._adb_startSession_is_called)
    UTF_assertTrue(GetGlobalAA()._adb_trackEventForSession_is_called)
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_invalid()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_startSession_is_called = false
    GetGlobalAA()._adb_trackEventForSession_is_called = false
    mediaModule._startSession = sub(clientSessionId as string, sessionConfig as object, xdmData as object, tsObject as object)
        GetGlobalAA()._adb_startSession_is_called = true
    end sub
    mediaModule._trackEventForSession = sub(requestId as string, clientSessionId as string, xdmData as object, tsObject as object)
        GetGlobalAA()._adb_trackEventForSession_is_called = true
    end sub

    mediaModule.processEvent("request_id", {
        clientSessionId: "client_session_id",
        tsObject: _adb_TimestampObject(),
        xdmData: {
            "xdm": {
                "eventType": "media.invalid",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        }
    })
    UTF_assertFalse(GetGlobalAA()._adb_startSession_is_called)
    UTF_assertFalse(GetGlobalAA()._adb_trackEventForSession_is_called)

    mediaModule.processEvent("request_id", {
        clientSessionId: "client_session_id",
        tsObject: _adb_TimestampObject(),
        xdmData: {
            "xdm": {
                "eventType_invalid": "media.ping",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        }
    })
    UTF_assertFalse(GetGlobalAA()._adb_startSession_is_called)
    UTF_assertFalse(GetGlobalAA()._adb_trackEventForSession_is_called)
end sub


' target: _isMediaConfigReady()
' @Test
sub TC_isMediaConfigReady()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._configurationModule.getMediaChannel = function() as string
        return "channel_name"
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return "player_name"
    end function
    UTF_assertTrue(mediaModule._isMediaConfigReady())


    mediaModule._configurationModule.getMediaChannel = function() as string
        return ""
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return "player_name"
    end function
    UTF_assertFalse(mediaModule._isMediaConfigReady())

    mediaModule._configurationModule.getMediaChannel = function() as string
        return "channel_name"
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return ""
    end function
    UTF_assertFalse(mediaModule._isMediaConfigReady())
end sub

' target: _startSession()
' @Test
sub TC_adb_MediaModule_startSession_withoutSessionConfig()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._configurationModule.getMediaChannel = function() as string
        return "channel_name"
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return "player_name"
    end function
    mediaModule._configurationModule.getMediaAppVersion = function() as string
        return "1.0.0"
    end function
    GetGlobalAA()._adb_kickRequestQueue_is_called = false
    mediaModule._kickRequestQueue = sub()
        GetGlobalAA()._adb_kickRequestQueue_is_called = true
    end sub

    tsObj = _adb_TimestampObject()
    UTF_assertFalse(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    mediaModule._startSession("client_session_id", {}, {
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "abc": "abc"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",
        }
    }, tsObj)
    UTF_assertTrue(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    UTF_assertEqual(1, mediaModule._edgeRequestQueue._edgeRequestWorker._queue.count())
    UTF_assertEqual("client_session_id", mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["requestId"])
    UTF_assertEqual(1, mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["xdmEvents"].count())
    cachedXDMEvent = mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["xdmEvents"][0]
    UTF_assertEqual("media.sessionStart", cachedXDMEvent["xdm"]["eventType"])
    UTF_assertFalse(_adb_isEmptyOrInvalidString(cachedXDMEvent["xdm"]["_id"]))
    UTF_assertEqual(tsObj.tsInISO8601, cachedXDMEvent["xdm"]["timestamp"])
    UTF_assertEqual({
        "sessionDetails": {
            "playerName": "player_name",
            "channel": "channel_name",
            "appVersion": "1.0.0",
            "abc": "abc"
        },
        "playhead": 0,
    }, cachedXDMEvent["xdm"]["mediaCollection"])

    UTF_assertEqual(tsObj.tsInMillis, mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["timestampInMillis"])
    UTF_assertEqual("/ee/va/v1/sessionStart", mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["path"])
    UTF_assertTrue(GetGlobalAA()._adb_kickRequestQueue_is_called)
end sub

' target: _startSession()
' @Test
sub TC_adb_MediaModule_startSession_invalidConfig()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._configurationModule.getMediaChannel = function() as string
        return ""
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return "player_name"
    end function
    mediaModule._configurationModule.getMediaAppVersion = function() as string
        return "1.0.0"
    end function
    GetGlobalAA()._adb_kickRequestQueue_is_called = false
    mediaModule._kickRequestQueue = sub()
        GetGlobalAA()._adb_kickRequestQueue_is_called = true
    end sub

    tsObj = _adb_TimestampObject()
    UTF_assertFalse(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    mediaModule._startSession("client_session_id", {}, {
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "abc": "abc"
                },
                "playhead": 0,
            },
            "eventType": "media.sessionStart",
        }
    }, tsObj)
    UTF_assertFalse(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    UTF_assertEqual(0, mediaModule._edgeRequestQueue._edgeRequestWorker._queue.count())
    UTF_assertFalse(GetGlobalAA()._adb_kickRequestQueue_is_called)
end sub

' target: _trackEventForSession()
' @Test
sub TC_adb_MediaModule_trackEventForSession()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._sessionManager.createNewSession("client_session_id")
    mediaModule._sessionManager.updateSessionIdAndGetQueuedRequests("client_session_id", "backedn_session_id")
    GetGlobalAA()._adb_kickRequestQueue_is_called = false
    mediaModule._kickRequestQueue = sub()
        GetGlobalAA()._adb_kickRequestQueue_is_called = true
    end sub
    GetGlobalAA()._adb_processQueuedRequests_is_called = false
    mediaModule._processQueuedRequests = sub()
        GetGlobalAA()._adb_processQueuedRequests_is_called = true
    end sub

    UTF_assertTrue(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    tsObj = _adb_TimestampObject()
    mediaModule._trackEventForSession("request_id", "client_session_id", {
        "xdm": {
            "mediaCollection": {
                "playhead": 10,
            },
            "eventType": "media.ping",
        }
    }, tsObj)

    UTF_assertEqual(1, mediaModule._edgeRequestQueue._edgeRequestWorker._queue.count())
    UTF_assertEqual("request_id", mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["requestId"])
    UTF_assertEqual(1, mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["xdmEvents"].count())
    cachedXDMEvent = mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["xdmEvents"][0]
    UTF_assertEqual("media.ping", cachedXDMEvent["xdm"]["eventType"])
    UTF_assertFalse(_adb_isEmptyOrInvalidString(cachedXDMEvent["xdm"]["_id"]))
    UTF_assertEqual(tsObj.tsInISO8601, cachedXDMEvent["xdm"]["timestamp"])
    UTF_assertEqual({
        "playhead": 10,
        "sessionID": "backedn_session_id"
    }, cachedXDMEvent["xdm"]["mediaCollection"])

    UTF_assertEqual(tsObj.tsInMillis, mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["timestampInMillis"])
    UTF_assertEqual("/ee/va/v1/media.ping", mediaModule._edgeRequestQueue._edgeRequestWorker._queue[0]["path"])
    UTF_assertTrue(GetGlobalAA()._adb_kickRequestQueue_is_called)
    UTF_assertFalse(GetGlobalAA()._adb_processQueuedRequests_is_called)
end sub

' target: _trackEventForSession()
' @Test
sub TC_adb_MediaModule_trackEventForSession_sessionIdNotReady()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._sessionManager.createNewSession("client_session_id")
    GetGlobalAA()._adb_kickRequestQueue_is_called = false
    mediaModule._kickRequestQueue = sub()
        GetGlobalAA()._adb_kickRequestQueue_is_called = true
    end sub
    GetGlobalAA()._adb_processQueuedRequests_is_called = false
    mediaModule._processQueuedRequests = sub()
        GetGlobalAA()._adb_processQueuedRequests_is_called = true
    end sub

    UTF_assertTrue(_adb_isEmptyOrInvalidString(mediaModule._sessionManager.getSessionId("client_session_id")))
    UTF_assertTrue(mediaModule._sessionManager.isSessionStarted("client_session_id"))

    tsObj = _adb_TimestampObject()
    mediaModule._trackEventForSession("request_id", "client_session_id", {
        "xdm": {
            "mediaCollection": {
                "playhead": 10,
            },
            "eventType": "media.ping",
        }
    }, tsObj)

    UTF_assertEqual(1, mediaModule._sessionManager._map["client_session_id"].queue.count())
    queuedRequest = mediaModule._sessionManager._map["client_session_id"].queue[0]
    UTF_assertEqual("request_id", queuedRequest["requestId"])
    UTF_assertEqual({
        "xdm": {
            "mediaCollection": {
                "playhead": 10,
            },
            "eventType": "media.ping",
        }
    }, queuedRequest["xdmData"])
    UTF_assertEqual(tsObj, queuedRequest["tsObject"])
    UTF_assertEqual(0, mediaModule._edgeRequestQueue._edgeRequestWorker._queue.count())
    UTF_assertTrue(GetGlobalAA()._adb_kickRequestQueue_is_called)
    UTF_assertFalse(GetGlobalAA()._adb_processQueuedRequests_is_called)
end sub

' target: _trackEventForSession()
' @Test
sub TC_adb_MediaModule_trackEventForSession_sessionEnd()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._sessionManager.createNewSession("client_session_id")
    mediaModule._sessionManager.updateSessionIdAndGetQueuedRequests("client_session_id", "backedn_session_id")
    GetGlobalAA()._adb_kickRequestQueue_is_called = false
    mediaModule._kickRequestQueue = sub()
        GetGlobalAA()._adb_kickRequestQueue_is_called = true
    end sub
    GetGlobalAA()._adb_processQueuedRequests_is_called = false
    mediaModule._processQueuedRequests = sub()
        GetGlobalAA()._adb_processQueuedRequests_is_called = true
    end sub

    UTF_assertTrue(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    tsObj = _adb_TimestampObject()
    mediaModule._trackEventForSession("request_id", "client_session_id", {
        "xdm": {
            "mediaCollection": {
                "playhead": 100,
            },
            "eventType": "media.sessionEnd",
        }
    }, tsObj)

    UTF_assertEqual(1, mediaModule._edgeRequestQueue._edgeRequestWorker._queue.count())
    UTF_assertFalse(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    UTF_assertTrue(GetGlobalAA()._adb_kickRequestQueue_is_called)
    UTF_assertFalse(GetGlobalAA()._adb_processQueuedRequests_is_called)
end sub

' target: _trackEventForSession()
' @Test
sub TC_adb_MediaModule_trackEventForSession_sessionNotStarted()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    ' mediaModule._sessionManager.createNewSession("client_session_id")
    GetGlobalAA()._adb_kickRequestQueue_is_called = false
    mediaModule._kickRequestQueue = sub()
        GetGlobalAA()._adb_kickRequestQueue_is_called = true
    end sub
    GetGlobalAA()._adb_processQueuedRequests_is_called = false
    mediaModule._processQueuedRequests = sub()
        GetGlobalAA()._adb_processQueuedRequests_is_called = true
    end sub

    UTF_assertFalse(mediaModule._sessionManager.isSessionStarted("client_session_id"))

    tsObj = _adb_TimestampObject()
    mediaModule._trackEventForSession("request_id", "client_session_id", {
        "xdm": {
            "mediaCollection": {
                "playhead": 10,
            },
            "eventType": "media.ping",
        }
    }, tsObj)

    UTF_assertFalse(mediaModule._sessionManager.isSessionStarted("client_session_id"))
    UTF_assertFalse(GetGlobalAA()._adb_kickRequestQueue_is_called)
    UTF_assertFalse(GetGlobalAA()._adb_processQueuedRequests_is_called)
end sub


' target: _kickRequestQueue()
' @Test
sub TC_adb_MediaModule_kickRequestQueue()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._sessionManager.createNewSession("client_session_id")
    UTF_assertTrue(mediaModule._sessionManager.isSessionStarted("client_session_id"))

    GetGlobalAA()._adb_processRequests_is_called = false
    ' The sessionStart request returns 200 with several handle event
    edgeRequestQueue.processRequests = function() as object
        if GetGlobalAA()._adb_processRequests_is_called
            return []
        end if
        GetGlobalAA()._adb_processRequests_is_called = true
        responseArray = []
        responseArray.push(_adb_EdgeResponse("client_session_id", 200, FormatJson({
            "requestId": "client_session_id",
            "handle": [{
                    "payload": [
                        {
                            "sessionId": "bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f"
                        }
                    ],
                    "type": "media-analytics:new-session",
                    "eventIndex": 0
                }, {
                    "payload": [
                        {
                            "scope": "Target",
                            "hint": "34",
                            "ttlSeconds": 1800
                        },
                        {
                            "scope": "AAM",
                            "hint": "7",
                            "ttlSeconds": 1800
                        },
                        {
                            "scope": "EdgeNetwork",
                            "hint": "va6",
                            "ttlSeconds": 1800
                        }
                    ],
                    "type": "locationHint:result"
                }, {
                    "payload": [
                        {
                            "key": "kndctr_EA0C49475E8AE1870A494023_AdobeOrg_cluster",
                            "value": "va6",
                            "maxAge": 1800
                        },
                        {
                            "key": "kndctr_EA0C49475E8AE1870A494023_AdobeOrg_identity",
                            "value": "CiY0Mzg5NTEyNzMzNTUxMDc5MzgzMzU2MjU5NDY5MTY3Mzc3MTc2OFIOCJ-YppX6MBgBKgNWQTbwAZ-YppX6MA==",
                            "maxAge": 34128000
                        }
                    ],
                    "type": "state:store"
                }
            ]
        })))
        ' The other media events return 204 (no content) status code
        responseArray.push(_adb_EdgeResponse("request_id_2", 204, ""))
        responseArray.push(_adb_EdgeResponse("request_id_3", 204, ""))
        return responseArray
    end function

    mediaModule._kickRequestQueue()

    UTF_assertEqual("bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f", mediaModule._sessionManager.getSessionId("client_session_id"))
end sub

' target: _kickRequestQueue()
' @Test
sub TC_adb_MediaModule_kickRequestQueue_withQueuedMediaEvents()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    mediaModule._sessionManager.createNewSession("client_session_id")
    UTF_assertTrue(mediaModule._sessionManager.isSessionStarted("client_session_id"))

    tsObj1 = _adb_TimestampObject()
    tsObj2 = _adb_TimestampObject()
    tsObj3 = _adb_TimestampObject()
    mediaModule._sessionManager.queueMediaRequest("request_id_1", "client_session_id", { xdm: { "eventType": "media.ping" } }, tsObj1)
    mediaModule._sessionManager.queueMediaRequest("request_id_2", "client_session_id", { xdm: { "eventType": "media.play" } }, tsObj2)
    mediaModule._sessionManager.queueMediaRequest("request_id_3", "client_session_id", { xdm: { "eventType": "media.ping" } }, tsObj3)

    GetGlobalAA()._adb_processedMediaEvents = []
    mediaModule._handleMediaEvent = sub(mediaEventType as string, requestId as string, sessionId as string, xdmData as object, tsObject as object)
        list = GetGlobalAA()._adb_processedMediaEvents
        list.push({
            "mediaEventType": mediaEventType,
            "requestId": requestId,
            "sessionId": sessionId,
            "xdmData": xdmData,
            "tsObject": tsObject
        })
    end sub
    GetGlobalAA()._adb_processRequests_is_called = false
    ' The sessionStart request returns 200 with several handle events
    edgeRequestQueue.processRequests = function() as object
        if GetGlobalAA()._adb_processRequests_is_called
            return []
        end if
        GetGlobalAA()._adb_processRequests_is_called = true
        responseArray = []
        responseArray.push(_adb_EdgeResponse("client_session_id", 200, FormatJson({
            "requestId": "client_session_id",
            "handle": [{
                    "payload": [
                        {
                            "sessionId": "bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f"
                        }
                    ],
                    "type": "media-analytics:new-session",
                    "eventIndex": 0
                }, {
                    "payload": [
                        {
                            "scope": "Target",
                            "hint": "34",
                            "ttlSeconds": 1800
                        },
                        {
                            "scope": "AAM",
                            "hint": "7",
                            "ttlSeconds": 1800
                        },
                        {
                            "scope": "EdgeNetwork",
                            "hint": "va6",
                            "ttlSeconds": 1800
                        }
                    ],
                    "type": "locationHint:result"
                }, {
                    "payload": [
                        {
                            "key": "kndctr_EA0C49475E8AE1870A494023_AdobeOrg_cluster",
                            "value": "va6",
                            "maxAge": 1800
                        },
                        {
                            "key": "kndctr_EA0C49475E8AE1870A494023_AdobeOrg_identity",
                            "value": "CiY0Mzg5NTEyNzMzNTUxMDc5MzgzMzU2MjU5NDY5MTY3Mzc3MTc2OFIOCJ-YppX6MBgBKgNWQTbwAZ-YppX6MA==",
                            "maxAge": 34128000
                        }
                    ],
                    "type": "state:store"
                }
            ]
        })))
        ' The other media events return 204 (no content) status code
        responseArray.push(_adb_EdgeResponse("request_id_2", 204, ""))
        responseArray.push(_adb_EdgeResponse("request_id_3", 204, ""))
        return responseArray
    end function

    mediaModule._kickRequestQueue()

    UTF_assertEqual("bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f", mediaModule._sessionManager.getSessionId("client_session_id"))

    list = GetGlobalAA()._adb_processedMediaEvents
    UTF_assertEqual(3, list.count())

    UTF_assertEqual("media.ping", list[0]["mediaEventType"])
    UTF_assertEqual("media.play", list[1]["mediaEventType"])
    UTF_assertEqual("media.ping", list[2]["mediaEventType"])

    UTF_assertEqual("request_id_1", list[0]["requestId"])
    UTF_assertEqual("request_id_2", list[1]["requestId"])
    UTF_assertEqual("request_id_3", list[2]["requestId"])

    UTF_assertEqual("bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f", list[0]["sessionId"])
    UTF_assertEqual("bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f", list[1]["sessionId"])
    UTF_assertEqual("bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f", list[2]["sessionId"])

    UTF_assertEqual({ xdm: { "eventType": "media.ping" } }, list[0]["xdmData"])
    UTF_assertEqual({ xdm: { "eventType": "media.play" } }, list[1]["xdmData"])
    UTF_assertEqual({ xdm: { "eventType": "media.ping" } }, list[2]["xdmData"])

    UTF_assertEqual(tsObj1, list[0]["tsObject"])
    UTF_assertEqual(tsObj2, list[1]["tsObject"])
    UTF_assertEqual(tsObj3, list[2]["tsObject"])
end sub
