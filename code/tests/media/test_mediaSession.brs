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




' *****************************************************************************************
' Private Functions

' target: _getPingInterval()
' @Test
sub TC_adb_MediaSession_getPingInterval_validInterval()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)


    sessionConfig = {"config.adpinginterval" : 1, "config.mainpinginterval" : 30 }

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    interval = mediaSession._getPingInterval()
    UTF_assertEqual(30, interval)

    adinterval = mediaSession._getPingInterval(true)
    UTF_assertEqual(1, adinterval)
end sub

' target: _getPingInterval()
' @Test
sub TC_adb_MediaSession_getPingInterval_invalidInterval()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)


    sessionConfig = {"config.adpinginterval" : 0, "config.mainpinginterval" : 0 }

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    interval = mediaSession._getPingInterval()
    UTF_assertEqual(10, interval)

    adinterval = mediaSession._getPingInterval(true)
    UTF_assertEqual(10, adinterval)


    sessionConfig = {"config.adpinginterval" : 11, "config.mainpinginterval" : 51 }
    mediaSession = _adb_MediaSession("testId", configurationModule, sessionConfig, edgeRequestQueue)

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
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
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

    mediaSession._extractSessionStartData(mediaHit)

    ''' verify
    UTF_assertNotInvalid(mediaSession._sessionStartHit)
    UTF_assertEqual(0, mediaSession._sessionStartHit.xdmData.xdm.mediaCollection.playhead)
end sub

' target: _extractSessionStartData()
' @Test
sub TC_adb_MediaSession_extractSessionStartData_notSessionStartHit_doesNotCacheHit()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    ''' test
    mediaSession = _adb_MediaSession("testId", configurationModule, {}, edgeRequestQueue)
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
    firstIdleStartTS = mediaSession._idleStartTS
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
