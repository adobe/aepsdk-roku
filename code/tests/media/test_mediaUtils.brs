' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

' target: _adb_extractPlayheadFromMediaXDMData()
' @Test
sub TC_adb_extractPlayheadFromMediaXDMData()
    playhead = _adb_extractPlayheadFromMediaXDMData({
        "xdm": {
            "mediaCollection": {
                "playhead": 123
            }
        }
    })
    UTF_assertEqual(playhead, 123)
end sub

' target: _adb_extractPlayheadFromMediaXDMData()
' @Test
sub TC_adb_extractPlayheadFromMediaXDMData_invalidType()
    playhead = _adb_extractPlayheadFromMediaXDMData({
        "xdm": {
            "mediaCollection": {
                "playhead": "xyz"
            }
        }
    })
    UTF_assertEqual(playhead, -1)
end sub

' target: _adb_extractPlayheadFromMediaXDMData()
' @Test
sub TC_adb_extractPlayheadFromMediaXDMData_invalid()
    playhead = _adb_extractPlayheadFromMediaXDMData({
        "xdm": {
            "mediaCollection_invalid": {
                "playhead": "xyz"
            }
        }
    })
    UTF_assertEqual(playhead, -1)
end sub

' target: _adb_isValidMediaXDMData()
' @Test
sub TC_adb_isValidMediaXDMData()
    UTF_assertTrue(_adb_isValidMediaXDMData({
        "xdm": {
            "eventType": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 0,
            }
        }
    }))
end sub

' target: _adb_isValidMediaXDMData()
' @Test
sub TC_adb_isValidMediaXDMData_invalid()
    UTF_assertFalse(_adb_isValidMediaXDMData({
        "xdm_invalid": {
            "eventType": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 0,
            }
        }
    }))

    UTF_assertFalse(_adb_isValidMediaXDMData({
        "xdm": {
            "eventType": "media.invalid",
            "mediaCollection": {
                "playhead": 0,
            }
        }
    }))

    UTF_assertFalse(_adb_isValidMediaXDMData({
        "xdm": {
            "invalid": "media.sessionEnd",
            "mediaCollection": {
                "playhead": 0,
            }
        }
    }))

    UTF_assertFalse(_adb_isValidMediaXDMData(invalid))
end sub
