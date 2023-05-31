' ********************** Copyright 2022 Adobe. All rights reserved. **********************

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
    m.top.control = "STOP"
end sub

sub eventLoop()
    internalConstants = _adb_internal_constants()
    serviceProvider = _adb_serviceProvider()
    processor = EventProcessor(internalConstants, m.top, serviceProvider)
    localDataStoreService = serviceProvider.localDataStoreService
    stored_ecid = localDataStoreService.readValue("ecid")
    if stored_ecid <> invalid and stored_ecid <> ""
        processor.ecid = stored_ecid
        _adb_log_info("[eventLoop] - load ecid from registry: " + stored_ecid)
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

function EventProcessor(internalConstants as object, task as object, serviceProvider as object) as object
    return {
        ADB_CONSTANTS: internalConstants,
        task: task,
        configuration: {},
        ecid: invalid,
        networkService: serviceProvider.networkService,

        handleEvent: function(event as dynamic) as void
            if event <> invalid
                _adb_log_info("[handleEvent] - handle event -> " + FormatJson(event))
                if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SEND_EDGE_EVENT
                    m._sendEvent(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_CONFIGURATION
                    m._setConfiguration(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_LOG_LEVEL
                    m._setLogLevel(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.SET_EXPERIENCE_CLOUD_ID
                    m._setECID(event)
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.GET_IDENTITIES
                    ' test ...
                    sleep(5000)
                    m.task[m.ADB_CONSTANTS.TASK.RESPONSE_EVENT] = event
                else if event.apiname = m.ADB_CONSTANTS.PUBLIC_API.UPDATE_IDENTITIES
                    ' test ...
                    sleep(5000)
                    m.task[m.ADB_CONSTANTS.TASK.RESPONSE_EVENT] = event
                end if
            else
                _adb_log_warning("[handleEvent] - event is invalid")
            end if
        end function,

        _setLogLevel: function(event as object) as void
            logLevel = event.data.level
            loggingService = _adb_serviceProvider().loggingService
            loggingService.setLogLevel(logLevel)
            _adb_log_info("[_setLogLevel] - set log level: " + FormatJson(logLevel))
        end function,

        _setConfiguration: function(event as object) as void
            _adb_log_info("[_setConfiguration] - set configuration")
            _adb_log_verbose("configuration before: " + FormatJson(m.configuration))
            m.configuration = event.data
            _adb_log_verbose("configuration after: " + FormatJson(m.configuration))
        end function,

        _setECID: function(event as object) as void
            _adb_log_info("[_setECID] - set ecid")
            ' print event.data.ecid
            m._saveECID(event.data.ecid)
        end function,

        _saveECID: function(ecid as string) as void
            _adb_log_info("[_saveECID] - save ecid")
            m.ecid = ecid
            localDataStoreService = _adb_serviceProvider().localDataStoreService
            localDataStoreService.writeValue("ecid", m.ecid)
            _adb_log_verbose("save ecid to registry: " + FormatJson(m.ecid))
        end function,

        _queryECID: function() as string
            _adb_log_info("[_queryECID] - query ECID from service side")
            url = m._buildEdgeRequestURL(m.configuration.edge.configId, "")
            jsonBody = {
                events: [
                    {
                        query: {
                            identity: { fetch: [
                                    "ECID"
                            ] }

                        }
                    }
                ]
            }
            response = m.networkService.syncPostRequest(url, jsonBody)
            responseJson = ParseJson(response.message)
            _adb_log_verbose("response json: " + response.message)
            return responseJson.handle[0].payload[0].id
        end function,

        _sendEvent: function(event as object) as void
            _adb_log_info("[_sendEvent] - set event")
            if m._isNotReadyToProcessEdgeEvent()
                _adb_log_warning("not ready to process edge event")
                return
            end if

            if m.ecid = invalid then
                ecid = m._queryECID()
                if ecid = invalid then
                    _adb_log_error("failed to fetch ecid from service side")
                    return
                else
                    _adb_log_verbose("save ecid to registry")
                    m._saveECID(ecid)
                end if
            end if
            _adb_log_verbose("find a valid ecid: " + m.ecid)
            edgeEventData = event.data
            ' print edgeEventData
            'queue event
            requestId = event.uuid
            url = m._buildEdgeRequestURL(m.configuration.edge.configId, requestId)
            _adb_log_verbose("url: " + url)
            jsonBody = {
                xdm: {
                    identityMap: {
                        ECID: [
                            {
                                id: invalid,
                                primary: true,
                                authenticatedState: "ambiguous"
                            }
                        ]
                    }
                },
                events: []
            }
            jsonBody.events[0] = event.data
            jsonBody.xdm.identityMap.ECID[0].id = m.ecid
            ' syncPostRequest: function(url as string, jsonObj as object, headers = [] as object) as object
            _adb_log_verbose("request JSON: " + FormatJson(jsonBody))
            response = m.networkService.syncPostRequest(url, jsonBody)
            _adb_log_verbose("response code : " + FormatJson(response.code))
            _adb_log_verbose("response message :" + response.message)
            ' print response.message
            ' handle repsone code and data ....
            m._sendResponseEvent({
                uuid: requestId,
                data: {
                    code: response.code,
                    message: response.message
                }
            })
        end function,
        ' ************************************************************
        '
        ' Build the URL to send the event to the Adobe Edge endpoint
        '
        ' @param configId The Adobe Edge configuration ID
        ' @param requestId The Adobe Edge request ID
        ' @return The URL to send the event to
        '
        ' ************************************************************
        _buildEdgeRequestURL: function(configId as string, requestId as string) as string
            if requestId.Len() < 1
                return "https://edge.adobedc.net/ee/v1/interact?configId=" + configId
            end if
            return "https://edge.adobedc.net/ee/v1/interact?configId=" + configId + "&requestId=" + requestId
        end function,

        ' ************************************************************
        '
        ' Check if the configuration is ready to process an edge event
        ' @return true if the configuration is ready to process an edge event
        '
        ' Exmaple:
        ' {
        '   edge: {
        '     configId: "1234567890",
        '   }
        ' }
        '
        ' ************************************************************
        _isNotReadyToProcessEdgeEvent: function() as boolean
            return m.configuration = invalid or m.configuration.edge = invalid or m.configuration.edge.configId = invalid or m.configuration.edge.configId.Len() < 1
        end function,
        _sendResponseEvent: function(event as object) as void
            _adb_log_info("[_sendResponseEvent] - send response event" + FormatJson(event))
            if m.task = invalid
                _adb_log_error("task instance is invalid, no task to send response event")
                return
            end if
            m.task[m.ADB_CONSTANTS.TASK.RESPONSE_EVENT] = event
        end function,
    }
end function



function _adb_isAdobeEvent(msgPayload as dynamic) as boolean
    if msgPayload <> invalid
        return msgPayload.DoesExist("uuid") and msgPayload.DoesExist("apiname")
    else
        return false
    end if
end function

function _adb_serviceProvider() as object
    if GetGlobalAA()._adb_serviceProvider_instance = invalid then
        instance = {
            loggingService: {
                ' (VERBOSE: 0, DEBUG: 1, INFO: 2, WARNING: 3, ERROR: 4)
                _logLevel: 0,

                setLogLevel: function(logLevel as integer) as void
                    m._logLevel = logLevel
                end function,

                warning: function(message as string) as void
                    if m._logLevel <= 3 then
                        print "[ADB-EDGE Warning] " + message
                    end if
                end function,

                error: function(message as string) as void
                    print "[ADB-EDGE Warning] " + message
                end function,

                debug: function(message as string) as void
                    if m._logLevel <= 1 then
                        print "[ADB-EDGE Debug] " + message
                    end if
                end function,

                info: function(message as string) as void
                    if m._logLevel <= 2 then
                        print "[ADB-EDGE Info] " + message
                    end if
                end function,

                verbose: function(message as string) as void
                    if m._logLevel <= 0 then
                        print "[ADB-EDGE Verbose] " + message
                    end if
                end function,
            },
            networkService: {
                ' **************************************************************
                '
                ' Sned POST request to the given URL with the given JSON object
                '
                ' @param url: the URL to send the request to
                ' @param jsonObj: the JSON object to send
                ' @param headers: the headers to send with the request
                ' @return the response object
                '
                ' **************************************************************
                syncPostRequest: function(url as string, jsonObj as object, headers = [] as object) as object
                    request = CreateObject("roUrlTransfer")
                    port = CreateObject("roMessagePort")
                    request.SetPort(port)
                    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
                    ' request.InitClientCertificates()
                    request.SetUrl(url)
                    request.AddHeader("Content-Type", "application/json")
                    request.AddHeader("accept", "application/json")
                    request.AddHeader("Accept-Language", "en-US")
                    for each header in headers
                        request.AddHeader(header.key, header.value)
                    end for
                    ' request.EnableEncodings(true)
                    if (request.AsyncPostFromString(FormatJson(jsonObj)))
                        while (true)
                            msg = wait(0, port)
                            if (type(msg) = "roUrlEvent")
                                code = msg.GetResponseCode()
                                repMessage = msg.getString()
                                return {
                                    code: code,
                                    message: repMessage
                                }
                            end if
                            if (msg = invalid)
                                request.AsyncCancel()
                                return invalid
                            end if
                        end while
                    end if
                    return invalid
                end function,
                ' **************************************************************
                '
                ' Sned POST request to the given URL with the given JSON object
                '
                ' @param url: the URL to send the request to
                ' @param jsonObj: the JSON object to send
                ' @param headers: the headers to send with the request
                ' @param port: the port to send the response to
                ' @return the response object
                '
                ' **************************************************************
                asyncPostRequest: function(url as string, jsonObj as object, port as object, headers = [] as object) as void
                    ' network response will be sent to the port
                end function,
            },
            localDataStoreService: {
                ''' private internal variables
                _registry: CreateObject("roRegistrySection", "adb_edge_mobile"),

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
        }
        GetGlobalAA()["_adb_serviceProvider_instance"] = instance
    end if

    return GetGlobalAA()._adb_serviceProvider_instance
end function

function _adb_log_error(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.error(message)
end function

function _adb_log_warning(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.warning(message)
end function

function _adb_log_info(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.info(message)
end function

function _adb_log_debug(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.debug(message)
end function

function _adb_log_verbose(message as string) as object
    log = _adb_serviceProvider().loggingService
    log.verbose(message)
end function


' return {

' dataStoreService: {
'     ''' private internal variables
'     _registry: CreateObject("roRegistrySection", "adbmobile"),

'     ''' public Functions
'     writeValue: function(key as string, value as dynamic) as dynamic
'         m._registry.Write(key, value)
'         m._registry.Flush()
'     end function,
'     readValue: function(key as string) as dynamic

'         '''bug in roku - Exists returns true even if no key. value in that case is an empty string
'         if m._registry.Exists(key) and m._registry.Read(key).Len() > 0
'             return m._registry.Read(key)
'         end if

'         return invalid
'     end function,

'     removeValue: function(key as string) as void
'         m._registry.Delete(key)
'         m._registry.Flush()
'     end function,

'     writeMap: function(mapName as string, map as dynamic) as dynamic
'         mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
'         '_adb_logger().debug("Persistence - writeMap() writing to map: adbmobileMap_" + mapName)

'         if map <> invalid and map.Count() > 0
'             For each key in map
'                 if map[key] <> invalid
'                     '_adb_logger().debug("Persistence - writeMap() writing " + key + ":" + map[key] + " to map: adbmobileMap_" + mapName)
'                     mapRegistry.Write(key, map[key])
'                     mapRegistry.Flush()
'                 end if
'             end for
'         end if
'     end function,

'     readMap: function(mapName as string) as dynamic
'         mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
'         keyList = mapRegistry.GetKeyList()
'         result = {}
'         if keyList <> invalid
'             '_adb_logger().debug("Persistence - readMap() reading from map: adbmobileMap_" + mapName + " with size:" + keyList.Count().toStr())
'             For each key in keyList
'                 result[key] = mapRegistry.Read(key)
'             end for
'         end if

'         return result
'     end function

'     readValueFromMap: function(mapName as string, key as string) as dynamic
'         mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
'         '_adb_logger().debug("Persistence - readValueFromMap() reading Value for key:" + key + " from map: adbmobileMap_" + mapName)
'         if mapRegistry.Exists(key) and mapRegistry.Read(key).Len() > 0
'             return mapRegistry.Read(key)
'         end if
'         '_adb_logger().debug("Persistence - readValueFromMap() did not get Value for key:" + key + " from map: adbmobileMap_" + mapName)
'         return invalid
'     end function,

'     removeValueFromMap: function(mapName as string, key as string) as void
'         mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
'         '_adb_logger().debug("Persistence - removeValueFromMap() removing key:" + key + " from map: adbmobileMap_" + mapName)
'         mapRegistry.Delete(key)
'         mapRegistry.Flush()
'     end function,

'     removeMap: function(mapName as string) as void
'         mapRegistry = CreateObject("roRegistrySection", "adbmobileMap_" + mapName)
'         '_adb_logger().debug("Persistence - removeMap() deleting map: adbmobileMap_" + mapName)
'         keyList = mapRegistry.GetKeyList()
'         For each key in keyList
'             m.removeValueFromMap(mapName, key)
'         end for
'     end function
' },
' deviceInfoService: {

' },
' appInfoService: {

' },
' }


function _adb_utils() as object
    return {

        ' uuid: function() as string
        '     return "uuid"
        ' end function,


        ' generateMD5: function(input as string) as string
        '     ba = CreateObject("roByteArray")
        '     ba.FromAsciiString(input)
        '     digest = CreateObject("roEVPDigest")
        '     digest.Setup("md5")
        '     digest.Update(ba)

        '     return digest.Final()
        ' end function,

        ' generateSHA256: function(input as string) as string
        '     ba = CreateObject("roByteArray")
        '     ba.FromAsciiString(input)
        '     digest = CreateObject("roEVPDigest")
        '     digest.Setup("sha256")
        '     digest.Update(ba)

        '     return digest.Final()
        ' end function,

        ' calculateTimeDiffInMillis: function(ts1 as string, ts2 as string) as integer
        '     result% = Mid(ts1, 5).ToInt() - Mid(ts2, 5).ToInt()
        '     return result%
        ' end function,

        ' decodeBase64String: function(encodedString as string) as object
        '     ba = CreateObject("roByteArray")
        '     ba.FromBase64String(encodedString)
        '     return ba.ToAsciiString()
        ' end function,

        ' timer: function() as object
        '     instance = {

        '         ''' public Functions
        '         start: function(interval as integer, name as string) as void
        '             if m._enabled = false
        '                 _adb_logger().debug("[Timer] Starting " + name + " timer with interval (" + interval.ToStr() + ")")
        '                 m._interval = interval
        '                 m._name = name
        '                 m._ts.Mark()
        '                 m._nextTick = m._interval
        '                 m._enabled = true
        '             else
        '                 _adb_logger().debug("[Timer] " + m._name + " timer already started.")
        '             end if
        '         end function,

        '         stop: function() as void
        '             if m._enabled = true
        '                 _adb_logger().debug("[Timer] Stoping " + m._name + " timer.")
        '                 m._enabled = false
        '                 m._nextTick = invalid
        '             else
        '                 _adb_logger().debug("[Timer] " + m._name + " timer already stopped.")
        '             end if
        '         end function,

        '         restartWithNewInterval: function(newInterval as integer) as void
        '             _adb_logger().debug("[Timer] Restarting " + m._name + " timer with interval (" + newInterval.ToStr() + ")")
        '             m._interval = newInterval
        '             m._ts.Mark()
        '             m._nextTick = m._interval
        '             m._enabled = true
        '         end function,

        '         reset: function() as void
        '             _adb_logger().debug("[Timer] Resetting " + m._name)
        '             m._ts.Mark()
        '             m._nextTick = m._interval
        '             m._enabled = true
        '         end function,

        '         ticked: function() as boolean
        '             ticked = false
        '             milliseconds = m._ts.TotalMilliseconds()

        '             if milliseconds >= m._nextTick
        '                 m._nextTick = milliseconds + m._interval
        '                 ticked = true
        '             end if

        '             return ticked
        '         end function,

        '         elapsedTime: function() as integer
        '             return m._ts.TotalMilliseconds()
        '         end function,

        '         enabled: function() as boolean
        '             return m._enabled
        '         end function,

        '         ''' initialize the private variables
        '         _init: function() as void
        '             m["_ts"] = CreateObject ("roTimespan")
        '             m["_interval"] = invalid
        '             m["_name"] = ""
        '             m["_enabled"] = false
        '             m["_nextTick"] = invalid
        '         end function
        '     }

        '     instance._init()

        '     return instance
        ' end function,
    }
end function
