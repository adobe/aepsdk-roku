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
        'test_timer.brs
        TC_adb_timer_init
        TC_adb_timer_initWithoutStartTime
        'test_constants.brs
        TC_AdobeAEPSDKConstants
        'test_map.brs
        TC_adb_optMapFromMap
        TC_adb_optStringFromMap
        TC_adb_optIntFromMap
        'test_string.brs
        TC_adb_isInvalidString
        TC_adb_isEmptyOrInvalidString
        TC_adb_isStringEndsWith
        TC_adb_isStringInArray
        TC_adb_stringEqualsIgnoreCase
        TC_adb_stringEquals
        'test_int.brs
        TC_adb_isInvalidInt_invalidInt
        TC_adb_isInvalidInt_validInt
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
        TC_adb_ConfigurationModule_validConsentConfig
        TC_adb_ConfigurationModule_invalidConsentConfig

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
        TC_adb_IdentityResponseEvent
        TC_adb_IdentityResponseEvent_empty_data
        TC_adb_EdgeResponseEvent
        TC_adb_EdgeResponseEvent_empty_data
    ]
    edge = [
        'test_buildEdgeRequestURL.brs
        TC_adb_buildEdgeRequestURL_validDomain
        TC_adb_buildEdgeRequestURL_validPathOverwriting
        TC_adb_buildEdgeRequestURL_validLocationHint
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
        TC_adb_EdgeRequestWorker_processRequest_customMeta_valid_response
        TC_adb_EdgeRequestWorker_processRequest_customDomain_valid_response
        TC_adb_EdgeRequestWorker_processRequest_datastreamIdOverride_valid_response
        TC_adb_EdgeRequestWorker_processRequest_datastreamConfigOverride_valid_response
        TC_adb_EdgeRequestWorker_processRequest_datastreamIdAndConfigOverride_valid_response
        TC_adb_EdgeRequestWorker_processRequest_invalidEventConfig_valid_response
        TC_adb_EdgeRequestWorker_processRequest_invalidDatastreamIdOverrideValue_valid_response
        TC_adb_EdgeRequestWorker_processRequest_invalidConfigOverrideValue_valid_response
        TC_adb_EdgeRequestWorker_processRequest_validLocationHint_appendsLocationHintToRequestURL
        TC_adb_EdgeRequestWorker_processRequest_validStateStore_appendsStateStoreToMeta
        TC_adb_EdgeRequestWorker_processRequest_overridesWithCustomMeta_valid_response
        TC_adb_EdgeRequestWorker_processRequest_invalid_response
        TC_adb_EdgeRequestWorker_processRequests
        TC_adb_EdgeRequestWorker_processRequests_empty_queue
        TC_adb_EdgeRequestWorker_processRequests_recoverableError_retriesAfterWaitTimeout
        TC_adb_EdgeRequestWorker_queue_newRequest_after_RecoverableError_retriesImmediately
        'test_edgeModule.brs
        TC_adb_EdgeModule_init
        TC_adb_EdgeModule_processEvent
        TC_adb_EdgeModule_processQueuedRequests
        'test_EdgeResponseManager.brs
        TC_adb_EdgeResponseManager_Init
        TC_adb_EdgeResponseManager_processResponse_validLocationHintResponse
        TC_adb_EdgeResponseManager_processResponse_validStateStoreResponse
        TC_adb_EdgeResponseManager_processResponse_responseWithTypeNotHandled
        'test_stateStoreManager.brs
        TC_adb_StateStoreManager_Init
        TC_adb_StateStoreManager_processStateStoreHandle_validHandle
        TC_adb_StateStoreManager_processStateStoreHandle_invalidHandle
        TC_adb_StateStoreManager_deleteStateStore
        TC_adb_StateStoreEntry_init
        TC_adb_StateStoreEntry_invalidPayload
        TC_adb_StateStoreEntry_invalidKey
        TC_adb_StateStoreEntry_isExpired_notExpired
        TC_adb_StateStoreEntry_isExpired_expired
        TC_adb_StateStoreEntry_noMaxAge

        'test_locationHintManager.brs
        TC_adb_LocationHintManager_init
        TC_adb_LocationHintManager_setLocationHint_validHintNoTTL
        TC_adb_LocationHintManager_setLocationHint_validHintWithTTL
        TC_adb_LocationHintManager_setLocationHint_invalid
        TC_adb_LocationHintManager_islocationHintExpired
        TC_adb_LocationHintManager_setLocationHint_validHintWithTTL
        TC_adb_LocationHintManager_getLocationHint_withoutSet
        TC_adb_LocationHintManager_getLocationHint_expiredTTL_callsDelete
        TC_adb_LocationHintManager_processLocationHintHandle_invalidHandle
        TC_adb_LocationHintManager_processLocationHintHandle_validHandle
        TC_adb_LocationHintManager_delete
    ]
    consent = [
        'test_consentModule.brs
        TC_adb_ConsentModule_init
        TC_adb_ConsentModule_processEvent_withCollectConsent_queuesEdgeRequest
        TC_adb_ConsentModule_processEvent_withoutCollectConsent_queuesEdgeRequest
        TC_adb_ConsentModule_processEvent_collectConsentPending_doesNotQueueEdgeRequest
        TC_adb_ConsentModule_processResponseEvent_validConsentHandle
        TC_adb_ConsentModule_processResponseEvent_missingConsentPreferencesHandle
        TC_adb_ConsentModule_processResponseEvent_invalidHandle
        'test_consentState.brs
        TS_consentState_SetUp
        TS_consentState_BeforeEach
        TS_consentState_TearDown
        TC_adb_ConsentState_init
        TC_adb_ConsentState_extractConsentFromConfiguration_valid
        TC_adb_ConsentState_extractConsentFromConfiguration_invalid
        TC_adb_ConsentState_isValidConsentValue_valid
        TC_adb_ConsentState_isValidConsentValue_invalid
        TC_adb_ConsentState_setCollectConsent_validValue_cachesAndPersists
        TC_adb_ConsentState_setCollectConsent_invalidValue_doesNotCacheOrPersist
        TC_adb_ConsentState_setCollectConsent_validValue_invalidValue_retainsOldValidValue
        TC_adb_ConsentState_getCollectConsent_cached_returnsCachedValue
        TC_adb_ConsentState_getCollectConsent_notCached_returnsPersistedValue
        TC_adb_ConsentState_getCollectConsent_notPersisted_fetchesFromConfig
        TC_adb_ConsentState_getCollectConsent_notPersisted_notInConfig_returnsInvalid
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
        TC_adb_MediaModule_processEvent_invalidMediaEvent_inactiveSession
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
        TC_adb_MediaSession_init_withoutSessionConfig
        TC_adb_MediaSession_init_withFullSessionConfig
        TC_adb_MediaSession_process_notActiveSession
        TC_adb_MediaSession_process_activeSession_sessionStartHit_queued
        TC_adb_MediaSession_process_activeSession_playbackHits_queued
        TC_adb_MediaSession_process_activeSession_adHits_queued
        TC_adb_MediaSession_process_activeSession_idleTimeout_queued
        TC_adb_MediaSession_process_activeSession_longRunningSession_queued
        TC_adb_MediaSession_tryDispatchMediaEvents_sessionStart_validConfigAndSessionConfig
        TC_adb_MediaSession_tryDispatchMediaEvents_sessionStart_validConfigNoSessionConfig
        TC_adb_MediaSession_tryDispatchMediaEvents_sessionStart_NoValidConfigNoSessionConfig
        TC_adb_MediaSession_tryDispatchMediaEvents_notSessionStart_validBackendId
        TC_adb_MediaSession_tryDispatchMediaEvents_notSessionStart_invalidBackendId
        TC_adb_MediaSession_close_noAbort_dispatchesHitQueue
        TC_adb_MediaSession_close_abort_deletesHitQueue
        TC_adb_MediaSession_getPingInterval_validInterval
        TC_adb_MediaSession_getPingInterval_invalidInterval
        TC_adb_MediaSession_extractSessionStartData_sessionStartHit_cachesHit
        TC_adb_MediaSession_extractSessionStartData_notSessionStartHit_doesNotCacheHit
        TC_adb_MediaSession_attachMediaConfig
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
        TC_adb_MediaSession_restartIfLongRunningSession_longRunningSession_restartsSession
        TC_adb_MediaSession_restartIfLongRunningSession_notLongRunningSession_ignored
        TC_adb_MediaSession_restartIfLongRunningSession_triggeredBySessionEndOrComplete_ignored
        TC_adb_MediaSession_resetForRestart
        TC_adb_MediaSession_shouldQueue_pingEvent_overPingInterval_returnsTrue
        TC_adb_MediaSession_shouldQueue_pingEvent_underPingInterval_returnsFalse
        TC_adb_MediaSession_shouldQueue_notPingEvent_returnsTrue
        TC_adb_MediaSession_queue_sessionActive_queues
        TC_adb_MediaSession_queue_sessionInActive_doesNotqueue
        TC_adb_MediaSession_processEdgeRequestQueue_sessionStart_200_storesBackendSessionId
        TC_adb_MediaSession_processEdgeRequestQueue_sessionStart_207_vaError400_closesSession
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
        TS_public_APIs_BeforeAll
        TS_public_APIs_BeforeEach
        TS_public_APIs_TearDown
        TC_APIs_getVersion
        TC_APIs_setLogLevel
        TC_APIs_setLogLevel_invalid
        TC_APIs_shutdown
        TC_APIs_updateConfiguration
        TC_APIs_updateConfiguration_invalid
        TC_APIs_sendEvent
        TC_APIs_sendEventWithData
        TC_APIs_sendEvent_invalid
        TC_APIs_sendEventWithData_invalidData
        TC_APIs_sendEvent_missingRequiredXDMData
        TC_APIs_sendEventWithCallback
        TC_APIs_sendEventWithCallback_timeout
        TC_APIs_setExperienceCloudId
        TC_APIs_getExperienceCloudId
        TC_APIs_getExperienceCloudId_callbackTimeout
        TC_APIs_createMediaSession
        TC_APIs_createMediaSession_withConfiguration
        TC_APIs_createMediaSession_invalidXDMData
        TC_APIs_createMediaSession_endPrevisouSession
        TC_APIs_sendMediaEvent
        TC_APIs_sendMediaEvent_invalidXDMData
        TC_APIs_sendMediaEvent_invalidSession
        TC_APIs_sendMediaEvent_sessionEnd
        TC_adb_ClientMediaSession
        TC_APIs_setConsent
        TC_APIs_setConsent_invalid
        TC_APIs_setConsent_emptyConsentList
        TC_APIs_setConsentWithCallback
        TC_APIs_setConsentWithCallback_timeout
    ]
    task = [
        'test_eventProcessor.brs
        TC_adb_EventProcessor_handleEvent_setLogLevel
        TC_adb_eventProcessor_handleEvent_setLogLevel_invalid
        TC_adb_eventProcessor_handleEvent_resetIdentities
        TC_adb_eventProcessor_handleEvent_setConfiguration
        TC_adb_eventProcessor_handleEvent_setECID
        TC_adb_eventProcessor_handleEvent_getECID
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
        TC_adb_eventProcessor_dispatchResponseEventToRegisteredModules
        TC_adb_eventProcessor_processQueuedRequests_dispatchesResponses
    ]
    functionList = []
    functionList.Append(common)
    functionList.Append(services)
    functionList.Append(core)
    functionList.Append(consent)
    functionList.Append(edge)
    functionList.Append(media)
    functionList.Append(initSDK)
    functionList.Append(api)
    functionList.Append(task)
    return functionList
end function
