' @BeforeAll
sub AdobeEdgeTestSuite_SetUp()
    print "AdobeEdgeTestSuite_SetUp"
end sub

' @AfterAll
sub AdobeEdgeTestSuite_TearDown()
    print "AdobeEdgeTestSuite_TearDown"
end sub

' @Test
sub TestCase_AdobeEdge_AdobeSDKConstants()
    cons = AdobeSDKConstants()
    UTF_assertEqual(cons.LOG_LEVEL.VERBOSE, 0)
    UTF_assertEqual(cons.LOG_LEVEL.DEBUG, 1)
    UTF_assertEqual(cons.LOG_LEVEL.INFO, 2)
    UTF_assertEqual(cons.LOG_LEVEL.WARNING, 3)
    UTF_assertEqual(cons.LOG_LEVEL.ERROR, 4)

    UTF_assertEqual(cons.CONFIGURATION.CONFIG_ID, "configId")
end sub