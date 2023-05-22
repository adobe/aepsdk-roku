sub init()
    m.port = createObject("roMessagePort")
    m.top.observeField("requestEvent", m.port)
    m.top.functionName = "eventLoop"
    m.top.control = "RUN"
end sub

sub eventLoop()
    serviceProvider = _adb_serviceProvider()
    utils = _adb_utils()
    eventProcessor = EventProcessor(m.top, serviceProvider)
    while true
        msg = wait(250, m.port)
        if msg <> invalid
            msg_type = type(msg)
            if msg_type = "roSGNodeEvent"
                ' get the payload of the observed field -> [requestEvent]
                payload = msg.getData()
                ' check if payload is an Adobe Event
                if isAdobeEvent(payload)
                    eventProcessor.handleEvent(payload)
                else
                    print "not an AdobeEvent"
                    print payload
                end if

            end if
        end if
    end while
end sub

function isAdobeEvent(msgPayload as dynamic) as boolean
    if msgPayload <> invalid
        return msgPayload.DoesExist("uuid") and msgPayload.DoesExist("apiname")
    else
        return false
    end if
end function

function EventProcessor(task as object, serviceProvider as object) as object
    return {
        ADB_CONSTANTS: AdobeSDKConstants(),
        task: task,
        configuration: {},
        ecid: invalid,
        handleEvent: function(event as dynamic) as void
            if event <> invalid
                print "handle event"
                print event
                if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT
                    m._setEvent(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_CONFIGURATION
                    m._setConfiguration(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID
                    m._setECID(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.GET_IDENTIFIERS
                    sleep(5000)
                    m.task[m.ADB_CONSTANTS.TASK.RESPONSE_EVENT] = event
                end if
            else
                print "event is invalid"
            end if
        end function,
        _setConfiguration: function(event as object) as void
            print "set configuration"
            m.configuration = event.data
            print m.configuration
        end function,
        _setECID: function(event as object) as void
            print "set ecid"
            m.ecid = event.data
            print m.ecid
            ' persist ecid in registry !!!!
        end function,
        _setEvent: function(event as object) as void
            print "set event"
            if m._isReadyToProcessEdgeEvent()
                edgeEvent = event.data
                print edgeEvent
            else
                print "not ready to process edge event"
                'queue event
            end if

        end function,
        _isReadyToProcessEdgeEvent: function() as boolean
            return m.configuration <> invalid and m.configuration.DoesExist("edge") and m.configuration.edge.DoesExist("orgId") and m.configuration.edge.orgId <> invalid and m.configuration.edge.orgId.Len() > 0
        end function,
    }
end function


function _adb_serviceProvider() as object
    return {
        networkService: {
            postRequest: function(url as string, postJson as object, headers = [] as object) as object
                request = CreateObject("roUrlTransfer")
                port = CreateObject("roMessagePort")
                request.SetPort(port)
                request.SetCertificatesFile("common:/certs/ca-bundle.crt")
                request.InitClientCertificates()
                request.SetUrl(url)
                request.AddHeader("Content-Type", "application/json")
                request.AddHeader("Accept-Encoding", "deflate/gzip")
                for each header in headers
                    request.AddHeader(header.key, header.value)
                end for
                request.EnableEncodings(true)
                request.AddHeader("X-Braze-Api-Key", Braze()._privateApi.config[BrazeConstants().BRAZE_CONFIG_FIELDS.API_KEY])
                if (request.AsyncPostFromString(FormatJson(postJson)))
                    while (true)
                        msg = wait(0, port)
                        if (type(msg) = "roUrlEvent")
                            code = msg.GetResponseCode()
                            return msg.getString()
                        end if
                        if (msg = invalid)
                            request.AsyncCancel()
                            return invalid
                        end if
                    end while
                end if
                return invalid
            end function,
        },
        dataStoreService: {
            ''' private internal variables
            _registry: CreateObject("roRegistrySection", "adbmobile"),

            ''' public Functions
            writeValue: function(key as string, value as dynamic) as dynamic
                m._registry.Write(key, value)
                m._registry.Flush()
            end function,
            readValue: function(key as string) as dynamic

                '''bug in roku - Exists returns true even if no key. value in that case is an empty string
                if m._registry.Exists(key) and m._registry.Read(key).Len() > 0
                    return m._registry.Read(key)
                end if

                return invalid
            end function,

            removeValue: function(key as string) as void
                m._registry.Delete(key)
                m._registry.Flush()
            end function,

            writeMap: function(mapName as string, map as dynamic) as dynamic
                mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                '_adb_logger().debug("Persistence - writeMap() writing to map: adbmobileMap_" + mapName)

                if map <> invalid and map.Count() > 0
                    For each key in map
                        if map[key] <> invalid
                            '_adb_logger().debug("Persistence - writeMap() writing " + key + ":" + map[key] + " to map: adbmobileMap_" + mapName)
                            mapRegistry.Write(key, map[key])
                            mapRegistry.Flush()
                        end if
                    end for
                end if
            end function,

            readMap: function(mapName as string) as dynamic
                mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                keyList = mapRegistry.GetKeyList()
                result = {}
                if keyList <> invalid
                    '_adb_logger().debug("Persistence - readMap() reading from map: adbmobileMap_" + mapName + " with size:" + keyList.Count().toStr())
                    For each key in keyList
                        result[key] = mapRegistry.Read(key)
                    end for
                end if

                return result
            end function

            readValueFromMap: function(mapName as string, key as string) as dynamic
                mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                '_adb_logger().debug("Persistence - readValueFromMap() reading Value for key:" + key + " from map: adbmobileMap_" + mapName)
                if mapRegistry.Exists(key) and mapRegistry.Read(key).Len() > 0
                    return mapRegistry.Read(key)
                end if
                '_adb_logger().debug("Persistence - readValueFromMap() did not get Value for key:" + key + " from map: adbmobileMap_" + mapName)
                return invalid
            end function,

            removeValueFromMap: function(mapName as string, key as string) as void
                mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                '_adb_logger().debug("Persistence - removeValueFromMap() removing key:" + key + " from map: adbmobileMap_" + mapName)
                mapRegistry.Delete(key)
                mapRegistry.Flush()
            end function,

            removeMap: function(mapName as string) as void
                mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
                '_adb_logger().debug("Persistence - removeMap() deleting map: adbmobileMap_" + mapName)
                keyList = mapRegistry.GetKeyList()
                For each key in keyList
                    m.removeValueFromMap(mapName, key)
                end for
            end function
        },
        deviceInfoService: {

        },
        appInfoService: {

        },
    }
end function

function _adb_utils() as object
    return {
        uuid: function() as string
            return "uuid"
        end function,
        getTimestampInMillis: function() as string
            dateTime = CreateObject("roDateTime")
            currMS = dateTime.GetMilliseconds()
            timeInSeconds = dateTime.AsSeconds()

            timeInMillis = timeInSeconds.ToStr()
            if currMS > 99
                timeInMillis = timeInMillis + currMS.ToStr()
            else if currMS > 9 and currMS < 100
                timeInMillis = timeInMillis + "0" + currMS.ToStr()
            else if currMS >= 0 and currMS < 10
                timeInMillis = timeInMillis + "00" + currMS.ToStr()
            end if

            return timeInMillis
        end function,

        generateMD5: function(input as string) as string
            ba = CreateObject("roByteArray")
            ba.FromAsciiString(input)
            digest = CreateObject("roEVPDigest")
            digest.Setup("md5")
            digest.Update(ba)

            return digest.Final()
        end function,

        generateSHA256: function(input as string) as string
            ba = CreateObject("roByteArray")
            ba.FromAsciiString(input)
            digest = CreateObject("roEVPDigest")
            digest.Setup("sha256")
            digest.Update(ba)

            return digest.Final()
        end function,

        generateSessionId: function() as string
            deviceInfo = CreateObject("roDeviceInfo")
            uuid = deviceInfo.GetRandomUUID()
            currTime = m.getTimestampInMillis()
            mid = _adb_visitor().marketingCloudID()

            if mid = invalid
                mid = ""
            end if

            hashedMidUuid = m.generateSHA256(mid + uuid)

            result$ = currTime + hashedMidUuid

            return result$
        end function,

        calculateTimeDiffInMillis: function(ts1 as string, ts2 as string) as integer
            result% = Mid(ts1, 5).ToInt() - Mid(ts2, 5).ToInt()
            return result%
        end function,

        decodeBase64String: function(encodedString as string) as object
            ba = CreateObject("roByteArray")
            ba.FromBase64String(encodedString)
            return ba.ToAsciiString()
        end function,

        timer: function() as object
            instance = {

                ''' public Functions
                start: function(interval as integer, name as string) as void
                    if m._enabled = false
                        _adb_logger().debug("[Timer] Starting " + name + " timer with interval (" + interval.ToStr() + ")")
                        m._interval = interval
                        m._name = name
                        m._ts.Mark()
                        m._nextTick = m._interval
                        m._enabled = true
                    else
                        _adb_logger().debug("[Timer] " + m._name + " timer already started.")
                    end if
                end function,

                stop: function() as void
                    if m._enabled = true
                        _adb_logger().debug("[Timer] Stoping " + m._name + " timer.")
                        m._enabled = false
                        m._nextTick = invalid
                    else
                        _adb_logger().debug("[Timer] " + m._name + " timer already stopped.")
                    end if
                end function,

                restartWithNewInterval: function(newInterval as integer) as void
                    _adb_logger().debug("[Timer] Restarting " + m._name + " timer with interval (" + newInterval.ToStr() + ")")
                    m._interval = newInterval
                    m._ts.Mark()
                    m._nextTick = m._interval
                    m._enabled = true
                end function,

                reset: function() as void
                    _adb_logger().debug("[Timer] Resetting " + m._name)
                    m._ts.Mark()
                    m._nextTick = m._interval
                    m._enabled = true
                end function,

                ticked: function() as boolean
                    ticked = false
                    milliseconds = m._ts.TotalMilliseconds()

                    if milliseconds >= m._nextTick
                        m._nextTick = milliseconds + m._interval
                        ticked = true
                    end if

                    return ticked
                end function,

                elapsedTime: function() as integer
                    return m._ts.TotalMilliseconds()
                end function,

                enabled: function() as boolean
                    return m._enabled
                end function,

                ''' initialize the private variables
                _init: function() as void
                    m["_ts"] = CreateObject ("roTimespan")
                    m["_interval"] = invalid
                    m["_name"] = ""
                    m["_enabled"] = false
                    m["_nextTick"] = invalid
                end function
            }

            instance._init()

            return instance
        end function,
    }
end function