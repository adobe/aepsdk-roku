# AEP Roku SDK API Usage

This document lists the APIs provided by AEP Roku SDK, along with code samples for API usage.

- [AdobeSDKInit](#AdobeSDKInit)
- [getVersion](#getVersion)
- [setLogLevel](#setLogLevel)
- [updateConfiguration](#updateConfiguration)
- [sendEvent](#sendEvent)
- [resetIdentities](#resetIdentities)
- [(optional) setExperienceCloudId](#setExperienceCloudId)
- [shutdown](#shutdown)

---

### AdobeSDKInit

Initialize the AEP Roku SDK and return the public API instance. `*` The following variables are reserved to hold the SDK instances in GetGlobalAA():

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
m.aepSdk = AdobeSDKInit()
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
sdkVersion = m.aepSdk.getVersion()
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
m.aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)
```

---

### updateConfiguration

> **Note**
> Some public APIs need valid configuration to process the data and make the network call to Adobe Experience Edge Network. All the hits will be queued if no valid configuration is found. It is ideal to call updateConfiguration API with valid require configuration before any other public APIs.

#### Configuration Keys

| Constants | Raw value | Required |
| :-- | :--: | :--: |
| `ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID` | "edge.configId" | **Yes**
| `ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN` | "edge.domain" | **No**

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

m.aepSdk.updateConfiguration(configuration)
```

The `EDGE_CONFIG_ID` value is presented as `Datastream ID` in the [Datastream details](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/configure.html?lang=en#view-details) page.

The `EDGE_DOMAIN` value is the first-party domain mapped to the Adobe-provisioned Edge Network domain. For more information, see this [documentation](https://developer.adobe.com/client-sdks/documentation/edge-network/#domain-configuration)

---

### sendEvent

Sends an Experience event to Edge Network.

##### Syntax

```brightscript
sendEvent: function(xdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
```

- `@param data as object : xdm data following the XDM schema that is defined in the Schema Editor`
- `@param [optional] callback as function(context, result) : handle Edge response`
- `@param [optional] context as dynamic : context to be passed to the callback function`

> **Note**
> `sendEvent` API will automatically collect and attach the identities synced with the SDK and the implementation details. That data is sent as `IdentityMap` and `Implementation Details` fieldgroups under the XDM payload and are sent with every Experience Edge Event. IdentityMap is added to the schema automatically but if you would like to include ImplementationDetails information in your dataset, add the `Implementation Details` field group to the schema tied to your dataset.

#### Sample ImplementationDetails XDM:
```json
"implementationDetails": {
  "name": "https://ns.adobe.com/experience/mobilesdk/roku",
  "version": "1.0.0-alpha1",
  "environment": "app"
}
```

##### Example 1

```brightscript
  m.aepSdk.sendEvent({
    "eventType": "commerce.orderPlaced",
      "commerce": {
        .....
      }
  })
```

> Identifiers are not case sensitive in [BrightScript](https://developer.roku.com/docs/references/brightscript/language/expressions-variables-types.md), so please always use the `String literals` to present the XDM data keys.

##### Example 2

```brightscript
  m.aepSdk.sendEvent({
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

#### Example of SendEvent with IdentityMap:

> **Note**
> `sendEvent` API allows passing custom identityMap with custom identifiers to the edge network. Create the map as per the requirements,

> **Note**
> To set the idenfier as primary for profile, set the Identifier entry field `primary` to `true`. By Default `ECID` sent by the SDK is set as primary on the platform side if no other identifier is set as primary.

> **Note**
> Set the "authenticatedState" property as per the authentication status of the user. Use "ambiguous" as default if not known.

> **Warning**
> Do not pass ECID in this IdentityMap. ECID will be attached by the SDK automatically.


IdentityMap looks like this:
```brightscript
 identityMap = {
    "CustomAdvertisingIdentifier" : [
          {
                "id" : "SampleAdIdentifier",
                "authenticatedState": "ambiguous",
                "primary": false
          }
    ],
    "CustomIdentifierNamespace" : [
          {
                "id" : "CustomIdentifier1",
                "authenticatedState": "ambiguous",
                "primary": false
          },
          {
                "id" : "CustomIdentifier2",
                "authenticatedState": "ambiguous",
                "primary": false
          }
    ]
}
```

Attach the IdentityMap to your XDM data payload in the sendEvent API:
```brightscript
  m.aepSdk.sendEvent(
    {
      "eventType": "commerce.orderPlaced",
        "commerce": {
          .....
        },

      "identityMap": identitMap
  )
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
m.aepSdk.resetIdentities()
```

---

### setExperienceCloudId

> **Note**
This API is intended to sync ECID (Experience Cloud ID) from [Adobe Media SDK for Roku](https://experienceleague.adobe.com/docs/media-analytics/using/media-use-cases/sdk-track-scenegraph.html?lang=en#global-methods-for-mediaheartbeat) with AEP Roku SDK.
> By default, the AEP Roku SDK automatically generates an ECID. If the AEP Roku SDK and the Media SDK for Roku are initialized in the same channel, this API helps in syncing ECID for both the SDKs. Use this API anytime the ECID changes in the Media SDK for Roku, to sync the ECID with the AEP Roku SDK.
> `*` Call this API before using other public APIs on AEP Roku SDK. Otherwise, an automatically generated ECID will be used.

> **Warning**
> This API should only be used to share the ECID between the Adobe Media SDK and AEP Roku SDK.

##### Syntax

```brightscript
setExperienceCloudId: function(ecid as string) as void
```

- `@param ecid as string : the ECID generated by the Media SDK for Roku`

##### Example

Setup Media SDK for Roku for Scenegraph APIs
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

Get ECID from Media SDK for Roku and set it with AEP Roku SDK

```brightscript
m.adbmobile.visitorMarketingCloudID()


''' Listen ECID response from Media SDK and set it on AEP Roku SDK
function onAdbmobileApiResponse() as void
      responseObject = m.adbmobileTask[m.adbmobileConstants.API_RESPONSE]

      if responseObject <> invalid
        methodName = responseObject.apiName
        ecid_from_media_sdk = responseObject.returnValue

        if methodName = m.adbmobileConstants.VISITOR_MARKETING_CLOUD_ID
          if ecid_from_media_sdk <> invalid
            print "API Response: ECID: " + ecid_from_media_sdk

            ''' AEP Roku SDK setECID()
            m.aepSdk.setExperienceCloudId(ecid_from_media_sdk)
          else
            print "API Response: ECID: " + "invalid"
          endif
        endif
      endif
    end function
```

---

### shutdown

Call this function to shut down the AEP Roku SDK and drop further API calls.

##### Syntax

```brightscript
shutdown: function() as void
```

##### Example

```brightscript
m.aepSdk.shutdown();
```
