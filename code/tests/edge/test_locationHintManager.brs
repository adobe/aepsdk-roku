' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' @BeforeEach
sub TS_LocationHintManager_BeforeEach()
    _adb_testUtil_clearPersistedLocationHint()
end sub

' @AfterEach
sub TS_LocationHintManager_AfterEach()
    _adb_testUtil_clearPersistedLocationHint()
end sub

' target: _adb_LocationHintManager()
' @Test
sub TC_adb_LocationHintManager_Init()
    locationHintManager = _adb_LocationHintManager()

    actualLocationHint = locationHintManager.getLocationHint()
    actualExpiryTS& = locationHintManager._expiryTSInMillis&
    invalidTS& = _adb_InternalConstants().TIMESTAMP.INVALID_VALUE

    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
    UTF_assertEqual(invalidTS&, actualExpiryTS&, generateErrorMessage("Location hint expiry timestamp", invalidTS&, actualExpiryTS&))
end sub

' target: _adb_LocationHintManager()
' @Test
sub TC_adb_LocationHintManager_Init_locationHintPersisted_notExpired()
    ' Mock persisted location hint
    _adb_testUtil_persistLocationHint("persistedLocationHint", 1000&)

    ' Init should load persisted location hint
    locationHintManager = _adb_LocationHintManager()

    ' mock _isLocationHintExpired
    locationHintManager._isLocationHintExpired = function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
        return false
    end function

    actualLocationHint = locationHintManager.getLocationHint()
    actualExpiryTS& = locationHintManager._expiryTSInMillis&

    UTF_assertEqual("persistedLocationHint", actualLocationHint, generateErrorMessage("Location hint", "persistedLocationHint", actualLocationHint))
    UTF_assertEqual(1000&, actualExpiryTS&, generateErrorMessage("Location hint expiry timestamp", 1000&, actualExpiryTS&))
end sub

' target: _adb_LocationHintManager_setLocationHint()
' @Test
sub TC_adb_LocationHintManager_setLocationHint_validHintNoTTL()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 1&, 0&)
    expectedExpiryTS& = 1000&

    actualLocationHint = locationHintManager._locationHint
    actualExpiryTS& = locationHintManager._expiryTSInMillis&
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertEqual(expectedExpiryTS&, actualExpiryTS&, generateErrorMessage("Location hint expiry timestamp", expectedExpiryTS&, actualExpiryTS&))

    ' assert that location hint data is persisted
    persistedLocationHint = _adb_testUtil_getPersistedLocationHint()
    persistedExpiryTS& = persistedLocationHint.expiryTs
    UTF_assertEqual(locationHint, persistedLocationHint.value, generateErrorMessage("Persisted location hint", locationHint, persistedLocationHint.value))
    UTF_assertEqual(locationHintManager._expiryTSInMillis&, persistedExpiryTS&, generateErrorMessage("Persisted location hint expiry timestamp", locationHintManager._expiryTSInMillis&, persistedExpiryTS&))
end sub

' target: _adb_LocationHintManager_setLocationHint()
' @Test
sub TC_adb_LocationHintManager_setLocationHint_validHintWithTTL()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 1&, 0&)

    expectedExpiryTS& = 1000&

    actualLocationHint = locationHintManager._locationHint
    actualExpiryTS& = locationHintManager._expiryTSInMillis&
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertEqual(expectedExpiryTS&, actualExpiryTS&, generateErrorMessage("Location hint expiry timestamp", expectedExpiryTS&, actualExpiryTS&))

    ' assert that location hint data is persisted
    persistedLocationHint = _adb_testUtil_getPersistedLocationHint()
    persistedExpiryTS& = persistedLocationHint.expiryTs
    UTF_assertEqual(locationHint, persistedLocationHint.value, generateErrorMessage("Persisted location hint", locationHint, persistedLocationHint.value))
    UTF_assertEqual(locationHintManager._expiryTSInMillis&, persistedExpiryTS&, generateErrorMessage("Persisted location hint expiry timestamp", locationHintManager._expiryTSInMillis&, persistedExpiryTS&))
end sub

' target: _adb_LocationHintManager_setLocationHint()
' @Test
sub TC_adb_LocationHintManager_setLocationHint_invalid()
    locationHintManager = _adb_LocationHintManager()

    locationHintManager.setLocationHint(invalid)
    actualLocationHint = locationHintManager._locationHint
    actualExpiryTS& = locationHintManager._expiryTSInMillis&
    invalidTS& = _adb_InternalConstants().TIMESTAMP.INVALID_VALUE

    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint (1)", "invalid", actualLocationHint))
    UTF_assertEqual(invalidTS& ,actualExpiryTS&, generateErrorMessage("Location hint expiry timestamp (1)", invalidTS&, actualExpiryTS&))

    locationHintManager.setLocationHint("")
    actualLocationHint = locationHintManager._locationHint

    actualExpiryTS& = locationHintManager._expiryTSInMillis&

    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint (2)", "invalid", actualLocationHint))
    UTF_assertEqual(invalidTS& ,actualExpiryTS&, generateErrorMessage("Location hint expiry timestamp (2)", invalidTS&, actualExpiryTS&))

    ' assert that location hint data is not persisted
    persistedLocationHint = _adb_testUtil_getPersistedLocationHint()
    UTF_assertInvalid(persistedLocationHint, generateErrorMessage("Persisted location hint", "invalid", persistedLocationHint))
end sub

' target: _adb_LocationHintManager_isLocationHintExpired()
' @Test
sub TC_adb_LocationHintManager_islocationHintExpired()
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager._expiryTSInMillis& = 100&

    UTF_assertFalse(locationHintManager._isLocationHintExpired(99), generateErrorMessage("Location hint expiry at timestamp:(99)", "false", "true"))
    UTF_assertFalse(locationHintManager._isLocationHintExpired(100), generateErrorMessage("Location hint expiry at timestamp:(100)", "false", "true"))
    ' Location hint is expired
    UTF_assertTrue(locationHintManager._isLocationHintExpired(101), generateErrorMessage("Location hint expiry at timestamp:(101)", "false", "true"))
end sub

' target: _adb_LocationHintManager_getLocationHint()
' @Test
sub TC_adb_LocationHintManager_getLocationHint_noPersistedValue()
    locationHintManager = _adb_LocationHintManager()

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", invalid, actualLocationHint))
end sub

' target: _adb_LocationHintManager_getLocationHint()
' @Test
sub TC_adb_LocationHintManager_getLocationHint_persistedValue_notExpired()
        ' Mock persisted location hint
        _adb_testUtil_persistLocationHint("persistedLocationHint", 100&)

        ' Init should load persisted location hint
        locationHintManager = _adb_LocationHintManager()

        ' mock _isLocationHintExpired
        locationHintManager._isLocationHintExpired = function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
            return false
        end function

        actualLocationHint = locationHintManager.getLocationHint()

        UTF_assertEqual("persistedLocationHint", actualLocationHint, generateErrorMessage("Location hint", "persistedLocationHint", actualLocationHint))
end sub

' target: _adb_LocationHintManager_getLocationHint()
' @Test
sub TC_adb_LocationHintManager_getLocationHint_persistedValue_expired()
    ' Mock persisted location hint
    _adb_testUtil_persistLocationHint("persistedLocationHint", 100&)

    ' Init should load persisted location hint
    locationHintManager = _adb_LocationHintManager()

    ' mock _isLocationHintExpired
    locationHintManager._isLocationHintExpired = function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
        return true
    end function

    actualLocationHint = locationHintManager.getLocationHint()

    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))

    ' assert that location hint data is deleted
    persistedLocationHint = _adb_testUtil_getPersistedLocationHint()
    UTF_assertInvalid(persistedLocationHint, generateErrorMessage("Persisted location hint", "invalid", persistedLocationHint))
end sub

' target: _adb_LocationHintManager_getLocationHint()
' @Test
sub TC_adb_LocationHintManager_getLocationHint_expiredTTL_callsDelete()
    invalidTS& = _adb_InternalConstants().TIMESTAMP.INVALID_VALUE
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 100&, 0&)

    ' mock location hint not expired
    locationHintManager._isLocationHintExpired = function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
        return false
    end function

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertNotEqual(invalidTS&, locationHintManager._expiryTSInMillis&, generateErrorMessage("Location hint expiry timestamp", "not invalid", locationHintManager._expiryTSInMillis&))

    ' mock location hint expiry
    locationHintManager._isLocationHintExpired = function(currentTimeInMillis = _adb_timestampInMillis() as longinteger) as boolean
        return true
    end function

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint expiry timestamp", "invalid", actualLocationHint))
    UTF_assertInvalid(locationHintManager._locationHint, generateErrorMessage("Location hint", "invalid", locationHintManager._locationHint))
    UTF_assertEqual(invalidTS&, locationHintManager._expiryTSInMillis&, generateErrorMessage("Location hint expiry timestamp", invalidTS&, locationHintManager._expiryTSInMillis&))
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
        payload: [m._DEFAULT_LOCATION_HINT_TTL_SEC
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
    invalidTS& = _adb_InternalConstants().TIMESTAMP.INVALID_VALUE
    locationHintManager = _adb_LocationHintManager()
    locationHint = "locationHint"

    locationHintManager.setLocationHint(locationHint, 100)

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertEqual(locationHint, actualLocationHint, generateErrorMessage("Location hint", locationHint, actualLocationHint))
    UTF_assertNotEqual(invalidTS&, locationHintManager._expiryTSInMillis&, generateErrorMessage("Location hint expiry timestamp", "not invalid", locationHintManager._expiryTSInMillis&))

    locationHintManager._delete()

    actualLocationHint = locationHintManager.getLocationHint()
    UTF_assertInvalid(actualLocationHint, generateErrorMessage("Location hint", "invalid", actualLocationHint))
    UTF_assertEqual(invalidTS&, locationHintManager._expiryTSInMillis&, generateErrorMessage("Location hint expiry timestamp", invalidTS&, locationHintManager._expiryTSInMillis&))
end sub
