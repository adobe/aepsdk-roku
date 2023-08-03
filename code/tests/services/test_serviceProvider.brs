' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_serviceProvider()
' @Test
sub TC_adb_serviceProvider()
    instance1 = _adb_serviceProvider()
    instance1.test = "test123"
    instance2 = _adb_serviceProvider()
    UTF_assertEqual(instance1.test, instance2.test)
    ' _adb_serviceProvider() should always return a singleton instance
    UTF_assertEqual(GetGlobalAA()._adb_serviceProvider_instance.test, instance1.test)
end sub