
sub init()
    m.sendEventButton = m.top.findNode("sendEventButton")
    m.bottomLayoutGroup = m.top.findNode("bottomLayoutGroup")

    m.sendEventButton.ObserveField("buttonSelected", "onButtonSelected")

    examplerect = m.top.boundingRect()
    centerx = (1280 - examplerect.width) / 2
    centery = (720 - examplerect.height) / 2
    m.top.translation = [centerx, centery]

    _initSDK()
end sub

sub _initSDK()
    '------------------------------------
    ' Initalize Adobe Edge SDK
    '------------------------------------
    m.adobeTaskNode = m.top.getScene().findNode("adobeTaskNode")

    m.aepSdk = AdobeAEPSDK(m.adobeTaskNode)

end sub

sub onButtonSelected()
    m.aepSdk.sendEvent({
        "eventType": "commerce.orderPlaced",
        "commerce": {
            "key3": "value3"
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
    }, sub(context, result)
        print "callback result: "
        print result
        print context
    end sub, m)
end sub

function onKeyEvent(key as string, press as boolean)

    handled = false
    if press
        if key = "down"
            print "======"
            if m.sendEventButton.hasFocus()
                m.bottomLayoutGroup.findNode("sendEventButton2").setFocus(true)
            else
                m.sendEventButton.setFocus(true)
            end if

            handled = true
        end if

    end if
    return handled
end function