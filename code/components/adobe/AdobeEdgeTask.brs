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
    _adb_logInfo("start the event loop")
    processor = _adb_EventProcessor(m.top)
    while true
        msg = wait(250, m.port)
        print _adb_timestampInMillis()
        ' kick off the queued requests
        processor.processQueuedRequests()

        if msg <> invalid
            msg_type = type(msg)
            if msg_type = "roSGNodeEvent"
                ' get the payload of the observed field -> [requestEvent]
                payload = msg.getData()
                processor.handleEvent(payload)
            end if
        end if
    end while
end sub

