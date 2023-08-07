' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_AdobeObject()
' @Test
sub TC_adb_AdobeObject()
    object = _adb_AdobeObject("object_type_1")
    UTF_assertEqual("adobe", object.owner)
    UTF_assertEqual("object_type_1", object.type)
    UTF_assertEqual("LongInteger", Type(object.timestampInMillis), "timestampInMillis is not a long int")
end sub
