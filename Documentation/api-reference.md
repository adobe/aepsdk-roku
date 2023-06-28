# Roku SDK API Usage

This document lists the APIs provided by Adobe Roku SDK, along with sample code snippets on how to properly use the APIs.

- [AdobeSDKInit](#AdobeSDKInit)
- [getVersion](#getVersion)
- [setLogLevel](#setLogLevel)
- [updateConfiguration](#updateConfiguration)
- [sendEdgeEvent](#sendEdgeEvent)
- [resetIdentities](#resetIdentities)
- [(optional) setExperienceCloudId](#setExperienceCloudId)
- [shutdown](#shutdown)

---

### AdobeSDKInit

Initialize the Adobe SDK and return the public API instance. `*` The following variables are reserved to hold SDK instances in GetGlobalAA():

- `GetGlobalAA()._adb_public_api`
- `GetGlobalAA()._adb_edge_task_node`
- `GetGlobalAA()._adb_serviceProvider_instance`

##### Syntax

```brightscript
function AdobeSDKInit() as object
```

- `@return instance as object : public API instance`

##### Example

```brightscript
m.adobeEdgeSdk = AdobeSDKInit()
```

---

### getVersion

##### Syntax

```brightscript
getVersion: function() as string
```

- `@return version as string`

##### Example

```brightscript
sdkVersion = m.adobeEdgeSdk.getVersion()
```

---

### setLogLevel

##### Syntax

```brightscript
setLogLevel: function(level as integer) as void
```

- `@param level as integer : the accepted values are (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)`

##### Example

```brightscript
ADB_CONSTANTS = AdobeSDKConstants()
m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)
```

---

### updateConfiguration

> It is better to call this function before calling any other public APIs. For example, if calling sendEdgeEvent() without a valid configuration in the SDK, the Edge requests will be queued locally and sent out later with the valid configuration.

##### Syntax

```brightscript
updateConfiguration: function(configuration as object) as void
```

- `@param configuration as object`

##### Example

```brightscript
ADB_CONSTANTS = AdobeSDKConstants()

configuration = {}
configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = "<YOUR_CONFIG_ID>"
configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = "<YOUR_DOMAIN_NAME>"

m.adobeEdgeSdk.updateConfiguration(configuration)
```

The `EDGE_CONFIG_ID` value is presented as `Datastream ID` in the [satastream details](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/configure.html?lang=en#view-details) page.

The `EDGE_DOMAIN` value is the first-party domain mapped to the Adobe-provisioned Edge Network domain. For more information, see this [documentation](https://developer.adobe.com/client-sdks/documentation/edge-network/#domain-configuration)

---

### sendEdgeEvent

Sends an Experience event to Edge Network.

##### Syntax

```brightscript
sendEdgeEvent: function(xdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
```

- `@param data as object : xdm data following the XDM schema that is defined in the Schema Editor`
- `@param [optional] callback as function(context, result) : handle Edge response`
- `@param [optional] context as dynamic : context to be passed to the callback function`

> This function will automatically add an identity property, the Experience Cloud Identifier (ECID), to each Edge network request within the Experience event's `XDM IdentityMap`.
> Also `ImplementationDetails` are automatically collected and are sent with every Experience Event. If you would like to include this information in your dataset, add the "Implementation Details" field group to the schema tied to your dataset.

##### Example 1

```brightscript
  m.adobeEdgeSdk.sendEdgeEvent({
    "eventType": "commerce.orderPlaced",
      "commerce": {
        .....
      }
  })
```

> Identifiers are not case sensitive in [BrightScript](https://developer.roku.com/docs/references/brightscript/language/expressions-variables-types.md), so please always use the `String literals` to present the XDM data keys. 

##### Example 2

```brightscript
  m.adobeEdgeSdk.sendEdgeEvent({
      "eventType": "commerce.orderPlaced",
      "commerce": {
        .....
      }
  }, sub(context, result)
      print "callback result: "
      print result
      print context
  end sub, context)
```

---

### resetIdentities

Call this function to reset the Adobe identities such as ECID from the SDK.

##### Syntax

```brightscript
resetIdentities: function() as void
```

##### Example

```brightscript
  m.adobeEdgeSdk.resetIdentities()
```

---

### setExperienceCloudId

> Note: Please do not call this API if you do not have both the [Adobe Media SDK](https://experienceleague.adobe.com/docs/media-analytics/using/media-use-cases/sdk-track-scenegraph.html?lang=en#global-methods-for-mediaheartbeat) and the Edge SDK running in the same channel and you need to use the same ECID in both SDKs. By default, the Edge SDK automatically generates an ECID (Experience Cloud ID) when first used. If the Edge SDK and the previous media SDK are initialized in the same channel, calling this function can keep both SDKs running with the same ECID. `*` Call this function before using other public APIs. Otherwise, an automatically generated ECID will be assigned. Whenever the ECID is changed in the Media SDK, this API needs to be called to synchronize it in both SDKs.

##### Syntax

```brightscript
setExperienceCloudId: function(ecid as string) as void
```

- `@param ecid as string : the ECID generated by the previous media SDK`

##### Example

Setup Media SDK for Scenegraph APIs
```brightscript

''' Create adbmobileTask node
m.adbmobileTask = createObject("roSGNode","adbmobileTask")

''' Get AdobeMobile SG connector instance
m.adbmobile = ADBMobile().getADBMobileConnectorInstance(m.adbmobileTask)

''' Get AdobeMobile SG constants
m.adbmobileConstants = m.adbmobile.sceneGraphConstants()

''' Register callback for receiving API responses
m.adbmobileTask.ObserveField(m.adbmobileConstants.API_RESPONSE, "onAdbmobileApiResponse")
```

Get ECID from Media SDK and set it with AdobeEdge SDK

```brightscript
m.adbmobile.visitorMarketingCloudID()


''' Listen ECID response from Media SDK and set it on AdobeEdge SDK
function onAdbmobileApiResponse() as void
      responseObject = m.adbmobileTask[m.adbmobileConstants.API_RESPONSE]

      if responseObject <> invalid
        methodName = responseObject.apiName
        ecid_from_media_sdk = responseObject.returnValue

        if methodName = m.adbmobileConstants.VISITOR_MARKETING_CLOUD_ID
          if ecid_from_media_sdk <> invalid
            print "API Response: ECID: " + ecid_from_media_sdk

            ''' AdobeEdgeSDK setECID()
            m.adobeEdgeSdk.setExperienceCloudId(ecid_from_media_sdk)
          else
            print "API Response: ECID: " + "invalid"
          endif
        endif
      endif
    end function
```

---

### shutdown

Call this function to shut down the SDK and drop further API calls.

##### Syntax

```brightscript
shutdown: function() as void
```

##### Example

```brightscript
m.adobeEdgeSdk.shutdown();
```
