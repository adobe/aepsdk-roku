# Getting Started

This guide explains how to quickly start using the Adobe Experience Platform Roku SDK with just a few lines of code.

## Configure a datastream

A `datastream` is a server-side configuration that tells the AEP Roku SDK where to send the data it collects. You can configure a datastream to send data to multiple Adobe solutions.

If no datastream was previously created, see [Configure datastreams](https://developer.adobe.com/client-sdks/documentation/getting-started/configure-datastreams/) before moving to the next step.

## Install the AEP Roku SDK

- Download the AEP Roku SDK zip file from the [GitHub Releases](https://github.com/adobe/aepsdk-roku/releases)

- Add the below SDK files to your Roku project

  - Copy the `AEPSDK.brs` file to the `source` directory
  - Copy the `components/adobe/AEPSDKTask.brs` and `components/adobe/AEPSDKTask.xml` files to the `components/adobe` directory

If you want to move `AEPSDK.brs`, `AEPSDKTask.brs`, and `AEPSDKTask.xml` to different locations than the paths specified below, please update `AEPSDKTask.xml` file with the corresponding file path.

```xml
  <script type="text/brightscript" uri="pkg:/components/adobe/AEPSDKTask.brs"/>
  <script type="text/brightscript" uri="pkg:/source/AEPSDK.brs"/>
```

## Initialize and configure the AEP Roku SDK

Initialize and configure the AEP Roku SDK inside your `scene` script.

```xml
  <script type="text/brightscript" uri="pkg:/source/AEPSDK.brs"/>
```

```brightscript
  m.aepSdk = AdobeAEPSDKInit()

  ADB_CONSTANTS = AdobeAEPSDKConstants()

  configuration = {}
  configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = "<YOUR_CONFIG_ID>"
  configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = "<YOUR_DOMAIN_NAME>"
  m.aepSdk.updateConfiguration(configuration)

  m.aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.DEBUG)

  ' send XDM data to Adobe Edge Network '

  m.aepSdk.sendEvent({
    "eventType": "commerce.orderPlaced",
    "eventType": {
      "key": "value"
    }
  })
```

> **Note**
> If you need to run both Media SDK for Roku and AEP Roku SDK in the same Roku channel and want to use the same ECID, use `setExperienceCloudId` API to set the ECID from Media SDK with the AEP Roku SDK. For more information, refer to the [API reference](./api-reference.md#setexperiencecloudid).

## Access AEP Roku SDK APIs in other components

In order to access the AEP Roku SDK APIs in any SceneGraph component, it is required to create a new AEP Roku SDK instance within the component due to the limitations in the component scope of the Roku SceneGraph framework.

Firstly, you need to attach the Adobe task node instance to the Scene node. After initializing the AEP Roku SDK, add the code below in the Scene script.

``` brightscript
adobeTaskNode = m.aepSdk.getTaskNode()

' To make the Adobe task node instance accessible in other components, appending it to the scene node is recommended.
m.top.appendChild(adobeTaskNode)
```

Then, in other ScenenGraph components scripts, you can retrieve the task node instance and use it to create a new AEP Roku SDK instance in a separate SceneGraph component.

``` brightscript
adobeTaskNode = m.top.getScene().findNode("adobeTaskNode")
sdkInstance = AdobeAEPSDKInit(adobeTaskNode)
```

## Next step

- Get familiar with the various APIs offered by the AEP Roku SDK by checking out the [API reference](./api-reference.md).

- Review the [sample app](../sample/simple-videoplayer-channel) that is integrated with the AEP Roku SDK.
