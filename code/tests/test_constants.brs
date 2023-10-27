' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: AdobeAEPSDKConstants()
' @Test
sub TC_AdobeAEPSDKConstants()
    cons = AdobeAEPSDKConstants()
    UTF_assertEqual(cons.LOG_LEVEL.VERBOSE, 0)
    UTF_assertEqual(cons.LOG_LEVEL.DEBUG, 1)
    UTF_assertEqual(cons.LOG_LEVEL.INFO, 2)
    UTF_assertEqual(cons.LOG_LEVEL.WARNING, 3)
    UTF_assertEqual(cons.LOG_LEVEL.ERROR, 4)

    ' Edge configuration
    UTF_assertEqual(cons.CONFIGURATION.EDGE_CONFIG_ID, "edge.configId")
    UTF_assertEqual(cons.CONFIGURATION.EDGE_DOMAIN, "edge.domain")

    ' Media configuration
    UTF_assertEqual(cons.CONFIGURATION.MEDIA_CHANNEL, "edgemedia.channel")
    UTF_assertEqual(cons.CONFIGURATION.MEDIA_PLAYER_NAME, "edgemedia.playerName")
    UTF_assertEqual(cons.CONFIGURATION.MEDIA_APP_VERSION, "edgemedia.appVersion")

    ' Media session-level configuration
    UTF_assertEqual(cons.MEDIA_SESSION_CONFIG.CHANNEL, "config.channel")
    UTF_assertEqual(cons.MEDIA_SESSION_CONFIG.MAIN_PING_INTERVAL, "config.mainpinginterval")
    UTF_assertEqual(cons.MEDIA_SESSION_CONFIG.AD_PING_INTERVAL, "config.adpinginterval")

end sub
