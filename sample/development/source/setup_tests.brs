' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


function _adb_run_tests() as void

    Runner = TestRunner()

    Runner.SetTestFilePrefix("adb_test_")

    Runner.SetFunctions(_adb_test_functions())

    Runner.Logger.SetVerbosity(3)
    Runner.Logger.SetEcho(false)
    Runner.Logger.SetJUnit(false)
    Runner.SetFailFast(true)

    Runner.Run()
end function


function _adb_test_functions() as dynamic
    return [
        ' adb_test_AdobeEdge.brs
        AdobeEdgeTestSuite_SetUp
        AdobeEdgeTestSuite_TearDown
        TestCase_AdobeEdge_AdobeSDKConstants
        TestCase_AdobeEdge_adb_sdkVersion
        TestCase_AdobeEdge_adb_serviceProvider
        TestCase_AdobeEdge_adb_isEmptyOrInvalidString
        TestCase_AdobeEdge_adb_optMapFromMap
        TestCase_AdobeEdge_adb_optStringFromMap
        TestCase_AdobeEdge_adb_optIntFromMap
        ' adb_test_AdobeEdge_AdobeSDKInit.brs
        AdobeEdgeTestSuite_AdobeSDKInit_SetUp
        AdobeEdgeTestSuite_AdobeSDKInit_TearDown
        TestCase_AdobeEdge_AdobeSDKInit_singleton
        TestCase_AdobeEdge_AdobeSDKInit_initialize_task_node
        ' adb_test_AdobeEdge_loggingService.brs
        AdobeEdgeTestSuite_loggingService_BeforeEach
        AdobeEdgeTestSuite_loggingService_TearDown
        TestCase_AdobeEdge_loggingService_logLevel
        TestCase_AdobeEdge_loggingService_logLevel_default
        TestCase_AdobeEdge_loggingService_utility_functions
        ' AdobeEdgeTestSuite_public_APIs.brs
        AdobeEdgeTestSuite_public_APIs_SetUp
        AdobeEdgeTestSuite_public_APIs_BeforeEach
        AdobeEdgeTestSuite_public_APIs_TearDown
        TestCase_AdobeEdge_public_APIs_getVersion
        TestCase_AdobeEdge_public_APIs_setLogLevel
        TestCase_AdobeEdge_public_APIs_setLogLevel_invalid
        TestCase_AdobeEdge_public_APIs_shutdown
        TestCase_AdobeEdge_public_APIs_updateConfiguration
        TestCase_AdobeEdge_public_APIs_updateConfiguration_invalid
        TestCase_AdobeEdge_public_APIs_sendEvent
        TestCase_AdobeEdge_public_APIs_sendEvent_invalid
        TestCase_AdobeEdge_public_APIs_sendEventWithCallback
        TestCase_AdobeEdge_public_APIs_setExperienceCloudId
        TestCase_AdobeEdge_public_APIs_buildEvent
        ' adb_test_AdobeEdge_localDataStoreService.brs
        AdobeEdgeTestSuite_localDataStoreService_BeforeEach
        AdobeEdgeTestSuite_localDataStoreService_TearDown
        TestCase_AdobeEdge_localDataStoreService_write
        ' adb_test_AdobeEdge_EventProcessor.brs
        AdobeEdgeTestSuite_EventProcessor_BeforeEach
        AdobeEdgeTestSuite_EventProcessor_TearDown
        TestCase_AdobeEdge_EventProcessor_init
        TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel
        TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel_invalid
        TestCase_AdobeEdge_EventProcessor_handleEvent_resetIdentities
        TestCase_AdobeEdge_EventProcessor_handleEvent_setConfiguration
        TestCase_AdobeEdge_EventProcessor_handleEvent_setECID
        TestCase_AdobeEdge_EventProcessor_hasXDMData
        TestCase_AdobeEdge_EventProcessor_handleEvent_sendEvent
        TestCase_AdobeEdge_EventProcessor_sendResponseEvent
        TestCase_AdobeEdge_EventProcessor_processQueuedRequests
        TestCase_AdobeEdge_EventProcessor_processQueuedRequests_multiple_requests
        TestCase_AdobeEdge_EventProcessor_processQueuedRequests_bad_request
        TestCase_AdobeEdge_EventProcessor_processQueuedRequests_empty_queue
        ' adb_test_AdobeEdge_Edge_utils.brs
        AdobeEdgeTestSuite_Edge_utils_SetUp
        AdobeEdgeTestSuite_Edge_utils_TearDown
        TestCase_AdobeEdge_adb_ImplementationDetails
        TestCase_AdobeEdge_adb_buildEdgeRequestURL_validDomain
        ' adb_test_AdobeEdge_EdgeRequestWorker.brs
        AdobeEdgeTestSuite_EdgeRequestWorker_SetUp
        AdobeEdgeTestSuite_EdgeRequestWorker_BeforeEach
        AdobeEdgeTestSuite_EdgeRequestWorker_TearDown
        TestCase_AdobeEdge_adb_EdgeRequestWorker_init
        TestCase_AdobeEdge_adb_EdgeRequestWorker_init_invalid
        TestCase_AdobeEdge_adb_EdgeRequestWorker_isReadyToProcess
        TestCase_AdobeEdge_adb_EdgeRequestWorker_queue
        TestCase_AdobeEdge_adb_EdgeRequestWorker_queue_bad_input
        TestCase_AdobeEdge_adb_EdgeRequestWorker_queue_limit
        TestCase_AdobeEdge_adb_EdgeRequestWorker_clear
        TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequest
        TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequest_invalid_response
        TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequests
        TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequests_empty_queue
        TestCase_AdobeEdge_adb_EdgeRequestWorker_processRequests_recoverable_error
        ' adb_test_AdobeEdge_AdobeStateManager.brs
        TS_StateManager_SetUp
        TS_StateaManager_BeforeEach
        TS_StateManager_TearDown
        T_StateManager_init
        T_StateManager_updateConfiguration_configId
        T_StateManager_updateConfiguration_edgeDomain
        T_StateManager_updateConfiguration_edgeDomain_invalidValues
        T_StateManager_updateConfiguration_separateUpdates
        T_StateManager_updateConfiguration_invalidConfigurationKeys
        T_StateManager_updateConfiguration_invalidConfigurationValues
        T_StateManager_getECID_noSetECID_invalidConfiguration_returnsInvalid
        T_StateManager_getECID_validConfiguration_fetchesECID
        T_StateManager_updateECID_validString_updatesECID
        T_StateManager_updateECID_invalid_deletesECID
        T_StateManager_resetIdentities_deletesECIDAndOtherIdentities
    ]
end function