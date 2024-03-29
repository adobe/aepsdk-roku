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

' ********************************** MODULE: Media utils **********************************

function _adb_isValidMediaXDMData(xdmData as object) as boolean
    if _adb_isEmptyOrInvalidMap(xdmData) or _adb_isEmptyOrInvalidMap(xdmData.xdm) or _adb_isEmptyOrInvalidString(xdmData.xdm["eventType"])
        return false
    end if

    eventType = xdmData.xdm["eventType"]

    return _adb_isValidMediaEvent(eventType)

    return true
end function

function _adb_extractPlayheadFromMediaXDMData(xdmData as object) as integer
    if _adb_isEmptyOrInvalidMap(xdmData) or _adb_isEmptyOrInvalidMap(xdmData.xdm) or _adb_isEmptyOrInvalidMap(xdmData.xdm["mediaCollection"]) or type(xdmData.xdm["mediaCollection"]["playhead"]) <> "roInteger"
        return -1
    end if
    return xdmData.xdm["mediaCollection"]["playhead"]
end function

function _adb_containsPlayheadValue(xdmData as object) as boolean
    if _adb_isEmptyOrInvalidMap(xdmData) or _adb_isEmptyOrInvalidMap(xdmData.xdm) or _adb_isEmptyOrInvalidMap(xdmData.xdm["mediaCollection"]) or xdmData.xdm["mediaCollection"]["playhead"] = invalid
        return false
    end if
    return true
end function

function _adb_isValidMediaEvent(eventType as dynamic) as boolean
    if _adb_isEmptyOrInvalidString(eventType)
        return false
    end if

    supportedMediaEvents = _adb_InternalConstants().MEDIA.EVENT_TYPE
    for each item in supportedMediaEvents.Items()
        constEventType = item.value
        if eventType = constEventType then
            return true
        end if
    end for
    return false
end function
