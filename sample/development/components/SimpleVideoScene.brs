
' 1st function that runs for the scene component on channel startup
sub init()
  m.ButtonGroup = m.top.findNode("ButtonGroup")
  m.Warning = m.top.findNode("WarningDialog")
  m.Exiter = m.top.findNode("Exiter")
  setContent()
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("buttonSelected", "onButtonSelected")


  '------------------------------------
  ' Initalize Adobe Edge SDK
  '------------------------------------


  m.adobeEdgeSdk = AdobeSDKInit()
  print "Adobe SDK version : " + m.adobeEdgeSdk.getVersion()

  ADB_CONSTANTS = AdobeSDKConstants()
  m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

  ' get_mid_from_media_sdk = "12340203495818708"
  ' m.adobeEdgeSdk.setExperienceCloudId(get_mid_from_media_sdk)

  configuration = {}

  test_config = ParseJson(ReadAsciiFile("pkg:/source/test_config.json"))
  if test_config.count() > 0
    configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = test_config.config_id
  end if

  ' configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = ""
  'configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = ""
  m.adobeEdgeSdk.updateConfiguration(configuration)

  m.adobeEdgeSdk.sendEvent({
    "eventType": "commerce.orderPlaced",
    "commerce": {
      "key1": "value1"
    }
  })

  ' m.adobeEdgeSdk.resetIdentities()

  ' m.adobeEdgeSdk.sendEvent({
  '   "eventType": "commerce.orderPlaced",
  '   "commerce": {
  '     "key2": "value2"
  '   }
  ' })

end sub

sub onButtonSelected()
  'Ok'
  if m.ButtonGroup.buttonSelected = 0
    m.Video.visible = "true"
    m.Video.control = "play"
    m.Video.setFocus(true)
    'Exit button pressed'
    'SendEvent button pressed
  else if m.ButtonGroup.buttonSelected = 1

    '----------------------------------------
    ' Send an Experience Event with callback
    '----------------------------------------

    m.adobeEdgeSdk.sendEvent({
      "eventType": "commerce.orderPlaced",
      "commerce": {
        "key3": "value3"
      }
    }, sub(context, result)
      print "callback result: "
      print result
      print context

      ' show result in dialog
      ' context.Warning.visible = "true"
      ' context.Warning.message = result.data.message
    end sub, m)

  else
    m.Exiter.control = "RUN"
  end if
end sub

'Set your information here
sub setContent()

  'Change the buttons
  Buttons = ["Play", "SendEvent", "Exit"]
  m.ButtonGroup.buttons = Buttons

end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as string, press as boolean) as boolean
  print "in SimpleVideoScene.xml onKeyEvent ";key;" "; press
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
