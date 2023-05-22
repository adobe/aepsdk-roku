
function AdobeSDKConstants() as object
    return {
        VERSION: "1.0.0-alpha.1",
        PUBLIC_API: {
            SET_CONFIGURATION: "setConfiguration",
            GET_IDENTIFIERS: "getIdentifiers",
            SET_IDENTIFIER: "setIdentifier",
            SET_EXPERIENCE_CLOUD_ID: "setExperienceCloudId",
            SYNC_IDENTIFIERS: "syncIdentifiers",
            SEND_EDGE_EVENT: "sendEdgeEvent",
            SEND_EDGE_EVENT_WITH_CALLBACK: "sendEdgeEventWithCallback",
            SHUTDOWN: "shutdown",
        },
        TASK: {
            REQUEST_EVENT: "requestEvent",
            RESPONSE_EVENT: "responseEvent",
        },
    }
end function

function AdobeSDK() as object
    if GetGlobalAA().AdobeSDKInstance = invalid then
        print "AdobeSDKInit() is not called"
        return invalid
    end if
    return GetGlobalAA().AdobeSDKInstance
end function

function AdobeEvent(apiName as string, data = invalid as dynamic) as object
    instance = {
        uuid: invalid,
        apiName: apiName,
        data: data,
    }
    instance.uuid = CreateObject("roDeviceInfo").GetRandomUUID()
    return instance
end function


function AdobeSDKInit(configuration as object, ecid = "" as string) as object
    ' m.AdbTask = CreateObject("roSGNode", "AdobeEdgeTask")
    '   adobeSDKInstance = AdobeSDKInit(m.AdbTask)
    task = GetGlobalAA().AdbTask
    if task = invalid then
        task = CreateObject("roSGNode", "AdobeEdgeTask")
        GetGlobalAA().AdbTask = task
    end if
    instance = GetGlobalAA().AdobeSDKInstance
    if instance = invalid then
        instance = {
            ' constants
            ADB_CONSTANTS: AdobeSDKConstants(),
            ' return SDK version
            getVersion: function() as string
                return ADB_CONSTANTS.VERSION
            end function,
            ' set configuration
            setConfiguration: function(config as object) as void
                print "setConfiguration"
                event = AdobeEvent(m.ADB_CONSTANTS.PUBLIC_API.SET_CONFIGURATION, config)
                m._adb_dispatchEvent(event)
            end function,
            ' retrieve identifiers
            getIdentifiers: function(callback as function, context = invalid as dynamic) as void
                event = AdobeEvent(m.ADB_CONSTANTS.PUBLIC_API.GET_IDENTIFIERS, {})
                ' store callback function
                callbackInfo = {}
                callbackInfo.cb = callback
                callbackInfo.context = context
                m._adb_callbacks[event.uuid] = callbackInfo
                ' send event
                m._adb_dispatchEvent(event)
            end function,
            ' set experience cloud id
            setExperienceCloudId: function(ecid as string) as void
                print "setExperienceCloudId"
                data = {}
                data.ecid = ecid
                event = AdobeEvent(m.ADB_CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID, data)
                m._adb_dispatchEvent(event)
            end function
            ' set identifier
            setIdentifier: function(identifier as string) as void
                print "setIdentifier"
                data = {}
                data.identifier = identifier
                event = AdobeEvent(m.ADB_CONSTANTS.PUBLIC_API.SET_IDENTIFIER, data)
                m._adb_dispatchEvent(event)
            end function,
            ' send edge event
            sendEdgeEvent: function(data as object) as void
                print "sendEdgeEvent"
                event = AdobeEvent(m.ADB_CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT, data)
                m._adb_dispatchEvent(event)
            end function,
            ' send edge event with callback
            sendEdgeEventWithCallback: function(callback as function, context = invalid as dynamic) as void
                print "sendEdgeEventWithCallback"
                event = AdobeEvent(m.ADB_CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT_WITH_CALLBACK, data)
                ' store callback function
                callbackInfo = {}
                callbackInfo.cb = callback
                callbackInfo.context = context
                m._adb_callbacks[event.uuid] = callbackInfo
                ' send event
                m._adb_dispatchEvent(event)
            end function,
            ' ---------------------------
            ' Add private memebers below
            ' ---------------------------
            ' private function
            _adb_dispatchEvent: function(event as object) as void
                print "dispatchEvent"
                m._adb_task[m.ADB_CONSTANTS.TASK.REQUEST_EVENT] = event
            end function,
            ' private memeber
            _adb_task: GetGlobalAA().AdbTask,
            ' private memeber
            _adb_callbacks: {},
            ' private memeber
            _adb_configuration: {}

        }
        GetGlobalAA().AdobeSDKInstance = instance
        task.observeField("responseEvent", "_adb_handle_response_event")
        ' task.addFields({ AdobeSDKInstance: instance })
    end if
    if ecid.len() > 0
        instance.setExperienceCloudId(ecid)
    end if
    instance.setConfiguration(configuration)
    return GetGlobalAA().AdobeSDKInstance
end function

function _adb_handle_response_event() as void
    sdk = GetGlobalAA().AdobeSDKInstance
    if sdk <> invalid then
        responseEvent = sdk._adb_task["responseEvent"]
        if responseEvent <> invalid
            print "responseEvent:"
            print responseEvent
            uuid = responseEvent.uuid
            if sdk._adb_callbacks[uuid] <> invalid
                context = sdk._adb_callbacks[uuid].context
                sdk._adb_callbacks[uuid].cb(context, responseEvent)
                sdk._adb_callbacks[uuid] = invalid
            end if
        end if
    end if
end function
