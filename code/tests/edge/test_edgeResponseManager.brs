' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_edgeResponseManager()
' @Test
sub TC_adb_EdgeResponseManager_Init()
    edgeResponseManager = _adb_edgeResponseManager()

    UTF_assertNotInvalid(edgeResponseManager._locationHintManager)
    UTF_assertNotInvalid(edgeResponseManager._stateStoreManager)
end sub

' target: _adb_edgeResponseManager_processResponse()
' @Test
sub TC_adb_EdgeResponseManager_processResponse_validLocationHintResponse()
    edgeResponseManager = _adb_edgeResponseManager()

    GetGlobalAA().locationHintManager_processLocationHintHandle_called = true
    GetGlobalAA().locationHintManager_processLocationHintHandle_actualHandle = invalid

    mockLocationHintManager = {
        processLocationHintHandle: function(handle as object) as void
            GetGlobalAA().locationHintManager_processLocationHintHandle_called = true
            GetGlobalAA().locationHintManager_processLocationHintHandle_actualHandle = handle
        end function
    }
    ' set the mock location hint manager
    edgeResponseManager._locationHintManager = mockLocationHintManager

    GetGlobalAA().locationHandle = {
        payload: [
            {
                scope: "edgenetwork",
                hint: "locationHint",
                ttlSeconds: 1800
            }
        ],
        type : "locationHint:result"
    }

    fakeEdgeResponse = _adb_EdgeResponse("fakeRequestID", 200, FormatJson({ "handle": [GetGlobalAA().locationHandle] }))

    edgeResponseManager.processResponse(fakeEdgeResponse)

    expectedHandle = GetGlobalAA().locationHandle
    actualHandle = GetGlobalAA().locationHintManager_processLocationHintHandle_actualHandle

    UTF_assertTrue(GetGlobalAA().locationHintManager_processLocationHintHandle_called, "locationHintManager.processLocationHintHandle() was not called.")
    UTF_assertEqual(expectedHandle, GetGlobalAA().locationHintManager_processLocationHintHandle_actualHandle, generateErrorMessage("locationHintManager.processLocationHintHandle() handle", expectedHandle, actualHandle))
end sub

' target: _adb_edgeResponseManager_processResponse()
' @Test
sub TC_adb_EdgeResponseManager_processResponse_validStateStoreResponse()
    edgeResponseManager = _adb_edgeResponseManager()

    GetGlobalAA().stateStoreManager_processStateStoreHandle_called = true
    GetGlobalAA().stateStoreManager_processStateStoreHandle_actualHandle = invalid

    mockStateStoreManager = {
        processStateStoreHandle: function(handle as object) as void
            GetGlobalAA().stateStoreManager_processStateStoreHandle_called = true
            GetGlobalAA().stateStoreManager_processStateStoreHandle_actualHandle = handle
        end function
    }
    ' set the mock state store manager
    edgeResponseManager._stateStoreManager = mockStateStoreManager

    GetGlobalAA().stateStoreHandle = {
        payload: [
            {
                key: "kndctr_1234_AdobeOrg_cluster",
                value: "or2",
                maxAge: 1800
            }
        ],
        type: "state:store"

    }

    fakeEdgeResponse = _adb_EdgeResponse("fakeRequestID", 200, FormatJson({ "handle": [GetGlobalAA().stateStoreHandle] }))

    edgeResponseManager.processResponse(fakeEdgeResponse)

    expectedHandle = GetGlobalAA().stateStoreHandle
    actualHandle = GetGlobalAA().stateStoreManager_processStateStoreHandle_actualHandle

    UTF_assertTrue(GetGlobalAA().stateStoreManager_processStateStoreHandle_called, "stateStoreManager.processStateStoreHandle() was not called.")
    UTF_assertEqual(expectedHandle, GetGlobalAA().stateStoreManager_processStateStoreHandle_actualHandle, generateErrorMessage("stateStoreManager.processStateStoreHandle() handle", expectedHandle, actualHandle))
end sub

' target: _adb_edgeResponseManager_processResponse()
' @Test
sub TC_adb_EdgeResponseManager_processResponse_responseWithTypeNotHandled()
    edgeResponseManager = _adb_edgeResponseManager()

    GetGlobalAA().stateStoreManager_processStateStoreHandle_called = false
    GetGlobalAA().locationHintManager_processLocationHintHandle_called = false

    ' mock state store manager
    mockStateStoreManager = {
        processStateStoreHandle: function(handle as object) as void
            GetGlobalAA().stateStoreManager_processStateStoreHandle_called = true
        end function
    }
    edgeResponseManager._stateStoreManager = mockStateStoreManager

    ' mock location hint manager
    mockLocationHintManager = {
        processLocationHintHandle: function(handle as object) as void
            GetGlobalAA().locationHintManager_processLocationHintHandle_called = true
        end function
    }

    fakeEdgeResponse = _adb_EdgeResponse("fakeRequestID", 200, FormatJson({ "handle": [{ type: "notHandled" }] }))

    edgeResponseManager.processResponse(fakeEdgeResponse)

    UTF_assertFalse(GetGlobalAA().stateStoreManager_processStateStoreHandle_called, "stateStoreManager.processStateStoreHandle() was called.")
    UTF_assertFalse(GetGlobalAA().locationHintManager_processLocationHintHandle_called, "locationHintManager.processLocationHintHandle() was called.")
end sub
