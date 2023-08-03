' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

sub Main(input as dynamic)
  if input <> invalid
    if input.RunTests = "true" and type(TestRunner) = "Function" then
      _adb_run_tests()
    end if
  end if

  #if unitTests
    _adb_run_tests()

  #else if integrationTests

    showHomeScreen("TestScene")

  #else

    showHomeScreen()

  #end if

end sub

sub showHomeScreen(scenenName = "MainScene" as string)
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  _scene = screen.CreateScene(scenenName)
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
