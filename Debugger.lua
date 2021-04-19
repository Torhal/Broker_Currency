--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local AddOnFolderName, private = ...

--------------------------------------------------------------------------------
---- Debugger
--------------------------------------------------------------------------------
local TextDump = _G.LibStub("LibTextDump-1.0")

local DebuggerHeight = 800
local DebuggerWidth = 750

local debugger = TextDump:New(("%s Debug Output"):format(AddOnFolderName), DebuggerWidth, DebuggerHeight)

local function GetDebugger()
    return debugger
end

private.GetDebugger = GetDebugger

function private.Debug(...)
    local message = string.format(...)

    GetDebugger():AddLine(message, "%X")

    return message
end
