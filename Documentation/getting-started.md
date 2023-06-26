# Getting Started

This guide explains how to quickly start using the Adobe Experience Platform Roku SDK with just a few lines of code.

## Configure a datastream

A datastream is a server-side configuration that tells the Adobe Experience Platform Web SDK where to send the data it collects. You can configure a datastream to send data to multiple Adobe solutions.

If no datastream was previously created, see [Configure datastreams](https://developer.adobe.com/client-sdks/documentation/getting-started/configure-datastreams/) before moving to the next step.

## install the Roku SDK

- Download the Roku SDK zip file from the [GitHub Releases](https://github.com/adobe/aepsdk-roku/releases)

- Add the below SDK files to your Roku project

  - Copy the `AdobeEdge.brs` file to the `source` directory
  - Copy the `components/adobe/AdobeEdgeTask.brs` and `components/adobe/AdobeEdgeTask.xml` files to the `components` directory

## Initialize and configure the Roku SDK

Initalize and configure the Roku SDK insdie your `scene` script.

```javascript
  m.adobeEdgeSdk = AdobeSDKInit()
  configuration = {
    edge: {
      configId: "copy_your_datastream_id_here"
    }
  }
  m.adobeEdgeSdk.updateConfiguration(configuration)
  ADB_CONSTANTS = AdobeSDKConstants()
  m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)
  
  ' send XDM data to Adobe Edge Network '
  
  m.adobeEdgeSdk.sendEdgeEvent({
    eventType: "commerce.orderPlaced",
    commerce: {
      key: "value"
    }
  })
```

## Next Step

- Get familiar with the various APIs offered by the Adobe Roku SDK by checking out the [API reference](./api-reference.md).

- Review the [sample apps](../sample/simple-videoplayer-channel/README.md) that is integrated with the Adobe Roku SDK.
