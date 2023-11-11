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

' target: createSession()
' @Test
sub TC_adb_MediaSessionManager_createSession_endsOldSession()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)
    mediaSessionManager._activeSession = _adb_MediaSession("testSessionId1", configurationModule, {}, edgeRequestQueue)

    sessionConfig = { "config.channel": "testChannel" }

    ''' test
    mediaSessionManager.createSession(configurationModule, sessionConfig, edgeRequestQueue)

    ''' verify
    UTF_assertNotInvalid(mediaSessionManager._activeSession)
    UTF_assertNotEqual("testSessionId1", mediaSessionManager._activeSession._sessionId)
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

    sessionConfig = { "config.channel": "testChannel" }

    GetGlobalAA()._adb_session_process_called = false
    GetGlobalAA()._adb_session_close_called = false

    ''' mock MediaSession
    mockMediaSession = _adb_MediaSession("testSessionId", configurationModule, sessionConfig, edgeRequestQueue)
    mockMediaSession.process = function(mediaHit as object) as void
        GetGlobalAA()._adb_session_process_called = true
        UTF_assertEqual({ "test": "test" }, mediaHit)
    end function

    mockMediaSession.close = function(isAbort = false as boolean) as void
        GetGlobalAA()._adb_session_close_called = true
    end function

    ''' test
    mediaSessionManager.createSession(configurationModule, sessionConfig, edgeRequestQueue)
    ''' update active session with mock
    mediaSessionManager._activeSession = mockMediaSession

    mediaSessionManager.queue({ "test": "test" })

    ''' verify
    UTF_assertNotInvalid(mediaSessionManager._activeSession, "Active session is invalid")
    UTF_assertTrue(GetGlobalAA()._adb_session_process_called, "Session process was not called")
    UTF_assertFalse(GetGlobalAA()._adb_session_close_called, "Session close was called")
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

    ''' test
    mediaSessionManager.queue({ "test": "test" })

    ''' verify
    UTF_assertInvalid(mediaSessionManager._activeSession)
end sub

' target: endSession()
' @Test
sub TC_adb_MediaSessionManager_endSession_validActiveSession_closesSession()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)

    sessionConfig = { "config.channel": "testChannel" }

    GetGlobalAA()._adb_session_process_called = false
    GetGlobalAA()._adb_session_close_called = false

    ''' mock MediaSession
    mockMediaSession = _adb_MediaSession("testSessionId", configurationModule, sessionConfig, edgeRequestQueue)
    mockMediaSession.process = function(_mediaHit as object) as void
        GetGlobalAA()._adb_session_process_called = true
    end function

    mockMediaSession.close = function(_mediaHit as object) as void
        GetGlobalAA()._adb_session_close_called = true
    end function

    ''' test
    mediaSessionManager.createSession(configurationModule, sessionConfig, edgeRequestQueue)
    ''' update active session with mock
    mediaSessionManager._activeSession = mockMediaSession
    mediaSessionManager.endSession()

    ''' verify
    UTF_assertInvalid(mediaSessionManager._activeSession)
    UTF_assertFalse(GetGlobalAA()._adb_session_process_called, "Session process was called")
    UTF_assertTrue(GetGlobalAA()._adb_session_close_called, "Session close was not called")
end sub

' target: endSession()
' @Test
sub TC_adb_MediaSessionManager_endSession_invalidActiveSession_getsIgnored()
    ''' setup
    configurationModule = _adb_ConfigurationModule()
    identityModule = _adb_IdentityModule(configurationModule)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule)
    edgeRequestQueue = _adb_edgeRequestQueue("media_queue", edgeModule)

    mediaSessionManager = _adb_MediaSessionManager()
    UTF_assertInvalid(mediaSessionManager._activeSession)

    ''' test
    UTF_assertInvalid(mediaSessionManager._activeSession)
    mediaSessionManager.endSession()

    ''' verify
    UTF_assertInvalid(mediaSessionManager._activeSession)
end sub
