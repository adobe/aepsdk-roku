' ********************** Copyright 2023 Adobe. All rights reserved. **********************
' *
' * This file is licensed to you under the Apache License, Version 2.0 (the "License");
' * you may not use this file except in compliance with the License. You may obtain a copy
' * of the License at http://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software distributed under
' * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' * OF ANY KIND, either express or implied. See the License for the specific language
' * governing permissions and limitations under the License.
' *
' *****************************************************************************************

' ***************************** MODULE: buildEdgeRequestURL *******************************

function _adb_buildEdgeRequestURL(configId as string, requestId as string, path as string, edgeDomain = invalid as dynamic) as string
    scheme = "https://"
    host = "edge.adobedc.net"
    ' overridablePath = "/ee/v1/interact"
    query = "?configId=" + configId

    if not _adb_isEmptyOrInvalidString(path) then
        if not path.startsWith("/")
            path = "/" + path
        end if
        if _adb_isStringEndsWith(path, "/") then
            path = path.left(path.len() - 1)
        end if
    end if

    if not _adb_isEmptyOrInvalidString(edgeDomain)
        host = edgeDomain
    end if

    if not _adb_isEmptyOrInvalidString(requestId)
        query = query + "&requestId=" + requestId
    end if

    requestUrl = scheme + host + path + query

    return requestUrl
end function