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

' ******************************** MODULE: NetworkService *********************************

function _adb_NetworkService() as object
    return {
        _debugMode: false,
        _debugQueue: [],

        ' **************************************************************
        '
        ' Sned POST request to the given URL with the given JSON object
        '
        ' @param url: the URL to send the request to
        ' @param jsonObj: the JSON object to send
        ' @param headers: the headers to send with the request
        ' @return the [NetworkResponse] object
        '
        ' **************************************************************
        syncPostRequest: function(url as string, jsonObj as object, headers = [] as dynamic) as object
            networkResponse = m._syncPostRequest(url, jsonObj, headers)

            if m._debugMode then
                m._queueDebugInfo(url, jsonObj, headers, networkResponse)
            end if

            return networkResponse
        end function,

        dump: function() as dynamic
            queue = m._debugQueue
            m._debugQueue = []
            return queue
        end function

        _queueDebugInfo: sub(url as string, jsonObj as object, headers as dynamic, networkResponse as object)
            response = invalid
            if _adb_isNetworkResponse(networkResponse) then
                response = {
                    "code": networkResponse.getResponseCode(),
                    "body": networkResponse.getResponseString()
                }
            end if
            m._debugQueue.Push({
                "method": "syncPostRequest",
                "url": url,
                "jsonObj": jsonObj,
                "headers": headers,
                "response": response
            })
        end sub,

        _syncPostRequest: function(url as string, jsonObj as object, headers = [] as dynamic) as object
            _adb_logDebug("NetworkService::syncPostRequest() - Attempting to send request with url:("  + chr(10) +  FormatJson(url)  + chr(10) + ") and body:("  + chr(10) + FormatJson(jsonObj)  + chr(10) + ").")

            request = CreateObject("roUrlTransfer")
            port = CreateObject("roMessagePort")
            request.SetPort(port)
            request.SetCertificatesFile("common:/certs/ca-bundle.crt")

            request.SetUrl(url)
            ' set default headers
            request.AddHeader("Content-Type", "application/json")
            request.AddHeader("accept", "application/json")
            request.AddHeader("Accept-Language", "en-US")

            for each header in headers
                request.AddHeader(header.key, header.value)
            end for

            if (request.AsyncPostFromString(FormatJson(jsonObj)))
                while (true)
                    msg = wait(0, port)
                    if (type(msg) = "roUrlEvent")
                        responseCode = msg.GetResponseCode()
                        responseString = msg.getString()
                        failureMessage = msg.GetFailureReason()
                        _adb_logDebug("NetworkService::syncPostRequest() - Received response code:(" + FormatJson(responseCode) + ") body:("  + chr(10) + responseString  + chr(10) + ") message:("  + chr(10) + failureMessage  + chr(10) + ").")
                        return _adb_NetworkResponse(responseCode, responseString)
                    end if
                    if (msg = invalid)
                        _adb_logDebug("NetworkService::syncPostRequest() - Failed to send edge request url:("  + chr(10) + FormatJson(url)  + chr(10) + ") and body:("  + chr(10) + FormatJson(jsonObj)  + chr(10) + ").")
                        request.AsyncCancel()
                        return invalid
                    end if
                end while
            end if
            return invalid
        end function
    }
end function
