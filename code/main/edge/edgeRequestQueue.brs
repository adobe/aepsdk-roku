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

' ****************************** MODULE: EdgeRequestQueue *********************************

function _adb_isEdgeRequestQueue(obj as object) as boolean
    return (obj <> invalid and obj.type = "com.adobe.module.edge.requestQueue")
end function

function _adb_edgeRequestQueue(name as string, edgeModule as object) as object
    if _adb_isEdgeModule(edgeModule) = false then
        _adb_logError("EdgeRequestQueue::_adb_edgeRequestQueue() - edgeModule is not valid.")
        return invalid
    end if
    requestQueue = _adb_AdobeObject("com.adobe.module.edge.requestQueue")
    requestQueue.Append({
        _name: name,
        _edgeRequestWorker: _adb_EdgeRequestWorker(),
        _edgeModule: edgeModule,

        add: sub(requestId as string, xdmEvents as object, timestampInMillis as longinteger, meta as object, path as string)
            m._edgeRequestWorker.queue(requestId, xdmEvents, timestampInMillis, meta, path)
        end sub,

        processRequests: function() as object
            responseEvents = []

            if not m._edgeRequestWorker.hasQueuedEvent()
                return responseEvents
            end if

            edgeConfig = m._edgeModule._getEdgeConfig()
            if edgeConfig = invalid
                _adb_logVerbose("EdgeRequestQueue::_adb_edgeRequestQueue() - Cannot send network request, invalid configuration.")
                return responseEvents
            end if

            responses = m._edgeRequestWorker.processRequests(edgeConfig.configId, edgeConfig.ecid, edgeConfig.edgeDomain)

            return responses
        end function,
    })
    return requestQueue
end function
