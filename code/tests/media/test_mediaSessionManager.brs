' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_MediaSessionManager()
' @Test
sub TC_adb_MediaSessionManager_init()
    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)
end sub

' target: createSession()
' @Test
sub TC_adb_MediaSessionManager_createSession()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)

    sessionConfig = { "config.channel": "testChannel" }

    ''' test
    mediaSessionManager.createSession(configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    UTF_assertNotInvalid(mediaSessionManager._activeSession)
end sub

' target: queue()
' @Test
sub TC_adb_MediaSessionManager_queue_validActiveSession_queuesWithSession()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)

    sessionConfig = { "config.channel": "testChannel" }

    GetGlobalAA()._adb_session_process_called = false

    ''' mock MediaSession
    mediaSession = _adb_MediaSession("testSessionId", configurationModule, sessionConfig, edgeRequestQueue)
    mediaSession.process = function(mediaHit as object) as void
        GetGlobalAA()._adb_session_process_called = true
        UTF_assertEqual({ "test": "test" }, mediaHit)
    end function

    mediaSessionManager._activeSession = mediaSession

    ''' test
    mediaSessionManager.createSession(configurationModule, sessionConfig, edgeRequestQueue)
    mediaSessionManager.queue({ "test": "test" })

    ''' verify
    UTF_assertNotInvalid(mediaSessionManager._activeSession)
    UTF_assertTrue(GetGlobalAA()._adb_session_process_called)
end sub

' target: queue()
' @Test
sub TC_adb_MediaSessionManager_queue_invalidActiveSession_ignoresMediaHit()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)

    sessionConfig = { "config.channel": "testChannel" }

    GetGlobalAA()._adb_session_process_called = false

    ''' mock MediaSession
    mediaSession = _adb_MediaSession("testSessionId", configurationModule, sessionConfig, edgeRequestQueue)
    mediaSession.process = function(_mediaHit as object) as void
        GetGlobalAA()._adb_session_process_called = true
    end function

    mediaSessionManager._activeSession = mediaSession

    ''' test
    mediaSessionManager.queue({ "test": "test" })

    ''' verify
    UTF_assertNotInvalid(mediaSessionManager._activeSession)
    UTF_assertTrue(GetGlobalAA()._adb_session_process_called)
end sub


