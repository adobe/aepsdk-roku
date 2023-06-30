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

' ******************************** MODULE: datetime utils *********************************

function _adb_ISO8601_timestamp() as string
    dateTime = createObject("roDateTime")
    return dateTime.toIsoString()
end function

function _adb_timestampInMillis() as integer
    dateTime = CreateObject("roDateTime")
    currMS = dateTime.GetMilliseconds()
    timeInSeconds = dateTime.AsSeconds()

    timeInMillis = timeInSeconds.ToStr()
    if currMS > 99
        timeInMillis = timeInMillis + currMS.ToStr()
    else if currMS > 9 and currMS < 100
        timeInMillis = timeInMillis + "0" + currMS.ToStr()
    else if currMS >= 0 and currMS < 10
        timeInMillis = timeInMillis + "00" + currMS.ToStr()
    end if

    return box(timeInMillis).ToInt()
end function