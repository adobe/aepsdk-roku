' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_NetworkResponse()
' @Test
sub TC_adb_NetworkResponse()
    networkResponse = _adb_NetworkResponse(200, "response body")

    UTF_assertTrue(_adb_isNetworkResponse(networkResponse))
    UTF_assertEqual(200, networkResponse.getResponseCode())
    UTF_assertEqual("response body", networkResponse.getResponseString())
end sub

' target: isSuccessful()
' @Test
sub TC_adb_NetworkResponse_isSuccessful()
    networkResponse = _adb_NetworkResponse(200, "response body")
    UTF_assertTrue(networkResponse.isSuccessful())
    networkResponse = _adb_NetworkResponse(299, "response body")
    UTF_assertTrue(networkResponse.isSuccessful())
    networkResponse = _adb_NetworkResponse(300, "response body")
    UTF_assertFalse(networkResponse.isSuccessful())
end sub

' target: isRecoverable()
' @Test
sub TC_adb_NetworkResponse_isRecoverable()
    networkResponse = _adb_NetworkResponse(408, "response body")
    UTF_assertTrue(networkResponse.isRecoverable())
    networkResponse = _adb_NetworkResponse(504, "response body")
    UTF_assertTrue(networkResponse.isRecoverable())
    networkResponse = _adb_NetworkResponse(503, "response body")
    UTF_assertTrue(networkResponse.isRecoverable())
end sub