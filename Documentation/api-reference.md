# Roku SDK API Usage

This document lists the APIs provided by Adobe Roku SDK, along with sample code snippets on how to properly use the APIs.

- [AdobeSDKInit](#AdobeSDKInit)
- [getVersion](#getVersion)
- [setLogLevel](#setLogLevel)
- [sendEdgeEvent](#sendEdgeEvent)
- [shutdown](#shutdown)

TBD 
- [setAdvertisingIdentifier](#setAdvertisingIdentifier)
- [updateIdentities](#updateIdentities)
- [setConfiguration](#setConfiguration)

---

### AdobeSDKInit

##### Syntax

```javascript
function AdobeSDKInit(configuration as object, ecid = "" as string) as object
```
Initialize the Adobe SDK and return the public API instance.

- `@param configuration as object      : configuration for the SDK`
- `@param [optional] ecid as string    : experience cloud id`
- `@return instance as object          : public API instance`

> By default, this SDK automatically generates an ECID (Experience Cloud ID) when first used. If you are running this Edge SDK with the previous [media SDK](https://experienceleague.adobe.com/docs/media-analytics/using/media-use-cases/sdk-track-scenegraph.html?lang=en#global-methods-for-mediaheartbeat), you can manually set one to keep both SDKs running with the same ECID.

##### Example 1

```javascript
  edge_config = {
    configId: "f6a0164d-4d36-48b5-bb29-264f14fbf57c"
  }
  m.adobeEdgeSdk = AdobeSDKInit({ edge: edge_config })
```

##### Example 2

```javascript
  mid_from_media_sdk = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  edge_config = {
    configId: "f6a0164d-4d36-48b5-bb29-264f14fbf57c"
  }
  m.adobeEdgeSdk = AdobeSDKInit({ edge: edge_config }, mid_from_media_sdk)
```

### getVersion

##### Syntax

```javascript
getVersion: function() as string
```
- `@return version as string`

##### Example 

```javascript
  m.adobeEdgeSdk.getVersion()
```

### setLogLevel

##### Syntax

```javascript
setLogLevel: function(level as integer) as void
```
- `@param level as integer : the accepted values are (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)`

##### Example 

```javascript
  ADB_CONSTANTS = AdobeSDKConstants()
  m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)
```

### shutdown 

##### Syntax

```javascript
shutdown: function() as void
```

##### Example 

```javascript
  m.adobeEdgeSdk.shutdown()
```

### sendEdgeEvent

Sends an Experience event to Edge Network.

##### Syntax

```javascript
sendEdgeEvent: function(xdmData as object, callback = _adb_default_callback as function, context = invalid as dynamic) as void
```
- `@param data as object : xdm data`
- `@param [optional] callback as function(context, result) : handle Edge response`
- `@param [optional] context as dynamic : context to be passed to the callback function`

##### Example 1

```javascript
  m.adobeEdgeSdk.sendEdgeEvent({
    eventType: "commerce.orderPlaced",
      commerce: {
        .....
      }
  })
```
##### Example 2
```javascript
  m.adobeEdgeSdk.sendEdgeEvent({
      eventType: "commerce.orderPlaced",
      commerce: {
        .....
      }
  }, sub(context, result)
      print "callback result: "
      print result
      print context
  end sub, context)
```
---

## TBM

### setAdvertisingIdentifier

This is used to set the advertising identifier for the SDK

##### Syntax

```javascript
setAdvertisingIdentifier: function(advertisingIdentifier as string) as void
```
- `@param advertisingIdentifier as string : the advertising identifier`

##### Example 

```javascript
  m.adobeEdgeSdk.setAdvertisingIdentifier("the advertising identifier")
```

### updateIdentities

##### Syntax

```javascript
updateIdentities: function(identifier as object) as void
```
- `@param identifier as object : xmd identity map`

##### Example 

```javascript
  m.adobeEdgeSdk.updateIdentities({
    Email: [{
              id: "user@example.com",
              authenticatedState: "authenticated",
              primary: false
            }]
  })
```
### updateConfiguration

##### Syntax

```javascript
setConfiguration: function(configuration as object) as void
```
- `@param configuration as object`

##### Example 

```javascript
  edge_config = {
    configId: "f6a0164d-4d36-48b5-bb29-264f14fbf57c"
  }
  m.adobeEdgeSdk.updateConfiguration({ edge: edge_config })
```


