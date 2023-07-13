' ********************** Copyright 2023 Adobe. All rights reserved. **********************
' *
' * This file is licensed to you under the Apache License, Version 2.0 (the "License");
' * you may not use this file except in compliance with the License. You may obtain a copy
' * of the License at http://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software distributed under
' * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
' * OF ANY KIND, either express or implied. See the License for the specific language
' * governing permissions and limitations under the License.
' *
' *****************************************************************************************

' *********************************** MODULE: Task Node ***********************************

function _adb_createTaskNode() as void
    GetGlobalAA()._adb_edge_task_node = invalid
    sdkThread = CreateObject("roSGNode", "AdobeEdgeTask")
    GetGlobalAA()._adb_edge_task_node = sdkThread
end function

function _adb_retrieveTaskNode() as object
    return GetGlobalAA()._adb_edge_task_node
end function

function _adb_observeTaskNode(field as string, functionName as string) as void
    taskNode = _adb_retrieveTaskNode()
    if taskNode <> invalid then
        taskNode.ObserveField(field, functionName)
    end if
end function

function _adb_startTaskNode() as void
    GetGlobalAA()._adb_edge_task_node.control = "RUN"
end function