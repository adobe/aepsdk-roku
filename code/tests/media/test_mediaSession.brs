' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_MediaSession()
' @Test
sub TC_adb_MediaSession_init()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    configuration = {}
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "test_channel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "test_playerName"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = "test_appVersion"

    configurationModule.updateConfiguration(configuration)

    ''' test
    sessionConfig = { "config.channel": "test_channel_session" }
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    UTF_assertNotInvalid(mediaSession)
    UTF_assertTrue(mediaSession._isActive)
    UTF_assertEqual("testId", mediaSession._clientSessionId)
    UTF_assertNotInvalid(mediaSession._configurationModule)
    UTF_assertNotInvalid(mediaSession._edgeRequestQueue)
    UTF_assertEqual("test_channel_session", mediaSession._sessionChannelName)
    UTF_assertEqual("test_appVersion", mediaSession._getAppVersion())
    UTF_assertEqual("test_playerName", mediaSession._getPlayerName())
    UTF_assertEqual("test_channel_session", mediaSession._getChannelName())
    isAd = true
    DEFAULT_PING_INTERVAL_SEC = 10
    UTF_assertEqual(DEFAULT_PING_INTERVAL_SEC, mediaSession._getPingInterval(isAd))
    UTF_assertEqual(DEFAULT_PING_INTERVAL_SEC, mediaSession._getPingInterval(not isAd))
end sub

' target: _adb_MediaSession()
' @Test
sub TC_adb_MediaSession_init_withoutSessionConfig()
    ''' setup
    configurationModule = _adb_ConfigurationModule()

    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    configuration = {}
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "test_channel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "test_playerName"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = "test_appVersion"

    configurationModule.updateConfiguration(configuration)

    ''' test
    sessionConfig = {}
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    UTF_assertNotInvalid(mediaSession)
    UTF_assertTrue(mediaSession._isActive)
    UTF_assertEqual("testId", mediaSession._clientSessionId)
    UTF_assertNotInvalid(mediaSession._configurationModule)
    UTF_assertNotInvalid(mediaSession._edgeRequestQueue)
    UTF_assertInvalid(mediaSession._sessionChannelName)
    UTF_assertEqual("test_appVersion", mediaSession._getAppVersion())
    UTF_assertEqual("test_playerName", mediaSession._getPlayerName())
    UTF_assertEqual("test_channel", mediaSession._getChannelName())
    isAd = true
    DEFAULT_PING_INTERVAL_SEC = 10
    UTF_assertEqual(DEFAULT_PING_INTERVAL_SEC, mediaSession._getPingInterval(isAd))
    UTF_assertEqual(DEFAULT_PING_INTERVAL_SEC, mediaSession._getPingInterval(not isAd))
end sub

' target: _adb_MediaSession()
' @Test
sub TC_adb_MediaSession_init_withFullSessionConfig()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    configuration = {}
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "test_channel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "test_playerName"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = "test_appVersion"

    configurationModule.updateConfiguration(configuration)

    sessionConfig = {
        "config.channel": "test_channel_session",
        "config.adpinginterval": 5,
        "config.mainpinginterval": 35,
    }

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    UTF_assertNotInvalid(mediaSession)
    UTF_assertTrue(mediaSession._isActive)
    UTF_assertEqual("testId", mediaSession._clientSessionId)
    UTF_assertNotInvalid(mediaSession._configurationModule)
    UTF_assertNotInvalid(mediaSession._edgeRequestQueue)
    UTF_assertEqual("test_channel_session", mediaSession._sessionChannelName)
    UTF_assertEqual("test_appVersion", mediaSession._getAppVersion())
    UTF_assertEqual("test_playerName", mediaSession._getPlayerName())
    UTF_assertEqual("test_channel_session", mediaSession._getChannelName())
    isAd = true
    UTF_assertEqual(5, mediaSession._getPingInterval(isAd))
    UTF_assertEqual(35, mediaSession._getPingInterval(not isAd))
end sub

' target: process()
' @Test
sub TC_adb_MediaSession_process_notActiveSession()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
    mediaSession._isActive = false

    ''' mock session functions
    GetGlobalAA()._test_media_session_restartIdleSession_called = false
    mediaSession._restartIdleSession = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_restartIdleSession_called = true
    end function

    GetGlobalAA()._test_media_session_restartIfLongRunningSession_called = false
    mediaSession._restartIfLongRunningSession = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_restartIfLongRunningSession_called = true
    end function

    GetGlobalAA()._test_media_session_updatePlaybackState_called = false
    mediaSession._updatePlaybackState = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_updatePlaybackState_called = true
    end function

    GetGlobalAA()._test_media_session_updateAdState_called = false
    mediaSession._updateAdState = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_updateAdState_called = true
    end function

    GetGlobalAA()._test_media_session_extractSessionStartData_called = false
    mediaSession._extractSessionStartData = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_extractSessionStartData_called = true
    end function

    GetGlobalAA()._test_media_session_closeIfIdle_called = false
    mediaSession._closeIfIdle = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_closeIfIdle_called = true
    end function

    GetGlobalAA()._test_media_session_restartIfLongRunningSession_called = false
    mediaSession._restartIfLongRunningSession = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_restartIfLongRunningSession_called = true
    end function

    GetGlobalAA()._test_media_session_shouldQueue_called = false
    mediaSession._shouldQueue = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_shouldQueue_called = true
    end function

    GetGlobalAA()._test_media_session_queue_called = false
    mediaSession._queue = function(_mediaHit as object) as void
        GetGlobalAA()._test_media_session_queue_called = true
    end function

    ''' test
    mediaSession.process(sessionStartHit)

    ''' verify
    UTF_assertTrue(GetGlobalAA()._test_media_session_restartIdleSession_called)

    UTF_assertFalse(GetGlobalAA()._test_media_session_updatePlaybackState_called)
    UTF_assertFalse(GetGlobalAA()._test_media_session_updateAdState_called)
    UTF_assertFalse(GetGlobalAA()._test_media_session_extractSessionStartData_called)
    UTF_assertFalse(GetGlobalAA()._test_media_session_closeIfIdle_called)
    UTF_assertFalse(GetGlobalAA()._test_media_session_restartIfLongRunningSession_called)
    UTF_assertFalse(GetGlobalAA()._test_media_session_shouldQueue_called)
    UTF_assertFalse(GetGlobalAA()._test_media_session_queue_called)
end sub

' target: process()
' @Test
sub TC_adb_MediaSession_process_activeSession_sessionStartHit_queued()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function

    ''' test
    UTF_assertInvalid(mediaSession._sessionStartHit)
    mediaSession.process(sessionStartHit)

    ''' verify
    UTF_assertEqual(1, GetGlobalAA()._test_media_session_hits.count())
    hit = GetGlobalAA()._test_media_session_hits[0]
    UTF_assertEqual(sessionStartHit, hit)
    UTF_assertNotInvalid(mediaSession._sessionStartHit)
    UTF_assertEqual(sessionStartHit, mediaSession._sessionStartHit)
    UTF_assertFalse(mediaSession._isPlaying)
end sub

' target: process()
' @Test
sub TC_adb_MediaSession_process_activeSession_playbackHits_queued()
    ''' setup
    playHit = {}
    playHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    playHit.eventType = "media.play"
    playHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    playHit.requestId = "playRequestId"

    pauseHit = {}
    pauseHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    pauseHit.eventType = "media.pauseStart"
    pauseHit.xdmData = {
        "xdm": {
            "eventType": "media.pauseStart",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    pauseHit.requestId = "pauseRequestId"


    bufferHit = {}
    bufferHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    bufferHit.eventType = "media.bufferStart"
    bufferHit.xdmData = {
        "xdm": {
            "eventType": "media.bufferStart",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }
    bufferHit.requestId = "bufferRequestId"

    pingHit1 = {}
    pingHit1.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    pingHit1.eventType = "media.ping"
    pingHit1.xdmData = {
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }
    pingHit1.requestId = "pingRequestId1"

    pingHit2 = {}
    pingHit2.tsObject = {
        "tsInMillis": 10001,
        "tsInISO8601": "10001"
    }
    pingHit2.eventType = "media.ping"
    pingHit2.xdmData = {
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 11
            }
        }
    }
    pingHit2.requestId = "pingRequestId2"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)

    ''' mock _tryDispatchMediaEvents()
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = 0
    mediaSession.tryDispatchMediaEvents = function() as void
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count + 1
    end function

    ''' default playback state
    UTF_assertFalse(mediaSession._isPlaying)

    ''' test and verify
    ''' play
    mediaSession.process(playHit)
    UTF_assertTrue(mediaSession._isPlaying, "Play should set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "Play should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Play should not set _isIdle")
    UTF_assertFalse(mediaSession._isInAd, "Play should not set _isInAd")

    ''' pause
    mediaSession.process(pauseHit)
    UTF_assertFalse(mediaSession._isPlaying, "pauseStart should reset _isPlaying")
    UTF_assertEqual(0, mediaSession._idleStartTS, "pauseStart should set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "pauseStart should not set _isIdle")
    UTF_assertFalse(mediaSession._isInAd, "pauseStart should not set _isInAd")

    ''' play
    mediaSession.process(playHit)
    UTF_assertTrue(mediaSession._isPlaying, "Play should set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "Play should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Play should not set _isIdle")
    UTF_assertFalse(mediaSession._isInAd, "Play should not set _isInAd")

    ''' buffer
    mediaSession.process(bufferHit)
    UTF_assertFalse(mediaSession._isPlaying, "Buffer should reset _isPlaying")
    UTF_assertEqual(0, mediaSession._idleStartTS, "Buffer should set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Buffer should not set _isIdle")
    UTF_assertFalse(mediaSession._isInAd, "Buffer should not set _isInAd")

    ''' ping 1 (should not be queued)
    mediaSession.process(pingHit1)
    UTF_assertFalse(mediaSession._isPlaying, "Ping should not set _isPlaying")
    UTF_assertEqual(0, mediaSession._idleStartTS, "Ping should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Ping should not set _isIdle")
    UTF_assertFalse(mediaSession._isInAd, "Ping should not set _isInAd")

    ''' ping 2 (should be queued since > default ping interval 10sec)
    mediaSession.process(pingHit2)
    UTF_assertFalse(mediaSession._isPlaying, "Ping should not set _isPlaying")
    UTF_assertEqual(0, mediaSession._idleStartTS, "Ping should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Ping should not set _isIdle")
    UTF_assertFalse(mediaSession._isInAd, "Ping should not set _isInAd")

    UTF_assertEqual(5, GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count, "tryDispatchMediaEvents() should be called 5 times")
    UTF_assertEqual(5, mediaSession.getHitQueueSize(), "hitQueue should have 5 hits")
    hits = mediaSession._hitQueue
    UTF_assertEqual(playHit, hits[0])
    UTF_assertEqual(pauseHit, hits[1])
    UTF_assertEqual(playHit, hits[2])
    UTF_assertEqual(bufferHit, hits[3])
    UTF_assertEqual(pingHit2, hits[4])
end sub

' target: process()
' @Test
sub TC_adb_MediaSession_process_activeSession_adHits_queued()
    ''' setup
    playHit = {}
    playHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    playHit.eventType = "media.play"
    playHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    playHit.requestId = "playRequestId"

    adStartHit = {}
    adStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    adStartHit.eventType = "media.adStart"
    adStartHit.xdmData = {
        "xdm": {
            "eventType": "media.adStart",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }
    adStartHit.requestId = "adRequestId"


    adCompleteHit = {}
    adCompleteHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    adCompleteHit.eventType = "media.adComplete"
    adCompleteHit.xdmData = {
        "xdm": {
            "eventType": "media.adComplete",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }
    adCompleteHit.requestId = "adCompleteRequestId"

    adSkipHit = {}
    adSkipHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    adSkipHit.eventType = "media.adSkip"
    adSkipHit.xdmData = {
        "xdm": {
            "eventType": "media.adSkip",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }
    adSkipHit.requestId = "adSkipRequestId"


    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)

    ''' mock _tryDispatchMediaEvents()
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = 0
    mediaSession.tryDispatchMediaEvents = function() as void
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count + 1
    end function

    ''' default playback state
    UTF_assertFalse(mediaSession._isPlaying)

    ''' test and verify
    ''' play
    mediaSession.process(playHit)
    UTF_assertTrue(mediaSession._isPlaying, "Play should set _isPlaying")
    UTF_assertFalse(mediaSession._isInAd, "Play should not set _isInAd")
    UTF_assertInvalid(mediaSession._idleStartTS, "Play should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Play should not set _isIdle")

    ''' adStart
    mediaSession.process(adStartHit)
    UTF_assertTrue(mediaSession._isPlaying, "adStart should not reset _isPlaying")
    UTF_assertTrue(mediaSession._isInAd, "adStart should set _isInAd")
    UTF_assertInvalid(mediaSession._idleStartTS, "adStart should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "adStart should not set _isIdle")

    ''' adComplete
    mediaSession.process(adCompleteHit)
    UTF_assertTrue(mediaSession._isPlaying, "adComplete should not reset _isPlaying")
    UTF_assertFalse(mediaSession._isInAd, "adComplete should reset _isInAd")
    UTF_assertInvalid(mediaSession._idleStartTS, "adComplete should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "adComplete should not set _isIdle")

    ''' adStart
    mediaSession.process(adStartHit)
    UTF_assertTrue(mediaSession._isPlaying, "adStart should not reset _isPlaying")
    UTF_assertTrue(mediaSession._isInAd, "adStart should set _isInAd")

    ''' adComplete
    mediaSession.process(adSkipHit)
    UTF_assertTrue(mediaSession._isPlaying, "adSkip should not reset _isPlaying")
    UTF_assertFalse(mediaSession._isInAd, "adSkip should reset _isInAd")
    UTF_assertInvalid(mediaSession._idleStartTS, "adSkip should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "adSkip should not set _isIdle")

    UTF_assertEqual(5, GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count)
    UTF_assertEqual(5, mediaSession.getHitQueueSize(), "hitQueue should have 5 hits")
    hits = mediaSession._hitQueue
    UTF_assertEqual(playHit, hits[0])
    UTF_assertEqual(adStartHit, hits[1])
    UTF_assertEqual(adCompleteHit, hits[2])
    UTF_assertEqual(adStartHit, hits[3])
    UTF_assertEqual(adSkipHit, hits[4])
end sub

' target: process()
' @Test
sub TC_adb_MediaSession_process_activeSession_idleTimeout_queued()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"

    playHit = {}
    playHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    playHit.eventType = "media.play"
    playHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    playHit.requestId = "playRequestId"

    pauseHit = {}
    pauseHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    pauseHit.eventType = "media.pauseStart"
    pauseHit.xdmData = {
        "xdm": {
            "eventType": "media.pauseStart",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }

    pingHit1 = {}
    pingHit1.tsObject = {
        "tsInMillis": (30 * 60 * 1000 + 1),
        "tsInISO8601": "1800001"
    }
    pingHit1.eventType = "media.ping"
    pingHit1.xdmData = {
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 1800
            }
        }
    }
    pingHit1.requestId = "pingRequestId1"

    autoGeneratedSessionEndHit = {}
    autoGeneratedSessionEndHit.tsObject = {
        "tsInMillis": (30 * 60 * 1000 + 1),
        "tsInISO8601": "1800001"
    }
    autoGeneratedSessionEndHit.eventType = "media.sessionEnd"
    autoGeneratedSessionEndHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionEnd",
            "timestamp": "1800001",
            "mediaCollection": {
                "playhead": 1800
            }
        }
    }

    restartIdlePlayHit = {}
    restartIdlePlayHit.tsObject = {
        "tsInMillis": (30 * 60 * 1000 + 2),
        "tsInISO8601": "1800002"
    }
    restartIdlePlayHit.eventType = "media.play"
    restartIdlePlayHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 1800
            }
        }
    }

    autoGeneratedSessionStartHit = {}
    autoGeneratedSessionStartHit.tsObject = {
        "tsInMillis": (30 * 60 * 1000 + 2),
        "tsInISO8601": "1800002"
    }
    autoGeneratedSessionStartHit.eventType = "media.sessionStart"
    autoGeneratedSessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "timestamp": "1800002",
            "mediaCollection": {
                "playhead": 1800,
                "sessionDetails": {
                    "streamType": "vod",
                    "hasResume": true,
                    "contentType": "video"
                }
            }
        }
    }

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)

    ''' mock _tryDispatchMediaEvents()
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = 0
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_idleSession_hits = []
    mediaSession.tryDispatchMediaEvents = function() as void
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count + 1
        ''' to test session hits before idleTimeout
        ''' expecting 4 events with auto sessionEnd
        if GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count <> 4 then
            return
        end if
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_idleSession_hits = m._hitQueue
    end function

    ''' default playback state
    UTF_assertFalse(mediaSession._isPlaying)

    ''' test and verify
    ''' sessionStart
    mediaSession.process(sessionStartHit)
    UTF_assertFalse(mediaSession._isPlaying, "sessionStart should not set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "sessionStart should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "sessionStart should not set _isIdle")

    ''' play
    mediaSession.process(playHit)
    UTF_assertTrue(mediaSession._isPlaying, "Play should set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "Play should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Play should not set _isIdle")

    ''' pause
    mediaSession.process(pauseHit)
    UTF_assertFalse(mediaSession._isPlaying, "pauseStart should reset _isPlaying")
    UTF_assertEqual(0, mediaSession._idleStartTS, "pauseStart should set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "pauseStart should not set _isIdle")

    ''' ping 1 (should trigger idleTimeout)
    mediaSession.process(pingHit1)
    UTF_assertFalse(mediaSession._isPlaying, "ping should not set _isPlaying")
    UTF_assertEqual(0, mediaSession._idleStartTS, "ping should not update _idleStartTS")
    UTF_assertTrue(mediaSession._isIdle, "ping should set _isIdle, since idle timeout is 30min")

    ''' autoGeneratedSessionEndHit (should be queued since idleTimeout)

    UTF_assertEqual(4, GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count)
    idleSessionHits = GetGlobalAA()._test_media_session_tryDispatchMediaEvents_idleSession_hits
    UTF_assertEqual(4, idleSessionHits.count(), "hitQueue should have 2 hits but has:" + StrI(idleSessionHits.count()))

    UTF_assertEqual(sessionStartHit, idleSessionHits[0])
    UTF_assertEqual(playHit, idleSessionHits[1])
    UTF_assertEqual(pauseHit, idleSessionHits[2])
    ''' drop the pingHit1 since it triggered idleTimeout
    UTF_assertEqual(autoGeneratedSessionEndHit.xdmData, idleSessionHits[3].xdmData, "sessionEnd data (" + FormatJson(idleSessionHits[3].xdmData) + ") should have expected xdmData:(" + FormatJson(autoGeneratedSessionEndHit.xdmData) + ")") ''' generated by _closeIfIdle() -> _createSessionEndHit()
    UTF_assertEqual(autoGeneratedSessionEndHit.tsObject, idleSessionHits[3].tsObject, "sessionEnd should have expected tsObject") ''' generated by _closeIfIdle() -> _createSessionEndHit()
    UTF_assertEqual(autoGeneratedSessionEndHit.eventType, idleSessionHits[3].eventType, "sessionEnd should have expected eventType") ''' generated by _closeIfIdle() -> _createSessionEndHit()
    UTF_assertFalse(mediaSession._isActive, "session should be inactive after idleTimeout") ''' closed by _closeIfIdle()

    ''' reset count for idleRestart scenario
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = 0

    ''' play (should restart idle session) and autogenerate sessionStart
    mediaSession.process(restartIdlePlayHit)
    UTF_assertTrue(mediaSession._isActive, "session should be active after idle restart") ''' activated by _restartIdleSession()
    UTF_assertTrue(mediaSession._isPlaying, "Play should set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "Play should reset _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Play should reset _isIdle")

    ''' verify
    UTF_assertEqual(2, GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count)
    UTF_assertEqual(2, mediaSession.getHitQueueSize(), "hitQueue should have 2 hits but has:" + StrI(mediaSession.getHitQueueSize()))
    hits = mediaSession._hitQueue

    UTF_assertNotEqual(autoGeneratedSessionStartHit.requestId, hits[0].requestId, "sessionResume requestId should not match cached sessionStart requestId")
    UTF_assertEqual(autoGeneratedSessionStartHit.xdmData, hits[0].xdmData, "sessionResume data (" + FormatJson(hits[0].xdmData) + ") should have expected xdmData:(" + FormatJson(autoGeneratedSessionStartHit.xdmData) + ")") ''' generated by _restartIdleSession() -> _createSessionResumeHit()
    UTF_assertEqual(autoGeneratedSessionStartHit.tsObject, hits[0].tsObject, "sessionResume should have expected tsObject") ''' generated by _restartIdleSession() -> _createSessionResumeHit()
    UTF_assertEqual(autoGeneratedSessionStartHit.eventType, hits[0].eventType, "sessionResume should have expected eventType") ''' generated by _restartIdleSession() -> _createSessionResumeHit()
    UTF_assertEqual(autoGeneratedSessionStartHit.xdmData, mediaSession._sessionStartHit.xdmData, "sessionResume should have expected xdmData") ''' cached by __extractSessionStartData()
    UTF_assertEqual(autoGeneratedSessionStartHit.tsObject, mediaSession._sessionStartHit.tsObject, "sessionResume should have expected tsObject")
    UTF_assertEqual(autoGeneratedSessionStartHit.eventType, mediaSession._sessionStartHit.eventType, "sessionResume should have expected eventType")
    UTF_assertNotInvalid(mediaSession._sessionStartHit.requestId, "Cached sessionResume should have requestId")
    UTF_assertEqual(restartIdlePlayHit, hits[1], "Restart trigger play event to be sent after session start")
end sub

' target: process()
' @Test
sub TC_adb_MediaSession_process_activeSession_longRunningSession_queued()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"

    playHit = {}
    playHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    playHit.eventType = "media.play"
    playHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    playHit.requestId = "playRequestId"

    ''' trigger the long running session timeout
    pingHit = {}
    pingHit.tsObject = {
        "tsInMillis": (24 * 60 * 60 * 1000 + 1),
        "tsInISO8601": "86400001"
    }
    pingHit.eventType = "media.ping"
    pingHit.xdmData = {
        "xdm": {
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }
    pingHit.requestId = "pingRequestId"

    autoGeneratedSessionEndHit = {}
    autoGeneratedSessionEndHit.tsObject = {
        "tsInMillis": (24 * 60 * 60 * 1000 + 1),
        "tsInISO8601": "86400001"
    }
    autoGeneratedSessionEndHit.eventType = "media.sessionEnd"
    autoGeneratedSessionEndHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionEnd",
            "timestamp": "86400001",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }

    autoGeneratedSessionStartHit = {}
    autoGeneratedSessionStartHit.tsObject = {
        "tsInMillis": (24 * 60 * 60 * 1000 + 1),
        "tsInISO8601": "86400001"
    }
    autoGeneratedSessionStartHit.eventType = "media.sessionStart"
    autoGeneratedSessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "timestamp": "86400001",
            "mediaCollection": {
                "playhead": 86400,
                "sessionDetails": {
                    "streamType": "vod",
                    "hasResume": true,
                    "contentType": "video"
                }
            }
        }
    }

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)

    ''' mock _tryDispatchMediaEvents()
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = 0
    mediaSession.tryDispatchMediaEvents = function() as void
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count = GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count + 1
    end function

    ''' default playback state
    UTF_assertFalse(mediaSession._isPlaying)

    ''' test and verify
    ''' sessionStart
    mediaSession.process(sessionStartHit)
    UTF_assertFalse(mediaSession._isPlaying, "sessionStart should not set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "sessionStart should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "sessionStart should not set _isIdle")

    ''' play
    mediaSession.process(playHit)
    UTF_assertTrue(mediaSession._isPlaying, "Play should set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "Play should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "Play should not set _isIdle")

    ''' ping (should trigger LongsessionTimeout)
    mediaSession.process(pingHit)
    UTF_assertTrue(mediaSession._isPlaying, "ping should not set _isPlaying")
    UTF_assertInvalid(mediaSession._idleStartTS, "ping should not set _idleStartTS")
    UTF_assertFalse(mediaSession._isIdle, "ping should not set _isIdle")

    ''' autoGeneratedSessionEndHit (should be queued since idleTimeout)
    ''' autoGeneratedSessionStartHit (should be queued since idleTimeout)
    ''' ping (that triggered long running session timeout will be dropped as the last sent hit was less than default ping interval 10sec)

    ''' verify
    ''' sessionStart, play, sessionEnd, sessionStart
    ''' ping that triggers sessionRestart is dropped since duration from last ping (sessionStart) < 10 sec (default ping interval)
    UTF_assertEqual(4, GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called_count)
    UTF_assertEqual(4, mediaSession.getHitQueueSize(), "hitQueue should have 5 hits but has:" + StrI(mediaSession.getHitQueueSize()))
    hits = mediaSession._hitQueue

    UTF_assertEqual(sessionStartHit, hits[0])
    UTF_assertEqual(playHit, hits[1])
    ''' pingHit will be sent with the new session since it triggered long running session timeout
    UTF_assertEqual(autoGeneratedSessionEndHit.xdmData, hits[2].xdmData, "sessionEnd data (" + FormatJson(hits[2].xdmData) + ") should have expected xdmData:(" + FormatJson(autoGeneratedSessionEndHit.xdmData) + ")") ''' generated by _closeIfIdle() -> _createSessionEndHit()
    UTF_assertEqual(autoGeneratedSessionEndHit.tsObject, hits[2].tsObject, "sessionEnd should have expected tsObject") ''' generated by _closeIfIdle() -> _createSessionEndHit()
    UTF_assertEqual(autoGeneratedSessionEndHit.eventType, hits[2].eventType, "sessionEnd should have expected eventType") ''' generated by _closeIfIdle() -> _createSessionEndHit()

    UTF_assertNotEqual(autoGeneratedSessionStartHit.requestId, hits[3].requestId, "sessionResume requestId should not match cached sessionStart requestId")
    UTF_assertEqual(autoGeneratedSessionStartHit.xdmData, hits[3].xdmData, "sessionResume data (" + FormatJson(hits[3].xdmData) + ") should have expected xdmData:(" + FormatJson(autoGeneratedSessionStartHit.xdmData) + ")") ''' generated by _restartIdleSession() -> _createSessionResumeHit()
    UTF_assertEqual(autoGeneratedSessionStartHit.tsObject, hits[3].tsObject, "sessionResume should have expected tsObject") ''' generated by _restartIdleSession() -> _createSessionResumeHit()
    UTF_assertEqual(autoGeneratedSessionStartHit.eventType, hits[3].eventType, "sessionResume should have expected eventType") ''' generated by _restartIdleSession() -> _createSessionResumeHit()
    UTF_assertEqual(autoGeneratedSessionStartHit.xdmData, mediaSession._sessionStartHit.xdmData, "sessionResume should have expected xdmData") ''' cached by __extractSessionStartData()
    UTF_assertEqual(autoGeneratedSessionStartHit.tsObject, mediaSession._sessionStartHit.tsObject, "sessionResume should have expected tsObject")
    UTF_assertEqual(autoGeneratedSessionStartHit.eventType, mediaSession._sessionStartHit.eventType, "sessionResume should have expected eventType")
    UTF_assertNotInvalid(mediaSession._sessionStartHit.requestId, "Cached sessionResume should have requestId")
end sub

' target: tryDispatchMediaEvents()
' @Test
sub TC_adb_MediaSession_tryDispatchMediaEvents_sessionStart_validConfigAndSessionConfig()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' mock configuration
    MEDIA_CONFIG_CONSTANTS = AdobeAEPSDKConstants().CONFIGURATION
    configuration = {}
    configuration[MEDIA_CONFIG_CONSTANTS.MEDIA_CHANNEL] = "testChannel"
    configuration[MEDIA_CONFIG_CONSTANTS.MEDIA_PLAYER_NAME] = "testPlayerName"
    configuration[MEDIA_CONFIG_CONSTANTS.MEDIA_APP_VERSION] = "testAppVersion"

    configurationModule.updateConfiguration(configuration)

    ''' mock edgeRequestQueue.add()
    GetGlobalAA()._test_edgeRequestQueue_add_called = false
    GetGlobalAA()._test_edgeRequestQueue_add_requestId = ""
    GetGlobalAA()._test_edgeRequestQueue_add_eventdata = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = -1
    GetGlobalAA()._test_edgeRequestQueue_add_meta = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_path = ""

    edgeRequestQueue.add = function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string) as void
        GetGlobalAA()._test_edgeRequestQueue_add_called = true
        GetGlobalAA()._test_edgeRequestQueue_add_requestId = requestId
        GetGlobalAA()._test_edgeRequestQueue_add_eventdata = eventData
        GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = timestampInMillis
        GetGlobalAA()._test_edgeRequestQueue_add_meta = meta
        GetGlobalAA()._test_edgeRequestQueue_add_path = path
    end function

    ''' create media session
    sessionConfig = { "config.channel": "channelFromSessionConfig", "config.adpinginterval": 1, "config.mainpinginterval": 30 }
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)
    mediaSession._hitQueue.push(sessionStartHit)

    expectedSessionStartXdm = {
        "xdm": {
            "eventType": "media.sessionStart",
            "timestamp": "1000", ''' added by tryDispatchMediaEvents()
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                    "channel": "channelFromSessionConfig", ''' updated by sessionConfig
                    "playerName": "testPlayerName",
                    "appVersion": "testAppVersion"
                }
            }
        }
    }

    ''' test
    mediaSession.tryDispatchMediaEvents()

    ''' verify
    actualEventData = GetGlobalAA()._test_edgeRequestQueue_add_eventdata
    UTF_assertNotInvalid(actualEventData, "eventData should not be invalid")
    actualXdmData = actualEventData

    UTF_assertTrue(GetGlobalAA()._test_edgeRequestQueue_add_called)
    UTF_assertEqual("sessionStartRequestId", GetGlobalAA()._test_edgeRequestQueue_add_requestId)
    ''' & prefix since timestamp is LongInteger
    UTF_assertEqual(1000&, GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis)
    UTF_assertEqual({}, GetGlobalAA()._test_edgeRequestQueue_add_meta)
    UTF_assertEqual("/ee/va/v1/sessionStart", GetGlobalAA()._test_edgeRequestQueue_add_path)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(actualXdmData.xdm._id))
    UTF_assertEqual(expectedSessionStartXdm.xdm.mediaCollection, actualXdmData.xdm.mediaCollection)
    UTF_assertEqual(expectedSessionStartXdm.xdm.timestamp, actualXdmData.xdm.timestamp)
    UTF_assertEqual(expectedSessionStartXdm.xdm.eventType, actualXdmData.xdm.eventType)
end sub

' target: tryDispatchMediaEvents()
' @Test
sub TC_adb_MediaSession_tryDispatchMediaEvents_sessionStart_validConfigNoSessionConfig()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"


    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' mock configuration
    MEDIA_CONFIG_CONSTANTS = AdobeAEPSDKConstants().CONFIGURATION
    configuration = {}
    configuration[MEDIA_CONFIG_CONSTANTS.MEDIA_CHANNEL] = "testChannel"
    configuration[MEDIA_CONFIG_CONSTANTS.MEDIA_PLAYER_NAME] = "testPlayerName"
    configuration[MEDIA_CONFIG_CONSTANTS.MEDIA_APP_VERSION] = "testAppVersion"

    configurationModule.updateConfiguration(configuration)

    ''' mock edgeRequestQueue.add()
    GetGlobalAA()._test_edgeRequestQueue_add_called = false
    GetGlobalAA()._test_edgeRequestQueue_add_requestId = ""
    GetGlobalAA()._test_edgeRequestQueue_add_eventData = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = -1
    GetGlobalAA()._test_edgeRequestQueue_add_meta = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_path = ""

    edgeRequestQueue.add = function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string) as void
        GetGlobalAA()._test_edgeRequestQueue_add_called = true
        GetGlobalAA()._test_edgeRequestQueue_add_requestId = requestId
        GetGlobalAA()._test_edgeRequestQueue_add_eventData = eventData
        GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = timestampInMillis
        GetGlobalAA()._test_edgeRequestQueue_add_meta = meta
        GetGlobalAA()._test_edgeRequestQueue_add_path = path
    end function

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
    mediaSession._hitQueue.push(sessionStartHit)

    expectedSessionStartXdm = {
        "xdm": {
            "eventType": "media.sessionStart",
            "timestamp": "1000", ''' added by tryDispatchMediaEvents()
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                    "channel": "testChannel",
                    "playerName": "testPlayerName",
                    "appVersion": "testAppVersion"
                }
            }
        }
    }

    ''' test
    mediaSession.tryDispatchMediaEvents()

    ''' verify
    actualEventData = GetGlobalAA()._test_edgeRequestQueue_add_eventData
    UTF_assertNotInvalid(actualEventData, "eventData should not be invalid")
    actualXdmData = actualEventData

    UTF_assertTrue(GetGlobalAA()._test_edgeRequestQueue_add_called)
    UTF_assertEqual("sessionStartRequestId", GetGlobalAA()._test_edgeRequestQueue_add_requestId)
    ''' & prefix since timestamp is LongInteger
    UTF_assertEqual(1000&, GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis)
    UTF_assertEqual({}, GetGlobalAA()._test_edgeRequestQueue_add_meta)
    UTF_assertEqual("/ee/va/v1/sessionStart", GetGlobalAA()._test_edgeRequestQueue_add_path)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(actualXdmData.xdm._id))
    UTF_assertEqual(expectedSessionStartXdm.xdm.mediaCollection, actualXdmData.xdm.mediaCollection)
    UTF_assertEqual(expectedSessionStartXdm.xdm.timestamp, actualXdmData.xdm.timestamp)
    UTF_assertEqual(expectedSessionStartXdm.xdm.eventType, actualXdmData.xdm.eventType)
end sub

' target: tryDispatchMediaEvents()
' SDK doesn't support remove configuration item at runtime and the required configuration items are not available when running into the MediaSession code.
' TODO: skip this test for now, let's remove it when refactoring the Media module before alpha release.
' @Ignore
sub TC_adb_MediaSession_tryDispatchMediaEvents_sessionStart_NoValidConfigNoSessionConfig()
    ''' setup
    sessionStartHit = {}
    sessionStartHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }
    sessionStartHit.requestId = "sessionStartRequestId"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' mock edgeRequestQueue.add()
    GetGlobalAA()._test_edgeRequestQueue_add_called = false
    GetGlobalAA()._test_edgeRequestQueue_add_requestId = ""
    GetGlobalAA()._test_edgeRequestQueue_add_eventData = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = -1
    GetGlobalAA()._test_edgeRequestQueue_add_meta = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_path = ""

    edgeRequestQueue.add = function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string) as void
        GetGlobalAA()._test_edgeRequestQueue_add_called = true
        GetGlobalAA()._test_edgeRequestQueue_add_requestId = requestId
        GetGlobalAA()._test_edgeRequestQueue_add_eventdata = eventData
        GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = timestampInMillis
        GetGlobalAA()._test_edgeRequestQueue_add_meta = meta
        GetGlobalAA()._test_edgeRequestQueue_add_path = path
    end function

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
    mediaSession._hitQueue.push(sessionStartHit)

    expectedSessionStartXdm = {
        "xdm": {
            "eventType": "media.sessionStart",
            "timestamp": "1000", ''' added by tryDispatchMediaEvents()
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video"
                }
            }
        }
    }

    ''' test
    mediaSession.tryDispatchMediaEvents()

    ''' verify
    actualEventData = GetGlobalAA()._test_edgeRequestQueue_add_eventdata
    UTF_assertNotInvalid(actualEventData, "eventData should not be invalid")
    actualXdmData = actualEventData

    UTF_assertTrue(GetGlobalAA()._test_edgeRequestQueue_add_called)
    UTF_assertEqual("sessionStartRequestId", GetGlobalAA()._test_edgeRequestQueue_add_requestId)
    ''' & prefix since timestamp is LongInteger
    UTF_assertEqual(1000&, GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis)
    UTF_assertEqual({}, GetGlobalAA()._test_edgeRequestQueue_add_meta)
    UTF_assertEqual("/ee/va/v1/sessionStart", GetGlobalAA()._test_edgeRequestQueue_add_path)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(actualXdmData.xdm._id))
    UTF_assertEqual(expectedSessionStartXdm.xdm.mediaCollection, actualXdmData.xdm.mediaCollection, "xdm mediaCollection does not match")
    UTF_assertEqual(expectedSessionStartXdm.xdm.timestamp, actualXdmData.xdm.timestamp)
    UTF_assertEqual(expectedSessionStartXdm.xdm.eventType, actualXdmData.xdm.eventType)
end sub

' target: tryDispatchMediaEvents()
' @Test
sub TC_adb_MediaSession_tryDispatchMediaEvents_notSessionStart_validBackendId()
    ''' setup
    playHit = {}
    playHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    playHit.eventType = "media.play"
    playHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    playHit.requestId = "playRequestId"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' mock edgeRequestQueue.add()
    GetGlobalAA()._test_edgeRequestQueue_add_called = false
    GetGlobalAA()._test_edgeRequestQueue_add_requestId = ""
    GetGlobalAA()._test_edgeRequestQueue_add_eventdata = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = -1
    GetGlobalAA()._test_edgeRequestQueue_add_meta = invalid
    GetGlobalAA()._test_edgeRequestQueue_add_path = ""

    edgeRequestQueue.add = function(requestId as string, eventData as object, timestampInMillis as longinteger, meta as object, path as string) as void
        GetGlobalAA()._test_edgeRequestQueue_add_called = true
        GetGlobalAA()._test_edgeRequestQueue_add_requestId = requestId
        GetGlobalAA()._test_edgeRequestQueue_add_eventdata = eventData
        GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis = timestampInMillis
        GetGlobalAA()._test_edgeRequestQueue_add_meta = meta
        GetGlobalAA()._test_edgeRequestQueue_add_path = path
    end function

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
    mediaSession._hitQueue.push(playHit)

    ''' mock backendSessionId
    mediaSession._backendSessionId = "testBackendSessionId"

    expectedPlayXdm = {
        "xdm": {
            "eventType": "media.play",
            "timestamp": "1000", ''' added by tryDispatchMediaEvents()
            "mediaCollection": {
                "sessionID": "testBackendSessionId", ''' added by tryDispatchMediaEvents()
                "playhead": 0
            }
        }
    }

    ''' test
    mediaSession.tryDispatchMediaEvents()

    ''' verify
    actualEventData = GetGlobalAA()._test_edgeRequestQueue_add_eventdata
    UTF_assertNotInvalid(actualEventData, "eventData should not be invalid")
    actualXdmData = actualEventData

    UTF_assertTrue(GetGlobalAA()._test_edgeRequestQueue_add_called)
    UTF_assertEqual("playRequestId", GetGlobalAA()._test_edgeRequestQueue_add_requestId)
    ''' & prefix since timestamp is LongInteger
    UTF_assertEqual(1000&, GetGlobalAA()._test_edgeRequestQueue_add_timestampInMillis)
    UTF_assertEqual({}, GetGlobalAA()._test_edgeRequestQueue_add_meta)
    UTF_assertEqual("/ee/va/v1/play", GetGlobalAA()._test_edgeRequestQueue_add_path)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(actualXdmData.xdm._id))
    UTF_assertEqual(expectedPlayXdm.xdm.mediaCollection, actualXdmData.xdm.mediaCollection)
    UTF_assertEqual(expectedPlayXdm.xdm.timestamp, actualXdmData.xdm.timestamp)
    UTF_assertEqual(expectedPlayXdm.xdm.eventType, actualXdmData.xdm.eventType)
end sub

' target: tryDispatchMediaEvents()
' @Test
sub TC_adb_MediaSession_tryDispatchMediaEvents_notSessionStart_invalidBackendId()
    ''' setup
    playHit = {}
    playHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    playHit.eventType = "media.play"
    playHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    playHit.requestId = "playRequestId"

    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' mock edgeRequestQueue.add()
    GetGlobalAA()._test_edgeRequestQueue_add_called = false

    edgeRequestQueue.add = function(_requestId as string, _eventData as object, _timestampInMillis as longinteger, _meta as object, _path as string) as void
        GetGlobalAA()._test_edgeRequestQueue_add_called = true
    end function

    ''' create media session
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
    mediaSession._hitQueue.push(playHit)

    ''' test
    mediaSession.tryDispatchMediaEvents()

    ''' verify
    UTF_assertFalse(GetGlobalAA()._test_edgeRequestQueue_add_called)
end sub

' target: close()
' @Test
sub TC_adb_MediaSession_close_noAbort_dispatchesHitQueue()
    ''' setup
    sessionConfig = { "config.adpinginterval": 1, "config.mainpinginterval": 30 }
    mediaSession = _adb_MediaSession("testId", {}, sessionConfig, {})
    mediaSession._hitQueue = [{}, {}, {}]

    ''' mock tryDispatchMediaEvents()
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called = false
    mediaSession.tryDispatchMediaEvents = function() as void
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called = true
    end function

    ''' test
    UTF_assertEqual(3, mediaSession.getHitQueueSize(), "Hit queue should not be empty")
    UTF_assertTrue(mediaSession._isActive)
    mediaSession.close()

    ''' verify
    UTF_assertEqual(3, mediaSession.getHitQueueSize(), "Hit queue should not be empty")
    UTF_assertTrue(GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called)
    UTF_assertFalse(mediaSession._isActive)
end sub

' target: close()
' @Test
sub TC_adb_MediaSession_close_abort_deletesHitQueue()
    ''' setup
    sessionConfig = { "config.adpinginterval": 1, "config.mainpinginterval": 30 }
    mediaSession = _adb_MediaSession("testId", {}, sessionConfig, {})
    mediaSession._hitQueue = [{}, {}, {}]

    ''' mock tryDispatchMediaEvents()
    GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called = false
    mediaSession.tryDispatchMediaEvents = function() as void
        GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called = true
    end function

    ''' test
    UTF_assertEqual(3, mediaSession.getHitQueueSize(), "Hit queue should not be empty")
    UTF_assertTrue(mediaSession._isActive)
    mediaSession.close(true)

    ''' verify
    UTF_assertEqual(0, mediaSession.getHitQueueSize(), "Hit queue should be empty")
    UTF_assertFalse(GetGlobalAA()._test_media_session_tryDispatchMediaEvents_called)
    UTF_assertFalse(mediaSession._isActive)
end sub

' *****************************************************************************************
' Private Functions

' target: _getPingInterval()
' @Test
sub TC_adb_MediaSession_getPingInterval_validInterval()
    ''' setup
    sessionConfig = { "config.adpinginterval": 1, "config.mainpinginterval": 30 }
    mediaSession = _adb_MediaSession("testId", {}, sessionConfig, {})

    ''' test
    interval = mediaSession._getPingInterval()

    ''' verify
    UTF_assertEqual(30, interval)

    adinterval = mediaSession._getPingInterval(true)
    UTF_assertEqual(1, adinterval)
end sub

' target: _getPingInterval()
' @Test
sub TC_adb_MediaSession_getPingInterval_invalidInterval()
    ''' setup
    sessionConfig = { "config.adpinginterval": 0, "config.mainpinginterval": 0 }
    mediaSession = _adb_MediaSession("testId", {}, sessionConfig, {})

    ''' test
    interval = mediaSession._getPingInterval()

    ''' verify
    UTF_assertEqual(10, interval)

    adinterval = mediaSession._getPingInterval(true)
    UTF_assertEqual(10, adinterval)


    sessionConfig = { "config.adpinginterval": 11, "config.mainpinginterval": 51 }
    mediaSession = _adb_MediaSession("testId", {}, sessionConfig, {})

    ''' verify
    interval = mediaSession._getPingInterval()
    UTF_assertEqual(10, interval)

    adinterval = mediaSession._getPingInterval(true)
    UTF_assertEqual(10, adinterval)
end sub

' target: _extractSessionStartData()
' @Test
sub TC_adb_MediaSession_extractSessionStartData_sessionStartHit_cachesHit()
    ''' setup
    mediaHit = {}
    mediaHit.xdmData = {
        "xdm": {
            "eventType": "media.sessionStart"
            "mediaCollection": {
                "playhead": 0,
            }
        }
    }
    mediaHit.eventType = "media.sessionStart"

    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' test
    mediaSession._extractSessionStartData(mediaHit)

    ''' verify
    UTF_assertNotInvalid(mediaSession._sessionStartHit)
    UTF_assertEqual(0, mediaSession._sessionStartHit.xdmData.xdm.mediaCollection.playhead)
end sub

' target: _extractSessionStartData()
' @Test
sub TC_adb_MediaSession_extractSessionStartData_notSessionStartHit_doesNotCacheHit()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.xdmData = {
        "xdm": {
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 0,
            }
        }
    }
    mediaHit.eventType = "media.play"

    ''' test
    mediaSession._extractSessionStartData(mediaHit)

    ''' verify
    UTF_assertInvalid(mediaSession._sessionStartHit)
end sub


' target: _attachMediaConfig()
' @Test
sub TC_adb_MediaSession_attachMediaConfig()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    ADB_CONSTANTS = AdobeAEPSDKConstants()
    configuration = {}
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "testChannel"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "testPlayerName"
    configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = "testAppVersion"

    configurationModule.updateConfiguration(configuration)
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
    updatedXDMData = mediaSession._attachMediaConfig({
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "sessionDetails": {
                }
                "playhead": 0,
            }
        }
    })

    ''' verify
    UTF_assertEqual("testChannel", updatedXDMData.xdm.mediaCollection.sessionDetails.channel)
    UTF_assertEqual("testPlayerName", updatedXDMData.xdm.mediaCollection.sessionDetails.playerName)
    UTF_assertEqual("testAppVersion", updatedXDMData.xdm.mediaCollection.sessionDetails.appVersion)
end sub

' target: _updatePlaybackState()
' @Test
sub TC_adb_MediaSession_updatePlaybackState_playEvent()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.eventType = "media.play"

    ''' test
    mediaSession._updatePlaybackState(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isPlaying, "Should be playing state")
    UTF_assertFalse(mediaSession._isIdle, "isIdle should be false")
    UTF_assertInvalid(mediaSession._idleStartTS, "idleStartTS should be invalid")
end sub

' target: _updatePlaybackState()
' @Test
sub TC_adb_MediaSession_updatePlaybackState_pauseStartEvent()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInMillis = 1000
    mediaHit.eventType = "media.pauseStart"

    ''' test
    mediaSession._updatePlaybackState(mediaHit)

    ''' verify
    UTF_assertNotInvalid(mediaSession._idleStartTS, "idleStartTS should be valid")
    UTF_assertFalse(mediaSession._isPlaying, "Should not be in playing state")
    ''' isIdle is only set when the session is deemed idle (30 mins of playback state != play)
    UTF_assertFalse(mediaSession._isIdle, "isIdle should be false")
end sub

' target: _updatePlaybackState()
' @Test
sub TC_adb_MediaSession_updatePlaybackState_pauseStart_bufferStartEvent()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInMillis = 1000
    mediaHit.eventType = "media.pauseStart"

    ''' test
    mediaSession._updatePlaybackState(mediaHit)

    ''' verify
    UTF_assertNotInvalid(mediaSession._idleStartTS)
    UTF_assertFalse(mediaSession._isPlaying)
    UTF_assertFalse(mediaSession._isIdle)

    ''' Buffer
    mediaHit.tsObject.tsInMillis = 2000
    mediaHit.eventType = "media.bufferStart"

    ''' test
    mediaSession._updatePlaybackState(mediaHit)

    ''' verify
    ''' idleStartTS should not change if already set
    UTF_assertEqual(1000, mediaSession._idleStartTS)
    UTF_assertNotInvalid(mediaSession._idleStartTS)
    UTF_assertFalse(mediaSession._isPlaying)
    ''' isIdle is only set when the session is deemed idle (30 mins of playback state != play)
    UTF_assertFalse(mediaSession._isIdle)
end sub

' target: _updatePlaybackState()
' @Test
sub TC_adb_MediaSession_updatePlaybackState_nonPlaybackEvents_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.eventType = "media.sessionStart"

    ''' test
    mediaSession._updatePlaybackState(mediaHit)

    ''' verify
    UTF_assertFalse(mediaSession._isPlaying)
    UTF_assertInvalid(mediaSession._idleStartTS)
    UTF_assertFalse(mediaSession._isIdle)

    mediaHit.eventType = "media.adStart"

    ''' test
    mediaSession._updatePlaybackState(mediaHit)

    ''' verify
    UTF_assertFalse(mediaSession._isPlaying)
    UTF_assertInvalid(mediaSession._idleStartTS)
    UTF_assertFalse(mediaSession._isIdle)
end sub

' target: _updateAdState()
' @Test
sub TC_adb_MediaSession_updateAdState_adStartEvent_setsIsInAd()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.eventType = "media.adStart"

    ''' test
    mediaSession._updateAdState(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isInAd, "Should be in ad state")
end sub

' target: _updateAdState()
' @Test
sub TC_adb_MediaSession_updateAdState_adCompleteEvent_adSkipEvent_resetsIsInAd()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}
    mediaHit.eventType = "media.adComplete"

    ''' test
    mediaSession._updateAdState(mediaHit)

    ''' verify
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")

    ''' adSkip
    mediaHit.eventType = "media.adSkip"
    mediaSession._updateAdState(mediaHit)
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")
end sub

' target: _updateAdState()
' @Test
sub TC_adb_MediaSession_updateAdState_nonAdEvent_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaHit = {}

    mediaHit.eventType = "media.adBreakStart"
    mediaSession._updateAdState(mediaHit)
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")

    mediaHit.eventType = "media.adBreakComplete"
    mediaSession._updateAdState(mediaHit)
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")

    mediaHit.eventType = "media.play"
    mediaSession._updateAdState(mediaHit)
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")

    mediaHit.eventType = "media.chapterStart"
    mediaSession._updateAdState(mediaHit)
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")

    mediaHit.eventType = "media.sessionStart"
    mediaSession._updateAdState(mediaHit)
    UTF_assertFalse(mediaSession._isInAd, "Should not be in ad state")
end sub

' target: _closeIfIdle()
' @Test
sub TC_adb_MediaSession_closeIfIdle_idleDurationOverIdleTimeout_endSession()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._isIdle = false
    mediaSession._isPlaying = false
    mediaSession._idleStartTS = 0
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' hit triggering idle time
    mediaHit = {}
    mediaHit.tsObject = {}
    mediaHit.requestId = "testRequestId"
    mediaHit.tsObject.tsInISO8601 = "1800001"
    mediaHit.tsObject.tsInMillis = (30 * 60 * 1000) + 1 ''' 30 mins + 1 ms
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10
            }
        }
    }

    expectedSessionEndHit = {
        "xdmData": {
            "xdm": {
                "timestamp": "1800001",
                "eventType": "media.sessionEnd",
                "mediaCollection": {
                    "playhead": 10,
                }
            }
        },
        "tsObject": {
            "tsInMillis": 1800001,
            "tsInISO8601": "1800001"

        },
        "eventType": "media.sessionEnd"
    }

    ''' test
    mediaSession._closeIfIdle(mediaHit)

    ''' verify
    UTF_assertFalse(mediaSession._isActive, "Session should not be active")
    UTF_assertTrue(mediaSession._isIdle)
    UTF_assertFalse(mediaSession._isPlaying)
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(1, hits.count(), "hit Queue is empty.")
    actualHit = hits[0]
    UTF_assertEqual(expectedSessionEndHit.eventType, actualHit.eventType, "expected eventType != actual eventType")
    UTF_assertEqual(expectedSessionEndHit.xdmData, actualHit.xdmData, "expected sessionEnd xdmData(" + FormatJson(expectedSessionEndHit.xdmData) + ") != actual sessionEnd xdmData(" + FormatJson(actualHit.xdmData) + ")")
    UTF_assertEqual(expectedSessionEndHit.tsObject, actualHit.tsObject, "expected sessionEnd tsObject != actual sessionEnd tsObject")
    UTF_assertNotInvalid(actualHit.requestId)
    UTF_assertNotEqual(mediaHit.requestId, actualHit.requestId, "Request ID must not match with the play hit")
end sub

' target: _closeIfIdle()
' @Test
sub TC_adb_MediaSession_closeIfIdle_idleDurationUnderIdleTimeout_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._isIdle = false
    mediaSession._isPlaying = false
    mediaSession._idleStartTS = 0
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.tsObject = {}
    mediaHit.requestId = "testRequestId"
    mediaHit.tsObject.tsInISO8601 = "1740000"
    mediaHit.tsObject.tsInMillis = (29 * 60 * 1000) ''' 29 mins
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10
            }
        }
    }

    ''' test
    mediaSession._closeIfIdle(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle)
    UTF_assertFalse(mediaSession._isPlaying)
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "hit Queue should be empty.")
end sub

' target: _closeIfIdle()
' @Test
sub TC_adb_MediaSession_closeIfIdle_alreadyIdleTimedout_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    ''' mock that session idleTimedout and is closed and marked idle
    mediaSession._isActive = false
    mediaSession._isIdle = true

    mediaSession._isPlaying = false
    mediaSession._idleStartTS = 0
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "1800001"
    mediaHit.tsObject.tsInMillis = (30 * 60 * 1000) + 1 ''' 30 mins + 1 ms
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 10
            }
        }
    }

    ''' test
    mediaSession._closeIfIdle(mediaHit)

    ''' verify
    UTF_assertFalse(mediaSession._isActive, "Session should not be active")
    UTF_assertTrue(mediaSession._isIdle, "Session should stay in idle state")
    UTF_assertFalse(mediaSession._isPlaying)
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _closeIfIdle()
' @Test
sub TC_adb_MediaSession_closeIfIdle_inPlayingState_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._isIdle = false
    ''' mock that session is in playing state
    mediaSession._isPlaying = true
    mediaSession._idleStartTS = 0
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "1800001"
    mediaHit.tsObject.tsInMillis = (30 * 60 * 1000) + 1 ''' 30 mins + 1 ms
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 10
            }
        }
    }

    ''' test
    mediaSession._closeIfIdle(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle, "Session should not be in idle state")
    UTF_assertTrue(mediaSession._isPlaying, "Session should be in playing state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _restartIdleSession()
' @Test
sub TC_adb_MediaSession_restartIdleSession_playAfterIdleTimeout_resumes()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' mock idle timeout state
    mediaSession._isIdle = true
    mediaSession._isActive = false
    mediaSession._isPlaying = false
    mediaSession._idleStartTS = 0

    ''' mock previous sessionStart hit
    sessionStartHit = {}
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.requestId = "sessionStartRequestId"
    sessionStartHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }
    mediaSession._sessionStartHit = sessionStartHit

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.eventType = "media.play"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "2000"
    mediaHit.tsObject.tsInMillis = 2000
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 11
            }
        }
    }

    expectedSessionResumeHit = {}
    expectedSessionResumeHit.eventType = "media.sessionStart"
    expectedSessionResumeHit.tsObject = {
        "tsInMillis": 2000,
        "tsInISO8601": "2000"
    }
    expectedSessionResumeHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 11,
                "sessionDetails": {
                    "hasResume": true,
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }

    ''' test
    mediaSession._restartIdleSession(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle, "Session should not be in idle state")
    UTF_assertTrue(mediaSession._isPlaying, "Session should be in playing state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(2, hits.count(), "Hit Queue should have 2 hits")
    ''' Verify the order of hits (first would be sessionStart and then play)
    actualSessionResumeHit = hits[0]
    playHit = hits[1]

    UTF_assertNotEqual(sessionStartHit.requestId, actualSessionResumeHit.requestId, "Request ID must not match with the cached sessionStart hit")
    UTF_assertNotEqual(playHit.requestId, actualSessionResumeHit.requestId, "Request ID must not match with the play hit")
    UTF_assertEqual(expectedSessionResumeHit.eventType, actualSessionResumeHit.eventType, "Event types must match")
    UTF_assertEqual(expectedSessionResumeHit.xdmData, actualSessionResumeHit.xdmData, "XDM data must match")
    UTF_assertEqual(mediaHit, playHit)
end sub

' target: _restartIdleSession()
' @Test
sub TC_adb_MediaSession_restartIdleSession_notPlayEventAfterIdleTimeout_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' mock idle timeout state
    mediaSession._isIdle = true
    mediaSession._isActive = false
    mediaSession._isPlaying = false
    mediaSession._idleStartTS = 0

    ''' mock previous sessionStart hit
    sessionStartHit = {}
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.requestId = "sessionStartRequestId"
    sessionStartHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }
    mediaSession._sessionStartHit = sessionStartHit

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.eventType = "media.sessionStart"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "2000"
    mediaHit.tsObject.tsInMillis = 2000
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 11
            }
        }
    }

    ''' test
    mediaSession._restartIdleSession(mediaHit)

    ''' verify
    UTF_assertFalse(mediaSession._isActive, "Session should not be active")
    UTF_assertTrue(mediaSession._isIdle, "Session should be in idle state")
    UTF_assertFalse(mediaSession._isPlaying, "Session should not be in playing state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _restartIdleSession()
' @Test
sub TC_adb_MediaSession_restartIdleSession_playifNotIdleTimeout_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    mediaSession._isIdle = false
    mediaSession._isActive = true

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.eventType = "media.play"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "2000"
    mediaHit.tsObject.tsInMillis = 2000
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 11
            }
        }
    }

    ''' test
    mediaSession._restartIdleSession(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle, "Session should not be in idle state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _restartIdleSession()
' @Test
sub TC_adb_MediaSession_restartIdleSession_ifActiveSession_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' Should not happen. Hypothetical case where isIdle is true and isActive is true
    mediaSession._isIdle = true
    ''' mock idle timeout state
    mediaSession._isActive = true

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.eventType = "media.play"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "2000"
    mediaHit.tsObject.tsInMillis = 2000
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 11
            }
        }
    }

    ''' test
    mediaSession._restartIdleSession(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertTrue(mediaSession._isIdle, "Session should be in idle state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _restartIfLongRunningSession()
' @Test
sub TC_adb_MediaSession_restartIfLongRunningSession_longRunningSession_restartsSession()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' mock previous sessionStart hit
    ''' sessionStart tsInMillis is used to calculate the session duration
    sessionStartHit = {}
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.requestId = "sessionStartRequestId"
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "0",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }
    mediaSession._sessionStartHit = sessionStartHit

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.eventType = "media.ping"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "86400001"
    mediaHit.tsObject.tsInMillis = (24 * 60 * 60 * 1000) + 1 ''' 24 hours + 1 ms
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }

    expectedSessionResumeHit = {}
    expectedSessionResumeHit.eventType = "media.sessionStart"
    expectedSessionResumeHit.tsObject = {
        "tsInMillis": 86400,
        "tsInISO8601": "86400001"
    }
    expectedSessionResumeHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 86400,
                "sessionDetails": {
                    "hasResume": true,
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }

    expectedSessionEndHit = {}
    expectedSessionEndHit.eventType = "media.sessionEnd"
    expectedSessionEndHit.tsObject = {
        "tsInMillis": 86400,
        "tsInISO8601": "86400001"
    }
    expectedSessionEndHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }

    ''' test
    mediaSession._restartIfLongRunningSession(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle, "Session should not be in idle state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(2, hits.count(), "Hit Queue should have 3 hits")
    ''' Verify the order of hits (first would be sessionStart and then play)
    actualSessionEndHit = hits[0]
    actualSessionResumeHit = hits[1]
    ''' ping will be dropped since less than ping interval

    UTF_assertNotEqual(sessionStartHit.requestId, actualSessionResumeHit.requestId, "SessionStart Request ID must not match with the cached sessionStart hit")
    UTF_assertEqual(expectedSessionEndHit.eventType, actualSessionEndHit.eventType, "SessionEnd Event types must match")
    UTF_assertEqual(expectedSessionEndHit.xdmData, actualSessionEndHit.xdmData, "SessionEnd XDM data must match")
    UTF_assertEqual(expectedSessionResumeHit.eventType, actualSessionResumeHit.eventType, "SessionStart Event types must match")
    UTF_assertEqual(expectedSessionResumeHit.xdmData, actualSessionResumeHit.xdmData, "SessionStart XDM data must match expected(" + FormatJson(expectedSessionResumeHit.xdmData) + ") != actual(" + FormatJson(actualSessionResumeHit.xdmData) + ")")
end sub

' target: _restartIfLongRunningSession()
' @Test
sub TC_adb_MediaSession_restartIfLongRunningSession_notLongRunningSession_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' mock previous sessionStart hit
    ''' sessionStart tsInMillis is used to calculate the session duration
    sessionStartHit = {}
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.requestId = "sessionStartRequestId"
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "0",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    mediaSession._sessionStartHit = sessionStartHit

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit
    mediaHit = {}
    mediaHit.eventType = "media.ping"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "1000"
    mediaHit.tsObject.tsInMillis = (23 * 60 * 60 * 1000) + (59 * 60 * 1000) ''' 23 hours + 59 mins
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }

    ''' test
    mediaSession._restartIfLongRunningSession(mediaHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle, "Session should not be in idle state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _restartIfLongRunningSession()
' @Test
sub TC_adb_MediaSession_restartIfLongRunningSession_triggeredBySessionEndOrComplete_ignored()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    ''' mock previous sessionStart hit
    ''' sessionStart tsInMillis is used to calculate the session duration
    sessionStartHit = {}
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.requestId = "sessionStartRequestId"
    sessionStartHit.tsObject = {
        "tsInMillis": 0,
        "tsInISO8601": "0"
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "0",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0
            }
        }
    }
    mediaSession._sessionStartHit = sessionStartHit

    ''' mock _queue()
    GetGlobalAA()._test_media_session_hits = []
    mediaSession._queue = function(mediaHit) as void
        hits = GetGlobalAA()._test_media_session_hits
        hits.push(mediaHit)
    end function


    ''' triggering hit (sessionEnd)
    sessionEndHit = {}
    sessionEndHit.eventType = "media.sessionEnd"
    sessionEndHit.tsObject = {}
    sessionEndHit.tsObject.tsInISO8601 = "1000"
    sessionEndHit.tsObject.tsInMillis = (24 * 60 * 60 * 1000) + 1 ''' 24 hours + 1 ms
    sessionEndHit.requestId = "testRequestId"
    sessionEndHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }

    ''' triggering hit (sessionComplete)
    sessionCompleteHit = {}
    sessionCompleteHit.eventType = "media.sessionComplete"
    sessionCompleteHit.tsObject = {}
    sessionCompleteHit.tsObject.tsInISO8601 = "1000"
    sessionCompleteHit.tsObject.tsInMillis = (24 * 60 * 60 * 1000) + 1 ''' 24 hours + 1 ms
    sessionCompleteHit.requestId = "testRequestId"
    sessionCompleteHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.sessionComplete",
            "mediaCollection": {
                "playhead": 86400
            }
        }
    }

    ''' test
    mediaSession._restartIfLongRunningSession(sessionEndHit)
    mediaSession._restartIfLongRunningSession(sessionCompleteHit)

    ''' verify
    UTF_assertTrue(mediaSession._isActive, "Session should be active")
    UTF_assertFalse(mediaSession._isIdle, "Session should not be in idle state")
    hits = GetGlobalAA()._test_media_session_hits
    UTF_assertEqual(0, hits.count(), "Hit Queue should be empty")
end sub

' target: _resetForRestart()
' @Test
sub TC_adb_MediaSession_resetForRestart()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._isIdle = true
    mediaSession._isActive = false
    mediaSession._backendSessionId = "testBackendSessionId"
    mediaSession._idleStartTS = 0
    mediaSession._lastHit = {}

    ''' should not be reset
    mediaSession._sessionStartHit = {}
    mediaSession._configurationModule = {}
    mediaSession._edgeRequestQueue = {}
    mediaSession._isPlaying = false
    mediaSession._isInAd = true


    ''' test
    mediaSession._resetForRestart()

    ''' verify
    UTF_assertInvalid(mediaSession._lastHit)
    UTF_assertFalse(mediaSession._isIdle)
    UTF_assertTrue(mediaSession._isActive)
    UTF_assertInvalid(mediaSession._idleStartTS)
    UTF_assertInvalid(mediaSession._backendSessionId)

    ''' not updated by resetForRestart
    UTF_assertNotInvalid(mediaSession._sessionStartHit)
    UTF_assertFalse(mediaSession._isPlaying)
    UTF_assertTrue(mediaSession._isInAd)
    UTF_assertNotInvalid(mediaSession._configurationModule)
    UTF_assertNotInvalid(mediaSession._edgeRequestQueue)
end sub

' target: _createSessionResumeHit()
' @Test
sub TC_adb_MediaSession_createSessionResumeHit()
    ''' setup
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    sessionStartHit = {}
    sessionStartHit.eventType = "media.sessionStart"
    sessionStartHit.requestId = "sessionStartRequestId"
    sessionStartHit.tsObject = {
        "tsInMillis": 1000,
        "tsInISO8601": "1000"
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails": {
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }

    playHit = {}
    playHit.eventType = "media.play"
    playHit.requestId = "playRequestId"
    playHit.tsObject = {
        "tsInMillis": 2000,
        "tsInISO8601": "2000"
    }
    playHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.play",
            "mediaCollection": {
                "playhead": 10
            }
        }
    }

    mediaSession._sessionStartHit = sessionStartHit

    ''' test
    actualSessionResumeHit = mediaSession._createSessionResumeHit(playHit)

    expectedSessionResumeHit = {}
    expectedSessionResumeHit.eventType = "media.sessionStart"
    expectedSessionResumeHit.tsObject = {
        "tsInMillis": 2000,
        "tsInISO8601": "2000"
    }
    expectedSessionResumeHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 10,
                "sessionDetails": {
                    "hasResume": true,
                    "streamType": "vod",
                    "contentType": "video",
                    "channel": "testChannel"
                }
            }
        }
    }
    ''' verify
    UTF_assertNotEqual(sessionStartHit.requestId, actualSessionResumeHit.requestId, "Request ID must not match with the cached sessionStart hit")
    UTF_assertNotEqual(playHit.requestId, actualSessionResumeHit.requestId, "Request ID must not match with the play hit")
    UTF_assertEqual(expectedSessionResumeHit.eventType, actualSessionResumeHit.eventType, "Event types must match")
    UTF_assertEqual(expectedSessionResumeHit.xdmData, actualSessionResumeHit.xdmData, "XDM data must match expected(" + FormatJson(expectedSessionResumeHit.xdmData) + ") != actual(" + FormatJson(actualSessionResumeHit.xdmData) + ")")
end sub

' target: _shouldQueue()
' @Test
sub TC_adb_MediaSession_shouldQueue_pingEvent_overPingInterval_returnsTrue()
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._lastHit = {}
    mediaSession._lastHit.tsObject = {}
    mediaSession._lastHit.tsObject.tsInMillis = 0
    mediaSession._lastHit.tsObject.tsInISO8601 = "0"

    mediaHit = {}
    mediaHit.eventType = "media.ping"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "10000"
    mediaHit.tsObject.tsInMillis = 10000 ''' default ping interval 10 seconds
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }

    ''' test
    shouldQueue = mediaSession._shouldQueue(mediaHit)

    ''' verify
    UTF_assertTrue(shouldQueue)
end sub

' target: _shouldQueue()
' @Test
sub TC_adb_MediaSession_shouldQueue_pingEvent_underPingInterval_returnsFalse()
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._lastHit = {}
    mediaSession._lastHit.tsObject = {}
    mediaSession._lastHit.tsObject.tsInMillis = 0
    mediaSession._lastHit.tsObject.tsInISO8601 = "0"

    mediaHit = {}
    mediaHit.eventType = "media.ping"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "9999"
    mediaHit.tsObject.tsInMillis = 9999 ''' default ping interval 10 seconds
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.ping",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }

    ''' test
    shouldQueue = mediaSession._shouldQueue(mediaHit)

    ''' verify
    UTF_assertFalse(shouldQueue)
end sub

' target: _shouldQueue()
' @Test
sub TC_adb_MediaSession_shouldQueue_notPingEvent_returnsTrue()
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    mediaSession._lastHit = {}
    mediaSession._lastHit.tsObject = {}
    mediaSession._lastHit.tsObject.tsInMillis = 0
    mediaSession._lastHit.tsObject.tsInISO8601 = "0"

    mediaHit = {}
    mediaHit.eventType = "media.chapterStart"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "1"
    mediaHit.tsObject.tsInMillis = 1 ''' default ping interval 10 seconds
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.chapterStart",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }

    ''' test and verify
    shouldQueue = mediaSession._shouldQueue(mediaHit)
    UTF_assertTrue(shouldQueue)

    mediaHit.eventType = "media.adStart"
    shouldQueue = mediaSession._shouldQueue(mediaHit)
    UTF_assertTrue(shouldQueue)

    mediaHit.eventType = "media.play"
    shouldQueue = mediaSession._shouldQueue(mediaHit)
    UTF_assertTrue(shouldQueue)

    mediaHit.eventType = "media.pauseStart"
    shouldQueue = mediaSession._shouldQueue(mediaHit)
    UTF_assertTrue(shouldQueue)

    mediaHit.eventType = "media.statesUpdate"
    shouldQueue = mediaSession._shouldQueue(mediaHit)
    UTF_assertTrue(shouldQueue)
end sub

' target: _queue()
' @Test
sub TC_adb_MediaSession_queue_sessionActive_queues()
    mediaSession = _adb_MediaSession("testId", {}, {}, {})

    mediaHit = {}
    mediaHit.eventType = "media.chapterStart"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "1"
    mediaHit.tsObject.tsInMillis = 1 ''' default ping interval 10 seconds
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.chapterStart",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }

    ''' test
    UTF_assertTrue(mediaSession._queue(mediaHit))

    ''' verify
end sub

' target: _queue()
' @Test
sub TC_adb_MediaSession_queue_sessionInActive_doesNotqueue()
    mediaSession = _adb_MediaSession("testId", {}, {}, {})
    ''' mock session inactive
    mediaSession._isActive = false

    mediaHit = {}
    mediaHit.eventType = "media.chapterStart"
    mediaHit.tsObject = {}
    mediaHit.tsObject.tsInISO8601 = "1"
    mediaHit.tsObject.tsInMillis = 1 ''' default ping interval 10 seconds
    mediaHit.requestId = "testRequestId"
    mediaHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.chapterStart",
            "mediaCollection": {
                "playhead": 1
            }
        }
    }

    ''' test and verify
    UTF_assertFalse(mediaSession._queue(mediaHit))
end sub

' target: _processEdgeRequestQueue()
' @Test
sub TC_adb_MediaSession_processEdgeRequestQueue_sessionStart_200_storesBackendSessionId()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSession = _adb_MediaSession("testId", {}, {}, edgeRequestQueue)

    ''' mock sessionStart requestID
    mediaSession._sessionStartHit = {}
    mediaSession._sessionStartHit.requestId = "sessionStartRequestId"

    ''' mock _processEdgeRequestQueue()
    edgeRequestQueue = mediaSession._edgeRequestQueue
    edgeRequestQueue.processRequests = function() as object
        responses = []
        responses.push(_adb_EdgeResponse("sessionStartRequestId", 200, FormatJson({
            "requestId": "sessionStartRequestId",
            "handle": [
                {
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
        return responses
    end function

    ''' test
    mediaSession._processEdgeRequestQueue()

    ''' verify
    UTF_assertEqual("bfba9a5f2986d69a9a9424f6a99702562512eb244f2b65c4f1c1553e7fe9997f", mediaSession._backendSessionId, "Backend sessionn IDs must match")
end sub

' target: _processEdgeRequestQueue()
' @Test
sub TC_adb_MediaSession_processEdgeRequestQueue_sessionStart_207_vaError400_closesSession()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSession = _adb_MediaSession("testId", {}, {}, edgeRequestQueue)

    ''' mock sessionStart requestID
    mediaSession._sessionStartHit = {}
    mediaSession._sessionStartHit.requestId = "sessionStartRequestId"

    ''' mock _processEdgeRequestQueue()
    edgeRequestQueue = mediaSession._edgeRequestQueue
    edgeRequestQueue.processRequests = function() as object
        responses = []
        responses.push(_adb_EdgeResponse("sessionStartRequestId", 207, FormatJson({
            "requestId": "sessionStartRequestId",
            "errors": [
                {
                    "type": "https://ns.adobe.com/aep/errors/va-edge-0400-400",
                    "status": 400,
                    "title": "Bad Request",
                    "detail": "Invalid request. Please check your input and try again.",
                    "report": {
                        "details": [
                            {
                                "name": "$.events[0].xdm.mediaCollection.sessionDetails",
                                "reason": "Missing required field"
                            }
                        ]
                    }
                }

            ]
        })))
        return responses
    end function

    ''' test
    mediaSession._processEdgeRequestQueue()

    ''' verify
    UTF_assertInvalid(mediaSession._backendSessionId, "Backend sessionn IDs must match")
    UTF_assertFalse(mediaSession._isActive, "Session should not be active")
end sub

' target: _createSessionEndHit()
''' Covered by
'''TC_adb_MediaSession_closeIfIdle_idleDurationOverIdleTimeout_endSession()
'''TC_adb_MediaSession_restartIfLongRunningSession_longRunningSession_restartsSession()


