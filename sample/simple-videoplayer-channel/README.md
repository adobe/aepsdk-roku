## Installation

To deploy the Adobe Roku SDK to this sample app, you will need to navigate to the current directory and run the following command:

```shell
make  link-sdk
```
## Initialize the SDK

SDK initialization code is located in [SimpleVideoScene.brs](./components/SimpleVideoScene.brs)

## Send an edge event

To send an edge event, use the following code:

```javascript
    m.adobeEdgeSdk.sendEdgeEvent({
      eventType: "commerce.orderPlaced",
      commerce: {
      },
    })
```
You can also find an example in [SimpleVideoScene.brs](./components/SimpleVideoScene.brs)

