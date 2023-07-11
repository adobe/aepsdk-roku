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
        ' **************************************************************
        '
        ' Sned POST request to the given URL with the given JSON object
        '
        ' @param url: the URL to send the request to
        ' @param jsonObj: the JSON object to send
        ' @param headers: the headers to send with the request
        ' @return the response object
        '
        ' **************************************************************
        syncPostRequest: function(url as string, jsonObj as object, headers = [] as object) as object
            _adb_log_verbose("syncPostRequest() - Attempting to send request with url:(" + FormatJson(url) + ") and body:(" + FormatJson(jsonObj) + ").")

            request = CreateObject("roUrlTransfer")
            port = CreateObject("roMessagePort")
            request.SetPort(port)
            request.SetCertificatesFile("common:/certs/ca-bundle.crt")
            ' request.InitClientCertificates()
            request.SetUrl(url)
            request.AddHeader("Content-Type", "application/json")
            request.AddHeader("accept", "application/json")
            request.AddHeader("Accept-Language", "en-US")
            for each header in headers
                request.AddHeader(header.key, header.value)
            end for
            ' request.EnableEncodings(true)
            if (request.AsyncPostFromString(FormatJson(jsonObj)))
                while (true)
                    msg = wait(0, port)
                    if (type(msg) = "roUrlEvent")
                        code = msg.GetResponseCode()
                        repMessage = msg.getString()
                        _adb_log_verbose("syncPostRequest() -  Sent edge request url:(" + FormatJson(url) + ") and body:(" + FormatJson(jsonObj) + ").")

                        return {
                            code: code,
                            message: repMessage
                        }
                    end if
                    if (msg = invalid)
                        _adb_log_verbose("syncPostRequest() - Failed to send edge request url:(" + FormatJson(url) + ") and body:(" + FormatJson(jsonObj) + ").")
                        request.AsyncCancel()
                        return invalid
                    end if
                end while
            end if
            return invalid
        end function,
    }
end function
