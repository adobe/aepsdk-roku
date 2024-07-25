' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_ExpiryTimer()
' @Test
sub TC_adb_ExpiryTimer_init()
    expiryTimer = _adb_ExpiryTimer(1800, 0)
    UTF_assertEqual(expiryTimer.initTSInMillis, 0&)
    UTF_assertEqual(expiryTimer.expiryTSInMillis, 1800&)
    UTF_assertFalse(expiryTimer.isExpired(0), "expiryTimer.isExpired() should return false")
    UTF_assertTrue(expiryTimer.isExpired(1801), "expiryTimer.isExpired(1800001) should return true")
end sub

' target: _adb_ExpiryTimer()
' @Test
sub TC_adb_ExpiryTimer_initWithoutStartTime()
    expiryTimer = _adb_ExpiryTimer(1800)

    UTF_assertNotInvalid(expiryTimer.initTSInMillis)

    initTSInMillis = expiryTimer.initTSInMillis
    expectedExpiryTSInMillis = initTSInMillis + 1800

    UTF_assertEqual(expiryTimer.expiryTSInMillis, expectedExpiryTSInMillis)
    UTF_assertFalse(expiryTimer.isExpired())
    UTF_assertTrue(expiryTimer.isExpired(expectedExpiryTSInMillis + 1))
end sub
