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
        TC_AdobeAEPSDKConstants
        'test_map.brs
        TC_adb_optMapFromMap
        TC_adb_optStringFromMap
        TC_adb_optIntFromMap
        'test_string.brs
        TC_adb_isEmptyOrInvalidString
        TC_adb_isStringEndsWith
        TC_adb_isStringInArray
        'test_datetime.brs
        TC_adb_timestampInMillis
        TC_adb_ISO8601_timestamp
        TC_adb_TimestampObject
        ' test_log.brs
        TS_logUtils_SetUp
        TS_logUtils_BeforeEach
        TS_logUtils_TearDown
        TC_adb_logError
        TC_adb_logWarning
        TC_adb_logInfo
        TC_adb_logDebug
        TC_adb_logVerbose
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
        'test_networkResponse.brs
        TC_adb_NetworkResponse
        TC_adb_NetworkResponse_isSuccessful
        TC_adb_NetworkResponse_isRecoverable
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
        TC_adb_ConfigurationModule_validMediaConfig
        TC_adb_ConfigurationModule_overwrittingMediaConfig
        TC_adb_ConfigurationModule_emptyMediaConfig
        TC_adb_ConfigurationModule_invalidMediaConfig
        ' test_identityModule.brs
        TS_identityModule_BeforeEach
        TC_adb_IdentityModule_bad_init
        TC_adb_IdentityModule_getECID_noSetECID_invalidConfiguration_returnsInvalid
        TC_adb_IdentityModule_updateECID_validString_updatesECID
        TC_adb_IdentityModule_updateECID_invalid_deletesECID
        TC_adb_IdentityModule_resetIdentities_deletesECIDAndOtherIdentities
        'test_adobeObject.brs
        TC_adb_AdobeObject
        'test_event.brs
        TC_adb_RequestEvent
        TC_adb_RequestEvent_empty_data
        TC_adb_ResponseEvent
        TC_adb_ResponseEvent_empty_data
    ]
    edge = [
        'test_buildEdgeRequestURL.brs
        TC_adb_buildEdgeRequestURL_validDomain
        TC_adb_buildEdgeRequestURL_validPathOverwriting
        'test_implementationDetails.brs
        TC_adb_ImplementationDetails
        ' test_edgeRequestWorker.brs
        TC_adb_EdgeRequestWorker_init
        TC_adb_EdgeRequestWorker_hasQueuedEvent
        TC_adb_EdgeRequestWorker_queue
        TC_adb_EdgeRequestWorker_queue_bad_input
        TC_adb_EdgeRequestWorker_queue_limit
        TC_adb_EdgeRequestWorker_clear
        TC_adb_EdgeRequestWorker_processRequest_valid_response
        TC_adb_EdgeRequestWorker_processRequest_invalid_response
        TC_adb_EdgeRequestWorker_processRequests
        TC_adb_EdgeRequestWorker_processRequests_empty_queue
        TC_adb_EdgeRequestWorker_processRequests_recoverableError_retriesAfterWaitTimeout
        TC_adb_EdgeRequestWorker_queue_newRequest_after_RecoverableError_retriesImmediately
        'test_edgeModule.brs
        TC_adb_EdgeModule_init
        TC_adb_EdgeModule_processEvent
        TC_adb_EdgeModule_processQueuedRequests
    ]
    media = [
        'test_mediaUtils.brs
        TC_adb_extractPlayheadFromMediaXDMData
        TC_adb_extractPlayheadFromMediaXDMData_invalid
        TC_adb_extractPlayheadFromMediaXDMData_invalidType
        TC_adb_isValidMediaXDMData
        TC_adb_isValidMediaXDMData_invalid
        ' test_mediaModule.brs
        TC_adb_MediaModule_init
        TC_adb_MediaModule_processEvent_sessionStart_validConfig_createsSessionAndQueuesEvent
        TC_adb_MediaModule_processEvent_sessionStart_InvalidConfig_ignoresEvent
        TC_adb_MediaModule_processEvent_MediaEventOtherThanSessionStart_validConfig_queuesEvent
        TC_adb_MediaModule_processEvent_SessionComplete_validConfig_queuesEventAndEndsSession
        TC_adb_MediaModule_processEvent_invalidMediaEvent_ignoresEvent
        TC_hasValidConfig
        ' test_mediaSessionManager.brs
        TC_adb_MediaSessionManager_init
        TC_adb_MediaSessionManager_createSession
        TC_adb_MediaSessionManager_createSession_endsOldSession
        TC_adb_MediaSessionManager_queue_validActiveSession_queuesWithSession
        TC_adb_MediaSessionManager_queue_invalidActiveSession_ignoresMediaHit
        TC_adb_MediaSessionManager_endSession_validActiveSession_closesSession
        TC_adb_MediaSessionManager_endSession_invalidActiveSession_getsIgnored
        ' test_mediaSession.brs
        TC_adb_MediaSession_init
        TC_adb_MediaSession_getPingInterval_validInterval
        TC_adb_MediaSession_getPingInterval_invalidInterval
        TC_adb_MediaSession_extractSessionStartData_sessionStartHit_cachesHit
        TC_adb_MediaSession_extractSessionStartData_notSessionStartHit_doesNotCacheHit
        TC_adb_MediaSession_attachMediaConfig
        TC_adb_MediaSession_updateChannelFromSessionConfig
        TC_adb_MediaSession_updatePlaybackState_playEvent
        TC_adb_MediaSession_updatePlaybackState_pauseStartEvent
        TC_adb_MediaSession_updatePlaybackState_pauseStart_bufferStartEvent
        TC_adb_MediaSession_updatePlaybackState_nonPlaybackEvents_ignored
        TC_adb_MediaSession_updateAdState_adStartEvent_setsIsInAd
        TC_adb_MediaSession_updateAdState_adCompleteEvent_adSkipEvent_resetsIsInAd
        TC_adb_MediaSession_updateAdState_nonAdEvent_ignored
        TC_adb_MediaSession_createSessionResumeHit
        TC_adb_MediaSession_closeIfIdle_idleDurationOverIdleTimeout_endSession
        TC_adb_MediaSession_closeIfIdle_idleDurationUnderIdleTimeout_ignored
        TC_adb_MediaSession_closeIfIdle_alreadyIdleTimedout_ignored
        TC_adb_MediaSession_closeIfIdle_inPlayingState_ignored
        TC_adb_MediaSession_restartIdleSession_playAfterIdleTimeout_resumes
        TC_adb_MediaSession_restartIdleSession_notPlayEventAfterIdleTimeout_ignored
        TC_adb_MediaSession_restartIdleSession_playifNotIdleTimeout_ignored
        TC_adb_MediaSession_restartIdleSession_ifActiveSession_ignored
    ]
    initSDK = [
        'test_AdobeAEPSDKInit.brs
        TS_AdobeAEPSDKInit_SetUp
        TS_AdobeAEPSDKInit_TearDown
        TC_AdobeAEPSDKInit_singleton
        TC_AdobeAEPSDKInit_initialize_task_node
    ]
    api = [
        'test_public_APIs.brs
        TS_public_APIs_BeforeEach
        TS_public_APIs_TearDown
        TC_APIs_getVersion
        TC_APIs_setLogLevel
        TC_APIs_setLogLevel_invalid
        TC_APIs_shutdown
        TC_APIs_updateConfiguration
        TC_APIs_updateConfiguration_invalid
        TC_APIs_sendEvent
        TC_APIs_sendEvent_invalid
        TC_APIs_sendEventWithCallback
        TC_APIs_sendEventWithCallback_timeout
        TC_APIs_setExperienceCloudId
        TC_APIs_createMediaSession
        TC_APIs_createMediaSession_withConfiguration
        TC_APIs_createMediaSession_invalidXDMData
        TC_APIs_createMediaSession_endPrevisouSession
        TC_APIs_sendMediaEvent
        TC_APIs_sendMediaEvent_invalidXDMData
        TC_APIs_sendMediaEvent_invalidSession
        TC_APIs_sendMediaEvent_sessionEnd
        TC_adb_ClientMediaSession
    ]
    task = [
        'test_eventProcessor.brs
        TC_adb_EventProcessor_handleEvent_setLogLevel
        TC_adb_eventProcessor_handleEvent_setLogLevel_invalid
        TC_adb_eventProcessor_handleEvent_resetIdentities
        TC_adb_eventProcessor_handleEvent_setConfiguration
        TC_adb_eventProcessor_handleEvent_setECID
        TC_adb_eventProcessor_handleEvent_handleMediaEvents
        TC_adb_eventProcessor_handleEvent_handleMediaEvents_invalid
        TC_adb_eventProcessor_handleCreateMediaSession
        TC_adb_eventProcessor_handleCreateMediaSession_invalid
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
    functionList.Append(media)
    functionList.Append(initSDK)
    functionList.Append(api)
    functionList.Append(task)
    return functionList
end function
