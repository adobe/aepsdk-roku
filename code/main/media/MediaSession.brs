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

 ' ***************************** MODULE: MediaSession *******************************

 function _adb_MediaSession(id as string, config as object, hitProcessor as object) as object
     return {
        _id = id,
        _SESSION_IDLE_THRESHOLD_SEC: 10 * 60, ' 30 minutes in pause state
        _LONG_SESSION_THRESHOLD_SEC: 24 * 60 * 60, ' 24 hours
        _DEFAULT_PING_INTERVAL_SEC: 10, ' 10 seconds
        _config: config,
        _backendSessionId: invalid,
        _hitQueue: [],
        _isActive: false,
        _lastEventTS: -1,
        _lastEventType: invalid,
        _hitProcessor: hitProcessor,

        start: sub()
            ' Start the session
            _isActive = true
        end sub,

        handleQueueEvent: sub(requestId as string, xdmData as object, tsObject as object)
        end sub,

        handleSessionEnd: sub(sessionId as string)
        ' Handle session end
        ' Dispatch all the hits before closing and deleting the internal session
        end sub,

        handleSessionUpdate: function(sessionId as string, backendSessionId as string)
        ' Handle backned session ID and append to all the low level media events
        end function,

        _processQueue: sub()
        ' Process the queue and send the hits to edgeWorker
        end sub,

        _isIdle: sub() as boolean
        ' Check if the session is idle for >= 30 minutes
        end sub,

        _isLongRunningSession: sub() as boolean
        ' Check if the session is long running >= 24 hours
        end sub,

        _getPingInterval: sub(isAd as boolean = false) as integer
        ' Get the ping interval for the event type
        ' Calculate ping interval based on config and isAd flag
        end sub,
     }
 end function
