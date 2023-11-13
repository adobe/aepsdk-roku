# Migrate from Media Analytics SDK to AEP SDK on Roku platform

If you are currently using the Media Analytics SDK for your Roku projects, this guide offers a detailed outline on how to migrate to AEP Roku SDK using a step-by-step approach.

In AEP Roku SDK, there are two Media trakcing APIs:

- `createMediaSession`
- `sendMediaEven`

In the AEP Roku SDK, calling the above APIs is the recommended implementation path for sending Media events to Edge Network.

## Initliaze SDK instances

| Meida SDK      | AEP SDK |
| ----------- | ----------- |
| ' Create adbmobileTask node <br>  m.adbmobileTask = createObject("roSGNode","adbmobileTask")  <br> <br> ' Get AdobeMobile SG connector instance <br> m.adbmobile = ADBMobile().getADBMobileConnectorInstance(m.adbmobileTask) <br> | ' Retrieve the Adobe task node <br> m.adobeTaskNode = m.top.getScene().findNode("adobeTaskNode") <br> <br> ' Create a SDK instance <br> m.aepSdk = AdobeAEPSDKInit(m.adobeTaskNode) <br> |
|    |         |

## Start the Media session

- Meida SDK

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
          "length": 100,
          "contentType": "vod"
        }
      }
    }
  })
```

## Track Media events

### trackPlay

- Meida SDK

``` brightscript
m.adbmobile.mediaTrackPlay()
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.play",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })
```

### trackPause

- Meida SDK

``` brightscript
m.adbmobile.mediaTrackPause()
```

- AEP SDK

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.pauseStart",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })
```

### trackComplete

- Meida SDK

``` brightscript
m.adbmobile.mediaTrackComplete()
```

- AEP SDK

``` brightscript
```

### trackSessionEnd

- Meida SDK

``` brightscript
m.adbmobile.mediaTrackSessionEnd()
```

- AEP SDK

``` brightscript
```

### trackError

- Meida SDK

``` brightscript
m.adbmobile.mediaTrackError(errorMsg, "video-player-error-code")
```

- AEP SDK

``` brightscript
```

### trackEvent

- Meida SDK

``` brightscript
‘ Create an adbreak info object
adBreakInfo = adb_media_init_adbreakinfo()
adBreakInfo.name = <ADBREAK_NAME>
adBreakInfo.startTime = <START_TIME>
adBreakInfo.position = <POSITION>

contextData = {}
m.adbmobile.mediaTrackEvent(MEDIA_AD_BREAK_START, adBreakInfo, contextData)
```

- AEP SDK

``` brightscript
```

### updateCurrentPlayhead

- Meida SDK

``` brightscript
m.adbmobile.updateCurrentPlayhead(123)
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

### updateQoEObject

- Meida SDK

``` brightscript
```

- AEP SDK

``` brightscript
```