
' 1st function that runs for the scene component on channel startup
sub init()
  'To see print statements/debug info, telnet on port 8089
  m.Image = m.top.findNode("Image")
  m.ButtonGroup = m.top.findNode("ButtonGroup")
  m.Details = m.top.findNode("Details")
  m.Title = m.top.findNode("Title")
  m.Video = m.top.findNode("Video")
  m.Warning = m.top.findNode("WarningDialog")
  m.Exiter = m.top.findNode("Exiter")
  setContent()
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("buttonSelected", "onButtonSelected")


  '------------------------------------
  ' Initalize Adobe Edge SDK
  '------------------------------------

  ADB_CONSTANTS = AdobeSDKConstants()
  m.adobeEdgeSdk = AdobeSDKInit()
  print "Adobe SDK version : " + m.adobeEdgeSdk.getVersion()

  m.adobeEdgeSdk.setLogLevel(ADB_CONSTANTS.LOG_LEVEL.VERBOSE)

  ' get_mid_from_media_sdk = "12340203495818708"
  ' m.adobeEdgeSdk.setExperienceCloudId(get_mid_from_media_sdk)

  configuration = {}
  configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_CONFIG_ID] = ""
  'configuration[ADB_CONSTANTS.CONFIGURATION.EDGE_DOMAIN] = ""
  m.adobeEdgeSdk.updateConfiguration(configuration)

  m.adobeEdgeSdk.sendEdgeEvent({
    "eventType": "commerce.orderPlaced",
    "commerce": {
      "key1": "value1"
    }
  })

  ' m.adobeEdgeSdk.resetIdentities()

  ' m.adobeEdgeSdk.sendEdgeEvent({
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

    m.adobeEdgeSdk.sendEdgeEvent({
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

  m.Image.uri = "pkg:/images/CraigVenter-2008.jpg"
  ContentNode = CreateObject("roSGNode", "ContentNode")
  ContentNode.streamFormat = "mp4"
  ContentNode.url = "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"
  ContentNode.ShortDescriptionLine1 = "Can we create new life out of our digital universe?"
  ContentNode.Description = "He walks the TED2008 audience through his latest research into fourth-generation fuels -- biologically created fuels with CO2 as their feedstock. His talk covers the details of creating brand-new chromosomes using digital technology, the reasons why we would want to do this, and the bioethics of synthetic life. A fascinating Q and A with TED's Chris Anderson follows."
  ContentNode.StarRating = 80
  ContentNode.Length = 1972
  ContentNode.Title = "Craig Venter asks, Can we create new life out of our digital universe?"
  ContentNode.subtitleConfig = { Trackname: "pkg:/source/CraigVenter.srt" }

  m.Video.content = ContentNode

  'Change the buttons
  Buttons = ["Play", "SendEvent", "Exit"]
  m.ButtonGroup.buttons = Buttons

  'Change the details
  m.Title.text = "Craig Venter asks, Can we create new life out of our digital universe?"
  m.Details.text = "He walks the TED2008 audience through his latest research into fourth-generation fuels -- biologically created fuels with CO2 as their feedstock. His talk covers the details of creating brand-new chromosomes using digital technology, the reasons why we would want to do this, and the bioethics of synthetic life. A fascinating Q and A with TED's Chris Anderson follows."

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
