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
    if GetGlobalAA()._adb_main_task_node = invalid
        sdkThread = CreateObject("roSGNode", "AEPSDKTask")
        sdkThread.id = "adobeTaskNode"
        GetGlobalAA()._adb_main_task_node = sdkThread
    end if
end function

function _adb_storeTaskNode(taskNode as object) as void
    if GetGlobalAA()._adb_main_task_node = invalid
        GetGlobalAA()._adb_main_task_node = taskNode
    end if
end function

function _adb_retrieveTaskNode() as object
    return GetGlobalAA()._adb_main_task_node
end function

function _adb_observeTaskNode(field as string, functionName as string) as void
    taskNode = _adb_retrieveTaskNode()
    if taskNode <> invalid then
        taskNode.ObserveField(field, functionName)
    end if
end function

function _adb_startTaskNode() as void
    GetGlobalAA()._adb_main_task_node.control = "RUN"
end function

function _adb_stopTaskNode() as void
    if GetGlobalAA()._adb_main_task_node <> invalid then
        GetGlobalAA()._adb_main_task_node.control = "DONE"
        GetGlobalAA()._adb_main_task_node = invalid
    end if
end function

function _adb_isAEPTaskNode(taskNode as object) as boolean
    try
        types = taskNode.getFieldTypes()
        if types.requestEvent = "associativearray" and types.responseEvent = "associativearray"
            return true
        end if
    catch ex
        _adb_logError("_adb_isAEPTaskNode() - " + ex.message)
    end try
    return false
end function
