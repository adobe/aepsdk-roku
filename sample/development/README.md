# Roku Sample Channel

This Roku channel project demonstrates the usage of the Adobe Roku SDK.

To run the project on your Roku device, follow the steps below to set it up beforehand.

## Install the Roku SDK

 To install the Roku SDK in this sample project, you can copy the SDK files to this sample project by following the [install instruction](../../Documentation/getting-started.md).

## Initialize and configure the Roku SDK

The Roku SDK is initialized and configured in the [SimpleVideoScene](./components/SimpleVideoScene.brs) file. The default `configId` value is invalid. Please provide a valid value for it.

## Send XDM data to the Adobe Edge Network

You can now use the `sendEvent` API to send XDM data to the Adobe Edge Network.
