# Migrate from Adobe Media SDK to Adobe Experience Platform Roku SDK

Follow this guide to migrate from [Adobe Media SDK](https://github.com/Adobe-Marketing-Cloud/media-sdks/tree/master/sdks/roku) to the latest Adobe Experience Platform Roku SDK.

## Table of contents
| Sections |
| -- |
| [Prerequisistes](#prerequisistes) |
| [API comparison between SDKs](#api-comparison) |
| [Initialize SDK instance](#initialize-sdk-instance) |
| [Start Media session](#start-media-session) |
| [Track Media events](#track-media-events) |

## Prerequisites
1. [Experience Data Model (XDM)](https://experienceleague.adobe.com/docs/experience-platform/xdm/home.html?lang=en)
2. [Datastreams](https://developer.adobe.com/client-sdks/home/getting-started/configure-datastreams/)
3. [Getting Started with implementing Media tracking using AEP Roku SDK](./getting-started.md)
4. [Setup schemas, datastream, dataset, Customer Journey Analytics (CJA) dashboard etc](https://experienceleague.adobe.com/docs/media-analytics/using/implementation/edge-recommended/media-edge-sdk/implementation-edge.html)


## API comparison

> [!NOTE]
> AEP Roku SDK has only two APIs for tracking media `createMediaSession()` and `sendMediaEvent()`.

### Core Plaback APIs:

| Media SDK | AEP Roku SDK | Sample |
| -- | -- | -- |
| `mediaTrackSessionStart(mediaInfo,mediaContextData)` | `createMediaSession(sessionStartXDM)` | [SessionStart](#tracksessionstart) |
| `mediaTrackPlay()` | `sendMediaEvent(playXDM)` | [Play](#trackplay) |
| `mediaTrackPause()` | `sendMediaEvent(pauseStartXDM)` | [Pause](#trackpause) |
| `mediaTrackComplete()` | `sendMediaEvent(sessionCompleteXDM)` | [SessionComplete](#trackcomplete) |
| `mediaTrackSessionEnd()` | `sendMediaEvent(sessionEndXDM)` | [SessionEnd](#tracksessionend) |

### Ad Tracking APIs:
| Media SDK | AEP Roku SDK| Sample |
| -- | -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_START, adBreakInfo, contextData)` | `sendMediaEvent(adbreakStartXDM)` | [AdBreakStart](#adbreakstart) |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_COMPLETE, invalid, invalid)` | `sendMediaEvent(adbreakCompleteXDM)` | [AdBreakComplete](#adbreakcomplete) |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_START, adInfo, contextData)` | `sendMediaEvent(adStartXDM)` | [AdStart](#adstart) |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_COMPLETE, invalid, invalid)` | `sendMediaEvent(adCompleteXDM)` | [AdComplete](#adcomplete) |
| `mediaTrackEvent(ADBMobile().MEDIA_AD_SKIP, invalid, invalid)` | `sendMediaEvent(adSkipXDM)` | [AdSkip](#adskip) |

### Buffer and Seek APIs
| Media SDK | AEP Roku SDK| Sample |
| -- | -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_BUFFER_START, invalid, invalid)` | `sendMediaEvent(bufferStartXDM)` | [BufferStart](#bufferstart) |
| `mediaTrackEvent(ADBMobile().MEDIA_BUFFER_COMPLETE, invalid, invalid)` | `sendMediaEvent(bufferCompleteXDM)` | [BufferComplete](#buffercomplete) |
| `mediaTrackEvent(ADBMobile().MEDIA_SEEK_START, invalid, invalid)` | `sendMediaEvent(pauseStartXDM)` | [SeekStart](#seekstart) |
| `mediaTrackEvent(ADBMobile().MEDIA_SEEK_COMPLETE, invalid, invalid)` | `sendMediaEvent(playXDM)` | [SeekComplete](#seekcomplete) |

> [!NOTE]
> For tracking seek in AEP Roku SDK, use eventType `pauseStart` with correct playhead. Media backend will detect seek based on change in playhead and timestamp values.

### Chapter APIs
| Media SDK | AEP Roku SDK| Sample |
| -- | -- | -- |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_START, chapterInfo, chapterContextData)` | `sendMediaEvent(chapterStartXDM)` | [ChapterStart](#chapterstart) |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_COMPLETE, invalid, invalid)` | `sendMediaEvent(chapterCompleteXDM)` | [ChapterComplete](#chaptercomplete) |
| `mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_SKIP, invalid, invalid)` | `sendMediaEvent(chapterSkipXDM)` | [ChapterSkip](#chapterskip) |

### Quality of Experience (QoE) and Error APIs
| Media SDK | AEP Roku SDK| Sample |
| -- | -- | -- |
| `mediaUpdateQoS(qosinfo)` | `sendMediaEvent(bitrateChangeXDM)` | [UpdateQoS](#updateqos) |
| `mediaTrackEvent(ADBMobile().MEDIA_BITRATE_CHANGE)` | `sendMediaEvent(bitrateChangeXDM)` | [BitrateChange](#bitratechange) |
| `mediaTrackError(errorId, ADBMobile().ERROR_SOURCE_PLAYER)` | `sendMediaEvent(errorXDM)` | [Error](#trackerror) |

> [!NOTE]
> QoE info has to be attached to the xdmData when calling `sendMediaEvent(bitrateChangeXDM)` for `bitrateChange` event. QoE info can also be attached to any other event's xdm data the sendMediaEvent(eventXDM) API. Refer to the [QoeDataDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/qoedatadetails.schema.md) fieldgroup

### Playhead update API
| Media SDK | AEP Roku SDK|
| -- | -- |
| `mediaUpdatePlayhead(position)` | NA (sent with all the APIs in the xdm data) |

## PlayerState Tracking API
| Media SDK | AEP Roku SDK|
| -- | -- |
| NA | `sendMediaEvent(statesUpdateXDM)` |

### Helper APIs
| Media SDK | AEP Roku SDK|
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

**AEP Roku SDK**

```brightscript
' Create SDK instance
m.aepSdk = AdobeAEPSDKInit()
```

> [!NOTE]
> AEP Roku SDK creates the taskNode internally.

## Start Media session

### trackSessionStart

**Media SDK**

``` brightscript
' Use the helper method to create mediaInfo object
name = "mediaName"
id = "mediaId"
length = 10
streamType = ADBMobile().MEDIA_STREAM_TYPE_VOD
mediaType = ADBMobile().MEDIA_TYPE_VIDEO

mediaInfo = adb_media_init_mediainfo(name, id, length, streamType, mediaType)

' (Optional) Attach standard metadata if any
standardMetadata = {}
standardMetadata[ADBMobile().MEDIA_VideoMetadataKeySHOW] = "sample show"

mediaInfo[ADBMobile().MEDIA_STANDARD_MEDIA_METADATA] = standardMetadata

' (Optional) Create map for custom metadadata if any
mediaContextData = {}
mediaContextData["cmk1"] = "cmv1"

' Call mediaTrackSessionStart API
m.adbmobile.mediaTrackSessionStart(mediaInfo, mediaContextData)
```

**AEP Roku SDK**

> [!IMPORTANT]
> createMediaSession() API requires [sessionDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md) fieldgroup with all the required fields present in the request payload.

| SessionDetails Fields (Required) |
| -- |
| [friendlyName](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmfriendlyname) |
| [name](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmname) |
| [length](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmlength) |
| [contentType](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmcontenttype) |
| [streamType](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmstreamtype) |
| [channel](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmchannel) |
| [playerName](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmplayername) |

``` brightscript
sessionDetails = {
    ' (Required)
    "friendlyName": "mediaName",
    "name": "mediaId",
    "length": 10,
    "contentType": "vod",
    "streamType" : "video",

    ' (Required) Auto populated by the SDK based on Media configuration
    "channel": "sampleChannel",
    "playerName": "playerName,

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
      "playhead":  <CURRENT_PLAYHEAD_INTEGER_VALUE>,
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

**AEP Roku SDK**

``` brightscript
playXDM = {
  "xdm": {
    "eventType": "media.play",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
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

**AEP Roku SDK**

``` brightscript
pauseStartXDM = {
  "xdm": {
    "eventType": "media.pauseStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
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

**AEP Roku SDK**

``` brightscript
sessionCompleteXDM = {
  "xdm": {
    "eventType": "media.sessionComplete",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
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

**AEP Roku SDK**

``` brightscript
sessionEndXDM = {
  "xdm": {
    "eventType": "media.sessionEnd",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
    }
  }
}

m.aepSdk.sendMediaEvent(sessionEndXDM)
```

---

### trackEvent

#### Track Ads

#### AdBreakStart

**Media SDK**

``` brightscript
name = "adBreakName"
position = 1
startTime = 0

adBreakInfo = adb_media_init_adbreakinfo(name, position, startTime)

m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_START, adBreakInfo, invalid)
```

**AEP Roku SDK**

> [!IMPORTANT]
> sendMediaEvent() API for event type `media.adBreakStart` requires [advertisingPodDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingpoddetails.schema.md) fieldgroup with all the required fields present in the request payload.

| AdvertisingPodDetails Fields (Required) |
| -- |
| [friendlyName](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingpoddetails.schema.md#xdmfriendlyname) |
| [index](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingpoddetails.schema.md#xdmindex) |
| [offset](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingpoddetails.schema.md#xdmoffset) |

``` brightscript
advertisingPodDetails = {
  ' (Required)
  "friendlyName": "adBreakName",
  "index": 1,
  "offset": 0
}

adBreakStartXDM = {
  "xdm": {
    "eventType": "media.adBreakStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "advertisingPodDetails": advertisingPodDetails
    }
  }
}

m.aepSdk.sendMediaEvent(adBreakStartXDM)
```

#### AdbreakComplete
``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_AD_BREAK_COMPLETE, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
adBreakCompleteXDM = {
  "xdm": {
    "eventType": "media.adBreakComplete",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(adBreakCompleteXDM)
```


#### AdStart

**Media SDK**

``` brightscript
name = "adName"
position = 1
length = 10
startTime = 0

adInfo = adb_media_init_adinfo(name, position, startTime)

''' (Optional) Attach standard metadata if any
standardAdMetadata = {}
standardAdMetadata[ADBMobile().MEDIA_AdMetadataKeyCAMPAIGN_ID] = "sampleCampaignID"

adInfo[ADBMobile().MEDIA_STANDARD_AD_METADATA] = standardAdMetadata

''' (Optional) Create a map of custom metadata if any
adContextData = {}
adContextData["cmk1"] = "cmv1"

m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_AD_START, adInfo, adContextData)
```

**AEP Roku SDK**

> [!IMPORTANT]
> sendMediaEvent() API for event type `media.adStart` requires [advertisingDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md) fieldgroup with all the required fields present in the request payload.

| AdvertisingDetails Fields (Required) |
| -- |
| friendlyName |
| name |
| [podPosition](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmpodposition) |
| [length](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmlength) |
| [playerName](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmplayername) |

``` brightscript
advertisingDetails = {
  ' (Required)
  "friendlyName": "adName",
  "name": "adId",
  "podPosition": 1,
  "length": 10,
  "playerName": "samplePlayerName"

  ' (Optional) Attach Standard metadata if any
  "campaignID": "sampleCampaignID"
}

' (Optional) Create map for custom data if any
customMetadata = {
  "cmk1":"cmv1"
}

adStartXDM = {
  "xdm": {
    "eventType": "media.adStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "advertisingDetails": advertisingDetails,
      "customMetadata": customMetadata
    }
  }
}

m.aepSdk.sendMediaEvent(adStartXDM)
```

> [!NOTE]
> To learn more refer to the [advertisingDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md) XDM fieldgroup.

#### AdComplete

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_AD_COMPLETE, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
adCompleteXDM = {
  "xdm": {
    "eventType": "media.adComplete",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(adCompleteXDM)
```

#### AdSkip

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_AD_SKIP, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
adSkipXDM = {
  "xdm": {
    "eventType": "media.adSkip",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(adSkipXDM)
```

#### Track Chapters

##### ChapterStart

**Media SDK**

``` brightscript
name = "chapterName"
position = 1
length = 10
startTime = 0

chapterInfo = adb_media_init_chapterinfo(name, position, length, startTime)

''' (Optional) Create a map of custom metadata if any
chapterContextData = {}
chapterContextData["cmk1"] = "cmv1"

m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_START, chapterInfo, chapterContextData)
```

**AEP Roku SDK**

> [!IMPORTANT]
> sendMediaEvent() API for event type `media.chapterStart` requires [chapterDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/chapterdetails.schema.md) fieldgroup with all the required fields present in the request payload.

| ChapterDetails Fields (Required) |
| -- |
| [friendlyName](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/chapterdetails.schema.md#xdmfriendlyname) |
| [index](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/chapterdetails.schema.md#xdmindex) |
| [length](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/chapterdetails.schema.md#xdmlength) |
| [offset](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/chapterdetails.schema.md#xdmoffset) |

``` brightscript
chapterDetails = {
  "friendlyName": "chapterName",
  "index":1,
  "length": 10,
  "offset": 0
}

' (Optional) Create map for custom data if any
customMetadata = {
  "cmk1":"cmv1"
}

chapterStartXDM = {
  "xdm": {
    "eventType": "media.chapterStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "chapterDetails": chapterDetails,
      "customMetadata": customMetadata
    }
  }
}

m.aepSdk.sendMediaEvent(chapterStartXDM)
```

> [!NOTE]
> To learn more refer to the [chapterDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/chapterdetails.schema.md) XDM fieldgroup.

##### ChapterComplete

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_COMPLETE, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
chapterCompleteXDM = {
  "xdm": {
    "eventType": "media.chapterComplete",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(chapterCompleteXDM)
```

##### ChapterSkip

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_CHAPTER_SKIP, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
chapterSkipXDM = {
  "xdm": {
    "eventType": "media.chapterSkip",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(chapterSkipXDM)
```

#### Track Buffer and Seek

##### BufferStart

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(MEDIA_BUFFER_START, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
bufferStartXDM = {
  "xdm": {
    "eventType": "media.bufferStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(bufferStartXDM)
```

##### BufferComplete

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_BUFFER_COMPLETE, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
bufferCompleteXDM = {
  "xdm": {
    "eventType": "media.bufferComplete",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(bufferCompleteXDM)
```

##### SeekStart

> [!IMPORTANT]
> Seeking is detected automatically by the backend using the playhead and timestamp value. So at the seek start, playback pauses and can be tracked as `pauseStart` and when seek completes, playback resumes and can be tracked as `play`.

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_SEEK_START, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
seekStartXDM = {
  "xdm": {
    "eventType": "media.pauseStart",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(seekStartXDM)
```

##### SeekComplete

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_SEEK_COMPLETE, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
seekCompleteXDM = {
  "xdm": {
    "eventType": "media.play",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}

m.aepSdk.sendMediaEvent(seekCompleteXDM)
```
---

##### BitrateChange

**Media SDK**

``` brightscript
' Use the helper method to create mediaInfo object
bitrate = 200000
fps = 24
droppedFrames = 1
startupTime = 2
qosInfo = m.adbmobile.adb_media_init_qosinfo(bitrate, startupTime, fps, droppedFrames)

m.adbmobile.mediaUpdateQoS(qosInfo)

m.adbmobile.mediaTrackEvent(ADBMobile().MEDIA_BITRATE_CHANGE, invalid, invalid)
```

**AEP Roku SDK**

``` brightscript
qoeDataDetails = {
  "bitrate" : 200000,
  "framesPerSecond" : 24,
  "droppedFrames" : 1,
  "timeToStart" : 2
}

bitrateChangeXDM = {
  "xdm": {
    "eventType": "media.bitrateChange",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "qoeDataDetails": qoeDataDetails
    }
  }
}

m.aepSdk.sendMediaEvent(bitrateChangeXDM)
```
---

### updateCurrentPlayhead

**Media SDK**

``` brightscript
m.adbmobile.updateCurrentPlayhead(<CURRENT_PLAYHEAD_INTEGER_VALUE>)
```

**AEP Roku SDK**

> [!IMPORTANT]
> Playhead value is expected in the XDM data for all the API calls. AEP Roku SDK requires calling ping event with latest playhead value every second as a proxy for updateCurrentPlayhead API.

```brightscript
playheadUpdatePingXDM = {
  "xdm": {
    "eventType": "media.ping",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>
    }
  }
}


m.aepSdk.sendMediaEvent(playheadUpdatePingXDM)
```

---

### updateQoS

**Media SDK**

``` brightscript
' Use the helper method to create mediaInfo object
bitrate = 200000
fps = 24
droppedFrames = 1
startupTime = 2
qosInfo = m.adbmobile.adb_media_init_qosinfo(bitrate, startupTime, fps, droppedFrames)

m.adbmobile.mediaUpdateQoS(qosInfo)
```

**AEP Roku SDK**

> [!IMPORTANT]
> All the QoE field values should be of `Integer` data type.

``` brightscript
qoeDataDetails = {
  "bitrate" : 200000,
  "framesPerSecond" : 24,
  "droppedFrames" : 1,
  "timeToStart" : 2
}

bitrateChangeXDM = {
  "xdm": {
    "eventType": "media.bitrateChange",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "qoeDataDetails": qoeDataDetails
    }
  }
}

m.aepSdk.sendMediaEvent(bitrateChangeXDM)
```

> [!NOTE]
> To learn more refer to the [qoeDataDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/qoedatadetails.schema.md) XDM fieldgroup.
> `qoeDataDetails` is supported and can be attached to any event going out.

Following is the sample to send qoeDataDetails with play event:

``` brightscript
playWithQoeXDM = {
  "xdm": {
    "eventType": "media.play",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "qoeDataDetails": qoeDataDetails
    }
  }
}

m.aepSdk.sendMediaEvent(playWithQoeXDM)
```
---

### trackError

**Media SDK**

``` brightscript
m.adbmobile.mediaTrackError("errorId", "video-player-error-code")
```

**AEP Roku SDK**
``` brightscript
errorDetails = {
  "name": "errorId",
  "source": "video-player-error-code"
}

errorXDM = {
  "xdm": {
    "eventType": "media.error",
    "mediaCollection": {
      "playhead": <CURRENT_PLAYHEAD_INTEGER_VALUE>,
      "errorDetails": errorDetails
    }
  }
}

m.aepSdk.sendMediaEvent(errorXDM)
```

> [!NOTE]
> To learn more refer to the [errorDetails](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/errordetails.schema.md) XDM fieldgroup.

## Public Constants

### StreamType

| Media SDK | AEP Roku SDK |
| -- | -- |
| MEDIA_STREAM_TYPE_VOD | "vod" |
| MEDIA_STREAM_TYPE_LIVE | "live" |
| MEDIA_STREAM_TYPE_LINEAR | "linear" |
| MEDIA_STREAM_TYPE_AOD | "aod" |
| MEDIA_STREAM_TYPE_AUDIOBOOK | "audiobook" |
| MEDIA_STREAM_TYPE_PODCAST | "podcast" |

### MediaType

| Media SDK | AEP Roku SDK |
| -- | -- |
| MEDIA_STREAM_TYPE_AUDIO | [xdm:streamType](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmstreamtype-known-values) |
| MEDIA_STREAM_TYPE_VIDEO | [xdm:streamType](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmstreamtype-known-values) |

### Standard Video Metadata

| Media SDK | AEP Roku SDK |
| -- | -- |
| MEDIA_VideoMetadataKeyAD_LOAD                 | [xdm:adLoad](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmadload) |
| MEDIA_VideoMetadataKeyASSET_ID                | [xdm:assetID](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmassetid) |
| MEDIA_VideoMetadataKeyAUTHORIZED              | [xdm:authorized](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmisauthorized) |
| MEDIA_VideoMetadataKeyDAY_PART                | [xdm:dayPart](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmdaypart) |
| MEDIA_VideoMetadataKeyEPISODE                 | [xdm:episode](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmepisode) |
| MEDIA_VideoMetadataKeyFEED                    | [xdm:feed](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmfeed) |
| MEDIA_VideoMetadataKeyFIRST_AIR_DATE          | [xdm:firstAirDate](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmfirstairdate) |
| MEDIA_VideoMetadataKeyFIRST_DIGITAL_DATE      | [xdm:firstDigitalDate](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmfirstdigitaldate) |
| MEDIA_VideoMetadataKeyGENRE                   | [xdm:genre](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmgenre) |
| MEDIA_VideoMetadataKeyMVPD                    | [xdm:mvpd](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmmvpd) |
| MEDIA_VideoMetadataKeyNETWORK                 | [xdm:network](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmnetwork) |
| MEDIA_VideoMetadataKeyORIGINATOR              |[xdm:originator](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmoriginator) |
| MEDIA_VideoMetadataKeyRATING                  | [xdm:rating](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmrating) |
| MEDIA_VideoMetadataKeySEASON                  | [xdm:season](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmseason) |
| MEDIA_VideoMetadataKeySHOW                    | [xdm:show](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmshow) |
| MEDIA_VideoMetadataKeySHOW_TYPE               | [xdm:showType](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmshowtype) |
| MEDIA_VideoMetadataKeySTREAM_FORMAT           | [xdm:streamFormat](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmstreamformat) |

### Standard Audio Metadata

| Media SDK | AEP Roku SDK |
| -- | -- |
| MEDIA_AudioMetadataKeyARTIST    | [xdm:artist](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmartist) |
| MEDIA_AudioMetadataKeyAUTHOR    | [xdm:author](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmauthor) |
| MEDIA_AudioMetadataKeyLABEL     | [xdm:label](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmlabel) |
| MEDIA_AudioMetadataKeyPUBLISHER | [xdm:publisher](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmpublisher) |
| MEDIA_AudioMetadataKeySTATION   | [xdm:station](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/sessiondetails.schema.md#xdmstation) |
### Standard Ad Metadata

| Media SDK | AEP Roku SDK |
| -- | -- |
| MEDIA_AdMetadataKeyADVERTISER   | [xdm:advertiser](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmadvertiser)  |
| MEDIA_AdMetadataKeyCAMPAIGN_ID  | [xdm:campaignID](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmcampaignid) |
| MEDIA_AdMetadataKeyCREATIVE_ID  | [xdm:creativeID](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmcreativeid) |
| MEDIA_AdMetadataKeyCREATIVE_URL | [xdm:creativeURL](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmcreativeurl) |
| MEDIA_AdMetadataKeyPLACEMENT_ID | [xdm:placementID](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmplacementid) |
| MEDIA_AdMetadataKeySITE_ID      | [xdm:siteID](https://github.com/adobe/xdm/blob/master/docs/reference/datatypes/advertisingdetails.schema.md#xdmsiteid) |

