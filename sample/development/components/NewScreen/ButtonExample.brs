
sub init()
    m.exampleButton1 = m.top.findNode("exampleButton1")
    m.exampleButton2 = m.top.findNode("exampleButton2")

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

' onKeyEvent will handle button presses it recognizes in this example.
' If the "up" or "down" buttons are pressed on the remote control, the
' focus will change to the other button that is not currently focused.
' If a different button was pressed on the remote control (except the
' home button), this onKeyEvent will not handle the button press and
' pass this information up the focus chain until something handles
' this button event.
function onKeyEvent(key as string, press as boolean)
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
    handled = false
    if press
        if key = "up" or key = "down"
            print "======"
            if m.exampleButton1.hasFocus()
                m.exampleButton2.setFocus(true)
            else
                m.exampleButton1.setFocus(true)
            end if

            handled = true
        end if
    end if

    return handled
end function