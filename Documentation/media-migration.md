# Migrate from Media SDK to AEP SDK

## Table of contents
| Sections |
| -- |
| [Prerequisistes](#prerequisistes) |
| [API comparison between SDKs](#api-comparison) |
| [Initialize SDK instance](#initialize-sdk-instance) |
| [Start Media session](#start-media-session) |
| [Track Media events](#track-media-events) |

## Prerequisistes
1. [Experience Data Model (XDM)](https://experienceleague.adobe.com/docs/experience-platform/xdm/home.html?lang=en)
2. [Datastreams](https://developer.adobe.com/client-sdks/home/getting-started/configure-datastreams/)
3. [Getting Started with implementing Media tracking using AEP Roku SDK](./getting-started.md)
4. [Setup schemas, datastream, dataset, Customer Journey Analytics (CJA) dashboard etc](https://experienceleague.adobe.com/docs/media-analytics/using/implementation/edge-recommended/media-edge-sdk/implementation-edge.html)


## API comparison

> [!NOTE]
> AEP SDK has only two media APIs `createMediaSession()` and `sendMediaEvent()`.

### Core Plaback APIs:

| Media SDK | AEP SDK|
| -- | -- |
| `mediaTrackSessionStart(mediaInfo,mediaContextData)` | `createMediaSession(sessionStartXDM)` |
| `mediaTrackPlay()` | `sendMediaEvent(playXDM)` |
| `mediaTrackPause()` | `sendMediaEvent(pauseStartXDM)` |
| `mediaTrackComplete()` | `sendMediaEvent(sessionCompleteXDM)` |
| `mediaTrackSessionEnd()` | `sendMediaEvent(sessionEndXDM)` |

### Ad Tracking APIs:
| Media SDK | AEP SDK|
| -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_START, adBreakInfo, contextData)` | `sendMediaEvent(adbreakStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_COMPLETE, invalid, invalid)` | `sendMediaEvent(adbreakCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_START, adInfo, contextData)` | `sendMediaEvent(adStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_COMPLETE, invalid, invalid)` | `sendMediaEvent(adCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_SKIP, invalid, invalid)` | `sendMediaEvent(adSkipXDM)` |

### Buffer and Seek APIs
| Media SDK | AEP SDK|
| -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_BUFFER_START, invalid, invalid)` | `sendMediaEvent(bufferStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_BUFFER_COMPLETE, invalid, invalid)` | `sendMediaEvent(bufferCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_SEEK_START, invalid, invalid)` | `sendMediaEvent(pauseStartXDM)` |
| `ADBMobile().mediaTrackEvent(ADBMobile().MEDIA_SEEK_COMPLETE, invalid, invalid)` | `sendMediaEvent(pauseStartXDM)` |

> [!NOTE]
> For tracking seek in AEP SDK, use eventType `pauseStart` with correct playhead. Media backend will detect seek based on playhead and timestamp values.

### Chapter APIs
| Media SDK | AEP SDK|
| -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_START, chapterInfo, chapterContextData)` | `sendMediaEvent(chapterStartXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_COMPLETE, invalid, invalid)` | `sendMediaEvent(chapterCompleteXDM)` |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_SKIP, invalid, invalid)` | `sendMediaEvent(chapterSkipXDM)` |

### Quality of Experience (QoE) and Error APIs
| Media SDK | AEP SDK|
| -- | -- |
| `mediaUpdateQoS(qosinfo)` | NA |
| `mediaTrackEvent(ADBMobile().MEDIA_BITRATE_CHANGE)` | `sendMediaEvent(bitrateChangeXDM)` |
| `mediaTrackError(errorId, ADBMobile().ERROR_SOURCE_PLAYER)` | `sendMediaEvent(errorXDM)` |

> [!NOTE]
> QoE info has to be attached to the xdmData when calling `sendMediaEvent(bitrateChangeXDM)` for `bitrateChange` event. QoE info can also be attached to any other event's xdm data the sendMediaEvent(eventXDM) API. Refer to the [QoeDataDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/qoedatadetails.schema.md) fieldgroup

### Playhead update API
| Media SDK | AEP SDK|
| -- | -- |
| `mediaUpdatePlayhead(position)` | NA (sent with all the APIs in the xdm data) |

## PlayerState Tracking API
| Media SDK | AEP SDK|
| -- | -- |
| NA | `sendMediaEvent(statesUpdateXDM)` |

### Helper APIs
| Media SDK | AEP SDK|
| -- | -- |
| `adb_media_init_mediainfo(title, id, length, streamType, mediaType)` | NA |
| `adb_media_init_adbreakinfo(title, startTime, position)` | NA |
| `adb_media_init_adinfo(title, id, position, duration)` | NA |
| `adb_media_init_chapterinfo(title, position, length, startTime)` | NA |
| `adb_media_init_qosinfo(bitrate, startupTime, fps, droppedFrames)` | NA |

## Initialize SDK instance

**Media SDK**

```brightscript
' Create adbmobileTask node
m.adbmobileTask = createObject("roSGNode","adbmobileTask")
' Create SDK instance
m.adbmobile = ADBMobile().getADBMobileConnectorInstance(m.adbmobileTask)
```

**AEP SDK**

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

**AEP SDK**

> [!Note]
> Checkout [sessionDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md) fieldgroup in the MediaAnalytics schema to know more about the required fields and StandardMetadata fields.

``` brightscript
sessionDetails = {
    "streamType": "video",
    "friendlyName": "test_media_name",
    "name": "test_media_id",
    "length": 10,
    "contentType": "vod",

    ' (Optional) Attach Standard metadata if any
    "show": "sample show"
}

' (Optional) Create map for custom data if any
customMetadata = {
  "cmk1":"cmv "
}

sessionStartXDM = {
  "xdm": {
    "eventType": "media.sessionStart"
    "mediaCollection": {
      "playhead":  <CURRENT_PLAYHEAD_VALUE>,
      "sessionDetails": sessionDetails,
      "customMetadata": customMetadata
    }
  }
}

m.aepSdk.createMediaSession(sessionStartXDM)
```

## Track Media events

### trackPlay

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackPlay()
```

**AEP SDK**

``` brightscript
playXDM = {
  "xdm": {
    "eventType": "media.play",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(playXDM)
```

---

### trackPause

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackPause()
```

**AEP SDK**

``` brightscript
pauseStartXDM = {
  "xdm": {
    "eventType": "media.pauseStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_VALUE>,
    }
  }
}

m.aepSdk.sendMediaEvent(pauseStartXDM)
```

---

### trackComplete

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackComplete()
```

**AEP SDK**

``` brightscript
sessionCompleteXDM = {
  "xdm": {
    "eventType": "media.sessionComplete",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_VALUE>,
    }
  }
}

m.aepSdk.sendMediaEvent(sessionCompleteXDM)
```

---

### trackSessionEnd

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackSessionEnd()
```

**AEP SDK**

``` brightscript
sessionEndXDM = {
  "xdm": {
    "eventType": "media.sessionEnd",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_VALUE>,
    }
  }
}

m.aepSdk.sendMediaEvent(sessionEndXDM)
```

---

### trackError

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackError("errorId", "video-player-error-code")
```

**AEP SDK**

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

---

### trackEvent

**Media SDK**

``` brightscript
seekContextData = {}
seekContextData = {}
m.adbmobile.mediaTrackEvent(MEDIA_SEEK_START, seekInfo, seekContextData)
```

**AEP SDK**

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

---

### updateCurrentPlayhead

**Media SDK**

``` brightscript
m.adbmobile.updateCurrentPlayhead(<CURRENT_PLAYHEAD_VALUE>)
```

**AEP SDK**

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

---

### updateQoEObject

**Media SDK**

``` brightscript
m.adbmobile.mediaUpdateQoS
```

**AEP SDK**

``` brightscript
```
