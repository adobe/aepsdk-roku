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
        _map: {},

        createNewSession: sub(clientSessionId as string)
            if _adb_isEmptyOrInvalidString(clientSessionId)
                _adb_logError("createNewSession() - clientSessionId is invalid.")
                return
            end if
            if m._map.DoesExist(clientSessionId)
                _adb_logError("createNewSession() - clientSessionId already exists.")
                return
            end if
            m._map[clientSessionId] = {
                sessionId: invalid,
                location: invalid,
                queue: []
            }
        end sub,

        updateSessionIdAndGetQueuedData: function(clientSessionId as string, sessionId as string, location as string) as object
            if m._map.DoesExist(clientSessionId)
                m._map[clientSessionId].sessionId = sessionId
                m._map[clientSessionId].location = location
                return m._map[clientSessionId].queue
            end if
            _adb_logError("updateSessionId() - clientSessionId is invalid.")
            return []
        end function,

        getLocation: function(clientSessionId as string) as string
            session = m._map.Lookup(clientSessionId)
            if session = invalid
                return ""
            end if
            return session.location
        end function,

        getSessionId: function(clientSessionId as string) as string
            session = m._map.Lookup(clientSessionId)
            if session = invalid
                return ""
            end if
            return session.sessionId
        end function,

        queueMediaData: sub(clientSessionId as string, requestId as string, data as object, timestampInMillis as longinteger)
            if m._map.DoesExist(clientSessionId)
                m._map[clientSessionId].queue.Push({
                    requestId: requestId,
                    data: data,
                    timestampInMillis: timestampInMillis
                })
                return
            end if
            _adb_logError("queueMediaData() - clientSessionId is invalid.")
        end sub,

        deleteSession: sub(clientSessionId as string)
            m._map.Delete(clientSessionId)
        end sub,
    }
end function