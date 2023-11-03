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

 ' ***************************** MODULE: MediaSessionManager *******************************

 function _adb_MediaSessionManager() as object
     return {
        _inactiveSessionMap: {},
        _currSession: invalid,

        createSession: sub(config as object, edgeHitProcessor as object) as string
            ' Create a new session and return the session ID
            ' set session to active
            sessionId = _adb_generateUUID()
            _currSession = _adb_MediaSession(sessionId, config, edgeHitProcessor)
            _currSession.start()

        end sub,

        queue: sub(requestId as string, xdmData as object, tsObject as object)
        end sub,

        endSession: sub(isAbort as boolean = false)
        ' Handle session end
        ' Dispatch all the hits before closing and deleting the internal session

            _inactiveSessionMap.(_currSession.id, _currSession)
        end sub,

        updateBackendSessionId: sub(backendSessionId as string)
        ' Handle backend session ID and append to all the low level media events
        end sub,

        notifyError: sub(error as string)
        ' Handle error
        end sub,

        _checkOldSessionsForPendingHits: sub()
        ' Check for old sessions and dispatch pending hits
        ' iterate over all the sessions in the session map and check if all the hits are dispatched
        ' delete the sessions if the hit is dispatched
        end sub,
     }
 end function
