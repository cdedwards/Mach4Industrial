--Requires
if mc.mcInEditor() == 1 then
	local sp = require("./Modules/mcSysPaths")
	sp.SetupPaths(".")
end
mcCO = require("mcCoroutine")
mcFile = require("mcFile")
mcSF = {}

-- Start Base Class Create of a control
local Control = {}
function Control:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Slider Functions
local function Slider_GetMax(self, Name)
	local val = scr.GetProperty(Name, "Max Value")
	return tonumber(val)
end
local function Slider_GetMin(self, Name)
	local val = scr.GetProperty(Name, "Min Value")
	return tonumber(val)
end
local function Slider_SetValue(self, Name, Amount, CheckBounds)
	if not CheckBounds then
		local Max = Slider_GetMax(self, Name)
		if Max and Amount > Max then
			Amount = Max
		end
		local Min = Slider_GetMin(self, Name)
		if Min and Amount < Min then
			Amount = Min
		end		
	end
	scr.SetProperty(Name, "Value", tostring(Amount))
end
local function Slider_Increment(self, Name, Amount)
	Amount = Amount or 1
	local CurrentValue = scr.GetProperty(Name, "Value")
	local NewValue = CurrentValue + Amount
	local Max = Slider_GetMax(self, Name)
	if Max and CurrentValue + Amount > Max then
		NewValue = Max
	end
	Slider_SetValue(self, Name, NewValue, false)
	return 0
end
local function Slider_Decrement(self, Name, Amount)
	Amount = Amount or 1
	local CurrentValue = scr.GetProperty(Name, "Value")
	local NewValue = CurrentValue - Amount
	local Min = Slider_GetMin(self, Name)
	if Min and CurrentValue - Amount < Min then
		NewValue = Min
	end
	Slider_SetValue(self, Name, NewValue, false)
	return 0
end
mcSF.Slider = Control:New({
		SetValue = Slider_SetValue,
		GetMin = Slider_GetMin,
		GetMax = Slider_GetMax,
		Increment = Slider_Increment,
		Decrement = Slider_Decrement,
	})

local function InputWait(Input, waittime, mode)
	local inst = mc.mcGetInstance("InputWait")
	local outputnumber = mc.OSIG_OUTPUT0 + tonumber(input)
	local WaitMode = {
		[0] = mc.WAIT_MODE_LOW,
		[1] = mc.WAIT_MODE_HIGH,
	}
	if (type(Input) ~= "number"  or type(mode) ~= "number") then
		return false;
	else
		local SignalReturn = mc.mcSignalWait(inst, WaitMode[tonumber(mode)]) -- WAIT_MODE_HIGH
	end

end

local function SetOutput(number, state)
	local inst = mc.mcGetInstance("Outputs");
	local outputnumber = mc.OSIG_OUTPUT0 + tonumber(number)
	local hdl = mc.mcSignalGetHandle(inst, outputnumber);
	rc = mc.mcSignalSetState(hdl, state);
	if (rc ~= mc.MERROR_NOERROR) then
		mc.mcCntlMacroAlarm(inst, 500, "Error with Set Output function")
		return false; 
	end
	return true;
end

local function CheckInput(number, time)
	local inst = mc.mcGetInstance("Check Inputs")

end

mcSF.Functions = {}
mcSF.EventTypes = {}
--Add Entities and RegisteredEvents to Framework table to be accessed elsewhere
mcSF.Entities = {}
mcSF.RegisteredEvents = {}
mcSF.RegisteredNames = {}
local ScreenState = {}
ScreenState.CycleStartMode = "GCODE" --Set this on startup, this assumes the GCODE window is shown by default.

mcSF.CT = {
	NONE          = 0,
	SCREEN        = 1,
	PAGE          = 2,
	GROUP         = 3,
	NOTEBOOK      = 4,
	NOTEBOOK_PAGE = 5,
	BUTTON        = 6,
	DRO           = 7,
	LED           = 8,
	TOOLPATH      = 9,
	GCODE_LIST    = 10,
	BITMAP_BUTTON = 11,
	TOGGLE_BUTTON = 12,
	STATIC_TEXT   = 13,
	STATIC_BITMAP = 14,
	SLIDER        = 15,
	GAUGE         = 16,
	MDI           = 17,
	LINE          = 18,
	LUA_PANEL     = 19,
	TEXT_BOX      = 20,
	PLUGIN_PANEL  = 21,
	ANIMATION     = 22,
	TOOL_OFFSETS  = 23,
	WORK_OFFSETS  = 24,
	GCODE_EDITOR  = 25,
	ANGULAR_METER = 26,
	LINEAR_METER  = 27,
	VIDEO         = 28,
	TIMER         = 29,
	LIST          = 30,
}
----------------------------------------
-- ScreenFramework Helper functions
----------------------------------------

mcSF.init = function()
	--mc.mcCntlSetLastError(inst, "Error something")
end
function mcSF:RunCB(name, ...)
	if name == nil then
		return
	end
	local FunctionName = tostring(name) .. "_CB"
	if self.Functions[FunctionName] ~= nil and type(self.Functions[FunctionName]) == "function" then
		return self.Functions[FunctionName](...)
	end
end
function mcSF:Log(data) -- bLoggingEnabled and or bPrintingEnabled must be true
	if self.bLoggingEnabled ~= true and self.bPrintingEnabled ~= true then
		return
	end
	if type(data) ~= "string" then
		data = tostring(data)
	end
	if mcLog ~= nil and mcLog.Log ~= nil then
		mcLog.Log(debug.getinfo(2)) -- sends data for where log is called
	end
	if mcLog ~= nil and mcLog.Print ~= nil then
		mcLog.Print(data, false, debug.getinfo(2))
	elseif mc.mcInEditor() == 1 then
		print(data)
	else
		mc.mcCntlSetLastError(mc.mcGetInstance(), data)
	end
end
mcSF.ModuleLoadOptions = {}
mcSF.ModuleLoadOptions.Mill4 = {
	"mcEngrave"	
}
mcSF.LoadedModules = {}
mcSF.LoadBaseModules = function(LoadType)
	local inst = mc.mcGetInstance()
	local LoadTypeTbl = {} 
	if type("LoadType") == "table" then
		LoadTypeTbl = LoadType
	elseif type("LoadType") == "string" then
		table.insert(LoadTypeTbl, LoadType)
	else
		return -1, "Invalid Module Type. Format is either {\"ModuleType\", \"OtherModuleType\"} or \"ModuleType\""
	end
	local rc
	for i, Name in pairs(LoadTypeTbl) do 
		if type(Name) == "string" then
			local rc
			if mcSF.ModuleLoadOptions[Name] ~= nil then
				for index, ModuleName in pairs(mcSF.ModuleLoadOptions[Name]) do 
					mcSF.LoadedModules[ModuleName], rc = mcPR.prequire(ModuleName)
					if rc ~= nil then
						mcSF.Log(string.format("Module %s Failed to Load Error: %s", ModuleName, tostring(rc)))
					end
				end
			else
				mcSF.Log( "Could not find module load option that matches \"" .. Name .. "\"")
			end
		else
			mcSF:Log("Invalid Module in Load Base Modules Table. Must be a string")
		end
	end
end
----------------------------------------
-- Start of Coroutine Helper Functions
----------------------------------------
mcSF.Coroutines = {}
function mcSF.CreateCoTimer(self)
	self.CoTimerPanel = wx.wxPanel (wx.NULL, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize( 0,0 ) )
	self.CoTimer = wx.wxTimer(self.CoTimerPanel)
	self.CoTimerPanel:Connect(wx.wxEVT_TIMER,
		function (event)
			local alive = false
			for id, tbl in pairs(self.Coroutines) do
				tbl.CheckCoroutine()
				if tbl.Coroutine ~= nil then
					alive = true
				else
					--mc.mcCntlSetLastError(0, "Coroutine Nil")
					self.Coroutines[id] = nil
				end
			end
			if not alive then
				--mc.mcCntlSetLastError(0, "CoTimer Stop")
				self.CoTimer:Stop()
			end
		end)
	self.CoTimer:Start(50, wx.wxTIMER_CONTINUOUS)
end
function mcSF:ContinueCoroutine(EventID)
	--mc.mcCntlSetLastError(0, "Continue Coroutine")
	self.Coroutines[EventID].ContinueCoroutine = true
end
function mcSF.CreateCoroutine(self, CoroutineFunction, CheckFunction, CheckFrequency)
	local EventID = GetEventID() -- Unique ID for coroutine
	self.Coroutines[EventID] = {}
	mcCO.AddCoroutineToTable(self.Coroutines[EventID])
	self.Coroutines[EventID].CoroutineFunction = CoroutineFunction
	self.Coroutines[EventID].CheckCoroutine(EventID)
	self:CreateCoTimer()
	self:CreateTimer(CheckFunction, EventID, CheckFrequency)
end
function mcSF.CreateTimer(self, func, id, speed)
	TimerPanel = wx.wxPanel (wx.NULL, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize( 0,0 ) )
	timer = wx.wxTimer(TimerPanel)
	TimerPanel:Connect(wx.wxEVT_TIMER,
		function (event)
			local bIsDone = func(id)
			if bIsDone then
				timer:Stop()
			end
		end)
	timer:Start(speed, wx.wxTIMER_CONTINUOUS)
end
----------------------------------------
-- End of Coroutine Helper Functions
----------------------------------------
local LastID = -1
function GetEventID()
	LastID = LastID + 1
	return LastID
end
-- Base function to be called by for registering an entities name
-- ControlType is the screen props full name. With the start of each work capitalized and no spaces
-- Ex. Button, BitmapButton or ToggleButton
local RegisterName = function(self, ControlType, Name)
	if Name == nil or type(Name) ~= "string" then
		-- Invalid data is sent. How do we want to notify people?
		return false
	end
	if self.Entities[ControlType] == nil then
		self.Entities[ControlType] = {}
		self.RegisteredNames[ControlType] = {}
	end
	if self.RegisteredNames[ControlType][Name] == nil then -- Make sure we only have one of each name per entity name
		table.insert(self.Entities[ControlType], Name)
		self.RegisteredNames[ControlType][Name] = true
	end
	return true
end
-- Base function to add a entity event to table
-- Name is assumed to be right because it should have already been checked when getting added
-- EventType dosen't have to be valid
-- If EventType is valid, Function MUST be as well
-- Only return value that means an error occured is false
-- true means added to table and nil means no even was supposed to be added
local RegisterEvent = function(self, ControlType, Name, EventType, Function)
	if EventType == nil or type(EventType) ~= "string" then
		-- This is ok, not all entities need to be mapped with functions
		return
	end
	if Function == nil or type(Function) ~= "function" then
		-- Invalid data is sent. If EventType is valid we NEED a function to map that event to. 
		--How do we want to notify people?
		return false
	end
	-- Make sure the overall table is present
	if self.RegisteredEvents[ControlType] == nil then
		self.RegisteredEvents[ControlType] = {}
	end
	-- Make sure the table for this screen object is present
	if self.RegisteredEvents[ControlType][Name] == nil then
		self.RegisteredEvents[ControlType][Name] = {}
	end
	self.RegisteredEvents[ControlType][Name][EventType] = Function
	return true
end
-- Base Function that all Register"ControlType" functions call
-- ControlType is hardcoded in each calling function but the rest are passed down in the order they come from the screen in
mcSF.Register = function(self, ControlType, Name, EventType, Function)
	local bIsValid = RegisterName(self, ControlType, Name)
	if bIsValid == false then
		return -1
	end
	bIsValid = RegisterEvent(self, ControlType, Name, EventType, Function)
	if bIsValid == false then
		return -2
	end
	return 0
end
mcSF.EventRun = function(self, ScreenProperties, ...)
	if ScreenProperties == nil or type(ScreenProperties) ~= "table" then
		return -3 -- Screen properties didn't make it here
	end
	local Name, EventType, ControlType = ScreenProperties[1], ScreenProperties[2], ScreenProperties[3] -- Screen Properties must come through as a table to make sure none of values get dropped
	if self.RegisteredEvents[ControlType] == nil then
		-- Unregistered entity
		return -1
	end
	if self.RegisteredEvents[ControlType][Name] == nil then
		-- Entity registered but no function assigned
		return -2
	end
	local Entity = self.RegisteredEvents[ControlType][Name]
	if Entity ~= nil then
		local Function = Entity[EventType]
		if Function ~= nil then
			Function(self, ...)
		else
			--Function Invalid - This should never happen
		end
	end
end
mcSF.SigLib = 
{
}
mcSF.MsgLib = 
{
}
mcSF.EventTypes.LeftDown = "Left Down Script"
mcSF.EventTypes.LeftUp = "Left Up Script"
mcSF.EventTypes.Clicked = "Clicked Script"
mcSF.EventTypes.OnEnterScript = "On Enter Script"
local inst = mc.mcGetInstance()
function __FUNC__() return debug.getinfo(2, 'n').name end
-------------------------------------------------------
--  PLC Function
-------------------------------------------------------
mcSF.PLC_pageId = 0
mcSF.PLC_screenId = 0
mcSF.PLC_testcount = 0
mcSF.PLC_machState = 0
mcSF.PLC_machStateOld = -1
mcSF.PLC_machEnabled = 0
mcSF.PLC_machWasEnabled = 0
-------------------------------------------------------
--  Tool Info GROUP FUNCTIONS
-------------------------------------------------------
--Group Name: MainTabs_grpTool
function mcSF.Functions.Touch()
	--Touch Button script
	if (Tframe == nil) then
		--TouchOff module
		package.loaded.mcTouchOff = nil
		mcTouchOff = require "mcTouchOff"
		Tframe = mcTouchOff.Dialog()
	else
		Tframe:Show()
		Tframe:Raise()
	end
end
function mcSF.Functions.Lathe()
	--local screen = "wxLathe_SF";
	local screen = "wxLathe_SF";

	local port = "127.0.0.1";
	local inst = mc.mcGetInstance();
	local path, rc = mc.mcCntlGetMachDir(inst);
	local exepath = path .. "\\Mach4GUIR.exe";
	if(wx.wxFileExists(exepath))then
		exepath = exepath ..  " /s" .. screen .." /r" .. port
		local screenpath = path .. string.format("\\Screens\\%s.set", screen)
		if(wx.wxFileExists(screenpath))then 
			exepath = 'START "Probing" ' .. exepath

			local rval = os.execute(exepath);
			mc.mcCntlSetLastError(inst, tostring(rval));
		else 
			mc.mcCntlSetLastError(inst, screen .. ".set Not Found" );
		end
	else
		mc.mcCntlSetLastError(inst, "Mach4GUIR.exe Not Found" );
	end
end
--[[
tbl = 
{
	["droRunOps_CurrentGcodeFile"] = {
		Type = "string",
		DefaultValue = "Not Found",
		SkipDefault = false,
		ScreenPropName = "Value"
	}
}
--]]
function mcSF.Functions.AddPersistentScreenProps(tbl)
	local SkipDefault
	for name, Info in pairs (tbl) do -- for each paired name (key) and number (value) in the DRO table
		if type(name) == "string" then
			SkipDefault = true
			if type(Info) ~= "table" then
				Info = {}
			end

			-- Make sure we have a type.
			-- If no type is sent try to make a guess based on the default value (if it's sent)
			if Info.Type ~= "string" and Info.Type ~= "int" and Info.Type ~= "double" then
				-- Log this maybe
				if type(Info.DefaultValue) == "number" then
					Info.Type = "double"
				else
					Info.Type = "string"
				end
			end

			-- Decide on a default value based on type becuase we were not sent one
			if Info.DefaultValue == nil then
				if Info.Type == "string" then
					Info.DefaultValue = "NotFound"
				else
					Info.DefaultValue = 0
				end
			end

			-- Make sure we have a valid scren property name
			if type(Info.ScreenPropName) ~= "string" then
				Info.ScreenPropName = "Value"
			end

			-- Allow caller to 
			if Info.SkipDefault == false then
				SkipDefault = false
			end
			local droName = name -- make the variable named droName equal the name from the table above
			local val = mcFile.IniGet("PersistentDROs", droName, Info.DefaultValue, Info.Type)  -- Get the Value from the profile ini
			if (val ~= Info.DefaultValue) or SkipDefault == false then -- If the value is not equal to NotFound
				scr.SetProperty((droName), "Value", val) -- Set the dros value to the value from the profile ini
			end -- End the If statement
		end
	end -- End the For loop
end
function mcSF.Functions.Probing()
	local screen = "wxProbe";
	local port = "127.0.0.1";
	local inst = mc.mcGetInstance();
	local path, rc = mc.mcCntlGetMachDir(inst);
	local exepath = path .. "\\Mach4GUIR.exe";
	if(wx.wxFileExists(exepath))then
		exepath = exepath ..  " /s" .. screen .." /r" .. port
		local screenpath = path .. string.format("\\Screens\\%s.set", screen)
		if(wx.wxFileExists(screenpath))then 
			exepath = 'START "Probing" ' .. exepath

			local rval = os.execute(exepath);
			mc.mcCntlSetLastError(inst, tostring(rval));
		else 
			mc.mcCntlSetLastError(inst, screen .. ".set Not Found" );
		end
	else
		mc.mcCntlSetLastError(inst, "Mach4GUIR.exe Not Found" );
	end
end
function mcSF.Functions.CSS()
	local nativeUnits, rc = mc.mcCntlGetUnitsDefault(inst)
	local units, rc = mc.mcCntlGetUnitsCurrent(inst)
	local xDia = mc.mcAxisGetPos(inst, 0)
	local dia, rc = mc.mcCntlGetDiaMode(inst)

	if (dia == 0) then
		xDia = (xDia * 2)
	end

	if (nativeUnits == 200) and (units == 210) then
		xDia = (xDia * 25.4)
	elseif (nativeUnits == 210) and (units == 200) then
		xDia = (xDia / 25.4)
	end

	if (units == 200) then --Gcode is in inch mode (G20)
		mc.mcSpindleCalcCSSToRPM(inst, xDia, true)
	elseif (units == 210) then --Gcode is in mm mode (G21)
		mc.mcSpindleCalcCSSToRPM(inst, xDia, false)
	end

	-------------------------------------------------------
	--  Set CSS Register
	-------------------------------------------------------
	local cssRegTbl = {--Table format: {"name", "description", initialval, persistent, value}
		--Unit dependent We will adjust these depending on Machine units and Gcode units (G20/21)
		--{"Bogus", "Description.", 5.0, 1, 0},
		{"CSS", "Current constant surface speed.", 0, 0, 0}
	}

	rc = mm.doRegTable(inst, "ADD", cssRegTbl, "iRegs0", "") --Instacne, Mode (DEL or ADD), Table, Device, Group This will create or delete all the registers in thcRegTbl if they don't exist in the profile
	if (rc ~= 0) then
		msg = mc.mcCntlGetErrorString(inst, rc) --Get the returned error string
		mc.mcCntlSetLastError(inst, msg)
	end

	local rc, hRegCSS, vX, vZ, blendedVelocity, spinRPM, currentCSS, lastCSS
	hRegCSS = mc.mcRegGetHandle(inst, "iRegs0/CSS")
	lastCSS = mc.mcRegGetValue(hRegCSS)
	vX, rc = mc.mcAxisGetVel(inst, mc.X_AXIS)
	vX = tonumber(vX)
	vZ, rc = mc.mcAxisGetVel(inst, mc.Z_AXIS)
	vZ = tonumber(vZ)
	blendedVelocity = math.sqrt((vX * vX) + (vZ * vZ))
	spinRPM, rc = mc.mcSpindleGetTrueRPM(inst)
	spinRPM = tonumber(spinRPM)

	if ((blendedVelocity > 0) and (spinRPM > 0)) then
		currentCSS = (blendedVelocity / spinRPM)
	else
		currentCSS = 0
	end

	if (currentCSS ~= lastCSS) then --We need to update our register
		mc.mcRegSetValue(hRegCSS, currentCSS)
	end
end
function mcSF.Functions.RememberPosition()
	local pos = mc.mcAxisGetMachinePos(inst, 0) -- Get current X (0) Machine Coordinates
	mc.mcProfileWriteString(inst, "RememberPos", "X", string.format (pos)) --Create a register and write the machine coordinates to it
	pos = mc.mcAxisGetMachinePos(inst, 1) -- Get current Y (1) Machine Coordinates
	mc.mcProfileWriteString(inst, "RememberPos", "Y", string.format (pos)) --Create a register and write the machine coordinates to it
	pos = mc.mcAxisGetMachinePos(inst, 2) -- Get current Z (2) Machine Coordinates
	mc.mcProfileWriteString(inst, "RememberPos", "Z", string.format (pos)) --Create a register and write the machine coordinates to it
end
function mcSF.Functions.ReturnToPosition()
	local xval = mc.mcProfileGetString(inst, "RememberPos", "X", "NotFound") -- Get the register Value
	local yval = mc.mcProfileGetString(inst, "RememberPos", "Y", "NotFound") -- Get the register Value
	local zval = mc.mcProfileGetString(inst, "RememberPos", "Z", "NotFound") -- Get the register Value

	if(xval == "NotFound")then -- check to see if the register is found
		wx.wxMessageBox('Register xval does not exist.\nYou must remember a postion before you can return to it.'); -- If the register does not exist tell us in a message box
	elseif (yval == "NotFound")then -- check to see if the register is found
		wx.wxMessageBox('Register yval does not exist.\nYou must remember a postion before you can return to it.'); -- If the register does not exist tell us in a message box
	elseif (zval == "NotFound")then -- check to see if the register is found
		wx.wxMessageBox('Register zval does not exist.\nYou must remember a postion before you can return to it.'); -- If the register does not exist tell us in a message box
	else
		mc.mcCntlMdiExecute(inst, "G00 G53 Z0.0000 \n G00 G53 X" .. xval .. "\n G00 G53 Y" .. yval .. "\n G00 G53 Z" .. zval)
	end
end
-------------------------------------------------------
--   Tool Info GROUP FUNCTIONS END 
-------------------------------------------------------

-------------------------------------------------------
--  File Ops TAB FUNCTIONS
-------------------------------------------------------
mcSF.Functions.OpenDocs = function()
	local major, minor = wx.wxGetOsVersion()
	local dir = mc.mcCntlGetMachDir(inst);
	local cmd = "explorer.exe /open," .. dir .. "\\Docs\\"
	if(minor <= 5) then -- Xp we don't need the /open
		cmd = "explorer.exe ," .. dir .. "\\Docs\\"
	end
	os.execute(cmd) -- another way to execute a program.
	--wx.wxExecute(cmd);
	scr.RefreshScreen(250); -- Windows 7 and 8 seem to require the screen to be refreshed.  
end
-------------------------------------------------------
--  File Ops TAB FUNCTIONS END
-------------------------------------------------------
-------------------------------------------------------
--  Tool Path Ops TAB FUNCTIONS
-------------------------------------------------------
local ToolPathViewCodes = 
{
	TOP = 0,
	BOTTOM = 1,
	LEFT = 2,
	RIGHT = 3,
	ISO = 4
}
function mcSF.Functions.ToolPathSetView(self, View)
	--VIEWS: 0 = top, 1 = bottom, 2 = Left, 3 = right 4 = iso
	local ViewCode = ToolPathViewCodes[string.upper(View)] 
	if ViewCode == nil then
		-- Error 
		return
	end
	local inst = mc.mcGetInstance();
	local ToolPaths = self.Entities[mcSF.CT.TOOLPATH]
	if ToolPaths ~= nil and #ToolPaths > 0 then
		for i, name in pairs(ToolPaths) do --This loop needs to 
			--mc.mcCntlSetLastError(inst, tostring(name))
			local rc = scr.SetProperty(tostring(name), "View", tostring(ViewCode))
		end
	end
end
function mcSF.Functions.LeftLook(self)
	-- Left
	local inst = mc.mcGetInstance();
	local rc = scr.SetProperty("toolpath1", "View", "2")
	local rc = scr.SetProperty("toolpath2", "View", "2")
	local rc = scr.SetProperty("toolpath3", "View", "2")
	local rc = scr.SetProperty("toolpath4", "View", "2")
	local rc = scr.SetProperty("toolpath5", "View", "2")
end
-------------------------------------------------------
--  Tool Path Ops TAB FUNCTIONSEND
-------------------------------------------------------
function mcSF.Functions.DerefAll(self)
	local inst = mc.mcGetInstance();
	mc.mcAxisDerefAll(inst);
end

function mcSF.Functions.Reset(self)
	local inst = mc.mcGetInstance()
	mc.mcCntlReset(inst)
	mc.mcSpindleSetDirection(inst, 0)
	mc.mcCntlSetLastError(inst, '')
end
mcSF.Functions.KeyboardInputsToggle = function(self)
---------------------------------------------------------------
-- Keyboard Inputs Toggle() function. Updated 5-16-16
--------------------------------------------------------------- 
	-- Check if require screen entities exist
	--if Entities.btnKeyboardJog == nil then -- Might be more than one of these buttons?
	--return
	--end
	local iReg = mc.mcIoGetHandle (inst, "Keyboard/Enable")
	local iReg2 = mc.mcIoGetHandle (inst, "Keyboard/EnableKeyboardJog")

	if (iReg ~= nil and iReg ~= 0) and (iReg2 ~= nil and iReg2 ~= 0) then
		local val = mc.mcIoGetState(iReg);
		local NewVal
		if (val == 1) then
			NewVal = 0
		else
			NewVal = 1
		end
		if self:RunCB("KeyboardInputsToggle", NewVal) == false then
			return
		end
		mc.mcIoSetState(iReg, NewVal);
		mc.mcIoSetState(iReg2, NewVal);
	end
end
mcSF.Functions.SpinCW = function(self)
	local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_SPINDLEON);
	local sigState = mc.mcSignalGetState(sigh);

	if (sigState == 1) then 
		mc.mcSpindleSetDirection(inst, 0);
	else 
		mc.mcSpindleSetDirection(inst, 1);
	end
end
mcSF.Functions.SpinCCW = function(self)
	local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_SPINDLEON);
	local sigState = mc.mcSignalGetState(sigh);
	if (sigState == 1) then 
		mc.mcSpindleSetDirection(inst, 0);
	else 
		mc.mcSpindleSetDirection(inst, -1);
	end
end
mcSF.Functions.CycleStop = function(self)
	mc.mcCntlCycleStop(inst);
	mc.mcSpindleSetDirection(inst, 0);
	mc.mcCntlSetLastError(inst, "Cycle Stopped");
	if(wait ~= nil) then
		wait = nil;
	end
end
mcSF.Functions.ButtonJogModeToggle = function(self)
	local cont = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_CONT);
	local jogcont = mc.mcSignalGetState(cont)
	local inc = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_INC);
	local joginc = mc.mcSignalGetState(inc)
	local mpg = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_MPG);
	local jogmpg = mc.mcSignalGetState(mpg)	
	if (jogcont == 1) then
		if self:RunCB("ButtonJogModeToggle", "INC") == false then
			return
		end
		mc.mcSignalSetState(cont, 0)
		mc.mcSignalSetState(inc, 1)
		mc.mcSignalSetState(mpg, 0)        
	else
		if self:RunCB("ButtonJogModeToggle", "CON") == false then
			return
		end
		mc.mcSignalSetState(cont, 1)
		mc.mcSignalSetState(inc, 0)
		mc.mcSignalSetState(mpg, 0)
	end
end
mcSF.Functions.RefAllHome = function(self)
	--require("mobdebug").start()
	local function refallhome(self)
		--require("mobdebug").coro()
		mc.mcAxisDerefAll(inst)  --Just to turn off all ref leds
		mc.mcAxisHomeAll(inst)
		coroutine.yield() --yield coroutine so we can do the following after motion stops
		----See ref all home button and plc script for coroutine.create and coroutine.resume
		wx.wxMessageBox('Referencing is complete')
		self:RunCB("RefAllHome")
	end
	local function CheckState(EventID)
		if mc.mcCntlGetState(inst) == 0 then
			mcSF:ContinueCoroutine(EventID) -- We want the coroutine for this id to continue
			return true -- done
		end
	end
	mcSF:CreateCoroutine(refallhome, CheckState, 50)
end
mcSF.PlateAlign = {}
mcSF.PlateAlign.CurrentPosIndex = 1
mcSF.PlateAlign.On = false
mcSF.Functions.RecordAlignPosition = function(self)
	local num = self.PlateAlign.CurrentPosIndex
	--------------------------------------------------------
	--Align Point
	--------------------------------------------------------
	local X  = mc.mcAxisGetMachinePos(inst, mc.X_AXIS) -- Get current X (0) Machine Coordinates
	mc.mcProfileWriteString(inst, "PlateAlign",string.format("X%.0f", num), tostring(X)) --Create a register and write the machine coordinates to it 

	local Y  = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS) -- Get current Y (1) Machine Coordinates
	mc.mcProfileWriteString(inst, "PlateAlign", string.format("Y%.0f", num), tostring(Y)) --Create a register and write the machine coordinates to it

	local msg = string.format("Plate position #1 has been recorded: X%.3f, Y%.3f", X, Y)
	if (num == 2) then
		msg = string.format("Plate position #2 has been recorded: X%.3f, Y%.3f", X, Y)
	end
	mc.mcCntlSetLastError(inst, msg)
	self.PlateAlign.CurrentPosIndex = num + 1
	if self.PlateAlign.CurrentPosIndex > 2 then
		self.PlateAlign.CurrentPosIndex = 1
	end
	if self:RunCB("RecordAlignPosition", self.PlateAlign.CurrentPosIndex) == false then
		return
	end
end

mcSF.Functions.PlateAlign = function(self)
	if mcSF.PlateAlign.CurrentPosIndex == 2 then
		self:RunCB("PlateAlign", "Cancel")
		return
	end
	if mcSF.PlateAlign.On == true then
		local inst = mc.mcGetInstance()
		if self:RunCB("PlateAlign", "Off") == false then
			return
		end
		mc.mcCntlMdiExecute(inst, "G69")
		mc.mcCntlSetLastError(inst, 'Plate Alignment has been canceled.')
		mcSF.PlateAlign.On = false
		return
	end
	local EnabledHdl = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_ENABLED)
	local Enabled = mc.mcSignalGetState(EnabledHdl)
	if (Enabled ~= 1) then -- Machine must be enabled so we can't continue
		return
	end
	local X1 = mc.mcProfileGetString(inst, "platealign", "X1", "NotFound") -- Get the register Value
	local X2 = mc.mcProfileGetString(inst, "platealign", "X2", "NotFound") -- Get the register Value
	local Y1 = mc.mcProfileGetString(inst, "platealign", "Y1", "NotFound") -- Get the register Value
	local Y2 = mc.mcProfileGetString(inst, "platealign", "Y2", "NotFound") -- Get the register Value
	if (X1 == "NotFound") then
		mc.mcCntlSetLastError(inst, "X1 position not defined, plate align aborted")
	else
		X1 = tonumber(X1)
	end
	if (X2 == "NotFound") then
		mc.mcCntlSetLastError(inst, "X2 position not defined, plate align aborted")
	else
		X2 = tonumber(X2)
	end
	if (Y1 == "NotFound") then
		mc.mcCntlSetLastError(inst, "Y1 position not defined, plate align aborted")
	else
		Y1 = tonumber(Y1)
	end
	if (Y2 == "NotFound") then
		mc.mcCntlSetLastError(inst, "Y2 position not defined, plate align aborted")
	else
		Y2 = tonumber(Y2)
	end
	self:RunCB("PlateAlign", "On")
	--Subtract the start from the end point 
	local xDelta = X2 - X1
	local yDelta = Y2 - Y1

	local angle = math.atan2 (yDelta, xDelta)
	angle = angle * 180 / math.pi
	mcSF.PlateAlign.On = true
	rc = mc.mcCntlGcodeExecuteWait(inst, string.format ("G54 G68 R%.4f", angle))
	mc.mcCntlSetLastError(inst, string.format("Plate align set: Angle = %.1f", angle)); 
end
mcSF.Functions.GoToWorkZero = function()
	mc.mcCntlMdiExecute(inst, "G00 X0 Y0")--Without Z moves
	--mc.mcCntlMdiExecute(inst, "G00 G53 Z0\nG00 X0 Y0 A0\nG00 Z0")--With Z moves
end
function mcSF.Functions.SetCycleStartMode(self, mode)
	if self:RunCB("SetCycleStartMode", mode) == false then
		return
	end
	ScreenState.CycleStartMode = mode;
end
mcSF.Functions.CycleStart = function(self)
	local inst = mc.mcGetInstance("Cycle Start Func")
	local rc = true
	local state = mc.mcCntlGetState(inst)
	if (state == mc.MC_STATE_MRUN_MACROH) then 
		mc.mcCntlCycleStart(inst)
		return;
	end
	if self:RunCB("CycleStart", state) == false then
		return
	end

	if (ScreenState.CycleStartMode == "GCODE") then
		mc.mcCntlCycleStart(inst) 
		--mc.mcCntlSetLastError(inst, "Cycle Start Called")
	else
		--mc.mcCntlSetLastError(inst,"Sent to CB for Cycle Start *screen*	==" .. tostring(ScreenState.CycleStartMode))
		Functions.CycleStart_CB(ScreenState.CycleStartMode)
		--mc.mcCntlSetLastError(inst, "Cycle Start Else Called")
	end
end
mcSF.Functions.SecondsToTime = function(seconds)
	if seconds == 0 then
		return "00:00:00.00"
	else
		local hours = string.format("%02.f", math.floor(seconds/3600))
		local mins = string.format("%02.f", math.floor((seconds/60) - (hours*60)))
		local secs = string.format("%04.2f",(seconds - (hours*3600) - (mins*60)))
		return hours .. ":" .. mins .. ":" .. secs
	end
end
mcSF.Functions.GetFixOffsetVars = function()
	local FixOffset = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_14)
	local Pval = mc.mcCntlGetPoundVar(inst, mc.SV_BUFWZP)
	local FixNum, whole, frac
	local PoundVarX
	if (FixOffset ~= 54.1) then --G54 through G59
		whole, frac = math.modf (FixOffset)
		FixNum = (whole - 53) 
		PoundVarX = ((mc.SV_FIXTURES_START - mc.SV_FIXTURES_INC) + (FixNum * mc.SV_FIXTURES_INC))
		CurrentFixture = string.format('G' .. tostring(FixOffset)) 
	else --G54.1 P1 through G54.1 P100
		FixNum = (Pval + 6)
		CurrentFixture = string.format('G54.1 P' .. tostring(Pval))
		if (Pval > 0) and (Pval < 51) then -- G54.1 P1 through G54.1 P50
			PoundVarX = ((mc.SV_FIXTURE_EXPAND - mc.SV_FIXTURES_INC) + (Pval * mc.SV_FIXTURES_INC))
		elseif (Pval > 50) and (Pval < 101) then -- G54.1 P51 through G54.1 P100
			PoundVarX = ((mc.SV_FIXTURE_EXPAND2 - mc.SV_FIXTURES_INC) + (Pval * mc.SV_FIXTURES_INC))	
		end
	end
	return PoundVarX
end
mcSF.Functions.GetFixOffsetVarForAxis = function(TargetAxis)
	TargetAxis = tonumber(TargetAxis)
	if (TargetAxis == nil)then
		mc.mcCntlSetLastError(mc.mcGetInstance(), "GetFixOffsetVarForAxis: TargetAxis isn't a number")
		return nil -- We don't want to set random stuff 
	end
	local StartVar = mcSF.Functions.GetFixOffsetVars()
	local requestedVar = StartVar
	if (mc.X_AXIS == TargetAxis) then
		requestedVar = requestedVar -- Already right
	elseif (mc.Y_AXIS == TargetAxis) then
		requestedVar = requestedVar + 1
	elseif (mc.Z_AXIS == TargetAxis) then
		requestedVar = requestedVar + 2
	elseif (mc.A_AXIS == TargetAxis) then
		requestedVar = requestedVar + 3
	elseif (mc.B_AXIS == TargetAxis) then
		requestedVar = requestedVar + 4
	elseif (mc.C_AXIS == TargetAxis) then
		requestedVar = requestedVar + 5
	else
		mc.mcCntlSetLastError(mc.mcGetInstance(), "GetFixOffsetVarForAxis: Target Axis isn't a valid axis. Use mc.X_Axis, mc.Y_Axis, mc.Z_Axis, mc.A_Axis, mc.B_Axis, or mc.C_Axis")
	end
	return requestedVar
end
mcSF.Functions.MergeTables = function(...)
	local HighLander = {}
	local tbls = {...}
	for inputNum, InputValue in pairs(tbls) do
		if type(InputValue) ~= "table" then
			Log("Invalid Data Sent to Merge Tables, Arguments Must be Tables")
		else
			for index, value in pairs(InputValue) do
				HighLander[index] = value
			end
		end
	end
	return HighLander
end
return mcSF