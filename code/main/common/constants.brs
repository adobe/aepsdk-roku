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
            RESET_IDENTITIES: "resetIdentities",
            SEND_EDGE_EVENT: "sendEvent",
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
            ECID: "ecid"
        },
        TASK: {
            REQUEST_EVENT: "requestEvent",
            RESPONSE_EVENT: "responseEvent",
        },
        MEDIA: {
            EVENT_TYPES: ["media.play", "media.ping", "media.bitrateChange", "media.bufferStart", "media.pauseStart", "media.adBreakStart", "media.adStart", "media.adComplete", "media.adSkip", "media.adBreakComplete", "media.chapterStart", "media.chapterComplete", "media.chapterSkip", "media.error", "media.sessionEnd", "media.sessionComplete", "media.statesUpdate"],
            SESSION_START_EVENT_TYPE: "media.sessionStart",
            SESSION_END_EVENT_TYPE: "media.sessionEnd",
            SESSION_START_EDGE_REQUEST_PATH: "/ee/va/v1/sessionStart",
            PING_INTERVAL_SEC: 10, ' seconds
        },
        CALLBACK_TIMEOUT_MS: 5000,
        EVENT_OWNER: "adobe",
    }
end function