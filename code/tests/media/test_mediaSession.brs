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


