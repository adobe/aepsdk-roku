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
        _SESSION_IDLE_THRESHOLD_SEC: 10 * 60, ' 10 minutes
        _DEFAULT_PING_INTERVAL_SEC: 10, ' 10 seconds

        createNewSession: sub(clientSessionId as string, mainPingInterval = m._DEFAULT_PING_INTERVAL_SEC as integer, adPingInternal = m._DEFAULT_PING_INTERVAL_SEC as integer)
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
                queue: [],
                lastActiveTS: invalid,
                mainPingInterval: mainPingInterval,
                adPingInternal: adPingInternal,
                lastPingTS: _adb_timestampInMillis(),
            }
        end sub,

        shouldSendPing: function(clientSessionId as string, timestampInMillis as longinteger) as boolean
            if m._map.DoesExist(clientSessionId)
                session = m._map[clientSessionId]
                return (timestampInMillis - session.lastPingTS >= session.mainPingInterval * 1000)
            end if
            _adb_logError("shouldSendPing() - clientSessionId is invalid.")
            return false
        end function,

        recordSessionActivity: sub(clientSessionId as string, timestampInMillis as longinteger)
            if m._map.DoesExist(clientSessionId)
                m._map[clientSessionId].lastActiveTS = timestampInMillis
                return
            end if
            _adb_logError("recordSessionActivity() - clientSessionId is invalid.")
        end sub,

        findIdleSessions: function(timestampInMillis as longinteger) as object
            ' TODO: iterate stored sessions and find idle sessions (currentTS - lastActiveTS > SESSION_IDLE_THRESHOLD)
            return []
        end function,

        findLongRunningSessions: function(timestampInMillis as longinteger) as object
            ' TODO: iterate stored sessions and find sessions running over 24 hours
            return []
        end function,

        updateSessionIdAndGetQueuedRequests: function(clientSessionId as string, sessionId as string) as object
            if m._map.DoesExist(clientSessionId)
                m._map[clientSessionId].sessionId = sessionId
                queuedRequests = m._map[clientSessionId].queue
                ' clean the queued requests
                m._map[clientSessionId].queue = []
                return queuedRequests
            end if
            _adb_logError("updateSessionIdAndGetQueuedRequests() - clientSessionId is invalid.")
            return []
        end function,

        isSessionStarted: function(clientSessionId as string) as boolean
            return m._map.Lookup(clientSessionId) <> invalid
        end function,

        getSessionId: function(clientSessionId as string) as string
            session = m._map.Lookup(clientSessionId)
            if session = invalid or session.sessionId = invalid
                return ""
            end if
            return session.sessionId
        end function,

        queueMediaRequest: sub(requestId as string, clientSessionId as string, xdmData as object, tsObject as object)
            if m._map.DoesExist(clientSessionId)
                m._map[clientSessionId].queue.Push({
                    requestId: requestId,
                    xdmData: xdmData,
                    tsObject: tsObject
                })
                return
            end if
            _adb_logError("queueMediaRequest() - clientSessionId is invalid.")
        end sub,

        deleteSession: sub(clientSessionId as string)
            m._map.Delete(clientSessionId)
        end sub,
    }
end function