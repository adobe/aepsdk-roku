' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

sub init()
  m.dialog = m.top.findNode("messageDialog")

  m.ButtonGroup = m.top.findNode("ButtonGroup")
  m.ButtonGroup.buttons = ["SendEventWithCallback", "NewScreen(API)", "MediaTracking"]
  m.ButtonGroup.observeField("buttonSelected", "onButtonSelected")

  m.videoTimer = m.top.findNode("VideoTimer")
  m.videoTimer.control = "none"
  m.videoTimer.ObserveField("fire", "videoTimerExecutor")

  m.video = m.top.findNode("Video")
  m.video.content = _createContentNode()
  m.video.observeField("state", "onVideoPlayerStateChange")

  _focusOnButtonGroup()

  _initSDK()
end sub

sub _initSDK()
  '------------------------------------
  ' Initalize Adobe Edge SDK
  '------------------------------------

  m.aepSdk = AdobeAEPSDKInit()
  print "Adobe SDK version : " + m.aepSdk.getVersion()
  m.adobeTaskNode = m.aepSdk.getTaskNode()

  ' The task node has a default id => "adobeTaskNode"
  ' If you want to set it to another value, you can enable the below code
  ' m.adobeTaskNode.id = "customized_adobe_task_node_id"
  m.top.appendChild(m.adobeTaskNode)

  ADB_CONSTANTS = AdobeAEPSDKConstants()
  m.aepSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

  configuration = {}

  configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = ""
  ' Note: the below Edge domain configuration is optional
  ' configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = ""
  configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_CHANNEL] = "channel_test_roku"
  configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_PLAYER_NAME] = "player_test_roku"
  configuration[ADB_CONSTANTS.CONFIGURATION.MEDIA_APP_VERSION] = "1.0.0"
  m.aepSdk.updateConfiguration(configuration)

  m.video_position = 0

end sub

sub _sendEventWithCallback()
  '----------------------------------------
  ' Send an Experience Event with callback
  '----------------------------------------

  m.aepSdk.sendEvent({
    "xdm": {
      "eventType": "commerce.orderPlaced",
      "commerce": {
        "key3": "value3"
      },
      "identityMap": {
        "RIDA": [
          {
            "id": "SampleAdId",
            "authenticatedState": "ambiguous",
            "primary": false
          }
        ]
      }
    },
    "data": {
      "key": "value"
    }
  }, sub(context, result)
    jsonObj = ParseJson(result.message)
    message = _extractLocationHint(jsonObj, "Not found locationHint")
    ' show result in dialog
    context.dialog.visible = "true"
    context.dialog.message = message
  end sub, m)
end sub

function _extractLocationHint(jsonObj as object, defaultMessage as string) as string
  message = defaultMessage
  for each item in jsonObj.handle
    if item.type = "locationHint:result" then
      for each data in item.payload
        if data.scope = "EdgeNetwork" then
          message = "locationHint: " + data.hint
        end if
      end for
    end if
  end for
  return message
end function

sub onButtonSelected()
  ' 0: "SendEventWithCallback",  1: "NewScreen(API)", 2: "MediaTracking"
  if m.ButtonGroup.buttonSelected = 0
    _sendEventWithCallback()
  else if m.ButtonGroup.buttonSelected = 1
    _createAndShowNewScreen()
  else if m.ButtonGroup.buttonSelected = 2
    _showVideoScreen()
  else
  end if
end sub

sub _createAndShowNewScreen()
  ' when creating a new screen, a new SDK instance will be created as well
  ' add this logic for creating/deleting multiple SDK instances, then to test the SDK instances are destroied correctly.
  if m.newScreen <> invalid
    m.top.removeChild(m.newScreen)
    m.newScreen = invalid
  end if

  m.newScreen = createObject("roSGNode", "NewScreen")
  m.top.appendChild(m.newScreen)

  _hideButtonGroup()
  _focusOnNewScreen()
end sub

sub _showVideoScreen()
  m.video.visible = true
  m.video.control = "play"
  m.video.setFocus(true)
  m.video_position = 0

  MEDIA_SESSION_CONFIGURATION = AdobeAEPSDKConstants().MEDIA_SESSION_CONFIGURATION
  sessionConfiguration = {}
  sessionConfiguration[MEDIA_SESSION_CONFIGURATION.AD_PING_INTERVAL] = 10
  sessionConfiguration[MEDIA_SESSION_CONFIGURATION.MAIN_PING_INTERVAL] = 20
  sessionConfiguration[MEDIA_SESSION_CONFIGURATION.CHANNEL] = "session_level_channel_name"

  ' Note: the session level configuration is optional, it overrides the global configuration for media events within the session
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
  }, sessionConfiguration)

end sub

sub _focusOnNewScreen()
  if m.newScreen <> invalid
    m.newScreen.visible = true
    m.newScreen.setFocus(true)
  end if
end sub

sub _focusOnButtonGroup()
  m.ButtonGroup.visible = true
  m.ButtonGroup.setFocus(true)
end sub

sub _hideButtonGroup()
  m.ButtonGroup.visible = false
end sub

sub _hideDialog()
  if m.dialog <> invalid
    m.dialog.visible = false
  end if
end sub

sub _hideNewScreen()
  if m.newScreen <> invalid
    m.newScreen.visible = false
  end if
end sub

sub _stopAndHideVideoScreen()
  if m.video <> invalid
    m.video.control = "stop"
    m.video.visible = false
  end if
end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as string, press as boolean) as boolean
  if press then
    if key = "back"
      if m.dialog.visible
        _hideDialog()
        _focusOnButtonGroup()
        return true
      else if m.newScreen <> invalid and m.newScreen.visible
        _hideNewScreen()
        _focusOnButtonGroup()
        return true
      else if m.video.visible
        _stopAndHideVideoScreen()
        _focusOnButtonGroup()
        return true
      else
        return false
      end if
    else if key = "OK"
      if m.dialog.visible
        _hideDialog()
        _focusOnButtonGroup()
        return true
      end if
    else
      ' other keys pressed
      return false
    end if
  end if
  return false
end function

function _createContentNode() as object
  contentNode = CreateObject("roSGNode", "ContentNode")
  contentNode.streamFormat = "mp4"
  contentNode.url = "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"
  contentNode.StarRating = 80
  contentNode.Length = 1280
  contentNode.Title = "Dan Gilbert asks, Why are we happy?"
  return contentNode
end function

sub onVideoPlayerStateChange()
  '--------------------
  ' Send Media events
  '--------------------
  position = m.video_position
  if m.video.state = "error"
    m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.error",
        "mediaCollection": {
          "playhead": position,
          "qoeDataDetails": {
            "bitrate": 35000,
            "droppedFrames": 30
          },
          "errorDetails": {
            "name": "test-buffer-start",
            "source": "player"
          }
        }
      }
    })
  else if m.video.state = "buffering"
    m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.bufferStart",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })

  else if m.video.state = "playing"
    m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.play",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })
    m.videoTimer.control = "start"
  else if m.video.state = "stopped"
    m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.sessionEnd",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })
    m.videoTimer.control = "stop"
  else if m.video.state = "finished"
    m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.sessionComplete",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })
    m.videoTimer.control = "stop"
  else if m.video.state = "paused"
    m.aepSdk.sendMediaEvent({
      "xdm": {
        "eventType": "media.pauseStart",
        "mediaCollection": {
          "playhead": position,
        }
      }
    })
  else
    print "onVideoPlayerStateChange: " + m.video.state
  end if
end sub

sub videoTimerExecutor()
  '--------------------
  ' Send Media pings
  '--------------------
  print "Video timer started to fire a ping event on video position : " m.video.position
  position = m.video_position
  m.aepSdk.sendMediaEvent({
    "xdm": {
      "eventType": "media.ping",
      "mediaCollection": {
        "playhead": position,
      }
    }
  })
  m.video_position = m.video.position
end sub