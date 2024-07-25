' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_LocationHintManager()
' @Test
sub TC_adb_LocationHintManager_Init()
    locationHintManager = _adb_LocationHintManager()

    actualLocationHint = locationHintManager.getLocationHint()
    actualExpiryTimer = locationHintManager._expiryTimer
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
    UTF_assertInvalid(actualExpiryTimer, generateErrorMessage("Location hint expiry timer", "invalid", actualExpiryTimer))
end sub

' target: _adb_LocationHintManager_setLocationHint()
' @Test
sub TC_adb_LocationHintManager_setLocationHint_validHintNoTTL()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint)
    expectedExpiryTS = locationHintManager._expiryTimer.initTSInMillis + (locationHintManager._DEFAULT_LOCATION_HINT_TTL_SEC * 1000)

    actualLocationHint = locationHintManager.getLocationHint()
    actualExpiryTS = locationHintManager._expiryTimer.expiryTSInMillis
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertEqual(expectedExpiryTS, actualExpiryTS, generateErrorMessage("Location hint expiry timestamp", expectedExpiryTS, actualExpiryTS))
end sub

' target: _adb_LocationHintManager_setLocationHint()
' @Test
sub TC_adb_LocationHintManager_setLocationHint_validHintWithTTL()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 100)

    expectedExpiryTS = locationHintManager._expiryTimer.initTSInMillis + (100 * 1000) ' TTL is 100 seconds

    actualLocationHint = locationHintManager.getLocationHint()
    actualExpiryTS = locationHintManager._expiryTimer.expiryTSInMillis
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertEqual(expectedExpiryTS, actualExpiryTS, generateErrorMessage("Location hint expiry timestamp", expectedExpiryTS, actualExpiryTS))
end sub

' target: _adb_LocationHintManager_setLocationHint()
' @Test
sub TC_adb_LocationHintManager_setLocationHint_invalid()
    locationHintManager = _adb_LocationHintManager()

    locationHintManager.setLocationHint(invalid)
    actualLocationHint = locationHintManager.getLocationHint()
    actualExpiryTimer = locationHintManager._expiryTimer

    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
    UTF_assertInvalid(actualExpiryTimer, generateErrorMessage("Location hint expiry timer", "invalid", actualExpiryTimer))

    locationHintManager.setLocationHint("")
    actualLocationHint = locationHintManager.getLocationHint()

    actualExpiryTimer = locationHintManager._expiryTimer
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
    UTF_assertInvalid(actualExpiryTimer, generateErrorMessage("Location hint expiry timer", "invalid", actualExpiryTimer))
end sub

' target: _adb_LocationHintManager_isLocationHintExpired()
' @Test
sub TC_adb_LocationHintManager_islocationHintExpired()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    expiryTimer = _adb_ExpiryTimer(100, 0)
    locationHintManager._expiryTimer = expiryTimer

    UTF_assertFalse(locationHintManager._isLocationHintExpired(99), generateErrorMessage("Location hint expiry", "false", "true"))
    UTF_assertFalse(locationHintManager._isLocationHintExpired(100), generateErrorMessage("Location hint expiry", "false", "true"))
    ' Location hint is expired
    UTF_assertTrue(locationHintManager._isLocationHintExpired(101), generateErrorMessage("Location hint expiry", "false", "true"))
end sub

' target: _adb_LocationHintManager_getLocationHint()
' @Test
sub TC_adb_LocationHintManager_getLocationHint_withoutSet()
    locationHintManager = _adb_LocationHintManager()

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", invalid, actualLocationHint))
end sub

' target: _adb_LocationHintManager_getLocationHint()
' @Test
sub TC_adb_LocationHintManager_getLocationHint_expiredTTL_callsDelete()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 100)

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertNotInvalid(locationHintManager._expiryTimer, generateErrorMessage("Location hint expiry timer", "not invalid", locationHintManager._expiryTimer))

    ' mock location hint expiry
    locationHintManager._isLocationHintExpired = function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
        return true
    end function

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint expiry timestamp", "invalid", actualLocationHint))
    UTF_assertInvalid(locationHintManager._locationHint, generateErrorMessage("Location hint", "invalid", locationHintManager._locationHint))
    UTF_assertInvalid(locationHintManager._expiryTimer, generateErrorMessage("Location hint expiry timer", "invalid", locationHintManager._expiryTimer))
end sub

' target: _adb_LocationHintManager_processLocationHintHandle_invalid()
' @Test
sub TC_adb_LocationHintManager_processLocationHintHandle_invalidHandle()
    locationHintManager = _adb_LocationHintManager()

    locationHintManager.processLocationHintHandle(invalid)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))


    locationHintManager.processLocationHintHandle({})
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    invalidHandle = {
        ' missing payload list
        type : "locationHint:result"
    }

    locationHintManager.processLocationHintHandle(invalidHandle)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))


    invalidHandle = {
        payload: [
            ' empty payload
        ],
        type : "locationHint:result"
    }

    locationHintManager.processLocationHintHandle(invalidHandle)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    ' invalid payload.scope
    handle = {
        payload: [
            {
                scope: "invalid",
                hint: "locationHint",
                ttlSeconds: 1800
            }
        ],
        type : "locationHint:result"
    }

    locationHintManager.processLocationHintHandle(handle)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    ' invalid payload.scope
    handle = {
        payload: [
            {
                scope: invalid,
                hint: "locationHint",
                ttlSeconds: 1800
            }
        ],
        type : "locationHint:result"
    }

    locationHintManager.processLocationHintHandle(handle)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    ' missing edgenetwork scope
    handle = {
        payload: [
            {
                scope: "target",
                hint: "locationHint",
                ttlSeconds: 1800
            },
            {
                scope: "audience",
                hint: "locationHint",
                ttlSeconds: 1800
            }
        ],
        type : "locationHint:result"
    }

    locationHintManager.processLocationHintHandle(handle)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

end sub

' target: _adb_LocationHintManager_processLocationHintHandle()
' @Test
sub TC_adb_LocationHintManager_processLocationHintHandle_validHandle()
    locationHintManager = _adb_LocationHintManager()

    handle = {
        payload: [
            {
                scope: "audience",
                hint: "locationHint",
                ttlSeconds: 1800
            },
            {
                scope: "edgenetwork",
                hint: "locationHint",
                ttlSeconds: 1800
            }
        ],
        type : "locationHint:result"
    }

    locationHintManager.processLocationHintHandle(handle)
    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertEqual("locationHint", actualLocationHint, generateErrorMessage("Location hint", "locationHint", actualLocationHint))
end sub

' target: _adb_LocationHintManager_delete()
' @Test
sub TC_adb_LocationHintManager_delete()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 100)

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertNotInvalid(locationHintManager._expiryTimer, generateErrorMessage("Location hint expiry timer", "not invalid", locationHintManager._expiryTimer))

    locationHintManager._delete()

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
    UTF_assertInvalid(locationHintManager._expiryTimer, generateErrorMessage("Location hint expiry timer", "invalid", locationHintManager._expiryTimer))
end sub



