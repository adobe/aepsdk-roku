# Roku Sample Channel

This Roku channel project demonstrates the usage of the AEP Roku SDK.

To run the project on your Roku device, follow the steps below to set it up beforehand.

## Install the Roku SDK

To install the AEP Roku SDK in this sample project, you can copy the SDK files to this sample project by following the [install instruction](../../Documentation/getting-started.md).

## Initialize and configure the Roku SDK

The Roku SDK is initialized in the [SimpleVideoScene](./components/SimpleVideoScene.brs) file. Configuration is empty, update the configuration with valid `configId` before running the channel.

## Send XDM data to the Adobe Edge Network

Use the `sendEvent` API to send XDM data to the Adobe Edge Network.
