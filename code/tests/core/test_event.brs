' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_RequestEvent()
' @Test
sub TC_adb_RequestEvent()
    event = _adb_RequestEvent("api_name", { key: "value" })

    UTF_assertTrue(_adb_isRequestEvent(event))
    UTF_assertEqual("adobe", event.owner)
    UTF_assertEqual("com.adobe.event.request", event.type)
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("api_name", event.apiName)
    UTF_assertEqual({ key: "value" }, event.data)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp))
end sub

' target: _adb_RequestEvent()
' @Test
sub TC_adb_RequestEvent_empty_data()
    event = _adb_RequestEvent("api_name")

    UTF_assertTrue(_adb_isRequestEvent(event))
    UTF_assertEqual("adobe", event.owner)
    UTF_assertEqual("com.adobe.event.request", event.type)
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("api_name", event.apiName)
    UTF_assertEqual({}, event.data)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp))
end sub

' target: _adb_ResponseEvent()
' @Test
sub TC_adb_ResponseEvent()
    event = _adb_ResponseEvent("parent_id", { key: "value" })

    UTF_assertTrue(_adb_isResponseEvent(event))
    UTF_assertEqual("adobe", event.owner)
    UTF_assertEqual("com.adobe.event.response", event.type)
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("parent_id", event.parentId)
    UTF_assertEqual({ key: "value" }, event.data)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp))
end sub

' target: _adb_ResponseEvent()
' @Test
sub TC_adb_ResponseEvent_empty_data()
    event = _adb_ResponseEvent("parent_id")

    UTF_assertTrue(_adb_isResponseEvent(event))
    UTF_assertEqual("adobe", event.owner)
    UTF_assertEqual("com.adobe.event.response", event.type)
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("parent_id", event.parentId)
    UTF_assertEqual({}, event.data)
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp))
end sub

' target: _adb_IdentityResponseEvent()
' @Test
sub TC_adb_IdentityResponseEvent()
    event = _adb_IdentityResponseEvent("parent_id", { key: "value" })

    UTF_assertTrue(_adb_isIdentityResponseEvent(event), "Event should be an identity response event")
    UTF_assertEqual("adobe", event.owner, generateErrorMessage("Event owner", "adobe", FormatJson(event.owner)))
    UTF_assertEqual("com.adobe.event.response", event.type, generateErrorMessage("Event type", "com.adobe.event.response", FormatJson(event.type)))
    UTF_assertEqual("com.adobe.module.identity", event.source, generateErrorMessage("Event source", "com.adobe.module.identity", FormatJson(event.source)))
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("parent_id", event.parentId, generateErrorMessage("Event parentId", "parent_id", FormatJson(event.parentId)))
    UTF_assertEqual({ key: "value" }, event.data, generateErrorMessage("Event data", "{ key: value }", FormatJson(event.data)))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid), "Event uuid should not be empty or invalid")
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp), "Event timestamp should not be empty or invalid")
end sub

' target: _adb_IdentityResponseEvent()
' @Test
sub TC_adb_IdentityResponseEvent_empty_data()
    event = _adb_IdentityResponseEvent("parent_id")

    UTF_assertTrue(_adb_isIdentityResponseEvent(event), "Event should be an identity response event")
    UTF_assertEqual("adobe", event.owner, generateErrorMessage("Event owner", "adobe", FormatJson(event.owner)))
    UTF_assertEqual("com.adobe.event.response", event.type, generateErrorMessage("Event type", "com.adobe.event.response", FormatJson(event.type)))
    UTF_assertEqual("com.adobe.module.identity", event.source, generateErrorMessage("Event source", "com.adobe.module.identity", FormatJson(event.source)))
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("parent_id", event.parentId, generateErrorMessage("Event parentId", "parent_id", FormatJson(event.parentId)))
    UTF_assertEqual({}, event.data, generateErrorMessage("Event data", "{ }", FormatJson(event.data)))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid), "Event uuid should not be empty or invalid")
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp), "Event timestamp should not be empty or invalid")
end sub

' target: _adb_EdgeResponseEvent()
' @Test
sub TC_adb_EdgeResponseEvent()
    event = _adb_EdgeResponseEvent("parent_id", { key: "value" })

    UTF_assertTrue(_adb_isEdgeResponseEvent(event), "Event should be an identity response event")
    UTF_assertEqual("adobe", event.owner, generateErrorMessage("Event owner", "adobe", FormatJson(event.owner)))
    UTF_assertEqual("com.adobe.event.response", event.type, generateErrorMessage("Event type", "com.adobe.event.response", FormatJson(event.type)))
    UTF_assertEqual("com.adobe.module.edge", event.source, generateErrorMessage("Event source", "com.adobe.module.edge", FormatJson(event.source)))
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("parent_id", event.parentId, generateErrorMessage("Event parentId", "parent_id", FormatJson(event.parentId)))
    UTF_assertEqual({ key: "value" }, event.data, generateErrorMessage("Event data", "{ key: value }", FormatJson(event.data)))
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid), "Event uuid should not be empty or invalid")
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp), "Event timestamp should not be empty or invalid")

end sub

' target: _adb_EdgeResponseEvent()
' @Test
sub TC_adb_EdgeResponseEvent_empty_data()
    event = _adb_EdgeResponseEvent("parent_id")

    UTF_assertTrue(_adb_isEdgeResponseEvent(event), "Event should be an identity response event")
    UTF_assertEqual("adobe", event.owner, generateErrorMessage("Event owner", "adobe", FormatJson(event.owner)))
    UTF_assertEqual("com.adobe.event.response", event.type, generateErrorMessage("Event type", "com.adobe.event.response", FormatJson(event.type)))
    UTF_assertEqual("com.adobe.module.edge", event.source, generateErrorMessage("Event source", "com.adobe.module.edge", FormatJson(event.source)))
    UTF_assertEqual("LongInteger", Type(event.timestampInMillis), "timestampInMillis is not a long int")
    UTF_assertEqual("parent_id", event.parentId, generateErrorMessage("Event parentId", "parent_id", FormatJson(event.parentId)))
    UTF_assertEqual({}, event.data, "Event data should be empty")
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.uuid), "Event uuid should not be empty or invalid")
    UTF_assertFalse(_adb_isEmptyOrInvalidString(event.timestamp), "Event timestamp should not be empty or invalid")
end sub
