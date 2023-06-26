
' 1st function called when channel application starts.
sub Main(input as dynamic)
  print "################"
  print "Start of Channel"
  print "################"
  print input
  ' Add deep linking support here. Input is an associative array containing
  ' parameters that the client defines. Examples include "options, contentID, etc."
  ' See guide here: https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
  ' For example, if a user clicks on an ad for a movie that your app provides,
  ' you will have mapped that movie to a contentID and you can parse that ID
  ' out from the input parameter here.
  ' Call the service provider API to look up
  ' the content details, or right data from feed for id
  if input <> invalid
    print "Received Input -- write code here to check it!"
    print input
    if input.reason <> invalid
      if input.reason = "ad" then
        print "Channel launched from ad click"
        'do ad stuff here
      end if
    end if
    if input.contentID <> invalid
      m.contentID = input.contentID
      print "contentID is: " + input.contentID
      'launch/prep the content mapped to the contentID here
    end if
    if input.RunTests = "true" and type(TestRunner) = "Function" then
      _adb_run_tests()
    end if
  end if
  _adb_run_tests()
  showHeroScreen()
end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen()
  print "main.brs - [showHeroScreen]"
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  scene = screen.CreateScene("SimpleVideoScene")
  screen.show()
  ' vscode_rdb_on_device_component_entry

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
  end while
end sub

function _adb_run_tests() as void
  Runner = TestRunner()

  Runner.SetTestFilePrefix("adb_test_")

  Runner.SetFunctions(_adb_test_functions())

  Runner.Logger.SetVerbosity(3)
  Runner.Logger.SetEcho(false)
  Runner.Logger.SetJUnit(false)
  Runner.SetFailFast(true)

  Runner.Run()
end function

function _adb_test_functions() as dynamic
  return [
    ' adb_test_AdobeEdge.brs
    AdobeEdgeTestSuite_SetUp
    AdobeEdgeTestSuite_TearDown
    TestCase_AdobeEdge_AdobeSDKConstants
    TestCase_AdobeEdge_adb_sdk_version
    TestCase_AdobeEdge_adb_serviceProvider
    TestCase_AdobeEdge_adb_StateManager_init
    TestCase_AdobeEdge_adb_StateManager_configId
    TestCase_AdobeEdge_adb_StateManager_edgeDomain
    TestCase_AdobeEdge_adb_isEmptyOrInvalidString
    ' adb_test_AdobeEdge_AdobeSDKInit.brs
    AdobeEdgeTestSuite_AdobeSDKInit_SetUp
    AdobeEdgeTestSuite_AdobeSDKInit_TearDown
    TestCase_AdobeEdge_AdobeSDKInit_singleton
    TestCase_AdobeEdge_AdobeSDKInit_initialize_task_node
    ' adb_test_AdobeEdge_loggingService.brs
    AdobeEdgeTestSuite_loggingService_BeforeEach
    AdobeEdgeTestSuite_loggingService_TearDown
    TestCase_AdobeEdge_loggingService_logLevel
    TestCase_AdobeEdge_loggingService_logLevel_default
    TestCase_AdobeEdge_loggingService_utility_functions
    ' AdobeEdgeTestSuite_public_APIs.brs
    AdobeEdgeTestSuite_public_APIs_SetUp
    AdobeEdgeTestSuite_public_APIs_BeforeEach
    AdobeEdgeTestSuite_public_APIs_TearDown
    TestCase_AdobeEdge_public_APIs_getVersion
    TestCase_AdobeEdge_public_APIs_setLogLevel
    TestCase_AdobeEdge_public_APIs_setLogLevel_invalid
    TestCase_AdobeEdge_public_APIs_shutdown
    TestCase_AdobeEdge_public_APIs_updateConfiguration
    TestCase_AdobeEdge_public_APIs_updateConfiguration_invalid
    TestCase_AdobeEdge_public_APIs_sendEdgeEvent
    TestCase_AdobeEdge_public_APIs_sendEdgeEvent_invalid
    TestCase_AdobeEdge_public_APIs_sendEdgeEventWithCallback
    TestCase_AdobeEdge_public_APIs_sendEdgeEventWithNonXdmData
    TestCase_AdobeEdge_public_APIs_setExperienceCloudId
    TestCase_AdobeEdge_public_APIs_buildEvent
    ' adb_test_AdobeEdge_localDataStoreService.brs
    AdobeEdgeTestSuite_localDataStoreService_BeforeEach
    AdobeEdgeTestSuite_localDataStoreService_TearDown
    TestCase_AdobeEdge_localDataStoreService_write
    ' adb_test_AdobeEdge_EventProcessor.brs
    AdobeEdgeTestSuite_EventProcessor_BeforeEach
    AdobeEdgeTestSuite_EventProcessor_TearDown
    TestCase_AdobeEdge_EventProcessor_init
    TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel
    TestCase_AdobeEdge_EventProcessor_handleEvent_setLogLevel_invalid
    TestCase_AdobeEdge_EventProcessor_handleEvent_setConfiguration
    TestCase_AdobeEdge_EventProcessor_handleEvent_setECID
    TestCase_AdobeEdge_EventProcessor_handleEvent_queryECID
    TestCase_AdobeEdge_EventProcessor_handleEvent_sendEvent
    TestCase_AdobeEdge_EventProcessor_sendResponseEvent
    TestCase_AdobeEdge_EventProcessor_loadECID
    ' adb_test_AdobeEdge_Edge_utils.brs
    AdobeEdgeTestSuite_Edge_utils_SetUp
    AdobeEdgeTestSuite_Edge_utils_TearDown
    TestCase_AdobeEdge_adb_generate_implementation_details
    TestCase_AdobeEdge_adb_buildEdgeRequestURL
    ' adb_test_AdobeEdge_EdgeRequestWorker.brs
    AdobeEdgeTestSuite_EdgeRequestWorker_SetUp
    AdobeEdgeTestSuite_EdgeRequestWorker_BeforeEach
    AdobeEdgeTestSuite_EdgeRequestWorker_TearDown
    TestCase_AdobeEdge_adb_EdgeRequestWorker_init
    TestCase_AdobeEdge_adb_EdgeRequestWorker_init_invalid
    TestCase_AdobeEdge_adb_EdgeRequestWorker_isReadyToProcess
    TestCase_AdobeEdge_adb_EdgeRequestWorker_queue
    TestCase_AdobeEdge_adb_EdgeRequestWorker_queue_bad_input
  ]
end function