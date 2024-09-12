' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: edgeRequest()
' @Test
sub TC_adb_EdgeRequest_init_valid()
    edgeRequest = _adb_EdgeRequest("request_id", { key: "value" }, 12345534)

    UTF_assertNotInvalid(edgeRequest)
    UTF_assertTrue(_adb_isValidEdgeRequest(edgeRequest))
    UTF_assertEqual("request_id", edgeRequest.getRequestId())
    UTF_assertEqual({ key: "value" }, edgeRequest.getEventData())
    UTF_assertEqual(12345534&, edgeRequest.getTimestampInMillis())
    UTF_assertEqual("edge", edgeRequest.getRequestType())
    UTF_assertEqual("/v1/interact", edgeRequest.getPath())
    UTF_assertEqual({}, edgeRequest.getMeta())

    edgeRequest.setMeta({ key: "value" })
    UTF_assertEqual({ key: "value" }, edgeRequest.getMeta())

    edgeRequest.setPath("/v2/collect")
    UTF_assertEqual("/v2/collect", edgeRequest.getPath())

    edgeRequest.setRequestType("consent")
    UTF_assertEqual("consent", edgeRequest.getRequestType())
end sub

' target: edgeRequest()
' @Test
sub TC_adb_EdgeRequest_init_invalid()
    InvalidEdgeRequests = [
        _adb_EdgeRequest("request_id", {}, -1),
        _adb_EdgeRequest("request_id", [{ xdm: {} }], -1),
        _adb_EdgeRequest("request_id", [], 12345534),
        _adb_EdgeRequest("request_id", invalid, 12345534),
        _adb_EdgeRequest("request_id", 999, 12345534),
        _adb_EdgeRequest("request_id", "invalid object", 12345534),
        _adb_EdgeRequest("", [{ xdm: {} }], 12345534),
    ]

    for each InvalidEdgeRequest in InvalidEdgeRequests
        UTF_assertInvalid(InvalidEdgeRequest)
        UTF_assertFalse(_adb_isValidEdgeRequest(InvalidEdgeRequest))
    end for
end sub

' target: edgeRequest()
' @Test
sub TC_adb_EdgeRequest_isValidEdgeRequest_valid()
    validEdgeRequest = _adb_EdgeRequest("request_id", { key: "value" }, 12345534)
    UTF_assertTrue(_adb_isValidEdgeRequest(validEdgeRequest))
end sub

' target: edgeRequest()
' @Test
sub TC_adb_EdgeRequest_isValidEdgeRequest_invalid()
    invalidEdgeRequest = [
        invalid,
        [],
        {},
        "string",
        123,
        true,
        false,
    ]

    for each edgeRequest in invalidEdgeRequest
        UTF_assertFalse(_adb_isValidEdgeRequest(edgeRequest))
    end for
end sub

' target: edgeRequest()
' @Test
sub TC_adb_EdgeRequest_isEdgeConsentRequest_valid()
    edgeConsentRequest = _adb_ConsentRequest("request_id", { key: "value" }, 12345534)

    UTF_assertTrue(_adb_isEdgeConsentRequest(edgeConsentRequest))
    UTF_assertEqual("consent", edgeConsentRequest.getRequestType())
end sub


