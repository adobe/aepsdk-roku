# Getting Started

This guide explains how to quickly start using the Adobe Experience Platform Roku SDK with just a few lines of code.

## Configure a datastream

A `datastream` is a server-side configuration that tells the AEP Roku SDK where to send the data it collects. You can configure a datastream to send data to multiple Adobe solutions.

If no datastream was previously created, see [Configure datastreams](https://developer.adobe.com/client-sdks/documentation/getting-started/configure-datastreams/) before moving to the next step.

## Install the AEP Roku SDK

- Download the AEP Roku SDK zip file from the [GitHub Releases](https://github.com/adobe/aepsdk-roku/releases)

- Add the below SDK files to your Roku project

  - Copy the `AdobeEdge.brs` file to the `source` directory
  - Copy the `components/adobe/AdobeEdgeTask.brs` and `components/adobe/AdobeEdgeTask.xml` files to the `components/adobe` directory

If you want to move `AdobeEdge.brs`, `AdobeEdgeTask.brs`, and `AdobeEdgeTask.xml` to different locations than the paths specified below, please update `AdobeEdgeTask.xml` file with the corresponding file path.

```xml
  <script type="text/brightscript" uri="pkg:/components/adobe/AdobeEdgeTask.brs"/>
  <script type="text/brightscript" uri="pkg:/source/AdobeEdge.brs"/>
```

## Initialize and configure the AEP Roku SDK

Initialize and configure the AEP Roku SDK inside your `scene` script.

```xml
  <script type="text/brightscript" uri="pkg:/source/AdobeEdge.brs"/>
```

```brightscript
  m.aepSdk = AdobeSDKInit()
  ADB_CONSTANTS = AdobeSDKConstants()

  configuration = {}
  configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = "<YOUR_CONFIG_ID>"
  configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = "<YOUR_DOMAIN_NAME>"
  m.adobeEdgeSdk.updateConfiguration(configuration)

  m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

  ' send XDM data to Adobe Edge Network '

  m.aepSdk.sendEvent({
    "eventType": "commerce.orderPlaced",
    "eventType": {
      "key": "value"
    }
  })
```

> If you need to run both Media SDK for Roku and AEP Roku SDK in the same Roku channel and want to use the same ECID, you can call the `setExperienceCloudId` API. For more information, refer to the [API reference](./api-reference.md#setexperiencecloudid).

## Next Step

- Get familiar with the various APIs offered by the Adobe Roku SDK by checking out the [API reference](./api-reference.md).

- Review the [sample app](../sample/simple-videoplayer-channel/README.md) that is integrated with the AEP Roku SDK.
