' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************

sub init()
    m.sendEventButton = m.top.findNode("sendEventButton2")
    m.sendEventButton.ObserveField("buttonSelected", "onButtonSelected")

    _initSDK()
end sub

sub _initSDK()
    '------------------------------------
    ' Initalize Adobe Edge SDK
    '------------------------------------
    m.adobeTaskNode = m.top.getScene().findNode("adobeTaskNode")

    m.aepSdk = AdobeAEPSDKInit(m.adobeTaskNode)

end sub

sub onButtonSelected()
    data = {}
    data["xdm"] = {
        "eventType": "page.view",
        "_obumobile5": {
            "page" : {
                "name": "RokuSampleApp.BottomGroup.sendEventWithCallback"
            }
        },
        "identityMap": {
            "RIDA": [
                {
                "id": "SampleAdId",
                "authenticatedState": "ambiguous",
                "primary": false
                }
            ]
        }
    }

    data["data"] = {
        "key": "value"
    }

    adbSendEventCallback = sub(context, result)
        print("BottomGroup::sendEventCallback called with result: " + FormatJson(result.message))
    end sub

    m.aepSdk.sendEvent(data, adbSendEventCallback, m)
end sub
