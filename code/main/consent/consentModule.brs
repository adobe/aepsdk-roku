' ********************** Copyright 2024 Adobe. All rights reserved. **********************
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

' ************************************ MODULE: Consent ***************************************

function _adb_isConsentModule(module as object) as boolean
    return (module <> invalid and module.type = "com.adobe.module.consent")
end function

function _adb_ConsentModule(consentState as object, edgeModule as object) as object
    if not _adb_isConsentStateModule(consentState) then
        _adb_logError("ConsentModule::_adb_ConsentModule() - consentState is not valid.")
        return invalid
    end if

    if not _adb_isEdgeModule(edgeModule) then
        _adb_logError("ConsentModule::_adb_ConsentModule() - edgeModule is not valid.")
        return invalid
    end if

    module = _adb_AdobeObject("com.adobe.module.consent")
    module.Append({
        _CONSENT_REQUEST_PATH: "/v1/privacy/set-consent",
        _HANDLE_TYPE_CONSENT_PREFERENCES: "consent:preferences",
        _REQUEST_TYPE_CONSENT: "consent",
        _edgeModule: edgeModule,
        _consentState: consentState,

        ' setConsent API triggers this API to queue edge requests
        ' event: event generated by the public API with consent data
        processEvent: function(event as object) as void
            _adb_logVerbose("ConsentModule::processEvent() - Received event:(" + chr(10) + FormatJson(event) + chr(10) + ")")

            requestId = event.uuid
            eventData = event.data
            timestampInMillis = event.timestampInMillis

            _adb_logDebug("ConsentModule::processEvent() - Sending consent request with data: (" + FormatJson(eventData) + ").")
            m._edgeModule.queueEdgeRequest(requestId, eventData, timestampInMillis, {}, m._CONSENT_REQUEST_PATH, m._REQUEST_TYPE_CONSENT)
        end function,

        ' Processes edge response events dispatched by the event processor
        ' Sets the collect consent based on the edge response
        processResponseEvent: function(event as object) as void
            _adb_logVerbose("ConsentModule::processResponseEvent() - Received response event:(" + chr(10) + FormatJson(event) + chr(10) + ")")

            if _adb_isEdgeResponseEvent(event) then
                try
                    eventData = event.data
                    if _adb_isEmptyOrInvalidMap(eventData)
                        _adb_logWarning("ConsentModule::processResponseEvent() - Invalid eventData in the edge response.")
                        return
                    end if

                    responseString = eventData.message
                    if _adb_isEmptyOrInvalidString(responseString)
                        _adb_logWarning("ConsentModule::processResponseEvent() - Invalid responseString in the edge response.")
                        return
                    end if

                    responseObj = ParseJson(responseString)

                    ''' process the response handles
                    if not _adb_isEmptyOrInvalidArray(responseObj.handle) then
                        m._processEdgeResponseHandles(responseObj.handle)
                    end if
                catch exception
                    _adb_logError(" - Failed to process the edge response, the exception message: " + exception.Message)
                end try
            end if
        end function,

        _processEdgeResponseHandles: function(handles as object) as void
            for each handle in handles
                if _adb_isEmptyOrInvalidMap(handle)
                    continue for
                end if

                if not _adb_stringEqualsIgnoreCase(handle.type, m._HANDLE_TYPE_CONSENT_PREFERENCES)
                    continue for
                end if

                payload = handle.payload[0]
                if _adb_isEmptyOrInvalidMap(payload)
                    continue for
                end if

                collectPayload = payload.collect
                if _adb_isEmptyOrInvalidMap(collectPayload)
                    continue for
                end if

                collectConsentValue = collectPayload.val

                _adb_logDebug("ConsentModule::_processEdgeResponseHandles() - Updating collect consent value to (" + FormatJson(collectConsentValue) + ").")
                m._consentState.setCollectConsent(collectConsentValue)
            end for
        end function,

        _extractCollectConsentValue: function(eventData as object) as dynamic
            collectConsentValue = invalid
            if _adb_isEmptyOrInvalidMap(eventData) then
                return collectConsentValue
            end if

            consents = eventData["consent"]
            if _adb_isEmptyOrInvalidArray(consents) then
                return collectConsentValue
            end if

            for each consent in consents
                if _adb_isEmptyOrInvalidMap(consent) then
                    continue for
                end if

                if _adb_isEmptyOrInvalidMap(consent.value) then
                    continue for
                end if

                if _adb_isEmptyOrInvalidMap(consent.value.collect) then
                    continue for
                end if

                collectConsentValue = consent.value.collect.val
            end for

            return collectConsentValue
        end function,

        dump: function() as object
            return {

            }
        end function
    })
    return module
end function
