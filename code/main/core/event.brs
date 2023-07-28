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

' *********************************** MODULE: Events **************************************

function _adb_isRequestEvent(event as object) as boolean
    return event <> invalid and event.owner = "adobe" and event.type = "com.adobe.event.request"
end function

function _adb_RequestEvent(apiName as string, data = {} as object) as object
    event = _adb_AdobeObject("com.adobe.event.request")
    event.Append({
        uuid: _adb_generate_UUID(),
        timestamp: _adb_ISO8601_timestamp(),
        apiName: apiName,
        data: data,
    })
    return event
end function

function _adb_isResponseEvent(event as object) as boolean
    return event <> invalid and event.owner = "adobe" and event.type = "com.adobe.event.response"
end function

function _adb_ResponseEvent(parentId as string, data = {} as object) as object
    event = _adb_AdobeObject("com.adobe.event.response")
    event.Append({
        uuid: _adb_generate_UUID(),
        parentId: parentId,
        timestamp: _adb_ISO8601_timestamp(),
        data: data,
    })
    return event
end function