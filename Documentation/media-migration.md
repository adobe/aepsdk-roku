# Migrate from Media Analytics SDK to AEP SDK on Roku platform

If you are currently using the Media Analytics SDK for your Roku projects, this guide offers a detailed outline on how to migrate to AEP Roku SDK using a step-by-step approach.

In AEP Roku SDK, there are two Media trakcing APIs:

- `createMediaSession`
- `sendMediaEven`

In the AEP Roku SDK, calling the above APIs is the recommended implementation path for sending Media events to Edge Network.

## Initliaze SDK instances

| Media SDK      | AEP SDK |
| ----------- | ----------- |
| ' Create adbmobileTask node <br>  m.adbmobileTask = createObject("roSGNode","adbmobileTask")  <br> <br> ' Get AdobeMobile SG connector instance <br> m.adbmobile = ADBMobile().getADBMobileConnectorInstance(m.adbmobileTask) <br> | ' Retrieve the Adobe task node <br> m.adobeTaskNode = m.top.getScene().findNode("adobeTaskNode") <br> <br> ' Create a SDK instance <br> m.aepSdk = AdobeAEPSDKInit(m.adobeTaskNode) <br> |
|    |         |

## Start the Media session

- Media SDK

``` brightscript
mInfo = adb_media_init_mediainfo("test_media_name", "test_media_id", 10, "vod", ADBMobile().MEDIA_TYPE_VIDEO)
mediaContextData = {}
mediaContextData["videotype"] = "episode" 
m.adbmobile.mediaTrackSessionStart(mInfo, mediaContextData)
```

- AEP SDK

``` brightscript
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
          "length": 10,
          "contentType": "vod"
        },
        "customMetadata":{
          "videotype":"episode" 
        }
      }
    }
  })
```

## Track Media events

### trackPlay

- Media SDK

``` brightscript
m.adbmobile.mediaTrackPlay()
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.play",
        "mediaCollection": {
          "playhead": <CURRENT_PLAYHEAD_VALUE>,
        }
      }
    })
```

### trackPause

- Media SDK

``` brightscript
m.adbmobile.mediaTrackPause()
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.pauseStart",
        "mediaCollection": {
          "playhead": <CURRENT_PLAYHEAD_VALUE>,
        }
      }
    })
```

### trackComplete

- Media SDK

``` brightscript
m.adbmobile.mediaTrackComplete()
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.sessionComplete",
        "mediaCollection": {
          "playhead": <CURRENT_PLAYHEAD_VALUE>,
        }
      }
    })
```

### trackSessionEnd

- Media SDK

``` brightscript
m.adbmobile.mediaTrackSessionEnd()
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.sessionEnd",
        "mediaCollection": {
          "playhead": <CURRENT_PLAYHEAD_VALUE>,
        }
      }
    })
```

### trackError

- Media SDK

``` brightscript
m.adbmobile.mediaTrackError("errorId", "video-player-error-code")
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.error",
        "mediaCollection": {
          "playhead": <CURRENT_PLAYHEAD_VALUE>,
          "errorDetails": {
            "name": "errorId",
            "source": "video-player-error-code"
          }
        }
      }
    })
```

### trackEvent

- Media SDK

``` brightscript
seekContextData = {}
seekContextData = {}
m.adbmobile.mediaTrackEvent(MEDIA_SEEK_START, seekInfo, seekContextData)
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
    "xdm": {
      "eventType": "media.ping",
      "mediaCollection": {
        "playhead": 123,
      }
    }
  })
```

### updateCurrentPlayhead

- Media SDK

``` brightscript
m.adbmobile.updateCurrentPlayhead(<CURRENT_PLAYHEAD_VALUE>)
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
    "xdm": {
      "eventType": "media.ping",
      "mediaCollection": {
        "playhead": <CURRENT_PLAYHEAD_VALUE>,
      }
    }
  })
```

### updateQoEObject

- Media SDK

``` brightscript
m.adbmobile.mediaUpdateQoS
```

- AEP SDK

``` brightscript
```
