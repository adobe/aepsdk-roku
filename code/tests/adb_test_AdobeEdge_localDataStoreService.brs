' ********************** Copyright 2023 Adobe. All rights reserved. **********************

' This file is licensed to you under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License. You may obtain a copy
' of the License at http://www.apache.org/licenses/LICENSE-2.0

' Unless required by applicable law or agreed to in writing, software distributed under
' the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' OF ANY KIND, either express or implied. See the License for the specific language
' governing permissions and limitations under the License.

' *****************************************************************************************


' @BeforeEach
sub AdobeEdgeTestSuite_localDataStoreService_BeforeEach()
    print "AdobeEdgeTestSuite_localDataStoreService_BeforeEach"
end sub

' @AfterAll
sub AdobeEdgeTestSuite_localDataStoreService_TearDown()
    print "AdobeEdgeTestSuite_loggingService_TearDown"
end sub

' target: writeValue()/readValue()/removeValue()
' @Test
sub TestCase_AdobeEdge_localDataStoreService_write()
    serviceProvider = _adb_serviceProvider()
    localDataStoreService = serviceProvider.localDataStoreService
    localDataStoreService.writeValue("testKey", "string-value")
    UTF_assertEqual(localDataStoreService.readValue("testKey"), "string-value")
    localDataStoreService.removeValue("testKey")
    UTF_assertInvalid(localDataStoreService.readValue("testKey"))
end sub

