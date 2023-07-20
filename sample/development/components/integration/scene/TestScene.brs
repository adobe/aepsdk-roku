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

  setupTest()
end sub

sub setupTest()
  AdobeSDKInit()
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
  m.testRunner.execute()
end sub

' *****************************************************************************************
' ****************************** ADBTestRunner ********************************************
' *****************************************************************************************

function ADBTestRunner() as object
  runner = {
    execute: function() as boolean
      return m._execute()
    end function,

    addDebugInfo: sub(info as object)
      m._addDebugInfo(info)
    end sub,

    init: sub(testSuite as object)
      GetGlobalAA()._adb_assert_result_map = {}
      GetGlobalAA()._adb_assert_current_tc_name = "unknown"
      m._loadTestSuite(testSuite)
    end sub
  }

  runner.Append({
    _debugInfoMap: {},
    _currentValidater: invalid,
    _testSuite: {},
    _testCaseNameArray: [],
    _resultMap: {},

    _addDebugInfo: sub(info as object)
      m._debugInfoMap[info.eventId] = info
    end sub,

    _loadTestSuite: sub(testSuite as object)
      m._testSuite = testSuite
      for each item in testSuite.Items()
        key = item.key
        value = item.value
        if m._isFunction(value) and m._isStartWith(LCase(key), "tc_") then
          m._testCaseNameArray.Push(key)
        end if
      end for
      _adb_logInfo("TestSuite loaded: " + FormatJson(m._testCaseNameArray))
    end sub,

    _hasNoExecutor: function() as boolean
      if m._currentValidater = invalid and m._testCaseNameArray.Count() = 0 then
        return true
      end if
      return false
    end function,

    _execute: function() as boolean

      if m._hasNoExecutor() then
        return false
      end if

      resultMap = GetGlobalAA()._adb_assert_result_map

      if m._currentValidater <> invalid then
        if resultMap[GetGlobalAA()._adb_assert_current_tc_name] = invalid then
          resultMap[GetGlobalAA()._adb_assert_current_tc_name] = []
        end if

        currentResultArray = resultMap[GetGlobalAA()._adb_assert_current_tc_name]
        try
          m._validate()
        catch e
          _adb_logInfo("exception: " + e.message)

          currentResultArray.Push({
            _result: false,
            _lineNumber: LINE_NUM,
            _msg: e.message,
          })
          m._currentValidater = invalid
        end try
        if m._resultMap[GetGlobalAA()._adb_assert_current_tc_name] = invalid then
          m._resultMap[GetGlobalAA()._adb_assert_current_tc_name] = []
        end if
        m._resultMap[GetGlobalAA()._adb_assert_current_tc_name].Append(currentResultArray)
      end if

      if m._currentValidater = invalid and m._testCaseNameArray.Count() > 0 then
        name = m._testCaseNameArray.Shift()
        if name = invalid then
          return false
        end if

        try
          GetGlobalAA()._adb_assert_current_tc_name = name
          m._currentValidater = m._executeTestCase(name)
        catch e
          _adb_logInfo("exception: " + e.message)
          if resultMap[name] = invalid then
            resultMap[name] = []
          end if
          resultArray = resultMap[name]
          resultArray.Push({
            _result: false,
            _lineNumber: LINE_NUM,
            _msg: e.message,
          })
          m._currentValidater = invalid
        end try

        m._resultMap[name] = resultMap[name]
      end if

      if m._hasNoExecutor() then
        _adb_logInfo("TestSuite finished: " + FormatJson(m._resultMap))
      end if

      return true
    end function,

    _validate: sub()
      for each item in m._currentValidater.Items()
        key = item.key
        value = item.value
        if m._isFunction(value) then
          _adb_logInfo("start to validate: " + key)
          _adb_logInfo("with debugInfo: " + FormatJson(m._debugInfoMap[key]))
          m._currentValidater[key](m._debugInfoMap[key])
        end if
      end for
      m._currentValidater = invalid
    end sub

    ' return a validater object
    _executeTestCase: function(testCasename as string) as object
      if testCasename <> invalid then
        return m._testSuite[testCasename]()
      end if
      return invalid
    end function,

    _isArray: function(object as dynamic) as boolean
      return object <> invalid and Type(object) = "roArray"
    end function,

    _isFunction: function(object as dynamic) as boolean
      return object <> invalid and Type(object) = "roFunction"
    end function,

    _isObject: function(object as dynamic) as boolean
      return object <> invalid and Type(object) = "roAssociativeArray"
    end function,

    _isStartWith: function(string as string, prefix as string) as boolean
      return string <> invalid and prefix <> invalid and string.left(prefix.len()) = prefix
    end function,
  })
  return runner
end function

sub ADB_assertTrue(expr as dynamic, lineNumber as integer, msg = "assertTrue()" as string)
  if expr <> invalid and GetInterface(expr, "ifBoolean") <> invalid and expr then
    _reportResult(true, lineNumber, msg)
  else
    _reportResult(false, lineNumber, msg)
  end if
end sub

sub _reportResult(result as boolean, lineNumber as integer, msg as string)

  tcName = GetGlobalAA()._adb_assert_current_tc_name
  resultMap = GetGlobalAA()._adb_assert_result_map
  if resultMap[tcName] = invalid then
    resultMap[tcName] = []
  end if
  resultArray = resultMap[tcName]
  resultArray.Push({
    _result: result,
    _lineNumber: lineNumber,
    _msg: msg,
  })
end sub