-- A system paths file was found.
mcsp = require "./Modules/mcSysPaths"
mcsp.SetupPaths("C:/Mach4Industrial", "CNC_Router")

-- PMC generated module load code.
package.path = package.path .. ";./Pmc/?.lua"
package.path = package.path .. ";./Pmc/?.luac"


-- PMC generated module load code.
function Mach_Cycle_Pmc()
end

-- Screen load script (Global)
pageId = 0
screenId = 0
testcount = 0
machState = 0
machStateOld = -1
machEnabled = 0
machWasEnabled = 0
inst = mc.mcGetInstance()
mobdebug = require('mobdebug')
mobdebug.onexit = mobdebug.done
--mobdebug.start() -- This line is to start the debug Process Comment out for no debuging
Tframe = nil --TouchFrame handle

---------------------------------------------------------------
-- Signal Library
---------------------------------------------------------------
SigLib = {
[mc.OSIG_MACHINE_ENABLED] = function (state)
    machEnabled = state;
    ButtonEnable()
end,

[mc.ISIG_INPUT0] = function (state)
    
end,

[mc.ISIG_INPUT1] = function (state) -- this is an example for a condition in the signal table.
   -- if (state == 1) then   
--        CycleStart()
--    --else
--        --mc.mcCntlFeedHold (0)
--    end

end,

[mc.OSIG_JOG_CONT] = function (state)
    if( state == 1) then 
       scr.SetProperty('labJogMode', 'Label', 'Continuous');
       scr.SetProperty('txtJogInc', 'Bg Color', '#C0C0C0');--Light Grey
       scr.SetProperty('txtJogInc', 'Fg Color', '#808080');--Dark Grey
    end
end,

[mc.OSIG_JOG_INC] = function (state)
    if( state == 1) then
        scr.SetProperty('labJogMode', 'Label', 'Incremental');
        scr.SetProperty('txtJogInc', 'Bg Color', '#FFFFFF');--White    
        scr.SetProperty('txtJogInc', 'Fg Color', '#000000');--Black
   end
end,

[mc.OSIG_JOG_MPG] = function (state)
    if( state == 1) then
        scr.SetProperty('labJogMode', 'Label', '');
        scr.SetProperty('txtJogInc', 'Bg Color', '#C0C0C0');--Light Grey
        scr.SetProperty('txtJogInc', 'Fg Color', '#808080');--Dark Grey
        --add the bits to grey jog buttons becasue buttons can't be MPGs
    end
end
}
---------------------------------------------------------------
-- Message Library
---------------------------------------------------------------
-- More messages can be found in the Message Script section of the scripting manual
--or by typing "mc.MSG_" scroll through the list to see if one of the messages fits your use case
MsgLib = {
	[mc.MSG_REG_CHANGED] = function (param1, param2)
		-- param1 in this case is the handle of the register that has changed
		-- For information on handles/registers please reference our scripting manual
		--local value = mc.mcRegGetValue(param1)
		--local info = mc.mcRegGetInfo(param1)
	end
}
------------------
--Tool Description Update
---------------------------------------------------------------
function tooldesc()
local tReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableToolToChange")
local CurTool = mc.mcRegGetValue(tReg)
local desc = mc.mcToolGetDesc(inst, CurTool)
local Treg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableToolDesc")
rc = mc.mcRegSetValueString(Treg, desc)
end
---------------------------------------------------------------
-- Keyboard Inputs Toggle() function. Updated 5-16-16
---------------------------------------------------------------
function KeyboardInputsToggle()
	local iReg = mc.mcIoGetHandle (inst, "Keyboard/Enable")
    local iReg2 = mc.mcIoGetHandle (inst, "Keyboard/EnableKeyboardJog")
	
	if (iReg ~= nil) and (iReg2 ~= nil) then
        local val = mc.mcIoGetState(iReg);
		if (val == 1) then
            mc.mcIoSetState(iReg, 0);
            mc.mcIoSetState(iReg2, 0);
			scr.SetProperty('btnKeyboardJog', 'Bg Color', '');
            scr.SetProperty('btnKeyboardJog', 'Label', 'Keyboard\nInputs Enable');
		else
            mc.mcIoSetState(iReg, 1);
            mc.mcIoSetState(iReg2, 1);
            scr.SetProperty('btnKeyboardJog', 'Bg Color', '#00FF00');
            scr.SetProperty('btnKeyboardJog', 'Label', 'Keyboard\nInputs Disable');
        end
	end
end
---------------------------------------------------------------
-- Remember Position function.
---------------------------------------------------------------
function RememberPosition()
    local pos = mc.mcAxisGetMachinePos(inst, 0) -- Get current X (0) Machine Coordinates
    mc.mcProfileWriteString(inst, "RememberPos", "X", string.format (pos)) --Create a register and write the machine coordinates to it
    local pos = mc.mcAxisGetMachinePos(inst, 1) -- Get current Y (1) Machine Coordinates
    mc.mcProfileWriteString(inst, "RememberPos", "Y", string.format (pos)) --Create a register and write the machine coordinates to it
    local pos = mc.mcAxisGetMachinePos(inst, 2) -- Get current Z (2) Machine Coordinates
    mc.mcProfileWriteString(inst, "RememberPos", "Z", string.format (pos)) --Create a register and write the machine coordinates to it
end
---------------------------------------------------------------
-- Return to Position function.
---------------------------------------------------------------
function ReturnToPosition()
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
---------------------------------------------------------------
-- Spin CW function.
---------------------------------------------------------------
function SpinCW()
    local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_SPINDLEON);
    local sigState = mc.mcSignalGetState(sigh);
    
    if (sigState == 1) then 
        mc.mcSpindleSetDirection(inst, 0);
    else 
        mc.mcSpindleSetDirection(inst, 1);
    end
end
---------------------------------------------------------------
-- Spin CCW function.
---------------------------------------------------------------
function SpinCCW()
    local sigh = mc.mcSignalGetHandle(inst, mc.OSIG_SPINDLEON);
    local sigState = mc.mcSignalGetState(sigh);
    
    if (sigState == 1) then 
        mc.mcSpindleSetDirection(inst, 0);
    else 
        mc.mcSpindleSetDirection(inst, -1);
    end
end
---------------------------------------------------------------
-- Open Docs function.
---------------------------------------------------------------
function OpenDocs()
    local major, minor = wx.wxGetOsVersion()
    local dir = mc.mcCntlGetMachDir(inst);
    local cmd = "explorer.exe /open," .. dir .. "\\Docs\\"
    if(minor <= 5) then -- Xp we don't need the /open
        cmd = "explorer.exe ," .. dir .. "\\Docs\\"
    end
	os.execute(cmd)
    scr.RefreshScreen(250); -- Windows 7 and 8 seem to require the screen to be refreshed.  
end
---------------------------------------------------------------
-- Cycle Stop function.
---------------------------------------------------------------
function CycleStop()
mc.mcCntlCycleStop(inst);
mc.mcSpindleSetDirection(inst, 0);
mc.mcCntlSetLastError(inst, "Cycle Stopped");
	if(wait ~= nil) then
		wait = nil;
	end
end
---------------------------------------------------------------
-- Button Jog Mode Toggle() function.
---------------------------------------------------------------
function ButtonJogModeToggle()
    local cont = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_CONT);
    local jogcont = mc.mcSignalGetState(cont)
    local inc = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_INC);
    local joginc = mc.mcSignalGetState(inc)
    local mpg = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_MPG);
    local jogmpg = mc.mcSignalGetState(mpg)
    
    if (jogcont == 1) then
        mc.mcSignalSetState(cont, 0)
        mc.mcSignalSetState(inc, 1)
        mc.mcSignalSetState(mpg, 0)        
    else
        mc.mcSignalSetState(cont, 1)
        mc.mcSignalSetState(inc, 0)
        mc.mcSignalSetState(mpg, 0)
    end

end
---------------------------------------------------------------
-- Ref All Home() function.
---------------------------------------------------------------
function RefAllHome()
    mc.mcAxisDerefAll(inst)  --Just to turn off all ref leds
    mc.mcAxisHomeAll(inst)
	
	--mc.mcCntlGcodeExecute(inst, "G53 X1 Y1")
    coroutine.yield() --yield coroutine so we can do the following after motion stops
    ----See ref all home button and plc script for coroutine.create and coroutine.resume
    wx.wxMessageBox('Referencing is complete')
end

function ZeroPlate()
  hreg = mc.mcRegGetHandle(inst,  string.format("iRegs0/%s", Tool_Offset))  
  local TouchPlate = 0.622 -- Thickness of touchplate above material
  local SlowProbeRate = 0.7  -- IPM
  local FastProbeRate = 5.0  -- IPM
  local JogRate = 60
  local Pos
    
  wx.wxMessageBox("1) Check that touch plate is connected.\n2) Position the tool\'s tip above and within 2\" of the plate.\n            Press ENTER.")
  -- Fast probe Z zero
  mc.mcCntlSetLastError(inst, "Probing for Z Zero . . .")
  mc.mcCntlGcodeExecute(inst,"G91 G31 Z-2.0 F".. FastProbeRate)
  coroutine.yield()  
  
  -- Retract slightly  
  mc.mcCntlGcodeExecute(inst,"G91     Z0.05  F".. JogRate)  
  coroutine.yield()
 
  -- Slow probe Z zero
  mc.mcCntlGcodeExecute(inst,"G91 G31 Z-0.07 F".. SlowProbeRate)  
  coroutine.yield()
  
  -- Get touch position (G53) and jog to it in case of overshoot  
  Pos = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, 0)  -- Get Touch Position (work coordinates)
  mc.mcCntlGcodeExecute(inst,"G90 Z".. Pos .. " F".. SlowProbeRate)
  coroutine.yield()

  -- Set DRO to height of touchplate and retract to a safe height
  mc.mcAxisSetPos(inst, mc.Z_AXIS, TouchPlate)
  mc.mcCntlGcodeExecute(inst,"G91 Z1.0 F".. JogRate)
  coroutine.yield()
  
  mc.mcCntlSetLastError(inst, "Z Zero set")
  mc.mcRegSetValue(hreg,99.9)

  --mc.mcCntlReset(0)
end  
---------------------------------------------------------------
-- Go To Work Zero() function.
---------------------------------------------------------------
function GoToWorkZero()
    mc.mcCntlMdiExecute(inst, "G00 X0 Y0")--Without Z or A moves
    --mc.mcCntlMdiExecute(inst, "G00 G53 Z0\nG00 X0 Y0 A0\nG00 Z0")--With Z and A moves
end
---------------------------------------------------------------
-- Cycle Start() function.
---------------------------------------------------------------
function CycleStart()	
	local rc
    local tab, rc = scr.GetProperty("MainTabs", "Current Tab")
    local tabG_Mdione, rc = scr.GetProperty("nbGCodeMDI1", "Current Tab")
	local tabG_Mditwo, rc = scr.GetProperty("nbGCodeMDI2", "Current Tab")
	local state = mc.mcCntlGetState(inst)
	--mc.mcCntlSetLastError(inst,"tab == " .. tostring(tab))
	
	if (state == mc.MC_STATE_MRUN_MACROH) then 
		mc.mcCntlCycleStart(inst)
	elseif ((tonumber(tab) == 0 and tonumber(tabG_Mdione) == 1)) then  
		scr.ExecMdi('mdi1')
	elseif ((tonumber(tab) == 5 and tonumber(tabG_Mditwo) == 1)) then  
		scr.ExecMdi('mdi2')
	else
		mc.mcCntlCycleStart(inst)    
	end
end
-------------------------------------------------------
--  Seconds to time Added 5-9-16
-------------------------------------------------------
--Converts decimal seconds to an HH:MM:SS.xx format
function SecondsToTime(seconds)
	if seconds == 0 then
		return "00:00:00.00"
	else
		local hours = string.format("%02.f", math.floor(seconds/3600))
		local mins = string.format("%02.f", math.floor((seconds/60) - (hours*60)))
		local secs = string.format("%04.2f",(seconds - (hours*3600) - (mins*60)))
		return hours .. ":" .. mins .. ":" .. secs
	end
end
---------------------------------------------------------------
-- Set Button Jog Mode to Cont.
---------------------------------------------------------------
local cont = mc.mcSignalGetHandle(inst, mc.OSIG_JOG_CONT);
local jogcont = mc.mcSignalGetState(cont)
mc.mcSignalSetState(cont, 1)
-------------------------------------------------------
--  Decimal to Fractions
-------------------------------------------------------
function DecToFrac(axis)
	--Determine position to get and labels to set.
    local work = mc.mcAxisGetPos(inst, axis)
	local lab = string.format("lblFrac" .. tostring(axis))
	local labNum = string.format("lblFracNum" .. tostring(axis))
	local labDen = string.format("lblFracDen" .. tostring(axis))
    local sign = (" ")		--Use a blank space so we do not get any errors.
	
    if work < 0 then	--Change the sign to -
		sign = ("-")
	end
	
	work = math.abs (work)
	local remainder = math.fmod(work, .0625)

	if remainder >= .03125 then 	--Round up to the closest 1/16
		work = work + remainder
	else							--Round down to the closest 1/16
		work = work - remainder
	end

	local inches = math.floor(work / 1.000)
	local iremainder = work % 1.000
	local halves = math.floor(iremainder / .5000)
	local remainder = iremainder % .5000
	local quarters = math.floor(remainder / .2500)
	local remainder = remainder % .2500
	local eights = math.floor(remainder / .1250)
	local remainder = remainder % .1250
	local sixteens = math.floor(remainder / .0625)

	numar = 0	--Default to 0. The next if statement will change it if needed.
	denom = 0	--Default to 0. The next if statement will change it if needed.

	if sixteens > 0 then
		numar = math.floor(iremainder / .0625)
		denom = 16
	elseif eights > 0 then
		numar = math.floor(iremainder / .1250)
		denom = 8
	elseif quarters > 0 then
		numar = math.floor(iremainder / .2500)
		denom = 4
	elseif halves > 0 then
		numar = math.floor(iremainder / .5000)
		denom = 2
	end
	
    scr.SetProperty((lab), 'Label', (sign) .. tostring(inches))
	scr.SetProperty((labNum), 'Label', tostring(numar))
	scr.SetProperty((labDen), 'Label', "/" .. tostring(denom))
end
---------------------------------------------------------------
--Timer panel example
---------------------------------------------------------------
TimerPanel = wx.wxPanel (wx.NULL, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize( 0,0 ) )
timer = wx.wxTimer(TimerPanel)
TimerPanel:Connect(wx.wxEVT_TIMER,
function (event)
    wx.wxMessageBox("Hello")
    timer:Stop()
end)
---------------------------------------------------------------
-- Load modules
---------------------------------------------------------------
--Register module
package.loaded.mcReg = nil
mcReg = require "mcRegister"

--ErrorCheck module Added 11-4-16
package.loaded.mcErrorCheck = nil
mcErrorCheck = require "mcErrorCheck"

--Trace module
package.loaded.mcTrace = nil
mcTrace = require "mcTrace"

--Engrave Module
package.loaded.mcEngrave = nil
mcEngrave = require('mcEngrave')

--Post Module
package.loaded.mcFPost = nil
mcEngrave = require('mcFPost')

package.loaded.Module2025 = nil
Module2025 = require('Module2025')
---------------------------------------------------------------
-- Get fixtue offset pound variables function Updated 5-16-16
---------------------------------------------------------------
function GetFixOffsetVars()
    local FixOffset = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_14)
    local Pval = mc.mcCntlGetPoundVar(inst, mc.SV_BUFP)
    local FixNum, whole, frac

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
PoundVarY = (PoundVarX + 1)
PoundVarZ = (PoundVarX + 2)
return PoundVarX, PoundVarY, PoundVarZ, FixNum, CurrentFixture
-------------------------------------------------------------------------------------------------------------------
--return information from the fixture offset function
-------------------------------------------------------------------------------------------------------------------
--PoundVar(Axis) returns the pound variable for the current fixture for that axis (not the pound variables value).
--CurretnFixture returned as a string (examples G54, G59, G54.1 P12).
--FixNum returns a simple number (1-106) for current fixture (examples G54 = 1, G59 = 6, G54.1 P1 = 7, etc).
-------------------------------------------------------------------------------------------------------------------
end
----------------------------------------
-- Retract		added 9/19/2016
----------------------------------------
function SetRetractCode()
    local inst = mc.mcGetInstance();
    local hReg = mc.mcRegGetHandle(inst, "/core/inst/RetractCode");
    mc.mcRegSetValueString(hReg, "G80G40G90G20\\nG53 G00 Z0\\nM5\\nG53 G00 X0Y0"); --This is the Gcode string that will be executed when retract is requested
end
SetRetractCode();
---------------------------------------------------------------
-- Button Enable function Updated 11-8-2015
---------------------------------------------------------------
function ButtonEnable() --This function enables or disables buttons associated with an axis if the axis is enabled or disabled.

    AxisTable = {
        [0] = 'X',
        [1] = 'Y',
        [2] = 'Z',
        [3] = 'A',
        [4] = 'B',
        [5] = 'C'}
        
    for Num, Axis in pairs (AxisTable) do -- for each paired Num (key) and Axis (value) in the Axis table
        local rc = mc.mcAxisIsEnabled(inst,(Num)) -- find out if the axis is enabled, returns a 1 or 0
        scr.SetProperty((string.format ('btnPos' .. Axis)), 'Enabled', tostring(rc)); --Turn the jog positive button on or off
        scr.SetProperty((string.format ('btnNeg' .. Axis)), 'Enabled', tostring(rc)); --Turn the jog negative button on or off
        scr.SetProperty((string.format ('btnZero' .. Axis)), 'Enabled', tostring(rc)); --Turn the zero axis button on or off
        scr.SetProperty((string.format ('btnRef' .. Axis)), 'Enabled', tostring(rc)); --Turn the reference button on or off
    end
    
end
ButtonEnable()

-- PLC script
function Mach_PLC_Script()
    local inst = mc.mcGetInstance()
    local rc = 0;
    testcount = testcount + 1
    machState, rc = mc.mcCntlGetState(inst);
    local inCycle = mc.mcCntlIsInCycle(inst);
    
    tooldesc()
    
    -------------------------------------------------------
    --  Set plate align (G68) Led
    -------------------------------------------------------
    local curLedState = math.tointeger(scr.GetProperty("ledPlateAlign", "Value"))
    local curAlignState = math.tointeger((mc.mcCntlGetPoundVar(inst, 4016) - 69))
    curAlignState = math.abs(curAlignState)
    if (curLedState ~= curAlignState) then
    	scr.SetProperty("ledPlateAlign", "Value", tostring(curAlignState))
    end
    -------------------------------------------------------
    --  Coroutine resume
    -------------------------------------------------------
    if (wait ~= nil) and (machState == 0) then --wait exist and state == idle
    	local state = coroutine.status(wait)
        if state == "suspended" then --wait is suspended
            coroutine.resume(wait)
        end
    end
    -------------------------------------------------------
    --  Cycle time label update
    -------------------------------------------------------
    --Requires a static text box named "CycleTime" on the screen
    if (machEnabled == 1) then
    	local cycletime = mc.mcCntlGetRunTime(inst, time)
    	scr.SetProperty("CycleTime", "Label", SecondsToTime(cycletime))
    end
    -------------------------------------------------------
    --  Set Height Offset Led
    -------------------------------------------------------
    local HOState = mc.mcCntlGetPoundVar(inst, 4008)
    if (HOState == 49) then
        scr.SetProperty("ledHOffset", "Value", "0")
    else
        scr.SetProperty("ledHOffset", "Value", "1")
    end
    -------------------------------------------------------
    --  Set Spindle Ratio DRO
    -------------------------------------------------------
    local spinmotormax, rangemax, ratio
    spinmotormax, rc = scr.GetProperty('droSpinMotorMax', 'Value')
    spinmotormax = tonumber(spinmotormax) or 1   
    rangemax, rc = scr.GetProperty('droRangeMax', 'Value')
    rangemax = tonumber(rangemax) or 1
    ratio = (rangemax / spinmotormax)    
    scr.SetProperty('droRatio', 'Value', tostring(ratio))
    
    -------------------------------------------------------
    --  Set Feedback Ratio DRO Updated 5-30-16
    -------------------------------------------------------
    local range, rc = mc.mcSpindleGetCurrentRange(inst)
    local fbratio, rc = mc.mcSpindleGetFeedbackRatio(inst, range)
    scr.SetProperty('droFeedbackRatio', 'Value', tostring(fbratio))
    
    -------------------------------------------------------
    --  PLC First Run
    -------------------------------------------------------
    if (testcount == 1) then --Set Keyboard input startup state
        local iReg = mc.mcIoGetHandle (inst, "Keyboard/Enable")
        mc.mcIoSetState(iReg, 1) --Set register to 1 to ensure KeyboardInputsToggle function will do a disable.
        KeyboardInputsToggle()
        DecToFrac(0)
        DecToFrac(1)
        DecToFrac(2)
    	scr.SetProperty('toolpath1', 'Hidden', '0')
    	---------------------------------------------------------------
    	-- Set Persistent DROs.
    	---------------------------------------------------------------
    
        DROTable = {
    	[1034] = "droEdgeFinder",
        [1035] = "droGageBlock",
        [1036] = "droGageBlockT"
        }
    	
    	-- ******************************************************************************************* --
    	-- The following is a loop. As a rule of thumb loops should be avoided in the PLC Script.  --
    	-- However, this loop only runs during the first run of the PLC script so it is acceptable.--
    	-- ******************************************************************************************* --                                                     
    
        for name,number in pairs (DROTable) do -- for each paired name (key) and number (value) in the DRO table
            local droName = (DROTable[name]) -- make the variable named droName equal the name from the table above
            --wx.wxMessageBox (droName)
            local val = mc.mcProfileGetString(inst, "PersistentDROs", (droName), "NotFound") -- Get the Value from the profile ini
            if(val ~= "NotFound")then -- If the value is not equal to NotFound
                scr.SetProperty((droName), "Value", val) -- Set the dros value to the value from the profile ini
            end -- End the If statement
        end -- End the For loop
    	
    end
    -------------------------------------------------------
    --This is the last thing we do.  So keep it at the end of the script!
    machStateOld = machState;
    machWasEnabled = machEnabled;
    
end

-- Signal script
function Mach_Signal_Script(sig, state)
    if SigLib[sig] ~= nil then
        SigLib[sig](state);
    end
end

-- Message script
function Mach_Message_Script(msg, param1, param2)
    if MsgLib ~= nil and MsgLib[msg] ~= nil then
        MsgLib[msg](param1, param2);
    end
    
end

-- Timer script
-- 'timer' contains the timer number that fired the															 script.
function Mach_Timer_Script(timer)
    
end

-- Screen unload script
function Mach_Screen_Unload_Script()
    --Screen unload
    if (Tframe ~= nil) then
    
    	Tframe:Close()
        Tframe:Destroy()
    end
    
end

-- Screen Vision script
function Mach_Screen_Vision_Script(...)
    
end

-- Default-GlobalScript
-- tabPositionsExtens-GlobalScript
function tabPositionsExtens_On_Enter_Script(...)
    local rc;
    local tabG_Mdi, rc = scr.GetProperty("nbGCodeMDI1", "Current Tab")
    
    --See if we have to do an MDI command
    if (tonumber(tabG_Mdi) == 1 ) then
        scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nMDI');
    else
        scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nGcode');
    end
end
-- nbpagePositions-GlobalScript
function btnDeRefAll_Left_Up_Script(...)
    local inst = mc.mcGetInstance();
    mc.mcAxisDerefAll(inst);
end
function droCurrentX_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droCurrentY_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(1)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droCurrentZ_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(2)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function btnRefAll_Left_Up_Script(...)
    wait = coroutine.create (RefAllHome) --Run the RefAllHome function as a coroutine named wait.
    --See RefAllHome function in screen load script for coroutine.yield and PLC script for coroutine.resume
end
function btnGotoZero_Left_Up_Script(...)
    GoToWorkZero()
end
function droMyFix_On_Modify_Script(...)
    inst = mc.mcGetInstance()
    
    local MyFix = scr.GetProperty("droMyFix", "Value")
    
    MyFix = tonumber(MyFix)
    if (MyFix > 0) and (MyFix) < 7 then
        MyFix = MyFix + 53
        mc.mcCntlGcodeExecute(inst, (string.format('G' .. MyFix)))
    elseif (MyFix > 6) and (MyFix < 107) then
    	MyFix = (MyFix - 6)
    	mc.mcCntlGcodeExecute(inst, (string.format("G54.1 P" .. MyFix)))
    	MyFix = tostring(MyFix)
    	scr.SetProperty("droMyFix", "Value", "1")
    else
        wx.wxMessageBox("The fixtures you can call through this input are limited to 1-106 (G54-G54.1 P100).\n \nEnter a valid number (1-126) and try again.\n\n*** It will now default to 1 (G54) ***")
        scr.SetProperty("droMyFix", "Value", "1")
        mc.mcCntlGcodeExecute(inst, "G54")
    end
end
function btmAutoZero_Clicked_Script(...)
    -- goto Park Location.
    local valX, valY, valZ, inst
    inst = mc.mcGetInstance()
    valX = scr.GetProperty("droParkLocX", "Value")
    valY = scr.GetProperty("droParkLocY", "Value") 
    valZ = scr.GetProperty("droParkLocZ", "Value")
    mc.mcCntlSetLastError(inst, "Parking at X = " .. valX .. " Y = " .. valY .. " Z = " .. valZ)
    mc.mcCntlGcodeExecute(inst, "G53 G0 Z" .. valZ)
    mc.mcCntlGcodeExecute(inst, "G53 G0 X" .. valX .. " Y" .. valY)
end
function btmLaserOffset_Clicked_Script(...)
    local inst = mc.mcGetInstance();
    
    local hreg =  mc.mcRegGetHandle(inst, "iRegs0/2025/LaserOffsetX") --   scr.GetProperty("droXLaserOffset", "Value")   -- -4.7335 -- X axis distance from laser crosshairs to spindle center
    local offsetX = mc.mcRegGetValueLong(hreg)	  
    	  hreg =  mc.mcRegGetHandle(inst,  "iRegs0/2025/LaserOffsetY") --scr.GetProperty("droYLaserOffset", "Value")   -- -0.0137 -- Y axis distance from laser crosshairs to spindle center
    local offsetY = mc.mcRegGetValueLong(hreg)
    
    mc.mcAxisSetPos(inst,mc.X_AXIS,offsetX)
    mc.mcAxisSetPos(inst,mc.Y_AXIS,offsetY)
    mc.mcCntlSetLastError(inst, "Workpiece X/Y DRO set to laser crosshair X = ".. offsetX .. " Y = " .. offsetY)
    
end
function btmToolChangePos_Clicked_Script(...)
    -- Tool Change Button
    
     
    inst = mc.mcGetInstance()
    
    local hreg,rc = mc.mcRegGetHandle(inst, "iRegs0/2025/TCX")
    TCX = mc.mcRegGetValueString(hreg)
    hreg = mc.mcRegGetHandle(inst, "iRegs0/2025/TCY")
    TCY = mc.mcRegGetValueString(hreg)
    hreg,rc = mc.mcRegGetHandle(inst, "iRegs0/2025/TCZ")
    TCZ = mc.mcRegGetValueString(hreg)
    
    if (rc ~= 0) then
    	mc.mcCntlSetLastError(inst, "oops")
    end
    
    local posmode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3) --get the current mode so we can return to it when macro ends
    
    hreg = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseMachineCoord')
    MC = mc.mcRegGetValueLong(hreg)
    hreg = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseSafeZ')
    SZ = mc.mcRegGetValueLong(hreg)
    
    if (SZ == 1) then
    	mc.mcCntlGcodeExecute(inst, "G53 G0 Z0")
    	mc.mcCntlSetLastError(inst, "Moving to Tool Change Position  X = "..TCX.." Y = "..TCY.." Z = -0.0")
    else
    	mc.mcCntlGcodeExecute(inst, "G53 G0 Z" .. TCZ)
    	mc.mcCntlSetLastError(inst, "Moving to Tool Change Position  X = "..TCX.." Y = "..TCY.." Z = "..TCZ)
    end
    
    mc.mcCntlGcodeExecute(inst, "G53 G0 X" .. TCX .. " Y" .. TCY)
    mc.mcCntlSetPoundVar(inst, mc.SV_MOD_GROUP_3, posmode) -- reset back.
     
end
function btmParkLocation_Clicked_Script(...)
    -- Park Location
    
     local valX, valY, valZ, inst
    inst = mc.mcGetInstance()
    local hreg = mc.mcRegGetHandle(inst, "iRegs0/2025/ParkLocationX")
    valX = mc.mcRegGetValueLong(hreg) --scr.GetProperty("droParkLocX", "Value")
    hreg = mc.mcRegGetHandle(inst, "iRegs0/2025/ParkLocationY")
    valY = mc.mcRegGetValueLong(hreg) --scr.GetProperty("droParkLocY", "Value") 
    hreg = mc.mcRegGetHandle(inst, "iRegs0/2025/ParkLocationZ")
    valZ = mc.mcRegGetValueLong(hreg) --scr.GetProperty("droParkLocZ", "Value")
    local posmode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3) --get the current mode so we can return to it when macro ends
    
    hreg = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseMachineCoord')
    MC = mc.mcRegGetValueLong(hreg)
    hreg = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseSafeZ')
    SZ = mc.mcRegGetValueLong(hreg)
    
    
    if (SZ ~= 1) then -- Maybe not so good
    	valZ = 0.0
    end
    
    
    if (MC ~= 1) then
    	mc.mcCntlSetLastError(inst, "Why tempt fate using Work Coordinates for Parking... X = "..valX.." Y = "..valY.." Z = "..valZ)
    	mc.mcCntlGcodeExecute(inst, "G0 Z" .. valZ)
    	mc.mcCntlGcodeExecute(inst, "G0 X" .. valX .. " Y" .. valY)
    else
    	-- We are in Machine Coords. SZ may be set.
    	mc.mcCntlSetLastError(inst, "Parking at X = " .. valX .. " Y = " .. valY .. " Z = " .. valZ)
    	mc.mcCntlGcodeExecute(inst, "G53 G0 Z" .. valZ)
    	mc.mcCntlGcodeExecute(inst, "G53 G0 X" .. valX .. " Y" .. valY)
    end
    
     mc.mcCntlSetPoundVar(inst, mc.SV_MOD_GROUP_3, posmode) -- Set mode back so nothing screws up.
     
end
function btnSimpleAutoZero_Clicked_Script(...)
    local inst = mc.mcGetInstance()
    
    -- Load the zTouchPlate module
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    package.path = path .. "\\Modules\\zTouchPlate\\?.lua;"
    package.loaded.zTouchPlate = nil
    local ztp = require "zTouchPlate"
    
    -- Load UI and code to implement this panel
    ztp.create()
    
end
-- nbpageExtents-GlobalScript
-- nbpFractional-GlobalScript
-- nbGCodeInput1-GlobalScript
function nbGCodeInput1_On_Enter_Script(...)
     scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nGcode');
end
-- nbMDIInput1-GlobalScript
function nbMDIInput1_On_Enter_Script(...)
    scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nMDI');
end
-- nbpTP1-GlobalScript
-- nbpttblone-GlobalScript
-- nbpFixTable-GlobalScript
-- nbpXOffsetsLathe-GlobalScript
-----------------------------------------------------------
--Create Registers for the wear offstes table
-----------------------------------------------------------
local inst = mc.mcGetInstance()
	if (scr == nil) then
		scr = require('screenipc')
	end
	
	if mcReg == nil then
		mcReg = require('mcRegister')
	end
	
	local inst = mc.mcGetInstance()
	local msg = ""
	local loopCount = 0
	local mode = 0
	------------------------------------------------
	--Offset Reg Table
	------------------------------------------------
	local OffsetTBL = {--Table format: {"name", "description", initialval, persistent, value}
		--Unit dependent We will adjust these depending on Machine units and Gcode units (G20/21)
		--{"Bogus", "Description.", 5.0, 1, 0},
		{"ToolToChange", "ToolToChange", 0, 1, 0},
		{"ToolDesc", "Tool Description", 0, 1, 0},
		{"OffsetVal", "OffsetVal", 0, 1, 0},
		{"HalfOffsetVal", "HalfOffsetVal", 0, 1, 0},
		{"TargetDimention", "TargetDimention", 0, 1, 0},
		{"ActualMeasure", "ActualMeasure", 0, 1, 0},
		{"halfoffset", "halfoffset", 0, 1, 0},
		{"Xwear", "X Wear", 0, 1, 0}
}
	--------------------------------------------
	--Build Offset Registers
	--------------------------------------------
	--if (mode == 0) then
	rc = mcReg.doRegTable(inst, "ADD", OffsetTBL, "iRegs0", "nf/Otable") --Instacne, Mode (DEL or ADD), Table, Device, Group This will create or delete all the registers in thcRegTbl if they don't exist in the profile
	if (rc ~= 0) then
		msg = mc.mcCntlGetErrorString(inst, rc) --Get the returned error string
		errorOut(msg)
	end	
	local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
		mc.mcRegSetValue(HREg, 1)
function nbpXOffsetsLathe_On_Enter_Script(...)
    local inst = mc.mcGetInstance()
    local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
    mc.mcRegSetValue(HREg, 1)
end
function btnHalfx_Left_Up_Script(...)
    ---------------------------------------------------------------
    -- Set 1/2 offset function.
    ---------------------------------------------------------------
    	local sigh = mc.mcRegGetHandle(inst, "iRegs0/nf/Otablehalfoffset");
        local sigState = mc.mcRegGetValue(sigh);
        
        if (sigState == 1) then 
            mc.mcRegSetValue(sigh, 0);
    		mc.mcCntlSetLastError(inst, 'Full Offset Enabled')
    		scr.SetProperty('btnHalfx', 'Label', 'Full Offset')
    		scr.SetProperty('btnHalfx', 'Bg Color', '#000000');--Black
            scr.SetProperty('btnHalfx', 'Fg Color', '#00FF00');--Green
    else 
            mc.mcRegSetValue(sigh, 1);
    		mc.mcCntlSetLastError(inst, 'Half Offset Enabled')
    		scr.SetProperty('btnHalfx', 'Label', 'Half Offset')
    		scr.SetProperty('btnHalfx', 'Bg Color', '#00FF00');--Green
            scr.SetProperty('btnHalfx', 'Fg Color', '#000000');--Black
        end
    
end
function lblactualx_Left_Up_Script(...)
    ----------------------------------------------------------------------
    --Wear Offsetting Facility
    ----------------------------------------------------------------------
    local inst = mc.mcGetInstance()
    wx.wxMilliSleep(200)
    local mode = mc.mcCntlGetMode(inst)
    local hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableTargetDimention")
    local target = mc.mcRegGetValue(hReg)
    local Hreg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableActualMeasure")
    local act = mc.mcRegGetValue(Hreg)
    local HReg = mc.mcRegGetHandle(inst, "iRegs0/nf/Otablehalfoffset")
    local half = mc.mcRegGetValue(HReg)
    local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
    local x = mc.mcRegGetValue(HREg)
    local tReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableToolToChange")
    local CurTool = mc.mcRegGetValue(tReg)
    local diff = (target - act)
    		if (half == 1) then
    	   diff = (diff / 2)
    end	
    		if (mode == 2) then
    		diff = (diff / 2)
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool 
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    		if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f       New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    diff = (diff * 2)
    local NewDiaWear = (Currwearz + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f       New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end	
    	elseif (mode == 1) then
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool 
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f       New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f       New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end
    	else 
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearx = mc.mcToolGetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool
    local Currwearz = mc.mcToolGetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f       New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f       New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    	end
    end
end
function btnaddoffset_2__Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    wx.wxMilliSleep(200)
    local mode = mc.mcCntlGetMode(inst)
    local hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableOffsetVal")
    local target = mc.mcRegGetValue(hReg)
    local HReg = mc.mcRegGetHandle(inst, "iRegs0/nf/Otablehalfoffset")
    local half = mc.mcRegGetValue(HReg)
    local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
    local x = mc.mcRegGetValue(HREg)
    local tReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableToolToChange")
    local CurTool = mc.mcRegGetValue(tReg)
    local desc = mc.mcToolGetDesc(inst, CurTool)
    	if (half == 1) then
    	target = (target / 2)
    end	
    
    --iRegs0/nf/OtableToolToChange
    
    	if (mode == 2) then
    		target = (target / 2)
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    
    
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f   Desc:     Prev Wear X:%.4f    New Wear X:%.4f", CurTool, desc, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    target = (target *2)
    local NewDiaWear = (Currwearz + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f    New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end
    	elseif (mode == 1) then
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f    New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f    New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end
    	else
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearx = mc.mcToolGetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool
    local Currwearz = mc.mcToolGetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f    New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f    New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    	end
    end
end
function droTooltoChangex_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...)
    mc.mcProfileWriteString(inst, "PersistentDROs", "droJogRate", string.format(val))
    
    tooldesc()
    
    return val
end
function droCounterx_On_Update_Script(...)
    local inst = mc.mcGetInstance()
    local fakept = mc.mcCntlGetPoundVar(inst, 3901)
    mc.mcCntlSetPoundVar(inst, 115, tonumber(fakept))
end
function droCounterx_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local fakept = mc.mcCntlGetPoundVar(inst, 3901)
    local reset = (fakept - fakept)
    mc.mcCntlSetPoundVar(inst, 115, tonumber(reset))
end
function droActualDim_2__On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    local hReg = mc.mcRegGetHandle(inst, 'iRegs0/nf/OtableTargetDimention')
    local Hreg = mc.mcRegGetHandle(inst, 'iRegs0/nf/OtableActualMeasure')
    	local target = mc.mcRegGetValue(hReg)
    	target = tonumber(target)
    	local actual = mc.mcRegGetValue(Hreg)
    	actual = tonumber(actual)
    	
    function imgupdate()
    	if (actual < target) then
    		
    		rc = scr.SetProperty('imgtwo', 'Image', 'xposmill2.png')
    	else
    		rc = scr.SetProperty('imgtwo', 'Image', 'xnegmill1.png')
    		
    end
    end
    imgupdate()
    return val
end
-- nbpZOffsetsLathe-GlobalScript
-----------------------------------------------------------
--Create Registers for the wear offstes table
-----------------------------------------------------------
local inst = mc.mcGetInstance()
	if (scr == nil) then
		scr = require('screenipc')
	end
	
	if mcReg == nil then
		mcReg = require('mcRegister')
	end
	
	local inst = mc.mcGetInstance()
	local msg = ""
	local loopCount = 0
	local mode = 0
	------------------------------------------------
	--Offset Reg Table
	------------------------------------------------
	local OffsetTBL = {--Table format: {"name", "description", initialval, persistent, value}
		--Unit dependent We will adjust these depending on Machine units and Gcode units (G20/21)
		--{"Bogus", "Description.", 5.0, 1, 0},
		{"ToolToChange", "ToolToChange", 0, 1, 0},
		{"ToolDesc", "Tool Description", 0, 1, 0},
		{"OffsetVal", "OffsetVal", 0, 1, 0},
		{"HalfOffsetVal", "HalfOffsetVal", 0, 1, 0},
		{"TargetDimention", "TargetDimention", 0, 1, 0},
		{"ActualMeasure", "ActualMeasure", 0, 1, 0},
		{"halfoffset", "halfoffset", 0, 1, 0},
		{"Xwear", "X Wear", 0, 1, 0}
}
	--------------------------------------------
	--Build Offset Registers
	--------------------------------------------
	--if (mode == 0) then
	rc = mcReg.doRegTable(inst, "ADD", OffsetTBL, "iRegs0", "nf/Otable") --Instacne, Mode (DEL or ADD), Table, Device, Group This will create or delete all the registers in thcRegTbl if they don't exist in the profile
	if (rc ~= 0) then
		msg = mc.mcCntlGetErrorString(inst, rc) --Get the returned error string
		errorOut(msg)
	end	
	local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
		mc.mcRegSetValue(HREg, 1)
function nbpZOffsetsLathe_On_Enter_Script(...)
    local inst = mc.mcGetInstance()
    local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
    mc.mcRegSetValue(HREg, 1)
end
function droActualDimz_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    local hReg = mc.mcRegGetHandle(inst, 'iRegs0/nf/OtableTargetDimention')
    local Hreg = mc.mcRegGetHandle(inst, 'iRegs0/nf/OtableActualMeasure')
    	local target = mc.mcRegGetValue(hReg)
    	target = tonumber(target)
    	local actual = mc.mcRegGetValue(Hreg)
    	actual = tonumber(actual)
    	
    function imgupdate()
    	if (actual < target) then
    		
    		rc = scr.SetProperty('img3', 'Image', 'zposmill2.png')
    	else
    		rc = scr.SetProperty('img3', 'Image', 'Znegmill1.png')
    		
    end
    end
    imgupdate()
    return val
end
function btnHalfz_Left_Up_Script(...)
    ---------------------------------------------------------------
    -- Set 1/2 offset function.
    ---------------------------------------------------------------
    	local sigh = mc.mcRegGetHandle(inst, "iRegs0/nf/Otablehalfoffset");
        local sigState = mc.mcRegGetValue(sigh);
        
        if (sigState == 1) then 
            mc.mcRegSetValue(sigh, 0);
    		mc.mcCntlSetLastError(inst, 'Full Offset Enabled')
    		scr.SetProperty('btnHalfz', 'Label', 'Full Offset')
    		scr.SetProperty('btnHalfz', 'Bg Color', '#000000');--Black
            scr.SetProperty('btnHalfz', 'Fg Color', '#00FF00');--Green
    else 
            mc.mcRegSetValue(sigh, 1);
    		mc.mcCntlSetLastError(inst, 'Half Offset Enabled')
    		scr.SetProperty('btnHalfz', 'Label', 'Half Offset')
    		scr.SetProperty('btnHalfz', 'Bg Color', '#00FF00');--Green
            scr.SetProperty('btnHalfz', 'Fg Color', '#000000');--Black
        end
    
end
function lblTargetz_Left_Up_Script(...)
    ----------------------------------------------------------------------
    --Wear Offsetting Facility
    ----------------------------------------------------------------------
    local inst = mc.mcGetInstance()
    wx.wxMilliSleep(200)
    local mode = mc.mcCntlGetMode(inst)
    local hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableTargetDimention")
    local target = mc.mcRegGetValue(hReg)
    local Hreg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableActualMeasure")
    local act = mc.mcRegGetValue(Hreg)
    local HReg = mc.mcRegGetHandle(inst, "iRegs0/nf/Otablehalfoffset")
    local half = mc.mcRegGetValue(HReg)
    local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
    local x = mc.mcRegGetValue(HREg)
    local tReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableToolToChange")
    local CurTool = mc.mcRegGetValue(tReg)
    local diff = (target - act)
    		if (half == 1) then
    	   diff = (diff / 2)
    end	
    		if (mode == 2) then
    		diff = (diff / 2)
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool 
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    		if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f       New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    diff = (diff * 2)
    local NewDiaWear = (Currwearz + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f       New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end	
    	elseif (mode == 1) then
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool 
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f       New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f       New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end
    	else 
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearx = mc.mcToolGetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool
    local Currwearz = mc.mcToolGetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f       New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + diff) --New wear value based on the previous value and the desired value
    	mc.mcToolSetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    	mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f       New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    	end
    end
end
function droCountz_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    wx.wxMilliSleep(200)
    local mode = mc.mcCntlGetMode(inst)
    local hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableOffsetVal")
    local target = mc.mcRegGetValue(hReg)
    local HReg = mc.mcRegGetHandle(inst, "iRegs0/nf/Otablehalfoffset")
    local half = mc.mcRegGetValue(HReg)
    local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
    local x = mc.mcRegGetValue(HREg)
    local tReg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableToolToChange")
    local CurTool = mc.mcRegGetValue(tReg)
    local desc = mc.mcToolGetDesc(inst, CurTool)
    	if (half == 1) then
    	target = (target / 2)
    end	
    
    --iRegs0/nf/OtableToolToChange
    
    	if (mode == 2) then
    		target = (target / 2)
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    
    
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f   Desc:     Prev Wear X:%.4f    New Wear X:%.4f", CurTool, desc, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    target = (target *2)
    local NewDiaWear = (Currwearz + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f    New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end
    	elseif (mode == 1) then
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearx = mc.mcToolGetData(inst, mc.SV_LATHE_X_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool 
    local Currwearz = mc.mcToolGetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_X_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f    New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_LATHE_Z_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f    New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    end
    	else
    --local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local Currwearx = mc.mcToolGetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, OffsetVal) --Current XWear offest for the current Tool
    local Currwearz = mc.mcToolGetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, OffsetVal) --Current ZWear offest for the current Tool
    	if (x == 1) then
    local oldval = Currwearx
    local NewDiaWear = (Currwearx + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_MILL_DIA_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear X:%.4f    New Wear X:%.4f", CurTool, oldval, NewDiaWear))
    	else
    local oldval = Currwearz
    local NewDiaWear = (Currwearz + target) --New wear value based on the previous value and the desired value
    mc.mcToolSetData(inst, mc.SV_MILL_LEN_WEAR, CurTool, NewDiaWear) --Set the new value after doing the math
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f     Prev Wear Z:%.4f    New Wear Z:%.4f", CurTool, oldval, NewDiaWear))
    	end
    end
end
function droTooltoChangez_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...)
    mc.mcProfileWriteString(inst, "PersistentDROs", "droJogRate", string.format(val))
    
    tooldesc()
    
    return val
end
-- tabToolPath-GlobalScript
function tabToolPath_On_Enter_Script(...)
     scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nGcode');
end
-- M6 Setup-GlobalScript
-- MultiProbing(1)-GlobalScript
function ProbingSetup1_1__Clicked_Script(...)
    local inst = mc.mcGetInstance();
    
    local hreg = mc.mcRegGetHandle(inst, 'ESS/Probing_State') -- registry location for Probing_State value. We will use this later to make sure the probe stops when the gcode for probing occurs
    local isHomed = 1 --, rc = acHoming:GetAllAxesHomed() -- used to make sure homing has occured
    local zOrigin = 0
    
    
    function GetRegister(regname)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     return mc.mcRegGetValueString(hreg)
    end
    
     function WriteRegister(regname, regvalue)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     mc.mcRegSetValueString(hreg, tostring(regvalue))
    end
    
    
    zHeightSurface = GetRegister("2025/ZHeightSurface")
    fixedPlateTouchZ = GetRegister("2025/FixedPlateTouchZ") -- the variable to store the height of tool that probed the permanent plate
    LastFixedPlateTouchZ = GetRegister("2025/LastFixedPlateTouchZ") -- var to store first touch in after m6.
    fixedPlate_X = GetRegister("2025/XPlate") -- fixed plate X location
    fixedPlate_Y = GetRegister("2025/YPlate") -- fixed plate Y location
    plateThickness = GetRegister("2025/PlateThickness") -- the thickness of the plate used to touch the surface z zero. For subtracting from touch position
    firstTouchSpeed = GetRegister("2025/FirstTouchSpeed") -- speed in inches per minute to probe for finding the surface before going slower
    secondTouchSpeed = GetRegister("2025/SecondTouchSpeed") -- slower speed to touch at
    touchRetractHeight = GetRegister("2025/TouchRetractHeight") -- how much to move up before touching slower
    moveToPlateDistance = GetRegister("2025/MoveToPlateDistance") -- how much to move up before touching slower
    --switch the distance input for moving the z to a negative to move in the correct direction
    moveToPlateDistance = -moveToPlateDistance 
    probingSearchDistance = GetRegister("2025/ProbingSearchDistance") -- how much to move up before touching slower
    --switch the distance input for probing to a negative to move in the correct direction
    probingSearchDistance = -probingSearchDistance
    
    --[[ 
    This function will be called to turn off and on soft limits 
    of the Z axis during the probing routine. Otherwise, it will 
    error or you ahve to manually click on soft limits button]]
    
    local function GetSoftLimitForAxis(axis)
    	local inst = mc.mcGetInstance()
    	local result, rc = mc.mcSoftLimitGetState(inst, mc.Z_AXIS)
    	return result
    end
    
    
    local function SetSoftLimit(axis, ison)
    	local inst = mc.mcGetInstance()
    	local rc = mc.mcSoftLimitSetState(inst, axis, ison)
    	return rc
    end
    
    function SetAxisPosition(axis, AxisPos)
    	
    	 mc.mcAxisSetPos(inst, axis, AxisPos)
    	 
    	end
    
    ----------------------------------------------------------------------------------------------------------------------------------
    --Before we start probing anything, let's check and make sure we are homed
    ----------------------------------------------------------------------------------------------------------------------------------
    if (rc ~= mc.MERROR_NOERROR) then
    	mc.mcCntlLog(inst, "Failed to determine if machine is homed, rc = "..rc, "", -1)
    	wx.wxMessageBox("Homing check failed, cannot set up M6 settings without homing first.", "Manual Tool Change")
    	return
    end
    if isHomed then
       local OldSoftLimitZ = GetSoftLimitForAxis(mc.Z_AXIS)
       SetSoftLimit(mc.Z_AXIS, mc.MC_OFF) -- turn off z axis soft limit for probing. Have to do this because you can input a large number in the probing distance input box. 
           
       local posmode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3) --get the current mode so we can return to it when macro ends
       local feedRate = mc.mcCntlGetPoundVar(inst, 2134) 
       
    ----------------------------------------------------------------------------------------------------------------------------------   
    -- First move tool over the moveable plate and zero out to the surface. This will become the current offset z0 and give us a number to work with when finding the fixed plate height difference
    -- Start the probing for Z first move
    ----------------------------------------------------------------------------------------------------------------------------------
       mc.mcCntlGcodeExecuteWait(inst,'G91 G31 Z'..probingSearchDistance .. 'F' .. firstTouchSpeed)
       if mc.mcRegGetValue(hreg) == -1 then
    	wx.wxMessageBox('No probe strike. Aborting the rest of the routine')
    	return
       end
       mc.mcCntlGcodeExecuteWait(inst, 'G91 Z'.. touchRetractHeight) -- retract and probe slower
    ----------------------------------------------------------------------------------------------------------------------------------   
    -- Second probing with slower speed   
    ----------------------------------------------------------------------------------------------------------------------------------
       mc.mcCntlGcodeExecuteWait(inst,'G91 G31 Z'..probingSearchDistance .. 'F' .. secondTouchSpeed)
       
       if mc.mcRegGetValue(hreg) == -1 then
    	wx.wxMessageBox('No probe strike. Aborting the rest of the routine')
    	return
       end
       mc.mcCntlSetLastError(inst, "First probe complete")
    
      SetAxisPosition(mc.Z_AXIS, 0)  
    
      zOrigin = mc.mcAxisGetPos(inst, mc.Z_AXIS) -- need to store this in zHeightSurface for later. First, we need to subtract the palte thickness from this number.
    ----------------------------------------------------------------------------------------------------------------------------------
    -- End probing for Z first move and setting work surface to 0
    ----------------------------------------------------------------------------------------------------------------------------------
      zHeightSurface = math.abs(zOrigin - plateThickness) -- subtracts the thickness of the moveable plate from the measurement of the probing touch height
      WriteRegister("2025/ZHeightSurface", zHeightSurface) -- Now store the machine z location that is currently used for work coordinate z0
    -- Set position of z axis with mcAxisSetPos and use this as the z height for your work coordinate Z0
      local double ZAxisPos = zHeightSurface
      SetAxisPosition(mc.Z_AXIS, ZAxisPos)    
      
    --------------------------------------------------------------------------------------------------------------------------------------
    -- End of first surface probe routine. Ask to move the plate over to the permanent position before moving the tool there
    --------------------------------------------------------------------------------------------------------------------------------------
      -- wx.wxMessageBox("Moving to mounted plate now. Press OK to Continue")
    
     --------------------------------------------------------------------------------------------------------------------------------------
    -- Move to permanent probe plate xy and probe
    --------------------------------------------------------------------------------------------------------------------------------------
    mc.mcCntlSetLastError(inst, "Moving to permanent plate")
    mc.mcCntlGcodeExecuteWait(inst, "G90 G53 G0 Z0.0"); -- Move the Z axis all the way up before XY moves
    mc.mcCntlGcodeExecuteWait(inst, "G53 G01 X" .. fixedPlate_X .. "Y" .. fixedPlate_Y .. "f350");-- use variables from gui for location
    mc.mcCntlGcodeExecuteWait(inst, 'G90 G53 G0 Z' .. moveToPlateDistance); -- Move the Z axis down. second probing pre-move in m6 setup screen is the input for this number.
    ----------------------------------------------------------------------------------------------------------------------------------
    -- probing 2 times. 1 fast and 2 is slow
    ----------------------------------------------------------------------------------------------------------------------------------
       mc.mcCntlGcodeExecuteWait(inst,'G91 G31 Z'..probingSearchDistance .. 'F' .. firstTouchSpeed) -- probing distance and first touch speed on m6 setup screen is the input for this number.
       if mc.mcRegGetValue(hreg) == -1 then -- look for error input from ess to confirm touch happened and exit if not
    	wx.wxMessageBox('No probe strike. Aborting the rest of the routine')
    	return
       end
       mc.mcCntlGcodeExecuteWait(inst, 'G91 Z'.. touchRetractHeight) -- retract and probe slower
    -- Second probing with slower speed   
       mc.mcCntlGcodeExecuteWait(inst,'G91 G31 Z'..probingSearchDistance .. 'F' .. secondTouchSpeed) -- probe again and use the second touch speed input on m6 screen
       if mc.mcRegGetValue(hreg) == -1 then --look for error input from ess to confirm touch happened and exit if not
    	wx.wxMessageBox('No probe strike. Aborting the rest of the routine')
    	return
       end
       
    fixedPlateTouchZ = mc.mcAxisGetPos(inst, mc.Z_AXIS) -- store the current height as the touch plate height
    WriteRegister("2025/FixedPlateTouchZ", fixedPlateTouchZ) -- store the current plate height for use in the m6 macro later
    resetLastFixedPlateTouchz = "reset"
    WriteRegister("2025/LastFixedPlateTouchZ", resetLastFixedPlateTouchz) -- just to get rid of an old value to show it has not run yet
    
    --wx.wxMessageBox(
     mc.mcCntlSetLastError(inst, "Fixed Plate height is " .. fixedPlateTouchZ) 
    -- End Move to permanent probe plate xy and probe
    ----------------------------------------------------------------------------------------------------------------------------------
    -- finish up
    ----------------------------------------------------------------------------------------------------------------------------------
      local ProbeChoice = wx.wxMessageBox("Remove Probe Clip","Click YES to move z to top and NO to prevent z from going to top" , 18)  -- brings up a dialog box and waits for a selection to proceed
      if (ProbeChoice == 16) then  --16 is cancel
    	rc = mc.mcCntlSetLastError(inst, 'Canceling.') 
      elseif (ProbeChoice == 2) then
    	-- mc.mcCntlGcodeExecute(inst, "G04 p.5") -- Dwell for half a second
    	mc.mcCntlGcodeExecuteWait(inst, "G90 G53 G0 Z0.0"); -- Move the Z axis all the way up before XY moves
      elseif (ProbeChoice == 8) then
    	mc.mcCntlGcodeExecuteWait(inst, "G91 G0 Z" .. touchRetractHeight)  
    	mc.mcCntlSetLastError(inst, "M6 Setup Complete")
      end
      mc.mcCntlSetPoundVar(inst, mc.SV_MOD_GROUP_3, posmode)
      mc.mcCntlSetPoundVar(inst, 2134, feedRate)  
      SetSoftLimit(mc.Z_AXIS, OldSoftLimitZ)
    else
      wx.wxMessageBox("Your machine must be homed\nbefore we can set up M6.", "Manual Tool Change") -- if not yet homed, exit with this message to home before trying again
    end
    
    
    
end
function btn_82__Clicked_Script(...)
    local inst = mc.mcGetInstance()
    
     function GetRegister(regname)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     return mc.mcRegGetValueString(hreg)
    end
    
    
    function GoToPermPlate()
    	mc.mcCntlGcodeExecute(inst, 'G53 X'.. FixedPlate_X .. 'Y' .. FixedPlate_Y .. 'f300')
    end
    
    FixedPlate_X = GetRegister("2025/XPlate") -- fixed plate X location
    FixedPlate_Y = GetRegister("2025/YPlate") -- fixed plate Y location
    
    mc.mcCntlGcodeExecuteWait(inst, "G90 G53 G0 Z0.0");--Move the Z axis all the way up
    GoToPermPlate()
    
    
    
    
    
    
    
    
    --SetSoftLimits(mc.Z_AXIS, mc.MC_ON)
    
    --wx.wxMessageBox(tostring(mc.mcSoftLimitGetState, "Z_Axis is set to: "))
    
end
function luaFixtureTable_1__Script(...)
    local inst = mc.mcGetInstance("panelFixtureTable")
    
    -- local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = package.path .. ";" .. path .. "\\Modules\\AvidCNC\\?.luac;" 
    
    package.loaded.FixtureTable = nil
    touFT = require "FixtureTable"
    
    touFT.FixtureOffsets()
end
-- grp(22)-GlobalScript
function txt_14__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_24__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_11__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_8__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
-- ProbingSettings-GlobalScript
function txt_15__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_10__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_13__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_14__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_15__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function txt_14__On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
-- grp(24)-GlobalScript
function btnZeroZ_1__Left_Down_Script(...)
    local inst = mc.mcGetInstance("Zero Z Btn, left down script")
    local hreg, rc = mc.mcRegGetHandle(inst, "ESS/HC/Z_DRO_Force_Sync_With_Aux")
    if (rc ~= mc.MERROR_NOERROR) then
      mc.mcCntlLog(
        inst,
        string.format("Failure to acquire register handle for ESS/HC/Z_DRO_Force_Sync_With_Aux, rc=%s", rc)
        "",
        -1)
    else
      mc.mcRegSetValueLong(hreg, 1)
      mc.mcCntlLog(inst, "Zero Z button forcing an ESS Z sync", "", -1)
    end
    
    hreg, rc = mc.mcRegGetHandle(inst, string.format("ESS/HC/Command"))
    if (rc ~= mc.MERROR_NOERROR) then
      mc.mcCntlLog(
        inst,
        string.format("Failure to acquire register handle for ESS/HC/Command, rc=%s", rc)
        "",
        -1)
    else
      mc.mcRegSetValueString(hreg, "(HC_WORK_Z_ZEROED=1)")
      mc.mcCntlLog(inst, '....ZeroZButton() said that Z was zeroed', "", -1)
    end
end
function btnGotoZero_1__Left_Up_Script(...)
    local show = avd.WarningDialog("Machine Movement Warning!", "Machine will move at the rapid rate and current Z height to the X and Y zero positions of the current work coordinates.", "iShowWarningMoveToWorkZero");
    if (show == 0) then
    	GoToWorkZero()
    end
end
function btn_89__Clicked_Script(...)
    local inst = mc.mcGetInstance()
    
     function GetRegister(regname)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     return mc.mcRegGetValueString(hreg)
    end
    
     function WriteRegister(regname, regvalue)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     mc.mcRegSetValueString(hreg, tostring(regvalue))
    end
    
    xLoc = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)   -- store the x loc
    WriteRegister("2025/XPlate", xLoc)
    yLoc = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)   -- store the y loc
    WriteRegister("2025/YPlate", yLoc)
    
    
    
    
    
    
end
function btn_90__Clicked_Script(...)
    local inst = mc.mcGetInstance()
    
     function GetRegister(regname)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     return mc.mcRegGetValueString(hreg)
    end
    
     function WriteRegister(regname, regvalue)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     mc.mcRegSetValueString(hreg, tostring(regvalue))
    end
    
    
    function GoToPermPlate()
    	mc.mcCntlGcodeExecute(inst, 'G53 X'.. FixedPlate_X .. 'Y' .. FixedPlate_Y .. 'f300')
    end
    
    function GoToMTCLocation()
    	mc.mcCntlGcodeExecuteWait(inst, 'G53 X'.. mTCPositionX .. 'Y' .. mTCPositionY)
    end
    
    
    FixedPlate_X = GetRegister("2025/XPlate") -- fixed plate X location
    FixedPlate_Y = GetRegister("2025/YPlate") -- fixed plate Y location
    mTCPositionX = GetRegister("2025/TCX") -- fixed plate X location
    mTCPositionY = GetRegister("2025/TCY") -- fixed plate Y location
    MTCZHeight =   GetRegister("2025/TCZ") -- mtc z heightr to move to after going to the location
    
    
    mc.mcCntlGcodeExecuteWait(inst, "G90 G53 G0 Z0.0");--Move the Z axis all the way up
    GoToMTCLocation()
    if (tonumber(MTCZHeight) <= 0) then
    	mc.mcCntlGcodeExecuteWait(inst, "G90 G53 G0 Z" .. MTCZHeight);--Move the Z axis toi change height
    end
    
    
    
    
end
function btn_91__Clicked_Script(...)
    local inst = mc.mcGetInstance()
    
     function WriteRegister(regname, regvalue)
     local inst = mc.mcGetInstance()
     local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
     mc.mcRegSetValueString(hreg, tostring(regvalue))
    end
    
    local zLoc, xLoc, yLoc
    
    zLoc = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)   -- store the z loc
    WriteRegister("2025/TCZ", zLoc) 
    xLoc = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)   -- store the x loc
    WriteRegister("2025/TCX", xLoc)
    yLoc = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)   -- store the y loc
    WriteRegister("2025/TCY", yLoc)
    
    
    
    
    
    
end
-- tabOffsets-GlobalScript
function tabOffsets_On_Enter_Script(...)
    local FixOffset = mc.mcCntlGetPoundVar(inst, 4014)
    FixOffset = 53 + (FixOffset * 10)
    local Fixture = 54
    
    while (Fixture <= 59) do
        local state = "0"
        if (Fixture == FixOffset) then
            state = "1"
        end
        scr.SetProperty(string.format("tbtnG%.0f", Fixture), "Button State", state)
        Fixture = Fixture + 1
    end
    
end
-- grpEdgeFinding-GlobalScript
function droEdgeFinder_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    mc.mcProfileWriteString(inst, "PersistentDROs", "droEdgeFinder", string.format (val)) --Create a register and write to it
    return val
    
end
function btnYTop_Clicked_Script(...)
    -- Touch Y positive button
    local inst = mc.mcGetInstance()
    local EdgeFinder = scr.GetProperty("droEdgeFinder", "Value")
    EdgeFinder = tonumber(EdgeFinder)
    local YPos = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)
    XVar, YVar, ZVar = GetFixOffsetVars()
    local OffsetVal = YPos - (EdgeFinder/2)
    mc.mcCntlSetPoundVar(inst, YVar, OffsetVal)
    mc.mcCntlSetLastError(inst, string.format("Y Offset Set: %.4f", OffsetVal))
end
function btnXLeft_Clicked_Script(...)
    --Touch X negative button
    local inst = mc.mcGetInstance()
    local EdgeFinder = scr.GetProperty("droEdgeFinder", "Value")
    EdgeFinder = tonumber(EdgeFinder)
    local XPos = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)
    XVar, YVar, ZVar = GetFixOffsetVars()
    local OffsetVal = XPos + (EdgeFinder/2)
    mc.mcCntlSetPoundVar(inst, XVar, OffsetVal)
    mc.mcCntlSetLastError(inst, string.format("X Offset Set: %.4f", OffsetVal))
end
function btnYBottom_Clicked_Script(...)
    -- Touch Y negative button
    local inst = mc.mcGetInstance()
    local EdgeFinder = scr.GetProperty("droEdgeFinder", "Value")
    EdgeFinder = tonumber(EdgeFinder)
    local YPos = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)
    XVar, YVar, ZVar = GetFixOffsetVars()
    local OffsetVal = YPos + (EdgeFinder/2)
    mc.mcCntlSetPoundVar(inst, YVar, OffsetVal)
    mc.mcCntlSetLastError(inst, string.format("Y Offset Set: %.4f", OffsetVal))
end
function btnXRight_Clicked_Script(...)
    --Touch X positive button
    local inst = mc.mcGetInstance()
    local EdgeFinder = scr.GetProperty("droEdgeFinder", "Value")
    EdgeFinder = tonumber(EdgeFinder)
    local XPos = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)
    XVar, YVar, ZVar = GetFixOffsetVars()
    local OffsetVal = XPos - (EdgeFinder/2)
    mc.mcCntlSetPoundVar(inst, XVar, OffsetVal)
    mc.mcCntlSetLastError(inst, string.format("X Offset Set: %.4f", OffsetVal))
end
function btnSetCenter_Clicked_Script(...)
    --Set Center button
    local XPos = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)
    local YPos = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)
    XVar, YVar, ZVar = GetFixOffsetVars()
    mc.mcCntlSetPoundVar(inst, XVar, XPos)
    mc.mcCntlSetPoundVar(inst, YVar, YPos)
    mc.mcCntlSetLastError(inst, string.format("X Offset Set: %.4f | Y Offset Set: %.4f", XPos, YPos))
end
function tbtnG59_Down_Script(...)
    local set = 59
    mc.mcCntlMdiExecute(inst, string.format("G%.0f", set))
    local button = 54
    while (button <= 59) do
        if (button ~= set) then
            scr.SetProperty(string.format("tbtnG%.0f", button), "Button State", "0")
        end
        button = button + 1
    end
    mc.mcCntlSetLastError(inst, string.format("Fixture Offset Set: G%.0f", set))
end
function tbtnG54_Down_Script(...)
    local set = 54
    mc.mcCntlMdiExecute(inst, string.format("G%.0f", set))
    local button = 54
    while (button <= 59) do
        if (button ~= set) then
            scr.SetProperty(string.format("tbtnG%.0f", button), "Button State", "0")
        end
        button = button + 1
    end
    mc.mcCntlSetLastError(inst, string.format("Fixture Offset Set: G%.0f", set))
end
function tbtnG55_Down_Script(...)
    local set = 55
    mc.mcCntlMdiExecute(inst, string.format("G%.0f", set))
    local button = 54
    while (button <= 59) do
        if (button ~= set) then
            scr.SetProperty(string.format("tbtnG%.0f", button), "Button State", "0")
        end
        button = button + 1
    end
    mc.mcCntlSetLastError(inst, string.format("Fixture Offset Set: G%.0f", set))
end
function tbtnG56_Down_Script(...)
    local set = 56
    mc.mcCntlMdiExecute(inst, string.format("G%.0f", set))
    local button = 54
    while (button <= 59) do
        if (button ~= set) then
            scr.SetProperty(string.format("tbtnG%.0f", button), "Button State", "0")
        end
        button = button + 1
    end
    mc.mcCntlSetLastError(inst, string.format("Fixture Offset Set: G%.0f", set))
end
function tbtnG57_Down_Script(...)
    local set = 57
    mc.mcCntlMdiExecute(inst, string.format("G%.0f", set))
    local button = 54
    while (button <= 59) do
        if (button ~= set) then
            scr.SetProperty(string.format("tbtnG%.0f", button), "Button State", "0")
        end
        button = button + 1
    end
    mc.mcCntlSetLastError(inst, string.format("Fixture Offset Set: G%.0f", set))
end
function tbtnG58_Down_Script(...)
    local set = 58
    mc.mcCntlMdiExecute(inst, string.format("G%.0f", set))
    local button = 54
    while (button <= 59) do
        if (button ~= set) then
            scr.SetProperty(string.format("tbtnG%.0f", button), "Button State", "0")
        end
        button = button + 1
    end
    mc.mcCntlSetLastError(inst, string.format("Fixture Offset Set: G%.0f", set))
end
-- grpZOffset-GlobalScript
function droGageBlock_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageBlock", string.format (val)) --Create a register and write to it
    return val
    
end
function btnSetZ_Clicked_Script(...)
    -- Set Z button
    local inst = mc.mcGetInstance()			  
    local GageBlock = scr.GetProperty("droGageBlock", "Value")
    local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local CurH = mc.mcCntlGetPoundVar(inst, 2032) --Current Selected H Offset
    local CurHVal = mc.mcCntlGetPoundVar(inst, 2035) --Value of Current H Offset
    local OffsetState = mc.mcCntlGetPoundVar(inst, 4008) --Current Height Offset State
    if (OffsetState == 49) then
        CurHVal = 0
    end
    GageBlock = tonumber(GageBlock)
    local ZPos = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)
    XVar, YVar, ZVar = GetFixOffsetVars()
    local OffsetVal = ZPos - GageBlock - CurHVal
    mc.mcCntlSetPoundVar(inst, ZVar, OffsetVal)
    mc.mcCntlSetLastError(inst, string.format("Z Offset Set: %.4f", OffsetVal))
end
function btnHOActivate_Clicked_Script(...)
    --Toggle height offset button
    local HOState = mc.mcCntlGetPoundVar(inst, 4008)
    if (HOState == 49) then
        mc.mcCntlMdiExecute(inst, "G43")
    else
        mc.mcCntlMdiExecute(inst, "G49")
    end
end
-- grpToolOffset-GlobalScript
function btnSetZ_1__Clicked_Script(...)
    --Set Tool button
    local inst = mc.mcGetInstance()			  
    local GageBlock = scr.GetProperty("droGageBlockT", "Value")
    local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
    local OffsetState = mc.mcCntlGetPoundVar(inst, 4008) --Current Height Offset State
    mc.mcCntlGcodeExecuteWait(inst, "G49")
    GageBlock = tonumber(GageBlock)
    local ZPos = mc.mcAxisGetPos(inst, mc.Z_AXIS)
    local OffsetVal = ZPos - GageBlock
    mc.mcToolSetData(inst, mc.MTOOL_MILL_HEIGHT, CurTool, OffsetVal)
    mc.mcCntlSetLastError(inst, string.format("Tool %.0f Height Offset Set: %.4f", CurTool, OffsetVal))
    if (OffsetState ~= 49) then
        mc.mcCntlMdiExecute(inst, string.format("G%.1f", OffsetState))
    end
end
function droGageBlockT_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageBlockT", string.format (val)) --Create a register and write to it
    return val
    
end
-- tabEdit-GlobalScript
function tabEdit_On_Enter_Script(...)
    local inst = mc.mcGetInstance()
    local hSig = mc.mcSignalGetHandle(inst, mc.OSIG_RUNNING_GCODE);
    local sigState = mc.mcSignalGetState(hSig);
    
    if (sigState ~= 1) then 
    	scr.EditorLoadCurrent("Edit1")
    end
end
function tabEdit_On_Exit_Script(...)
    local inst = mc.mcGetInstance()
    local loadedName, rc = scr.EditorGetFileName("Edit1")
    if loadedName ~= "" then
    	scr.EditorSaveCurrent("Edit1")
    end
end
-- tabProbing-GlobalScript
-- tabPSingleSurf-GlobalScript
-- grpProbeY-GlobalScript
function droSurfYPos_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droSurfYPos", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droSurfYPos", string.format (val)) --Create a register and write the machine coordinates to it
    
end
function btnSurfY_Clicked_Script(...)
    --Single Surface Measure Y button
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local ypos = scr.GetProperty("droSurfYPos", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.SingleSurfY (ypos, work)
end
function btnSurfYHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.SingleSurfHelp()
    
end
-- grpProbeZ-GlobalScript
function droSurfZPos_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droSurfZPos", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droSurfZPos", string.format (val)) --Create a register and write to it
end
function btnSurfZ_Clicked_Script(...)
    --Single Surface Measure Z button
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local zpos = scr.GetProperty("droSurfZPos", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.SingleSurfZ (zpos, work)
end
function btnSurfZHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.SingleSurfHelp()
    
end
-- grpProbeX-GlobalScript
function droSurfXPos_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droSurfXPos", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droSurfXPos", string.format (val)) --Create a register and write the machine coordinates to it
    
end
function btnSurfX_Clicked_Script(...)
    --Single Surface Measure X button
    --PRIVATE
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    --Probing module
    package.loaded.Probing = nil
    
    local prb = require "mcProbing"
    
    local xpos = scr.GetProperty("droSurfXPos", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.SingleSurfX (xpos, work)
end
function btnSurfXHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.SingleSurfHelp()
    
end
-- tabCorners-GlobalScript
-- grpInsideCorner-GlobalScript
function droInCornerX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droInCornerX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droInCornerX", string.format (val)) --Create a register and write to it
end
function droInCornerY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droInCornerY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droInCornerY", string.format (val)) --Create a register and write to it
end
function droInCornerSpaceX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droInCornerSpaceX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droInCornerSpaceX", string.format (val)) --Create a register and write to it
end
function droInCornerSpaceY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droInCornerSpaceY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droInCornerSpaceY", string.format (val)) --Create a register and write to it
end
function btnInCorner_Clicked_Script(...)
    --Corners inner measure button
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local xpos = scr.GetProperty("droInCornerX", "Value")
    local ypos = scr.GetProperty("droInCornerY", "Value")
    local xinc = scr.GetProperty("droInCornerSpaceY", "Value")
    local yinc = scr.GetProperty("droInCornerSpaceX", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.InternalCorner (xpos, ypos, xinc, yinc, work)
end
function btnInCornerHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.InsideCornerHelp()
    
end
-- grpOutsideCorner-GlobalScript
function droOutCornerX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCornerX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCornerX", string.format (val)) --Create a register and write to it
end
function droOutCornerY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCornerY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCornerY", string.format (val)) --Create a register and write to it
end
function droOutCornerSpaceX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCornerSpaceX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCornerSpaceX", string.format (val)) --Create a register and write to it
end
function droOutCornerSpaceY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCornerSpaceY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCornerSpaceY", string.format (val)) --Create a register and write to it
end
function btnOutCorner_Clicked_Script(...)
    -- Outside corner Measure
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local xpos = scr.GetProperty("droOutCornerX", "Value")
    local ypos = scr.GetProperty("droOutCornerY", "Value")
    local xinc = scr.GetProperty("droOutCornerSpaceY", "Value")
    local yinc = scr.GetProperty("droOutCornerSpaceX", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.ExternalCorner (xpos, ypos, xinc, yinc, work)
    
end
function btnOutCornerHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.OutsideCornerHelp()
    
end
-- tabCentering-GlobalScript
-- grpInsideCenter-GlobalScript
function droInCenterWidth_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droInCenterWidth", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droInCenterWidth", string.format (val)) --Create a register and write to it
end
function btnInCenterX_Clicked_Script(...)
    -- Inside X centering
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local width = scr.GetProperty("droInCenterWidth", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.InsideCenteringX (width, work)
end
function btnInCenterY_Clicked_Script(...)
    -- Inside Y centering
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local width = scr.GetProperty("droInCenterWidth", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.InsideCenteringY (width, work)
end
function btnInCenterHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.InsideCenteringHelp()
    
end
-- grpOutsideCenter-GlobalScript
function droOutCenterWidth_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCenterWidth", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCenterWidth", string.format (val)) --Create a register and write to it
end
function droOutCenterAppr_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCenterAppr", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCenterAppr", string.format (val)) --Create a register and write to it
end
function droOutCenterZ_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droOutCenterZ", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droOutCenterZ", string.format (val)) --Create a register and write to it
end
function btnOutCenterX_Clicked_Script(...)
    -- Outside X centering
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local width = scr.GetProperty("droOutCenterWidth", "Value")
    local approach = scr.GetProperty("droOutCenterAppr", "Value")
    local zpos = scr.GetProperty("droOutCenterZ", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.OutsideCenteringX (width, approach, zpos, work)
end
function btnOutCenterY_Clicked_Script(...)
    -- Outside Y centering
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local width = scr.GetProperty("droOutCenterWidth", "Value")
    local approach = scr.GetProperty("droOutCenterAppr", "Value")
    local zpos = scr.GetProperty("droOutCenterZ", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.OutsideCenteringY (width, approach, zpos, work)
end
function btnOutCenterHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.OutsideCenteringHelp()
    
end
-- tabBoreBoss-GlobalScript
-- grpBore-GlobalScript
function droBoreDiam_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droBoreDiam", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droBoreDiam", string.format (val)) --Create a register and write to it
end
function btnBore_Clicked_Script(...)
    -- Bore Dia Measure
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local diam = scr.GetProperty("droBoreDiam", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.Bore (diam, work)
    
end
function btnInCornerHelp_1__Clicked_Script(...)
    local prb = require "mcProbing"
    prb.BoreHelp()
    
end
-- grpBoss-GlobalScript
function droBossDiam_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droBossDiam", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droBossDiam", string.format (val)) --Create a register and write to it
end
function droBossApproach_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droBossApproach", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droBossApproach", string.format (val)) --Create a register and write to it
end
function droBossZ_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droBossZ", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droBossZ", string.format (val)) --Create a register and write to it
end
function btnBoss_Clicked_Script(...)
    -- Boss Diam Measure
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local diam = scr.GetProperty("droBossDiam", "Value")
    local approach = scr.GetProperty("droBossApproach", "Value")
    local zpos = scr.GetProperty("droBossZ", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.Boss (diam, approach, zpos, work)
end
function btnInCornerHelp_2__Clicked_Script(...)
    local prb = require "mcProbing"
    prb.BossHelp()
    
end
-- tabAngle-GlobalScript
-- grpAngleX-GlobalScript
function droAngleXpos_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleXpos", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleXpos", string.format (val)) --Create a register and write to it
end
function droAngleYInc_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleYInc", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleYInc", string.format (val)) --Create a register and write to it
end
function droAngleXCenterX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleXCenterX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleXCenterX", string.format (val)) --Create a register and write to it
end
function droAngleXCenterY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleXCenterY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleXCenterY", string.format (val)) --Create a register and write to it
end
function btnAngleX_Clicked_Script(...)
    --Single Angle X
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
     
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local pos = scr.GetProperty("droAngleXpos", "Value")
    local inc = scr.GetProperty("droAngleYInc", "Value")
    local xcntr = scr.GetProperty("droAngleXCenterX", "Value")
    local ycntr = scr.GetProperty("droAngleXCenterY", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.SingleAngleX (pos, inc, xcntr, ycntr, work)
end
function btnAngleXHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.SingleAngleHelp()
    
end
-- grpAngleY-GlobalScript
function droAngleYpos_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleYpos", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleYpos", string.format (val)) --Create a register and write to it
end
function droAngleXInc_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleXInc", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleXInc", string.format (val)) --Create a register and write to it
end
function droAngleYCenterX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleYCenterX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleYCenterX", string.format (val)) --Create a register and write to it
end
function droAngleYCenterY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droAngleYCenterY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droAngleYCenterY", string.format (val)) --Create a register and write to it
end
function btnAngleY_Clicked_Script(...)
    --Single angle Y
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local pos = scr.GetProperty("droAngleYpos", "Value")
    local inc = scr.GetProperty("droAngleXInc", "Value")
    local xcntr = scr.GetProperty("droAngleXCenterX", "Value")
    local ycntr = scr.GetProperty("droAngleXCenterY", "Value")
    local work = scr.GetProperty("ledSetWork", "Value")
    
    prb.SingleAngleY (pos, inc, xcntr, ycntr, work)
end
function btnAngleYHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.SingleAngleHelp()
    
end
-- tabCalibration-GlobalScript
-- grpZCal-GlobalScript
function droCalZ_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droCalZ", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droCalZ", string.format (val)) --Create a register and write to it
end
function btnProbeCalZ_Clicked_Script(...)
    --Calibrate Z
    
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local zpos = scr.GetProperty("droCalZ", "Value")
    
    prb.LengthCal (zpos)
end
function btnCalZHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.LengthCalHelp()
end
-- grpXYRadCal-GlobalScript
function droGageX_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droGageX", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageX", string.format (val)) --Create a register and write to it
end
function droGageY_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droGageY", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageY", string.format (val)) --Create a register and write to it
end
function droGageZ_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droGageZ", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageZ", string.format (val)) --Create a register and write to it
end
function droGageSafeZ_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droGageSafeZ", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageSafeZ", string.format (val)) --Create a register and write to it
end
function droGageDiameter_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    
    local val = scr.GetProperty("droGageDiameter", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droGageDiameter", string.format (val)) --Create a register and write to it
end
function btnProbeCalXY_Clicked_Script(...)
    --Calibrate XY Offset
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local xpos = scr.GetProperty("droGageX", "Value")
    local ypos = scr.GetProperty("droGageY", "Value")
    local diam = scr.GetProperty("droGageDiameter", "Value")
    local zpos = scr.GetProperty("droGageZ", "Value")
    local safez = scr.GetProperty("droGageSafeZ", "Value")
    
    prb.XYOffsetCal (xpos, ypos, diam, zpos , safez) 
end
function btnProbeCalRad_Clicked_Script(...)
    --Calibrate Radius
    --PRIVATE
    
    inst = mc.mcGetInstance()
    local profile = mc.mcProfileGetName(inst)
    local path = mc.mcCntlGetMachDir(inst)
    
    package.path = path .. "\\Modules\\?.lua;" .. path .. "\\Profiles\\" .. profile .. "\\Modules\\?.lua;"
    
    --Master module
    package.loaded.MasterModule = nil
    mm = require "mcMasterModule"
    
    --Probing module
    package.loaded.Probing = nil
    local prb = require "mcProbing"
    
    local xpos = scr.GetProperty("droGageX", "Value")
    local ypos = scr.GetProperty("droGageY", "Value")
    local zpos = scr.GetProperty("droGageZ", "Value")
    local diam = scr.GetProperty("droGageDiameter", "Value")
    local safez = scr.GetProperty("droGageSafeZ", "Value")
    
    prb.RadiusCal (xpos, ypos, diam, zpos, safez)
end
function btnXYRadHelp__Clicked_Script(...)
    local prb = require "mcProbing"
    prb.XYRadCalHelp()
end
-- tabSettings-GlobalScript
function droPrbOffNum_On_Modify_Script(...)
    local val = scr.GetProperty("droPrbOffNum", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "OffsetNum", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: Offset number updated")
end
function droPrbGcode_On_Modify_Script(...)
    local val = scr.GetProperty("droPrbGcode", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "GCode", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: G code updated " .. val)
end
function droSlowFeed_On_Modify_Script(...)
    local val = scr.GetProperty("droSlowFeed", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "SlowFeed", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: Slow measure feedrate updated")
end
function droFastFeed_On_Modify_Script(...)
    local val = scr.GetProperty("droFastFeed", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "FastFeed", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: Fast find feedrate updated")
end
function droBackOff_On_Modify_Script(...)
    local val = scr.GetProperty("droBackOff", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "BackOff", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: Retract amount updated")
end
function droOverShoot_On_Modify_Script(...)
    local val = scr.GetProperty("droOverShoot", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "OverShoot", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: Overshoot amount")
end
function droPrbInPos_On_Modify_Script(...)
    local val = scr.GetProperty("droPrbInPos", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "InPosZone", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: In position tolerance updated")
end
function btnPrbSettingsHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.SettingsHelp()
end
function btnMeasType_Clicked_Script(...)
    --Set probing measurment type
    
    local inst = mc.mcGetInstance()
    local MeasureOnlyLED = scr.GetProperty("ledMeasOnly", "Value")
    
    if (MeasureOnlyLED == "1") then
        scr.SetProperty("ledMeasOnly", "Value", "0")
        scr.SetProperty("ledSetWork", "Value", "1")
    else
        scr.SetProperty("ledMeasOnly", "Value", "1")
        scr.SetProperty("ledSetWork", "Value", "0")
    end
end
-- grpProbeResults-GlobalScript
function btnResultsHelp_Clicked_Script(...)
    local prb = require "mcProbing"
    prb.ResultsHelp()
end
-- nbpEngrave-GlobalScript
-- grpEngrave-GlobalScript
function TextInput_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    if (val == nil) then
    	return
    else
    	mc.mcProfileWriteString(inst, sec, "Text", tostring(val))
    end
    _G.Text = tostring(val)
    return val
end
function ZerosDRO_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    mc.mcProfileWriteString(inst, sec, "SerialNumbers", tostring(val))
    _G.SN = val;
    return val
    
end
function CreateCodeBTN_Clicked_Script(...)
    -- call the code to crreate the Gcode
    function GetProps()
    	local EngData = mcEng.CreateEngData()
    	EngData.Text = 							scr.GetProperty("TextInput", "Value")			  
    	EngData.Inc = 							scr.GetProperty("IncAmmountDRO", "Value")		
    	EngData.Zeros =  						scr.GetProperty("ZerosDRO", "Value")			
    	EngData.Tags =							scr.GetProperty("TagsToMakeDRO", "Value")		
    	EngData.SN =							scr.GetProperty("CurrentSNDRO", "Value")		
    	EngData.AutoSN =						scr.GetProperty("AutoSN", "Button State") 		
    	EngData.TagCounter =					scr.GetProperty("TagCounterDRO", "Value")		
    	EngData.Charspace =						scr.GetProperty("CharspaceDRO", "Value")		
    	EngData.CutDepth =						scr.GetProperty("CutDepthDRO", "Value")			
    	EngData.Traverse =						scr.GetProperty("TraverseHeightDRO", "Value")	
    	EngData.TextHeight =					scr.GetProperty("TextHeightDRO", "Value")		
    	EngData.Digits = 						scr.GetProperty("DigitsDRO", "Value")			
    	EngData.PlungeF = 						scr.GetProperty("PlungeFeedRateDRO", "Value")	
    	EngData.CutF = 							scr.GetProperty("CutFeedRateDRO", "Value")		
    	EngData.RPM = 							scr.GetProperty("RPMDRO", "Value")				
    	--Arc Settings Below	
    	EngData.ArcSettings.Center.x = 			scr.GetProperty("XArcCenterDRO", "Value")		
    	EngData.ArcSettings.Center.y =  		scr.GetProperty("YArcCenterDRO", "Value")		
    	EngData.ArcSettings.Angle = 			scr.GetProperty("ArcAngleDRO", "Value")				
    	EngData.ArcSettings.Radius = 			scr.GetProperty("RadiusOfArcDRO", "Value")		
    	return EngData
    end
    
    
    
    
    local EngData = GetProps()
    local TotalTags = scr.GetProperty("TagsToMakeDRO", "Value")
    local TagCounter = scr.GetProperty("TagCounterDRO", "Value")
    local autosn = scr.GetProperty("AutoSN", "Button State")          --Here
    if (TotalTags == TagCounter) and (tonumber(autosn) == 1)then      --Here
    	
    	mc.mcCntlSetLastError(inst, "Tag Batch Finished")
    else
    	if(mcEng.CreateGcode ~= nil)then
    		local EngData = GetProps()
    		local DoList = scr.GetProperty("List_Text_tog", "Button State");
    		local str = ""
    		if(tonumber(DoList) == 0) then 
    			scr.SetProperty("QueueList","Selected","0")-- move the line to the top
    			str = scr.GetProperty("QueueList", "Value");
    			local liststring = scr.GetProperty("QueueList", "Strings")
    			local strend = string.find(liststring,"|")
    			if(strend == nil)then strend = string.len(liststring) end 
    			liststring =  string.sub(liststring, strend+1 )
    			scr.SetProperty("QueueList", "Strings", liststring);
    			scr.SetProperty("QueueList","Selected","0")-- move the line to the top
    		else
    			str = scr.GetProperty("TextInput", "Value");
    		end 
    		if(str ~= nil)then 
    			mcEng.CreateGcode(tostring(str),EngData)
    		else 
    			mc.mcCntlSetLastError(mc.mcGetInstance(),"STR == Nil")
    		end 
    	else 
    		mc.mcCntlSetLastError(mc.mcGetInstance(),"Fail!!!!")
    	end
    	mcEng.SaveParams()
    end
end
function tmrCutMode_Timer_Event_Script(...)
    if (_G.ctypebuttons == nil) then
    	_G.ctypebuttons = {[1] = "CutTypeV0", [2] = "CutTypeV90", [3] = "CutTypeV180", [4] = "CutTypeH0", [5] = "CutTypeH90", [6] = "CutTypeH180", [7] = "CutTypeH270", [8] = "CutTypeV270", [9] = "CutTypeArc"}
    end
    local validBtn = "none"
    local cytpebuttons = _G.cytpebuttons
    for _,btnName in ipairs(ctypebuttons) do
    	local isOn = scr.GetProperty(tostring(btnName),"Button State")
    	if(tonumber(isOn) == 1) then
    		validBtn = btnName
    	end
    end
    if(validBtn == "none")then 
    	if (_G.CutType == nil) then
    		_G.CutType = 'CutTypeH0'
    	end
    	scr.SetProperty(tostring(_G.CutType),"Button State", '1')
    	
    end
end
function CurrentSNDRO_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    mc.mcProfileWriteString(inst, sec, "SerialNumbers", tostring(val))
    _G.SN = val;
    return val
    
end
function IncAmmountDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function TagsToMakeDRO_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = select(1,...) -- Get the user supplied value.
    scr.SetProperty("TagCounterDRO", "Value", tostring(0))
    return val
end
function TagCounterDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function TextHeightDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function CharspaceDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function CutDepthDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function TraverseHeightDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function XArcCenterDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function YArcCenterDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function ArcAngleDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function RadiusOfArcDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function PlungeFeedRateDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function CutFeedRateDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function RPMDRO_On_Modify_Script(...)
    local val = select(1,...)
    return val
end
function CutTypeV180_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeV180')
    _G.CutType = 'CutTypeV180'
end
function CutTypeV90_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeV90')
    _G.CutType = 'CutTypeV90'
end
function CutTypeV270_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeV270')
    _G.CutType = 'CutTypeV270'
end
function CutTypeV0_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeV0')
    _G.CutType = 'CutTypeV0'
end
function CutTypeH90_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeH90')
    _G.CutType = 'CutTypeH90'
end
function CutTypeH180_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeH180')
    _G.CutType = 'CutTypeH180'
    
end
function CutTypeH0_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeH0')
    _G.CutType = 'CutTypeH0'
    
end
function CutTypeH270_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeH270')
    _G.CutType = 'CutTypeH270'
end
function btnLoadSettings_Clicked_Script(...)
    mcEng.ReadSettingsfile("txt")    --Load Settings button
end
function btnExportSettings_Clicked_Script(...)
    local EngData = mcEng.GetProps()
    mcEng.SaveTableToFile("Settings.txt", EngData) --Export settings button
end
function List_Text_tog_Down_Script(...)
    local inst = mc.mcGetInstance()
    scr.SetProperty('btnLoadTXT', 'Enabled', '0')
    mc.mcCntlSetLastError(inst, 'Engrave Text Mode')
end
function List_Text_tog_Up_Script(...)
    local inst = mc.mcGetInstance()
    scr.SetProperty('btnLoadTXT', 'Enabled', '1')
    scr.SetProperty('TextInput', 'Value', '')
    mc.mcCntlSetLastError(inst, 'Engrave List Mode')
end
function CutTypeArc_Down_Script(...)
    mcEng.SetEngraveCutType('CutTypeArc')
end
function btnLoadTXT_Clicked_Script(...)
    local inst = mc.mcGetInstance()
    if scr.GetProperty('btnLoadTXT', 'Label') == "Load CSV Sheet" then
    scr.SetProperty('btnLoadTXT', 'Label', "Load TXT Sheet")
    mcEng.readCSVfile("txt")
    mc.mcCntlSetLastError(inst, 'TXT file loaded')
    else
    scr.SetProperty('btnLoadTXT', 'Label', "Load CSV Sheet")
    mcEng.readCSVfile("csv")
    mc.mcCntlSetLastError(inst, 'CSV file loaded')
    end
end
-- nbpSurfaceMap-GlobalScript
function checkmaps(action)
	local inst = mc.mcGetInstance("SMap list pop")
	local MapNumber = {}	--Might not want this to be local... but I guess I'll pass the info 
	local selected = scr.GetProperty("lst(Maps)", "Selected") -- Let's get the selected list entity in case we need it
	local reg = mc.mcRegGetHandle(inst, "mcSurfaceMap0/smCommand")
	resp, rc = mc.mcRegSendCommand(reg, "GET MAP LIST") --Grab the list of .dat files in the curr dir
	local tkz = wx.wxStringTokenizer(resp, ("\n"));	--Makes a token for each segment ending in \n
	local i = 0 -- Counter
	rc = scr.SetProperty("lst(Maps)","Strings","") --CLEAR LIST BEFORE WE WRITE TO IT
	--The below function will update the maps list. I need to do it before and after an operation... so that's what we're gonna do
	function updatelist(tkz)
		rc = scr.SetProperty("lst(Maps)","Strings","") --CLEAR LIST BEFORE WE WRITE TO IT
		resp, rc = mc.mcRegSendCommand(reg, "GET MAP LIST") --Grab the list of .dat files in the curr dir
		tkz = wx.wxStringTokenizer(resp, ("\n"));	--Makes a token for each segment ending in \n
		while (tkz:HasMoreTokens()) do	--While we have more tokens, do this WORK
			local token = tkz:GetNextToken()
			local start, finish = string.find(tostring(token), ",1") --Here we're looking if the string has a ,1... if it does it's active
			--"C:\\Mach4Hobby4866\\Profiles\\Mach4Mill\\zLevelMap0.dat,1\nC:\\Mach4Hobby4866\\Profiles\\Mach4Mill\\zLevelMap1.dat,1\n
			if (start ~= nil) then
				local new = string.gsub(tostring(token) , ",1", "") --Now I remove the ,1 or ,0 from the file name and put in table.
				new = "ACTIVE -" .. tostring(new)
				MapNumber[tostring(i)] = tostring(new)
				local currcontent = scr.GetProperty("lst(Maps)", "Strings")
					if (currcontent == "") then
						newcontent = tostring(new) .. "|"
					else
						newcontent = tostring(currcontent) .. "|" .. tostring(new) .. "|"
					end
				rc = scr.SetProperty("lst(Maps)", "Strings", newcontent)
			else
				local new = string.gsub(tostring(token) , ",0", "") --Now I remove the ,1 or ,0 from the file name and put in table.
				if (new == "p") then
					return
				end
				new = "INACTIVE -" .. tostring(new)
				MapNumber[tostring(i)] = tostring(new)
				local currcontent = scr.GetProperty("lst(Maps)", "Strings")
					if (currcontent == "") then
						newcontent = tostring(new) .. "|"
					else
						newcontent = tostring(currcontent) .. "|" .. tostring(new) .. "|"
					end
						rc = scr.SetProperty("lst(Maps)", "Strings", newcontent)
			end
			i = i + 1
		end
	end
	updatelist(tkz) --UPDATE LIST EVERY TIME WE CALL THIS FUNCTION
	
		if (action == "enable") and (tostring(selected) ~= "-1") then	--IF ENABLE IS ACTION
			--Here we're going to get the selected string from the map list and enable (or disable) it
			--and we already have the map data because we ran this func
			--now with the selected number I can check the map list and see if it's "ACTIVE"
			str = MapNumber[tostring(selected)] --This is the map number as well...
			start, finish = string.find(tostring(str), "INACTIVE") --Here we're looking if the string says active
			if (start ~= nil) then 
				--We have to activate the map
				selected = tonumber(selected) + 1
				resp, rc = mc.mcRegSendCommand(reg, "SET MAP " .. tostring(selected) .. " ENABLED") --Grab the list of .dat files in the curr dir
				updatelist(tkz) -- NOW UPDATE LIST AGAIN TO SHOW WE ACTIVATED IT
			else
				--Leave it alone
				return
			end
		elseif (action == "disable") and (tostring(selected) ~= "-1") then			--IF DISABLE IS ACTION
			str = MapNumber[tostring(selected)] --This is the map number as well...
			start, finish = string.find(tostring(str), "INACTIVE") --Here we're looking if the string says active
			if (start == nil) then 
				--We have to activate the map
				selected = tonumber(selected) + 1
				resp, rc = mc.mcRegSendCommand(reg, "SET MAP " .. tostring(selected) .. " DISABLED") --Grab the list of .dat files in the curr dir
				updatelist(tkz) -- NOW UPDATE LIST AGAIN TO SHOW WE ACTIVATED IT
			else
				return
			end
		end
		rc = scr.SetProperty("lst(Maps)","Selected", tostring(selected))
	return maps
end
function nbpSurfaceMap_On_Enter_Script(...)
    --scr.SetProperty("lst(Maps)", "Strings", "")
end
function btnMapEnable_Clicked_Script(...)
    checkmaps("enable")
    
end
function btnDisableMap_Clicked_Script(...)
    checkmaps("disable")
end
function tmr_SMap__Timer_Event_Script(...)
    checkmaps(action)
end
-- tabTrace-GlobalScript
_G.ContinueTrace = false -- for resuming coroutine
_G.DialogReturn = nil
function _G.CheckCoroutine()
	if _G.CoroutineFuntion ~= nil then
		_G.Coroutine = coroutine.create(_G.CoroutineFuntion)
		_G.CoroutineFuntion = nil
		_G.ContinueTrace = false
		coroutine.resume(_G.Coroutine)
	end
	--if a button was pressed, and coroutiune is suspened
	if _G.Coroutine ~= nil then
		if coroutine.status(_G.Coroutine) == 'suspended' then
			if _G.ContinueTrace == true then
				_G.ContinueTrace = false
				coroutine.resume(_G.Coroutine)
			end
		elseif coroutine.status(_G.Coroutine) == "dead" then
			_G.Coroutine = nil
		end
	end
end
function tabTrace_On_Enter_Script(...)
    _G.TraceEntered = true
end
function tabTrace_On_Exit_Script(...)
    _G.TraceEntered = false
end
function btnTrace1_Clicked_Script(...)
    --mobdebug.start()
    _G.TraceEntered = true
    mcTrace.BeginTrace()
end
function btnTrace9_Clicked_Script(...)
    mcTrace.ReturnToFirst()
end
function tog_20__Down_Script(...)
    trace.materialheighton()
end
function tog_20__Up_Script(...)
    trace.materialheightoff()
end
function btnTrace10_Clicked_Script(...)
    mcTrace.ReturnToPrev()
end
function btn_87__Clicked_Script(...)
    mcTrace.setwork()
end
function btnTrace1File_Clicked_Script(...)
    local inst = mc.mcGetInstance()
    local file = wx.wxFileDialog(wx.NULL, "Select File From Intermediary Directory", "", "", "Text files (*.txt)|*.txt|", 
    							  wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST,wx.wxDefaultPosition,wx.wxDefaultSize, "Select Trace File" );
    if (file:ShowModal() == wx.wxID_OK ) then
    	local path = file:GetPath()
    	if path ~= nil then
    		_G.TraceEntered = true
    		mcTrace.BeginTrace(path)
    	end
    end
end
-- grp(24)-GlobalScript
function btnTrace7_Clicked_Script(...)
    mcTrace.Point()
    
    
end
function btnTrace3_Clicked_Script(...)
    mcTrace.RapidEndPoint()
    
    
end
function btnTrace2_Clicked_Script(...)
    mcTrace.LineEndPoint()
end
function btnTrace4_Clicked_Script(...)
    mcTrace.ArcPoint()
end
function btnTrace8_Clicked_Script(...)
    mcTrace.ArcPointCenter()
end
function btnTrace5_Clicked_Script(...)
    --local debug = true
    
    _G.CoroutineFuntion = mcTrace.Circle2Point
end
function btnTrace6_Clicked_Script(...)
    --local debug = true
    _G.CoroutineFuntion = mcTrace.Circle3Point
end
function btnEditPoints_Clicked_Script(...)
    local wizard = "\\Wizards\\PointWizard.mcc"
    local inst = mc.mcGetInstance()
    local path, rc = mc.mcCntlGetMachDir(inst)
    local exepath = path .. wizard
    dofile(exepath)
    
end
-- PlateAlign(3)-GlobalScript
function btn_97__Clicked_Script(...)
    local xTarget = scr.GetProperty("XTargetDRO", "Value")
    local yTarget = scr.GetProperty("YTargetDRO", "Value")
    local zTarget = scr.GetProperty("ZTargetDRO", "Value")
    local Incremental = scr.GetProperty("IncBtn", "Button State")
    local inst = mc.mcGetInstance()
    local x = mc.mcAxisGetPos(inst, mc.X_AXIS)
    local y = mc.mcAxisGetPos(inst, mc.Y_AXIS)
    local z = mc.mcAxisGetPos(inst, mc.Z_AXIS)
    if Incremental == nil then return end
    local mdiString = "G9" .. Incremental .. " G00 "
    	if (x ~= xTarget or Incremental == "1") and tonumber(xTarget) ~= nil then
    		mdiString = mdiString .. string.format("X%.4f ", tonumber(xTarget))	
    	end
    	if (y ~= yTarget or Incremental == "1") and tonumber(yTarget) ~= nil then
    		mdiString = mdiString .. string.format("Y%.4f ", tonumber(yTarget))	
    	end
    	if (z ~= zTarget or Incremental == "1") and tonumber(zTarget) ~= nil then
    		mdiString = mdiString .. string.format("Z%.4f ", tonumber(zTarget))	
    	end
    	if mdiString ~= "G9" .. Incremental .. " G00 " then
    		mdiString = mdiString .. string.format("F%.1f", scr.GetProperty("slideFRO", "Value"))
    		mc.mcCntlGcodeExecute(inst, mdiString)
    	end
    
end
-- PlateAlign(3)-GlobalScript
function btnTrace11_Clicked_Script(...)
    mcTrace.RemoveLastElement()
end
function btn_99__Clicked_Script(...)
    local inst = mc.mcGetInstance();
    local path, rc = mc.mcCntlGetMachDir(inst)
    local fileName = "TraceGuide.pdf"
    local cmd = path .. "\\Docs\\" .. fileName
    if(wx.wxFileExists(cmd))then
    	os.execute(cmd)
    else
    	mc.mcCntlSetLastError(inst, "Missing file: " .. fileName)
    end
end
-- grp(27)-GlobalScript
function tmr_5__Timer_Event_Script(...)
    if _G.TraceEntered == true then
    	_G.CheckCoroutine()
    end
end
function tmr_6__Timer_Event_Script(...)
    scr.SetProperty("btnTrace1", "Label", "Start Trace")
    scr.SetProperty("btnTrace1", "Enabled", "1")
    scr.SetProperty("btnTrace1File", "Enabled", "1")
    scr.SetProperty("btnEditPoints", "Enabled", "1")
    scr.SetProperty("btnTrace4", "Label", "Filet Mid Point")
    scr.SetProperty("btnTrace8", "Label", "Arc Center Point")
    for i = 2, 11, 1 do
    	local btn = "btnTrace" .. tostring(i)
    	scr.SetProperty(btn, "Enabled", "0")
    end
    local inst = mc.mcGetInstance()
    
    local x = mc.mcAxisGetPos(inst, mc.X_AXIS)
    local y = mc.mcAxisGetPos(inst, mc.Y_AXIS)
    local z = mc.mcAxisGetPos(inst, mc.Z_AXIS)
    local xTarget = scr.SetProperty("XTargetDRO", "Value", tostring(x))
    local yTarget = scr.SetProperty("YTargetDRO", "Value", tostring(y))
    local zTarget = scr.SetProperty("ZTargetDRO", "Value", tostring(z))
    local units = mc.mcCntlGetUnitsDefault(inst)
    	local hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/TRC/cutDepth")
    	mc.mcRegSetValue(hReg, 0)
    	hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/TRC/materialTop")
    	mc.mcRegSetValue(hReg, 0)
    	hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/TRC/totalDepth")
    	mc.mcRegSetValue(hReg, 0)
    	hReg = mc.mcRegGetHandle(inst, "iRegs0/nf/TRC/safeZ")
    	if units == 200 then -- inches
    		mc.mcRegSetValue(hReg, .25)
    	else --mm
    		mc.mcRegSetValue(hReg, 5)
    	end
    	
end
-- tabVision-GlobalScript
_G.UpdateCount = 0
function tabVision_On_Enter_Script(...)
    local rc;
    local tabG_Mdi, rc = scr.GetProperty("nbGCodeMDI1", "Current Tab")
    
    --See if we have to do an MDI command
    if (tonumber(tabG_Mdi) == 1 ) then
        scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nMDI');
    else
        scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nGcode');
    end
end
-- nbpagevisDRO-GlobalScript
-- grpM4Vision-GlobalScript
-----------------------------------------------------------
--Create Registers for the wear offstes table
-----------------------------------------------------------
local inst = mc.mcGetInstance()
	if (scr == nil) then
		scr = require('screenipc')
	end
	
	if mcReg == nil then
		mcReg = require('mcRegister')
	end
	
	local inst = mc.mcGetInstance()
	local msg = ""
	local loopCount = 0
	local mode = 0
	------------------------------------------------
	--Offset Reg Table
	------------------------------------------------
	local VisionTBL = {--Table format: {"name", "description", initialval, persistent, value}
		--Unit dependent We will adjust these depending on Machine units and Gcode units (G20/21)
		--{"Bogus", "Description.", 5.0, 1, 0},
		{"MacrosLoaded", "AreMacrosLoaded", 0, 1, 0},
		{"circlesize", "SizeOfCircle", 0, 1, 0},
		{"circlerange", "RangeOfCircle", 0, 1, 0},
		{"FindCenter", "FindTheCenter", 0, 1, 0},
		{"CycleStart", "CycleStart", 0, 1, 0}
}
	--------------------------------------------
	--Build Offset Registers
	--------------------------------------------
	--if (mode == 0) then
	rc = mcReg.doRegTable(inst, "ADD", VisionTBL, "iRegs0", "") --Instacne, Mode (DEL or ADD), Table, Device, Group This will create or delete all the registers in thcRegTbl if they don't exist in the profile
	if (rc ~= 0) then
		msg = mc.mcCntlGetErrorString(inst, rc) --Get the returned error string
		errorOut(msg)
	end	
	--local HREg = mc.mcRegGetHandle(inst, "iRegs0/nf/OtableXwear")
	--	mc.mcRegSetValue(HREg, 1)
function btnVSNena_Clicked_Script(...)
    inst = mc.mcGetInstance()
    rc = scr.VisionSetMode("MyVid", scr.VISION_CIRCLE)
    rc = mc.mcCntlSetLastError(inst, "Vision Enabled")  
end
function btn_411__Clicked_Script(...)
    inst = mc.mcGetInstance()
    scr.VisionSetMode("MyVid", scr.VISION_NONE)
    mc.mcCntlSetLastError(inst, "Vision Disabled")  
end
function btnJogReset_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    rc = mc.mcJogSetRate(inst, mc.X_AXIS, 100)
    rc = mc.mcJogSetRate(inst, mc.Y_AXIS, 100)
    rc = mc.mcJogSetRate(inst, mc.Z_AXIS, 100)
end
function btnAutoFind_Left_Down_Script(...)
    FindCenterNow = true
    local hreg ,rc = mc.mcRegGetHandle(mc.mcGetInstance(), 'iRegs0/FindCenter')
    local val, rc = mc.mcRegGetValue(hreg)
    if (val == 1) then
    	local rc = mc.mcRegSetValue(hreg, 0)
    else
    	local rc = mc.mcRegSetValue(hreg, 1)
    end
    
    
end
function btnsizedown_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    local hReg = mc.mcRegGetHandle(inst, 'iRegs0/circlesize')
    local regval = mc.mcRegGetValue(hReg)
    local newval = (regval - 1)
    mc.mcRegSetValue(hReg, newval)
end
function btnszUp_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    local hReg = mc.mcRegGetHandle(inst, 'iRegs0/circlesize')
    local regval = mc.mcRegGetValue(hReg)
    local newval = (regval + 1)
    mc.mcRegSetValue(hReg, newval)
end
function btnRngDn_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    local hReg = mc.mcRegGetHandle(inst, 'iRegs0/circlerange')
    local regval = mc.mcRegGetValue(hReg)
    local newval = (regval - 1)
    mc.mcRegSetValue(hReg, newval)
end
function btnRngUp_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    local hReg = mc.mcRegGetHandle(inst, 'iRegs0/circlerange')
    local regval = mc.mcRegGetValue(hReg)
    local newval = (regval + 1)
    mc.mcRegSetValue(hReg, newval)
end
-- tabSettings2025-GlobalScript
function droYPlate_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droXPlate_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst,rc = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droParkLocZ_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droParkLocX_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droParkLocY_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droPlateThickness_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droTCX_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droTCY_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droTCZ_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droXLaserOffset_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droYLaserOffset_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droMaterialOffset_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function tbtnIgnoreM6_Down_Script(...)
    local val = 1
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/IgnoreM6')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
    
end
function tbtnIgnoreM6_Up_Script(...)
    local val = 0
    local inst
    inst = mc.mcGetInstance()
    local hreg = mc.mcRegGetHandle(inst, 'iRegs0/2025/IgnoreM6')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droPrbToUse_On_Modify_Script(...)
    local val = scr.GetProperty("droPrbGcode", "Value")
    mc.mcProfileWriteString(inst, "ProbingSettings", "GCode", tostring(val))
    mc.mcCntlSetLastError(inst, "Probe: G code updated " .. val)
end
function tbtnUseMachineCoord_Down_Script(...)
    local val = 1
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseMachineCoord')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
    
    
end
function tbtnUseMachineCoord_Up_Script(...)
    local val = 0
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseMachineCoord')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function tbtnUseMaterrialOffset_Down_Script(...)
    local val = 1
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseMatOffset')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
    
end
function tbtnUseMaterrialOffset_Up_Script(...)
    local val = 0
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseMatOffset')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function droZPlane_On_Update_Script(...)
    local val = select(1,...) -- Get the system value.
    local inst = mc.mcGetInstance()
    val = tonumber(val) -- The value may be a number or a string. Convert as needed.
    DecToFrac(0)
    --local val = scr.GetProperty("droZPlane", "Value")
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
function tbtnUseSafeZ_1__Down_Script(...)
    local val = 1
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseSafeZ')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
    
end
function tbtnUseSafeZ_1__Up_Script(...)
    local val = 0
    local inst
    local rc
    inst = mc.mcGetInstance()
    local hreg,rc = mc.mcRegGetHandle(inst, 'iRegs0/2025/UseSafeZ')
    rc = mc.mcRegSetValueLong(hreg, val)
    return val -- the script MUST return a value, otherwise, the control will not be updated.
end
-- tabDiag-GlobalScript
function tabDiag_On_Enter_Script(...)
    local rc;
    local tabG_Mdi, rc = scr.GetProperty("nbGCodeMDI2", "Current Tab")
    
    --See if we have to do an MDI command
    if (tonumber(tabG_Mdi) == 1 ) then
        scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nMDI');
    else
        scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nGcode');
    end
end
-- grpHoming-GlobalScript
function btnRefAllDiag_Left_Up_Script(...)
    --RefAllHome()
    wait = coroutine.create (RefAllHome) --Run the RefAllHome function as a coroutine named wait.
    --See RefAllHome function in screen load script for coroutine.yield and PLC script for coroutine.resume
end
function btnRefX_Left_Up_Script(...)
    --local inst = mc.mcGetInstance ()
    --mc.mcCntlGcodeExecuteWait(inst, 'M07')
    --mc.mcAxisHome(inst, 0)
    --repeat
    --wx.wxMilliSleep(200)
    --local homing, rc= mc.mcAxisIsHoming(inst, 0)
    --until homing == 0
    --mc.mcCntlGcodeExecuteWait(inst, 'M09')
    
end
-- Digital Readouts-GlobalScript
-- Input Signals-GlobalScript
-- Output Signals-GlobalScript
-- Spindle Diagnostics-GlobalScript
-- nbGCodeInput2-GlobalScript
function nbGCodeInput2_On_Enter_Script(...)
     scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nGcode');
end
-- nbMDIInput2-GlobalScript
function nbMDIInput2_On_Enter_Script(...)
    scr.SetProperty('btnCycleStart', 'Label', 'Cycle Start\nMDI');
end
-- ControlGroup-GlobalScript
function btnCycleStart_Left_Up_Script(...)
    CycleStart()
end
function btnStop_Left_Up_Script(...)
    CycleStop()
end
function btnReset_Left_Up_Script(...)
    local inst = mc.mcGetInstance()
    mc.mcCntlReset(inst)
    mc.mcSpindleSetDirection(inst, 0)
    mc.mcCntlSetLastError(inst, '')
end
-- grpFeedRate-GlobalScript
function btnFROMax_Left_Up_Script(...)
    local maxval = scr.GetProperty('slideFRO', 'Max Value')
    scr.SetProperty('slideFRO', 'Value', tostring(maxval));
end
function btnFROUp_Left_Up_Script(...)
    local val = scr.GetProperty('slideFRO', 'Value');
    val = tonumber(val) + 10;
    local maxval = scr.GetProperty('slideFRO', 'Max Value')
    if (tonumber(val) >= tonumber(maxval)) then
     val = maxval;
    end
    scr.SetProperty('slideFRO', 'Value', tostring(val));
end
function btnFRO100_Left_Up_Script(...)
    scr.SetProperty('slideFRO', 'Value', tostring(100));
end
function btnFROMin_Left_Up_Script(...)
    --scr.SetProperty('slideFRO', 'Value', tostring(0));
    local minval = scr.GetProperty('slideFRO', 'Min Value')
    scr.SetProperty('slideFRO', 'Value', tostring(minval));
end
function btnFRODn_Left_Up_Script(...)
    --local val = scr.GetProperty('slideFRO', 'Value');
    --val = tonumber(val) - 10;
    --if (val < 0 ) then
    --    val =0;
    --end
    --scr.SetProperty('slideFRO', 'Value', tostring(val));
    -- Down
    local val = scr.GetProperty('slideFRO', 'Value');
    val = tonumber(val) - 10;
    local minval = scr.GetProperty('slideFRO', 'Min Value')
    if (tonumber(val) <= tonumber(minval)) then
     val = minval;
    end
    scr.SetProperty('slideFRO', 'Value', tostring(val));
end
-- grpRapid Rate-GlobalScript
function btnRROMax_Left_Up_Script(...)
    --Max
    local maxval = scr.GetProperty('slideRRO', 'Max Value')
    scr.SetProperty('slideRRO', 'Value', tostring(maxval));
end
function btnRROUp_Left_Up_Script(...)
    -- Up
    local val = scr.GetProperty('slideRRO', 'Value');
    val = tonumber(val) + 10;
    local maxval = scr.GetProperty('slideRRO', 'Max Value')
    if (tonumber(val) >= tonumber(maxval)) then
     val = maxval;
    end
    scr.SetProperty('slideRRO', 'Value', tostring(val));
end
function btnRRO50_Left_Up_Script(...)
    -- 50
    scr.SetProperty('slideRRO', 'Value', tostring(50));
end
function btnRROMin_Left_Up_Script(...)
    -- Min
    local minval = scr.GetProperty('slideRRO', 'Min Value')
    scr.SetProperty('slideRRO', 'Value', tostring(minval));
end
function btnRRODn_Left_Up_Script(...)
    -- Down
    local val = scr.GetProperty('slideRRO', 'Value');
    val = tonumber(val) - 10;
    local minval = scr.GetProperty('slideRRO', 'Min Value')
    if (tonumber(val) <= tonumber(minval)) then
     val = minval;
    end
    scr.SetProperty('slideRRO', 'Value', tostring(val));
end
-- grpSpindle-GlobalScript
function btnSROMax_Left_Up_Script(...)
    --Max
    local maxval = scr.GetProperty('slideSRO', 'Max Value')
    scr.SetProperty('slideSRO', 'Value', tostring(maxval));
end
function btnSROUp_Left_Up_Script(...)
    -- Up
    local val = scr.GetProperty('slideSRO', 'Value');
    val = tonumber(val) + 10;
    local maxval = scr.GetProperty('slideSRO', 'Max Value')
    if (tonumber(val) >= tonumber(maxval)) then
     val = maxval;
    end
    scr.SetProperty('slideSRO', 'Value', tostring(val));
end
function btnSRO100_Left_Up_Script(...)
    -- 100
    scr.SetProperty('slideSRO', 'Value', tostring(100));
end
function btnSROMin_Left_Up_Script(...)
    -- Min
    local minval = scr.GetProperty('slideSRO', 'Min Value')
    scr.SetProperty('slideSRO', 'Value', tostring(minval));
end
function btnSRODn_Left_Up_Script(...)
    -- Down
    local val = scr.GetProperty('slideSRO', 'Value');
    val = tonumber(val) - 10;
    local minval = scr.GetProperty('slideSRO', 'Min Value')
    if (tonumber(val) <= tonumber(minval)) then
     val = minval;
    end
    scr.SetProperty('slideSRO', 'Value', tostring(val));
end
function btnSpindleCW_Left_Up_Script(...)
    SpinCW()
end
function btnSpindleCCW_Left_Up_Script(...)
    SpinCCW()
end
-- tabFileOps-GlobalScript
function btnHelpDocs_Left_Up_Script(...)
    OpenDocs()
    --local inst = mc.mcGetInstance()
    --local dir = mc.mcCntlGetMachDir(inst);
    --wx.wxExecute("explorer.exe /open," .. dir .. "\\Docs\\");
    
end
function btnEditGcode_Clicked_Script(...)
    scr.SetProperty("MainTabs", 'Current Tab', tostring(3))
end
-- tabRunOps-GlobalScript
function btnMist_1__Clicked_Script(...)
    -- Vaccum table button script
    -- M112/M113 Output 51 signal 1101
    
    inst = mc.mcGetInstance()
    
    local hSig, rc = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT51)
    local state, rc = mc.mcSignalGetState(hSig)
    
    if state == 1 then
        mc.mcSignalSetState(hSig, 0)
    else
        mc.mcSignalSetState(hSig, 1)
    end
end
function btnOptStop_1__Clicked_Script(...)
    -- Dust Collector button script
    -- M110/M111 Output 50 signal 1100
    
    inst = mc.mcGetInstance()
    
    local hSig, rc = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT50)
    local state, rc = mc.mcSignalGetState(hSig)
    
    if state == 1 then
        mc.mcSignalSetState(hSig, 0)
    else
        mc.mcSignalSetState(hSig, 1)
    end
end
function btnSingleBlock_1__Clicked_Script(...)
    -- Table Pins button script
    -- M116/M117 Output 53 signal 1103
    
    inst = mc.mcGetInstance()
    
    local hSig, rc = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT53)
    local state, rc = mc.mcSignalGetState(hSig)
    
    if state == 1 then
        mc.mcSignalSetState(hSig, 0)
    else
        mc.mcSignalSetState(hSig, 1)
    end
end
-- tabToolpathOps-GlobalScript
function btnDispLeft_Left_Up_Script(...)
    -- Left
    local inst = mc.mcGetInstance();
    local rc = scr.SetProperty("toolpath1", "View", "2")
    local rc = scr.SetProperty("toolpath2", "View", "2")
    local rc = scr.SetProperty("toolpath3", "View", "2")
    local rc = scr.SetProperty("toolpath4", "View", "2")
    local rc = scr.SetProperty("toolpath5", "View", "2")
    
end
function btnDispISO_Left_Up_Script(...)
    -- ISO
    local inst = mc.mcGetInstance();
    local rc = scr.SetProperty("toolpath1", "View", "4")
    local rc = scr.SetProperty("toolpath2", "View", "4")
    local rc = scr.SetProperty("toolpath3", "View", "4")
    local rc = scr.SetProperty("toolpath4", "View", "4")
    local rc = scr.SetProperty("toolpath5", "View", "4")
end
function btnDispTop_Left_Up_Script(...)
    --Top
    local inst = mc.mcGetInstance();
    local rc = scr.SetProperty("toolpath1", "View", "0")
    local rc = scr.SetProperty("toolpath2", "View", "0")
    local rc = scr.SetProperty("toolpath3", "View", "0")
    local rc = scr.SetProperty("toolpath4", "View", "0")
    local rc = scr.SetProperty("toolpath5", "View", "0")
end
function btnDispBottom_Left_Up_Script(...)
    -- Bottom
    local inst = mc.mcGetInstance();
    local rc = scr.SetProperty("toolpath1", "View", "1")
    local rc = scr.SetProperty("toolpath2", "View", "1")
    local rc = scr.SetProperty("toolpath3", "View", "1")
    local rc = scr.SetProperty("toolpath4", "View", "1")
    local rc = scr.SetProperty("toolpath5", "View", "1")
end
function btnDispRight_Left_Up_Script(...)
    -- Right
    local inst = mc.mcGetInstance();
    local rc = scr.SetProperty("toolpath1", "View", "3")
    local rc = scr.SetProperty("toolpath2", "View", "3")
    local rc = scr.SetProperty("toolpath3", "View", "3")
    local rc = scr.SetProperty("toolpath4", "View", "3")
    local rc = scr.SetProperty("toolpath5", "View", "3")
end
-- tabJogging-GlobalScript
function btnToggleJogMode_Left_Up_Script(...)
    ButtonJogModeToggle()
end
function btnKeyboardJog_Left_Up_Script(...)
    KeyboardInputsToggle()
end
function droJogRate_On_Modify_Script(...)
    local inst = mc.mcGetInstance()
    local val = scr.GetProperty("droJogRate", "Value")
    mc.mcProfileWriteString(inst, "PersistentDROs", "droJogRate", string.format (val)) --Create a register and write the machine coordinates to it
end
-- grpTool-GlobalScript
function btnRemember_Left_Up_Script(...)
    --Remember Position
    RememberPosition() -- This runs the Remember Position Function that is in the screenload script.
end
function btnReturn_Left_Up_Script(...)
    -- Return To Position
    ReturnToPosition() -- This runs the Return to Position Function that is in the screenload script.
end
function btnTouch_Left_Up_Script(...)
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
