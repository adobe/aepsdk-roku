' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


' @BeforeEach
sub AdobeEdgeTestSuite_EventProcessor_BeforeEach()
    print "AdobeEdgeTestSuite_EventProcessor_BeforeEach"
end sub

' @AfterAll
sub AdobeEdgeTestSuite_EventProcessor_TearDown()
    print "AdobeEdgeTestSuite_EventProcessor_TearDown"
end sub

' target: _setLogLevel()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    UTF_assertEqual(loggingService._logLevel, 1)

    eventProcesser = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcesser.handleEvent({
        apiName: "setLogLevel",
        data: {
            level: 3
        },
        timestamp: "1234",
        uuid: "4567"
    })
    UTF_assertEqual(loggingService._logLevel, 3)
end sub

' target: _setLogLevel()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel_invalid()
    serviceProvider = _adb_serviceProvider()
    loggingService = serviceProvider.loggingService
    loggingService.setLogLevel(1)
    UTF_assertEqual(loggingService._logLevel, 1)

    eventProcesser = _adb_task_node_EventProcessor(_adb_internal_constants(), {})
    eventProcesser.handleEvent({
        apiName: "setLogLevel",
        data: {
            invalid_key: 3
        },
        timestamp: "1234",
        uuid: "4567"
    })
    UTF_assertEqual(loggingService._logLevel, 1)
end sub

' target: _setConfiguration()
' @Test
sub TestCase_AdobeEdge_EventProcessor_handleEvent_setConfiguration()

end sub

