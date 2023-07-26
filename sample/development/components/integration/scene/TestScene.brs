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
  m.Warning = m.top.findNode("WarningDialog")
  m.timer = m.top.findNode("testTimer")
  m.timer.control = "start"
  m.timer.ObserveField("fire", "executeTests")
  m.sdkInstance = invalid
  setupTest()
end sub

sub setupTest()
  m.sdkInstance = AdobeSDKInit()
  taskNode = _adb_retrieveTaskNode()
  taskNode.addField("debugInfo", "assocarray", true)
  taskNode.observeField("debugInfo", "onDebugInfoChange")

  m.testRunner = ADBTestRunner()
  testSuite = TS_SDK_integration()
  m.testRunner.init(testSuite)
end sub

sub onDebugInfoChange()
  taskNode = _adb_retrieveTaskNode()
  info = taskNode.getField("debugInfo")
  m.testRunner.addDebugInfo(info)
end sub

sub executeTests()
  hasNext = m.testRunner.execute()
  if not hasNext then
    m.sdkInstance.shutdown()
  end if
end sub
