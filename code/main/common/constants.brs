' ********************** Copyright 2023 Adobe. All rights reserved. **********************
' *
' * This file is licensed to you under the Apache License, Version 2.0 (the "License");
' * you may not use this file except in compliance with the License. You may obtain a copy
' * of the License at http://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software distributed under
' * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' * OF ANY KIND, either express or implied. See the License for the specific language
' * governing permissions and limitations under the License.
' *
' *****************************************************************************************

' ********************************** MODULE: constants ************************************

function _adb_InternalConstants() as object
    return {
        PUBLIC_API: {
            SET_CONFIGURATION: "setConfiguration",
            SET_EXPERIENCE_CLOUD_ID: "setExperienceCloudId",
            GET_EXPERIENCE_CLOUD_ID: "getExperienceCloudId",
            RESET_IDENTITIES: "resetIdentities",
            SEND_EDGE_EVENT: "sendEvent",
            SET_CONSENT: "setConsent",
            SET_LOG_LEVEL: "setLogLevel",
            RESET_SDK: "resetSDK",
            CREATE_MEDIA_SESSION: "createMediaSession",
            SEND_MEDIA_EVENT: "sendMediaEvent",
        },
        EVENT_DATA_KEY: {
            LOG: { LEVEL: "level" },
            ECID: "ecid",
        },
        LOCAL_DATA_STORE_KEYS: {
            ECID: "ecid",
            CONSENT_COLLECT: "consent.collect",
            LOCATION_HINT: "locationhint",
            STATE_STORE: "statestore",
        },
        TASK: {
            REQUEST_EVENT: "requestEvent",
            RESPONSE_EVENT: "responseEvent",
        },
        MEDIA: {
            EVENT_TYPE : {
                SESSION_START: "media.sessionStart",
                PLAY: "media.play",
                PING: "media.ping",
                BITRATE_CHANGE: "media.bitrateChange",
                BUFFER_START: "media.bufferStart",
                PAUSE_START: "media.pauseStart",
                AD_BREAK_START: "media.adBreakStart",
                AD_START: "media.adStart",
                AD_COMPLETE: "media.adComplete",
                AD_SKIP: "media.adSkip",
                AD_BREAK_COMPLETE: "media.adBreakComplete",
                CHAPTER_START: "media.chapterStart",
                CHAPTER_COMPLETE: "media.chapterComplete",
                CHAPTER_SKIP: "media.chapterSkip",
                ERROR: "media.error",
                STATES_UPDATE: "media.statesUpdate",
                SESSION_END: "media.sessionEnd",
                SESSION_COMPLETE: "media.sessionComplete"
            }
        },
        TIMESTAMP: {
            INVALID_VALUE: -1&
        }
        CALLBACK_TIMEOUT_MS: 5000,
        EVENT_OWNER: "adobe",
    }
end function
