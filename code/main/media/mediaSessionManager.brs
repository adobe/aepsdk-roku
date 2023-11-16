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
        _activeSession: invalid,

        createSession: function(clientSessionId as string, configurationModule as object, sessionConfig as object, edgeRequestQueue as object) as void
            ' End the current session if any
            m.endSession()

            ' Start a new session
            m._activeSession = _adb_MediaSession(clientSessionId, configurationModule, sessionConfig, edgeRequestQueue)

        end function,

        queue: function(mediaHit as object) as void
            ' Check if there is any active session
            if not m._existActiveSession() then
                return
            end if

            m._activeSession.process(mediaHit)
        end function,

        endSession: function(isAbort = false as boolean) as void
            ' Check if there is any active session
            if m._activeSession = invalid then
                return
            end if

            ' Handle session end
            ' Dispatch all the hits before closing and deleting the internal session
            m._activeSession.close(isAbort)
            m._activeSession = invalid
        end function,

        getActiveClientSessionId: function() as string
            if m._activeSession = invalid then
                return ""
            end if

            return m._activeSession.getClientSessionId()
        end function,

        _existActiveSession: function() as boolean
            return m._activeSession <> invalid
        end function,

        _getBackendSessionId: function() as string
            if m._activeSession = invalid then
                return ""
            end if

            return m._activeSession._backendSessionId
        end function,
    }
end function
