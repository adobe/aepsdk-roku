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
  m.ButtonGroup = m.top.findNode("ButtonGroup")
  m.Warning = m.top.findNode("WarningDialog")
  setContent()
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("buttonSelected", "onButtonSelected")
  m.timer = m.top.findNode("MainTimer")
  m.timer.control = "start"
  m.timer.ObserveField("fire", "timerExecutor")
  m.test_shutdown = false

  _initSDK()
end sub

sub _initSDK()
  '------------------------------------
  ' Initalize Adobe Edge SDK
  '------------------------------------

  m.adobeEdgeSdk = AdobeSDKInit()
  print "Adobe SDK version : " + m.adobeEdgeSdk.getVersion()

  ADB_CONSTANTS = AdobeSDKConstants()
  m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

  configuration = {}
  test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
  if test_config <> invalid and test_config.count() > 0
    configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = test_config.config_id
  end if

  m.adobeEdgeSdk.updateConfiguration(configuration)

end sub

sub _sendEventWithCallback()
  '----------------------------------------
  ' Send an Experience Event with callback
  '----------------------------------------

  m.adobeEdgeSdk.sendEvent({
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
  }, sub(context, result)
    print "callback result: "
    print result
    print context
    jsonObj = ParseJson(result.message)
    message = ""
    for each item in jsonObj.handle
      if item.type = "locationHint:result" then
        for each data in item.payload
          if data.scope = "EdgeNetwork" then
            message = "locationHint:EdgeNetwork: " + data.hint
          end if
        end for
      end if
    end for

    ' show result in dialog
    context.Warning.visible = "true"

    context.Warning.message = message
  end sub, m)
end sub

sub _testShutdownAPI()
  if m.adobeEdgeSdk = invalid
    throw "Adobe Edge SDK is not initialized"
  end if

  counter = 0
  while counter < 20
    m.adobeEdgeSdk.sendEvent({
      "eventType": "commerce.orderPlaced",
      "commerce": {
        "key1": "value1",
        "counter": counter
      }
    })
    counter++
  end while
  ' print "+++++++++++++++++++++++ counter:"; counter

  m.test_shutdown = true
end sub

sub onButtonSelected()

  if m.ButtonGroup.buttonSelected = 0
    'SendEventWithCallback button pressed
    _sendEventWithCallback()

  else if m.ButtonGroup.buttonSelected = 1
    'Shutdown button pressed
    _testShutdownAPI()


  else
  end if
end sub

'Set your information here
sub setContent()

  'Change the buttons
  Buttons = ["SendEventWithCallback", "Shutdown", "2"]
  m.ButtonGroup.buttons = Buttons

end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as string, press as boolean) as boolean
  print "in MainScene.xml onKeyEvent ";key;" "; press
  if press then
    if key = "back"
      print "------ [back pressed] ------"
      if m.Warning.visible
        m.Warning.visible = false
        m.ButtonGroup.setFocus(true)
        return true
      else if m.Video.visible
        m.Video.control = "stop"
        m.Video.visible = false
        m.ButtonGroup.setFocus(true)
        return true
      else
        return false
      end if
    else if key = "OK"
      print "------- [ok pressed] -------"
      if m.Warning.visible
        m.Warning.visible = false
        m.ButtonGroup.setFocus(true)
        return true
      end if
    else
      return false
    end if
  end if
  return false
end function

sub timerExecutor()
  if m.test_shutdown
    m.adobeEdgeSdk.shutdown()
    m.adobeEdgeSdk = invalid

    m.adobeEdgeSdk_2 = AdobeSDKInit()
    ADB_CONSTANTS = AdobeSDKConstants()
    m.adobeEdgeSdk_2.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

    configuration = {}

    test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
    if test_config <> invalid and test_config.count() > 0
      configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = test_config.config_id
    end if
    m.adobeEdgeSdk_2.updateConfiguration(configuration)

    m.adobeEdgeSdk_2.sendEvent({
      "eventType": "commerce.orderPlaced",
      "commerce": {
        "key3": "value3"
      }
    }, sub(context, result)
      ' print "callback result: "
      print result
      print context
      jsonObj = ParseJson(result.message)
      message = ""
      for each item in jsonObj.handle
        if item.type = "locationHint:result" then
          for each data in item.payload
            if data.scope = "EdgeNetwork" then
              message = "shutdown -> re-init -> sendEvent: " + data.hint
            end if
          end for
        end if
      end for

      ' show result in dialog
      context.Warning.visible = "true"

      context.Warning.message = message
    end sub, m)

  end if

  m.test_shutdown = false
end sub