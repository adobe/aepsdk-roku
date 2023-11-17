# Migrate from Media SDK to AEPRoku SDK

## Prerequisistes
1. [Experience Data Model (XDM)](https://experienceleague.adobe.com/docs/experience-platform/xdm/home.html?lang=en)
2. [Datastreams](https://developer.adobe.com/client-sdks/home/getting-started/configure-datastreams/)
3. Setup schemas, datastream, dataset, Customer Journey Analytics (CJA) dashboard etc. using this [guide](https://experienceleague.adobe.com/docs/media-analytics/using/implementation/edge-recommended/media-edge-sdk/implementation-edge.html) for Media tracking using AEPEdge SDK.

## Table of contents
| Sections |
| -- |
| [API comparison between SDKs](#api-comparison) |
| [Initliaze SDK instance](#initliaze-sdk-instance) |
| [Start Media session](#start-media-session) |
| [Track Media events](#track-media-events) |

## API comparison

### Core Plaback APIs:
> [!NOTE]
> AEPRoku SDK has only two media APIs `createMediaSession()` and `sendMediaEvent()`.

| Media SDK | AEPRoku SDK|
| -- | -- |
| `mediaTrackSessionStart(mediaInfo,mediaContextData)` | `createMediaSession(sessionStartXDM)` |
| `mediaTrackPlay()` | `sendMediaEvent(playXDM)` |
| `mediaTrackPause()` | `sendMediaEvent(pauseXDM)` |
| `mediaTrackComplete()` | `sendMediaEvent(completeXDM)` |
| `mediaTrackSessionEnd()` | `sendMediaEvent(sessionEndXDM)` |

### Ad Tracking APIs:
| Media SDK | AEPRoku SDK|
| -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_START, adBreakInfo, contextData)` | `sendMediaEvent(adbreakStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_START, invalid, invalid)` | `sendMediaEvent(adbreakCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_START, adInfo, contextData)` | `sendMediaEvent(adStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_COMPLETE, invalid, invalid)` | `sendMediaEvent(adCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_SKIP, invalid, invalid)` | `sendMediaEvent(adSkipXDM)` |

### Buffer and Seek APIs
| Media SDK | AEPRoku SDK|
| -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_BUFFER_START, bufferInfo, bufferContextData)` | `sendMediaEvent(bufferCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_BUFFER_COMPLETE, invalid, invalid)` | `sendMediaEvent(bufferCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_SEEK_START, seekInfo, seekContextData)` | `sendMediaEvent(pauseXDM)` |
| `ADBMobile().mediaTrackEvent(ADBMobile().MEDIA_SEEK_COMPLETE, invalid, invalid)` | `sendMediaEvent(pauseXDM)` |

> [!NOTE]
> For tracking seek in AEPRoku SDK, use eventType `pauseStart` with correct playhead. Media backend will detect seek based on playhead and timestamp values.

### Chapter APIs
| Media SDK | AEPRoku SDK|
| -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_START, chapterInfo, chapterContextData)` | `sendMediaEvent(chapterStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_COMPLETE, invalid, invalid)` | `sendMediaEvent(chapterCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_SKIP, invalid, invalid)` | `sendMediaEvent(chapterSkipXDM)` |

### Quality of Experience and Error APIs
| Media SDK | AEPRoku SDK|
| -- | -- |
| `mediaUpdateQoS(qosinfo)` | NA |
| `mediaTrackEvent(ADBMobile().MEDIA_BITRATE_CHANGE)` | `sendMediaEvent(pingXDM)` |
| `mediaTrackError(errorId, ADBMobile().ERROR_SOURCE_PLAYER)` | `sendMediaEvent(errorXDM)` |

> [!NOTE]
> QoE info can be attached to any event's xdm data the sendMediaEvent(eventXDM) API. Refer to the [QoeDataDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/qoedatadetails.schema.md) fieldgroup

### Playhead update API
| Media SDK | AEPRoku SDK|
| -- | -- |
| `mediaUpdatePlayhead(position)` | NA (sent with all the APIs in the xdm data) |

### Helper APIs
| Media SDK | AEPRoku SDK|
| -- | -- |
| `adb_media_init_mediainfo(title, id, length, streamType, mediaType)` | NA |
| `adb_media_init_adinfo(title, id, position, duration)` | NA |
| `adb_media_init_qosinfo(bitrate, startupTime, fps, droppedFrames)` | NA |

## Initliaze SDK instance

**Media SDK**

```brightscript
' Create adbmobileTask node
m.adbmobileTask = createObject("roSGNode","adbmobileTask") <br> Get AdobeMobile SG connector instance
' Create SDK instance
m.adbmobile = ADBMobile().getADBMobileConnectorInstance(m.adbmobileTask)
```

**AEPRoku SDK**

```brightscript
' Create SDK instance
m.aepSdk = AdobeAEPSDKInit()
```

> [!NOTE]
> AEP SDK creates the taskNode internally.

## Start Media session

**Media SDK**

``` brightscript
' Use the helper method to create mediaInfo object
mediaInfo = adb_media_init_mediainfo("test_media_name", "test_media_id", 10, ADBMobile().MEDIA_STREAM_TYPE_VOD, ADBMobile().MEDIA_TYPE_VIDEO)

' (Optional) Attach Standard metadata if any
standardMetadata = {}
standardMetadata[ADBMobile().MEDIA_VideoMetadataKeySHOW] = "sample show"

mediaInfo[ADBMobile().MEDIA_STANDARD_MEDIA_METADATA] = standardMetadata

' (Optional) Create map for custom metadadata if any
customMetadata = {}
customMetadata["cmk1"] = "cmv1"

' Call mediaTrackSessionStart API
m.adbmobile.mediaTrackSessionStart(mediaInfo, customMetadata)
```

**AEPRoku SDK**

``` brightscript
' Create sessionDetails object following the [sessionDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md) fieldGroup
' (Optional) Standard Metadata keys are available in the [sessionDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md) fieldGroup
sessionDetails = {
    "streamType": "video",
    "friendlyName": "test_media_name",
    "name": "test_media_id",
    "length": 10,
    "contentType": "vod",

    ''' (Optional) Attach Standard metadata if any
    "show": "sample show"
}

' (Optional) create map for custom data if any
customMetadata = {
  "cmk1":"cmv "
}

m.aepSdk.createMediaSession({
    "xdm": {
      "eventType": "media.sessionStart"
      "mediaCollection": {
        "playhead":  <CURRENT_PLAYHEAD_VALUE>,
        "sessionDetails": sessionDetails,
        "customMetadata": customMetadata
      }
    }
  })
```

## Track Media events

### trackPlay

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackPlay()
```

**AEPRoku SDK**

``` brightscript
m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.play",
        "mediaCollection": {
          "playhead": <CURRENT_PLAYHEAD_VALUE>
        }
      }
    })
```

### trackPause

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackPause()
```

**AEPRoku SDK**

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

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackComplete()
```

**AEPRoku SDK**

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

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackSessionEnd()
```

**AEPRoku SDK**

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

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackError("errorId", "video-player-error-code")
```

**AEPRoku SDK**

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

**Media SDK**

``` brightscript
seekContextData = {}
seekContextData = {}
m.adbmobile.mediaTrackEvent(MEDIA_SEEK_START, seekInfo, seekContextData)
```

**AEPRoku SDK**

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

**Media SDK**

``` brightscript
m.adbmobile.updateCurrentPlayhead(<CURRENT_PLAYHEAD_VALUE>)
```

**AEPRoku SDK**

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

**AEPRoku SDK**

``` brightscript
```
