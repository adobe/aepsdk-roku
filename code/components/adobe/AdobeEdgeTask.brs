sub init()
    m.port = createObject("roMessagePort")
    m.top.observeField("requestEvent", m.port)
    m.top.functionName = "eventLoop"
    m.top.control = "RUN"
end sub

sub eventLoop()
    eventProcessor = EventProcessor(m.top, serviceProvider)
    while true
        msg = wait(250, m.port)
        if msg <> invalid
            msg_type = type(msg)
            if msg_type = "roSGNodeEvent"
                eventProcessor.handleEvent(msg.getData())
            end if
        end if
    end while
end sub

function EventProcessor(task as object, serviceProvider as object) as object
    return {
    }
end function