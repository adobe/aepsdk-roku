' ********************** Copyright 2024 Adobe. All rights reserved. **********************
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

' ******************************* MODULE: EdgeRequest *******************************

function _adb_isValidEdgeRequest(obj as object) as boolean
    _CONSTANTS = _adb_InternalConstants()
    if _adb_isEmptyOrInvalidMap(obj) or not _adb_stringEqualsIgnoreCase(obj.type, _CONSTANTS.OBJECT_TYPE.EDGE_REQUEST)
        _adb_logVerbose("EdgeRequest::_adb_isValidEdgeRequest() - Invalid edge request, object is invalid or not of type (" + _CONSTANTS.OBJECT_TYPE.EDGE_REQUEST + ").")
        return false
    end if

    if _adb_isEmptyOrInvalidString(obj._requestId)
        _adb_logVerbose("EdgeRequest::_adb_isValidEdgeRequest() - Invalid edge request, requestId is invalid")
        return false
    end if

    if _adb_isEmptyOrInvalidMap(obj._eventData)
        _adb_logVerbose("EdgeRequest::_adb_isValidEdgeRequest() - Invalid edge request, eventData object is invalid")
        return false
    end if

    if _adb_isInvalidLongInt(obj._timestampInMillis) or obj._timestampInMillis <= 0&
        _adb_logVerbose("EdgeRequest::_adb_isValidEdgeRequest() - Invalid edge request, timestampInMillis :(" + FormatJson(obj.timestampInMillis) + ") is invalid")
        return false
    end if

    return true
end function

function _adb_isEdgeConsentRequest(obj as object) as boolean
    _CONSTANTS = _adb_InternalConstants()
    return _adb_isValidEdgeRequest(obj) and _adb_stringEqualsIgnoreCase(obj._requestType, _CONSTANTS.REQUEST_TYPE.CONSENT)
end function

function _adb_EdgeRequest(requestId as string, data as object, timestampInMillis as longinteger) as object
    _CONSTANTS = _adb_InternalConstants()
    if _adb_isEmptyOrInvalidString(requestId)
        _adb_logDebug("EdgeRequest::_adb_EdgeRequest() - Invalid edge request, requestId is invalid")
        return invalid
    end if

    if _adb_isEmptyOrInvalidMap(data)
        _adb_logDebug("EdgeRequest::_adb_EdgeRequest() - Invalid edge request, eventData object is invalid")
        return invalid
    end if

    if _adb_isInvalidLongInt(timestampInMillis) or timestampInMillis <= 0&
        _adb_logDebug("EdgeRequest::_adb_EdgeRequest() - Invalid edge request, timestampInMillis :(" + FormatJson(obj.timestampInMillis) + ") is invalid")
        return invalid
    end if

    edgeRequest = _adb_AdobeObject(_CONSTANTS.OBJECT_TYPE.EDGE_REQUEST)

    edgeRequest.Append({
        _EDGE_INTERACT_PATH: "/v1/interact",
        _CONSTANTS: _adb_InternalConstants(),
        _requestId: invalid,
        _eventData: invalid,
        _timestampInMillis: invalid,
        _meta: invalid,
        _path: invalid,
        _requestType: invalid,

        _init: function(requestId as string, data as object, timestampInMillis as longinteger)
            m._requestId = requestId
            m._eventData = data
            m._timestampInMillis = timestampInMillis
            m._meta = {}
            m._path = m._EDGE_INTERACT_PATH
            m._requestType = m._CONSTANTS.REQUEST_TYPE.EDGE
        end function,

        setMeta: function(meta as object) as void
            m._meta = meta
        end function,

        setPath: function(path as dynamic) as void
            m._path = path
        end function,

        setRequestType: function(requestType as string) as void
            m._requestType = requestType
        end function,

        getRequestId: function() as string
            return m._requestId
        end function,

        getEventData: function() as object
            return m._eventData
        end function,

        getTimestampInMillis: function() as longinteger
            return m._timestampInMillis
        end function,

        getMeta: function() as object
            return m._meta
        end function,

        getPath: function() as string
            return m._path
        end function,

        getRequestType: function() as string
            return m._requestType
        end function
    })

    edgeRequest._init(requestId, data, timestampInMillis)

    return edgeRequest
end function
