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
            ' cache the original SDK data to be restored after the test suite execution
            m._cacheSDKData()
            m._run_beforeAll(m._testSuite)
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
                ' run the after all function since the test suite execution is done
                m._run_afterAll(m._testSuite)
                ' restore the original SDK data
                m._restoreSDKData()

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
            catch exception
                _adb_logInfo("exception: " + exception.message)
                _adb_reportResult(false, LINE_NUM, exception.message)
                print exception
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

        _run_beforeAll: sub(testSuiteObject as object)
            if m._isFunction(testSuiteObject.TS_beforeAll) then
                testSuiteObject.TS_beforeAll()
            end if
        end sub,

        _run_afterAll: sub(testSuiteObject as object)
            if m._isFunction(m._testSuite.TS_afterAll) then
                testSuiteObject.TS_afterAll()
            end if
        end sub

        _cacheSDKData: function() as void
            print("ADBTestRunner - cacheSDKData")
            m.originalSDKData = {
                "ecid" : ADB_getPersistedECID(),
                "statestore" : ADB_getPersistedStateStore(),
                "locationhint": ADB_getPersistedLocationHint(),
                "consent.collect": ADB_getPersistedConsent(),
            }

            print("ADBTestRunner::cacheSDKData - originalSDKData: " + FormatJson(m.originalSDKData))
        end function

        _restoreSDKData: function() as void
            print("ADBTestRunner - restoreSDKData: " + FormatJson(m.originalSDKData))
            if _adb_isEmptyOrInvalidMap(m.originalSDKData)
                return
            end if

            ADB_persistECIDInRegistry(m.originalSDKData.ecid)

            if not _adb_isEmptyOrInvalidMap(m.originalSDKData.statestore) then
                ADB_persistStateStoreInRegistry(FormatJson(m.originalSDKData.statestore))
            end if

            if not _adb_isEmptyOrInvalidString(m.originalSDKData.locationhint) then
                ADB_persistLocationHintInRegistry(FormatJson(m.originalSDKData.locationhint))
            end if

            ADB_persistConsentInRegistry(m.originalSDKData["consent.collect"])
        end function
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

' ************************ Registry Helpers ************************
function ADB_persistECIDInRegistry(value as dynamic) as void
    if _adb_isEmptyOrInvalidString(value)
        ADB_removeRegistryValue("ecid")
        return
    end if

    ADB_writeRegistryValue("ecid", value)
end function

function ADB_getPersistedECID() as dynamic
    persistedECID = ADB_readRegistryValue("ecid")
    return persistedECID
end function

function ADB_clearPersistedECID() as void
    ADB_removeRegistryValue("ecid")
end function

function ADB_persistStateStoreInRegistry(value as dynamic) as void
    ADB_writeRegistryValue("statestore", value)
end function

function ADB_getPersistedStateStore() as dynamic
    persistedStateStoreJson = ADB_readRegistryValue("statestore")
    if _adb_isEmptyOrInvalidString(persistedStateStoreJson)
        return invalid
    end if

    persistedStateStoreObject = ParseJson(persistedStateStoreJson)

    return persistedStateStoreObject
end function

function ADB_clearPersistedStateStore() as void
    ADB_removeRegistryValue("statestore")
end function

function ADB_persistLocationHintInRegistry(value as dynamic) as void
    ADB_writeRegistryValue("locationhint", value)
end function

function ADB_getPersistedLocationHint() as dynamic
    persistedLocationHintJson = ADB_readRegistryValue("locationhint")
    if _adb_isEmptyOrInvalidString(persistedLocationHintJson)
        return invalid
    end if

    locationHintObject = ParseJson(persistedLocationHintJson)
    return locationHintObject
end function

function ADB_clearPersistedLocationHint() as void
    ADB_removeRegistryValue("locationhint")
end function

function ADB_persistConsentInRegistry(value as dynamic) as void
    if _adb_isEmptyOrInvalidString(value)
        ADB_removeRegistryValue("consent.collect")
        return
    end if

    ADB_writeRegistryValue("consent.collect", value)
end function

function ADB_getPersistedConsent() as dynamic
    persistedConsentString = ADB_readRegistryValue("consent.collect")

    return persistedConsentString
end function

function ADB_clearPersistedConsent() as void
    ADB_removeRegistryValue("consent.collect")
end function

function ADB_writeRegistryValue(key as string, value as dynamic) as void
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    _registry.Write(key, value)
    _registry.Flush()
end function

function ADB_readRegistryValue(key as string) as dynamic
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    if _registry.Exists(key) and _registry.Read(key).Len() > 0
        return _registry.Read(key)
    end if

    return invalid
end function

function ADB_removeRegistryValue(key) as void
    _registry = CreateObject("roRegistrySection", "adb_aep_roku_sdk")
    _registry.Delete(key)
    _registry.Flush()
end function

' ************************ Test Helpers ************************
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

sub ADB_testSDKVersion() as string
    return "1.2.0"
end sub

function ADB_generateErrorMessage(message as string, expected as dynamic, actual as dynamic) as string
    if (type(expected) <> "roString" and type(expected) <> "String")
        expected = FormatJson(expected)
    end if

    if (type(actual) <> "roString" and type(actual) <> "String")
        actual = FormatJson(actual)
    end if

    return message + " Expected: (" + chr(10) + expected + chr(10) + ") Actual: ("+ chr(10) + actual + chr(10) +")"
end function

function _adb_integrationTestUtil_reset()
    ADB_clearPersistedECID()
    ADB_clearPersistedConsent()
    ADB_clearPersistedLocationHint()
    ADB_clearPersistedStateStore()
end function

function _adb_integrationTestUtil_getHandle(handleType as string, responsePayload as object) as object
    handle = {}

    handles = responsePayload.handle
    if _adb_isEmptyOrInvalidArray(handles) then
      return handle
    end if

    for each item in handles
        if _adb_isEmptyOrInvalidMap(item) then
            continue for
        end if

        if not _adb_stringEqualsIgnoreCase(item.type, handleType) then
            continue for
        end if

        handle = item
        exit for
    end for

    return handle
end function
