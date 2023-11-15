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

    sessionConfig = { "config.channel": "testChannel" }

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    UTF_assertNotInvalid(mediaSession)
    UTF_assertTrue(mediaSession._isActive)
    UTF_assertEqual("testId", mediaSession._id)
    UTF_assertNotInvalid(mediaSession._configurationModule)
    UTF_assertNotInvalid(mediaSession._edgeRequestQueue)
    UTF_assertNotInvalid(mediaSession._sessionConfig)
end sub

''' TODO
' target: process()
' @Test


''' TODO
' target: tryDispatchMediaEvents()
' @Test


''' TODO
' target: close()
' @Test

' *****************************************************************************************
' Private Functions

' target: _getPingInterval()
' @Test
sub TC_adb_MediaSession_getPingInterval_validInterval()
    ''' setup
    sessionConfig = {"config.adpinginterval" : 1, "config.mainpinginterval" : 30 }
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
    sessionConfig = {"config.adpinginterval" : 0, "config.mainpinginterval" : 0 }
    mediaSession = _adb_MediaSession("testId", {}, sessionConfig, {})

    ''' test
    interval = mediaSession._getPingInterval()

    ''' verify
    UTF_assertEqual(10, interval)

    adinterval = mediaSession._getPingInterval(true)
    UTF_assertEqual(10, adinterval)


    sessionConfig = {"config.adpinginterval" : 11, "config.mainpinginterval" : 51 }
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

' target: _updateChannelFromSessionConfig()
' @Test
sub TC_adb_MediaSession_updateChannelFromSessionConfig()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)
    sessionConfig = {"config.channel" : "channelFromSessionConfig"}

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)
    updatedXDMData = mediaSession._updateChannelFromSessionConfig({
        "xdm": {
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "sessionDetails": {
                    "channel" : "channelFromSDKConfig"
                }
                "playhead": 0,
            }
        }
    })

    ''' verify
    UTF_assertEqual("channelFromSessionConfig", updatedXDMData.xdm.mediaCollection.sessionDetails.channel)
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
                "timestamp": "2000",
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
    UTF_assertEqual(expectedSessionEndHit.xdmData, actualHit.xdmData, "expected sessionEnd xdmData != actual sessionEnd xdmData")
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
        "tsObject": {
            "tsInMillis": 1000,
            "tsInISO8601": "1000"
        }
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails" : {
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
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
        "tsObject": {
            "tsInMillis": 2000,
            "tsInISO8601": "2000"
        }
    }
    expectedSessionResumeHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 11,
                "sessionDetails" : {
                    "hasResume" : true,
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
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
        "tsObject": {
            "tsInMillis": 1000,
            "tsInISO8601": "1000"
        }
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails" : {
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
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
                "sessionDetails" : {
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
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
    mediaHit.tsObject.tsInISO8601 = "1000"
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
        "tsObject": {
            "tsInMillis": 86400,
            "tsInISO8601": "86400001"
        }
    }
    expectedSessionResumeHit.xdmData = {
        "xdm": {
            "timestamp": "86400001",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 86400,
                "sessionDetails" : {
                    "hasResume" : true,
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
                }
            }
        }
    }

    expectedSessionEndHit = {}
    expectedSessionEndHit.eventType = "media.sessionEnd"
    expectedSessionEndHit.tsObject = {
        "tsObject": {
            "tsInMillis": 86400,
            "tsInISO8601": "86400001"
        }
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
    UTF_assertEqual(3, hits.count(), "Hit Queue should have 3 hits")
    ''' Verify the order of hits (first would be sessionStart and then play)
    actualSessionEndHit = hits[0]
    actualSessionResumeHit = hits[1]
    pingHit = hits[2]

    UTF_assertNotEqual(pingHit.requestId, actualSessionEndHit.requestId, "SessionEnd Request ID must not match with the ping hit")
    UTF_assertNotEqual(sessionStartHit.requestId, actualSessionResumeHit.requestId, "SessionStart Request ID must not match with the cached sessionStart hit")
    UTF_assertNotEqual(pingHit.requestId, actualSessionResumeHit.requestId, "SessionStart Request ID must not match with the ping hit")
    UTF_assertEqual(expectedSessionEndHit.eventType, actualSessionEndHit.eventType, "SessionEnd Event types must match")
    UTF_assertEqual(expectedSessionEndHit.xdmData, actualSessionEndHit.xdmData, "SessionEnd XDM data must match")
    UTF_assertEqual(expectedSessionResumeHit.eventType, actualSessionResumeHit.eventType, "SessionStart Event types must match")
    UTF_assertEqual(expectedSessionResumeHit.xdmData, actualSessionResumeHit.xdmData, "SessionStart XDM data must match")
    UTF_assertEqual(mediaHit, pingHit)
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
    mediaSession._sessionConfig = {}
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
    UTF_assertNotInvalid(mediaSession._sessionConfig)
    UTF_assertNotInvalid(mediaSession._configurationModule)
    UTF_assertNotInvalid(mediaSession._edgeRequestQueue)
    UTF_assertNotInvalid(mediaSession._sessionConfig)
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
        "tsObject": {
            "tsInMillis": 1000,
            "tsInISO8601": "1000"
        }
    }
    sessionStartHit.xdmData = {
        "xdm": {
            "timestamp": "1000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 0,
                "sessionDetails" : {
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
                }
            }
        }
    }

    playHit = {}
    playHit.eventType = "media.play"
    playHit.requestId = "playRequestId"
    playHit.tsObject = {
        "tsObject": {
            "tsInMillis": 2000,
            "tsInISO8601": "2000"
        }
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
        "tsObject": {
            "tsInMillis": 2000,
            "tsInISO8601": "2000"
        }
    }
    expectedSessionResumeHit.xdmData = {
        "xdm": {
            "timestamp": "2000",
            "eventType": "media.sessionStart",
            "mediaCollection": {
                "playhead": 10,
                "sessionDetails" : {
                    "hasResume" : true,
                    "streamType" : "vod",
                    "contentType" : "video",
                    "channel" : "testChannel"
                }
            }
        }
    }
    ''' verify
    UTF_assertNotEqual(sessionStartHit.requestId, actualSessionResumeHit.requestId, "Request ID must not match with the cached sessionStart hit")
    UTF_assertNotEqual(playHit.requestId, actualSessionResumeHit.requestId, "Request ID must not match with the play hit")
    UTF_assertEqual(expectedSessionResumeHit.eventType, actualSessionResumeHit.eventType, "Event types must match")
    UTF_assertEqual(expectedSessionResumeHit.xdmData, actualSessionResumeHit.xdmData, "XDM data must match")
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
        responses.push(_adb_EdgeResponse("sessionStartRequestId",207, FormatJson({
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


