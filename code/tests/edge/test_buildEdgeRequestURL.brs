' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_buildEdgeRequestURL()
' @Test
sub TC_adb_buildEdgeRequestURL_validDomain()
    url = _adb_buildEdgeRequestURL("config_id_1", "request_id_1", "/ee/v1/interact")
    UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id_1&requestId=request_id_1", url)

    urlWithCustomDomain = _adb_buildEdgeRequestURL("config_id_2", "request_id_2", "/ee/v1/interact", "custom.domain.net")
    UTF_assertEqual("https://custom.domain.net/ee/v1/interact?configId=config_id_2&requestId=request_id_2", urlWithCustomDomain)
end sub

' target: _adb_buildEdgeRequestURL()
' @Test
sub TC_adb_buildEdgeRequestURL_validPathOverwriting()
    url = _adb_buildEdgeRequestURL("config_id_1", "request_id_1", "/ee/v1/interact")
    UTF_assertEqual("https://edge.adobedc.net/ee/v1/interact?configId=config_id_1&requestId=request_id_1", url)

    urlWithCustomDomain = _adb_buildEdgeRequestURL("config_id_2", "request_id_2", "/custom/path", "custom.domain.net")
    UTF_assertEqual("https://custom.domain.net/custom/path?configId=config_id_2&requestId=request_id_2", urlWithCustomDomain)
end sub