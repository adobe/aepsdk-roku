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
    isoString = dateTime.toIsoString()
    if isoString.EndsWith("Z")
        milliSeconds = StrI(dateTime.GetMilliseconds()).Trim()
        isoString = isoString.Left(isoString.Len() - 1) + "." + milliSeconds + "Z"
    end if
    return isoString
end function

' Returns the current time in milliseconds.
function _adb_timestampInMillis() as longinteger
    longInt& = 0

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

    if timeInMillis.Len() < 13
        _adb_logError("_adb_timestampInMillis() - timeInMillis is not 13 digits long: " + timeInMillis)
        return longInt&
    end if

    ' BrightScript does not have a built-in function to convert a string to a long integer.
    ' However, you can use the following workaround instead:
    longInt& = parseJson(timeInMillis)

    return longInt&

end function