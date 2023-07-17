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

    Runner.SetTestFilePrefix("test_")

    Runner.SetFunctions(_adb_test_functions())

    Runner.Logger.SetVerbosity(3)
    Runner.Logger.SetEcho(false)
    Runner.Logger.SetJUnit(false)
    Runner.SetFailFast(true)

    Runner.Run()
end function


function _adb_test_functions() as dynamic
    common = [
        'test_datetime.brs
        TC_adb_sdkVersion
        'test_constants.brs
        TC_AdobeSDKConstants
        'test_map.brs
        TC_adb_optMapFromMap
        TC_adb_optStringFromMap
        TC_adb_optIntFromMap
        'test_string.brs
        TC_adb_isEmptyOrInvalidString
    ]
    services = [
        'test_serviceProvider.brs
        TC_adb_serviceProvider

        ' test_localDataStoreService.brs
        TC_localDataStoreService_write
        'test_loggingService.brs
        TC_loggingService_logLevel
        TC_loggingService_logLevel_default
        TC_loggingService_utility_functions
    ]
    core = [
        'test_configurationModule.brs
        TC_adb_ConfigurationModule_init
        TC_adb_ConfigurationModule_configId
        TC_adb_ConfigurationModule_edgeDomain
        TC_adb_ConfigurationModule_edgeDomain_invalidValues
        TC_adb_ConfigurationModule_separateUpdates
        TC_adb_ConfigurationModule_invalidConfigurationKeys
        TC_adb_ConfigurationModule_invalidConfigurationValues
        ' test_identityModule.brs
        TS_identityModule_BeforeEach
        TC_adb_IdentityModule_bad_init
        TC_adb_IdentityModule_getECID_noSetECID_invalidConfiguration_returnsInvalid
        TC_adb_IdentityModule_updateECID_validString_updatesECID
        TC_adb_IdentityModule_updateECID_invalid_deletesECID
        TC_adb_IdentityModule_resetIdentities_deletesECIDAndOtherIdentities
    ]
    edge = [
        'test_buildEdgeRequestURL.brs
        TC_adb_buildEdgeRequestURL_validDomain
        'test_implementationDetails.brs
        TC_adb_ImplementationDetails
        ' test_edgeRequestWorker.brs
        TC_adb_EdgeRequestWorker_init
        TC_adb_EdgeRequestWorker_hasQueuedEvent
        TestCase_AdobeEdge_adb_EdgeRequestWorker_queue
        TC_adb_EdgeRequestWorker_queue_bad_input
        TC_adb_EdgeRequestWorker_queue_limit
        TC_adb_EdgeRequestWorker_clear
        TC_adb_EdgeRequestWorker_processRequest
        TC_adb_EdgeRequestWorker_processRequest_invalid_response
        TC_adb_EdgeRequestWorker_processRequests
        TC_adb_EdgeRequestWorker_processRequests_empty_queue
        TC_adb_EdgeRequestWorker_processRequests_recoverable_error
    ]
    initSDK = [
        'test_AdobeSDKInit.brs
        AdobeSDKInit_SetUp
        AdobeSDKInit_TearDown
        TC_AdobeSDKInit_singleton
        TC_AdobeSDKInit_initialize_task_node
    ]
    api = [
        'test_public_APIs.brs
        public_APIs_BeforeEach
        public_APIs_TearDown
        TC_APIs_getVersion
        TC_APIs_setLogLevel
        TC_APIs_setLogLevel_invalid
        TC_APIs_shutdown
        TC_APIs_updateConfiguration
        TC_APIs_updateConfiguration_invalid
        TC_APIs_sendEvent
        TC_APIs_sendEvent_invalid
        TC_APIs_sendEventWithCallback
        TC_APIs_setExperienceCloudId
    ]
    task = [
        'test_eventProcessor.brs
        TC_adb_EventProcessor_handleEvent_setLogLevel
        TC_adb_eventProcessor_handleEvent_setLogLevel_invalid
        TC_adb_eventProcessor_handleEvent_resetIdentities
        TC_adb_eventProcessor_handleEvent_setConfiguration
        TC_adb_eventProcessor_handleEvent_setECID
        TC_adb_eventProcessor_hasXDMData
        TC_adb_eventProcessor_handleEvent_sendEvent
        TC_adb_eventProcessor_sendResponseEvent
        TC_adb_eventProcessor_processQueuedRequests
        TC_adb_eventProcessor_processQueuedRequests_multiple
        TC_adb_eventProcessor_processQueuedRequests_bad_request
        TC_adb_eventProcessor_init
    ]
    functionList = []
    functionList.Append(common)
    functionList.Append(services)
    functionList.Append(core)
    functionList.Append(edge)
    functionList.Append(initSDK)
    functionList.Append(api)
    functionList.Append(task)
    return functionList
end function