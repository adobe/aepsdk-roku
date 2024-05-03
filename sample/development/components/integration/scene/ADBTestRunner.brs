' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

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
            _adb_resetResultMap()
            _adb_updateCurrentTestCaseName("unknown")
            m._loadTestSuite(testSuite)
        end sub
    }

    runner.Append({
        _debugInfoMap: {},
        _currentValidater: invalid,
        _testSuite: {},
        _testCaseNameArray: [],
        _testCaseNameArrayForResultMap: [],

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
                    m._testCaseNameArrayForResultMap.Push(key)
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

            if m._currentValidater <> invalid then
                m._validate()
            end if

            if m._currentValidater = invalid and m._testCaseNameArray.Count() > 0 then
                name = m._testCaseNameArray.Shift()
                if name = invalid then
                    return false
                end if

                _adb_updateCurrentTestCaseName(name)
                m._run_beforeEach(m._testSuite)
                m._currentValidater = m._executeTestCase(name)
                m._run_afterEach(m._testSuite)

            end if

            if m._hasNoExecutor() then
                resultMap = _adb_resetResultMap()
                _adb_logInfo("")
                _adb_logInfo("")
                _adb_logInfo("Integration test result in JSON: ")
                _adb_logInfo("")
                _adb_logInfo(FormatJson(resultMap))
                _adb_logInfo("")
                _adb_logInfo("")

                _adb_logInfo("======================================================")
                _adb_logInfo("            Integration Tests Report                  ")
                _adb_logInfo("======================================================")
                failedTestCaseNameArray = []
                for each testCaseName in m._testCaseNameArrayForResultMap
                    _adb_logInfo("")
                    _adb_logInfo("  Test Case:    <<" + testCaseName + ">>")
                    resultFlag = true
                    failedTestCaseNameMap = {}
                    for each item in resultMap[testCaseName]
                        _adb_logInfo("")
                        _adb_logInfo("- linenumber  : " + FormatJson(item._lineNumber))
                        _adb_logInfo("- msg         : " + item._msg)
                        _adb_logInfo("- result      : " + FormatJson(item._result))
                        _adb_logInfo("")
                        if item._result = false then
                            resultFlag = false
                            if not failedTestCaseNameMap.DoesExist(testCaseName) then
                                failedTestCaseNameArray.Push(testCaseName)
                                failedTestCaseNameMap[testCaseName] = true
                            end if

                        end if
                    end for
                    if resultFlag = true then
                        _adb_logInfo("  SUCCESS")
                    else
                        _adb_logInfo("FAILED")
                    end if
                    _adb_logInfo("")
                    _adb_logInfo("----------------------------------------------")
                    _adb_logInfo("")
                end for

                _adb_logInfo("======================================================")
                _adb_logInfo("")
                if failedTestCaseNameArray.count() > 0 then
                    _adb_logInfo("      Integration Tests: FAILED")
                    _adb_logInfo("  in: " + FormatJson(failedTestCaseNameArray))
                else
                    _adb_logInfo("      Integration Tests: SUCCESS")
                end if
                _adb_logInfo("")
                _adb_logInfo("======================================================")

            end if

            return true
        end function,

        _validate: sub()
            try
                for each item in m._currentValidater.Items()
                    key = item.key
                    value = item.value
                    if m._isFunction(value) then
                        _adb_logInfo("start to validate: " + key)
                        ' _adb_logInfo("with debugInfo: " + FormatJson(m._debugInfoMap[key]))
                        m._currentValidater[key](m._debugInfoMap[key])
                    end if
                end for
            catch e
                _adb_logInfo("exception: " + e.message)
                _adb_reportResult(false, LINE_NUM, e.message)
                print e
            end try
            m._currentValidater = invalid
        end sub

        ' return a validater object
        _executeTestCase: function(testCasename as string) as object
            try
                if testCasename <> invalid then
                    return m._testSuite[testCasename]()
                end if
            catch e
                _adb_logInfo("exception: " + e.message)
                _adb_reportResult(false, LINE_NUM, e.message)
                print e
            end try

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

        _run_beforeEach: sub(testSuiteObject as object)
            if m._isFunction(testSuiteObject.TS_beforeEach) then
                testSuiteObject.TS_beforeEach()
            end if
        end sub,

        _run_afterEach: sub(testSuiteObject as object)
            if m._isFunction(testSuiteObject.TS_afterEach) then
                testSuiteObject.TS_afterEach()
            end if
        end sub,
    })
    return runner
end function

sub ADB_assertTrue(expr as dynamic, lineNumber as integer, msg as string)
    if expr <> invalid and GetInterface(expr, "ifBoolean") <> invalid and expr then
        _adb_reportResult(true, lineNumber, msg)
    else
        _adb_reportResult(false, lineNumber, msg)
    end if
end sub

sub _adb_reportResult(result as boolean, lineNumber as integer, msg as string)

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

function _adb_resetResultMap() as object
    resultMap = GetGlobalAA()._adb_assert_result_map
    GetGlobalAA()._adb_assert_result_map = {}
    GetGlobalAA()._adb_assert_current_tc_name = "unknown"
    return resultMap
end function

sub _adb_updateCurrentTestCaseName(name as string)
    GetGlobalAA()._adb_assert_current_tc_name = name
end sub

function ADB_retrieveSDKInstance() as object
    if GetGlobalAA()._adb_public_api <> invalid then
        return GetGlobalAA()._adb_public_api
    end if
    return invalid
end function

sub ADB_resetSDK(instance as object)
    event = _adb_RequestEvent(instance._private.cons.PUBLIC_API.RESET_SDK, {})
    instance._private.dispatchEvent(event)
end sub

function ADB_removeRegistryValue(key) as void
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    _registry.Delete(key)
    _registry.Flush()
end function

function ADB_clearPersistedECID() as void
    ADB_removeRegistryValue("ecid")
end function

function ADB_getPersistedECID() as dynamic
    persistedECID = ADB_readRegistryValue("ecid")
    return persistedECID
end function

function ADB_readRegistryValue(key as string) as dynamic
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    if _registry.Exists(key) and _registry.Read(key).Len() > 0
        return _registry.Read(key)
    end if

    return invalid
end function

function ADB_persistECIDInRegistry(value as string) as dynamic
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    _registry.Write("ecid", value)
    return invalid
end function

sub ADB_testSDKVersion() as string
    return "1.2.0"
end sub
