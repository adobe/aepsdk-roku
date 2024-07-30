' ********************** Copyright 2024 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_timer()
' @Test
sub TC_adb_timer_init()
    timer = _adb_timer(1800, 0)
    UTF_assertEqual(timer.initTSInMillis, 0&)
    UTF_assertEqual(timer.expiryTSInMillis, 1800&)
    UTF_assertFalse(timer.isExpired(0), "timer.isExpired() should return false")
    UTF_assertTrue(timer.isExpired(1801), "timer.isExpired(1800001) should return true")
end sub

' target: _adb_timer()
' @Test
sub TC_adb_timer_initWithoutStartTime()
    timer = _adb_timer(1800)

    UTF_assertNotInvalid(timer.initTSInMillis)

    initTSInMillis = timer.initTSInMillis
    expectedExpiryTSInMillis = initTSInMillis + 1800

    UTF_assertEqual(timer.expiryTSInMillis, expectedExpiryTSInMillis)
    UTF_assertFalse(timer.isExpired())
    UTF_assertTrue(timer.isExpired(expectedExpiryTSInMillis + 1))
end sub
