function ADBTestRunner() as object
    runner = {
        _testSuite: {},
        execute: sub ()
            m._runTestSuites()
        end sub,
        hasNext: function() as boolean
            return m._testSuite.Count() > 0
        end function,
        init: sub (testSuite as object)
            m._testSuite = testSuite
        end sub,
    }
    runner.Append({
        _testSuiteArray: [],
        _currentTestSuite: invalid,
        _currentTestCaseArray: [],

        _resetAssertResults: sub ()
            GetGlobalAA()._adb_assert_parent_function_name = ""
            GetGlobalAA()._adb_assert_result_array = []
            GetGlobalAA()._adb_debug_node = invalid
            GetGlobalAA()._adb_debug_node_info_port = invalid
        end sub,

        _printAssertResults: sub ()
            resultArray = GetGlobalAA()._adb_assert_result_array
            for each result in resultArray
                print GetGlobalAA()._adb_assert_parent_function_name + ": " + FormatJson(result)
            end for
        end sub,

        _runTestSuites: sub()
            for each testSuite in m._tsArray
                m._runTestSuite(testSuite)
            end for
        end sub,

        _runTestSuite: sub(testSuiteFunc as dynamic)
            if m._isFunction(testSuiteFunc) then
                testSuiteObject = testSuiteFunc()
                m._run_setup(testSuiteObject)
                for each item in testSuiteObject.Items()
                    key = item.key
                    value = item.value
                    if m._isFunction(value) and m._isStartWith(LCase(key), "tc_") then
                        m._run_beforeEach(key, testSuiteObject)
                        try
                            testSuiteObject[key]()
                        catch e
                            ADB_reportResult(false, "Catch an exception:" + e.message + ", line number: " + FormatJson(LINE_NUM))
                        end try
                    end if
                end for
                m._run_teardown(testSuiteObject)
            end if
        end sub,

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

        _run_beforeEach: sub(tcName as string, testSuiteObject as object)
            GetGlobalAA()._adb_assert_parent_function_name = tcName
            if m._isFunction(testSuiteObject.TS_beforeEach) then
                testSuiteObject.TS_beforeEach()
            end if
        end sub,
        _run_afterEach: sub(testSuiteObject as object)
            GetGlobalAA()._adb_assert_parent_function_name = ""
            if m._isFunction(testSuiteObject.TS_afterEach) then
                testSuiteObject.TS_afterEach()
            end if
        end sub,
        _run_setup: function(testSuiteObject as object) as dynamic
            m._resetAssertResults()
            if m._isFunction(testSuiteObject.TS_setup) then
                testSuiteObject.TS_setup()
            end if
        end function,

        _run_teardown: function(testSuiteObject as object) as dynamic
            if m._isFunction(testSuiteObject.TS_teardown) then
                testSuiteObject.TS_teardown()
            end if
            m._printAssertResults()
        end function
    })
    return runner
end function

sub ADB_assertTrue(expr as dynamic, msg = "assertTrue()" as string)
    if expr <> invalid and GetInterface(expr, "ifBoolean") <> invalid and expr then
        ADB_reportResult(true, msg + " line number: " + FormatJson(LINE_NUM))
    else
        ADB_reportResult(false, msg + " line number: " + FormatJson(LINE_NUM))
    end if
end sub

sub ADB_reportResult(result as boolean, msg as string)
    resultArray = GetGlobalAA()._adb_assert_result_array
    resultArray.Push({
        _result: result,
        _msg: msg,
    })
end sub

sub ADB_enableNodeDebugging(node as object)
    if type(node) = "roSGNode" and node.hasField("debugInfo")then
        GetGlobalAA()._adb_debug_node = node
        ' if not node.addField("debug_info", "assocarray", true) then
        '     throw "Failed to add debug_info field to node"
        ' end if
        port = createObject("roMessagePort")
        GetGlobalAA()._adb_debug_node_info_port = port
        node.observeField("debugInfo", "ADB_retrieveDebugInof")
    end if
end sub

function ADB_retrieveDebugInof() as object
    node = _adb_retrieveTaskNode()
    print node
    ' port = GetGlobalAA()._adb_debug_node_info_port
    ' msg = wait(500, port)
    ' counter = 0
    ' while counter < 30
    '     if msg <> invalid
    '         print msg
    '         node = GetGlobalAA()._adb_debug_node
    '         if type(node) = "roSGNode" then
    '             print "zyt:"
    '             print _adb_timestampInMillis()
    '             return node.getField("debugInfo")
    '         end if
    '     end if
    '     counter++
    ' end while
    ' print "zyt:"
    ' print _adb_timestampInMillis()
    ' return invalid
    return {}
end function
