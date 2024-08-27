' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_EdgeModule()
' @Test
sub TC_adb_EdgeModule_init()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)
    UTF_assertTrue(_adb_isEdgeModule(edgeModule))

    edgeModule = _adb_EdgeModule(configurationModule, invalid, consentState)
    UTF_assertInvalid(edgeModule)

    edgeModule = _adb_EdgeModule(invalid, identityModule, consentState)
    UTF_assertInvalid(edgeModule)

    edgeModule = _adb_EdgeModule(configurationModule, identityModule, invalid)
    UTF_assertInvalid(edgeModule)

    edgeModule = _adb_EdgeModule(invalid, invalid, invalid)
    UTF_assertInvalid(edgeModule)
end sub

' target: processEvent()
' @Test
sub TC_adb_EdgeModule_processEvent()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)

    timestampInMillis& = _adb_timestampInMillis()
    edgeModule.processEvent("request_id", { key: "value" }, timestampInMillis&)

    queue = edgeModule._edgeRequestWorker._queue
    UTF_assertEqual(1, queue.Count())
    UTF_assertEqual("request_id", queue[0].getRequestId())
    UTF_assertEqual({ key: "value" }, queue[0].getEventData())
    UTF_assertEqual(timestampInMillis&, queue[0].getTimestampInMillis())
end sub

' target: processQueuedRequests()
' @Test
sub TC_adb_EdgeModule_processQueuedRequests()
    configurationModule = _adb_ConfigurationModule()
    consentState = _adb_ConsentState(configurationModule)
    identityModule = _adb_IdentityModule(configurationModule, consentState)
    edgeModule = _adb_EdgeModule(configurationModule, identityModule, consentState)

    edgeModule._getEdgeConfig = function() as object
        return {
            configId: "config_id",
            ecid: "ecid",
            edgeDomain: invalid
        }
    end function

    edgeModule._edgeRequestWorker.hasQueuedEvent = function() as boolean
        return true
    end function

    edgeModule._edgeRequestWorker.processRequests = function(_edgeConfig as object) as dynamic
        array = []
        array.Push(_adb_EdgeResponse("request_id", 200, "response_body"))
        return array
    end function

    result = edgeModule.processQueuedRequests()
    UTF_assertTrue(_adb_isArray(result))
    UTF_assertEqual(1, result.Count())
    UTF_assertTrue(_adb_isResponseEvent(result[0]))
    UTF_assertEqual("request_id", result[0].parentId)
    UTF_assertEqual({ code: 200, message: "response_body" }, result[0].data)

end sub
