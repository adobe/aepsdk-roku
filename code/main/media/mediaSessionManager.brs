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

        createSession: sub(clientSessionId as string, config as object, edgeRequestQueue as object) as void
            ' End the current session if any
            endSession()

            ' Start a new session
            sessionId = _adb_generateUUID()
            m._currSession = _adb_MediaSession(sessionId, config, edgeRequestQueue)

        end sub,

        queue: sub(requestId as string, eventType as string, xdmData as object, tsObject as object)
            ' Check if there is any active session
            if m._currSession is invalid then
                return
            end if

            m._currSession.queue(requestId, eventType, xdmData, tsObject)

            ''' Check for inactive sessions with pending hits. Delete the session if all the hits are dispatched
            m._checkInactiveSessionsForPendingHits()
        end sub,

        endSession: sub(isAbort as boolean = false)
            ' Check if there is any active session
            if m._currSession is invalid then
                return
            end if

            ' Handle session end
            ' Dispatch all the hits before closing and deleting the internal session
            m._inactiveSessionMap[_currSession.id] = m._currSession
            m._currSession = invalid
        end sub,

        _checkInactiveSessionsForPendingHits: sub()
            ' Check for old sessions and dispatch pending hits
            ' iterate over all the sessions in the session map and check if all the hits are dispatched
            ' if the session is not active and hit queue is empty, delete the session
            for each sessionId in m._inactiveSessionMap
                session = m._inactiveSessionMap[sessionId]
                if not session.isActive and session.getHitQueueSize() = 0 then
                    m._inactiveSessionMap.remove(sessionId)
                else
                    ' Dispatch all the hits before deleting the internal session
                    session.processQueuedEvents()
                end if
            end for

        end sub,
     }
 end function
