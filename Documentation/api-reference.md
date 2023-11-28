# AEP Roku SDK API Usage

This document lists the APIs provided by AEP Roku SDK, along with code samples for API usage.


- Edge APIs
    - [AdobeAEPSDKInit](#AdobeAEPSDKInit)
    - [getVersion](#getVersion)
    - [resetIdentities](#resetIdentities)
    - [(optional) setExperienceCloudId](#setExperienceCloudId)
    - [sendEvent](#sendEvent)
    - [setLogLevel](#setLogLevel)
    - [shutdown](#shutdown)
    - [updateConfiguration](#updateConfiguration)
- Media APIs
    - [createMediaSession](#createMediaSession)
    - [sendMediaEvent](#sendMediaEvent)

## Edge APIs:

### AdobeAEPSDKInit

> [!IMPORTANT]
> The AEP task node performs the core logic of the SDK. Typically, a Roku project maintains only one instance of the AEP task node.

It's required to first call AdobeAEPSDKInit() without passing an argument within the scene script. It initializes a new AEP task node and creates an associated SDK instance. Then, the task node instance can be retrieved via the getTaskNode() API.

For example:
```brightscript
sdkInstance = AdobeAEPSDKInit()
adobeTaskNode = sdkInstance.getTaskNode()
```

To make this task node instance accessible in other components, appending it to the scene node is recommended.

For example:
```brightscript
m.top.appendChild(adobeTaskNode)
```

The task node's ID is by default set to "adobeTaskNode". Then, retrieve it by ID and use it to create a new SDK instance in other components.

For example:
```brightscript
adobeTaskNode = m.top.getScene().findNode("adobeTaskNode")
sdkInstance = AdobeAEPSDKInit(adobeTaskNode)
```

> **Note**
> The following variables are reserved to hold the SDK instances in GetGlobalAA():
>- `GetGlobalAA()._adb_public_api`
>- `GetGlobalAA()._adb_main_task_node`
>- `GetGlobalAA()._adb_serviceProvider_instance`

##### Syntax

```brightscript
function AdobeAEPSDKInit(taskNode = invalid as dynamic) as object
```

- `@return instance as object : public API instance`

##### Example

```brightscript
m.aepSdk = AdobeAEPSDKInit()
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
> The `sendEvent` API automatically attaches the following information with each Experience Event:
> - `IdentityMap` with the ECID - included by default to Experience Event class based XDM schemas
> - `Implementation Details` - for more details see the [Implementation Details XDM field group](https://github.com/adobe/xdm/blob/master/components/datatypes/industry-verticals/implementationdetails.schema.json)

> **Note**
> If the SDK fails to receive the Edge response within 5 seconds, the callback function will not be executed.


> **Note**
> Variables are not case sensitive in [BrightScript](https://developer.roku.com/docs/references/brightscript/language/expressions-variables-types.md), so always use the `String literals` to present the XDM data **keys**.

##### Example: sendEvent

```brightscript
  m.aepSdk.sendEvent({
    "eventType": "commerce.orderPlaced",
      "commerce": {
        .....
      }
  })
```

##### Example: sendEvent with callback

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

#### Send Custom IdentityMap

`sendEvent` API allows passing custom identifiers to the Edge Network using custom Identity map . Create the map using the identifier namespace as key and pass in the identity items for the namespace as an array. Configure the "primary" and "authenticatedState" per individual identity item per your application's requirements.

> **Note**
> Passing custom Identity map is optional. Do not pass the ECID with the sendEvent API, the ECID automatically attaches it on all requests. By default, the ECID is set as primary server-side if no other identifier uses "primary" : true.


##### Example

```brightscript
customIdentityMap = {
    "RIDA" : [
          {
            "id" : "SampleAdIdentifier",
            "authenticatedState": "ambiguous",
            "primary": false
          }
    ],
    "EMAIL" : [
          {
            "id" : "user@example.com",
            "authenticatedState": "ambiguous",
            "primary": false
          },
          {
            "id" : "useralias@example.com",
            "authenticatedState": "ambiguous",
            "primary": false
          }
    ]
}
```

```brightscript
  m.aepSdk.sendEvent({
    "eventType": "commerce.orderPlaced",
      "commerce": {
        .....
      },
      "identityMap": customIdentityMap
  })
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

### setLogLevel

##### Syntax

```brightscript
setLogLevel: function(level as integer) as void
```

- `@param level as integer : the accepted values are (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)`

##### Example

```brightscript
ADB_CONSTANTS = AdobeAEPSDKConstants()
m.aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)
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

---

### updateConfiguration

> **Note**
> Some public APIs need valid configuration to process the data and make the network call to Adobe Experience Edge Network. All the hits will be queued if no valid configuration is found. It is ideal to call updateConfiguration API with valid require configuration before any other public APIs.

#### Configuration Keys

- Required for all APIs

| Constants | Raw value | Type | Required |
| :-- | :--: | :--: | :--: |
| `ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID` | "edge.configId" | String | **Yes**
| `ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN` | "edge.domain" | String | **No**

- Required for Media tracking APIs

| Constants | Raw value | Type | Required |
| :-- | :--: | :--: | :--: |
| `ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL` | "edgemedia.channel" | String | **Yes**
| `ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME` | "edgemedia.playerName" | String | **Yes**
| `ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION` | "edgemedia.appVersion" | String | **No**

##### Syntax

```brightscript
updateConfiguration: function(configuration as object) as void
```

- `@param configuration as object`

##### Example

```brightscript
ADB_CONSTANTS = AdobeAEPSDKConstants()

configuration = {}
configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = "<YOUR_CONFIG_ID>"
configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = "<YOUR_DOMAIN_NAME>"

m.aepSdk.updateConfiguration(configuration)
```

The `EDGE_CONFIG_ID` value is presented as `Datastream ID` in the [Datastream details](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/configure.html?lang=en#view-details) page.

The `EDGE_DOMAIN` value is the first-party domain mapped to the Adobe-provisioned Edge Network domain. For more information, see this [documentation](https://developer.adobe.com/client-sdks/documentation/edge-network/#domain-configuration)

## Media APIs

### createMediaSession

Creates a new Media session with the provided XDM data. The XDM data event type should be `media.sessionStart`. If the `playerName`, `channel`, and `appVersion` are not provided in the XDM data, the SDK will use the global values passed via `updateConfiguration` API.

About the XDM data structure, please refer to the [starting the session
](https://experienceleague.adobe.com/docs/experience-platform/edge-network-server-api/media-edge-apis/getting-started.html?lang=en#start-session) document.

##### Syntax

```brightscript
createMediaSession: function(xdmData as object, configuration = {} as object) as void
```

- `@param xdmData as object : the XDM data of type "media.sessionStart"`
- `@param configuration as object : the session-level configuration`

> [!NOTE]
> If the ping interval is not set, the default interval of `10 sec` will be used.

##### Configuration Keys

| Constants | Raw value | Type | Range | Required |
| :-- | :--: | :--: | :--: | :--: |
| `ADB_CONSTANTS.MEDIA_SESSION_CONFIGURATION.CHANNEL` | "config.channel" | String | | **No**
| `ADB_CONSTANTS.MEDIA_SESSION_CONFIGURATION.AD_PING_INTERVAL` | "config.adpinginterval" | Integer | 1~10 | **No**
| `ADB_CONSTANTS.MEDIA_SESSION_CONFIGURATION.MAIN_PING_INTERVAL` | "config.mainpinginterval" | Integer | 10~50 | **No**

> [!IMPORTANT]
> SessionStart API requires [sessionDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md) fieldgroup with all the required fields present in the request payload.

##### Example

```brightscript
m.aepSdk.createMediaSession({
  "xdm": {
    "eventType": "media.sessionStart"
     "mediaCollection": {
      "playhead": 0,
      "sessionDetails": {
        "streamType": "video",
        "friendlyName": "test_media_name",
        "hasResume": false,
        "name": "test_media_id",
        "length": 100,
        "contentType": "vod"
      }
    }
  }
})
```

```brightscript
MEDIA_SESSION_CONFIGURATION = AdobeAEPSDKConstants().MEDIA_SESSION_CONFIGURATION
sessionConfiguration = {}
sessionConfiguration[MEDIA_SESSION_CONFIGURATION.CHANNEL] = "channel_name_for_current_session" ''' Overwrites channel configured in the SDK configuration.
sessionConfiguration[MEDIA_SESSION_CONFIGURATION.AD_PING_INTERVAL] = 1 ''' Overwrites ad content ping interval to 1 second.
sessionConfiguration[MEDIA_SESSION_CONFIGURATION.MAIN_PING_INTERVAL] = 30 ''' Overwrites main content ping interval to 30 seconds.

m.aepSdk.createMediaSession({
  "xdm": {
    "eventType": "media.sessionStart"
     "mediaCollection": {
      "playhead": 0,
      "sessionDetails": {
        "streamType": "video",
        "friendlyName": "test_media_name",
        "hasResume": false,
        "name": "test_media_id",
        "length": 100,
        "contentType": "vod"
      }
    }
  }
}, sessionConfiguration)
```

---

### sendMediaEvent

> **Important**
> Media session needs to be active before using `sendMediaEvent` API. Use `createMediaSession` API to create the session.

About the XDM data structure, please refer to the [Media Edge API Documentation](https://experienceleague.adobe.com/docs/experience-platform/edge-network-server-api/media-edge-apis/getting-started.html?lang=en).

> **Important**
> Ensure that the `media.ping` event is sent at least once every second with the latest playhead value during the video playback. SDK relies on these pings to function properly.
> Refer to [MainScene.brs](../sample/simple-videoplayer-channel/components/MainScene.brs) for information on how the sample app uses a timer to send ping events every second.

##### Syntax

```brightscript
sendMediaEvent: function(xdmData as object) as void
```

##### Example

```brightscript
m.aepSdk.sendMediaEvent({
  "xdm": {
    "eventType": "media.play",
    "mediaCollection": {
      "playhead": <current_playhead>,
    }
  }
})
```
