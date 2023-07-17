' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_optMapFromMap()
' @Test
sub TC_adb_optMapFromMap()
    UTF_assertEqual({ "key": "value" }, _adb_optMapFromMap({ "map": { "key": "value" } }, "map"))


    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": 1 }, "map"))
    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": "string" }, "map"))
    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": true }, "map"))
    UTF_assertEqual(invalid, _adb_optMapFromMap(invalid, "map1"))
    UTF_assertEqual(invalid, _adb_optMapFromMap({ "map": { "key": "value" } }, "map1"))

    UTF_assertEqual({}, _adb_optMapFromMap({ "map": { "key": "value" } }, "map1", {}))
    UTF_assertEqual(false, _adb_optMapFromMap({ "map": { "key": "value" } }, "map1", false))
    UTF_assertEqual("invalidMap", _adb_optMapFromMap({ "map": { "key": "value" } }, "map1", "invalidMap"))
end sub


' target: _adb_optStringFromMap()
' @Test
sub TC_adb_optStringFromMap()
    UTF_assertEqual("value", _adb_optStringFromMap({ "key": "value" }, "key"))

    UTF_assertEqual(invalid, _adb_optStringFromMap({ "key": 1 }, "key"))
    UTF_assertEqual(invalid, _adb_optStringFromMap({ "key": true }, "key"))
    UTF_assertEqual(invalid, _adb_optStringFromMap({ "key": "value" }, "key1"))
    UTF_assertEqual(invalid, _adb_optStringFromMap(invalid, "key1"))

    UTF_assertEqual("invalid", _adb_optStringFromMap({ "key": "value" }, "key1", "invalid"))
    UTF_assertEqual(false, _adb_optStringFromMap({ "key": "value" }, "key1", false))
    UTF_assertEqual({}, _adb_optStringFromMap({ "key": "value" }, "key1", {}))
end sub

' target: _adb_optIntFromMap()
' @Test
sub TC_adb_optIntFromMap()
    UTF_assertEqual(1, _adb_optIntFromMap({ "key": 1 }, "key"))

    UTF_assertEqual(invalid, _adb_optIntFromMap({ "key": "value" }, "key1"))
    UTF_assertEqual(invalid, _adb_optIntFromMap({ "key": true }, "key1"))
    UTF_assertEqual(invalid, _adb_optIntFromMap({ "key": 1 }, "key1"))
    UTF_assertEqual(invalid, _adb_optIntFromMap(invalid, "key1"))

    UTF_assertEqual(-1, _adb_optIntFromMap({ "key": "value" }, "key1", -1))
    UTF_assertEqual(false, _adb_optIntFromMap({ "key": "value" }, "key1", false))
    UTF_assertEqual("invalid", _adb_optIntFromMap({ "key": "value" }, "key1", "invalid"))
    UTF_assertEqual({}, _adb_optIntFromMap({ "key": "value" }, "key1", {}))
end sub