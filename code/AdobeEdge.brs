function AdobeSDK() as object
    if GetGlobalAA().AdobeSDKInstance = invalid then
        print "AdobeSDKInit() is not called"
        return invalid
    end if
    return GetGlobalAA().AdobeSDKInstance
end function

function AdobeSDKInit(configuration as object, ecid = "" as string) as object
    task = GetGlobalAA().AdbTask
    if task = invalid then
        task = CreateObject("roSGNode", "AdobeEdgeTask")
        GetGlobalAA().AdbTask = task
    end if
    instance = GetGlobalAA().AdobeSDKInstance
    if instance = invalid then
        instance = {

        }
        GetGlobalAA().AdobeSDKInstance = instance
    end if
    return GetGlobalAA().AdobeSDKInstance
end function
