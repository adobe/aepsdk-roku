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
sub TC_adb_MediaModule_processEvent_sessionStart_validConfig_createsSessionAndQueuesEvent()
    ' setup
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration = {}
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "testChannel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "testPlayerName"

    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration(configuration)

    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    mediaSessionManager = _adb_MediaSessionManager()
    mediaModule._sessionManager = mediaSessionManager
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_sessionManager_createSession_called = false
    GetGlobalAA()._adb_sessionManager_endSession_called = false
    GetGlobalAA()._adb_sessionManager_queue_called = false

    testTSObject = {}
    testTSObject.tsInISO8601 = "testISOString"
    testTSObject.tsInMillis = 1234567890

    ' mock MediaSessionManager.createSession()
    mediaSessionManager.createSession = function(clientSessionId as string, configurationModule, sessionConfig, edgeRequestQueue) as void
        GetGlobalAA()._adb_sessionManager_createSession_called = true
        UTF_assertEqual(sessionConfig, { "config.channel": "testChannel" }, "Session configuration doesn't match")
        UTF_assertNotInvalid(edgeRequestQueue, "EdgeRequestQueue is invalid")
        UTF_assertNotInvalid(configurationModule, "ConfigurationModule is invalid")
    end function

    ' mock MediaSessionManager.endSession()
    mediaSessionManager.endSession = function() as void
        GetGlobalAA()._adb_sessionManager_endSession_called = true
    end function

    ' mock MediaSessionManager.queue()
    mediaSessionManager.queue = function(mediaHit as object) as void
        GetGlobalAA()._adb_sessionManager_queue_called = true

        UTF_assertEqual(mediaHit.xdmData, {
            "xdm": {
                "mediaCollection": {
                    "sessionDetails": {
                        "name": "name"
                    },
                    "playhead": 0
                },
                "eventType": "media.sessionStart",

            }
        })

        UTF_assertEqual(mediaHit.tsObject.tsInISO8601, "testISOString")
        UTF_assertEqual(mediaHit.tsObject.tsInMillis, 1234567890)
        UTF_assertEqual(mediaHit.requestId, "testRequestid")
    end function

    ' test
    eventData = {}
    eventData.xdmData = {
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0
            },
            "eventType": "media.sessionStart",

        }
    }
    eventData.tsObject = testTSObject
    eventData.clientSessionId = "testClientSessionId"
    eventData.configuration = { "config.channel": "testChannel" }

    mediaModule.processEvent("testRequestid", eventData)

    ' verify
    UTF_assertTrue(GetGlobalAA()._adb_sessionManager_createSession_called, "MediaSessionManager::createSession() was not called.")
    UTF_assertTrue(GetGlobalAA()._adb_sessionManager_queue_called, "MediaSessionManager::queue() was not called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_endSession_called, "MediaSessionManager::endSession() was called.")
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_sessionStart_InvalidConfig_ignoresEvent()
    ' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    mediaSessionManager = _adb_MediaSessionManager()
    mediaModule._sessionManager = mediaSessionManager
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_sessionManager_createSession_called = false
    GetGlobalAA()._adb_sessionManager_endSession_called = false
    GetGlobalAA()._adb_sessionManager_queue_called = false

    testTSObject = {}
    testTSObject.tsInISO8601 = "testISOString"
    testTSObject.tsInMillis = 1234567890

    ' mock MediaSessionManager.createSession()
    mediaSessionManager.createSession = function(_clientSessionId, _configurationModule, _sessionConfig, _edgeRequestQueue) as void
        GetGlobalAA()._adb_sessionManager_createSession_called = true
    end function

    ' mock MediaSessionManager.endSession()
    mediaSessionManager.endSession = function() as void
        GetGlobalAA()._adb_sessionManager_endSession_called = true
    end function

    ' mock MediaSessionManager.queue()
    mediaSessionManager.queue = function(_mediaHit as object) as void
        GetGlobalAA()._adb_sessionManager_queue_called = true
    end function

    ' test
    eventData = {}
    eventData.xdmData = {
        "xdm": {
            "mediaCollection": {
                "sessionDetails": {
                    "name": "name"
                },
                "playhead": 0
            },
            "eventType": "media.sessionStart",

        }
    }
    eventData.tsObject = testTSObject
    eventData.configuration = { "config.channel": "testChannel" }
    eventData.clientSessionId = "testClientSessionId"

    mediaModule.processEvent("testRequestid", eventData)

    ' verify
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_createSession_called, "MediaSessionManager::createSession() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_queue_called, "MediaSessionManager::queue() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_endSession_called, "MediaSessionManager::endSession() was called.")
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_MediaEventOtherThanSessionStart_validConfig_queuesEvent()
    ' setup
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration = {}
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "testChannel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "testPlayerName"

    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration(configuration)

    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    mediaSessionManager = _adb_MediaSessionManager()
    mediaModule._sessionManager = mediaSessionManager
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_sessionManager_createSession_called = false
    GetGlobalAA()._adb_sessionManager_endSession_called = false
    GetGlobalAA()._adb_sessionManager_queue_called = false

    testTSObject = {}
    testTSObject.tsInISO8601 = "testISOString"
    testTSObject.tsInMillis = 1234567890

    ' mock MediaSessionManager.createSession()
    mediaSessionManager.createSession = function(_clientSessionId, _configurationModule, _sessionConfig, _edgeRequestQueue) as void
        GetGlobalAA()._adb_sessionManager_createSession_called = true
    end function

    ' mock MediaSessionManager.endSession()
    mediaSessionManager.endSession = function() as void
        GetGlobalAA()._adb_sessionManager_endSession_called = true
    end function

    ' mock MediaSessionManager.queue()
    mediaSessionManager.queue = function(mediaHit as object) as void
        GetGlobalAA()._adb_sessionManager_queue_called = true

        UTF_assertEqual(mediaHit.xdmData, {
            "xdm": {
                "mediaCollection": {
                    "playhead": 10
                },
                "eventType": "media.play",

            }
        })

        UTF_assertEqual(mediaHit.tsObject.tsInISO8601, "testISOString")
        UTF_assertEqual(mediaHit.tsObject.tsInMillis, 1234567890)
        UTF_assertEqual(mediaHit.requestId, "testRequestid")
    end function

    ' mock MediaSessionManager.getActiveClientSessionId()
    mediaSessionManager.getActiveClientSessionId = function() as string
        return "active_session_id"
    end function


    ' test
    eventData = {}
    eventData.xdmData = {
        "xdm": {
            "mediaCollection": {
                "playhead": 10
            },
            "eventType": "media.play",

        }
    }
    eventData.tsObject = testTSObject
    eventData.configuration = { "config.channel": "testChannel" }
    eventData.clientSessionId = "active_session_id"

    mediaModule.processEvent("testRequestid", eventData)

    ' verify
    UTF_assertTrue(GetGlobalAA()._adb_sessionManager_queue_called, "MediaSessionManager::queue() was not called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_createSession_called, "MediaSessionManager::createSession() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_endSession_called, "MediaSessionManager::endSession() was called.")
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_SessionComplete_validConfig_queuesEventAndEndsSession()
    ' setup
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration = {}
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "testChannel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "testPlayerName"

    configurationModule = _adb_ConfigurationModule()
    configurationModule.updateConfiguration(configuration)

    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    mediaSessionManager = _adb_MediaSessionManager()
    mediaModule._sessionManager = mediaSessionManager
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_sessionManager_createSession_called = false
    GetGlobalAA()._adb_sessionManager_endSession_called = false
    GetGlobalAA()._adb_sessionManager_queue_called = false

    testTSObject = {}
    testTSObject.tsInISO8601 = "testISOString"
    testTSObject.tsInMillis = 1234567890

    ' mock MediaSessionManager.createSession()
    mediaSessionManager.createSession = function(_clientSessionId, _configurationModule, _sessionConfig, _edgeRequestQueue) as void
        GetGlobalAA()._adb_sessionManager_createSession_called = true
    end function

    ' mock MediaSessionManager.endSession()
    mediaSessionManager.endSession = function() as void
        GetGlobalAA()._adb_sessionManager_endSession_called = true

    end function

    ' mock MediaSessionManager.queue()
    mediaSessionManager.queue = function(mediaHit as object) as void
        GetGlobalAA()._adb_sessionManager_queue_called = true

        UTF_assertEqual(mediaHit.xdmData, {
            "xdm": {
                "mediaCollection": {
                    "playhead": 10
                },
                "eventType": "media.sessionComplete",

            }
        })

        UTF_assertEqual(mediaHit.tsObject.tsInISO8601, "testISOString")
        UTF_assertEqual(mediaHit.tsObject.tsInMillis, 1234567890)
        UTF_assertEqual(mediaHit.requestId, "testRequestid")
    end function
    ' mock MediaSessionManager.getActiveClientSessionId()
    mediaSessionManager.getActiveClientSessionId = function() as string
        return "active_session_id"
    end function

    ' test
    eventData = {}
    eventData.xdmData = {
        "xdm": {
            "mediaCollection": {
                "playhead": 10
            },
            "eventType": "media.sessionComplete",

        }
    }
    eventData.tsObject = testTSObject
    eventData.configuration = { "config.channel": "testChannel" }
    eventData.clientSessionId = "active_session_id"

    mediaModule.processEvent("testRequestid", eventData)

    ' verify
    UTF_assertTrue(GetGlobalAA()._adb_sessionManager_queue_called, "MediaSessionManager::queue() was not called.")
    UTF_assertTrue(GetGlobalAA()._adb_sessionManager_endSession_called, "MediaSessionManager::endSession() was not called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_createSession_called, "MediaSessionManager::createSession() was called.")
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_invalidMediaEvent_ignoresEvent()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    mediaSessionManager = _adb_MediaSessionManager()
    mediaModule._sessionManager = mediaSessionManager
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_sessionManager_createSession_called = false
    GetGlobalAA()._adb_sessionManager_endSession_called = false
    GetGlobalAA()._adb_sessionManager_queue_called = false

    ' mock MediaSessionManager.createSession()
    mediaSessionManager.createSession = function(_clientSessionId, _configurationModule, _sessionConfig, _edgeRequestQueue) as void
        GetGlobalAA()._adb_sessionManager_createSession_called = true
    end function

    ' mock MediaSessionManager.endSession()
    mediaSessionManager.endSession = function() as void
        GetGlobalAA()._adb_sessionManager_endSession_called = true
    end function

    ' mock MediaSessionManager.queue()
    mediaSessionManager.queue = function(_mediaHit as object) as void
        GetGlobalAA()._adb_sessionManager_queue_called = true
    end function

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

    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_queue_called, "MediaSessionManager::queue() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_endSession_called, "MediaSessionManager::endSession() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_createSession_called, "MediaSessionManager::createSession() was called.")
end sub

' target: processEvent()
' @Test
sub TC_adb_MediaModule_processEvent_invalidMediaEvent_inactiveSession()
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    mediaModule = _adb_MediaModule(configurationModule, edgeRequestQueue)
    mediaSessionManager = _adb_MediaSessionManager()
    mediaModule._sessionManager = mediaSessionManager
    UTF_assertTrue(_adb_isMediaModule(mediaModule))

    GetGlobalAA()._adb_sessionManager_createSession_called = false
    GetGlobalAA()._adb_sessionManager_endSession_called = false
    GetGlobalAA()._adb_sessionManager_queue_called = false

    ' mock MediaSessionManager.createSession()
    mediaSessionManager.createSession = function(_clientSessionId, _configurationModule, _sessionConfig, _edgeRequestQueue) as void
        GetGlobalAA()._adb_sessionManager_createSession_called = true
    end function

    ' mock MediaSessionManager.endSession()
    mediaSessionManager.endSession = function() as void
        GetGlobalAA()._adb_sessionManager_endSession_called = true
    end function

    ' mock MediaSessionManager.queue()
    mediaSessionManager.queue = function(_mediaHit as object) as void
        GetGlobalAA()._adb_sessionManager_queue_called = true
    end function

    ' mock MediaSessionManager.getActiveClientSessionId()
    mediaSessionManager.getActiveClientSessionId = function() as string
        return "active_session_id"
    end function

    ' handle the media event with a different clientSessionId
    mediaModule.processEvent("request_id", {
        clientSessionId: "new_session_id",
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

    ' the media module should dropt this event
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_queue_called, "MediaSessionManager::queue() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_endSession_called, "MediaSessionManager::endSession() was called.")
    UTF_assertFalse(GetGlobalAA()._adb_sessionManager_createSession_called, "MediaSessionManager::createSession() was called.")
end sub

' target: _hasValidConfig()
' @Test
sub TC_hasValidConfig()
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
    UTF_assertTrue(mediaModule._hasValidConfig())


    mediaModule._configurationModule.getMediaChannel = function() as string
        return ""
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return "player_name"
    end function
    UTF_assertFalse(mediaModule._hasValidConfig())

    mediaModule._configurationModule.getMediaChannel = function() as string
        return "channel_name"
    end function
    mediaModule._configurationModule.getMediaPlayerName = function() as string
        return ""
    end function
    UTF_assertFalse(mediaModule._hasValidConfig())
end sub
