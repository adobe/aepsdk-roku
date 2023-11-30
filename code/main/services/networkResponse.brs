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

' ******************************* MODULE: Network Response ********************************

function _adb_NetworkResponse(responseCode as integer, responseBody as string) as object
    networkResponse = _adb_AdobeObject("com.adobe.service.network.response")
    networkResponse.Append({
        _responseCode: responseCode,
        _responseBody: responseBody,

        getResponseCode: function() as integer
            return m._responseCode
        end function,

        getResponseString: function() as string
            return m._responseBody
        end function,

        isSuccessful: function() as boolean
            ' https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#successful_responses
            return m._responseCode >= 200 and m._responseCode < 300
        end function,

        isRecoverable: function() as boolean
            return m._responseCode = 408 or m._responseCode = 504 or m._responseCode = 503
        end function,

        toString: function() as string
            return "Network request completed with response code (" + FormatJson(m.getResponseCode()) + ") body:(" + chr(10) + m.getResponseString() + chr(10) + ")"
        end function
    })
    return networkResponse
end function

function _adb_isNetworkResponse(networkResponse as object) as boolean
    return (networkResponse <> invalid and networkResponse.type = "com.adobe.service.network.response")
end function
