' ********************** Copyright 2022 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


' Return the Adobe SDK constants

function AdobeSDKConstants() as object
    return {
        CONFIGURATION: {
            CONFIG_ID: "configId",
            EDGE_DOMAIN: "edgeDomain",
            EDGE_ENVIRONMENT: "edgeEnvironment",
        },
        LOG_LEVEL: {
            VERBOSE: 0,
            DEBUG: 1,
            INFO: 2,
            WARNING: 3,
            ERROR: 4
        },
    }
end function


' *****************************************************************************
'
' Initialize the Adobe SDK and return the public API instance.
' The following variables are reserved to hold SDK instances in GetGlobalAA():
'   - GetGlobalAA()._adb_public_api
'   - GetGlobalAA()._adb_edge_task_node
'
' @param configuration as object      : configuration for the SDK
' @param (optional) ecid as string    : experience cloud id
' @return instance as object          : public API instance
'
'
' Example:
'
' config = {
'   edge = {
'     configId: "0123456789"
'   }
' }
' m.adobeEdgeSdk = AdobeSDKInit(config)
'
' *****************************************************************************

function AdobeSDKInit(configuration as object, ecid = "" as string) as object
    ' create the edge task node
    if GetGlobalAA()._adb_edge_task_node = invalid then
        edgeTask = CreateObject("roSGNode", "AdobeEdgeTask")
        if edgeTask = invalid then
            print "AdobeSDKInit() failed"
            return invalid
        end if
        GetGlobalAA()._adb_edge_task_node = edgeTask
    end if
    ' create the public API instance
    if GetGlobalAA()._adb_public_api = invalid then
        GetGlobalAA()._adb_public_api = {

            ' ********************************
            '
            ' Return SDK version
            '
            ' @return version as string
            '
            ' ********************************

            getVersion: function() as string
                return m._adb_internal.internalConstants.VERSION
            end function,

            ' ********************************************************************************************************
            '
            ' Set log level
            '
            ' @param level as integer : the accepted values are (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
            '
            ' Example:
            '
            ' ADB_CONSTANTS = AdobeSDKConstants()
            ' m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)
            '
            ' ********************************************************************************************************

            setLogLevel: function(level as integer) as void
                print "setDebugLogging"
            end function,

            ' ********************************
            '
            ' Shut down the SDK
            '
            ' ********************************

            shutdown: function() as void
                print "shutdown"
            end function,

            ' *************************************************************************************
            '
            ' Send edge event
            '
            ' @param data as object : xdm data
            ' @param [optional] callback as function(context, result) : handle Edge response
            ' @param [optional] context as dynamic : context to be passed to the callback function
            '
            ' Example 1:
            '
            ' m.adobeEdgeSdk.sendEdgeEvent({
            '   eventType: "commerce.orderPlaced",
            '   commerce: {
            '      .....
            '   }
            ' })
            '
            ' Example 2:
            '
            ' m.adobeEdgeSdk.sendEdgeEventWithCallback({
            '     eventType: "commerce.orderPlaced",
            '     commerce: {
            '        .....
            '     }
            '   }, sub(context, result)
            '     print "callback result: "
            '     print result
            '     print context
            '   end sub, context)
            '
            ' *************************************************************************************

            sendEdgeEvent: function(xdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
                print "sendEdgeEvent"
            end function,

            ' ********************************************************************
            '
            ' Update identities
            '
            ' @param identities as object : xmd identity map
            '
            ' Example:
            '
            ' m.adobeEdgeSdk.updateIdentities({
            '   Email: [
            '     {
            '       id: "user@example.com",
            '       authenticatedState: "authenticated",
            '       primary: false
            '     }
            '   ]
            ' })
            ' ********************************************************************

            updateIdentities: function(identities as object) as void
                print "updateIdentities"
                print identities
            end function,
            
            ' **********************************************************************
            '
            ' This is used to set the advertising identifier for the SDK
            '
            ' @param advertisingIdentifier as string : the advertising identifier
            '
            ' **********************************************************************
            
            setAdvertisingIdentifier: function(advertisingIdentifier as string) as void
                print "setAdvertisingIdentifier"
                print advertisingIdentifier
            end function,

            ' ********************************
            '
            ' Update configuration
            '
            ' @param configuration as object
            '
            ' ********************************

            updateConfiguration: function(configuration as object) as void
                print "updateConfiguration"
            end function,
        }
    end if

    ' start the event loop on task node
    GetGlobalAA()._adb_edge_task_node.control = "RUN"
    _adb_public_api = GetGlobalAA()._adb_public_api
    ' set ecid if provided
    if ecid.len() > 0
        _adb_public_api._adb_internal.setExperienceCloudId(ecid)
    end if

    ' set configuration
    _adb_public_api.setConfiguration(configuration)

    return GetGlobalAA()._adb_public_api
end function
