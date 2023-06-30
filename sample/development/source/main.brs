
' 1st function called when channel application starts.
sub Main(input as dynamic)
  ' print input
  if input <> invalid
    if input.RunTests = "true" and type(TestRunner) = "Function" then
      _adb_run_tests()
    end if
  end if

  _adb_run_tests()

  showHeroScreen()
end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen()
  print "main.brs - [showHeroScreen]"
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  _scene = screen.CreateScene("MainScene")
  screen.show()
  ' vscode_rdb_on_device_component_entry

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
  end while
end sub


