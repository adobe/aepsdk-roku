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
    m.port = createObject("roMessagePort")
    m.top.observeField("requestEvent", m.port)
    m.top.functionName = "eventLoop"
    ' m.top.control = "STOP"
    m.top.control = "INIT"
end sub

sub eventLoop()
    _adb_log_info("start the event loop")
    internalConstants = _adb_internal_constants()
    serviceProvider = _adb_serviceProvider()
    processor = _adb_EventProcessor(internalConstants, m.top, serviceProvider)
    localDataStoreService = serviceProvider.localDataStoreService
    stored_ecid = localDataStoreService.readValue("ecid")
    if stored_ecid <> invalid and stored_ecid <> ""
        ' processor.ecid = stored_ecid
        ' _adb_log_info("[eventLoop] - load ecid from registry: " + stored_ecid)
    end if

    while true
        msg = wait(250, m.port)
        if msg <> invalid
            msg_type = type(msg)
            if msg_type = "roSGNodeEvent"
                ' get the payload of the observed field -> [requestEvent]
                payload = msg.getData()
                ' check if payload is an Adobe Event
                if _adb_isAdobeEvent(payload)
                    processor.handleEvent(payload)
                else
                    print "not an AdobeEvent"
                    print payload
                end if
            end if
        end if
    end while
end sub

