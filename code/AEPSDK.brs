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

' *********************************** MODULE: public API **********************************

' Return the Adobe SDK constants

function AdobeAEPSDKConstants() as object
    return {
        CONFIGURATION: {
            EDGE_CONFIG_ID: "edge.configId",
            EDGE_DOMAIN: "edge.domain",
            MEDIA_CHANNEL: "edgemedia.channel",
            MEDIA_PLAYER_NAME: "edgemedia.playerName",
            MEDIA_APP_VERSION: "edgemedia.appVersion",
        },
        LOG_LEVEL: {
            VERBOSE: 0,
            DEBUG: 1,
            INFO: 2,
            WARNING: 3,
            ERROR: 4
        }
    }
end function

' *****************************************************************************
'
' Initialize the Adobe SDK and return the public API instance.
' The following variables are reserved to hold SDK instances in GetGlobalAA():
'   - GetGlobalAA()._adb_public_api
'   - GetGlobalAA()._adb_main_task_node
'   - GetGlobalAA()._adb_serviceProvider_instance
'
' @return instance as object : public API instance
'
' *****************************************************************************

function AdobeAEPSDKInit() as object

    if GetGlobalAA()._adb_public_api <> invalid then
        _adb_logInfo("AdobeAEPSDKInit() - Unable to initialize a new SDK instance as there is an existing active instance. Call shutdown() API for existing instance before initializing a new one.")
        return GetGlobalAA()._adb_public_api
    end if

    _adb_logDebug("AdobeAEPSDKInit() - Initializing the SDK.")

    ' create the SDK thread
    _adb_createTaskNode()

    if _adb_retrieveTaskNode() = invalid then
        _adb_logDebug("AdobeAEPSDKInit() - Failed to initialize the SDK, task node is invalid.")
        return invalid
    end if

    ' listen response events
    _adb_observeTaskNode("responseEvent", "_adb_handleResponseEvent")

    GetGlobalAA()._adb_public_api = {

        ' ********************************
        '
        ' Return SDK version
        '
        ' @return version as string
        '
        ' ********************************

        getVersion: function() as string
            return _adb_sdkVersion()
        end function,

        ' ********************************************************************************************************
        '
        ' Set log level
        '
        ' @param level as integer : the accepted values are (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
        '
        ' ********************************************************************************************************

        setLogLevel: function(level as integer) as void
            _adb_logDebug("API: setLogLevel()")
            if(level < 0 or level > 4) then
                _adb_logError("setLogLevel() - Invalid log level:(" + StrI(level) + ").")
                return
            end if
            ' event data: { "level": level }
            data = {}
            data[m._private.cons.EVENT_DATA_KEY.LOG.LEVEL] = level

            event = _adb_RequestEvent(m._private.cons.PUBLIC_API.SET_LOG_LEVEL, data)
            m._private.dispatchEvent(event)
        end function,

        ' ***********************************************************************
        '
        ' Call this function to shutdown the SDK and drop the further API calls.
        '
        ' ***********************************************************************

        shutdown: function() as void
            _adb_logDebug("API: shutdown()")

            if GetGlobalAA()._adb_public_api <> invalid then
                ' stop the task node
                _adb_stopTaskNode()
                ' clear the cached callback functions
                m._private.cachedCallbackInfo = {}
                ' clear the global reference
                GetGlobalAA()._adb_public_api = invalid
            end if

        end function,

        ' ***********************************************************************
        '
        ' Call this function to reset the Adobe identities such as ECID from the SDK.
        '
        ' ***********************************************************************

        resetIdentities: function() as void
            _adb_logDebug("API: resetIdentities()")
            event = _adb_RequestEvent(m._private.cons.PUBLIC_API.RESET_IDENTITIES, invalid)
            m._private.dispatchEvent(event)
        end function,

        ' **********************************************************************************
        '
        ' Call this function before using any other public APIs.
        ' For example, if calling sendEvent() without a valid configuration in the SDK,
        ' the SDK will drop the Edge event.
        '
        ' @param configuration as object
        '
        ' **********************************************************************************

        updateConfiguration: function(configuration as object) as void
            _adb_logDebug("API: updateConfiguration()")
            if _adb_isEmptyOrInvalidMap(configuration) then
                _adb_logError("updateConfiguration() - Cannot update configuration as the configuration is invalid.")
                return
            end if
            event = _adb_RequestEvent(m._private.cons.PUBLIC_API.SET_CONFIGURATION, configuration)
            m._private.dispatchEvent(event)
        end function,

        ' *************************************************************************************
        '
        ' Send event.
        '
        ' This function will automatically add an identity property, the Experience Cloud Identifier (ECID),
        ' to each Edge network request within the Experience event's "XDM IdentityMap".
        ' Also "ImplementationDetails" are automatically collected and are sent with every Experience Event.
        ' If you would like to include this information in your dataset, add the "Implementation Details"
        ' field group to the schema tied to your dataset.
        '
        ' This function allows passing custom identifiers using identityMap.
        '
        ' @param data as object : xdm data
        ' @param [optional] callback as function(context, result) : handle Edge response
        ' @param [optional] context as dynamic : context to be passed to the callback function
        '
        ' *************************************************************************************

        sendEvent: function(xdmData as object, callback = _adb_defaultCallback as function, context = invalid as dynamic) as void
            _adb_logDebug("API: sendEvent()")
            if _adb_isEmptyOrInvalidMap(xdmData) then
                _adb_logError("sendEvent() - Cannot send event, invalid XDM data")
                return
            end if
            ' event data: { "xdm": xdmData }
            ' add a timestamp to the XDM data
            xdmData.timestamp = _adb_ISO8601_timestamp()
            event = _adb_RequestEvent(m._private.cons.PUBLIC_API.SEND_EDGE_EVENT, {
                xdm: xdmData,
            })

            ' event.data.xdm.timestamp = event.getISOTimestamp()
            if callback <> _adb_defaultCallback then
                ' store callback function
                callbackInfo = {
                    cb: callback,
                    context: context,
                    timestampInMillis: event.timestampInMillis
                }
                m._private.cachedCallbackInfo[event.uuid] = callbackInfo
                _adb_logDebug("sendEvent() - Cached callback function for event with uuid: " + FormatJson(event.uuid))
            end if
            m._private.dispatchEvent(event)
        end function,

        ' ****************************************************************************************************
        '
        ' Note: Please do not call this API if you do not have both the Adobe Media SDK and the Edge SDK
        ' running in the same channel and you need to use the same ECID in both SDKs.
        '
        ' By default, the Edge SDK automatically generates an ECID (Experience Cloud ID) when first used.
        ' If the Edge SDK and the previous media SDK are running in the same channel, calling this function
        ' can keep both SDKs running with the same ECID.
        '
        ' Call this function before using other public APIs. Otherwise, an automatically generated ECID will be assigned.
        ' Whenever the ECID is changed in the Media SDK, this API needs to be called to synchronize it in both SDKs.
        '
        ' @param ecid as string : the ECID generated by the previous media SDK
        '
        ' ****************************************************************************************************

        setExperienceCloudId: function(ecid as string) as void
            _adb_logDebug("API: setExperienceCloudId()")
            if _adb_isEmptyOrInvalidString(ecid)
                _adb_logError("setExperienceCloudId() - Cannot set ECID, invalid ecid:(" + FormatJson(ecid) + ") passed.")
                return
            end if
            ' event data: { "ecid": ecid }
            data = {}
            data[m._private.cons.EVENT_DATA_KEY.ecid] = ecid
            event = _adb_RequestEvent(m._private.cons.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID, data)
            m._private.dispatchEvent(event)
        end function,

        ' ****************************************************************************************************
        '
        ' Call this function to start a new Media session with the given XDM data. The XDM data must be the type
        ' of "media.sessionStart".
        ' If the "playerName", "channel", and "appVersion" are not provided in the XDM data, the SDK will use
        ' the global values passed via "updateConfiguration" API.
        '
        ' @param xdmData as object : the XDM data of type "media.sessionStart"
        '
        ' ****************************************************************************************************
        ' TODO: we're discussing the possibility of adding another parameter to this API for passing the per-session configuration
        ' For example: createMediaSession: function(xdmData as object, configuration = {} as object) as void
        createMediaSession: function(xdmData as object) as void
            _adb_logDebug("API: _createMediaSession()")

            if not _adb_isValidMediaXDMData(xdmData)
                _adb_logError("createMediaSession() - Cannot create media session, invalid XDM data")
                return
            end if


            ' TODO: print error message if the previsou session is not ended.

            m._private._currentPlayHead = 0
            m._private.mediaSession.startNewSession()
            m.sendMediaEvent(xdmData)

        end function,

        ' ****************************************************************************************************
        '
        ' Before calling this function to send a Media event with the given XDM data, it's required to call the
        ' "createMediaSession" API to start a new session.
        '
        ' @param xdmData as object : the XDM data of the Media event
        '
        ' ****************************************************************************************************
        sendMediaEvent: function(xdmData as object) as void
            _adb_logDebug("API: _sendMediaEvent()")

            if not m._private.mediaSession.isInValidSession()
                _adb_logError("sendMediaEvent() - Cannot send media event, not in a valid media session. Call createMediaSession() API to start a new session.")
                return
            end if

            if not _adb_isValidMediaXDMData(xdmData)
                _adb_logError("sendMediaEvent() - Cannot send media event, invalid XDM data")
                return
            end if

            timestamp = _adb_ISO8601_timestamp()
            sessionId = m._private.mediaSession.getClientSessionIdAndRecordAction(xdmData.xdm.eventType, timestamp, xdmData)

            data = {
                clientSessionId: sessionId,
                timestampInISO8601: timestamp,
                param: xdmData
            }
            event = _adb_RequestEvent(m._private.cons.PUBLIC_API.SEND_MEDIA_EVENT, data)
            m._private.dispatchEvent(event)

            if xdmData.xdm.eventType = "media.sessionEnd"
                m._private.mediaSession.endSession()
            end if
        end function,

        ' ********************************
        ' Add private memebers below
        ' ********************************
        _private: {
            mediaSession: _adb_ClientMediaSession(),
            ' constants
            cons: _adb_InternalConstants(),
            ' for testing purpose
            lastEventId: invalid,
            ' dispatch events to the task node
            dispatchEvent: function(event as object) as void
                _adb_logDebug("dispatchEvent() - Dispatching event:(" + FormatJson(event) + ")")
                taskNode = _adb_retrieveTaskNode()
                if taskNode = invalid then
                    _adb_logDebug("dispatchEvent() - Cannot dispatch public API event after shutdown(). Please initialze the SDK using AdobeAEPSDKInit() API.")
                    return
                end if

                taskNode[m.cons.TASK.REQUEST_EVENT] = event
                m.lastEventId = event.uuid
            end function,

            ' API callbacks to be called later
            ' CallbackInfo = {cb: function, context: dynamic}
            cachedCallbackInfo: {},
        }

    }

    ' start the event loop on the SDK thread
    _adb_startTaskNode()

    _adb_logDebug("AdobeAEPSDKInit() - Successfully initialized the SDK")
    return GetGlobalAA()._adb_public_api
end function

' ****************************************************************************************************************************************
'                                              Below functions are for internal use only
' ****************************************************************************************************************************************

function _adb_defaultCallback(_context, _result) as void
end function

function _adb_isValidMediaXDMData(xdmData as object) as boolean
    ' TODO: validate the XDM data against the schema or ????
    return true
end function

function _adb_ClientMediaSession() as object
    return {
        _clientSessionId: invalid,
        _trackActionQueue: [],
        _currentPlayHead: 0,

        startNewSession: function() as string
            m._clientSessionId = _adb_generate_UUID()
            m._trackActionQueue = []
            return m._clientSessionId
        end function,

        isInValidSession: function() as boolean
            return m._clientSessionId <> invalid
        end function,

        endSession: sub()
            m._clientSessionId = invalid

            lines = []
            lines.Push("***************************************************************")
            lines.Push("*  The media session is ended, the events are recorded below  *")
            lines.Push("***************************************************************")
            for each obj in m._trackActionQueue
                lines.Push("action: " + obj.action + ", timestamp: " + obj.timestamp + ", param: " + FormatJson(obj.param))
            end for
            output = lines.Join(chr(10))
            _adb_logVerbose(output)
            m._trackActionQueue = []
        end sub,

        getClientSessionIdAndRecordAction: function(action as string, timestamp = "" as string, param = {} as object) as string
            m._trackActionQueue.Push({
                action: action,
                timestamp: timestamp,
                param: param
            })
            return m._clientSessionId
        end function,

    }
end function


' ********** response event observer **********
function _adb_handleResponseEvent() as void
    sdk = GetGlobalAA()._adb_public_api
    if sdk <> invalid then
        ' remove timeout callbacks
        timeout_ms = sdk._private.cons.CALLBACK_TIMEOUT_MS
        current_time = _adb_timestampInMillis()
        for each key in sdk._private.cachedCallbackInfo
            cachedCallback = sdk._private.cachedCallbackInfo[key]

            if cachedCallback <> invalid and ((current_time - cachedCallback.timestampInMillis) > timeout_ms)
                sdk._private.cachedCallbackInfo.Delete(key)
            end if
        end for

        taskNode = _adb_retrieveTaskNode()
        if taskNode = invalid then
            return
        end if
        responseEvent = taskNode[sdk._private.cons.TASK.RESPONSE_EVENT]
        if responseEvent <> invalid
            uuid = responseEvent.parentId

            _adb_logDebug("_adb_handleResponseEvent() - Received response event:" + FormatJson(responseEvent) + " with uuid:" + FormatJson(uuid))
            if sdk._private.cachedCallbackInfo[uuid] <> invalid
                context = sdk._private.cachedCallbackInfo[uuid].context
                sdk._private.cachedCallbackInfo[uuid].cb(context, responseEvent.data)
                sdk._private.cachedCallbackInfo.Delete(uuid)
            else
                _adb_logDebug("_adb_handleResponseEvent() - Not handling response event, callback not passed with the request event.")
            end if
        else
            _adb_logError("_adb_handleResponseEvent() - Failed to handle response event, response event is invalid")
        end if
    else
        _adb_logError("_adb_handleResponseEvent() - Failed to handle response event, SDK instance is invalid")
    end if
end function
' *********************************************

