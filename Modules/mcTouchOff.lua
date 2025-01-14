------------------------------------------------------------------------------
-- Name:        Touch Off
-- Author:      B Price
-- Modified by: B Price 7/3/2019 Added support for find center if coordinates are rotated
-- Created:     05/17/2016
-- Copyright:   (c) 2016 Newfangled Solutions. All rights reserved.
-- License:  	BSD license - This header can not be removed
-- Thanks go to the following for helping with this project in one form or another.
-- Brian Barker, Steve Murphree, Todd Monto, Jim Dingus, Rob Gaudette, T Lamontagne, Steve Stallings, Chris Buchanan, J Thacher
------------------------------------------------------------------------------

local mcTouchOff = {}

local inst = mc.mcGetInstance()
local lastCheck = true

-- Get current mode and feed rate so we can set them back at the end of each function or after an error.
function GetPreState()
	m_CurFeed = mc.mcCntlGetPoundVar(inst, mc.SV_FEEDRATE)	--Feed rate
	m_CurAbsMode = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_3)	--G90, G91
end

--------------------- Get the values from the ini. DO NOT EDIT THESE VALUES HERE!!! ----------------------------
function ReadIni()
	ToffProbeRate = mc.mcProfileGetString(inst, 'ToffParams', 'ToffProbeRate', '5.0000') -- Get the Value from the profile ini. If none exist use 5.0000
	ToffProbeRate = math.abs (ToffProbeRate) --Make sure value is unsigned
	
	ToffRetractDistance = mc.mcProfileGetString(inst, 'ToffParams', 'ToffRetractDistance', '.1000') -- Get the Value from the profile ini. If none exist use .1000
	ToffRetractDistance = math.abs (tonumber(ToffRetractDistance)) --Make sure value is unsigned
	
	ToffPrepRate = mc.mcProfileGetString(inst, 'ToffParams', 'ToffPrepRate', '60.0000') -- Get the Value from the profile ini. If none exist use 60.000
	ToffPrepRate = math.abs (ToffPrepRate) --Make sure value is unsigned
	
	ToffPrepDistance = mc.mcProfileGetString(inst, 'ToffParams', 'ToffPrepDistance', '0.5000') -- Get the Value from the profile ini. If none exist use 0.5000
	ToffPrepDistance = math.abs (ToffPrepDistance) --Make sure value is unsigned
	
	ToffPlate = mc.mcProfileGetString(inst, 'ToffParams', 'ToffPlate', '.2500') -- Get the Value from the profile ini. If none exist use .2500
	ToffPlate = math.abs (ToffPlate) --Make sure value is unsigned
	
	ToffToolDiam = mc.mcProfileGetString(inst, 'ToffParams', 'ToffToolDiam', '.5000') -- Get the Value from the profile ini. If none exist use .5000
	ToffToolDiam = math.abs (ToffToolDiam) --Make sure value is unsigned
	
	ToffToolRadius = (ToffToolDiam /2)
	
	ToffCornerOption = mc.mcProfileGetString(inst, 'ToffParams', 'ToffCornerOption', '0'); -- Get the Value from the profile ini. If none exist use 0
	ToffCornerOption = math.abs (ToffCornerOption) --Make sure value is unsigned
	
	ToffCenterOption = mc.mcProfileGetString(inst, 'ToffParams', 'ToffCenterOption', '0'); -- Get the Value from the profile ini. If none exist use 0
	ToffCenterOption = math.abs (ToffCenterOption) --Make sure value is unsigned
	
	ToffProbeCode = mc.mcProfileGetString(inst, 'ToffParams', 'ToffProbeCode', '31'); -- Get the Value from the profile ini. If none exist use 31
	ToffProbeCode = math.abs (ToffProbeCode) --Make sure value is unsigned
end

----------- Check Probe State -----------
--We can use this function to return the current state CheckProbe()
--or check it for active CheckProbe(1)
--or check it for inactive CheckProbe(0)
function CheckProbe(state)

	----- Select probe signal depending on probe code selected
	ProbeSig = mc.ISIG_PROBE --Default probe signal, G31
	if ToffProbeCode == 31.1 then
		ProbeSig = mc.ISIG_PROBE1
	elseif ToffProbeCode == 31.2 then
		ProbeSig = mc.ISIG_PROBE2
	elseif ToffProbeCode == 31.3 then
		ProbeSig = mc.ISIG_PROBE3
	end
	
	local check = true --Default value of check
	local hsig = mc.mcSignalGetHandle(inst, ProbeSig)
	local ProbeState = mc.mcSignalGetState(hsig)
	local errmsg = 'ERROR: No contact with probe' --Default error message
	
	if (ProbeState == 1) then --Change the error message
		errmsg = 'ERROR: Unexpected probe touch'
	end
	
	if (state == nil) then --We did not specify the value of the state parameter so lets return ProbeState
		if (ProbeState == 1) then 
			return (true);
		else
			return (false);
		end
	end
	
	if (ProbeState ~= state) then --CheckProbe failed
		mc.mcCntlSetLastError(inst, errmsg)
		mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
		wx.wxMilliSleep(20)
		check = false
		m_CheckProbe = false
		mc.mcCntlEStop(inst)
	end
	wx.wxMilliSleep(20)
	return check
end

--------- Get machine position --------------
function GetMachPos(Axis)
	if (Axis == 'X') then
		XMach = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)
	elseif (Axis == 'Y') then
		YMach = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)
	elseif (Axis == 'Z') then
		ZMach = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)
	end
end

----------- Get Work position --------------
function GetWorkPos(Axis)
	if (Axis == 'X') then
		XWork = mc.mcAxisGetPos(inst, mc.X_AXIS)
	elseif (Axis == 'Y') then
		YWork = mc.mcAxisGetPos(inst, mc.Y_AXIS)
	elseif (Axis == 'Z') then
		ZWork = mc.mcAxisGetPos(inst, mc.Z_AXIS)
	end
end

--------- Go to machine position -------------
--This will move the axis to the position that was got using the GetMachPos function.
function ToMachPos(Axis)
	mc.mcCntlSetLastError(inst, string.format(Axis .. ' axis is moving to a requested machine position.')) -- Tell the operator the axis is moving to a machine position.
	if (Axis == 'X') then
		Code(string.format('G90 G53 X ' .. XMach .. 'F ' .. ToffPrepRate))
	elseif (Axis == 'Y') then
		Code(string.format('G90 G53 Y ' .. YMach .. 'F ' .. ToffPrepRate))
	elseif (Axis == 'Z') then
		Code(string.format('G90 G53 Z ' .. ZMach .. 'F ' .. ToffPrepRate))
	end
end

----------- Go to work position -------------
--This will move the axis to the position that was got using the GetWorkPos function.
function ToWorkPos(Axis)
	mc.mcCntlSetLastError(inst, string.format(Axis .. ' axis is moving to a requested work position.')) -- Tell the operator the axis is moving to a work position.
	if (Axis == 'X') then
		Code(string.format('G90 X ' .. XWork .. 'F ' .. ToffPrepRate))
	elseif (Axis == 'Y') then
		Code(string.format('G90 Y ' .. YWork .. 'F ' .. ToffPrepRate))
	elseif (Axis == 'Z') then
		Code(string.format('G90 Z ' .. ZWork .. 'F ' .. ToffPrepRate))
	end
end

------------- Get Fixture Offset Values -----------
function GetFixOffsetValues()
	XVar, YVar, ZVar = GetFixOffsetVars() 	--Get the fixture offset pound variables.
	XSet = mc.mcCntlGetPoundVar(inst, XVar)	--Get the value of the # variable
	YSet = mc.mcCntlGetPoundVar(inst, YVar)	--Get the value of the # variable
	ZSet = mc.mcCntlGetPoundVar(inst, ZVar)	--Get the value of the # variable
	return XSet, YSet, ZSet
end


---------- Get fixture offset pound variables function -------------
function GetFixOffsetVars()  --Function GetFixOffsetVars() may also be in the ScreenLoad script
	local FixOffset = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_14)
    local Pval = mc.mcCntlGetPoundVar(inst, mc.SV_BUFWZP)
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
	--PoundVar(Axis) returns the pound variable for the current fixture for that axis (not the pound variables value).
	--CurrentFixture returned as a string (examples G54, G59, G54.1 P12).
	--FixNum returns a simple number (1-106) for current fixture (examples G54 = 1, G59 = 6, G54.1 P1 = 7, etc).
end
	
---------- Set Fixture Offset --------
function SetFixOffset(Axis, Direction)
	if (Axis == 'X') then
		Pos = mc.mcAxisGetProbePos(inst, mc.X_AXIS, 1)
		OffsetVal = (((ToffPlate + ToffToolRadius) * Direction) + Pos)
	elseif (Axis == 'Y') then
		Pos = mc.mcAxisGetProbePos(inst, mc.Y_AXIS, 1)
		OffsetVal = (((ToffPlate + ToffToolRadius) * Direction) + Pos)
	elseif (Axis == 'Z') then
		Pos = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, 1)
		OffsetVal = ((ToffPlate * Direction) + Pos)
	end
	
	XVar, YVar, ZVar, FixNum, CurrentFixture = GetFixOffsetVars() -- Get the fixture offset pound variables. Function GetFixOffsetVars() may also be in the ScreenLoad script
	
	if (Axis == 'X') then
		mc.mcCntlSetPoundVar(inst, XVar, OffsetVal)
		--Code(string.format('G10 L2 P' .. CurrentFixture .. 'X' .. OffsetVal), true)
	elseif (Axis == 'Y') then
		mc.mcCntlSetPoundVar(inst, YVar, OffsetVal)
	elseif (Axis == 'Z') then
		mc.mcCntlSetPoundVar(inst, ZVar, OffsetVal)
	end
	
	mc.mcCntlSetLastError(inst, string.format(Axis .. ' Axis Offset Set to: ' .. OffsetVal .. '.')) -- Tell the operator what we set the offset to
	
end

------------- Code -----------
-- This function condenses the way you can execute Gcode and will pause processing until the Gcode is finished being executed.
-- See the function frameMainOnUpdateUI() for other essential bits that allows this to work. 
function Code(Gcode, ProbeActive)
	m_CheckProbe = false
	local rc = mc.mcCntlGcodeExecute(inst, Gcode)
	if (ProbeActive ~= true) then
		ProbeActive = false;
	end
	coroutine.yield(rc, ProbeActive)
end

---------- Touch Off Function --------
function TouchOff(Axis, Direction)
	-- Get the values from the Touch Off Parameters and manipulate them for this function as needed here.
	local PrepDistance = ((ToffPrepDistance + ToffToolDiam) * Direction) --Sets the maximum distance a touch move will travel and the + or - direction. 
	mc.mcCntlSetLastError(inst, string.format(Axis .. ' axis is performing a touch move.')) -- Tell the operator the axis is doing a touch move
	Code(string.format('G91 G' .. ToffProbeCode .. ' ' .. Axis .. ' ' .. PrepDistance .. 'F' .. ToffProbeRate), true) -- Probe and make sure probe is active (true) when motion stops.
end

------------- Touch Retract -----------
function TouchRetract(Axis, Direction)
	local TouchRetract = (ToffRetractDistance * Direction)
	mc.mcCntlSetLastError(inst, 'Retracting')
	Code(string.format('G91 G1 ' .. Axis .. ' ' .. TouchRetract .. 'F' .. ToffPrepRate)) -- Retract. This is the only move not done as a probe move because the probe will already be active.
end

------- Prep move function -----------------
-- Example syntax to use this function: PrepMove ('Z', -1, 3)
-- This will give you a Z Axis (Z, needs to be in quotes) move in the negative direction (-1, 1 would be positive) the distance defined by Level 3 (3)
-- You can edit the way this function works by altering Levels or adding your own
function PrepMove(Axis, Direction, Level)	--, Multiplier)
	-- Get the values from the Touch Off Parameters and manipulate them for this function as needed here.
	local PrepDistance = ToffPrepDistance
	local RetractDistance = ToffRetractDistance
	local TouchPlate = ToffPlate
	
	if Level == 0 then
		PrepDistance = RetractDistance
	elseif Level == 1 then
		PrepDistance = (RetractDistance * 2)
	elseif Level == 2 then
		PrepDistance = PrepDistance
	elseif Level == 3 then
		PrepDistance = (PrepDistance + RetractDistance + TouchPlate)
	end
		
	-- Set Direction
	if Direction < 1 then
		PrepDistance = (PrepDistance * -1)
	end
	
	mc.mcCntlSetLastError(inst, string.format(Axis .. ' axis is performing a Level ' .. Level .. ' prep move.')) -- Tell the operator the axis is doing a touch move
	Code(string.format('G91 G' .. ToffProbeCode .. ' ' .. Axis .. ' ' .. PrepDistance .. 'F' .. ToffPrepRate)) -- Execute a probe move as Gcode. The reason we do this as a probe move is an unexpected touch will stop motion.	
end

------------- Finish Move -----------
function FinishMove()	
	mc.mcCntlSetLastError(inst, 'Moving to X0 Y0.') -- Tell the operator we are moving to X and Y zero.
	Code(string.format('G90 G' .. ToffProbeCode .. 'X0 Y0 F' .. ToffPrepRate)) -- Do a probe move to X0 Y0 at the prep rate
end

------- Single Axis Touch Functions ----------
------------------ X -------------------------
function TouchOffXPos0() --Left
	GetPreState()
	TouchOff('X', 1) -- Do a touch move in the X positive direction
	SetFixOffset('X', 1)
	TouchRetract('X', -1)
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch is finished. X axis set to ' .. XSet) -- Tell the operator what we set the offset/s to.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

function TouchOffXNeg0() --Right
	GetPreState()
	TouchOff('X', -1) -- Do a touch move in the X negative direction
	SetFixOffset('X', -1)
	TouchRetract('X', 1)
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch is finished. X axis set to ' .. XSet) -- Tell the operator what we set the offset/s to.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Y -------------------------
function TouchOffYNeg0() --Top
	GetPreState()
	TouchOff('Y', -1) -- Do a touch move in the Y negative direction
	SetFixOffset('Y', -1)
	TouchRetract('Y', 1)
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch is finished. Y axis set to ' .. YSet) -- Tell the operator what we set the offset/s to.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

function TouchOffYPos0() --Bottom
	GetPreState()
	TouchOff('Y', 1) -- Do a touch move in the Y positive direction
	SetFixOffset('Y', 1)
	TouchRetract('Y', -1)
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch is finished. Y axis set to ' .. YSet) -- Tell the operator what we set the offset/s to.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Z -------------------------
function TouchOffZNeg0()	--Set work zero to material top
	GetPreState()
	TouchOff('Z', -1) -- Do a touch move in the Z negative direction
	SetFixOffset('Z', -1)
	TouchRetract('Z', 1)
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch is finished. Z axis set to ' .. ZSet) -- Tell the operator what we set the offset/s to.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

function TouchOffZNeg1()	--Set tool length offset
	GetPreState()
	local CurTool = mc.mcToolGetCurrent(inst) --Current Tool Num
	if (CurTool > 0) and (CurTool < 255) then
		GetMachPos('Z')
		TouchOff('Z', -1) -- Do a touch move in the X negative direction
		local ZPos = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, 0)
		ToMachPos('Z')
		local GageBlock = ToffPlate
		local OffsetVal = ZPos - GageBlock
		OffsetState = mc.mcCntlGetPoundVar(inst, mc.SV_MOD_GROUP_8) --Current Height Offset State
		
		mc.mcCntlGcodeExecuteWait(inst, "G49")
		mc.mcToolSetData(inst, mc.MTOOL_MILL_HEIGHT, CurTool, OffsetVal)
		mc.mcCntlSetLastError(inst, string.format("Tool %.0f Height Offset Set: %.4f", CurTool, OffsetVal))
		if (OffsetState ~= 49) then
			mc.mcCntlMdiExecute(inst, string.format("G%.1f", OffsetState))
		end
	else
	mc.mcCntlSetLastError(inst, ('Cannot set a height for an invalid tool number. Call a valid tool and try again.'))
	end
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------- Multi Axis Touch Functions ----------
------------------ Top Left ------------------
function TouchZnegYnegXpos0() -- Top left Outside with Z
	GetPreState() -- So we can set them back when finished with this routine.
	TouchOff('Z', -1) -- Do a touch move in the Z negative direction
	SetFixOffset('Z', -1)	--Set the fixture offset
	TouchRetract('Z', 1)	--Retract
	GetMachPos('Y') -- Get the machine coordinates before moving it so we can return to it later
	
	PrepMove('Y', 1, 2) -- Do a Level 1 prep move in the Y positive direction (Axis, Direction, Level)
	PrepMove('Z', -1, 1) -- Do a Level 3 prep move in the Z negative direction (Axis, Direction, Level)
	TouchOff('Y', -1) -- Do a touch move in the Y negative direction
	SetFixOffset('Y', -1)	--Set the fixture offset
	TouchRetract('Y', 1)	--Retract
	
	PrepMove('Z', 1, 1) -- Do a Level 3 prep move in the Z positive direction (Axis, Direction, Level)
	ToMachPos('Y') -- Return to the machine position we got earlier
	
	PrepMove('X', -1, 2) -- Do a Level 1 prep move in the X negative direction (Axis, Direction, Level)
	PrepMove('Z', -1, 1) -- Do a Level 3 prep move in the Z negative direction (Axis, Direction, Level)
	TouchOff('X', 1) -- Do a touch move in the X positive direction
	SetFixOffset('X', 1)	--Set the fixture offset
	TouchRetract('X', -1)	--Retract
	
	PrepMove('Z', 1, 1) -- Do a Level 3 prep move in the Z positive direction (Axis, Direction, Level)
	FinishMove() -- Move to X0 Y0
	GetFixOffsetValues()	--For our message
	mc.mcCntlSetLastError(inst, 'Touch combination is finished. X axis set to ' .. XSet .. ' Y axis set to ' .. YSet .. ' Z axis set to ' .. ZSet) -- Tell the operator the touch combination function is finished and what all the fixture offsets were set to.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Top Right ------------------
function TouchZnegYnegXneg0() -- Top right Outside with Z
	GetPreState()
	TouchOff('Z', -1)
	SetFixOffset('Z', -1)
	TouchRetract('Z', 1)
	GetMachPos('Y')
	
	PrepMove('Y', 1, 2)
	PrepMove('Z', -1, 1)
	TouchOff('Y', -1)
	SetFixOffset('Y', -1)
	TouchRetract('Y', 1)
	
	PrepMove('Z', 1, 1)
	ToMachPos('Y')
	
	PrepMove('X', 1, 2)
	PrepMove('Z', -1, 1)
	TouchOff('X', -1)
	SetFixOffset('X', -1)
	TouchRetract('X', 1)
	
	PrepMove('Z', 1, 1)
	FinishMove()
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch combination is finished. X axis set to ' .. XSet .. ' Y axis set to ' .. YSet .. ' Z axis set to ' .. ZSet) -- Tell the operator the touch combination function is finished
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Bottom Left ----------------
function TouchZnegYposXpos0() -- Bottom left Outside with Z
	GetPreState()
	TouchOff('Z', -1)
	SetFixOffset('Z', -1)
	TouchRetract('Z', 1)
	GetMachPos('Y')
	
	PrepMove('Y', -1, 2)
	PrepMove('Z', -1, 1)
	TouchOff('Y', 1)
	SetFixOffset('Y', 1)
	TouchRetract('Y', -1)
	
	PrepMove('Z', 1, 1)
	ToMachPos('Y')
	
	PrepMove('X', -1, 2)
	PrepMove('Z', -1, 1)
	TouchOff('X', 1)
	SetFixOffset('X', 1)
	TouchRetract('X', -1)
	
	PrepMove('Z', 1, 1)
	FinishMove()
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch combination is finished. X axis set to ' .. XSet .. ' Y axis set to ' .. YSet .. ' Z axis set to ' .. ZSet) -- Tell the operator the touch combination function is finished
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Bottom Right ---------------
function TouchZnegYposXneg0() -- Bottom right Outside with Z
	GetPreState()
	TouchOff('Z', -1)
	SetFixOffset('Z', -1)
	TouchRetract('Z', 1)
	GetMachPos('Y')
	
	PrepMove('Y', -1, 2)
	PrepMove('Z', -1, 1)
	TouchOff('Y', 1)
	SetFixOffset('Y', 1)
	TouchRetract('Y', -1)
	
	PrepMove('Z', 1, 1)
	ToMachPos('Y')
	
	PrepMove('X', 1, 2)
	PrepMove('Z', -1, 1)
	TouchOff('X', -1)
	SetFixOffset('X', -1)
	TouchRetract('X', 1)
	
	PrepMove('Z', 1, 1)
	FinishMove()
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch combination is finished. X axis set to ' .. XSet .. ' Y axis set to ' .. YSet .. ' Z axis set to ' .. ZSet) -- Tell the operator the touch combination function is finished
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Center Touch Functions ---------------------
function TouchCenter0() -- Center Inside No Z
	--If G68 active Cancel G68 with G69, find the center in machine coords and go there then set G68 back then set work 0.
	XVar, YVar, ZVar = GetFixOffsetVars() 			-- Get the fixture offset pound variables. Function GetFixOffsetVars() may also be in the ScreenLoad script
	GetPreState()
	local rotation = mc.mcCntlGetPoundVar(inst, 2137)
	if (rotation ~= 0.0000) then
		Code('G69')
	end
	GetMachPos('X')
	GetMachPos('Y')
	TouchOff('X', -1) -- Do a touch move in the X negative direction
	local Pos1 = mc.mcAxisGetProbePos(inst, mc.X_AXIS, 1) --Get the probe position in machine coordinates
	Code(string.format('G90 G53 X ' .. XMach .. 'Y' .. YMach .. 'F ' .. ToffPrepRate)) --Move back to start position
	TouchOff('X', 1) -- Do a touch move in the X positive direction
	local Pos2 = mc.mcAxisGetProbePos(inst, mc.X_AXIS, 1) --Get the probe position in machine coordinates
	Code(string.format('G90 G53 X ' .. XMach .. 'Y' .. YMach .. 'F ' .. ToffPrepRate)) --Move back to start position
	
	TouchOff('Y', -1) -- Do a touch move in the Y negative direction
	local Pos3 = mc.mcAxisGetProbePos(inst, mc.Y_AXIS, 1) --Get the probe position in machine coordinates
	Code(string.format('G90 G53 X ' .. XMach .. 'Y' .. YMach .. 'F ' .. ToffPrepRate)) --Move back to start position
	TouchOff('Y', 1) -- Do a touch move in the Y positive direction
	local Pos4 = mc.mcAxisGetProbePos(inst, mc.Y_AXIS, 1) --Get the probe position in machine coordinates
	Code(string.format('G90 G53 X ' .. XMach .. 'Y' .. YMach .. 'F ' .. ToffPrepRate)) --Move back to start position
	
	--Calculate center
	local XCenter = (Pos1  + Pos2) / 2
	local YCenter = (Pos3 + Pos4) / 2
	
	--Move to center
	mc.mcCntlSetLastError(inst, 'Moving to Center.') -- Tell the operator we are moving to the center.
	Code(string.format('G90 G53 G' .. ToffProbeCode .. 'X' .. XCenter .. 'Y' .. YCenter .. 'F' .. ToffPrepRate)) -- Do a probe move to XCenter YCenter (machine coordinates) at the prep rate
	
	--Set our rotated angle back if applies
	if (rotation ~= 0.0000) then
		Code(string.format('G68 R ' .. rotation)) 
	end
	
	--Now that we are at the center lets zero out our work coordinates
	rc = mc.mcAxisSetPos(inst, mc.X_AXIS, 0.0000)
	rc = mc.mcAxisSetPos(inst, mc.Y_AXIS, 0.0000)
	
	GetFixOffsetValues()
	mc.mcCntlSetLastError(inst, 'Touch combination is finished. X axis set to ' .. XSet .. ' Y axis set to ' .. YSet) --Tell the operator what the work offset values are.
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

------------------ Angle Touch Function ---------------------
function Angle0()
	GetPreState()
	Code(string.format('G69')) -- Cancel any previously set G68 angle.
	rc = UI.m_choiceMeasureAngle:GetSelection()	--0 = X+, 1 = X-, 2 = Y+, 3 = Y-

	if (rc < 2) then
		TouchAxis = 'X'
		PrepAxis = 'Y'
	else 
		TouchAxis = 'Y'
		PrepAxis = 'X'
	end
	
	if (rc == 0) or (rc == 2) then
		TouchDirection = 1
	else
		TouchDirection = -1
	end
	
	RetractDirection = TouchDirection * -1
	
	GetMachPos((TouchAxis))
	TouchOff((TouchAxis), (TouchDirection)) -- Do a touch move in the X positive direction
	local X1  = mc.mcAxisGetProbePos(inst, mc.X_AXIS, 1)	--Last parameter is 1 for machine position 0 would get work position
	local Y1  = mc.mcAxisGetProbePos(inst, mc.Y_AXIS, 1)	--Last parameter is 1 for machine position 0 would get work position
	ToMachPos(TouchAxis)
	
	mc.mcCntlSetLastError(inst, 'Moving to position for second touch.')
	Code(string.format('G91 G' .. ToffProbeCode .. PrepAxis .. ToffPrepDistance .. 'F' .. ToffPrepRate)) -- Probe
	
	GetMachPos((TouchAxis))
	TouchOff((TouchAxis), (TouchDirection)) -- Do a touch move in the X positive direction
	local X2  = mc.mcAxisGetProbePos(inst, mc.X_AXIS, 1)
	local Y2  = mc.mcAxisGetProbePos(inst, mc.Y_AXIS, 1)
	ToMachPos(TouchAxis)
	
	--Subtract the start from the end point 
	local xDelta = X2 - X1
	local yDelta = Y2 - Y1
	
	local angle = math.atan2 (yDelta, xDelta)
	angle = angle * 180 / math.pi
	
	if TouchAxis == 'X' then
		angle = angle - 90.0
	end
	
	mc.mcCntlSetLastError(inst, 'Angle (G68) has been set to ' .. tostring(angle))
	Code(string.format('G68 R' .. angle)) --Rotate coordinate system
	mc.mcCntlGcodeExecute(inst, string.format('G ' .. m_CurAbsMode .. '\nF ' .. m_CurFeed)) --Set mode and feed back
end

ReadIni()

------------------ Dialog ---------------------
function mcTouchOff.Dialog()

UI = {}


-- create frameMain
UI.frameMain = wx.wxFrame (wx.NULL, wx.wxID_ANY, "TouchOff UI", wx.wxDefaultPosition, wx.wxSize( 900,530 ), wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxRESIZE_BORDER )
	UI.frameMain:SetSizeHints( wx.wxSize( 900,530 ), wx.wxDefaultSize )
	UI.frameMain :SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
	
	UI.m_menubar1 = wx.wxMenuBar( 0 )
	UI.m_menuHelp = wx.wxMenu()
	UI.m_menuItemDocs = wx.wxMenuItem( UI.m_menuHelp, wx.wxID_ANY, "Docs", "", wx.wxITEM_NORMAL )
	UI.m_menuHelp:Append( UI.m_menuItemDocs )
	
	UI.m_menubar1:Append( UI.m_menuHelp, "Help" ) 
	
	UI.frameMain:SetMenuBar( UI.m_menubar1 )
	
	UI.bSizerFrame = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.fgSizerFrame = wx.wxFlexGridSizer( 0, 3, 0, 0 )
	UI.fgSizerFrame:AddGrowableCol( 0 )
	UI.fgSizerFrame:AddGrowableCol( 1 )
	UI.fgSizerFrame:AddGrowableCol( 2 )
	UI.fgSizerFrame:AddGrowableRow( 0 )
	UI.fgSizerFrame:SetFlexibleDirection( wx.wxBOTH )
	UI.fgSizerFrame:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.sbSizerSettings = wx.wxStaticBoxSizer( wx.wxStaticBox( UI.frameMain, wx.wxID_ANY, "Settings/Options" ), wx.wxHORIZONTAL )
	
	UI.fgSizerSettings = wx.wxFlexGridSizer( 12, 2, 0, 0 )
	UI.fgSizerSettings:AddGrowableCol( 0 )
	UI.fgSizerSettings:AddGrowableCol( 1 )
	UI.fgSizerSettings:AddGrowableRow( 0 )
	UI.fgSizerSettings:AddGrowableRow( 1 )
	UI.fgSizerSettings:AddGrowableRow( 2 )
	UI.fgSizerSettings:AddGrowableRow( 3 )
	UI.fgSizerSettings:AddGrowableRow( 4 )
	UI.fgSizerSettings:AddGrowableRow( 5 )
	UI.fgSizerSettings:AddGrowableRow( 6 )
	UI.fgSizerSettings:AddGrowableRow( 7 )
	UI.fgSizerSettings:AddGrowableRow( 8 )
	UI.fgSizerSettings:AddGrowableRow( 9 )
	UI.fgSizerSettings:AddGrowableRow( 10 )
	UI.fgSizerSettings:AddGrowableRow( 11 )
	UI.fgSizerSettings:SetFlexibleDirection( wx.wxBOTH )
	UI.fgSizerSettings:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.m_staticTextProbeFeedRate = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Probe Feed Rate", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextProbeFeedRate:Wrap( -1 )
	UI.m_staticTextProbeFeedRate:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextProbeFeedRate, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlProbeFeedRate = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_textCtrlProbeFeedRate:SetToolTip( "Probe Feed Rate is the rate (speed) the axes will move at during a probe move. This is typically very slow. Setting it too high could result in chipped tools, bent probes, etc. All machines are different and it is the operators responsibility to set this to something acceptable for their machine." )
	
	UI.fgSizerSettings:Add( UI.m_textCtrlProbeFeedRate, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextRetractDistance = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Retract Distance", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextRetractDistance:Wrap( -1 )

	UI.m_staticTextRetractDistance:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextRetractDistance, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlRetractDistance = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_textCtrlRetractDistance:SetToolTip( "Retract Distance is the distance the axis will retract after it touches." )
	
	UI.fgSizerSettings:Add( UI.m_textCtrlRetractDistance, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextPrepFeedRate = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Prep. Feed Rate", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextPrepFeedRate:Wrap( -1 )
	UI.m_staticTextPrepFeedRate:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextPrepFeedRate, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlPrepFeedRate = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_textCtrlPrepFeedRate:SetToolTip( "Prep. Feed Rate is the rate (speed) the axes will move at during a preparation move." )
	
	UI.fgSizerSettings:Add( UI.m_textCtrlPrepFeedRate, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextPrepDistance = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Prep. Distance", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextPrepDistance:Wrap( -1 )
	UI.m_staticTextPrepDistance:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextPrepDistance, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlPrepDistance = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_textCtrlPrepDistance:SetToolTip( "Prep. Distance is a variable that is used to calculate the distance axes will move in a preparation move. If a touch is detected in the preparation move you will get a \"ERROR: Unexpected probe touch\" error message in the status bar, motion will stop and Mach will be disabled." )
	
	UI.fgSizerSettings:Add( UI.m_textCtrlPrepDistance, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextToolDiam = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Tool or Probe Diameter", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextToolDiam:Wrap( -1 )
	UI.m_staticTextToolDiam:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextToolDiam, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlToolDiam = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_textCtrlToolDiam:SetToolTip( "Tool or Probe Diameter is the diameter of the tool or probe being used in the touch function." )
	
	UI.fgSizerSettings:Add( UI.m_textCtrlToolDiam, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextTouchPlateHeight = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Touch Plate Height", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextTouchPlateHeight:Wrap( -1 )
	UI.m_staticTextTouchPlateHeight:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextTouchPlateHeight, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlTouchPlateHeight = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_textCtrlTouchPlateHeight:SetToolTip( "Touch Plate Height is the thickness of the touch plate. A touch plate capable of setting more than one axis must be the same thickness on all planes it is capable of being used to set in a single function." )
	
	UI.fgSizerSettings:Add( UI.m_textCtrlTouchPlateHeight, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextProbeCode = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Probe Code Options", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextProbeCode:Wrap( -1 )
	UI.m_staticTextProbeCode:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextProbeCode, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_choiceProbeCodeChoices = { "G31 (Probe)", "G31.1 (Probe 1)", "G31.2 (Probe 2)", "G31.3 (Probe 3)" }
	UI.m_choiceProbeCode = wx.wxChoice( UI.frameMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_choiceProbeCodeChoices, 0 )
	UI.m_choiceProbeCode:SetSelection( 0 )
	UI.m_choiceProbeCode:SetToolTip( "Probe Code Options sets the option for the probe being used. \n\nProbe Code is the Gcode that will be executed when a touch function is used. This does not change the motion the machine will make during any function. It only changes which input the function is looking at to detect a touch. Mach4 has 4 probe inputs and the options are limited to those 4.\n\nG31 = Probe\nG31.1 = Probe 1\nG31.2 = Probe 2\nG31.3 = Probe 3" )
	
	UI.fgSizerSettings:Add( UI.m_choiceProbeCode, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextCornerTouchOptions = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Corner Touch Options", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextCornerTouchOptions:Wrap( -1 )
	UI.m_staticTextCornerTouchOptions:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextCornerTouchOptions, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_choiceCornerTouchChoices = { "Outside With Z" }
	UI.m_choiceCornerTouch = wx.wxChoice( UI.frameMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_choiceCornerTouchChoices, 0 )
	UI.m_choiceCornerTouch:SetSelection( 0 )
	UI.m_choiceCornerTouch:SetToolTip( "Corner Touch Options sets the option for a corner touch. \n\nOutside With Z description:\nJog to point where the tool or probe is just above the Z and close enough to the corner your touching that the Prep. Distance will get you past the edge of the part but not so far that when probing (Prep. Distance + Tool Diameter) it will not make contact with the probe." )
	
	UI.fgSizerSettings:Add( UI.m_choiceCornerTouch, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextCenterTouchOptions = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Center Touch Options", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextCenterTouchOptions:Wrap( -1 )
	UI.m_staticTextCenterTouchOptions:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
	
	UI.fgSizerSettings:Add( UI.m_staticTextCenterTouchOptions, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_choiceCenterTouchChoices = { "Inside No Z" }
	UI.m_choiceCenterTouch = wx.wxChoice( UI.frameMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_choiceCenterTouchChoices, 0 )
	UI.m_choiceCenterTouch:SetSelection( 0 )
	UI.m_choiceCenterTouch:SetToolTip( "Center Touch Options sets the options for a center touch. \n\nInside No Z description:\nJog to a point where the tool or probe is deep enough inside the bore, square or rectangle to touch four points. This will set the work coordinates to 0 at the center of the feature. This action does not provoke any Z axis movement and will not alter the fixture offset for the Z axis." )
	
	UI.fgSizerSettings:Add( UI.m_choiceCenterTouch, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextMeasureAngleOptions = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Measure Angle Options", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextMeasureAngleOptions:Wrap( -1 )
	UI.fgSizerSettings:Add( UI.m_staticTextMeasureAngleOptions, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_choiceMeasureAngleChoices = { "X++", "X--", "Y++", "Y--" }
	UI.m_choiceMeasureAngle = wx.wxChoice( UI.frameMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_choiceMeasureAngleChoices, 0 )
	UI.m_choiceMeasureAngle:SetSelection( 0 )
	UI.m_choiceMeasureAngle:SetToolTip( "Measure Angle Options sets the option for the axis and direction to probe in to find an angle and performs a G68 (which rotates the coordinate system)." )
	
	UI.fgSizerSettings:Add( UI.m_choiceMeasureAngle, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextZOnlyOptions = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Z Only Options", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.m_staticTextZOnlyOptions:Wrap( -1 )
	UI.fgSizerSettings:Add( UI.m_staticTextZOnlyOptions, 1, wx.wxALIGN_RIGHT + wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_choiceZOnlyChoices = { "Material Top", "Tool Length (TLO)" }
	UI.m_choiceZOnly = wx.wxChoice( UI.frameMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_choiceZOnlyChoices, 0 )
	UI.m_choiceZOnly:SetSelection( 0 )
	UI.m_choiceZOnly:SetToolTip( "Z Only Options sets the option of what it is your trying to find the Z value for.\n\nMaterial Top:\nUsed to find the top of the material being machined. It sets the current fixtures Z work offset to 0.0000 (zero) at the top of the material.\n\nTool Length (TLO):\nWill set the length offset for the current tool. Make sure you have called the tool offset you want to set through MDI or Gcode before performing this function." )
	
	UI.fgSizerSettings:Add( UI.m_choiceZOnly, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.sbSizerSettings:Add( UI.fgSizerSettings, 1, wx.wxALL + wx.wxEXPAND, 0 )
	
	
	UI.fgSizerFrame:Add( UI.sbSizerSettings, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.sbSizerStatus = wx.wxStaticBoxSizer( wx.wxStaticBox( UI.frameMain, wx.wxID_ANY, "Status" ), wx.wxHORIZONTAL )
	
	UI.fgSizerStatus = wx.wxFlexGridSizer( 6, 2, 10, 10 )
	UI.fgSizerStatus:AddGrowableCol( 0 )
	UI.fgSizerStatus:AddGrowableCol( 1 )
	UI.fgSizerStatus:AddGrowableRow( 0 )
	UI.fgSizerStatus:AddGrowableRow( 1 )
	UI.fgSizerStatus:AddGrowableRow( 2 )
	UI.fgSizerStatus:AddGrowableRow( 3 )
	UI.fgSizerStatus:AddGrowableRow( 4 )
	UI.fgSizerStatus:AddGrowableRow( 5 )
	UI.fgSizerStatus:SetFlexibleDirection( wx.wxBOTH )
	UI.fgSizerStatus:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.m_staticTextX = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticTextX:Wrap( -1 )
	UI.m_staticTextX:SetFont( wx.wxFont( 24, 70, 90, 90, False, "" ) )
	
	UI.fgSizerStatus:Add( UI.m_staticTextX, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlX = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "0.0000", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_RIGHT )
	UI.m_textCtrlX:SetFont( wx.wxFont( 18, 70, 90, 92, False, "" ) )
	
	UI.fgSizerStatus:Add( UI.m_textCtrlX, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextY = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Y", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticTextY:Wrap( -1 )
	UI.m_staticTextY:SetFont( wx.wxFont( 24, 70, 90, 90, False, "" ) )
	
	UI.fgSizerStatus:Add( UI.m_staticTextY, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlY = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "0.0000", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_RIGHT )
	UI.m_textCtrlY:SetFont( wx.wxFont( 18, 70, 90, 92, False, "" ) )
	
	UI.fgSizerStatus:Add( UI.m_textCtrlY, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_staticTextZ = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "Z", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticTextZ:Wrap( -1 )
	UI.m_staticTextZ:SetFont( wx.wxFont( 24, 70, 90, 90, False, "" ) )
	
	UI.fgSizerStatus:Add( UI.m_staticTextZ, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_textCtrlZ = wx.wxTextCtrl( UI.frameMain, wx.wxID_ANY, "0.0000", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_RIGHT )
	UI.m_textCtrlZ:SetFont( wx.wxFont( 18, 70, 90, 92, False, "" ) )
	
	UI.fgSizerStatus:Add( UI.m_textCtrlZ, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.fgSizerStatus:Add( 0, 0, 1, wx.wxEXPAND, 5 )
	
	UI.m_buttonMachineWork = wx.wxButton( UI.frameMain, wx.wxID_ANY, "Work/Machine Toggle\nCurrently Displaying\nWork Coordinates", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_buttonMachineWork:SetFont( wx.wxFont( 12, 70, 90, 92, False, "" ) )
	UI.m_buttonMachineWork:SetForegroundColour( wx.wxColour( 255, 255, 255 ) )
	UI.m_buttonMachineWork:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
	UI.m_buttonMachineWork:SetToolTip( "Machine/Work Toggle. This toggle button selects which units are displayed in the TouchOff UI DROs. The options are Work or Machine. Each click will change the currently displayed units to the other. Choosing to display machine coordinates is not a retained setting. By default the TouchOff UI is opened each time displaying work coordinates." )
	
	UI.fgSizerStatus:Add( UI.m_buttonMachineWork, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.fgSizerStatus:Add( 0, 0, 1, wx.wxALL, 5 )
	
	UI.m_staticTextProbeStatus = wx.wxStaticText( UI.frameMain, wx.wxID_ANY, "\nSelected Probe Is\nCurrently Inactive", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE + wx.wxST_NO_AUTORESIZE+wx.wxSUNKEN_BORDER )
	UI.m_staticTextProbeStatus:Wrap( -1 )
	UI.m_staticTextProbeStatus:SetFont( wx.wxFont( 12, 70, 90, 92, False, "" ) )
	UI.m_staticTextProbeStatus:SetForegroundColour( wx.wxColour( 255, 255, 255 ) )
	UI.m_staticTextProbeStatus:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
	UI.m_staticTextProbeStatus:SetToolTip( "This is an indicator for the current status (active or inactive) of the selected probe input." )
	
	UI.fgSizerStatus:Add( UI.m_staticTextProbeStatus, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.sbSizerStatus:Add( UI.fgSizerStatus, 1, wx.wxALL + wx.wxEXPAND, 0 )
	
	
	UI.fgSizerFrame:Add( UI.sbSizerStatus, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.sbSizerFunctions = wx.wxStaticBoxSizer( wx.wxStaticBox( UI.frameMain, wx.wxID_ANY, "Functions" ), wx.wxHORIZONTAL )
	
	UI.fgSizerFunctions = wx.wxFlexGridSizer( 4, 3, 40, 40 )
	UI.fgSizerFunctions:AddGrowableCol( 0 )
	UI.fgSizerFunctions:AddGrowableCol( 1 )
	UI.fgSizerFunctions:AddGrowableCol( 2 )
	UI.fgSizerFunctions:AddGrowableRow( 0 )
	UI.fgSizerFunctions:AddGrowableRow( 1 )
	UI.fgSizerFunctions:AddGrowableRow( 2 )
	UI.fgSizerFunctions:AddGrowableRow( 3 )
	UI.fgSizerFunctions:SetFlexibleDirection( wx.wxBOTH )
	UI.fgSizerFunctions:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.m_bpButtonTopLeft = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageTopLeft())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonTopLeft = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonTopLeft:SetToolTip( "Find top left corner:\n\nThis will find the top left corner. Corner touch options selection can modify the behavior." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonTopLeft, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonTop = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageTop())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonTop = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonTop:SetToolTip( "Find Y++:\n\nThis will find the Y positive edge. The probe move will be a Y-- move." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonTop, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonTopRight = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageTopRight())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonTopRight = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonTopRight:SetToolTip( "Find top right corner:\n\nThis will find the top right corner. Corner touch options selection can modify the behavior." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonTopRight, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonLeft = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageLeft())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonLeft = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonLeft:SetToolTip( "Find X--:\n\nThis will find the X negative edge. The probe move will be a X++ move." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonLeft, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonCenter = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageCenter())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonCenter = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonCenter:SetToolTip( "Find center:\n\nThis will find the center of a square, circle or rectangle. Center touch options selection can modify the behavior." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonCenter, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonRight = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageRight())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonRight = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonRight:SetToolTip( "Find X++:\n\nThis will find the X positive edge. The probe move will be a X-- move." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonRight, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonBottomLeft = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageBottomLeft())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonBottomLeft = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonBottomLeft:SetToolTip( "Find bottom left corner:\n\nThis will find the bottom left corner. Corner touch options selection can modify the behavior." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonBottomLeft, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonBottom = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageBottom())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonBottom = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonBottom:SetToolTip( "Find Y--:\n\nThis will find the Y negative edge. The probe move will be a Y++ move." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonBottom, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonBottomRight = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageBottomRight())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonBottomRight = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonBottomRight:SetToolTip( "Find bottom right corner:\n\nThis will find the bottom right corner. Corner touch options selection can modify the behavior." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonBottomRight, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonMeasureAngle = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageMeasureAngle())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonMeasureAngle = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonMeasureAngle:SetToolTip( "Find angle:\n\nThis will find the angle of an edge and rotate the coordinate system with a G68 by this amount. The measure angle option selection will dictate the direction of travel during a probe move." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonMeasureAngle, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bitmap1 = wx.wxStaticBitmap( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageCompass())), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	--UI.m_bitmap1 = wx.wxStaticBitmap( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_bitmap1:SetToolTip( "This simply shows the direction an axis will be moving in to make a X or Y positive or negative move." )
	
	UI.fgSizerFunctions:Add( UI.m_bitmap1, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_bpButtonZOnly = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, (wx.wxBitmap(ImageZOnly())), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	--UI.m_bpButtonZOnly = wx.wxBitmapButton( UI.frameMain, wx.wxID_ANY, wx.wxNullBitmap, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
	UI.m_bpButtonZOnly:SetToolTip( "Find Z:\n\nThis will only probe with the Z axis. The Z only option selection will dictate what is set using the probe contact position." )
	
	UI.fgSizerFunctions:Add( UI.m_bpButtonZOnly, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.sbSizerFunctions:Add( UI.fgSizerFunctions, 1, wx.wxALL + wx.wxEXPAND, 0 )
	
	
	UI.fgSizerFrame:Add( UI.sbSizerFunctions, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.bSizerFrame:Add( UI.fgSizerFrame, 1, wx.wxEXPAND, 0 )
	
	
	UI.frameMain:SetSizer( UI.bSizerFrame )
	UI.frameMain:Layout()
	
	UI.frameMain:Centre( wx.wxBOTH )
	
	-- Connect Events
	
	UI.frameMain:Connect( wx.wxEVT_ACTIVATE, function(event)
	frameMainOnActivate()
	
	event:Skip()
	end )
	
	UI.frameMain:Connect( wx.wxEVT_CLOSE_WINDOW, function(event)
	frameMainOnClose()
	
	end )
	
	UI.frameMain:Connect( wx.wxEVT_UPDATE_UI, function(event)
	frameMainOnUpdateUI()
	
	event:Skip()
	end )
	
	UI.frameMain:Connect( wx.wxID_ANY ,wx.wxEVT_COMMAND_MENU_SELECTED , function(event)
	m_menuItemDocsOnMenuSelection()
	
	--event:Skip()
	end )
	
	UI.m_textCtrlProbeFeedRate:Connect( wx.wxEVT_KILL_FOCUS, function(event)
	m_textCtrlProbeFeedRateOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlProbeFeedRate:Connect( wx.wxEVT_COMMAND_TEXT_ENTER, function(event)
	m_textCtrlProbeFeedRateOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlRetractDistance:Connect( wx.wxEVT_KILL_FOCUS, function(event)
	m_textCtrlRetractDistanceOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlRetractDistance:Connect( wx.wxEVT_COMMAND_TEXT_ENTER, function(event)
	m_textCtrlRetractDistanceOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlPrepFeedRate:Connect( wx.wxEVT_KILL_FOCUS, function(event)
	m_textCtrlPrepFeedRateOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlPrepFeedRate:Connect( wx.wxEVT_COMMAND_TEXT_ENTER, function(event)
	m_textCtrlPrepFeedRateOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlPrepDistance:Connect( wx.wxEVT_KILL_FOCUS, function(event)
	m_textCtrlPrepDistanceOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlPrepDistance:Connect( wx.wxEVT_COMMAND_TEXT_ENTER, function(event)
	m_textCtrlPrepDistanceOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlToolDiam:Connect( wx.wxEVT_KILL_FOCUS, function(event)
	m_textCtrlToolDiamOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlToolDiam:Connect( wx.wxEVT_COMMAND_TEXT_ENTER, function(event)
	m_textCtrlToolDiamOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlTouchPlateHeight:Connect( wx.wxEVT_KILL_FOCUS, function(event)
	m_textCtrlTouchPlateHeightOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_textCtrlTouchPlateHeight:Connect( wx.wxEVT_COMMAND_TEXT_ENTER, function(event)
	m_textCtrlTouchPlateHeightOnKillFocus()
	
	event:Skip()
	end )
	
	UI.m_choiceProbeCode:Connect( wx. wxEVT_COMMAND_CHOICE_SELECTED, function(event)
	m_choiceProbeCodeOnChoice()
	
	event:Skip()
	end )
	
	UI.m_choiceCornerTouch:Connect( wx. wxEVT_COMMAND_CHOICE_SELECTED, function(event)
	m_choiceCornerTouchOnChoice()
	
	event:Skip()
	end )
	
	UI.m_choiceCenterTouch:Connect( wx. wxEVT_COMMAND_CHOICE_SELECTED, function(event)
	m_choiceCenterTouchOnChoice()
	
	event:Skip()
	end )
	
	UI.m_choiceMeasureAngle:Connect( wx. wxEVT_COMMAND_CHOICE_SELECTED, function(event)
	m_choiceMeasureAngleOnChoice()
	
	event:Skip()
	end )
	
	UI.m_choiceZOnly:Connect( wx. wxEVT_COMMAND_CHOICE_SELECTED, function(event)
	m_choiceZOnlyOnChoice()
	
	event:Skip()
	end )
	
	UI.m_buttonMachineWork:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_buttonMachineWorkOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonTopLeft:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonTopLeftOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonTop:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonTopOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonTopRight:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonTopRightOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonLeft:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonLeftOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonCenter:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonCenterOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonRight:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonRightOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonBottomLeft:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonBottomLeftOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonBottom:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonBottomOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonBottomRight:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonBottomRightOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonMeasureAngle:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonMeasureAngleOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.m_bpButtonZOnly:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
	m_bpButtonZOnlyOnButtonClick()
	
	--event:Skip()
	end )
	
	UI.frameMain:Show(true)	--Show the frame
	
	return (UI.frameMain)

end -- User Interface

--Functions for connect events
function frameMainOnActivate()
	
	MachWorkDRO = true --Sets UI DROs to work coordinates as default
	UI.m_buttonMachineWork:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )--set theButton color to work coords state
	UI.m_buttonMachineWork:SetForegroundColour( wx.wxColour( 255, 255, 255 ) )--set theButton color to work coords state
	UI.m_buttonMachineWork:SetLabel( "Work/Machine Toggle\nCurrently Displaying\nWork Coordinates" )
	
	local GetProbeRate = mc.mcProfileGetString(inst, 'ToffParams', 'ToffProbeRate', '5.0') -- Get the Value from the profile ini.
	UI.m_textCtrlProbeFeedRate:SetValue(tostring (GetProbeRate))
	
	local GetRetractDistance = mc.mcProfileGetString(inst, 'ToffParams', 'ToffRetractDistance', '0.1') -- Get the Value from the profile ini.
	UI.m_textCtrlRetractDistance:SetValue(tostring (GetRetractDistance))
	
	local GetPrepFeedRate = mc.mcProfileGetString(inst, 'ToffParams', 'ToffPrepRate', '60') -- Get the Value from the profile ini.
	UI.m_textCtrlPrepFeedRate:SetValue(tostring (GetPrepFeedRate))
	
	local GetPrepDistance = mc.mcProfileGetString(inst, 'ToffParams', 'ToffPrepDistance', '0.5') -- Get the Value from the profile ini.
	UI.m_textCtrlPrepDistance:SetValue(tostring (GetPrepDistance))
	
	local GetTouchToolDiam = mc.mcProfileGetString(inst, 'ToffParams', 'ToffToolDiam', '0.25') -- Get the Value from the profile ini.
	UI.m_textCtrlToolDiam:SetValue(tostring (GetTouchToolDiam))
	
	local GetTouchPlate = mc.mcProfileGetString(inst, 'ToffParams', 'ToffPlate', '0.2') -- Get the Value from the profile ini.
	UI.m_textCtrlTouchPlateHeight:SetValue(tostring (GetTouchPlate))
	
	--UI.m_choiceProbeCode
	local GetProbeCode = mc.mcProfileGetString(inst, 'ToffParams', 'ToffProbeCode', '31'); -- Get the Value from the profile ini.
	if tonumber (GetProbeCode)  == 31 then
		UI.m_choiceProbeCode:SetSelection(0)
	elseif tonumber (GetProbeCode) == 31.1 then
		UI.m_choiceProbeCode:SetSelection(1)
	elseif tonumber (GetProbeCode) == 31.2 then
		UI.m_choiceProbeCode:SetSelection(2)
	elseif tonumber (GetProbeCode) == 31.3 then
		UI.m_choiceProbeCode:SetSelection(3)
	end
	
	local GetCornerOption = mc.mcProfileGetString(inst, 'ToffParams', 'ToffCornerOption', '0'); -- Get the Value from the profile ini.
	UI.m_choiceCornerTouch:SetSelection(tonumber (GetCornerOption))
	
	local GetCenterOption = mc.mcProfileGetString(inst, 'ToffParams', 'ToffCenterOption', '0'); -- Get the Value from the profile ini.
	UI.m_choiceCenterTouch:SetSelection(tonumber (GetCenterOption))
	
	local GetMeasureAngleOptions = mc.mcProfileGetString(inst, 'ToffParams', 'ToffAngleOption', '0'); -- Get the Value from the profile ini.
	UI.m_bpButtonMeasureAngle:SetBitmapLabel(wx.wxBitmap(ImageMeasureAngle(GetMeasureAngleOptions)))
	UI.m_choiceMeasureAngle:SetSelection(tonumber (GetMeasureAngleOptions))
	
	local GetZOnlyOption = mc.mcProfileGetString(inst, 'ToffParams', 'ToffZOnlyOption', '0'); -- Get the Value from the profile ini.
	UI.m_bpButtonZOnly:SetBitmapLabel(wx.wxBitmap(ImageZOnly(GetZOnlyOption)))
	UI.m_choiceZOnly:SetSelection(tonumber (GetZOnlyOption))
end

function frameMainOnClose() --edited 4/8/2019
	co = nil
	Tframe = nil
	UI.frameMain:Destroy()
	--UI.frameMain:Hide()	--Hide the frame
	--co = nil
end

function frameMainOnUpdateUI()

	mcState, rc = mc.mcCntlGetState(inst)
	if (co ~= nil) and (mcState == 0) then
		local state = coroutine.status(co)
		if state == "suspended" then	--We are about to run some more code so check to see if we have to check the probe state
			local IsOk = true;
			if ( m_CheckProbe == true) then	--The probe should be active at the end of the move
				IsOk = CheckProbe(1)
			else
				IsOk = CheckProbe(0)	--The probe should NOT be active at the end of the move
			end
			if ( IsOk == false ) then --If the check failed lets kill the Coroutine
				co = nil
				IsOk = true
			else
				coerrorcheck, rc, m_CheckProbe = coroutine.resume(co)
				if(coerrorcheck == false) then	--Something happened here to the coroutine so kill it
					co = nil
				end
				--if(rc < 0) then	--Something happened in the Gcode and we have an error So Kill the coroutine
				--	co = nil
				--end
			end
		end
		
		if state == "dead" then	 --Kill the coroutine
			co = nil
		end
	end
	
	if mcState ~= 0 then	--Disable input fields, selections and buttons if not in idle state
		UI.m_menuItemDocs:Enable(false)
		UI.m_textCtrlProbeFeedRate:Enable(false)
		UI.m_textCtrlRetractDistance:Enable(false)
		UI.m_textCtrlPrepFeedRate:Enable(false)
		UI.m_textCtrlPrepDistance:Enable(false)
		UI.m_textCtrlToolDiam:Enable(false)
		UI.m_textCtrlTouchPlateHeight:Enable(false)
		UI.m_choiceProbeCode:Enable(false)
		UI.m_choiceCornerTouch:Enable(false)
		UI.m_choiceCenterTouch:Enable(false)
		UI.m_choiceMeasureAngle:Enable(false)
		UI.m_choiceZOnly:Enable(false)
		UI.m_bpButtonTopLeft:Enable(false)
		UI.m_bpButtonTop:Enable(false)
		UI.m_bpButtonTopRight:Enable(false)
		UI.m_bpButtonLeft:Enable(false)
		UI.m_bpButtonCenter:Enable(false)
		UI.m_bpButtonRight:Enable(false)
		UI.m_bpButtonBottomLeft:Enable(false)
		UI.m_bpButtonBottom:Enable(false)
		UI.m_bpButtonBottomRight:Enable(false)
		UI.m_bpButtonMeasureAngle:Enable(false)
		UI.m_bpButtonZOnly:Enable(false)
	else	--Enable input fields, selections and buttons if in idle state
		UI.m_menuItemDocs:Enable(true)
		UI.m_textCtrlProbeFeedRate:Enable(true)
		UI.m_textCtrlRetractDistance:Enable(true)
		UI.m_textCtrlPrepFeedRate:Enable(true)
		UI.m_textCtrlPrepDistance:Enable(true)
		UI.m_textCtrlToolDiam:Enable(true)
		UI.m_textCtrlTouchPlateHeight:Enable(true)
		UI.m_choiceProbeCode:Enable(true)
		UI.m_choiceCornerTouch:Enable(true)
		UI.m_choiceCenterTouch:Enable(true)
		UI.m_choiceMeasureAngle:Enable(true)
		UI.m_choiceZOnly:Enable(true)
		UI.m_bpButtonTopLeft:Enable(true)
		UI.m_bpButtonTop:Enable(true)
		UI.m_bpButtonTopRight:Enable(true)
		UI.m_bpButtonLeft:Enable(true)
		UI.m_bpButtonCenter:Enable(true)
		UI.m_bpButtonRight:Enable(true)
		UI.m_bpButtonBottomLeft:Enable(true)
		UI.m_bpButtonBottom:Enable(true)
		UI.m_bpButtonBottomRight:Enable(true)
		UI.m_bpButtonMeasureAngle:Enable(true)
		UI.m_bpButtonZOnly:Enable(true)
	end
	
	-- Set Machine/Work DROs to requested coordinates
	if (MachWorkDRO == true) then	--Set Machine/Work DROs to work coordinates
		xmachine = mc.mcAxisGetPos(inst, mc.X_AXIS)
		ymachine = mc.mcAxisGetPos(inst, mc.Y_AXIS)
		zmachine = mc.mcAxisGetPos(inst, mc.Z_AXIS)
	else --Set Machine/Work DROs to machine coordinates
		xmachine = mc.mcAxisGetMachinePos(inst, mc.X_AXIS)
		ymachine = mc.mcAxisGetMachinePos(inst, mc.Y_AXIS)
		zmachine = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)
	end
	
	UI.m_textCtrlX:SetValue (string.format ('%0.4f', xmachine))
	UI.m_textCtrlY:SetValue (string.format ('%0.4f', ymachine))
	UI.m_textCtrlZ:SetValue (string.format ('%0.4f', zmachine))
	
	-- Set Probe LED state
	-- Select probe signal depending on probe code selected
	ReadIni()
	ProbeSignal = mc.ISIG_PROBE --Default probe signal, probe (G31)
	if ToffProbeCode == 31.1 then
		ProbeSignal = mc.ISIG_PROBE1
	elseif ToffProbeCode == 31.2 then
		ProbeSignal = mc.ISIG_PROBE2
	elseif ToffProbeCode == 31.3 then
		ProbeSignal = mc.ISIG_PROBE3
	end
	
	local hsig = mc.mcSignalGetHandle(inst, ProbeSignal)
	local ProbeState = (mc.mcSignalGetState(hsig))
	if (ProbeState ~= LastCheck) then --The probe input status has changed
		if (ProbeState == 1) then --The probe input is active
			UI.m_staticTextProbeStatus:SetBackgroundColour( wx.wxColour( 130, 180, 224) )
			UI.m_staticTextProbeStatus:SetLabel("\nSelected Probe Is\nCurrently Active")
		else
			UI.m_staticTextProbeStatus:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
			UI.m_staticTextProbeStatus:SetLabel("\nSelected Probe Is\nCurrently Inactive")
		end
		UI.m_staticTextProbeStatus:Refresh()
	end
	LastCheck = ProbeState --Set LastCheck so we only run this statement once for each probe state change. 
end

function m_menuItemDocsOnMenuSelection()
	local major, minor = wx.wxGetOsVersion()
    local dir = mc.mcCntlGetMachDir(inst);
    local cmd = "explorer.exe /open," .. dir .. "\\Docs\\TouchOffHelp.pdf"
    if(minor <= 5) then -- Xp we don't need the /open
        cmd = "explorer.exe ," .. dir .. "\\Docs\\TouchOffHelp.pdf"
    end
    wx.wxExecute(cmd);
end

function m_textCtrlProbeFeedRateOnKillFocus()
	local SetProbeRate = UI.m_textCtrlProbeFeedRate:GetValue()
	SetProbeRate = math.abs (SetProbeRate) --Make sure value is unsigned
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffProbeRate', tostring (SetProbeRate))
end

function m_textCtrlRetractDistanceOnKillFocus()
	local SetRetractDistance = UI.m_textCtrlRetractDistance:GetValue()
	SetRetractDistance = math.abs (SetRetractDistance) --Make sure value is unsigned
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffRetractDistance', tostring (SetRetractDistance))
end

function m_textCtrlPrepFeedRateOnKillFocus()
	local SetPrepFeedRate = UI.m_textCtrlPrepFeedRate:GetValue()
	SetPrepFeedRate = math.abs (SetPrepFeedRate) --Make sure value is unsigned
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffPrepRate', tostring (SetPrepFeedRate))
end

function m_textCtrlPrepDistanceOnKillFocus()
	local SetPrepDistance = UI.m_textCtrlPrepDistance:GetValue()
	SetPrepDistance = math.abs (SetPrepDistance) --Make sure value is unsigned
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffPrepDistance', tostring (SetPrepDistance))
end

function m_textCtrlToolDiamOnKillFocus()
	local SetTouchToolDiam = UI.m_textCtrlToolDiam:GetValue()
	SetTouchToolDiam = math.abs (SetTouchToolDiam) --Make sure value is unsigned
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffToolDiam', tostring (SetTouchToolDiam))
end

function m_textCtrlTouchPlateHeightOnKillFocus()
	local SetTouchPlate = UI.m_textCtrlTouchPlateHeight:GetValue()
	SetTouchPlate = math.abs (SetTouchPlate) --Make sure value is unsigned
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffPlate', tostring (SetTouchPlate))
end

function m_choiceProbeCodeOnChoice()
	rc = UI.m_choiceProbeCode:GetSelection()
	if rc == 0 then
		mc.mcProfileWriteString(inst, 'ToffParams', 'ToffProbeCode', '31')
	elseif rc == 1 then
		mc.mcProfileWriteString(inst, 'ToffParams', 'ToffProbeCode', '31.1')
	elseif rc == 2 then
		mc.mcProfileWriteString(inst, 'ToffParams', 'ToffProbeCode', '31.2')
	elseif rc == 3 then
		mc.mcProfileWriteString(inst, 'ToffParams', 'ToffProbeCode', '31.3')
	end
end

function m_choiceCornerTouchOnChoice()
	rc = UI.m_choiceCornerTouch:GetSelection()
	rc = math.tointeger(rc)
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffCornerOption', tostring(rc))
	UI.m_bpButtonTopLeft:SetBitmapLabel(wx.wxBitmap(ImageTopLeft(tostring(rc)))) --Set button image based on selected option.
	UI.m_bpButtonTopRight:SetBitmapLabel(wx.wxBitmap(ImageTopRight(tostring(rc)))) --Set button image based on selected option.
	UI.m_bpButtonBottomLeft:SetBitmapLabel(wx.wxBitmap(ImageBottomLeft(tostring(rc)))) --Set button image based on selected option.
	UI.m_bpButtonBottomRight:SetBitmapLabel(wx.wxBitmap(ImageBottomRight(tostring(rc)))) --Set button image based on selected option.
end

function m_choiceCenterTouchOnChoice()
	rc = UI.m_choiceCenterTouch:GetSelection()
	rc = math.tointeger(rc)
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffCenterOption', tostring(rc))
	UI.m_bpButtonCenter:SetBitmapLabel(wx.wxBitmap(ImageCenter(tostring(rc)))) --Set button image based on selected option.
end

function m_choiceMeasureAngleOnChoice()
	rc = UI.m_choiceMeasureAngle:GetSelection()
	rc = math.tointeger(rc)
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffAngleOption', (tostring(rc)))
	
	UI.m_bpButtonMeasureAngle:SetBitmapLabel(wx.wxBitmap(ImageMeasureAngle(tostring(rc)))) --Set button image based on selected option.
end

function m_choiceZOnlyOnChoice()
	rc = UI.m_choiceZOnly:GetSelection()
	rc = math.tointeger(rc)
	mc.mcProfileWriteString(inst, 'ToffParams', 'ToffZOnlyOption', (tostring(rc)))
	UI.m_bpButtonZOnly:SetBitmapLabel(wx.wxBitmap(ImageZOnly(tostring(rc)))) --Set button image based on selected option.
end

function m_buttonMachineWorkOnButtonClick()
	--Toggle
	if (MachWorkDRO == true) then
		MachWorkDRO = false
	else
		MachWorkDRO = true
	end
	
	if (MachWorkDRO == true) then 	--Set Machine/Work to work coordinates
		UI.m_buttonMachineWork:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
		UI.m_buttonMachineWork:SetForegroundColour( wx.wxColour( 255, 255, 255 ) )
		UI.m_buttonMachineWork:SetLabel( "Work/Machine Toggle\nCurrently Displaying\nWork Coordinates" )
	else 							--Set Machine/Work to machine coordinates
		UI.m_buttonMachineWork:SetBackgroundColour( wx.wxColour( 255, 0, 0 ) )
		UI.m_buttonMachineWork:SetForegroundColour( wx.wxColour( 0, 0, 0 ) )
		UI.m_buttonMachineWork:SetLabel( "Work/Machine Toggle\nCurrently Displaying\nMachine Coordinates" )
	end
end

function m_bpButtonTopLeftOnButtonClick()
	--rc = UI.m_choiceCornerTouch:GetSelection()
	--if rc == 0 then
	co = coroutine.create (TouchZnegYnegXpos0)
	--elseif rc == 1 then
	--co = coroutine.create (TouchZnegYnegXpos1)
	--elseif rc == 2 then
	--co = coroutine.create (TouchZnegYnegXpos2)
	--elseif rc == 3 then
	--co = coroutine.create (TouchZnegYnegXpos3)
	--end
end

function m_bpButtonTopOnButtonClick()
	co = coroutine.create (TouchOffYNeg0)
end

function m_bpButtonTopRightOnButtonClick()
	--rc = UI.m_choiceCornerTouch:GetSelection()
	--if rc == 0 then
	co = coroutine.create (TouchZnegYnegXneg0)
	--elseif rc == 1 then
	--co = coroutine.create (TouchZnegYnegXneg1)
	--elseif rc == 2 then
	--co = coroutine.create (TouchZnegYnegXneg2)
	--elseif rc == 3 then
	--co = coroutine.create (TouchZnegYnegXneg3)
	--end
end

function m_bpButtonLeftOnButtonClick()
	co = coroutine.create (TouchOffXPos0)
end

function m_bpButtonCenterOnButtonClick()
	--rc = UI.m_choiceCenterTouch:GetSelection()
	--if rc == 0 then
	co = coroutine.create (TouchCenter0)
	--elseif rc == 1 then
	--co = coroutine.create (TouchCenter1)
	--elseif rc == 2 then
	--co = coroutine.create (TouchCenter2)
	--elseif rc == 3 then
	--co = coroutine.create (TouchCenter3)
	--end
end

function m_bpButtonRightOnButtonClick()
	co = coroutine.create (TouchOffXNeg0)
end

function m_bpButtonBottomLeftOnButtonClick()
	--rc = UI.m_choiceCornerTouch:GetSelection()
	--if rc == 0 then
	co = coroutine.create (TouchZnegYposXpos0)
	--elseif rc == 1 then
	--co = coroutine.create (TouchZnegYposXpos1)
	--elseif rc == 2 then
	--co = coroutine.create (TouchZnegYposXpos2)
	--elseif rc == 3 then
	--co = coroutine.create (TouchZnegYposXpos3)
	--end
end

function m_bpButtonBottomOnButtonClick()
	co = coroutine.create (TouchOffYPos0)
end

function m_bpButtonBottomRightOnButtonClick()
	--rc = UI.m_choiceCornerTouch:GetSelection()
	--if rc == 0 then
	co = coroutine.create (TouchZnegYposXneg0)
	--elseif rc == 1 then
	--co = coroutine.create (TouchZnegYposXneg1)
	--elseif rc == 2 then
	--co = coroutine.create (TouchZnegYposXneg2)
	--elseif rc == 3 then
	--co = coroutine.create (TouchZnegYposXneg3)
	--end
end

function m_bpButtonMeasureAngleOnButtonClick()
	--rc = UI.m_choiceMeasureAngle:GetSelection()
	--if rc == 0 then	--Find X+ angle
	co = coroutine.create (Angle0)
	--elseif rc == 1 then	--Find X- angle
	--co = coroutine.create (Angle1)
	--elseif rc == 2 then	--Find Y+ angle
	--co = coroutine.create (Angle2)
	--elseif rc == 3 then	--Find Y- angle
	--co = coroutine.create (Angle3)
	--end
end

function m_bpButtonZOnlyOnButtonClick()
	rc = UI.m_choiceZOnly:GetSelection()
	if rc == 0 then	--Material top
	co = coroutine.create (TouchOffZNeg0)
	elseif rc == 1 then	--TLO
	co = coroutine.create (TouchOffZNeg1)
	--elseif rc == 2 then	--Material bottom
	--co = coroutine.create (TouchOffZNeg2)
	--elseif rc == 3 then	--Material thickness
	--co = coroutine.create (TouchOffZNeg3)
	end
end

------------ Embedded Images ----------------------

function ImageTopLeft(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 282 2",
		"  	c None",
		". 	c #9F9F9F",
		"+ 	c #989898",
		"@ 	c #929292",
		"# 	c #8C8C8C",
		"$ 	c #898989",
		"% 	c #878787",
		"& 	c #888888",
		"* 	c #939393",
		"= 	c #FFFFFF",
		"- 	c #8E8E8E",
		"; 	c #EDEDED",
		"> 	c #EEEEEE",
		", 	c #EBEBEB",
		"' 	c #8F8F8F",
		") 	c #EFEFEF",
		"! 	c #FCFCFC",
		"~ 	c #FDFDFD",
		"{ 	c #ECECEC",
		"] 	c #F4F4F4",
		"^ 	c #000000",
		"/ 	c #EAEAEA",
		"( 	c #8D8D8D",
		"_ 	c #F0F0F0",
		": 	c #161616",
		"< 	c #FBFBFB",
		"[ 	c #E8E8E8",
		"} 	c #909090",
		"| 	c #FAFAFA",
		"1 	c #E9E9E9",
		"2 	c #E7E7E7",
		"3 	c #F8F8F8",
		"4 	c #FEFEFE",
		"5 	c #E6E6E6",
		"6 	c #F9F9F9",
		"7 	c #E5E5E5",
		"8 	c #E4E4E4",
		"9 	c #919191",
		"0 	c #F5F5F5",
		"a 	c #515151",
		"b 	c #090909",
		"c 	c #525252",
		"d 	c #E3E3E3",
		"e 	c #F2F2F2",
		"f 	c #656565",
		"g 	c #111111",
		"h 	c #E2E2E2",
		"i 	c #F1F1F1",
		"j 	c #575757",
		"k 	c #E1E1E1",
		"l 	c #4D4D4D",
		"m 	c #121212",
		"n 	c #4E4E4E",
		"o 	c #404040",
		"p 	c #020202",
		"q 	c #010101",
		"r 	c #424242",
		"s 	c #DFDFDF",
		"t 	c #E0E0E0",
		"u 	c #363636",
		"v 	c #030303",
		"w 	c #131313",
		"x 	c #373737",
		"y 	c #F7F7F7",
		"z 	c #F3F3F3",
		"A 	c #2D2D2D",
		"B 	c #040404",
		"C 	c #DDDDDD",
		"D 	c #DEDEDE",
		"E 	c #242424",
		"F 	c #050505",
		"G 	c #272727",
		"H 	c #DBDBDB",
		"I 	c #DCDCDC",
		"J 	c #1B1B1B",
		"K 	c #D7D7D7",
		"L 	c #CFCFCF",
		"M 	c #CBCBCB",
		"N 	c #949494",
		"O 	c #DADADA",
		"P 	c #D8D8D8",
		"Q 	c #D9D9D9",
		"R 	c #222222",
		"S 	c #D6D6D6",
		"T 	c #D0D0D0",
		"U 	c #979797",
		"V 	c #D5D5D5",
		"W 	c #D4D4D4",
		"X 	c #D2D2D2",
		"Y 	c #CDCDCD",
		"Z 	c #C9C9C9",
		"` 	c #D3D3D3",
		" .	c #CCCCCC",
		"..	c #C8C8C8",
		"+.	c #ACACAC",
		"@.	c #535353",
		"#.	c #2A2A2A",
		"$.	c #232323",
		"%.	c #252525",
		"&.	c #282828",
		"*.	c #2C2C2C",
		"=.	c #303030",
		"-.	c #333333",
		";.	c #383838",
		">.	c #3C3C3C",
		",.	c #474747",
		"'.	c #4C4C4C",
		").	c #545454",
		"!.	c #585858",
		"~.	c #5A5A5A",
		"{.	c #5E5E5E",
		"].	c #5F5F5F",
		"^.	c #616161",
		"/.	c #626262",
		"(.	c #686868",
		"_.	c #828282",
		":.	c #BBBBBB",
		"<.	c #C7C7C7",
		"[.	c #7F7F7F",
		"}.	c #353535",
		"|.	c #3F3F3F",
		"1.	c #414141",
		"2.	c #444444",
		"3.	c #484848",
		"4.	c #4B4B4B",
		"5.	c #666666",
		"6.	c #696969",
		"7.	c #6C6C6C",
		"8.	c #6F6F6F",
		"9.	c #717171",
		"0.	c #747474",
		"a.	c #9E9E9E",
		"b.	c #CACACA",
		"c.	c #C5C5C5",
		"d.	c #AEAEAE",
		"e.	c #292929",
		"f.	c #3A3A3A",
		"g.	c #3E3E3E",
		"h.	c #454545",
		"i.	c #464646",
		"j.	c #494949",
		"k.	c #505050",
		"l.	c #6D6D6D",
		"m.	c #727272",
		"n.	c #757575",
		"o.	c #767676",
		"p.	c #BABABA",
		"q.	c #423F3D",
		"r.	c #453E37",
		"s.	c #4C4033",
		"t.	c #4F4131",
		"u.	c #524435",
		"v.	c #52493F",
		"w.	c #534F4B",
		"x.	c #555453",
		"y.	c #646464",
		"z.	c #6E6E6E",
		"A.	c #707070",
		"B.	c #737373",
		"C.	c #777777",
		"D.	c #848484",
		"E.	c #3F3E3D",
		"F.	c #423B34",
		"G.	c #493825",
		"H.	c #2E5075",
		"I.	c #1B5FAB",
		"J.	c #1269C8",
		"K.	c #136ACA",
		"L.	c #2A5C94",
		"M.	c #504E4B",
		"N.	c #5B5043",
		"O.	c #5A5652",
		"P.	c #5D5D5D",
		"Q.	c #6B6B6B",
		"R.	c #41403F",
		"S.	c #453B31",
		"T.	c #3F3D3A",
		"U.	c #066EE2",
		"V.	c #007EFF",
		"W.	c #007AFF",
		"X.	c #0079FF",
		"Y.	c #007DFF",
		"Z.	c #2D619B",
		"`.	c #625444",
		" +	c #5E5B57",
		".+	c #606060",
		"++	c #676767",
		"@+	c #6A6A6A",
		"#+	c #434343",
		"$+	c #453F37",
		"%+	c #403E3D",
		"&+	c #0081FF",
		"*+	c #0076FA",
		"=+	c #0176F8",
		"-+	c #0077FD",
		";+	c #2F639B",
		">+	c #63574A",
		",+	c #5F5E5E",
		"'+	c #636363",
		")+	c #464441",
		"!+	c #4D3C2A",
		"~+	c #076FE3",
		"{+	c #007BFF",
		"]+	c #5A5651",
		"^+	c #625C56",
		"/+	c #555555",
		"(+	c #4B443C",
		"_+	c #315379",
		":+	c #0078FF",
		"<+	c #156DCE",
		"[+	c #65584A",
		"}+	c #4A4A4A",
		"|+	c #504436",
		"1+	c #1D61AC",
		"2+	c #0076FC",
		"3+	c #0076FD",
		"4+	c #68543F",
		"5+	c #343434",
		"6+	c #554635",
		"7+	c #0671E7",
		"8+	c #0076F9",
		"9+	c #007CFF",
		"0+	c #665037",
		"a+	c #5B5B5B",
		"b+	c #0A0A0A",
		"c+	c #393939",
		"d+	c #594B3B",
		"e+	c #156BCA",
		"f+	c #624D35",
		"g+	c #595959",
		"h+	c #5C5C5C",
		"i+	c #5A5146",
		"j+	c #2E6099",
		"k+	c #5D4C39",
		"l+	c #5B5652",
		"m+	c #575552",
		"n+	c #285C96",
		"o+	c #544A40",
		"p+	c #565656",
		"q+	c #060606",
		"r+	c #1A1A1A",
		"s+	c #5C5B5A",
		"t+	c #31659F",
		"u+	c #066FE4",
		"v+	c #503E2A",
		"w+	c #4D4A46",
		"x+	c #615E5A",
		"y+	c #695A4A",
		"z+	c #3165A0",
		"A+	c #3D3D3D",
		"B+	c #463F38",
		"C+	c #64615D",
		"D+	c #695D50",
		"E+	c #5F5B56",
		"F+	c #166ECF",
		"G+	c #0075FC",
		"H+	c #0870E4",
		"I+	c #295D96",
		"J+	c #453E36",
		"K+	c #3D3C3B",
		"L+	c #656463",
		"M+	c #655F59",
		"N+	c #685C4E",
		"O+	c #6B5843",
		"P+	c #68523A",
		"Q+	c #644F38",
		"R+	c #4C4845",
		"S+	c #4F4F4F",
		"T+	c #313131",
		"U+	c #2B2B2B",
		"V+	c #262626",
		"W+	c #838383",
		"X+	c #ADADAD",
		"Y+	c #D1D1D1",
		"Z+	c #CECECE",
		"`+	c #C6C6C6",
		" @	c #C3C3C3",
		".@	c #C0C0C0",
		"+@	c #999999",
		"@@	c #9B9B9B",
		"#@	c #969696",
		"$@	c #9D9D9D",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # # # $ $ $ $ $ $ $ % $ $ % $ $ % $ $ $ $ & & & $ % $ % $ % $ $ $ $ $ $ & & & & $ $ $ $ % $ $ $ $ $ % # # @ + . ",
		". * = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = @ . ",
		". - = ; ; ; > > ; ; ; ; ; ; ; ; ; > > ; > ; > ; ; ; > > > ; > > > > ; ; ; ; ; > > > ; ; ; ; > > ; ; > ; ; ; ; > , = # . ",
		". ' = ; ; ; ; ; ; ; ; ; ; ) ) ; ) ; ; ) ; ; ; ; ; ; ) ; ; ; ; ; ; > ! = = = = = = = = = ! > ; ; ; ; ; ; ; ; ; ; , = # . ",
		". ' ~ { { { { { { { { { { > > { > { { { { { { { { { { > { { { { { > ] ^ ^ ^ ^ ^ ^ ^ ^ ^ ] > { { { { { { { { { { / = ( . ",
		". ' ~ ; ; , ; , , ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; , , , ; ; ; ; _ = ^ : : : : : : : ^ = _ ; ; ; ; ; , ; ; ; ; / = ( . ",
		". ' < / / / / / / / { / / { { / / / / / { / / { / / / / / / / / / ) = ^ : : : : : : : ^ = ; / / / / { { / / { / [ = ( . ",
		". } | 1 1 , 1 , 1 1 1 1 , , 1 1 / / 1 , 1 1 1 1 , 1 / 1 , , 1 1 1 { = ^ : : : : : : : ^ = { 1 , 1 1 1 1 1 , , 1 2 = ( . ",
		". } 3 [ [ [ / / [ [ [ [ / / [ [ [ [ [ / [ [ / [ [ [ [ [ [ [ [ / / , 4 ^ : : : : : : : ^ 4 , [ / [ [ [ [ [ / / [ 5 = ( . ",
		". } 6 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 1 1 1 1 1 1 1 1 1 1 , 4 ^ : : : : : : : ^ 4 , 1 2 1 1 1 1 1 1 1 1 5 = - . ",
		". } ] 7 [ 5 5 5 [ 7 5 5 5 5 [ 5 5 [ 5 5 [ 5 5 [ 8 [ [ [ 5 ; ~ = = = = ^ : : : : : : : ^ = = = = ~ ; 5 5 [ [ 5 5 8 = - . ",
		". 9 0 7 2 7 5 7 7 2 5 5 7 7 2 7 7 2 7 7 7 7 7 2 2 2 2 7 2 ; a ^ ^ ^ ^ b : : : : : : : b ^ ^ ^ ^ c ; 5 7 7 7 7 5 d = - . ",
		". 9 e 8 8 8 7 8 5 8 8 7 8 5 8 8 8 5 8 7 7 7 8 8 8 8 8 8 7 { = f ^ g : : : : : : : : : : : g ^ f = { 7 7 7 7 7 7 h = - . ",
		". 9 i d d d d d d d d d d d d d d d d d d d d d d 8 d 8 h 8 , = j ^ g : : : : : : : : : g ^ j = , d d d d d d d k = ' . ",
		". 9 i 8 8 8 8 h 8 8 8 8 h h h 8 8 k 8 8 8 8 8 8 h d h 8 h 8 8 { 4 l ^ m : : : : : : : m ^ n = { 8 8 8 8 8 h h 8 h = ' . ",
		". 9 _ d d d k k d d d k k d k k d k d d k d d k k k k k k d d k { < o p m : : : : : m q r | / d d k k d d d k k s = ' . ",
		". @ ; h t t t t t t t t t h t t t h h t t t t h t t h h t t t t h { 6 u v w : : : w v x y , h h h t t h h h t h t 4 ' . ",
		". @ { k s t s s s s s s k s s t s s s s t t s s s s s k k s t s s t / z A B w : w B A z / k s s k k s s s s s s C < } . ",
		". @ , D D D D t D D t D D D D D D D D D D s s s s s s s s s s s s s t , ) E F g F G ) , s s s s s s s s s s s t t ~ @ . ",
		". @ , s s s s s s s C s s s s s s s s s C D C H H I I I I I I I I I I I [ 5 J ^ J 5 [ I I I I I I I I I I I H K L M N . ",
		". @ 2 D D D I I I D I D D D I D D D I D C I H O P Q K K K K K K K Q Q Q O 5 H R C 5 P K Q Q Q Q Q K K K K Q P S T M U . ",
		". * 5 H C H C C C C H H H H C C C H H C O O K S V W W V V V V V W W W W W V s t s S W W W W W W W W V V W W V X Y Z U . ",
		". * 5 O O O I I I O O O O O I I O O O H O K V ` X W H 8 , ; ; ; ; { { ; { , , / 1 2 5 7 7 8 7 7 d d k C K ` X T  ...U . ",
		". * 7 H H H H H H H H H H H H H H H H H P S W X S k +.@.#.$.E %.&.#.*.=.-.;.>.r ,.'.a ).!.~.{.].^./.(._.:.H W L M <.+ . ",
		". * d Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q O Q K ` W k [.G }.>.|.1.r r 2.3.4.l c ).~.{./.5.6.7.8.9.9.0.0.0.8.(.a.O L b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O K V ` H d.e.f.g.g.g.|.r r h.i.j.n k.).~.{./.5.6.7.l.9.m.m.n.o.n.0.(.p.W b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O P S W 8 ).u o o g.g.o q.r.s.t.u.v.w.x.!.{./.y.6.7.z.A.m.B.B.0.o.C.9.D.Q b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O P S W , *.g.1.|.o E.F.G.H.I.J.K.L.M.N.O.P.^.f (.Q.z.A.A.B.0.n.o.n.n.7.C b.c.+ . ",
		". * 7 O O O O O O O O t t t O O O O O O P S W ; %.1.r o R.S.T.U.V.W.X.X.W.Y.Z.`. +.+y.++@+l.8.9.m.m.B.n.o.n.y.s b.c.+ . ",
		". * 7 O O O O O O O O ; n 0 k O O O O O P S W ; &.2.r #+$+%+&+W.*+=+=+=+=+-+W.;+>+,+'+5.6.7.z.A.A.B.m.B.n.0.f t b.c.+ . ",
		". * 7 O O O O O O O O | ^ .+] h O O O O P S W { #.i.2.)+!+~+X.=+=+=+=+=+=+=+-+{+]+^+.+f (.Q.l.8.8.m.B.m.0.B.'+t b.c.+ . ",
		". * 7 O O O O O O O O = ^ ^ /+] h O O O P S W { *.3.i.(+_+Y.*+=+=+=+=+=+=+=+=+:+<+[+.+'+f 6.7.7.8.8.A.m.B.B.^.t b.c.+ . ",
		". * 7 O O H I I I I I = ^ g ^ }+i d O O P S W , =.4.j.|+1+W.=+=+=+=+=+=+=+=+=+2+3+4+{.^.f 5.@+7.7.8.A.9.A.m..+t b.c.+ . ",
		". * 7 O 2 t > > > > > = ^ : g q 1.) 8 O P S W , 5+n '.6+7+:+=+=+=+=+=+=+=+=+=+8+9+0+a+]./.f (.@+7.l.z.8.A.A.].k b.c.+ . ",
		". * 7 O ] ^ ^ ^ ^ ^ ^ ^ b+: : m p u ; 7 P S W / c+k.a d+e+:+=+=+=+=+=+=+=+=+=+*+Y.f+g+h+.+'+f 5.(.Q.7.l.z.z.a+k b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : m v *.1 8 K W 1 g.)./+i+j+X.=+=+=+=+=+=+=+=+=+:+~+k+).g+P..+^.f ++(.@+Q.Q.7.g+k b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : : w B G k d V 1 r !.g+l+m+{+-+=+=+=+=+=+=+=+*+9+n+o+c p+!.P.]..+y.f f 5.++6./+h b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : : : w q+r+Q D [ ,.{.P.s+>+t+X.3+=+=+=+=+=+*+W.u+v+w+l c p+g+~.{..+/.'+y.f 5.a d b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : : : : m ^ R s 2 './.^..+x+y+z+W.:+2+8+*+:+9+u+A+B+,.4.l c /+!.~.h+{.]..+^./.'.d b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : : : w q+r+K D 5 a 5.f y.'+C+D+E+F+G+{+9+H+I+v+J+K+r ,.4.n a ).p+!.~.a+h+P.{.3.8 b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : : w B $.h d V 5 ).6.++5.f f L+M+N+O+P+Q+k+o+R+i.|.g.r ,.}+l n c ).).j !.g+!.#+7 b.c.+ . ",
		". * 7 O = ^ : : : : : : : : : : m v A 1 8 K W 7 !.7.Q.Q.@+(.++f ^..+P.g+).c '.j.2.o g.r h.3.'.n k.c @.)./+).g.5 b.c.+ . ",
		". * 7 O ] ^ ^ ^ ^ ^ ^ ^ b+: : m p 5+{ 7 P S W 7 ~.z.z.l.7.Q.(.5.f '+.+h+g+@.S+'.3.#+g.|.r i.,.j.4.n n S+a k.c+5 b.c.+ . ",
		". * 7 O 2 t > > > > > = ^ : g q |.) 8 H P S W 8 {.A.A.8.z.l.7.@+(.f /.].a+j @.S+j.h.r A+|.#+2.i.j.j.'.4.'.n 5+2 b.c.+ . ",
		". * 7 O O H I I I I I = ^ g ^ }+i d O O P S W 8 ].m.A.9.A.8.7.7.@+5.f ^.{.~.).a l j.2.1.A+|.#+h.h.i.,.3.j.4.T+[ b.c.+ . ",
		". * 7 O O O O O O O O = ^ ^ @.] h O O O P S W 8 .+B.B.m.A.8.8.7.7.6.f '+.+h+!.c S+4.i.2.o g.|.1.2.h.i.,.i.3.A [ b.c.+ . ",
		". * 7 O O O O O O O O | ^ .+] h O O O O P S W d '+B.0.m.B.m.8.8.l.Q.(.f .+{.!./+a l j.i.#+|.g.|.r #+2.h.2.i.U+1 b.c.+ . ",
		". * 7 O O O O O O O O ; n z k O O O O O P S W d y.0.n.B.m.B.A.A.z.7.6.5.'+].a+/+a n j.,.#+r |.g.|.o 1.#+r 2.e.1 b.c.+ . ",
		". * 7 O O O O O O O O t t t O O O O O O P S W d '+n.o.n.B.m.m.9.8.l.@+++y..+h+!.c S+}+3.2.#+o g.g.|.1.o r 1.V+1 b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O P S W k Q.n.n.o.n.0.B.A.A.z.Q.(.f ^.P.j @.k.4.j.h.2.r |.g.g.o |.1.g.A 2 b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O P S W C W+9.C.o.0.B.B.m.A.z.7.6.y./.{.!./+a '.}+,.h.1.1.o g.g.o o u /+t b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O P S W K p.(.0.n.o.n.m.m.9.l.7.6.5./.{.~.).k.n j.i.h.r r |.g.g.g.f.e.X+P b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O P S W ` H a.6.A.0.0.0.9.9.8.7.6.5./.{.~.).c l 4.3.2.r r 1.|.>.}.G [.k Y+b.c.+ . ",
		". * 7 O O O O O O O O O O O O O O O O O K V ` X W O p.W+6.'+/.].].a+!./+a '.3.#+A+c+5+T+A U+e.V+%.$.e.).+.k V Z+M `++ . ",
		". * 7 O O O O O O O O O O O O O O O O H ` X Y+L L T W O D s t t k k k h d d 8 7 5 2 2 [ [ 1 1 / / / 2 k P Y+Z+ .Z  @+ . ",
		". * 7 O O O O O O O O O O O O O O O O I M  .M b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.b.M Z c..@+@. ",
		". U ; 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 2 c.`+<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.<.`+c..@:.@@. ",
		". @@U * * * * * * * * * * * * * * * * N #@+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +@@@$@. ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '1' then
		Image = {
		"60 60 126 2",
		"  	c #ACACAC",
		". 	c #ADADAD",
		"+ 	c #A5A5A5",
		"@ 	c #9E9E9E",
		"# 	c #9D9D9D",
		"$ 	c #9C9C9C",
		"% 	c #F2F2F2",
		"& 	c #FFFFFF",
		"* 	c #B8B8B8",
		"= 	c #B3B3B3",
		"- 	c #F1F1F1",
		"; 	c #F0F0F0",
		"> 	c #FDFDFD",
		", 	c #C5C5C5",
		"' 	c #BDBDBD",
		") 	c #AEAEAE",
		"! 	c #ECECEC",
		"~ 	c #EEEEEE",
		"{ 	c #EFEFEF",
		"] 	c #FBFBFB",
		"^ 	c #C3C3C3",
		"/ 	c #AFAFAF",
		"( 	c #EBEBEB",
		"_ 	c #EDEDED",
		": 	c #FAFAFA",
		"< 	c #C2C2C2",
		"[ 	c #C0C0C0",
		"} 	c #EAEAEA",
		"| 	c #F9F9F9",
		"1 	c #BFBFBF",
		"2 	c #B0B0B0",
		"3 	c #E9E9E9",
		"4 	c #F8F8F8",
		"5 	c #F7F7F7",
		"6 	c #C1C1C1",
		"7 	c #E8E8E8",
		"8 	c #F6F6F6",
		"9 	c #E7E7E7",
		"0 	c #E6E6E6",
		"a 	c #F3F3F3",
		"b 	c #E5E5E5",
		"c 	c #E4E4E4",
		"d 	c #E3E3E3",
		"e 	c #E2E2E2",
		"f 	c #BEBEBE",
		"g 	c #E1E1E1",
		"h 	c #ABABAB",
		"i 	c #161616",
		"j 	c #E0E0E0",
		"k 	c #AAAAAA",
		"l 	c #DFDFDF",
		"m 	c #A9A9A9",
		"n 	c #DEDEDE",
		"o 	c #DCDCDC",
		"p 	c #DDDDDD",
		"q 	c #BBBBBB",
		"r 	c #DBDBDB",
		"s 	c #A8A8A8",
		"t 	c #A7A7A7",
		"u 	c #A6A6A6",
		"v 	c #DADADA",
		"w 	c #D8D8D8",
		"x 	c #D9D9D9",
		"y 	c #B9B9B9",
		"z 	c #D6D6D6",
		"A 	c #D7D7D7",
		"B 	c #7C7C7C",
		"C 	c #434343",
		"D 	c #373737",
		"E 	c #444444",
		"F 	c #CDCDCD",
		"G 	c #C8C8C8",
		"H 	c #C9C9C9",
		"I 	c #CACACA",
		"J 	c #C4C4C4",
		"K 	c #D2D2D2",
		"L 	c #B4B4B4",
		"M 	c #CCCCCC",
		"N 	c #C7C7C7",
		"O 	c #3B3B3B",
		"P 	c #3C3C3C",
		"Q 	c #CFCFCF",
		"R 	c #B1B1B1",
		"S 	c #C6C6C6",
		"T 	c #BCBCBC",
		"U 	c #363636",
		"V 	c #D0D0D0",
		"W 	c #B7B7B7",
		"X 	c #2E2E2E",
		"Y 	c #B2B2B2",
		"Z 	c #2A2A2A",
		"` 	c #252525",
		" .	c #CBCBCB",
		"..	c #212121",
		"+.	c #9F9F9F",
		"@.	c #1D1D1D",
		"#.	c #1E1E1E",
		"$.	c #979797",
		"%.	c #1A1A1A",
		"&.	c #1B1B1B",
		"*.	c #989898",
		"=.	c #CECECE",
		"-.	c #8F8F8F",
		";.	c #181818",
		">.	c #868686",
		",.	c #171717",
		"'.	c #7D7D7D",
		").	c #727272",
		"!.	c #737373",
		"~.	c #313131",
		"{.	c #333333",
		"].	c #494949",
		"^.	c #555555",
		"/.	c #535353",
		"(.	c #525252",
		"_.	c #3F3F3F",
		":.	c #6C6C6C",
		"<.	c #484848",
		"[.	c #545454",
		"}.	c #515151",
		"|.	c #464646",
		"1.	c #323232",
		"2.	c #717171",
		"3.	c #A1A1A1",
		"4.	c #A0A0A0",
		"5.	c #A2A2A2",
		"      .             . . .     . .       .   .     .   . .         . .     .     .         .   . .     .       .         ",
		"    + @ # # # # # # # # # # $ # # $ # # $ # # # # $ $ $ # $ # $ # $ # # # # # # $ $ $ $ # # # # $ # # # # # $ # #   . . ",
		"  % & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & * = ",
		"= - - ; ; ; - - ; ; ; ; ; ; ; ; ; - - ; - ; - ; ; ; - - - ; - - - - ; ; ; ; ; - - - ; ; ; ; - - ; ; - ; ; ; ; - ; > , ' ",
		") ! ; ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ { ~ ~ { ~ ~ ~ ~ ~ ~ { ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ] ^ ' ",
		"/ ( ~ _ _ _ _ _ _ _ _ _ _ ~ ~ _ ~ _ _ _ _ _ _ _ _ _ _ ~ _ _ _ _ _ _ _ _ ~ ~ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ : < [ ",
		"/ } ~ _ _ ! _ ! ! _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! ! ! _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ | < 1 ",
		"2 3 ! ( ( ( ( ( ( ( ! ( ( ! ! ( ( ( ( ( ! ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ! ! ( ( ! ( ( 4 < 1 ",
		"/ 3 ( } } ( } ( } } } } ( ( } } } } } ( } } } } ( } } } ( ( } } } } } } } } } } } } ( } } } } ( } } } } } ( ( } } 5 6 1 ",
		"/ 7 } 3 3 3 } } 3 3 3 3 } } 3 3 3 3 3 } 3 3 } 3 3 3 3 3 3 3 3 } } 3 3 } 3 3 3 3 3 3 3 3 3 3 3 } 3 3 3 3 3 } } 3 3 8 6 1 ",
		"/ 9 } 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 7 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 7 3 3 3 3 3 3 3 3 3 8 6 1 ",
		"2 0 9 0 7 9 9 9 7 0 9 9 9 9 7 9 9 7 9 9 7 9 9 7 0 7 7 7 9 9 7 7 0 7 7 9 7 7 7 9 9 7 9 9 9 7 7 9 7 9 9 9 7 7 9 9 9 a [ [ ",
		"/ b 9 0 9 0 0 0 0 9 0 0 0 0 9 0 0 9 0 0 0 0 0 9 9 9 9 0 9 0 0 0 0 0 9 0 0 0 9 0 0 9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 % 1 1 ",
		"/ c b b b b b b 0 b b b b 0 b b b 0 b b b b b b b b b b b b b b b b b b b b b b b b b 0 b b b b b b b b b b b b b % 1 [ ",
		"2 d c c c c c c c c c c c c c c c c c c c c c c c c c c d c c c c c c c c c c c c c c c c c d c c c c c c c c c c ; 1 [ ",
		"/ d c c c c c d c c c c d d d c c e c c c c c c d d d c d c c c d d c c c c c d c c c c d c c c c c c c c d d c c ~ f [ ",
		"2 e d d d d e e d d d e e d e e d e d d e d d e e e e e e d d e d d d e e e d d d e e d e e e d d e e d d d e e e ~ f 6 ",
		"/ g g e g g g g g g g g g e g g g e e g g g g e h i i i i i i i i i i i i h g e g g g g g g e e e g g e e e g e e _ ' 6 ",
		"/ j j g j j j j j j j j g j j j j j j j j j j j k i i i i i i i i i i i i k j j j g j j j g j j g g j j j j j j j ( ' 6 ",
		"2 l l l l l l j l l j l l l l l l l l l l l l l m i i i i i i i i i i i i m l l l j l l l l l l l l l l l l l l l } ' 6 ",
		"/ l l l l l l l l l n l l l l l l l l l l l l l m i i i i i i i i i i i i m l l l n l l l l l l l l l n l l l l l 3 ' 6 ",
		"2 n o n n n p p p n p n n n p n n n p n n n n n m i i i i i i i i i i i i m n n p n n p n n n n p p p p p p p p n 7 q 6 ",
		"2 p r o p o p p p p o o o o p p p o o p p o o o s i i i i i i i i i i i i t o o p p p p p p o o p p o p p p o o p 9 q < ",
		"/ o r r r r o o o r r r r r o o r r r r r r o o u i i i i i i i i i i i i u r r o r r o r o r r r o r o o o r r r 0 q < ",
		"2 r v r r r r r r r r r r r r r r r r r r r r r u i i i i i i i i i i i i u r r r r r r r r r r r r r r r r r r r c q < ",
		"/ v w x x x v v x x v v v v x v v v v v v x x x u i i i i i i i i i i i i + x x x x v v v v x w x x v v x x x x x d q < ",
		"2 v x x w w x x w x x x x x x x x x x x x x x w + i i i i i i i i i i i i + x x x v x x x v w x x x x x w x x w w d y < ",
		"2 x z A A A A z A w w z z A A A z z B C C C C C D i i i i i i i i i i i i D E C C C C B A A A A A A w z z w A z A j y ^ ",
		"2 F G H H I I H I I I I I I I I I I J C i i i i i i i i i i i i i i i i i i i i i i C J I I I I I I I H I I I I I K L , ",
		"2 M , N G H N N H N N H G N H N H H G f O i i i i i i i i i i i i i i i i i i i i P 1 G H G N G G G N N G G G G G Q = J ",
		"R M S H H G H H G G H H H G G H G G G G T U i i i i i i i i i i i i i i i i i i U q G H H G G H G H H G G H G G H V = , ",
		"R M , H G G H H G G G G H H G G H H G H H W X i i i i i i i i i i i i i i i i X W H G G G G H H G G H H H G G H H V = , ",
		"R M , G G H G H G G G G G H G G H G G H H G Y Z i i i i i i i i i i i i i i Z = H G G G H H H H G H H G G H H H H V = J ",
		"R M S G H G H G H H G H G H G H H G H H H G H   ` i i i i i i i i i i i i `   H H G H H H G G H H H H G H H H H H V = , ",
		"2  .J N G N N G N N N N N N N G G N G G N N G N + ..i i i i i i i i i i ..u N N N N G G N N N N G G N N G N G N N Q Y , ",
		"2  .J N N N N N N G N N N N N N N G N N N N G N N +.@.i i i i i i i i #.+.N N G G N N N N N N N N N N N N N G G N Q = , ",
		"R M , N G N N N N N N N G G N G G N G N N N N N N G $.%.i i i i i i &.*.G N N N N N N G N N N G N N N G G G N N G =.= , ",
		"R  .J N N N N N G G N N N N N N N N N N G N G N N N N -.;.i i i i ;.-.N N N N G G N N N N N G N N N N N G N N N N =.= , ",
		"2  ., N N N N N N N N N N G G N N N N G G G N N N N N N >.,.i i ,.>.G G N N N G N N N N N N N G G G N N G N N N N Q = , ",
		"2  .J N N N N N N N N N N N N N N N N N N N N N N N N N N '.i i '.N N N N N N N N N N N N N N N N N N N N N N N N =.Y , ",
		"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S ).!.S S S S S S S S S S S S S S S S S S S S S S S S S F Y S ",
		"R I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
		"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
		"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
		"R I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
		"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
		"2 H < , , J , , , , , , , , J ~.~.~.{.].^./.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.^.(._.~.~.D :.^ , , , , , , , M Y , ",
		"R H < , , , J , , , , , , J , ~.~.~.{.<.[.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.(.}.|.O 1.D 2.J , , , , , , , M Y , ",
		"2 H < , , J , , , , , , , , , ~.~.~.{.<.[.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.(.}.|.O 1.D 2., , , , , , J , M R S ",
		"2 H < , , , , J J , , J , , , , , , , , , , , J , , , , , , , , , , , , , , , , , , , , , , , , , J , , , , , , ,  .R S ",
		"2 G < , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , J J , , , , , , , , J J , , , , , , , , , , , , M Y , ",
		"R H [ J J ^ J J J J J ^ J J J J J J J J J J J ^ J J J J J J J J J , , ^ J J J J J J J , , J J J J J J J J J J ^ J  .R , ",
		"2 H < , , J , , , , , , , , , , , , , , , , , J J , , , J , , , , , , , , , J , , , , , , J J , , , , , , , , J , M Y J ",
		"2 H < , , , , J J , , J , , , , , , , , , , , J , , , , , , , , , , , , , , , , , , , , , , , , , J , , , , , , ,  .Y < ",
		"2 G < , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , J J , , , , , , , , J J , , , , , , , , , , , , M Y T ",
		"2 H [ J J ^ J J J J J ^ J J J J J J J J J J J ^ J J J J J J J J J , , ^ J J J J J J J , , J J J J J J J J J J ^ J  .  = ",
		"2 H q [ [ [ [ [ [ 1 [ [ 1 [ [ 1 [ [ 1 [ [ [ 1 [ 1 [ [ [ [ [ [ [ 1 [ [ [ [ [ 1 [ 1 [ [ [ [ [ [ 1 1 1 [ [ 1 [ 1 [ [ ,   ) ",
		"2 H g l n n l n n l l l l n n l l n n n l n n l n n n l l n l n n n n l l n n n l n n l l l l n l l n n n l n l l _     ",
		"2   m 3.3.3.3.3.3.3.4.3.4.4.4.3.4.3.5.3.3.3.3.3.3.3.3.4.3.4.3.3.3.3.4.4.3.4.3.4.4.3.4.3.3.4.3.3.3.3.3.3.4.4.4.4.3.      ",
		"2 2 2 . .     . .                 .   . . . . .   . .         . .           .                       . .                 "};
	end
	
	return Image
end

function ImageTop(pic)
	local Image = {
	"60 60 126 2",
	"  	c #ACACAC",
	". 	c #ADADAD",
	"+ 	c #A5A5A5",
	"@ 	c #9E9E9E",
	"# 	c #9D9D9D",
	"$ 	c #9C9C9C",
	"% 	c #F2F2F2",
	"& 	c #FFFFFF",
	"* 	c #B8B8B8",
	"= 	c #B3B3B3",
	"- 	c #F1F1F1",
	"; 	c #F0F0F0",
	"> 	c #FDFDFD",
	", 	c #C5C5C5",
	"' 	c #BDBDBD",
	") 	c #AEAEAE",
	"! 	c #ECECEC",
	"~ 	c #EEEEEE",
	"{ 	c #EFEFEF",
	"] 	c #FBFBFB",
	"^ 	c #C3C3C3",
	"/ 	c #AFAFAF",
	"( 	c #EBEBEB",
	"_ 	c #EDEDED",
	": 	c #FAFAFA",
	"< 	c #C2C2C2",
	"[ 	c #C0C0C0",
	"} 	c #EAEAEA",
	"| 	c #F9F9F9",
	"1 	c #BFBFBF",
	"2 	c #B0B0B0",
	"3 	c #E9E9E9",
	"4 	c #F8F8F8",
	"5 	c #F7F7F7",
	"6 	c #C1C1C1",
	"7 	c #E8E8E8",
	"8 	c #F6F6F6",
	"9 	c #E7E7E7",
	"0 	c #E6E6E6",
	"a 	c #F3F3F3",
	"b 	c #E5E5E5",
	"c 	c #E4E4E4",
	"d 	c #E3E3E3",
	"e 	c #E2E2E2",
	"f 	c #BEBEBE",
	"g 	c #E1E1E1",
	"h 	c #ABABAB",
	"i 	c #161616",
	"j 	c #E0E0E0",
	"k 	c #AAAAAA",
	"l 	c #DFDFDF",
	"m 	c #A9A9A9",
	"n 	c #DEDEDE",
	"o 	c #DCDCDC",
	"p 	c #DDDDDD",
	"q 	c #BBBBBB",
	"r 	c #DBDBDB",
	"s 	c #A8A8A8",
	"t 	c #A7A7A7",
	"u 	c #A6A6A6",
	"v 	c #DADADA",
	"w 	c #D8D8D8",
	"x 	c #D9D9D9",
	"y 	c #B9B9B9",
	"z 	c #D6D6D6",
	"A 	c #D7D7D7",
	"B 	c #7C7C7C",
	"C 	c #434343",
	"D 	c #373737",
	"E 	c #444444",
	"F 	c #CDCDCD",
	"G 	c #C8C8C8",
	"H 	c #C9C9C9",
	"I 	c #CACACA",
	"J 	c #C4C4C4",
	"K 	c #D2D2D2",
	"L 	c #B4B4B4",
	"M 	c #CCCCCC",
	"N 	c #C7C7C7",
	"O 	c #3B3B3B",
	"P 	c #3C3C3C",
	"Q 	c #CFCFCF",
	"R 	c #B1B1B1",
	"S 	c #C6C6C6",
	"T 	c #BCBCBC",
	"U 	c #363636",
	"V 	c #D0D0D0",
	"W 	c #B7B7B7",
	"X 	c #2E2E2E",
	"Y 	c #B2B2B2",
	"Z 	c #2A2A2A",
	"` 	c #252525",
	" .	c #CBCBCB",
	"..	c #212121",
	"+.	c #9F9F9F",
	"@.	c #1D1D1D",
	"#.	c #1E1E1E",
	"$.	c #979797",
	"%.	c #1A1A1A",
	"&.	c #1B1B1B",
	"*.	c #989898",
	"=.	c #CECECE",
	"-.	c #8F8F8F",
	";.	c #181818",
	">.	c #868686",
	",.	c #171717",
	"'.	c #7D7D7D",
	").	c #727272",
	"!.	c #737373",
	"~.	c #313131",
	"{.	c #333333",
	"].	c #494949",
	"^.	c #555555",
	"/.	c #535353",
	"(.	c #525252",
	"_.	c #3F3F3F",
	":.	c #6C6C6C",
	"<.	c #484848",
	"[.	c #545454",
	"}.	c #515151",
	"|.	c #464646",
	"1.	c #323232",
	"2.	c #717171",
	"3.	c #A1A1A1",
	"4.	c #A0A0A0",
	"5.	c #A2A2A2",
	"      .             . . .     . .       .   .     .   . .         . .     .     .         .   . .     .       .         ",
	"    + @ # # # # # # # # # # $ # # $ # # $ # # # # $ $ $ # $ # $ # $ # # # # # # $ $ $ $ # # # # $ # # # # # $ # #   . . ",
	"  % & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & * = ",
	"= - - ; ; ; - - ; ; ; ; ; ; ; ; ; - - ; - ; - ; ; ; - - - ; - - - - ; ; ; ; ; - - - ; ; ; ; - - ; ; - ; ; ; ; - ; > , ' ",
	") ! ; ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ { ~ ~ { ~ ~ ~ ~ ~ ~ { ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ] ^ ' ",
	"/ ( ~ _ _ _ _ _ _ _ _ _ _ ~ ~ _ ~ _ _ _ _ _ _ _ _ _ _ ~ _ _ _ _ _ _ _ _ ~ ~ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ : < [ ",
	"/ } ~ _ _ ! _ ! ! _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! ! ! _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ | < 1 ",
	"2 3 ! ( ( ( ( ( ( ( ! ( ( ! ! ( ( ( ( ( ! ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ! ! ( ( ! ( ( 4 < 1 ",
	"/ 3 ( } } ( } ( } } } } ( ( } } } } } ( } } } } ( } } } ( ( } } } } } } } } } } } } ( } } } } ( } } } } } ( ( } } 5 6 1 ",
	"/ 7 } 3 3 3 } } 3 3 3 3 } } 3 3 3 3 3 } 3 3 } 3 3 3 3 3 3 3 3 } } 3 3 } 3 3 3 3 3 3 3 3 3 3 3 } 3 3 3 3 3 } } 3 3 8 6 1 ",
	"/ 9 } 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 7 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 7 3 3 3 3 3 3 3 3 3 8 6 1 ",
	"2 0 9 0 7 9 9 9 7 0 9 9 9 9 7 9 9 7 9 9 7 9 9 7 0 7 7 7 9 9 7 7 0 7 7 9 7 7 7 9 9 7 9 9 9 7 7 9 7 9 9 9 7 7 9 9 9 a [ [ ",
	"/ b 9 0 9 0 0 0 0 9 0 0 0 0 9 0 0 9 0 0 0 0 0 9 9 9 9 0 9 0 0 0 0 0 9 0 0 0 9 0 0 9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 % 1 1 ",
	"/ c b b b b b b 0 b b b b 0 b b b 0 b b b b b b b b b b b b b b b b b b b b b b b b b 0 b b b b b b b b b b b b b % 1 [ ",
	"2 d c c c c c c c c c c c c c c c c c c c c c c c c c c d c c c c c c c c c c c c c c c c c d c c c c c c c c c c ; 1 [ ",
	"/ d c c c c c d c c c c d d d c c e c c c c c c d d d c d c c c d d c c c c c d c c c c d c c c c c c c c d d c c ~ f [ ",
	"2 e d d d d e e d d d e e d e e d e d d e d d e e e e e e d d e d d d e e e d d d e e d e e e d d e e d d d e e e ~ f 6 ",
	"/ g g e g g g g g g g g g e g g g e e g g g g e h i i i i i i i i i i i i h g e g g g g g g e e e g g e e e g e e _ ' 6 ",
	"/ j j g j j j j j j j j g j j j j j j j j j j j k i i i i i i i i i i i i k j j j g j j j g j j g g j j j j j j j ( ' 6 ",
	"2 l l l l l l j l l j l l l l l l l l l l l l l m i i i i i i i i i i i i m l l l j l l l l l l l l l l l l l l l } ' 6 ",
	"/ l l l l l l l l l n l l l l l l l l l l l l l m i i i i i i i i i i i i m l l l n l l l l l l l l l n l l l l l 3 ' 6 ",
	"2 n o n n n p p p n p n n n p n n n p n n n n n m i i i i i i i i i i i i m n n p n n p n n n n p p p p p p p p n 7 q 6 ",
	"2 p r o p o p p p p o o o o p p p o o p p o o o s i i i i i i i i i i i i t o o p p p p p p o o p p o p p p o o p 9 q < ",
	"/ o r r r r o o o r r r r r o o r r r r r r o o u i i i i i i i i i i i i u r r o r r o r o r r r o r o o o r r r 0 q < ",
	"2 r v r r r r r r r r r r r r r r r r r r r r r u i i i i i i i i i i i i u r r r r r r r r r r r r r r r r r r r c q < ",
	"/ v w x x x v v x x v v v v x v v v v v v x x x u i i i i i i i i i i i i + x x x x v v v v x w x x v v x x x x x d q < ",
	"2 v x x w w x x w x x x x x x x x x x x x x x w + i i i i i i i i i i i i + x x x v x x x v w x x x x x w x x w w d y < ",
	"2 x z A A A A z A w w z z A A A z z B C C C C C D i i i i i i i i i i i i D E C C C C B A A A A A A w z z w A z A j y ^ ",
	"2 F G H H I I H I I I I I I I I I I J C i i i i i i i i i i i i i i i i i i i i i i C J I I I I I I I H I I I I I K L , ",
	"2 M , N G H N N H N N H G N H N H H G f O i i i i i i i i i i i i i i i i i i i i P 1 G H G N G G G N N G G G G G Q = J ",
	"R M S H H G H H G G H H H G G H G G G G T U i i i i i i i i i i i i i i i i i i U q G H H G G H G H H G G H G G H V = , ",
	"R M , H G G H H G G G G H H G G H H G H H W X i i i i i i i i i i i i i i i i X W H G G G G H H G G H H H G G H H V = , ",
	"R M , G G H G H G G G G G H G G H G G H H G Y Z i i i i i i i i i i i i i i Z = H G G G H H H H G H H G G H H H H V = J ",
	"R M S G H G H G H H G H G H G H H G H H H G H   ` i i i i i i i i i i i i `   H H G H H H G G H H H H G H H H H H V = , ",
	"2  .J N G N N G N N N N N N N G G N G G N N G N + ..i i i i i i i i i i ..u N N N N G G N N N N G G N N G N G N N Q Y , ",
	"2  .J N N N N N N G N N N N N N N G N N N N G N N +.@.i i i i i i i i #.+.N N G G N N N N N N N N N N N N N G G N Q = , ",
	"R M , N G N N N N N N N G G N G G N G N N N N N N G $.%.i i i i i i &.*.G N N N N N N G N N N G N N N G G G N N G =.= , ",
	"R  .J N N N N N G G N N N N N N N N N N G N G N N N N -.;.i i i i ;.-.N N N N G G N N N N N G N N N N N G N N N N =.= , ",
	"2  ., N N N N N N N N N N G G N N N N G G G N N N N N N >.,.i i ,.>.G G N N N G N N N N N N N G G G N N G N N N N Q = , ",
	"2  .J N N N N N N N N N N N N N N N N N N N N N N N N N N '.i i '.N N N N N N N N N N N N N N N N N N N N N N N N =.Y , ",
	"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S ).!.S S S S S S S S S S S S S S S S S S S S S S S S S F Y S ",
	"R I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
	"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
	"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
	"R I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
	"2 I ^ S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S S F Y , ",
	"2 H < , , J , , , , , , , , J ~.~.~.{.].^./.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.^.(._.~.~.D :.^ , , , , , , , M Y , ",
	"R H < , , , J , , , , , , J , ~.~.~.{.<.[.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.(.}.|.O 1.D 2.J , , , , , , , M Y , ",
	"2 H < , , J , , , , , , , , , ~.~.~.{.<.[.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.}.(.}.|.O 1.D 2., , , , , , J , M R S ",
	"2 H < , , , , J J , , J , , , , , , , , , , , J , , , , , , , , , , , , , , , , , , , , , , , , , J , , , , , , ,  .R S ",
	"2 G < , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , J J , , , , , , , , J J , , , , , , , , , , , , M Y , ",
	"R H [ J J ^ J J J J J ^ J J J J J J J J J J J ^ J J J J J J J J J , , ^ J J J J J J J , , J J J J J J J J J J ^ J  .R , ",
	"2 H < , , J , , , , , , , , , , , , , , , , , J J , , , J , , , , , , , , , J , , , , , , J J , , , , , , , , J , M Y J ",
	"2 H < , , , , J J , , J , , , , , , , , , , , J , , , , , , , , , , , , , , , , , , , , , , , , , J , , , , , , ,  .Y < ",
	"2 G < , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , J J , , , , , , , , J J , , , , , , , , , , , , M Y T ",
	"2 H [ J J ^ J J J J J ^ J J J J J J J J J J J ^ J J J J J J J J J , , ^ J J J J J J J , , J J J J J J J J J J ^ J  .  = ",
	"2 H q [ [ [ [ [ [ 1 [ [ 1 [ [ 1 [ [ 1 [ [ [ 1 [ 1 [ [ [ [ [ [ [ 1 [ [ [ [ [ 1 [ 1 [ [ [ [ [ [ 1 1 1 [ [ 1 [ 1 [ [ ,   ) ",
	"2 H g l n n l n n l l l l n n l l n n n l n n l n n n l l n l n n n n l l n n n l n n l l l l n l l n n n l n l l _     ",
	"2   m 3.3.3.3.3.3.3.4.3.4.4.4.3.4.3.5.3.3.3.3.3.3.3.3.4.3.4.3.3.3.3.4.4.3.4.3.4.4.3.4.3.3.4.3.3.3.3.3.3.4.4.4.4.3.      ",
	"2 2 2 . .     . .                 .   . . . . .   . .         . .           .                       . .                 "};		
	return Image
end

function ImageTopRight(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 288 2",
		"  	c None",
		". 	c #9F9F9F",
		"+ 	c #9B9B9B",
		"@ 	c #979797",
		"# 	c #939393",
		"$ 	c #929292",
		"% 	c #919191",
		"& 	c #909090",
		"* 	c #8F8F8F",
		"= 	c #8E8E8E",
		"- 	c #989898",
		"; 	c #EDEDED",
		"> 	c #E5E5E5",
		", 	c #E3E3E3",
		"' 	c #E6E6E6",
		") 	c #E7E7E7",
		"! 	c #EBEBEB",
		"~ 	c #ECECEC",
		"{ 	c #F0F0F0",
		"] 	c #F1F1F1",
		"^ 	c #F2F2F2",
		"/ 	c #F5F5F5",
		"( 	c #F4F4F4",
		"_ 	c #F9F9F9",
		": 	c #F8F8F8",
		"< 	c #FAFAFA",
		"[ 	c #FBFBFB",
		"} 	c #FDFDFD",
		"| 	c #FFFFFF",
		"1 	c #DADADA",
		"2 	c #D9D9D9",
		"3 	c #DBDBDB",
		"4 	c #DEDEDE",
		"5 	c #DFDFDF",
		"6 	c #E1E1E1",
		"7 	c #E2E2E2",
		"8 	c #E4E4E4",
		"9 	c #E9E9E9",
		"0 	c #E8E8E8",
		"a 	c #EAEAEA",
		"b 	c #8C8C8C",
		"c 	c #DDDDDD",
		"d 	c #E0E0E0",
		"e 	c #000000",
		"f 	c #DCDCDC",
		"g 	c #EEEEEE",
		"h 	c #161616",
		"i 	c #898989",
		"j 	c #4E4E4E",
		"k 	c #0A0A0A",
		"l 	c #F3F3F3",
		"m 	c #606060",
		"n 	c #111111",
		"o 	c #EFEFEF",
		"p 	c #535353",
		"q 	c #555555",
		"r 	c #878787",
		"s 	c #4A4A4A",
		"t 	c #010101",
		"u 	c #121212",
		"v 	c #3F3F3F",
		"w 	c #020202",
		"x 	c #414141",
		"y 	c #343434",
		"z 	c #030303",
		"A 	c #131313",
		"B 	c #363636",
		"C 	c #2D2D2D",
		"D 	c #040404",
		"E 	c #2C2C2C",
		"F 	c #949494",
		"G 	c #232323",
		"H 	c #060606",
		"I 	c #272727",
		"J 	c #969696",
		"K 	c #C5C5C5",
		"L 	c #CBCBCB",
		"M 	c #D3D3D3",
		"N 	c #D7D7D7",
		"O 	c #D8D8D8",
		"P 	c #1A1A1A",
		"Q 	c #C6C6C6",
		"R 	c #CCCCCC",
		"S 	c #D2D2D2",
		"T 	c #D5D5D5",
		"U 	c #D6D6D6",
		"V 	c #222222",
		"W 	c #C7C7C7",
		"X 	c #D1D1D1",
		"Y 	c #D4D4D4",
		"Z 	c #CACACA",
		"` 	c #CFCFCF",
		" .	c #BABABA",
		"..	c #838383",
		"+.	c #6B6B6B",
		"@.	c #636363",
		"#.	c #646464",
		"$.	c #5F5F5F",
		"%.	c #5E5E5E",
		"&.	c #5A5A5A",
		"*.	c #585858",
		"=.	c #545454",
		"-.	c #515151",
		";.	c #4C4C4C",
		">.	c #474747",
		",.	c #424242",
		"'.	c #3E3E3E",
		").	c #393939",
		"!.	c #303030",
		"~.	c #2A2A2A",
		"{.	c #282828",
		"].	c #252525",
		"^.	c #AEAEAE",
		"/.	c #D0D0D0",
		"(.	c #9E9E9E",
		"_.	c #686868",
		":.	c #717171",
		"<.	c #757575",
		"[.	c #747474",
		"}.	c #737373",
		"|.	c #727272",
		"1.	c #707070",
		"2.	c #6E6E6E",
		"3.	c #6C6C6C",
		"4.	c #696969",
		"5.	c #666666",
		"6.	c #626262",
		"7.	c #505050",
		"8.	c #4B4B4B",
		"9.	c #484848",
		"0.	c #464646",
		"a.	c #444444",
		"b.	c #292929",
		"c.	c #7F7F7F",
		"d.	c #888888",
		"e.	c #777777",
		"f.	c #767676",
		"g.	c #676767",
		"h.	c #656565",
		"i.	c #616161",
		"j.	c #5D5D5D",
		"k.	c #595959",
		"l.	c #494949",
		"m.	c #404040",
		"n.	c #3A3A3A",
		"o.	c #ACACAC",
		"p.	c #6F6F6F",
		"q.	c #6D6D6D",
		"r.	c #5D5B58",
		"s.	c #5C564E",
		"t.	c #5C5043",
		"u.	c #594B3B",
		"v.	c #544638",
		"w.	c #4E453B",
		"x.	c #494540",
		"y.	c #454443",
		"z.	c #434343",
		"A.	c #353535",
		"B.	c #6A6A6A",
		"C.	c #636362",
		"D.	c #645D56",
		"E.	c #675644",
		"F.	c #3D5F84",
		"G.	c #2266B2",
		"H.	c #156BCA",
		"I.	c #146BCB",
		"J.	c #285A91",
		"K.	c #464441",
		"L.	c #4A3F31",
		"M.	c #43403C",
		"N.	c #3C3C3C",
		"O.	c #656463",
		"P.	c #696056",
		"Q.	c #5E5C59",
		"R.	c #0871E5",
		"S.	c #007AFF",
		"T.	c #0079FF",
		"U.	c #0078FF",
		"V.	c #007BFF",
		"W.	c #007FFF",
		"X.	c #245892",
		"Y.	c #483A2A",
		"Z.	c #413E3A",
		"`.	c #69635B",
		" +	c #605E5B",
		".+	c #0077FF",
		"++	c #0076FA",
		"@+	c #0176F8",
		"#+	c #0077FE",
		"$+	c #007DFF",
		"%+	c #245690",
		"&+	c #44392C",
		"*+	c #3F3E3D",
		"=+	c #242424",
		"-+	c #676462",
		";+	c #6E5D4A",
		">+	c #0971E5",
		",+	c #0078FE",
		"'+	c #403C37",
		")+	c #433D36",
		"!+	c #676059",
		"~+	c #42648A",
		"{+	c #1068C9",
		"]+	c #493C2E",
		"^+	c #FEFEFE",
		"/+	c #575757",
		"(+	c #5B5B5B",
		"_+	c #6A5D4F",
		":+	c #2769B4",
		"<+	c #0077FD",
		"[+	c #4F3B26",
		"}+	c #454545",
		"|+	c #4D4D4D",
		"1+	c #685948",
		"2+	c #0771E7",
		"3+	c #0076F9",
		"4+	c #523C24",
		"5+	c #FCFCFC",
		"6+	c #5C5C5C",
		"7+	c #635545",
		"8+	c #166CCD",
		"9+	c #554029",
		"0+	c #090909",
		"a+	c #5B5247",
		"b+	c #2E5F97",
		"c+	c #0770E4",
		"d+	c #564532",
		"e+	c #333333",
		"f+	c #55514C",
		"g+	c #4E4C49",
		"h+	c #007EFF",
		"i+	c #2B5F98",
		"j+	c #564C42",
		"k+	c #525252",
		"l+	c #383838",
		"m+	c #4F4F4F",
		"n+	c #4D4C4B",
		"o+	c #514538",
		"p+	c #265A93",
		"q+	c #0870E5",
		"r+	c #5E4D39",
		"s+	c #56524F",
		"t+	c #1B1B1B",
		"u+	c #050505",
		"v+	c #484441",
		"w+	c #493B2B",
		"x+	c #21558E",
		"y+	c #0771E6",
		"z+	c #5D564E",
		"A+	c #3D3D3D",
		"B+	c #3E3B37",
		"C+	c #493D30",
		"D+	c #47433E",
		"E+	c #116ACB",
		"F+	c #0076FD",
		"G+	c #007CFF",
		"H+	c #30649C",
		"I+	c #655340",
		"J+	c #605951",
		"K+	c #5C5B5B",
		"L+	c #474645",
		"M+	c #4F4942",
		"N+	c #56493B",
		"O+	c #5F4B36",
		"P+	c #624C34",
		"Q+	c #655039",
		"R+	c #665542",
		"S+	c #63594F",
		"T+	c #605D59",
		"U+	c #313131",
		"V+	c #565656",
		"W+	c #373737",
		"X+	c #F7F7F7",
		"Y+	c #2B2B2B",
		"Z+	c #262626",
		"`+	c #828282",
		" @	c #BBBBBB",
		".@	c #CECECE",
		"+@	c #ADADAD",
		"@@	c #848484",
		"#@	c #C9C9C9",
		"$@	c #999999",
		"%@	c #C0C0C0",
		"&@	c #CDCDCD",
		"*@	c #C3C3C3",
		"=@	c #C8C8C8",
		"-@	c #9D9D9D",
		";@	c #8D8D8D",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # $ $ $ $ $ % % % % % & & & & * * * * = # - . ",
		". @ ; > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > , > ' ' ) ! ! ~ ; { ] ] ^ / ( _ : < [ } } | | | $ . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 3 1 3 4 5 4 6 7 , 8 , 8 > > 9 0 9 a ; ~ ; ; | b . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 1 ) ( | | | | | | | ( ) 1 1 1 1 1 1 1 1 2 3 1 c 4 5 4 5 d , 8 , 8 ) 0 9 0 9 a ; ~ ; ; | b . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 3 d e e e e e e e e e d 3 1 1 1 1 1 1 1 2 3 1 3 4 5 4 d d , 8 , 8 > ' 9 0 ! a ! ~ ; ; | b . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 f g e h h h h h h h e g f 1 1 1 1 1 1 1 2 3 f c f 5 4 5 d 6 8 , > ' ' 9 a 9 a ; ~ ; g | b . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 f g e h h h h h h h e g f 1 1 1 1 1 1 1 2 3 f c f 5 d 5 d 6 7 , 8 > ' 9 a ! a ! ~ ; g | i . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 f g e h h h h h h h e g f 1 1 1 1 1 1 1 2 3 f c f 5 4 5 d , 8 , ' > 0 9 0 9 a ! ~ ; ; | i . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 f g e h h h h h h h e g f 1 1 1 1 1 1 1 2 3 1 c 4 5 4 5 d , 8 , 8 ) > 9 0 9 a ; ~ ; ; | i . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 f g e h h h h h h h e g f 1 1 1 1 1 1 1 2 3 1 3 f c d 5 d , 8 , 8 ' ' 9 0 9 ~ ; ~ ; ; | i . ",
		". # > 1 1 1 1 1 1 1 d ; < | | | e h h h h h h h e | | | < ; d 1 1 1 2 3 1 3 4 5 4 5 d 6 8 , > ' ' 9 0 9 a ; ~ ; ; | i . ",
		". # > 1 1 1 1 1 1 1 d j e e e e k h h h h h h h k e e e e j d 1 1 1 2 3 1 3 4 5 4 6 d 6 7 , 8 > ' 9 a ! a ; ~ ; ; | i . ",
		". # > 1 1 1 1 1 1 1 d l m e n h h h h h h h h h h h n e m / d 1 1 1 2 3 1 3 4 5 4 5 7 , 7 , ' > ' 9 a ! ~ ; g o ; | i . ",
		". # > 1 1 1 1 1 1 1 1 6 ( p e n h h h h h h h h h n e q ( 6 1 1 1 1 2 3 f c f 5 4 5 d 6 7 , 8 ) 0 9 0 9 ~ ; g o ; | r . ",
		". # > 1 1 1 1 1 1 1 1 1 7 ( s t u h h h h h h h u t s ( 7 1 1 1 1 1 2 3 f c 4 5 4 d d 6 8 , 8 > ' 9 0 9 a ; ~ ; ; | i . ",
		". # > 1 1 1 1 1 1 1 1 1 1 7 ] v w u h h h h h u w x ] 7 1 1 1 1 1 1 2 3 1 c 4 5 4 5 d , 8 , 8 > ' 9 0 a a ; g o ; | i . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 , o y z A h h h A z B o , 1 1 1 1 1 1 1 2 3 1 3 4 5 4 5 7 6 6 , ' ) 0 9 0 a a ; ~ ; g | r . ",
		". # > 1 1 1 1 1 1 1 1 1 1 1 1 8 ~ C D A h A D E ; 8 1 1 1 1 1 1 1 1 2 3 1 3 f 5 4 5 7 , 8 , 8 > ' 9 0 9 a ; ~ ; g | i . ",
		". F ) f 3 1 1 1 1 1 1 1 1 1 1 3 > 9 G H u H I 9 > 1 1 1 1 1 1 1 1 1 1 3 3 c 4 5 4 5 d , 8 , > > ' 9 a ! a ; ~ o ; | i . ",
		". J K L M N O O O O O O O O O O O 8 7 P e P 6 8 O O O O O O O O O N 2 O 1 1 c c 4 d d 6 8 , > > 0 9 0 9 ~ ; ~ ; g | r . ",
		". - Q R S T U U U U U U U U U U U N , N V 2 , N U U U U U U U U U T N U N 1 f 4 5 d d , 8 , > > ' 9 0 9 a ; ~ ; ; | i . ",
		". - W L X M Y Y Y Y Y Y Y Y Y Y Y Y T 4 5 4 T Y Y Y Y Y Y Y Y Y Y M M Y T N 3 c 5 5 d , 8 , 8 > ' ) a 9 a ; ~ ; g | i . ",
		". - W Z ` S M N c 6 , , , 8 8 8 > > ' ' ) 0 9 9 a ! ! ~ ~ ; ; ! 8 3 Y S M U 1 3 5 5 7 6 8 , 8 ) 0 9 0 9 ~ ; ~ ; ; | i . ",
		". - W Z ` Y 3  ...+.@.#.@.m $.%.&.*.=.-.;.>.,.'.).y !.E ~.{.].E =.^.6 U S T O 3 5 5 d 6 7 , 8 ) 8 9 0 ! a ; ~ ; ; | i . ",
		". - W Z /.1 (._.:.<.<.[.}.}.|.1.2.3.4.5.6.%.*.=.7.j 8.9.0.a.x '.B b.c.6 Y Y 2 f 5 5 d 6 , 8 8 ) 0 9 0 9 a ; ~ ; ; | d.. ",
		". - W Z Y  .4.[.e.<.f.<.[.}.1.1.2.+.g.h.i.j.k.q -.;.l.0.a.,.,.x m.n.I o.3 Y N f 5 5 7 6 7 , 8 ) 0 9 0 a a ! ~ o g | d.. ",
		". - W Z 1 ..1.<.f.f.<.}.|.|.:.p.q.+.5.#.m r.s.t.u.v.w.x.y.z.m.v m.'.A.p 8 T N f 5 6 7 6 8 8 8 > 0 9 0 9 a ! g ; g | d.. ",
		". - W Z 4 4.[.f.[.<.}.|.}.1.1.2.3.B.h.C.D.E.F.G.H.I.J.K.L.M.x m.'.'.N.~.! T N f 5 6 d 6 7 7 > ) ' 9 0 ! a ! ~ ; g | i . ",
		". - W Z 5 @.[.<.}.[.|.}.|.p.p.q.+._.O.P.Q.R.S.T.U.T.V.W.X.Y.Z.'.'.'.v G ; T N f 5 5 d , 8 8 ~ ; ; 9 0 ! a ; ~ ; ; | r . ",
		". - W Z d 6.[.|.}.}.|.1.p.p.3.3._.g.`. +S..+++@+@+@+@+#+$+%+&+*+m.v x =+; T N f 5 d d , 8 ! | -.} 9 0 9 a ; ~ ; g | i . ",
		". - W Z d $.:.|.|.1.:.1.p.3.3.B.5.-+;+>+.+@+@+@+@+@+@+@+,+W.'+)+x ,.,.].; T N f 5 5 d 6 ~ | h.e | 9 a 9 a ; ~ ; g | r . ",
		". - W Z 6 $.:.:.1.1.p.2.q.3.B._.h.!+~+T.++@+@+@+@+@+@+@+@+S.{+]+x ,.,.{.; Y N f 5 5 7 ~ ^+/+e e | 9 a 9 a ; ~ ; g | i . ",
		". - W Z 6 (+p.q.2.2.q.3.+.4.5.h.@._+:+U.@+@+@+@+@+@+@+@+@+<+.+[+}+}+a.~.~ Y 2 f 5 d ~ [ |+e n e | ! ! ~ o { g g g | r . ",
		". - W Z 6 *.3.3.3.+.B.4._.h.h.6.m 1+2+.+@+@+@+@+@+@+@+@+@+3+W.4+>.0.9.E ~ Y 2 f d a _ m.e n h e | ^+^+| | | ( 5+; | i . ",
		". - W Z 7 q 4.4.4._.g.5.h.@.i.$.6+7+8+U.@+@+@+@+@+@+@+@+@+++W.9+s l.8.!.; Y 2 f ! l B w u h h 0+e e e e e e e | ; | i . ",
		". - W Z , -.5.5.#.h.#.@.m m %.(+k.a+b+S.@+@+@+@+@+@+@+@+@+U.c+d+;.j |+e+~ Y 1 0 o C z u h h h h h h h h h h e | ; | i . ",
		". - W Z , ;.6.6.6.i.m $.%.6+&./+p f+g+h+#+@+@+@+@+@+@+@+++S.i+j+-.7.k+l+! T ' ' =+D A h h h h h h h h h h h e | ; | i . ",
		". - W Z 8 9.%.%.%.j.6+(+*.*.=.p m+n+o+p+$+,+@+@+@+@+@+++U.q+r+s+q =.=.N.! 5 3 t+u+A h h h h h h h h h h h h e | ; | i . ",
		". - W Z > z.&.&.*./+*.q q k+-.m+;.l.v+w+x+W.S.<+3+++.+S.y+=.z+/+*.&.&.,.a d V e n h h h h h h h h h h h h h e | g | i . ",
		". - W Z ' A+=.=.q p k+-.-.m+|+l.9.a.v B+C+D+E+F+G+G+c+H+I+J+K+j.%.%.%.>.9 5 c t+u+A h h h h h h h h h h h h e | g | d.. ",
		". - W Z ) ).k+7.-.7.m+j |+8.l.}+z.m.'.,.L+M+N+O+P+Q+R+S+T+$.m i.6.6.6.;.) U ' ' I D A h h h h h h h h h h h e | g | d.. ",
		". - W Z ) y |+j ;.8.s l.l.0.a.,.'.'.,.>.8.|+k+=.k.(+%.m m @.#.h.#.5.5.-.' Y O 0 o C z u h h h h h h h h h h e | ; | d.. ",
		". - W Z 0 U+8.l.s l.9.>.0.a.x A+v ,.>.8.|+k+V+k.6+$.i.@.h.5.g._.4.4.4.=.> Y N f ! l W+t u h h 0+e e e e e e e | ; | d.. ",
		". - W Z 0 C 9.0.>.}+a.z.z.m.A+v ,.}+s j k+V+*.j.m 6.h.h._.4.B.+.3.3.3.*.> Y 2 f 5 a X+,.e n h e | ^+^+| | | ( 5+; | i . ",
		". - W Z 9 Y+a.}+}+a.z.,.v '.v z.0.9.|+-.q k.j.m @.h.5.4.+.3.q.2.2.q.p.&.8 Y 2 f 5 6 ! < j e n e | ! ! ~ ; { g g ; | i . ",
		". - W Z 9 b.,.,.x ,.m.v '.v z.a.>.;.j =.*.&.$.i.h._.B.3.q.2.p.1.1.:.:.%.> Y 2 f 5 5 7 a | /+e e | 9 0 9 a ; ~ ; g | i . ",
		". - W Z a Z+,.,.x v '.'.v x }+0.l.j k+V+&.%.m h.5.B.3.3.p.1.:.1.|.|.:.$.> Y 2 f 5 5 7 , ~ | h.e | ) a ! a ; ~ ; g | i . ",
		". - W Z a ].x v m.'.'.v ,.a.}+l.8.7.=.*.6+m #.g._.3.3.p.p.1.|.}.}.|.[.i., Y 2 f 5 6 7 , 8 ! | k+} 9 0 9 a ; ~ ; ; | r . ",
		". - W Z a G v '.'.'.v m.z.}+0.l.j 7.=.&.%.6.h._.+.q.p.p.|.}.|.[.}.<.[.6., Y N f 5 6 d 6 8 , ~ ; ; 9 0 9 a ; ~ ; ; | i . ",
		". - W Z ) b.N.'.'.m.x x a.0.>.;.m+p /+(+$.@.h.B.3.2.1.1.}.|.}.<.[.f.[._.6 T N f 5 5 d 6 8 , > ' ' 9 0 9 ~ ; ~ ; g | i . ",
		". - W Z 6 =.A.'.m.v m.z.}+>.9.8.m+=.*.6+m #.5.+.q.p.:.|.|.}.<.f.f.<.p.`+c T N f 5 5 7 , 8 , > > ' 9 0 9 ~ ! ~ ; ; | i . ",
		". - W Z O o.I n.m.x ,.,.a.0.l.;.-.q k.j.i.h.g.+.2.1.1.}.[.<.f.<.e.[._. @N Y N f 5 5 7 , 8 , > > 0 9 0 9 a ; ~ ; ; | i . ",
		". - W Z X 6 c.b.B '.x a.0.9.8.j 7.=.*.%.6.5.4.3.2.1.|.}.}.[.<.<.:._.(.3 M Y 2 f 5 5 7 , 7 , > > 0 9 a ! a ; ~ ; ; | i . ",
		". - Q L .@T 6 +@q C Z+b.Y+C U+y ).'.z.9.;.-.q k.(+$.m i.@.h.#.3.@@ .1 Y S T O 3 5 5 d 6 7 , > > ' 9 a ! ~ ; ~ ; ; | r . ",
		". - K #@R .@X O d ) 9 9 9 0 0 ) ' ' > 8 , , 7 6 6 6 d d d d 5 c 2 Y ` ` /.S U N d 5 7 6 8 , > ' ' 9 0 9 a ; ~ ; g | b . ",
		". $@%@K #@L Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z Z L R &@/.` d c d 5 7 6 7 , 8 ' ' ) 0 a a ! ! | b . ",
		". +  @%@*@Q K K K K K K K K K K K K K K K K K K K K K K K K K K K K K W =@#@L L } [ ^+| | | | | | | | | | | | | | | $ . ",
		". -@+ $@- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - @ @ @ F $ & * * * * = = = = ;@;@;@;@;@b b $ - . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '1' then
	Image = {
	--XpmImage Here
	};
	end
	return Image
end

function ImageLeft(pic)
	local Image = {
	"60 60 143 2",
	"  	c #ACACAC",
	". 	c #ADADAD",
	"+ 	c #A5A5A5",
	"@ 	c #9E9E9E",
	"# 	c #9D9D9D",
	"$ 	c #9C9C9C",
	"% 	c #F2F2F2",
	"& 	c #FFFFFF",
	"* 	c #B8B8B8",
	"= 	c #B3B3B3",
	"- 	c #F1F1F1",
	"; 	c #F0F0F0",
	"> 	c #FDFDFD",
	", 	c #C5C5C5",
	"' 	c #BDBDBD",
	") 	c #AEAEAE",
	"! 	c #ECECEC",
	"~ 	c #EEEEEE",
	"{ 	c #EFEFEF",
	"] 	c #FBFBFB",
	"^ 	c #C3C3C3",
	"/ 	c #AFAFAF",
	"( 	c #EBEBEB",
	"_ 	c #EDEDED",
	": 	c #FAFAFA",
	"< 	c #C2C2C2",
	"[ 	c #C0C0C0",
	"} 	c #EAEAEA",
	"| 	c #F9F9F9",
	"1 	c #BFBFBF",
	"2 	c #B0B0B0",
	"3 	c #E9E9E9",
	"4 	c #F8F8F8",
	"5 	c #F7F7F7",
	"6 	c #C1C1C1",
	"7 	c #E8E8E8",
	"8 	c #F6F6F6",
	"9 	c #E7E7E7",
	"0 	c #E6E6E6",
	"a 	c #E5E5E5",
	"b 	c #F3F3F3",
	"c 	c #797979",
	"d 	c #808080",
	"e 	c #E4E4E4",
	"f 	c #383838",
	"g 	c #393939",
	"h 	c #E3E3E3",
	"i 	c #313131",
	"j 	c #323232",
	"k 	c #E2E2E2",
	"l 	c #3D3D3D",
	"m 	c #BEBEBE",
	"n 	c #424242",
	"o 	c #4B4B4B",
	"p 	c #E1E1E1",
	"q 	c #818181",
	"r 	c #DADADA",
	"s 	c #595959",
	"t 	c #585858",
	"u 	c #E0E0E0",
	"v 	c #464646",
	"w 	c #494949",
	"x 	c #D6D6D6",
	"y 	c #5B5B5B",
	"z 	c #DFDFDF",
	"A 	c #454545",
	"B 	c #161616",
	"C 	c #414141",
	"D 	c #D1D1D1",
	"E 	c #565656",
	"F 	c #DEDEDE",
	"G 	c #CCCCCC",
	"H 	c #DCDCDC",
	"I 	c #DDDDDD",
	"J 	c #BBBBBB",
	"K 	c #DBDBDB",
	"L 	c #2C2C2C",
	"M 	c #A6A6A6",
	"N 	c #A7A7A7",
	"O 	c #272727",
	"P 	c #B5B5B5",
	"Q 	c #575757",
	"R 	c #222222",
	"S 	c #D8D8D8",
	"T 	c #D9D9D9",
	"U 	c #1E1E1E",
	"V 	c #555555",
	"W 	c #1B1B1B",
	"X 	c #9B9B9B",
	"Y 	c #B9B9B9",
	"Z 	c #D7D7D7",
	"` 	c #181818",
	" .	c #919191",
	"..	c #CDCDCD",
	"+.	c #C8C8C8",
	"@.	c #C9C9C9",
	"#.	c #CACACA",
	"$.	c #171717",
	"%.	c #7F7F7F",
	"&.	c #CBCBCB",
	"*.	c #535353",
	"=.	c #525252",
	"-.	c #D2D2D2",
	";.	c #B4B4B4",
	">.	c #C7C7C7",
	",.	c #747474",
	"'.	c #515151",
	").	c #CFCFCF",
	"!.	c #C4C4C4",
	"~.	c #B1B1B1",
	"{.	c #C6C6C6",
	"].	c #737373",
	"^.	c #D0D0D0",
	"/.	c #888888",
	"(.	c #1A1A1A",
	"_.	c #909090",
	":.	c #1D1D1D",
	"<.	c #969696",
	"[.	c #B2B2B2",
	"}.	c #212121",
	"|.	c #9F9F9F",
	"1.	c #989898",
	"2.	c #999999",
	"3.	c #353535",
	"4.	c #252525",
	"5.	c #CECECE",
	"6.	c #404040",
	"7.	c #292929",
	"8.	c #ABABAB",
	"9.	c #2E2E2E",
	"0.	c #B6B6B6",
	"a.	c #3F3F3F",
	"b.	c #3B3B3B",
	"c.	c #BABABA",
	"d.	c #545454",
	"e.	c #4A4A4A",
	"f.	c #484848",
	"g.	c #333333",
	"h.	c #BCBCBC",
	"i.	c #A9A9A9",
	"j.	c #A1A1A1",
	"k.	c #A0A0A0",
	"l.	c #A2A2A2",
	"      .             . . .     . .       .   .     .   . .         . .     .     .         .   . .     .       .         ",
	"    + @ # # # # # # # # # # $ # # $ # # $ # # # # $ $ $ # $ # $ # $ # # # # # # $ $ $ $ # # # # $ # # # # # $ # #   . . ",
	"  % & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & * = ",
	"= - - ; ; ; - - ; ; ; ; ; ; ; ; ; - - ; - ; - ; ; ; - - - ; - - - - ; ; ; ; ; - - - ; ; ; ; - - ; ; - ; ; ; ; - ; > , ' ",
	") ! ; ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ { ~ ~ { ~ ~ ~ ~ ~ ~ { ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ] ^ ' ",
	"/ ( ~ _ _ _ _ _ _ _ _ _ _ ~ ~ _ ~ _ _ _ _ _ _ _ _ _ _ ~ _ _ _ _ _ _ _ _ ~ ~ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ : < [ ",
	"/ } ~ _ _ ! _ ! ! _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! ! ! _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ | < 1 ",
	"2 3 ! ( ( ( ( ( ( ( ! ( ( ! ! ( ( ( ( ( ! ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ! ! ( ( ! ( ( 4 < 1 ",
	"/ 3 ( } } ( } ( } } } } ( ( } } } } } ( } } } } ( } } } ( ( } } } } } } } } } } } } ( } } } } ( } } } } } ( ( } } 5 6 1 ",
	"/ 7 } 3 3 3 } } 3 3 3 3 } } 3 3 3 3 3 } 3 3 } 3 3 3 3 3 3 3 3 } } 3 3 } 3 3 3 3 3 3 3 3 3 3 3 } 3 3 3 3 3 } } 3 3 8 6 1 ",
	"/ 9 } 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 7 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 7 3 3 3 3 3 3 3 3 3 8 6 1 ",
	"2 0 9 0 7 9 9 9 7 0 9 9 9 9 7 9 9 7 9 9 7 9 9 7 0 7 7 7 9 9 7 7 0 7 7 9 7 7 7 9 9 7 9 9 9 7 7 9 a 0 9 9 7 7 9 9 9 b [ [ ",
	"/ a 9 0 9 0 0 0 0 9 0 0 0 0 9 0 0 9 0 0 0 0 0 9 9 9 9 0 9 0 0 0 0 0 9 0 0 0 9 0 0 9 0 0 0 0 0 0 c d d 0 0 0 0 0 0 % 1 1 ",
	"/ e a a a a a a 0 a a a a 0 a a a 0 a a a a a a a a a a a a a a a a a a a a a a a a a 0 a a a a f g g a a a a a a % 1 [ ",
	"2 h e e e e e e e e e e e e e e e e e e e e e e e e e e h e e e e e e e e e e e e e e e e e h e i j j e e e e e e ; 1 [ ",
	"/ h e e e e e h e e e e h h h e e k e e e e e e h h h e h e e e h h e e e e e h e e e e h e e e i l l e e h h e e ~ m [ ",
	"2 k h h h h k k h h h k k h k k h k h h k h h k k k k k k h h k h h h k k k h h h k k h k k k h n o o h h h k k k ~ m 6 ",
	"/ p p k p p p p p p p p p k p p p k k p p p p k p p k k p q r p k k k k p p p k p p p p p p k k s t t k k k p k k _ ' 6 ",
	"/ u u p u u u u u u u u p u u u u u u u u u u u u u u p p v w x u u u u u u u u u p u u u p u u y s s u u u u u u ( ' 6 ",
	"2 z z z z z z u z z u z z z z z z z z z z z z z z z z z z A B C D z z z z z z z z u z z z z z z t E E z z z z z z } ' 6 ",
	"/ z z z z z z z z z F z z z z z z z z z z z z z z z F z z A B B g G z F z z z z z F z z z z z z t E E F z z z z z 3 ' 6 ",
	"2 F H F F F I I I F I F F F I F F F I F F F F F F F I I I A B B B i , I F F F F I F F I F F F F t E E I I I I I F 7 J 6 ",
	"2 I K H I H I I I I H H H H I I I H H I I H H H I I I I H A B B B B L m H H H H I I I I I I H H t E E I I I H H I 9 J < ",
	"/ H K K K K H H H K K K K K H H K K K M M M N N M M N N M f B B B B B O P K K K H K K H K H K K Q E E H H H K K K 0 J < ",
	"2 K r K K K K K K K K K K K K K K K K B B B B B B B B B B B B B B B B B R ) K K K K K K K K K K Q E E K K K K K K e J < ",
	"/ r S T T T r r T T r r r r T r r r r B B B B B B B B B B B B B B B B B B U + T T T r r r r T S Q V V r T T T T T h J < ",
	"2 r T T S S T T S T T T T T T T T T T B B B B B B B B B B B B B B B B B B B W X T r T T T r S T Q V V T S T T S S h Y < ",
	"2 T x Z Z Z Z x Z S S x x Z Z Z x x Z B B B B B B B B B B B B B B B B B B B B `  .Z x Z Z Z Z Z E V V x x S Z x Z u Y ^ ",
	"2 ..+.@.@.#.#.@.#.#.#.#.#.#.#.#.#.#.#.B B B B B B B B B B B B B B B B B B B B B $.%.&.#.#.#.#.#.*.=.=.@.#.#.#.#.#.-.;., ",
	"2 G , >.+.@.>.>.@.>.>.@.+.>.@.>.@.@.+.B B B B B B B B B B B B B B B B B B B B B B B ,.+.@.+.>.+.*.'.'.>.+.+.+.+.+.).= !.",
	"~.G {.@.@.+.@.@.+.+.@.@.@.+.+.@.+.+.+.B B B B B B B B B B B B B B B B B B B B B B B ].@.@.+.+.@.*.=.=.+.+.@.+.+.@.^.= , ",
	"~.G , @.+.+.@.@.+.+.+.+.@.@.+.+.@.@.+.B B B B B B B B B B B B B B B B B B B B B $.%.+.+.+.+.@.@.*.'.=.@.@.+.+.@.@.^.= , ",
	"~.G , +.+.@.+.@.+.+.+.+.+.@.+.+.@.+.+.B B B B B B B B B B B B B B B B B B B B ` /.+.+.+.@.@.@.@.*.=.=.+.+.@.@.@.@.^.= !.",
	"~.G {.+.@.+.@.+.@.@.+.@.+.@.+.@.@.+.@.B B B B B B B B B B B B B B B B B B B (._.@.+.@.@.@.+.+.@.*.=.=.+.@.@.@.@.@.^.= , ",
	"2 &.!.>.+.>.>.+.>.>.>.>.>.>.>.+.+.>.+.B B B B B B B B B B B B B B B B B B :.<.>.>.>.+.+.>.>.>.>.*.'.'.>.+.>.+.>.>.).[., ",
	"2 &.!.>.>.>.>.>.>.+.>.>.>.>.>.>.>.+.>.B B B B B B B B B B B B B B B B B }.|.>.+.+.>.>.>.>.>.>.>.*.'.'.>.>.>.+.+.>.).= , ",
	"~.G , >.+.>.>.>.>.>.>.>.+.+.>.+.+.>.+.1.1.1.1.1.1.2.2.1.1.3.B B B B B 4.M >.>.>.>.>.>.+.>.>.>.+.*.'.'.+.+.+.>.>.+.5.= , ",
	"~.&.!.>.>.>.>.>.+.+.>.>.>.>.>.>.>.>.>.>.+.>.+.>.>.>.>.>.>.6.B B B B 7.8.>.>.>.+.+.>.>.>.>.>.+.>.*.'.'.>.+.>.>.>.>.5.= , ",
	"2 &., >.>.>.>.>.>.>.>.>.>.+.+.>.>.>.>.+.+.+.>.>.>.>.>.>.>.6.B B B 9.[.+.>.>.>.+.>.>.>.>.>.>.>.+.*.'.'.>.+.>.>.>.>.).= , ",
	"2 &.!.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.6.B B 3.0.>.>.>.>.>.>.>.>.>.>.>.>.>.>.*.=.=.>.>.>.>.>.>.5.[., ",
	"2 #.^ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.a.B b.c.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.V d.d.{.{.{.{.{.{...[.{.",
	"~.#.^ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.a.n ' {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.e.f.f.{.{.{.{.{.{...[., ",
	"2 #.^ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.].[ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.g.g.g.{.{.{.{.{.{...[., ",
	"2 #.^ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.i i i {.{.{.{.{.{...[., ",
	"~.#.^ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.i i i {.{.{.{.{.{...[., ",
	"2 #.^ {.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.{.i i i {.{.{.{.{.{...[., ",
	"2 @.< , , !., , , , , , , , !.!.!., , !., , !., , , , , , , !., !., !., !.!., , , !., , , , !., , , , , , , , , , G [., ",
	"~.@.< , , , !., , , , , , !., , !., , , , , , , , !.!.!., , , , , , , , , , , , !., !.!.!.!., !., , , , , , , , , G [., ",
	"2 @.< , , !., , , , , , , , , , , , , , , , , !.!., , , !., , , , , , , , , !., , , , , , !.!., , , , , , , , !., G ~.{.",
	"2 @.< , , , , !.!., , !., , , , , , , , , , , !., , , , , , , , , , , , , , , , , , , , , , , , , !., , , , , , , &.~.{.",
	"2 +.< , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , !.!., , , , , , , , !.!., , , , , , , , , , , , G [., ",
	"~.@.[ !.!.^ !.!.!.!.!.^ !.!.!.!.!.!.!.!.!.!.!.^ !.!.!.!.!.!.!.!.!., , ^ !.!.!.!.!.!.!., , !.!.!.!.!.!.!.!.!.!.^ !.&.~., ",
	"2 @.< , , !., , , , , , , , , , , , , , , , , !.!., , , !., , , , , , , , , !., , , , , , !.!., , , , , , , , !., G [.!.",
	"2 @.< , , , , !.!., , !., , , , , , , , , , , !., , , , , , , , , , , , , , , , , , , , , , , , , !., , , , , , , &.[.< ",
	"2 +.< , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , !.!., , , , , , , , !.!., , , , , , , , , , , , G [.h.",
	"2 @.[ !.!.^ !.!.!.!.!.^ !.!.!.!.!.!.!.!.!.!.!.^ !.!.!.!.!.!.!.!.!., , ^ !.!.!.!.!.!.!., , !.!.!.!.!.!.!.!.!.!.^ !.&.  = ",
	"2 @.J [ [ [ [ [ [ 1 [ [ 1 [ [ 1 [ [ 1 [ [ [ 1 [ 1 [ [ [ [ [ [ [ 1 [ [ [ [ [ 1 [ 1 [ [ [ [ [ [ 1 1 1 [ [ 1 [ 1 [ [ ,   ) ",
	"2 @.p z F F z F F z z z z F F z z F F F z F F z F F F z z F z F F F F z z F F F z F F z z z z F z z F F F z F z z _     ",
	"2   i.j.j.j.j.j.j.j.k.j.k.k.k.j.k.j.l.j.j.j.j.j.j.j.j.k.j.k.j.j.j.j.k.k.j.k.j.k.k.j.k.j.j.k.j.j.j.j.j.j.k.k.k.k.j.      ",
	"2 2 2 . .     . .                 .   . . . . .   . .         . .           .                       . .                 "};
	return Image
end

function ImageCenter(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 240 2",
		"  	c #9F9F9F",
		". 	c #9D9D9D",
		"+ 	c #9C9C9C",
		"@ 	c #FFFFFF",
		"# 	c #F1F1F1",
		"$ 	c #242424",
		"% 	c #2C2C2C",
		"& 	c #2B2B2B",
		"* 	c #2A2A2A",
		"= 	c #292929",
		"- 	c #282828",
		"; 	c #323232",
		"> 	c #383838",
		", 	c #363636",
		"' 	c #2F2F2F",
		") 	c #2D2D2D",
		"! 	c #1A1A1A",
		"~ 	c #181818",
		"{ 	c #191919",
		"] 	c #2E2E2E",
		"^ 	c #353535",
		"/ 	c #3A3A3A",
		"( 	c #303030",
		"_ 	c #252525",
		": 	c #FDFDFD",
		"< 	c #F0F0F0",
		"[ 	c #D2D2D2",
		"} 	c #D1D1D1",
		"| 	c #CFCFCF",
		"1 	c #CDCDCD",
		"2 	c #CACACA",
		"3 	c #C5C5C5",
		"4 	c #BFBFBF",
		"5 	c #B8B8B8",
		"6 	c #B1B1B1",
		"7 	c #AFAFAF",
		"8 	c #B3B3B3",
		"9 	c #B7B7B7",
		"0 	c #BABABA",
		"a 	c #BDBDBD",
		"b 	c #BEBEBE",
		"c 	c #B9B9B9",
		"d 	c #979797",
		"e 	c #7D7D7D",
		"f 	c #656565",
		"g 	c #5E5E5E",
		"h 	c #3B3B3B",
		"i 	c #454545",
		"j 	c #171717",
		"k 	c #141414",
		"l 	c #434343",
		"m 	c #3C3C3C",
		"n 	c #606060",
		"o 	c #676767",
		"p 	c #7F7F7F",
		"q 	c #959595",
		"r 	c #B6B6B6",
		"s 	c #CCCCCC",
		"t 	c #CECECE",
		"u 	c #D5D5D5",
		"v 	c #D9D9D9",
		"w 	c #DCDCDC",
		"x 	c #DFDFDF",
		"y 	c #E2E2E2",
		"z 	c #E4E4E4",
		"A 	c #E6E6E6",
		"B 	c #E7E7E7",
		"C 	c #E8E8E8",
		"D 	c #FBFBFB",
		"E 	c #EEEEEE",
		"F 	c #DADADA",
		"G 	c #D8D8D8",
		"H 	c #C4C4C4",
		"I 	c #B5B5B5",
		"J 	c #B0B0B0",
		"K 	c #B2B2B2",
		"L 	c #7C7C7C",
		"M 	c #6C6C6C",
		"N 	c #333333",
		"O 	c #101010",
		"P 	c #313131",
		"Q 	c #3E3E3E",
		"R 	c #373737",
		"S 	c #767676",
		"T 	c #646464",
		"U 	c #0C0C0C",
		"V 	c #0A0A0A",
		"W 	c #5B5B5B",
		"X 	c #3F3F3F",
		"Y 	c #1F1F1F",
		"Z 	c #6D6D6D",
		"` 	c #7E7E7E",
		" .	c #D0D0D0",
		"..	c #D4D4D4",
		"+.	c #DDDDDD",
		"@.	c #E1E1E1",
		"#.	c #E5E5E5",
		"$.	c #E9E9E9",
		"%.	c #EAEAEA",
		"&.	c #FAFAFA",
		"*.	c #E0E0E0",
		"=.	c #DEDEDE",
		"-.	c #C7C7C7",
		";.	c #AEAEAE",
		">.	c #4C4C4C",
		",.	c #828282",
		"'.	c #343434",
		").	c #080808",
		"!.	c #555555",
		"~.	c #0E0E0E",
		"{.	c #737373",
		"].	c #C9C9C9",
		"^.	c #EBEBEB",
		"/.	c #F9F9F9",
		"(.	c #ECECEC",
		"_.	c #E3E3E3",
		":.	c #C0C0C0",
		"<.	c #888888",
		"[.	c #484848",
		"}.	c #070707",
		"|.	c #414141",
		"1.	c #8D8D8D",
		"2.	c #A4A4A4",
		"3.	c #929292",
		"4.	c #8B8B8B",
		"5.	c #AAAAAA",
		"6.	c #747474",
		"7.	c #ADADAD",
		"8.	c #919191",
		"9.	c #A1A1A1",
		"0.	c #A3A3A3",
		"a.	c #585858",
		"b.	c #717171",
		"c.	c #D7D7D7",
		"d.	c #F8F8F8",
		"e.	c #595959",
		"f.	c #7A7A7A",
		"g.	c #A6A6A6",
		"h.	c #8F8F8F",
		"i.	c #909090",
		"j.	c #949494",
		"k.	c #969696",
		"l.	c #939393",
		"m.	c #A5A5A5",
		"n.	c #BBBBBB",
		"o.	c #C8C8C8",
		"p.	c #EDEDED",
		"q.	c #F7F7F7",
		"r.	c #151515",
		"s.	c #8C8C8C",
		"t.	c #707070",
		"u.	c #0D0D0D",
		"v.	c #6A6A6A",
		"w.	c #9E9E9E",
		"x.	c #F6F6F6",
		"y.	c #232323",
		"z.	c #8E8E8E",
		"A.	c #A7A7A7",
		"B.	c #A2A2A2",
		"C.	c #9A9A9A",
		"D.	c #989898",
		"E.	c #626262",
		"F.	c #A9A9A9",
		"G.	c #121212",
		"H.	c #0F0F0F",
		"I.	c #A8A8A8",
		"J.	c #999999",
		"K.	c #ABABAB",
		"L.	c #696969",
		"M.	c #F3F3F3",
		"N.	c #797979",
		"O.	c #9B9B9B",
		"P.	c #F2F2F2",
		"Q.	c #D3D3D3",
		"R.	c #0B0B0B",
		"S.	c #727272",
		"T.	c #878787",
		"U.	c #EFEFEF",
		"V.	c #111111",
		"W.	c #787878",
		"X.	c #1B1B1B",
		"Y.	c #6F6F6F",
		"Z.	c #A0A0A0",
		"`.	c #202020",
		" +	c #DBDBDB",
		".+	c #ACACAC",
		"++	c #808080",
		"@+	c #464646",
		"#+	c #404040",
		"$+	c #B4B4B4",
		"%+	c #1E1E1E",
		"&+	c #CBCBCB",
		"*+	c #4F4F4F",
		"=+	c #C1C1C1",
		"-+	c #C3C3C3",
		";+	c #474747",
		">+	c #BCBCBC",
		",+	c #4D4D4D",
		"'+	c #C6C6C6",
		")+	c #262626",
		"!+	c #131313",
		"~+	c #C2C2C2",
		"{+	c #3D3D3D",
		"]+	c #5A5A5A",
		"^+	c #393939",
		"/+	c #858585",
		"(+	c #444444",
		"_+	c #4A4A4A",
		":+	c #090909",
		"<+	c #1D1D1D",
		"[+	c #505050",
		"}+	c #6E6E6E",
		"|+	c #757575",
		"1+	c #161616",
		"2+	c #5D5D5D",
		"3+	c #6B6B6B",
		"4+	c #838383",
		"5+	c #7B7B7B",
		"6+	c #545454",
		"7+	c #777777",
		"8+	c #515151",
		"9+	c #898989",
		"0+	c #4E4E4E",
		"a+	c #222222",
		"b+	c #424242",
		"c+	c #494949",
		"d+	c #D6D6D6",
		"e+	c #616161",
		"f+	c #636363",
		"g+	c #1C1C1C",
		"h+	c #212121",
		"i+	c #5F5F5F",
		"j+	c #8A8A8A",
		"k+	c #525252",
		"l+	c #5C5C5C",
		"m+	c #666666",
		"n+	c #4B4B4B",
		"o+	c #686868",
		"p+	c #818181",
		"q+	c #272727",
		"                                                                                                                        ",
		"              . . . . . . . + . . + . . + . . . . + + + . + . + . + . . . . . . + + + + . . . . + . . . . . +           ",
		"    @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @     ",
		"    # $ % % % % % & & & * * = - = * & * & & ; > , ' ) ! ~ ~ ~ { ! % ] ^ / , ] ) ) ] ] ' ' ' ( ( ( ( ( ( ( ( ( ( _ :     ",
		"    < * [ [ [ [ } | 1 2 3 4 5 6 7 8 9 0 a b c d e f g h i j k l m n o p q r 2 s t [ u v w x y z A B C C C C C C ] D     ",
		"    E ' F F F F v G u } s H a I J 7 K I L M N O P Q R S T U V W p Q X / ! Y Z ` 6 s  ...v +.@.#.B C $.$.%.%.%.%.P &.    ",
		"    E ( @.@.*.*.=.+.F u t -.b 5 K ;.e ; V / >.,.9 9 9 5 '.).).% 5 5 c c   !.Q k ~.{.].| u F x z B C $.%.^.^.^.^.P /.    ",
		"    (.( #.#.#.z _.*.+.G } ].:.c <.[.}.|.1.6 K 2.3.4.5.6.~.).).U Z 7.1.8.9.5 0 0.a.V - b. .c.+.y A C %.^.(.(.(.(.; d.    ",
		"    ^.P C C C B A _.x F [ 2 :.e.).m f.;.g.1.1.h.i.j.K ( }.}.}.}.% ;.k.3.l.3.3.m.n.. n ).> o.F *.#.C %.^.(.p.p.p.; q.    ",
		"    %.P %.%.$.C B #.*.F [ :.( r.f.7.7.i.s.h.8.8.1.7.t.u.}.}.}.}.U v.;.h.3.l.q l.q 7.a w.& $ 3 =.z C %.(.(.p.E E ; x.    ",
		"    %.P ^.^.^.$.C A @.F a y.) 0.6 k.1.z.z.h.h.h.k.A.N }.}.}.}.}.}.) B.C.i.3.3.q q q D.8 9 E.= <.y B $.(.p.E E E ; x.    ",
		"    B P (.(.(.^.$.A @.H y.X I F.3.8.3.h.h.z.h.z.A.T k G.G.V ).H.G.k n I.h.3.3.l.q k.d J.K.:.L.Y 4.B $.(.p.E E E ; M.    ",
		"    B P p.p.(.^.$.B 1 $ L.9 A.D.q l.3.i.h.z.h.z.3.j.. 9.2.; U N.2.w.j.j.h.8.3.3.l.q d O.+ I.a w._ 8.$.^.p.E E E P P.    ",
		"    #.P E p.p.(.$.Q.~ |.:.K.w.J.q 3.3.8.h.z.z.z.z.8.8.i.g.( R.S.  i.i.h.i.i.8.3.l.q k.J.. B.7.H T.Y 4 ^.p.E E U.P P.    ",
		"    z P E E p.(.B ] (  .9 m.  J.k.l.3.i.i.h.h.z.h.h.h.z.2.] R.t.+ z.h.h.i.i.8.3.3.l.q D.+ B.F.8  .o V.t p.E E U.P <     ",
		"    _.P E E p.(.W.X.[ o.K.m.  D.k.j.8.8.i.h.z.h.z.z.h.z.2.' R.Y.+ 1.h.z.h.i.i.8.8.l.j.d O.Z.I.7.:.G , `.c.E E U.P E     ",
		"    y P E E E r V +  +6 .+m.  C.k.j.3.i.i.i.h.h.z.z.z.s.0.] R.Y.O.1.h.h.h.h.i.8.3.l.j.d C.  g.;.6 Q.v { ++E E U.P E     ",
		"    @.P U.E E @+#+z b 8 7.m.  J.q j.3.i.8.i.h.h.z.z.z.1.0.] R.Y.O.1.h.h.h.h.h.8.3.3.q k.C.  g.;.$+r C ,.%+t E U.P p.    ",
		"    @.P U.E 7 R.F.z r I 7.m.  J.k.l.3.3.8.h.z.h.z.z.z.s.0.' R.Y.O.1.z.z.h.h.h.8.3.3.l.k.C.  m.7.$+9 &+G %+<.E U.P ^.    ",
		"    x P U.$.> *+#.=+5 I 7.m.w.C.k.j.3.3.8.i.h.z.z.z.z.1.0.] R.Y.O.s.z.h.z.h.i.8.3.3.j.k.C.  m.7.I 0 n.$.l.! n.U.P %.    ",
		"    w P U.g.u.n.+.0 0 I 7.m.  C.k.l.3.3.i.i.h.h.h.z.z.1.0.] R.Y.O.s.z.h.h.h.i.i.3.3.j.k.C.  m.7.$+c a -+%.h 4.U.( o.    ",
		"    G P U.T.;+(.a b 0 I 7.m.  C.q j.3.3.8.i.z.h.z.z.z.s.0.] R.Y.O.1.z.h.h.h.i.i.3.3.j.k.C.  m.7.I 0 4 >+(.f ,+%.R '+    ",
		"    u > B Q T (.a 4 0 I .+m.  C.k.l.3.3.8.i.z.h.h.z.z.1.0.' R.Y.O.1.z.z.h.h.h.8.3.3.j.k.C.  m.7.I 0 b :.Q.9 )+=+X H     ",
		"    [ #+:.!+7.G :.b 5 8 K.m.w.J.k.j.3.3.8.i.h.h.h.z.z.1.0.' R.Y.O.s.z.h.h.h.i.8.8.3.l.k.J.  m..+K 5 b ~+>+E m g.X -+    ",
		"    } {+  / E :.:.0 =+ .6 m.w.J.k.j.3.8.i.i.z.z.z.z.z.1.2.' R.Y.O.1.z.z.h.z.h.8.3.3.j.k.C.w.m.6 } ~+0 :.b (.]+W - ~+    ",
		"     .^+j.>.E r -+A c.` K A.  C.k.j.3.8.8.i.h.z.h.z.z.s.0.] R.Y.O.1.z.h.h.h.h.8.8.3.j.k.C.  A.K e c.A -+0 +.C.'.r.=+    ",
		"     .^ /+(+E z ^.i._+:+>+I.w.C.q j.3.3.i.i.h.h.z.z.z.s.0.] R.Y.O.1.z.z.h.h.i.8.8.3.j.k.C.  I.>+:+_+8.^._.c.i.i j =+    ",
		"     .<+[++ E h._+V :+!+3 g.+ D.j.3.i.i.h.h.z.1.z.1.s.s.0.' R.}+C.s.s.1.1.1.z.h.i.i.3.q D.. m.3 !+:+V _+d E v m r.=+    ",
		"     .! e.|+Q ~.V V :+1+o.=+r 6 .+5.I.A.g.m.2.2.2.0.0.0.7.N U f..+B.0.m.2.2.m.g.A.I.5..+J r :.o.1+:+V V O ^+&+l r.=+    ",
		"     .{ X.R.V V V V :+u.{+R N ; P P ' ' ' ' ' ' ] ] ] ' N k :+)+; ) ' ' ' ' ' ' ' ( P P ; N R {+u.:+V V V V 1+O r.=+    ",
		"     .~ { V V V V V :+V H.u.U U R.R.R.R.R.R.R.R.R.R.R.R.U :+}.V U R.R.R.R.R.R.R.R.R.R.R.U U u.H.V :+V V V V ~.H.r.=+    ",
		"     .X.2+3+^+H.V V :+G.8.4+L W.|+{.S.b.b.b.Y.t.Y.Y.Y.}+5+)+R.6+S Y.Y.Y.t.t.b.t.b.S.{.|+W.L 4+8.G.:+V V V ^ 7.m r.=+    ",
		"     .! (+g.E l.i V :+k &+9 .+A.0.9.Z.w.. + + + + O.O.J.7.; U 7+A.C.O.+ + + + w.  Z.9.0.A..+9 &+r.:+V |.,.(.%.R r.=+    ",
		"     .) }+8+E #.C 9+l :+n.A.+ D.j.3.8.i.h.h.1.z.z.1.s.4.B.] R.Y.J.4.1.z.z.z.h.h.i.i.3.q D.. g.>+:+m ,.@.(.u 0.h r.=+    ",
		"     ./ + >.E 9 '+C  .7+K A.  C.k.j.3.3.8.i.h.z.h.z.z.1.0.' R.Y.O.1.z.h.h.h.i.8.3.3.l.q C.  A.$+S 2 C -.n.G 9.X r.=+    ",
		"     .{+9.0+E n.:.0 H Q.6 m.w.C.k.j.3.3.8.i.z.z.h.z.z.1.0.' R.Y.O.1.z.z.h.z.i.8.3.3.j.q C.  m.6 Q.-.0 4 b $.6.,+a+=+    ",
		"     .|.I ~ -. .:.b 5 8 .+m.  C.k.j.3.3.8.i.z.h.h.z.z.1.0.] R.Y.O.s.z.h.h.h.i.8.3.3.l.k.C.  m.K.K 5 b ~+a E |.C.m =+    ",
		"     .h v a+Y.^.a 4 0 I 7.m.w.C.k.l.3.3.8.h.z.z.h.z.z.1.0.' R.Y.O.s.z.h.z.h.i.8.3.3.l.q C.  m.7.I 0 b :.1 } $ 0 b+=+    ",
		"     .P U.,._+(.a b 0 I .+m.  C.k.j.3.8.i.i.h.h.h.z.z.s.0.] R.Y.O.s.z.z.h.h.i.8.3.3.j.q C.  m.7.I c 4 a C ++`.} h =+    ",
		"     .( U.+ j t Q.>+0 $+7.m.  C.k.j.3.3.8.i.h.h.z.z.z.s.0.' R.Y.O.1.z.h.z.h.i.8.3.3.j.k.J.w.m.7.I 0 a a (.c+M U.N =+    ",
		"     .( U.2 { Y.^.n.c $+7.m.  C.k.j.3.3.8.h.z.z.z.z.z.s.0.' R.Y.O.1.z.h.h.z.i.8.3.3.j.q C.w.m..+I 0 0 w 3 { I.U.( =+    ",
		"     .( U.E D.U -+d+r I 7.m.  C.k.j.3.3.8.i.h.h.h.z.z.1.0.] R.Y.O.1.z.h.h.h.h.i.3.3.j.k.C.  m.7.I c -+_.h #+E U.( =+    ",
		"     .( U.E y %+e+C 5 $+;.g.  C.d q 3.3.8.i.z.h.z.z.z.s.0.' R.Y.O.s.z.h.h.z.h.8.8.3.l.q J.  m.7.I r B 0.U a E U.( =+    ",
		"     .( U.E E k.V -.v J 7.g.  O.d q 3.8.i.i.h.h.h.h.z.1.0.] R.Y.O.s.z.z.h.z.i.i.8.3.j.k.J.w.m.7.6 '+C ) ,+E E E ( =+    ",
		"     .( U.E E #.'.; u ~+.+A.Z.O.d q l.8.i.h.h.h.z.h.h.z.2.] R.Y.+ z.z.z.h.h.h.h.i.3.l.k.J.w.m.K.5 d+T { -+p.E E ( =+    ",
		"     .( U.E E p.c.O f+u 8 I.B.O.D.q j.3.3.8.i.i.h.z.z.z.2.' R.t.+ z.z.h.z.h.h.i.8.3.l.q D.  m.7.| 0.V K.(.p.E E ( =+    ",
		"     .( U.E E p.^.s = Y.-+.+B.. J.q q l.3.8.8.i.h.i.8.8.g.' R.b.  8.i.z.h.z.h.h.8.3.l.q J.  m.a 0.g+f.$.(.p.p.E ( =+    ",
		"     .( E E E p.^.$.l.%+w.4 A.. O.D.q l.3.8.i.i.l.j.  9.2.; U N.2.w.q 3.z.h.z.h.h.3.3.q D.  I 5 h+|.A $.^.(.p.p.( =+    ",
		"     .( E E E p.(.$.B 4.y.p a F.J.D.q q l.3.8.h.I.n k G.G.V ).H.G.G.i+F.1.h.z.h.i.8.3.l.+ r k.h+|. +A $.^.(.(.(.( =+    ",
		"     .( E E E p.(.$.B y 9+<+f+c 7 d q q q l.3.h.J.B.) }.}.}.}.}.}.- + J.z.i.h.z.z.i.h.  7 j+! {+c.@.A C $.^.^.^.' =+    ",
		"     .( E E p.(.(.%.C z =.I.%+> K b 2.q j.q l.3.h.7 v.U }.}.}.}.V T 7 1.i.8.i.z.s.l.J $+k+).v.[ F *.#.B C $.%.%.' =+    ",
		"     .( p.p.p.(.^.%.C #.*.F 4 % V.M .+c D.3.l.q 3.k.7.) }.}.}.}.)+I.d 8.3.i.1.s.g.K.|+'.j ` 2 [ F x _.A B C C C ' =+    ",
		"     .( (.(.(.(.^.%.C A y +.c.t l+{ `.|+>+0 m.l.3.z.J m+R.).).u.v.6 z.8.i.C.J J l.> }.n+m.:.].} G +.*._.z #.#.#.] =+    ",
		"     .' ^.^.^.^.%.$.C B z x F u | >+o+r.R 0+l.0 c K.F.6 Y ).).y.r 2.m.K r 9.n {+!+m /+K 5 b -.t u F +.=.*.*.@.@.] =+    ",
		"     .' %.%.%.%.$.$.C B #.@.+.v .. .s 2.7+b+h+, c+e 6.a 3.u.V.C.a ` p+2+, %+X.]+` K 7 J I a H s } u G v F F F F ) =+    ",
		"    t ' C c.G c.c.d+u ....[ | 1 o.'+-+t s '+w.T./ = - = '.R.U , % * ] P 6.h.I.a 0 7 A.B.m.5.K 9 0 4 =+~+~+~+3 -.- 4     ",
		"    2 h+] * * * * * = = = = = - - - q+q+- ' R ^ `.!+!+!+!+!+!+!+!+!+!+! P , N = _ _ $ y.y.y.$ _ )+)+)+)+)+)+)+q+Y >+    ",
		"    ~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+=+:.>+r     ",
		"                                                                                                                        ",
		"                                                                                                                        "};
	elseif pic == '1' then
	Image = {
	--XpmImage Here
	};
	end
	return Image
end

function ImageRight(pic)
	local Image = {
	"60 60 143 2",
	"  	c #ACACAC",
	". 	c #ADADAD",
	"+ 	c #9D9D9D",
	"@ 	c #9C9C9C",
	"# 	c #9E9E9E",
	"$ 	c #A5A5A5",
	"% 	c #B3B3B3",
	"& 	c #B8B8B8",
	"* 	c #FFFFFF",
	"= 	c #F2F2F2",
	"- 	c #BDBDBD",
	"; 	c #C5C5C5",
	"> 	c #FDFDFD",
	", 	c #F0F0F0",
	"' 	c #F1F1F1",
	") 	c #C3C3C3",
	"! 	c #FBFBFB",
	"~ 	c #EEEEEE",
	"{ 	c #EFEFEF",
	"] 	c #ECECEC",
	"^ 	c #AEAEAE",
	"/ 	c #C0C0C0",
	"( 	c #C2C2C2",
	"_ 	c #FAFAFA",
	": 	c #EDEDED",
	"< 	c #EBEBEB",
	"[ 	c #AFAFAF",
	"} 	c #BFBFBF",
	"| 	c #F9F9F9",
	"1 	c #EAEAEA",
	"2 	c #F8F8F8",
	"3 	c #E9E9E9",
	"4 	c #B0B0B0",
	"5 	c #C1C1C1",
	"6 	c #F7F7F7",
	"7 	c #F6F6F6",
	"8 	c #E8E8E8",
	"9 	c #E7E7E7",
	"0 	c #F3F3F3",
	"a 	c #E6E6E6",
	"b 	c #E5E5E5",
	"c 	c #808080",
	"d 	c #797979",
	"e 	c #393939",
	"f 	c #383838",
	"g 	c #E4E4E4",
	"h 	c #323232",
	"i 	c #313131",
	"j 	c #E3E3E3",
	"k 	c #BEBEBE",
	"l 	c #3D3D3D",
	"m 	c #E2E2E2",
	"n 	c #4B4B4B",
	"o 	c #424242",
	"p 	c #E1E1E1",
	"q 	c #585858",
	"r 	c #595959",
	"s 	c #DADADA",
	"t 	c #818181",
	"u 	c #E0E0E0",
	"v 	c #5B5B5B",
	"w 	c #D6D6D6",
	"x 	c #494949",
	"y 	c #464646",
	"z 	c #DFDFDF",
	"A 	c #565656",
	"B 	c #D1D1D1",
	"C 	c #414141",
	"D 	c #161616",
	"E 	c #454545",
	"F 	c #DEDEDE",
	"G 	c #CCCCCC",
	"H 	c #BBBBBB",
	"I 	c #DDDDDD",
	"J 	c #DCDCDC",
	"K 	c #2C2C2C",
	"L 	c #DBDBDB",
	"M 	c #575757",
	"N 	c #B5B5B5",
	"O 	c #272727",
	"P 	c #A6A6A6",
	"Q 	c #A7A7A7",
	"R 	c #222222",
	"S 	c #D9D9D9",
	"T 	c #555555",
	"U 	c #D8D8D8",
	"V 	c #1E1E1E",
	"W 	c #B9B9B9",
	"X 	c #9B9B9B",
	"Y 	c #1B1B1B",
	"Z 	c #D7D7D7",
	"` 	c #919191",
	" .	c #181818",
	"..	c #B4B4B4",
	"+.	c #D2D2D2",
	"@.	c #CACACA",
	"#.	c #C9C9C9",
	"$.	c #525252",
	"%.	c #535353",
	"&.	c #CBCBCB",
	"*.	c #7F7F7F",
	"=.	c #171717",
	"-.	c #C8C8C8",
	";.	c #CDCDCD",
	">.	c #C4C4C4",
	",.	c #CFCFCF",
	"'.	c #C7C7C7",
	").	c #515151",
	"!.	c #747474",
	"~.	c #D0D0D0",
	"{.	c #737373",
	"].	c #C6C6C6",
	"^.	c #B1B1B1",
	"/.	c #888888",
	"(.	c #909090",
	"_.	c #1A1A1A",
	":.	c #B2B2B2",
	"<.	c #969696",
	"[.	c #1D1D1D",
	"}.	c #9F9F9F",
	"|.	c #212121",
	"1.	c #CECECE",
	"2.	c #252525",
	"3.	c #353535",
	"4.	c #989898",
	"5.	c #999999",
	"6.	c #ABABAB",
	"7.	c #292929",
	"8.	c #404040",
	"9.	c #2E2E2E",
	"0.	c #B6B6B6",
	"a.	c #545454",
	"b.	c #BABABA",
	"c.	c #3B3B3B",
	"d.	c #3F3F3F",
	"e.	c #484848",
	"f.	c #4A4A4A",
	"g.	c #333333",
	"h.	c #BCBCBC",
	"i.	c #A1A1A1",
	"j.	c #A0A0A0",
	"k.	c #A2A2A2",
	"l.	c #A9A9A9",
	"        .       .     . .   .         .     .     . .         . .   .     .   .       . .     . . .             .       ",
	". .   + + @ + + + + + @ + + + + @ @ @ @ + + + + + + @ + @ + @ + @ @ @ + + + + @ + + @ + + @ + + + + + + + + + + # $     ",
	"% & * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * =   ",
	"- ; > , ' , , , , ' , , ' ' , , , , ' ' ' , , , , , ' ' ' ' , ' ' ' , , , ' , ' , ' ' , , , , , , , , , ' ' , , , ' ' % ",
	"- ) ! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ ~ ~ ~ ~ ~ ~ ~ ~ { ~ ~ ~ ~ ~ ~ { ~ ~ { ~ { { ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ , ] ^ ",
	"/ ( _ : : : : : : : : : : : : : : : : : : : ~ ~ : : : : : : : : ~ : : : : : : : : : : ~ : ~ ~ : : : : : : : : : : ~ < [ ",
	"} ( | : : : : : ] : : : : : : : : : : : : ] : : : : : : : : : ] ] ] : : : : : : : : : : : : : : : : : ] ] : ] : : ~ 1 [ ",
	"} ( 2 < < ] < < ] ] < < < < < < ] < < < < < < < < < ] < < < < < < < < < ] < < ] < < < < < ] ] < < ] < < < < < < < ] 3 4 ",
	"} 5 6 1 1 < < 1 1 1 1 1 < 1 1 1 1 < 1 1 1 1 1 1 1 1 1 1 1 1 < < 1 1 1 < 1 1 1 1 < 1 1 1 1 1 < < 1 1 1 1 < 1 < 1 1 < 3 [ ",
	"} 5 7 3 3 1 1 3 3 3 3 3 1 3 3 3 3 3 3 3 3 3 3 3 1 3 3 1 1 3 3 3 3 3 3 3 3 1 3 3 1 3 3 3 3 3 1 1 3 3 3 3 1 1 3 3 3 1 8 [ ",
	"} 5 7 3 3 3 3 3 3 3 3 3 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 1 9 [ ",
	"/ / 0 9 9 9 8 8 9 9 a b 9 8 8 9 9 9 8 9 9 8 8 8 9 8 8 a 8 8 9 9 8 8 8 a 8 9 9 8 9 9 8 9 9 8 9 9 9 9 a 8 9 9 9 8 a 9 a 4 ",
	"} } = a a a a a a c c d a a a a a a 9 a a 9 a a a 9 a a a a a 9 a 9 9 9 9 a a a a a 9 a a 9 a a a a 9 a a a a 9 a 9 b [ ",
	"/ } = b b b b b b e e f b b b b a b b b b b b b b b b b b b b b b b b b b b b b b b a b b b a b b b b a b b b b b b g [ ",
	"/ } , g g g g g g h h i g j g g g g g g g g g g g g g g g g g j g g g g g g g g g g g g g g g g g g g g g g g g g g j 4 ",
	"/ k ~ g g j j g g l l i g g g j g g g g j g g g g g j j g g g j g j j j g g g g g g m g g j j j g g g g j g g g g g j [ ",
	"5 k ~ m m m j j j n n o j m m m j m m j j j m m m j j j m j j m m m m m m j j m j j m j m m j m m j j j m m j j j j m 4 ",
	"5 - : m m p m m m q q r m m p p p p p p m p p p m m m m p s t p m m p p m p p p p m m p p p m p p p p p p p p p m p p [ ",
	"5 - < u u u u u u r r v u u p u u u p u u u u u u u u u w x y p p u u u u u u u u u u u u u u p u u u u u u u u p u u [ ",
	"5 - 1 z z z z z z A A q z z z z z z u z z z z z z z z B C D E z z z z z z z z z z z z z z z z z z u z z u z z z z z z 4 ",
	"5 - 3 z z z z z F A A q z z z z z z F z z z z z F z G e D D E z z F z z z z z z z z z z z z z z z F z z z z z z z z z [ ",
	"5 H 8 F I I I I I A A q F F F F I F F I F F F F I ; i D D D E I I I F F F F F F F I F F F I F F F I F I I I F F F J F 4 ",
	"( H 9 I J J I I I A A q J J I I I I I I J J J J k K D D D D E J I I I I J J J I I J J I I I J J J J I I I I J I J L I 4 ",
	"( H a L L L J J J A A M L L J L J L L J L L L N O D D D D D f P Q Q P P Q Q P P P L L L J J L L L L L J J J L L L L J [ ",
	"( H g L L L L L L A A M L L L L L L L L L L ^ R D D D D D D D D D D D D D D D D D L L L L L L L L L L L L L L L L s L 4 ",
	"( H j S S S S S s T T M U S s s s s S S S $ V D D D D D D D D D D D D D D D D D D s s s s S s s s s S S s s S S S U s [ ",
	"( W j U U S S U S T T M S U s S S S s S X Y D D D D D D D D D D D D D D D D D D D S S S S S S S S S S U S S U U S S s 4 ",
	") W u Z w Z U w w T T A Z Z Z Z Z w Z `  .D D D D D D D D D D D D D D D D D D D D Z w w Z Z Z w w U U Z w Z Z Z Z w S 4 ",
	"; ..+.@.@.@.@.@.#.$.$.%.@.@.@.@.@.&.*.=.D D D D D D D D D D D D D D D D D D D D D @.@.@.@.@.@.@.@.@.@.@.#.@.@.#.#.-.;.4 ",
	">.% ,.-.-.-.-.-.'.).).%.-.'.-.#.-.!.D D D D D D D D D D D D D D D D D D D D D D D -.#.#.'.#.'.-.#.'.'.#.'.'.#.-.'.; G 4 ",
	"; % ~.#.-.-.#.-.-.$.$.%.#.-.-.#.#.{.D D D D D D D D D D D D D D D D D D D D D D D -.-.-.#.-.-.#.#.#.-.-.#.#.-.#.#.].G ^.",
	"; % ~.#.#.-.-.#.#.$.).%.#.#.-.-.-.-.*.=.D D D D D D D D D D D D D D D D D D D D D -.#.#.-.-.#.#.-.-.-.-.#.#.-.-.#.; G ^.",
	">.% ~.#.#.#.#.-.-.$.$.%.#.#.#.#.-.-.-./. .D D D D D D D D D D D D D D D D D D D D -.-.#.-.-.#.-.-.-.-.-.#.-.#.-.-.; G ^.",
	"; % ~.#.#.#.#.#.-.$.$.%.#.-.-.#.#.#.-.#.(._.D D D D D D D D D D D D D D D D D D D #.-.#.#.-.#.-.#.-.#.#.-.#.-.#.-.].G ^.",
	"; :.,.'.'.-.'.-.'.).).%.'.'.'.'.-.-.'.'.'.<.[.D D D D D D D D D D D D D D D D D D -.'.-.-.'.'.'.'.'.'.'.-.'.'.-.'.>.&.4 ",
	"; % ,.'.-.-.'.'.'.).).%.'.'.'.'.'.'.'.-.-.'.}.|.D D D D D D D D D D D D D D D D D '.-.'.'.'.'.'.'.'.-.'.'.'.'.'.'.>.&.4 ",
	"; % 1.-.'.'.-.-.-.).).%.-.'.'.'.-.'.'.'.'.'.'.P 2.D D D D D 3.4.4.5.5.4.4.4.4.4.4.-.'.-.-.'.-.-.'.'.'.'.'.'.'.-.'.; G ^.",
	"; % 1.'.'.'.'.-.'.).).%.'.-.'.'.'.'.'.-.-.'.'.'.6.7.D D D D 8.'.'.'.'.'.'.-.'.-.'.'.'.'.'.'.'.'.'.'.-.-.'.'.'.'.'.>.&.^.",
	"; % ,.'.'.'.'.-.'.).).%.-.'.'.'.'.'.'.'.-.'.'.'.-.:.9.D D D 8.'.'.'.'.'.'.'.-.-.-.'.'.'.'.-.-.'.'.'.'.'.'.'.'.'.'.; &.4 ",
	"; :.1.'.'.'.'.'.'.$.$.%.'.'.'.'.'.'.'.'.'.'.'.'.'.'.0.3.D D 8.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.>.&.4 ",
	"].:.;.].].].].].].a.a.T ].].].].].].].].].].].].].].].b.c.D d.].].].].].].].].].].].].].].].].].].].].].].].].].].) @.4 ",
	"; :.;.].].].].].].e.e.f.].].].].].].].].].].].].].].].].- o d.].].].].].].].].].].].].].].].].].].].].].].].].].].) @.^.",
	"; :.;.].].].].].].g.g.g.].].].].].].].].].].].].].].].].]./ {.].].].].].].].].].].].].].].].].].].].].].].].].].].) @.4 ",
	"; :.;.].].].].].].i i i ].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].) @.4 ",
	"; :.;.].].].].].].i i i ].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].) @.^.",
	"; :.;.].].].].].].i i i ].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].].) @.4 ",
	"; :.G ; ; ; ; ; ; ; ; ; ; >.; ; ; ; >.; ; ; >.>.; >.; >.; >.; ; ; ; ; ; ; >.; ; >.; ; >.>.>.; ; ; ; ; ; ; ; >.; ; ( #.4 ",
	"; :.G ; ; ; ; ; ; ; ; ; >.; >.>.>.>.; >.; ; ; ; ; ; ; ; ; ; ; ; >.>.>.; ; ; ; ; ; ; ; >.; ; >.; ; ; ; ; ; >.; ; ; ( #.^.",
	"].^.G ; >.; ; ; ; ; ; ; ; >.>.; ; ; ; ; ; >.; ; ; ; ; ; ; ; ; >.; ; ; >.>.; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; >.; ; ( #.4 ",
	"].^.&.; ; ; ; ; ; ; >.; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; >.; ; ; ; ; ; ; ; ; ; ; >.; ; >.>.; ; ; ; ( #.4 ",
	"; :.G ; ; ; ; ; ; ; ; ; ; ; ; >.>.; ; ; ; ; ; ; ; >.>.; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ( -.4 ",
	"; ^.&.>.) >.>.>.>.>.>.>.>.>.>.; ; >.>.>.>.>.>.>.) ; ; >.>.>.>.>.>.>.>.>.) >.>.>.>.>.>.>.>.>.>.>.) >.>.>.>.>.) >.>./ #.^.",
	">.:.G ; >.; ; ; ; ; ; ; ; >.>.; ; ; ; ; ; >.; ; ; ; ; ; ; ; ; >.; ; ; >.>.; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; >.; ; ( #.4 ",
	"( :.&.; ; ; ; ; ; ; >.; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; >.; ; ; ; ; ; ; ; ; ; ; >.; ; >.>.; ; ; ; ( #.4 ",
	"h.:.G ; ; ; ; ; ; ; ; ; ; ; ; >.>.; ; ; ; ; ; ; ; >.>.; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ( -.4 ",
	"%   &.>.) >.>.>.>.>.>.>.>.>.>.; ; >.>.>.>.>.>.>.) ; ; >.>.>.>.>.>.>.>.>.) >.>.>.>.>.>.>.>.>.>.>.) >.>.>.>.>.) >.>./ #.4 ",
	"^   ; / / } / } / / } } } / / / / / / } / } / / / / / } / / / / / / / } / } / / / } / / } / / } / / } / / / / / / H #.4 ",
	"    : z z F z F F F z z F z z z z F F z F F F z z F F F F z F z z F F F z F F z F F F z z F F z z z z F F z F F z p #.4 ",
	"      i.j.j.j.j.i.i.i.i.i.i.j.i.i.j.i.j.j.i.j.i.j.j.i.i.i.i.j.i.j.i.i.i.i.i.i.i.i.k.i.j.i.j.j.j.i.j.i.i.i.i.i.i.i.l.  4 ",
	"                . .                       .           . .         . .   . . . . .   .                 . .     . . 4 4 4 "};
	return Image
end

function ImageBottomLeft(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 289 2",
		"  	c None",
		". 	c #9F9F9F",
		"+ 	c #989898",
		"@ 	c #929292",
		"# 	c #8C8C8C",
		"$ 	c #8D8D8D",
		"% 	c #8E8E8E",
		"& 	c #8F8F8F",
		"* 	c #909090",
		"= 	c #949494",
		"- 	c #979797",
		"; 	c #999999",
		"> 	c #9B9B9B",
		", 	c #9D9D9D",
		"' 	c #FFFFFF",
		") 	c #FEFEFE",
		"! 	c #FBFBFB",
		"~ 	c #FDFDFD",
		"{ 	c #CBCBCB",
		"] 	c #C9C9C9",
		"^ 	c #C8C8C8",
		"/ 	c #C7C7C7",
		"( 	c #C5C5C5",
		"_ 	c #C6C6C6",
		": 	c #C3C3C3",
		"< 	c #C0C0C0",
		"[ 	c #BBBBBB",
		"} 	c #EBEBEB",
		"| 	c #EAEAEA",
		"1 	c #E8E8E8",
		"2 	c #E7E7E7",
		"3 	c #E6E6E6",
		"4 	c #E4E4E4",
		"5 	c #E3E3E3",
		"6 	c #E2E2E2",
		"7 	c #E1E1E1",
		"8 	c #DFDFDF",
		"9 	c #E0E0E0",
		"0 	c #DDDDDD",
		"a 	c #CFCFCF",
		"b 	c #D0D0D0",
		"c 	c #CDCDCD",
		"d 	c #CCCCCC",
		"e 	c #CACACA",
		"f 	c #EEEEEE",
		"g 	c #EDEDED",
		"h 	c #ECECEC",
		"i 	c #E9E9E9",
		"j 	c #E5E5E5",
		"k 	c #D7D7D7",
		"l 	c #D6D6D6",
		"m 	c #D2D2D2",
		"n 	c #D4D4D4",
		"o 	c #D9D9D9",
		"p 	c #D8D8D8",
		"q 	c #D1D1D1",
		"r 	c #CECECE",
		"s 	c #878787",
		"t 	c #DBDBDB",
		"u 	c #D5D5D5",
		"v 	c #DADADA",
		"w 	c #BABABA",
		"x 	c #848484",
		"y 	c #6C6C6C",
		"z 	c #646464",
		"A 	c #656565",
		"B 	c #636363",
		"C 	c #616161",
		"D 	c #606060",
		"E 	c #5F5F5F",
		"F 	c #5B5B5B",
		"G 	c #595959",
		"H 	c #555555",
		"I 	c #515151",
		"J 	c #4C4C4C",
		"K 	c #484848",
		"L 	c #434343",
		"M 	c #3E3E3E",
		"N 	c #393939",
		"O 	c #343434",
		"P 	c #313131",
		"Q 	c #2D2D2D",
		"R 	c #2B2B2B",
		"S 	c #292929",
		"T 	c #262626",
		"U 	c #ADADAD",
		"V 	c #898989",
		"W 	c #DCDCDC",
		"X 	c #D3D3D3",
		"Y 	c #9E9E9E",
		"Z 	c #686868",
		"` 	c #717171",
		" .	c #757575",
		"..	c #747474",
		"+.	c #737373",
		"@.	c #727272",
		"#.	c #707070",
		"$.	c #6E6E6E",
		"%.	c #696969",
		"&.	c #666666",
		"*.	c #626262",
		"=.	c #5E5E5E",
		"-.	c #585858",
		";.	c #545454",
		">.	c #505050",
		",.	c #4E4E4E",
		"'.	c #4B4B4B",
		").	c #464646",
		"!.	c #444444",
		"~.	c #414141",
		"{.	c #363636",
		"].	c #7F7F7F",
		"^.	c #777777",
		"/.	c #767676",
		"(.	c #6B6B6B",
		"_.	c #676767",
		":.	c #5D5D5D",
		"<.	c #494949",
		"[.	c #424242",
		"}.	c #404040",
		"|.	c #3A3A3A",
		"1.	c #272727",
		"2.	c #ACACAC",
		"3.	c #828282",
		"4.	c #6F6F6F",
		"5.	c #6D6D6D",
		"6.	c #5C5C5C",
		"7.	c #4F4F4F",
		"8.	c #474747",
		"9.	c #454545",
		"0.	c #3F3F3F",
		"a.	c #353535",
		"b.	c #6A6A6A",
		"c.	c #575757",
		"d.	c #535353",
		"e.	c #3C3C3C",
		"f.	c #5A5A5A",
		"g.	c #232323",
		"h.	c #525252",
		"i.	c #252525",
		"j.	c #000000",
		"k.	c #565656",
		"l.	c #F0F0F0",
		"m.	c #111111",
		"n.	c #FAFAFA",
		"o.	c #4D4D4D",
		"p.	c #FCFCFC",
		"q.	c #F4F4F4",
		"r.	c #161616",
		"s.	c #F7F7F7",
		"t.	c #4A4A4A",
		"u.	c #3D3D3D",
		"v.	c #888888",
		"w.	c #090909",
		"x.	c #121212",
		"y.	c #010101",
		"z.	c #373737",
		"A.	c #F3F3F3",
		"B.	c #030303",
		"C.	c #EFEFEF",
		"D.	c #62605D",
		"E.	c #655E57",
		"F.	c #675B4E",
		"G.	c #655747",
		"H.	c #635546",
		"I.	c #5B5247",
		"J.	c #54504C",
		"K.	c #4E4D4C",
		"L.	c #131313",
		"M.	c #040404",
		"N.	c #605F5E",
		"O.	c #645D56",
		"P.	c #6B5A47",
		"Q.	c #3F6188",
		"R.	c #2468B4",
		"S.	c #156CCC",
		"T.	c #146BCD",
		"U.	c #2E5F97",
		"V.	c #4E4C49",
		"W.	c #524639",
		"X.	c #494542",
		"Y.	c #050505",
		"Z.	c #1B1B1B",
		"`.	c #5D5C5C",
		" +	c #62594F",
		".+	c #5C5856",
		"++	c #0871E5",
		"@+	c #007AFF",
		"#+	c #0078FF",
		"$+	c #007EFF",
		"%+	c #265A93",
		"&+	c #4A3C2C",
		"*+	c #3E3B37",
		"=+	c #222222",
		"-+	c #5C554E",
		";+	c #585653",
		">+	c #007CFF",
		",+	c #0076FA",
		"'+	c #0176F8",
		")+	c #0077FE",
		"!+	c #007DFF",
		"~+	c #21558E",
		"{+	c #473C2F",
		"]+	c #464544",
		"^+	c #565451",
		"/+	c #5F4E3B",
		"(+	c #0078FE",
		"_+	c #007FFF",
		":+	c #47433E",
		"<+	c #4D4741",
		"[+	c #242424",
		"}+	c #383838",
		"|+	c #554E47",
		"1+	c #375980",
		"2+	c #007BFF",
		"3+	c #116ACC",
		"4+	c #56493B",
		"5+	c #333333",
		"6+	c #55483A",
		"7+	c #1F63AE",
		"8+	c #0079FF",
		"9+	c #0077FD",
		"0+	c #0076FD",
		"a+	c #5F4B36",
		"b+	c #020202",
		"c+	c #303030",
		"d+	c #534433",
		"e+	c #0770E6",
		"f+	c #0076F9",
		"g+	c #654F37",
		"h+	c #F9F9F9",
		"i+	c #2C2C2C",
		"j+	c #4F4131",
		"k+	c #1269C8",
		"l+	c #68533B",
		"m+	c #2A2A2A",
		"n+	c #4A4137",
		"o+	c #26598F",
		"p+	c #0077FF",
		"q+	c #6A5946",
		"r+	c #282828",
		"s+	c #443F3B",
		"t+	c #423F3C",
		"u+	c #0080FF",
		"v+	c #32649E",
		"w+	c #665C52",
		"x+	c #41403F",
		"y+	c #463A2D",
		"z+	c #22568F",
		"A+	c #0771E6",
		"B+	c #6B5A46",
		"C+	c #63605C",
		"D+	c #403D39",
		"E+	c #463828",
		"F+	c #235690",
		"G+	c #0871E6",
		"H+	c #5B5A5B",
		"I+	c #413E3A",
		"J+	c #473B2E",
		"K+	c #44403B",
		"L+	c #1068CB",
		"M+	c #0076FE",
		"N+	c #0770E4",
		"O+	c #2E629C",
		"P+	c #675541",
		"Q+	c #635C55",
		"R+	c #626261",
		"S+	c #424140",
		"T+	c #47413B",
		"U+	c #4D4032",
		"V+	c #53402A",
		"W+	c #5A442B",
		"X+	c #5C4730",
		"Y+	c #5E4D3B",
		"Z+	c #5D544A",
		"`+	c #5D5A56",
		" @	c #DEDEDE",
		".@	c #838383",
		"+@	c #AEAEAE",
		"@@	c #1A1A1A",
		"#@	c #969696",
		"$@	c #060606",
		"%@	c #939393",
		"&@	c #F1F1F1",
		"*@	c #F5F5F5",
		"=@	c #0A0A0A",
		"-@	c #F8F8F8",
		";@	c #F2F2F2",
		">@	c #919191",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # $ $ $ $ $ % % % % & & & & * @ = - - - + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + ; > , . ",
		". @ ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ) ! ~ { { ] ^ / ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( _ : < [ > . ",
		". # ' } } | | 1 2 3 3 4 5 6 7 6 8 9 0 9 a b c d { e e e e e e e e e e e e e e e e e e e e e e e e e e e e e { ] ( < ; . ",
		". # ' f g h g | i 1 i 3 3 j 5 4 7 6 8 9 k l m b a a n o 0 8 9 9 9 9 7 7 7 6 5 5 4 j 3 3 2 1 1 i i i 2 9 p q r d ] ( + . ",
		". s ' g g h g h } | i 3 j j 5 6 7 9 8 8 t p u m n v w x y z A B C D E F G H I J K L M N O P Q R S T Q H U 7 u r { _ + . ",
		". V ' g g h g | } | i 1 j j 5 6 5 6 8 8 W o n X t Y Z `  . ...+.+.@.#.$.y %.&.*.=.-.;.>.,.'.K ).!.~.M {.S ].7 q e / + . ",
		". V ' g g h g | i 1 i 1 j j 5 4 5 6 8 8 W k n k [ Z ..^. ./. ...+.#.#.$.(._.A C :.G H I J <.).!.[.[.~.}.|.1.2.p e / + . ",
		". V ' g g h } h i 1 i 3 j j 5 4 5 6 8 8 W k u 0 3.4. ././. .+.@.@.` 4.5.(.&.z D 6.-.;.7.'.K 8.9.L }.0.}.M a.;.7 e / + . ",
		". V ' f g h g h i 1 i 3 3 j 5 4 7 9 8 8 W k u 7 Z ../... .+.@.+.#.#.$.y b.A B E F c.d.7.J 8.).!.~.~.}.M M e.S 2 e / + . ",
		". V ' g g h g | i 1 i g g h 5 4 7 9 7 8 W k n 5 *... .+...@.+.@.4.4.5.(.Z A *.=.f.;.>.,.<.).9.L }.0.M M M 0.g.| e / + . ",
		". s ' g g h g | i 1 i ~ h.' } 4 5 6 7 8 W o n 5 C ..@.+.+.@.#.4.4.y y Z _.z D 6.-.;.>.'.<.9.!.[.0.M M }.0.~.i.| e / + . ",
		". V ' f g h g | } | 2 ' j.A ' h 5 6 8 8 W o n j E ` @.@.#.` #.4.y y b.&.A D =.f.k.h.,.<.).9.~.0.M M 0.~.[.[.T | e / + . ",
		". V ' f g h g | i 1 i ' j.j.c.' | 6 8 8 W o n j =.` ` #.#.4.$.5.y b.Z A C E f.-.;.,.J 8.!.L 0.M 0.}.[.~.[.[.S i e / + . ",
		". V ' g f f l.g h } } ' j.m.j.,.n.} 7 8 W o n 4 f.4.5.$.$.5.y (.%.&.A B D :.G H I o.K ).L 0.M 0.[.L !.9.9.!.R i e / + . ",
		". V ' g p.q.' ' ' ) ) ' j.r.m.j.[.s.| 8 W o n j -.y y y (.b.%.Z A A *.D :.-.k.h.,.t.9.[.0.u.}.L L !.9.8.).K Q 1 e / + . ",
		". v.' g ' j.j.j.j.j.j.j.w.r.r.x.y.z.A.} W k n j ;.%.%.%.Z _.&.A B C E 6.G k.h.o.'.8.[.0.u.~.!.).8.K <.t.<.'.P 1 e / + . ",
		". v.' g ' j.r.r.r.r.r.r.r.r.r.r.x.B.Q C.1 p n 3 I &.&.z A z B D.E.F.G.H.I.J.K.'.8.[.M M [.!.).<.<.t.'.J ,.o.O 2 e / + . ",
		". v.' f ' j.r.r.r.r.r.r.r.r.r.r.r.L.M.1.3 3 l 2 J *.*.*.C N.O.P.Q.R.S.T.U.V.W.X.[.M }.L 9.<.'.o.,.7.>.I >.h.N 2 e / + . ",
		". v.' f ' j.r.r.r.r.r.r.r.r.r.r.r.r.L.Y.Z.0 8 i 8.=.=.=.`. +.+++@+#+#+#+@+$+%+&+*+0.!.K <.o.7.I I h.d.H ;.;.u.3 e / + . ",
		". V ' f ' j.r.r.r.r.r.r.r.r.r.r.r.r.r.m.j.=+9 | [.f.f.-.-+;+>+#+,+'+'+'+'+)+!+~+{+]+<.J 7.I h.H H -.c.-.f.f.L j e / + . ",
		". V ' g ' j.r.r.r.r.r.r.r.r.r.r.r.r.L.Y.Z.t 8 } e.;.;.^+/+++#+'+'+'+'+'+'+'+(+_+:+<+J 7.d.;.-.-.F 6.:.=.=.=.K 4 e / + . ",
		". V ' g ' j.r.r.r.r.r.r.r.r.r.r.r.L.M.[+3 3 u } }+h.>.|+1+2+,+'+'+'+'+'+'+'+'+@+3+4+h.d.c.f.6.=.E D C *.*.*.J 5 e / + . ",
		". V ' g ' j.r.r.r.r.r.r.r.r.r.r.x.B.Q C.1 v n h 5+o.,.6+7+8+'+'+'+'+'+'+'+'+'+9+0+a+;.G F =.D D B z A z &.&.I 5 e / + . ",
		". V ' g ' j.j.j.j.j.j.j.w.r.r.x.b+{.A.} W o n g c+'.<.d+e+#+'+'+'+'+'+'+'+'+'+f+>+g+G 6.E C B A &._.Z %.%.%.H 6 e / + . ",
		". V ' g p.q.' ' ' ) ) ' j.r.m.j.}.h+| 9 W o n h i+K ).j+k+8+'+'+'+'+'+'+'+'+'+,+>+l+:.D *.A A Z %.b.(.y y y -.7 e / + . ",
		". s ' f f f l.C.h } } ' j.m.j.o.! h 9 8 W o n h m+!.9.n+o+2+'+'+'+'+'+'+'+'+'+p+++q+D B A &.%.(.y 5.$.$.5.4.F 7 e / + . ",
		". V ' f g h g | i | i ' j.j.c.) h 6 8 8 W k n g r+[.[.s+t+u+(+'+'+'+'+'+'+'+,+8+v+w+C A Z b.y 5.$.4.#.#.` ` E 7 e / + . ",
		". s ' f g h g | i | i ' j.A ' h 7 9 8 8 W k u g i.[.[.x+y+z+!+(+'+'+'+'+'+,+#+A+B+C+A &.b.y y 4.#.` #.@.@.` E 9 e / + . ",
		". V ' f g h g | i 1 i ~ I ' } 4 5 9 9 8 W k u g [+~.0.}.D+E+F+_+@+9+f+,+p+@+G+H+E.z _.Z y y 4.4.#.@.+.+.@...*.9 e / + . ",
		". s ' g g h g | } 1 i g g h 4 4 5 9 8 8 W k u g g.0.M M M I+J+K+L+M+$+$+N+O+P+Q+R+A Z (.5.4.4.@.+.@...+. ...B 8 e / + . ",
		". V ' f g h } | } 1 i 3 2 j 6 6 7 9 7 8 W k u } m+e.M M }.~.S+T+U+V+W+X+Y+Z+`+E B A b.y $.#.#.+.@.+. .../...%. @e / + . ",
		". v.' f g f } | i 1 i 1 j 4 4 4 7 6 7 8 W k u 4 d.a.M }.0.}.L 9.8.K '.7.;.-.6.D z &.(.5.4.` @.@.+. ././. .#..@v e / + . ",
		". v.' f C.h } | | 1 i 1 2 4 5 6 7 6 8 8 W k n t 2.1.|.}.~.[.[.!.).<.J I H G :.C A _.(.$.#.#.+... ./. .^...%.w n e / + . ",
		". v.' g g h g | i 1 i 1 2 4 4 5 7 9 8 8 W o n n 7 ].S {.M ~.!.).K '.,.>.;.-.=.*.&.%.y $.#.@.+.+... . .` Z Y v b e / + . ",
		". V ' g g h g | } 1 i 4 2 4 5 6 7 9 8 8 t p u m l 7 +@;.i+i.r+m+i+c+O N M [.8.J I ;.-.f.=.E D B z B (..@w t n a e / + . ",
		". V ' g g h g h i 1 i 1 2 4 5 4 7 6 8 8 t v l X m n t 4 } g g h h } } | i i 1 2 3 3 j j 4 4 4 5 5 5 7 0 k X m a e / + . ",
		". V ' f g h g | i | 2 3 j 4 5 4 5 9 8 8 0 t k u n X X n n n n n n n n n n u  @8  @u n n n n n n n n n n n n X q { / + . ",
		". V ' g g h g | i 1 i 3 j j 5 4 5 9 9 8  @W v k l k u l l l l l l l l l k 5 o =+k 5 k l l l l l l l l l l l u m d _ + . ",
		". s ' f g h g h i 1 i 1 j j 5 4 7 9 9  @0 0 v v p o k p p p p p p p p p 4 7 @@j.@@6 4 p p p p p p p p p p p k X { ( #@. ",
		". V ' g C.h g | } | i 3 j j 5 4 5 9 8  @8  @0 t t v v v v v v v v v v j i 1.$@x.$@g.i j t v v v v v v v v v v t W 2 = . ",
		". V ' f g h g | i 1 i 3 j 4 5 4 5 6 8  @8 W t v t o v v v v v v v v 4 g i+M.L.r.L.M.Q h 4 v v v v v v v v v v v v j %@. ",
		". s ' f g h g | | 1 i 1 2 3 5 7 7 6 8  @8  @t v t o v v v v v v v 5 C.{.B.L.r.r.r.L.B.O C.5 v v v v v v v v v v v j %@. ",
		". V ' g C.f g | | 1 i 3 j 4 5 4 5 9 8  @8  @0 v t o v v v v v v 6 &@~.b+x.r.r.r.r.r.x.b+0.&@6 v v v v v v v v v v j %@. ",
		". V ' g g h g | i 1 i 3 j 4 5 4 7 9 9  @8  @0 W t o v v v v v 6 q.t.y.x.r.r.r.r.r.r.r.x.y.t.q.6 v v v v v v v v v j %@. ",
		". s ' g C.f g h i 1 i 1 2 4 5 6 7 9 8  @8 W 0 W t o v v v v 7 q.H j.m.r.r.r.r.r.r.r.r.r.m.j.d.q.7 v v v v v v v v j %@. ",
		". V ' g C.f g h } | i 3 j 3 5 6 5 6 8  @8  @t v t o v v v 9 *@D j.m.r.r.r.r.r.r.r.r.r.r.r.m.j.D A.9 v v v v v v v j %@. ",
		". V ' g g h g | } | i 3 j 4 5 6 7 9 7  @8  @t v t o v v v 9 ,.j.j.j.j.=@r.r.r.r.r.r.r.=@j.j.j.j.,.9 v v v v v v v j %@. ",
		". V ' g g h g | i 1 i 3 3 j 5 4 7 9 8  @8  @t v t o v v v 9 g n.' ' ' j.r.r.r.r.r.r.r.j.' ' ' n.g 9 v v v v v v v j %@. ",
		". V ' g g h g h i 1 i 3 3 4 5 4 5 9 8 9 0 W t v t o v v v v v v v W f j.r.r.r.r.r.r.r.j.f W v v v v v v v v v v v j %@. ",
		". V ' g g h g | i 1 i j 2 4 5 4 5 9 8  @8  @0 v t o v v v v v v v W f j.r.r.r.r.r.r.r.j.f W v v v v v v v v v v v j %@. ",
		". V ' g g h } | i 1 i 1 j 3 5 4 5 9 8  @8 W 0 W t o v v v v v v v W f j.r.r.r.r.r.r.r.j.f W v v v v v v v v v v v j %@. ",
		". V ' f g h } | } | i 3 j 4 5 6 7 9 8 9 8 W 0 W t o v v v v v v v W f j.r.r.r.r.r.r.r.j.f W v v v v v v v v v v v j %@. ",
		". # ' f g h g | i | i 3 3 j 5 4 7 9 8  @8 W 0 W t o v v v v v v v W f j.r.r.r.r.r.r.r.j.f W v v v v v v v v v v v j %@. ",
		". # ' g g h } | } 1 i 3 j 4 5 4 5 9 9  @8  @t v t o v v v v v v v t 9 j.j.j.j.j.j.j.j.j.9 t v v v v v v v v v v v j %@. ",
		". # ' g g h g | i 1 i 1 2 4 5 4 5 9 8  @8  @0 v t o v v v v v v v v 2 q.' ' ' ' ' ' ' q.2 v v v v v v v v v v v v j %@. ",
		". # ' g g h g | i 1 i j j 4 5 4 5 6 7  @8  @t v t o v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v j %@. ",
		". @ ' ' ' ~ ~ ! n.-@h+q.*@;@&@&@l.g h } } 2 3 3 j 5 j j j j j j j j j j j j j j j j j j j j j j j j j j j j j j j g - . ",
		". + %@% & & & & * * * * >@>@>@>@>@@ @ @ @ @ %@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@- > . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '1' then
	Image = {
	--XpmImage Here
	};
	end
	return Image
end

function ImageBottom(pic)
	local Image = {
	"60 60 122 2",
	"  	c #ACACAC",
	". 	c #ADADAD",
	"+ 	c #A5A5A5",
	"@ 	c #9E9E9E",
	"# 	c #9D9D9D",
	"$ 	c #9C9C9C",
	"% 	c #F2F2F2",
	"& 	c #FFFFFF",
	"* 	c #B8B8B8",
	"= 	c #B3B3B3",
	"- 	c #F1F1F1",
	"; 	c #F0F0F0",
	"> 	c #FDFDFD",
	", 	c #C5C5C5",
	"' 	c #BDBDBD",
	") 	c #AEAEAE",
	"! 	c #ECECEC",
	"~ 	c #EEEEEE",
	"{ 	c #EFEFEF",
	"] 	c #FBFBFB",
	"^ 	c #C3C3C3",
	"/ 	c #AFAFAF",
	"( 	c #EBEBEB",
	"_ 	c #EDEDED",
	": 	c #FAFAFA",
	"< 	c #C2C2C2",
	"[ 	c #C0C0C0",
	"} 	c #EAEAEA",
	"| 	c #F9F9F9",
	"1 	c #BFBFBF",
	"2 	c #B0B0B0",
	"3 	c #E9E9E9",
	"4 	c #F8F8F8",
	"5 	c #828282",
	"6 	c #393939",
	"7 	c #323232",
	"8 	c #3D3D3D",
	"9 	c #4C4C4C",
	"0 	c #5A5A5A",
	"a 	c #5B5B5B",
	"b 	c #595959",
	"c 	c #5D5D5D",
	"d 	c #4E4E4E",
	"e 	c #343434",
	"f 	c #313131",
	"g 	c #F7F7F7",
	"h 	c #C1C1C1",
	"i 	c #E8E8E8",
	"j 	c #818181",
	"k 	c #5C5C5C",
	"l 	c #F6F6F6",
	"m 	c #E7E7E7",
	"n 	c #E6E6E6",
	"o 	c #7A7A7A",
	"p 	c #383838",
	"q 	c #434343",
	"r 	c #5E5E5E",
	"s 	c #4F4F4F",
	"t 	c #F3F3F3",
	"u 	c #E5E5E5",
	"v 	c #E4E4E4",
	"w 	c #E3E3E3",
	"x 	c #E2E2E2",
	"y 	c #BEBEBE",
	"z 	c #E1E1E1",
	"A 	c #8D8D8D",
	"B 	c #161616",
	"C 	c #E0E0E0",
	"D 	c #969696",
	"E 	c #171717",
	"F 	c #DFDFDF",
	"G 	c #9F9F9F",
	"H 	c #181818",
	"I 	c #DEDEDE",
	"J 	c #A9A9A9",
	"K 	c #1C1C1C",
	"L 	c #1B1B1B",
	"M 	c #A8A8A8",
	"N 	c #DCDCDC",
	"O 	c #DDDDDD",
	"P 	c #1F1F1F",
	"Q 	c #1E1E1E",
	"R 	c #B1B1B1",
	"S 	c #BBBBBB",
	"T 	c #DBDBDB",
	"U 	c #B7B7B7",
	"V 	c #222222",
	"W 	c #B6B6B6",
	"X 	c #BCBCBC",
	"Y 	c #272727",
	"Z 	c #DADADA",
	"` 	c #2C2C2C",
	" .	c #D8D8D8",
	"..	c #D9D9D9",
	"+.	c #C7C7C7",
	"@.	c #C6C6C6",
	"#.	c #CBCBCB",
	"$.	c #B9B9B9",
	"%.	c #D6D6D6",
	"&.	c #D7D7D7",
	"*.	c #CDCDCD",
	"=.	c #3F3F3F",
	"-.	c #C8C8C8",
	";.	c #C9C9C9",
	">.	c #CACACA",
	",.	c #C4C4C4",
	"'.	c #D2D2D2",
	").	c #B4B4B4",
	"!.	c #CCCCCC",
	"~.	c #747474",
	"{.	c #404040",
	"].	c #353535",
	"^.	c #757575",
	"/.	c #CFCFCF",
	"(.	c #999999",
	"_.	c #D0D0D0",
	":.	c #989898",
	"<.	c #B2B2B2",
	"[.	c #CECECE",
	"}.	c #A1A1A1",
	"|.	c #A0A0A0",
	"1.	c #A2A2A2",
	"      .             . . .     . .       .   .     .   . .         . .     .     .         .   . .     .       .         ",
	"    + @ # # # # # # # # # # $ # # $ # # $ # # # # $ $ $ # $ # $ # $ # # # # # # $ $ $ $ # # # # $ # # # # # $ # #   . . ",
	"  % & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & * = ",
	"= - - ; ; ; - - ; ; ; ; ; ; ; ; ; - - ; - ; - ; ; ; - - - ; - - - - ; ; ; ; ; - - - ; ; ; ; - - ; ; - ; ; ; ; - ; > , ' ",
	") ! ; ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ { ~ ~ { ~ ~ ~ ~ ~ ~ { ~ ~ ~ ~ ~ ~ ~ ~ ~ { { ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ] ^ ' ",
	"/ ( ~ _ _ _ _ _ _ _ _ _ _ ~ ~ _ ~ _ _ _ _ _ _ _ _ _ _ ~ _ _ _ _ _ _ _ _ ~ ~ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ : < [ ",
	"/ } ~ _ _ ! _ ! ! _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! ! ! _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ _ _ _ _ _ _ _ ! _ _ _ _ _ | < 1 ",
	"2 3 ! ( ( ( ( ( ( ( ! ( ( ! ! ( ( ( ( ( ! ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ( ( ( ! ( ( ( ( ( ( ! ! ( ( ! ( ( 4 < 1 ",
	"/ 3 ( } } ( } ( } } } } ( ( 5 6 7 8 9 0 a b b b b b b b b b b b b b b b b b b b b 0 c d e f f f } } } } } ( ( } } g h 1 ",
	"/ i } 3 3 3 } } 3 3 3 3 } 3 j 6 7 8 9 0 a b b b b b b b b b b b b b b b b b b b b b k d e f f f 3 3 3 3 3 } } 3 3 l h 1 ",
	"/ m } 3 3 3 3 3 3 3 3 3 3 n o p f f q 0 c 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 a r s e f f f 3 3 3 3 3 3 3 3 3 l h 1 ",
	"2 n m n i m m m i n m m m m i m m i m m i m m i n i i i m m i i n i i m i i i m m i m m m i i m i m m m i i m m m t [ [ ",
	"/ u m n m n n n n m n n n n m n n m n n n n n m m m m n m n n n n n m n n n m n n m n n n n n n n n n n n n n n n % 1 1 ",
	"/ v u u u u u u n u u u u n u u u n u u u u u u u u u u u u u u u u u u u u u u u u u n u u u u u u u u u u u u u % 1 [ ",
	"2 w v v v v v v v v v v v v v v v v v v v v v v v v v v w v v v v v v v v v v v v v v v v v w v v v v v v v v v v ; 1 [ ",
	"/ w v v v v v w v v v v w w w v v x v v v v v v w w w v w v v v w w v v v v v w v v v v w v v v v v v v v w w v v ~ y [ ",
	"2 x w w w w x x w w w x x w x x w x w w x w w x x x x x x w w 5 j w w x x x w w w x x w x x x w w x x w w w x x x ~ y h ",
	"/ z z x z z z z z z z z z x z z z x x z z z z x z z x x z z A B B A x x z z z x z z z z z z x x x z z x x x z x x _ ' h ",
	"/ C C z C C C C C C C C z C C C C C C C C C C C C C C z z D E B B E D C C C C C C z C C C z C C z z C C C C C C C ( ' h ",
	"2 F F F F F F C F F C F F F F F F F F F F F F F F F F F G H B B B B H G F F F F F C F F F F F F F F F F F F F F F } ' h ",
	"/ F F F F F F F F F I F F F F F F F F F F F F F F F I J K B B B B B B L M F F F F I F F F F F F F F F I F F F F F 3 ' h ",
	"2 I N I I I O O O I O I I I O I I I O I I I I I I I 2 P B B B B B B B B Q R I I O I I O I I I I O O O O O O O O I i S h ",
	"2 O T N O N O O O O N N N N O O O N N O O N N N O U V B B B B B B B B B B V W N O O O O O O N N O O N O O O N N O m S < ",
	"/ N T T T T N N N T T T T T N N T T T T T T N N X Y B B B B B B B B B B B B Y X N T T N T N T T T N T N N N T T T n S < ",
	"2 T Z T T T T T T T T T T T T T T T T T T T T < ` B B B B B B B B B B B B B B ` < T T T T T T T T T T T T T T T T v S < ",
	"/ Z  .......Z Z ....Z Z Z Z ..Z Z Z Z Z Z ..+.f B B B B B B B B B B B B B B B B f @.Z Z Z Z .. .....Z Z ..........w S < ",
	"2 Z .... . ..... .........................#.p B B B B B B B B B B B B B B B B B B 6 #.....Z  ........... ..... . .w $.< ",
	"2 ..%.&.&.&.&.%.&. . .%.%.&.&.&.%.%.&.&.*.=.B B B B B B B B B B B B B B B B B B B B =.*.&.&.&.&.&.&. .%.%. .&.%.&.C $.^ ",
	"2 *.-.;.;.>.>.;.>.>.>.>.>.>.>.>.>.>.>.,.q B B B B B B B B B B B B B B B B B B B B B B q ,.>.>.>.>.>.>.;.>.>.>.>.>.'.)., ",
	"2 !., +.-.;.+.+.;.+.+.;.-.+.;.+.;.;.-.~.{.{.{.{.{.].B B B B B B B B B B B B ].{.{.{.{.{.^.-.+.-.-.-.+.+.-.-.-.-.-./.= ,.",
	"R !.@.;.;.-.;.;.-.-.;.;.;.-.-.;.-.-.-.-.;.;.-.;.-.(.B B B B B B B B B B B B (.-.;.-.-.;.;.-.-.;.-.;.;.-.-.;.-.-.;._.= , ",
	"R !., ;.-.-.;.;.-.-.-.-.;.;.-.-.;.;.-.;.;.;.-.;.;.(.B B B B B B B B B B B B (.-.-.;.-.-.-.-.;.;.-.-.;.;.;.-.-.;.;._.= , ",
	"R !., -.-.;.-.;.-.-.-.-.-.;.-.-.;.-.-.;.;.-.-.-.;.(.B B B B B B B B B B B B (.;.;.-.-.-.;.;.;.;.-.;.;.-.-.;.;.;.;._.= ,.",
	"R !.@.-.;.-.;.-.;.;.-.;.-.;.-.;.;.-.;.;.;.-.;.-.;.(.B B B B B B B B B B B B (.;.;.-.;.;.;.-.-.;.;.;.;.-.;.;.;.;.;._.= , ",
	"2 #.,.+.-.+.+.-.+.+.+.+.+.+.+.-.-.+.-.-.+.+.-.+.+.:.B B B B B B B B B B B B :.+.+.+.-.-.+.+.+.+.-.-.+.+.-.+.-.+.+./.<., ",
	"2 #.,.+.+.+.+.+.+.-.+.+.+.+.+.+.+.-.+.+.+.+.-.+.+.:.B B B B B B B B B B B B :.-.-.+.+.+.+.+.+.+.+.+.+.+.+.+.-.-.+./.= , ",
	"R !., +.-.+.+.+.+.+.+.+.-.-.+.-.-.+.-.+.+.+.+.+.+.(.B B B B B B B B B B B B :.+.+.+.+.-.+.+.+.-.+.+.+.-.-.-.+.+.-.[.= , ",
	"R #.,.+.+.+.+.+.-.-.+.+.+.+.+.+.+.+.+.+.-.+.-.+.+.:.B B B B B B B B B B B B :.-.-.+.+.+.+.+.-.+.+.+.+.+.-.+.+.+.+.[.= , ",
	"2 #., +.+.+.+.+.+.+.+.+.+.-.-.+.+.+.+.-.-.-.+.+.+.:.B B B B B B B B B B B B :.-.+.+.+.+.+.+.+.-.-.-.+.+.-.+.+.+.+./.= , ",
	"2 #.,.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.:.B B B B B B B B B B B B :.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.+.[.<., ",
	"2 >.^ @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.*.<.@.",
	"R >.^ @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.*.<., ",
	"2 >.^ @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.*.<., ",
	"2 >.^ @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.*.<., ",
	"R >.^ @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.*.<., ",
	"2 >.^ @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.*.<., ",
	"2 ;.< , , ,., , , , , , , , ,.,.,., , ,., , ,., , , , , , , ,., ,., ,., ,.,., , , ,., , , , ,., , , , , , , , , , !.<., ",
	"R ;.< , , , ,., , , , , , ,., , ,., , , , , , , , ,.,.,., , , , , , , , , , , , ,., ,.,.,.,., ,., , , , , , , , , !.<., ",
	"2 ;.< , , ,., , , , , , , , , , , , , , , , , ,.,., , , ,., , , , , , , , , ,., , , , , , ,.,., , , , , , , , ,., !.R @.",
	"2 ;.< , , , , ,.,., , ,., , , , , , , , , , , ,., , , , , , , , , , , , , , , , , , , , , , , , , ,., , , , , , , #.R @.",
	"2 -.< , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , ,.,., , , , , , , , ,.,., , , , , , , , , , , , !.<., ",
	"R ;.[ ,.,.^ ,.,.,.,.,.^ ,.,.,.,.,.,.,.,.,.,.,.^ ,.,.,.,.,.,.,.,.,., , ^ ,.,.,.,.,.,.,., , ,.,.,.,.,.,.,.,.,.,.^ ,.#.R , ",
	"2 ;.< , , ,., , , , , , , , , , , , , , , , , ,.,., , , ,., , , , , , , , , ,., , , , , , ,.,., , , , , , , , ,., !.<.,.",
	"2 ;.< , , , , ,.,., , ,., , , , , , , , , , , ,., , , , , , , , , , , , , , , , , , , , , , , , , ,., , , , , , , #.<.< ",
	"2 -.< , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , ,.,., , , , , , , , ,.,., , , , , , , , , , , , !.<.X ",
	"2 ;.[ ,.,.^ ,.,.,.,.,.^ ,.,.,.,.,.,.,.,.,.,.,.^ ,.,.,.,.,.,.,.,.,., , ^ ,.,.,.,.,.,.,., , ,.,.,.,.,.,.,.,.,.,.^ ,.#.  = ",
	"2 ;.S [ [ [ [ [ [ 1 [ [ 1 [ [ 1 [ [ 1 [ [ [ 1 [ 1 [ [ [ [ [ [ [ 1 [ [ [ [ [ 1 [ 1 [ [ [ [ [ [ 1 1 1 [ [ 1 [ 1 [ [ ,   ) ",
	"2 ;.z F I I F I I F F F F I I F F I I I F I I F I I I F F I F I I I I F F I I I F I I F F F F I F F I I I F I F F _     ",
	"2   J }.}.}.}.}.}.}.|.}.|.|.|.}.|.}.1.}.}.}.}.}.}.}.}.|.}.|.}.}.}.}.|.|.}.|.}.|.|.}.|.}.}.|.}.}.}.}.}.}.|.|.|.|.}.      ",
	"2 2 2 . .     . .                 .   . . . . .   . .         . .           .                       . .                 "};
	return Image
end

function ImageBottomRight(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 288 2",
		"  	c None",
		". 	c #9F9F9F",
		"+ 	c #9D9D9D",
		"@ 	c #9B9B9B",
		"# 	c #999999",
		"$ 	c #989898",
		"% 	c #969696",
		"& 	c #949494",
		"* 	c #939393",
		"= 	c #979797",
		"- 	c #BBBBBB",
		"; 	c #C0C0C0",
		"> 	c #C5C5C5",
		", 	c #C6C6C6",
		"' 	c #C7C7C7",
		") 	c #E7E7E7",
		"! 	c #E5E5E5",
		"~ 	c #EDEDED",
		"{ 	c #C9C9C9",
		"] 	c #CBCBCB",
		"^ 	c #CACACA",
		"/ 	c #CCCCCC",
		"( 	c #DCDCDC",
		"_ 	c #DADADA",
		": 	c #C3C3C3",
		"< 	c #CECECE",
		"[ 	c #D1D1D1",
		"} 	c #D8D8D8",
		"| 	c #E1E1E1",
		"1 	c #EAEAEA",
		"2 	c #E9E9E9",
		"3 	c #E8E8E8",
		"4 	c #E6E6E6",
		"5 	c #E4E4E4",
		"6 	c #E3E3E3",
		"7 	c #E2E2E2",
		"8 	c #E0E0E0",
		"9 	c #DFDFDF",
		"0 	c #DEDEDE",
		"a 	c #D4D4D4",
		"b 	c #D0D0D0",
		"c 	c #CFCFCF",
		"d 	c #D2D2D2",
		"e 	c #D3D3D3",
		"f 	c #DBDBDB",
		"g 	c #D5D5D5",
		"h 	c #ACACAC",
		"i 	c #545454",
		"j 	c #292929",
		"k 	c #232323",
		"l 	c #252525",
		"m 	c #262626",
		"n 	c #2B2B2B",
		"o 	c #2D2D2D",
		"p 	c #313131",
		"q 	c #343434",
		"r 	c #393939",
		"s 	c #3D3D3D",
		"t 	c #434343",
		"u 	c #484848",
		"v 	c #4C4C4C",
		"w 	c #515151",
		"x 	c #555555",
		"y 	c #585858",
		"z 	c #5B5B5B",
		"A 	c #5F5F5F",
		"B 	c #626262",
		"C 	c #636363",
		"D 	c #696969",
		"E 	c #838383",
		"F 	c #BABABA",
		"G 	c #D7D7D7",
		"H 	c #7F7F7F",
		"I 	c #272727",
		"J 	c #353535",
		"K 	c #3C3C3C",
		"L 	c #3F3F3F",
		"M 	c #414141",
		"N 	c #424242",
		"O 	c #444444",
		"P 	c #4B4B4B",
		"Q 	c #4D4D4D",
		"R 	c #525252",
		"S 	c #5A5A5A",
		"T 	c #5E5E5E",
		"U 	c #666666",
		"V 	c #6C6C6C",
		"W 	c #6F6F6F",
		"X 	c #717171",
		"Y 	c #747474",
		"Z 	c #707070",
		"` 	c #9E9E9E",
		" .	c #D6D6D6",
		"..	c #ADADAD",
		"+.	c #3A3A3A",
		"@.	c #3E3E3E",
		"#.	c #454545",
		"$.	c #464646",
		"%.	c #494949",
		"&.	c #4E4E4E",
		"*.	c #505050",
		"=.	c #6D6D6D",
		"-.	c #727272",
		";.	c #757575",
		">.	c #767676",
		",.	c #686868",
		"'.	c #363636",
		").	c #404040",
		"!.	c #474747",
		"~.	c #4A4A4A",
		"{.	c #646464",
		"].	c #6E6E6E",
		"^.	c #737373",
		"/.	c #777777",
		"(.	c #DDDDDD",
		"_.	c #535353",
		":.	c #575757",
		"<.	c #5D5D5D",
		"[.	c #616161",
		"}.	c #656565",
		"|.	c #6B6B6B",
		"1.	c #4F4F4F",
		"2.	c #5C5C5C",
		"3.	c #606060",
		"4.	c #676767",
		"5.	c #6A6A6A",
		"6.	c #F3F3F3",
		"7.	c #F4F4F4",
		"8.	c #000000",
		"9.	c #FAFAFA",
		"0.	c #FFFFFF",
		"a.	c #F1F1F1",
		"b.	c #111111",
		"c.	c #EFEFEF",
		"d.	c #010101",
		"e.	c #161616",
		"f.	c #EEEEEE",
		"g.	c #595959",
		"h.	c #ECECEC",
		"i.	c #020202",
		"j.	c #121212",
		"k.	c #0A0A0A",
		"l.	c #4E4C49",
		"m.	c #575048",
		"n.	c #5D5144",
		"o.	c #635545",
		"p.	c #67594A",
		"q.	c #675E53",
		"r.	c #65615C",
		"s.	c #666564",
		"t.	c #030303",
		"u.	c #403F3E",
		"v.	c #4A433B",
		"w.	c #544330",
		"x.	c #36587E",
		"y.	c #2265B0",
		"z.	c #166CCD",
		"A.	c #166DCE",
		"B.	c #34679D",
		"C.	c #5F5D5A",
		"D.	c #6A5E51",
		"E.	c #67635F",
		"F.	c #040404",
		"G.	c #131313",
		"H.	c #565656",
		"I.	c #434241",
		"J.	c #42382E",
		"K.	c #413F3C",
		"L.	c #0770E4",
		"M.	c #007CFF",
		"N.	c #0079FF",
		"O.	c #0078FF",
		"P.	c #007AFF",
		"Q.	c #3367A1",
		"R.	c #6B5C4C",
		"S.	c #64615D",
		"T.	c #1A1A1A",
		"U.	c #060606",
		"V.	c #4B443C",
		"W.	c #42403D",
		"X.	c #0081FF",
		"Y.	c #0076FA",
		"Z.	c #0176F8",
		"`.	c #0076FD",
		" +	c #3266A0",
		".+	c #675B4E",
		"++	c #5F5E5D",
		"@+	c #222222",
		"#+	c #4F4C4A",
		"$+	c #554432",
		"%+	c #076FE3",
		"&+	c #5C5853",
		"*+	c #5F5952",
		"=+	c #D9D9D9",
		"-+	c #564F48",
		";+	c #36587D",
		">+	c #156DCE",
		",+	c #605345",
		"'+	c #5D5143",
		")+	c #2264AF",
		"!+	c #0077FC",
		"~+	c #0075FE",
		"{+	c #604D37",
		"]+	c #2C2C2C",
		"^+	c #645544",
		"/+	c #0771E7",
		"(+	c #0076F9",
		"_+	c #007DFF",
		":+	c #5D472F",
		"<+	c #655747",
		"[+	c #156CCC",
		"}+	c #007EFF",
		"|+	c #59442D",
		"1+	c #EBEBEB",
		"2+	c #655C51",
		"3+	c #32649C",
		"4+	c #52412E",
		"5+	c #303030",
		"6+	c #635F5A",
		"7+	c #5D5957",
		"8+	c #007BFF",
		"9+	c #0077FD",
		"0+	c #255993",
		"a+	c #4B4237",
		"b+	c #61605F",
		"c+	c #31639D",
		"d+	c #0670E5",
		"e+	c #4D3B27",
		"f+	c #46423E",
		"g+	c #2A2A2A",
		"h+	c #615E5A",
		"i+	c #2F639B",
		"j+	c #056FE4",
		"k+	c #3F3E3F",
		"l+	c #443D36",
		"m+	c #282828",
		"n+	c #F5F5F5",
		"o+	c #5E5B57",
		"p+	c #605447",
		"q+	c #534F4C",
		"r+	c #136CCC",
		"s+	c #0077FE",
		"t+	c #007FFF",
		"u+	c #0080FF",
		"v+	c #066FE3",
		"w+	c #235791",
		"x+	c #483622",
		"y+	c #423B34",
		"z+	c #585756",
		"A+	c #57524B",
		"B+	c #584B3D",
		"C+	c #58442F",
		"D+	c #564027",
		"E+	c #523D25",
		"F+	c #4D3C2A",
		"G+	c #473E33",
		"H+	c #413E3A",
		"I+	c #848484",
		"J+	c #AEAEAE",
		"K+	c #828282",
		"L+	c #383838",
		"M+	c #333333",
		"N+	c #242424",
		"O+	c #C8C8C8",
		"P+	c #CDCDCD",
		"Q+	c #929292",
		"R+	c #1B1B1B",
		"S+	c #FDFDFD",
		"T+	c #050505",
		"U+	c #909090",
		"V+	c #FBFBFB",
		"W+	c #8F8F8F",
		"X+	c #FEFEFE",
		"Y+	c #F7F7F7",
		"Z+	c #373737",
		"`+	c #F9F9F9",
		" @	c #F0F0F0",
		".@	c #919191",
		"+@	c #8E8E8E",
		"@@	c #F2F2F2",
		"#@	c #090909",
		"$@	c #8D8D8D",
		"%@	c #F8F8F8",
		"&@	c #8C8C8C",
		"*@	c #FCFCFC",
		"=@	c #878787",
		"-@	c #898989",
		";@	c #888888",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ % & * * * * * * * * * * * * * * * * = @ . ",
		". @ - ; > , ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' , > ) ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ~ = . ",
		". # ; > { ] ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ] / ] ( _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ : { / < [ } | ) 1 1 1 2 2 3 3 ) ) 4 ! 5 6 6 7 | | | 8 8 9 0 _ a b c c [ d e f _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ , ] < g | h i j k l m j n o p q r s t u v w x y z A A B C D E F _ a d e g G _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ [ | H I J K L M N N O u P Q R i S T B U D V W X X Y Y Y Z D ` f e a  .} _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ } ..j +.@.@.@.L N N #.$.%.&.*.i S T B U D V =.X -.-.;.>.;.Y ,.F G a  .} _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 8 x '.).).@.@.).M M #.!.~.v w x y T B {.D V ].Z -.^.^.Y >./.X E (.a  .} _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ ) o @.M L ).@.@.L N O #.%.P *._.:.<.[.}.,.|.].Z Z ^.Y ;.>.;.;.|.| a  .} _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 2 m M N ).M L @.@.).t O u ~.1.R y 2.3.{.4.5.=.W X -.-.^.;.>.;.C 6 a  .} _ _ _ _ _ _ 8 8 8 _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 2 j O N t M ).L @.L N t !.%.&.w x z A C U D V ].Z Z ^.-.^.;.Y {.6 a  .} _ _ _ _ _ | 6.&.~ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 2 n $.O #.O t N L @.L t $.%.Q w x y T 3.}.,.|.=.W W -.^.-.Y ^.C 6 a  .} _ _ _ _ 7 7.3.8.9._ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 3 o u $.!.$.#.O M L @.).O $.P 1.R y 2.3.C }.D V V W W Z -.^.^.3.5 a  .} _ _ _ 7 7._.8.8.0._ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 3 p P %.u !.$.#.#.t L s M O %.Q w i S T [.}.U 5.V V W Z X Z -.A 5 a  .} _ _ 6 a.~.8.b.8.0.( ( ( ( ( f _ _ ! * . ",
		". $ > ^ ) q &.v P v %.%.$.O t L s N #.%.1._.:.z A B }.,.5.V =.].W Z Z T 5 a  .} f 5 c.L d.b.e.8.0.f.f.f.f.f.8 ) _ ! * . ",
		". $ > ^ 4 r *.w 1.&.&.P %.!.$.N L @.t u v 1._.g.2.3.C }.U ,.|.V =.].].S ! a  .} ! h.q i.j.e.e.k.8.8.8.8.8.8.8.7._ ! * . ",
		". $ > ^ 4 @.i x i _.R *.&.v u #.N @.).O %.l.m.n.o.p.q.r.s.4.,.5.|.|.V y ! a G 5 2 o t.j.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ ! t y g.y :.i i R &.Q ~.!.N @.u.v.w.x.y.z.A.B.C.D.E.}.}.U 4.D i 4 g 6 7 k F.G.e.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ 5 u T <.2.z S y H.i w &.P !.I.J.K.L.M.N.O.O.O.P.Q.R.S.C {.}.U w 4 0 G T.U.G.e.e.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ 6 v B [.3.A T 2.S y x R Q P V.W.X.N.Y.Z.Z.Z.Z.`.N. +.+++3.[.B v ) 9 @+8.j.e.e.e.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ 6 w U }.{.C B 3.T S g.H.R #+$+%+N.Z.Z.Z.Z.Z.Z.Z.`.P.&+*+2.<.T !.3 0 =+T.U.G.e.e.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ 7 x D 4.U }.}.{.3.A <.y H.-+;+M.Y.Z.Z.Z.Z.Z.Z.Z.Z.O.>+,+y g.y N 2 g 6 | I F.G.e.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ | g.V |.|.5.,.4.}.[.3.<.g.'+)+N.Z.Z.Z.Z.Z.Z.Z.Z.Z.!+~+{+i x i @.2 a G 5 2 ]+t.j.e.e.e.e.e.e.e.e.e.e.8.0._ ! * . ",
		". $ > ^ | z ].].=.V |.,.U }.C 3.2.^+/+O.Z.Z.Z.Z.Z.Z.Z.Z.Z.(+_+:+1.w *.r 1 a  .} ! ~ '.i.j.e.e.k.8.8.8.8.8.8.8.7._ ! * . ",
		". $ > ^ | A Z Z W ].=.V 5.,.}.B A <+[+O.Z.Z.Z.Z.Z.Z.Z.Z.Z.Y.}+|+P v &.q 1+a  .} _ 5 c.M d.b.e.8.0.f.f.f.f.f.8 ) _ ! * . ",
		". $ > ^ 8 3.-.Z X Z W V V 5.U }.[.2+3+N.Z.Z.Z.Z.Z.Z.Z.Z.Z.O.%+4+u %.P 5+1+a  .} _ _ 6 a.~.8.b.8.0.( ( ( ( ( f _ _ ! * . ",
		". $ > ^ 8 [.^.^.-.Z W W V V D }.C 6+7+8+9+Z.Z.Z.Z.Z.Z.Z.Y.M.0+a+!.$.u ]+h.a  .} _ _ _ 7 7.x 8.8.0._ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 8 C ^.Y -.^.-.W W =.|.,.}.b+.+c+P.9+Z.Z.Z.Z.Z.Y.P.d+e+f+#.O $.g+h.a  .} _ _ _ _ 7 7.3.8.9._ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 8 }.Y ;.^.-.^.Z Z ].V D U C h+<+i+M.N.9+(+Y.O._+j+k+l+M t N O m+~ a  .} _ _ _ _ _ | n+&.~ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ 9 {.;.>.;.^.-.-.X W =.5.4.{.3.o+p+q+r+s+t+u+v+w+x+y+u.M ).N M l ~ a  .} _ _ _ _ _ _ 8 8 8 _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ (.V ;.;.>.;.Y ^.Z Z ].|.,.}.[.<.z+A+B+C+D+E+F+G+H+@.@.).L M @.]+1+a  .} _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ =+I+X /.>.Y ^.^.-.Z ].V D {.B T y x w v ~.!.#.M M ).@.@.).).'.i 5 a  .} _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ a F ,.Y ;.>.;.-.-.X =.V D U B T S i *.&.%.$.#.N N L @.@.@.+.j J+f e g G _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ! * . ",
		". $ > ^ c _ ` ,.W Y Y Y X X W V D U B T S i R Q P u O N N M L K J I H | a e G =+_ =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+6 * . ",
		". $ ' ] c a f - K+,.B [.A T S y i w v !.N K L+M+5+]+g+m+l N+k g+_.h |  .d a  .} f f f f f f f f f f f f f f f f f ! * . ",
		". = O+/ b d e G (.| 6 6 ! ! 5 ! ! 4 ) 2 1 1+1+h.~ h.h.~ ~ ~ ~ 1+5 f a d e g G _ f _ _ _ ( ( _ _ _ _ _ ( ( ( _ _ _ 4 * . ",
		". = { P+d g a a g g a a a a a a a a  .9 8 9 g a a a a a g g g g g a a g  .G _ _ (.f f (.(.(.f f f f (.(.(.(.f (.f 4 * . ",
		". = ] b  .} =+G G G G =+=+=+=+=+G } 4 (.@+f 4 _ =+=+=+G G G G G G G =+} _ f ( (.0 ( 0 0 0 ( 0 0 0 ( 0 ( ( ( 0 0 0 ) Q+. ",
		". & ] c G f ( ( ( ( ( ( ( ( ( ( ( 3 4 R+8.R+4 3 ( ( ( ( ( ( ( ( ( ( ( f f (.0 (.9 9 9 9 9 9 9 9 9 (.9 9 9 9 9 9 9 1+Q+. ",
		". Q+S+8 8 9 9 9 9 9 9 9 9 9 9 9 1+c.I T+b.T+N+c.1+8 9 9 9 9 9 9 9 9 9 9 9 9 9 0 0 0 0 0 0 0 0 0 0 8 0 0 8 0 0 0 0 1+Q+. ",
		". U+V+(.9 9 9 9 9 9 | | 9 9 | 1 6.o F.G.e.G.F.o 6.1 8 9 9 8 9 | | 9 9 9 9 9 8 8 9 9 9 9 8 9 9 | 9 9 9 9 9 9 8 9 | h.Q+. ",
		". W+X+8 7 8 7 7 7 8 8 7 7 7 1+Y+Z+t.G.e.e.e.G.t.'.`+h.7 8 8 8 8 7 7 8 8 7 8 8 8 8 7 7 8 8 8 7 8 8 8 8 8 8 8 8 8 7 ~ Q+. ",
		". W+0.9 | | 6 6 6 | | 6 6 1 9.N d.j.e.e.e.e.e.j.i.).V+h.| 6 6 | | | | | | 6 6 | 6 6 | 6 | | 6 | | 6 6 6 | | 6 6 6  @.@. ",
		". W+0.7 5 7 7 5 5 5 5 5 h.0.&.8.j.e.e.e.e.e.e.e.j.8.Q X+h.5 5 7 5 7 6 7 5 5 5 5 5 5 | 5 5 7 7 7 5 5 5 5 7 5 5 5 5 a..@. ",
		". W+0.| 6 6 6 6 6 6 6 1+0.:.8.b.e.e.e.e.e.e.e.e.e.b.8.:.0.1+5 7 5 6 5 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 a..@. ",
		". +@0.7 ! ! ! ! ! ! h.0.}.8.b.e.e.e.e.e.e.e.e.e.e.e.b.8.}.0.h.! 5 5 5 5 5 5 ! ! ! 5 4 5 5 5 4 5 ! 5 5 4 5 ! 5 5 5 @@.@. ",
		". +@0.6 4 ! ! ! ! 4 ~ R 8.8.8.8.#@e.e.e.e.e.e.e.#@8.8.8.8.w ~ ) ! ) ) ) ) ! ! ! ! ! ) ! ! ) ! ! 4 4 ) ! ! 4 ! ) ! n+.@. ",
		". +@0.5 4 4 3 3 4 4 ~ S+0.0.0.0.8.e.e.e.e.e.e.e.8.0.0.0.0.S+~ 4 3 3 3 5 3 4 4 3 4 4 3 4 4 3 4 4 4 4 ! 3 4 4 4 3 ! 7.U+. ",
		". +@0.4 2 2 2 2 2 2 2 2 ) 2 1+X+8.e.e.e.e.e.e.e.8.X+1+2 2 2 2 2 2 2 2 2 2 ) 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 `+U+. ",
		". $@0.4 3 1 1 3 3 3 3 3 1 3 1+X+8.e.e.e.e.e.e.e.8.X+1+1 1 3 3 3 3 3 3 3 3 1 3 3 1 3 3 3 3 3 1 1 3 3 3 3 1 1 3 3 3 %@U+. ",
		". $@0.) 2 1+1+2 2 2 2 2 1+2 h.0.8.e.e.e.e.e.e.e.8.0.h.2 2 2 1+1+2 1 2 1+2 2 2 2 1+2 1 1 2 2 1+1+2 2 2 2 1+2 1+2 2 9.U+. ",
		". $@0.3 1 h.1 1 h.h.1 1 1 1 ~ 0.8.e.e.e.e.e.e.e.8.0.c.1 1 1 1 1 1 1 1 1 h.1 1 h.1 1 1 1 1 h.h.1 1 h.1 1 1 1 1 1 1 V+W+. ",
		". $@0.1 ~ ~ ~ ~ 1+~ ~ ~ ~ ~  @0.8.e.e.e.e.e.e.e.8.0. @~ ~ ~ ~ 1+1+1+~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 1+1+~ 1+~ ~ S+W+. ",
		". $@0.1 h.h.h.h.h.h.h.h.h.h.f.7.8.8.8.8.8.8.8.8.8.7.f.h.h.h.h.h.f.h.h.h.h.h.h.h.h.h.h.f.h.f.f.h.h.h.h.h.h.h.h.h.h.S+W+. ",
		". &@0.1+~ ~ ~ ~ ~ ~ ~ ~ ~ ~ f.*@0.0.0.0.0.0.0.0.0.*@f.~ ~ ~ ~ ~ ~ c.~ ~ ~ ~ ~ ~ c.~ ~ c.~ c.c.~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 0.W+. ",
		". &@0.1+f.~ ~ ~ ~ f.~ ~ f.f.~ ~ ~ ~ f.f.f.~ ~ ~ ~ ~ f.f.f.f.~ f.f.f.~ ~ ~ f.~ f.~ f.f.~ ~ ~ ~ ~ ~ ~ ~ ~ f.f.~ ~ ~ 0.+@. ",
		". Q+0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.* . ",
		". $ Q+&@&@=@-@-@-@-@-@=@-@-@-@-@;@;@;@;@-@-@-@-@-@-@=@-@=@-@=@-@;@;@;@-@-@-@-@=@-@-@=@-@-@=@-@-@-@-@-@-@-@&@&@&@&@Q+$ . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '1' then
		Image = {
		--XpmImage Here
		};
	end
	return Image
end

function ImageMeasureAngle(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 209 2",
		"  	c #9F9F9F",
		". 	c #9D9D9D",
		"+ 	c #9C9C9C",
		"@ 	c #FFFFFF",
		"# 	c #F1F1F1",
		"$ 	c #F0F0F0",
		"% 	c #FDFDFD",
		"& 	c #EEEEEE",
		"* 	c #EFEFEF",
		"= 	c #FBFBFB",
		"- 	c #EDEDED",
		"; 	c #EAEAEA",
		"> 	c #E8E8E8",
		", 	c #EBEBEB",
		"' 	c #FAFAFA",
		") 	c #ECECEC",
		"! 	c #E9E9E9",
		"~ 	c #828282",
		"{ 	c #383838",
		"] 	c #E5E5E5",
		"^ 	c #525252",
		"/ 	c #8D8D8D",
		"( 	c #F9F9F9",
		"_ 	c #E4E4E4",
		": 	c #3E3E3E",
		"< 	c #030303",
		"[ 	c #AFAFAF",
		"} 	c #D1D1D1",
		"| 	c #050505",
		"1 	c #393939",
		"2 	c #F8F8F8",
		"3 	c #797979",
		"4 	c #8E8E8E",
		"5 	c #060606",
		"6 	c #5F5F5F",
		"7 	c #7E7E7E",
		"8 	c #909090",
		"9 	c #F7F7F7",
		"0 	c #161616",
		"a 	c #6E6E6E",
		"b 	c #121212",
		"c 	c #181818",
		"d 	c #DCDCDC",
		"e 	c #2C2C2C",
		"f 	c #0E0E0E",
		"g 	c #DFDFDF",
		"h 	c #E7E7E7",
		"i 	c #F6F6F6",
		"j 	c #656565",
		"k 	c #E3E3E3",
		"l 	c #DEDEDE",
		"m 	c #545454",
		"n 	c #BDBDBD",
		"o 	c #0D0D0D",
		"p 	c #E6E6E6",
		"q 	c #5C5C5C",
		"r 	c #E2E2E2",
		"s 	c #E1E1E1",
		"t 	c #DDDDDD",
		"u 	c #D7D7D7",
		"v 	c #9E9E9E",
		"w 	c #555555",
		"x 	c #6D6D6D",
		"y 	c #111111",
		"z 	c #A5A5A5",
		"A 	c #F3F3F3",
		"B 	c #D8D8D8",
		"C 	c #D9D9D9",
		"D 	c #535353",
		"E 	c #E0E0E0",
		"F 	c #D5D5D5",
		"G 	c #252525",
		"H 	c #1D1D1D",
		"I 	c #282828",
		"J 	c #242424",
		"K 	c #D2D2D2",
		"L 	c #F2F2F2",
		"M 	c #4B4B4B",
		"N 	c #DBDBDB",
		"O 	c #DADADA",
		"P 	c #CBCBCB",
		"Q 	c #D0D0D0",
		"R 	c #696969",
		"S 	c #1A1A1A",
		"T 	c #8F8F8F",
		"U 	c #A9A9A9",
		"V 	c #1B1B1B",
		"W 	c #D3D3D3",
		"X 	c #434343",
		"Y 	c #D6D6D6",
		"Z 	c #C8C8C8",
		"` 	c #ACACAC",
		" .	c #1F1F1F",
		"..	c #4D4D4D",
		"+.	c #626262",
		"@.	c #B6B6B6",
		"#.	c #CDCDCD",
		"$.	c #C9C9C9",
		"%.	c #C3C3C3",
		"&.	c #3B3B3B",
		"*.	c #2A2A2A",
		"=.	c #C4C4C4",
		"-.	c #363636",
		";.	c #D4D4D4",
		">.	c #CACACA",
		",.	c #7C7C7C",
		"'.	c #272727",
		").	c #858585",
		"!.	c #989898",
		"~.	c #B7B7B7",
		"{.	c #2B2B2B",
		"].	c #494949",
		"^.	c #585858",
		"/.	c #C5C5C5",
		"(.	c #CFCFCF",
		"_.	c #C6C6C6",
		":.	c #C0C0C0",
		"<.	c #505050",
		"[.	c #2D2D2D",
		"}.	c #B4B4B4",
		"|.	c #2E2E2E",
		"1.	c #C1C1C1",
		"2.	c #C7C7C7",
		"3.	c #CECECE",
		"4.	c #8B8B8B",
		"5.	c #2F2F2F",
		"6.	c #898989",
		"7.	c #919191",
		"8.	c #414141",
		"9.	c #333333",
		"0.	c #4C4C4C",
		"a.	c #343434",
		"b.	c #BFBFBF",
		"c.	c #474747",
		"d.	c #BBBBBB",
		"e.	c #C2C2C2",
		"f.	c #5B5B5B",
		"g.	c #303030",
		"h.	c #A2A2A2",
		"i.	c #B1B1B1",
		"j.	c #616161",
		"k.	c #CCCCCC",
		"l.	c #B9B9B9",
		"m.	c #BABABA",
		"n.	c #313131",
		"o.	c #6A6A6A",
		"p.	c #767676",
		"q.	c #999999",
		"r.	c #646464",
		"s.	c #9B9B9B",
		"t.	c #636363",
		"u.	c #BCBCBC",
		"v.	c #B5B5B5",
		"w.	c #969696",
		"x.	c #6C6C6C",
		"y.	c #B2B2B2",
		"z.	c #3F3F3F",
		"A.	c #B3B3B3",
		"B.	c #4F4F4F",
		"C.	c #717171",
		"D.	c #A6A6A6",
		"E.	c #B8B8B8",
		"F.	c #424242",
		"G.	c #464646",
		"H.	c #292929",
		"I.	c #262626",
		"J.	c #676767",
		"K.	c #A3A3A3",
		"L.	c #8A8A8A",
		"M.	c #212121",
		"N.	c #4E4E4E",
		"O.	c #8C8C8C",
		"P.	c #878787",
		"Q.	c #565656",
		"R.	c #ADADAD",
		"S.	c #AEAEAE",
		"T.	c #ABABAB",
		"U.	c #454545",
		"V.	c #191919",
		"W.	c #9A9A9A",
		"X.	c #AAAAAA",
		"Y.	c #3A3A3A",
		"Z.	c #151515",
		"`.	c #6F6F6F",
		" +	c #959595",
		".+	c #929292",
		"++	c #131313",
		"@+	c #A8A8A8",
		"#+	c #B0B0B0",
		"$+	c #0F0F0F",
		"%+	c #101010",
		"&+	c #5E5E5E",
		"*+	c #202020",
		"=+	c #222222",
		"-+	c #7A7A7A",
		";+	c #0C0C0C",
		">+	c #BEBEBE",
		",+	c #444444",
		"'+	c #0A0A0A",
		")+	c #070707",
		"!+	c #3C3C3C",
		"~+	c #A7A7A7",
		"{+	c #757575",
		"]+	c #A1A1A1",
		"^+	c #232323",
		"/+	c #848484",
		"(+	c #020202",
		"_+	c #A0A0A0",
		":+	c #939393",
		"                                                                                                                        ",
		"              . . . . . . . + . . + . . + . . . . + + + . + . + . + . . . . . . + + + + . . . . + . . . . . +           ",
		"    @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @     ",
		"    # $ $ $ # # $ $ $ $ $ $ $ $ $ # # $ # $ # $ $ $ # # # $ # # # # $ $ $ $ $ # # # $ $ $ $ # # $ $ # $ $ $ $ # $ %     ",
		"    $ & & & & & & & & & & * * & * & & * & & & & & & * & & & & & & & & & * * & & & & & & & & & & & & & & & & & & & =     ",
		"    & - - - - - - - - - - & & - & - - - - - - - ; > , & - - - - - - - - & & - - & $ * - - - - - - - - - - - - - - '     ",
		"    & - - ) - ) ) - - - - - - - - - - - - - - ! ~ { ] ) ) - - - - - - - - - ) - $ ^ / * - - - - - - - ) - - - - - (     ",
		"    ) , , , , , , , ) , , ) ) , , , , , ) , , _ : < [ ; , , , , , ) , , , , , ) } | 1 $ , , , , , , ) ) , , ) , , 2     ",
		"    , ; ; , ; , ; ; ; ; 3 , ; ; ; ; ; , ; ; ; ] 4 5 6 ] , , ; ; ; ; ; ; ; ; ; , 7 5 8 ) ; ; ; , ; ; ; ; ; , , ; ; 9     ",
		"    ; ! ! ! ; ; ! ! ! ! 0 a > ! ! ! ! ; ! > > ] } b c d > ! ! ; ; ! ! ; ! ! > ) e f g h > > ! ; ! ! ! ! ! ; ; ! ! i     ",
		"    ; ! ! ! ! ! ! ! ! ! 0 0 j h ! ! ! ! ! h _ k l m f   _ > ! ! ! ! ! ! ! > > n o m ; _ ] h ! > ! ! ! ! ! ! ! ! ! i     ",
		"    h p > h h h > p h h 0 0 0 q r > h h h _ s t u v b w g ] > > p > > h > h h x y z g d s ] h h > h h h > > h h h A     ",
		"    h p h B B B B C B B 0 0 0 0 D E p p ] r t u } F G H } k ] p p p h p p k _ I J ] K u t r ] p p p p p p p p p p L     ",
		"    ] ] ] 0 0 0 0 0 0 0 0 0 0 0 0 M N ] _ s O K P Q R S T g _ ] ] ] ] ] _ r U V x d P W O s _ ] ] ] ] ] ] ] ] ] ] L     ",
		"    _ _ _ 0 0 0 0 0 0 0 0 0 0 0 0 0 X Y k E C Q Z Z `  ...O r _ _ _ _ _ r s +. .@.#.Z Q C E r _ _ _ _ _ _ _ _ _ _ $     ",
		"    k _ _ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 : Q E N K $.%.K &.J %.g k k k _ k s B *.&._ =.$.K O E k _ _ _ _ _ _ k k _ _ &     ",
		"    r k k 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -.P N ;.>.=.>.,.'.).N s k k k s l !.'.~ W %.>.;.N g r k k r r k k k r r r &     ",
		"    s s s 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 M t Y #.=.%.~.{.].Y l r r r E d ^.*.=./.=.#.Y d g r r r s s r r r s r r -     ",
		"    s E E 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -.$.t u (._.:.P <.[.}.N g E g t _.|.^ B 1.2.(.u t E E E s s E E E E E E E ,     ",
		"    g g g 0 0 0 0 0 0 0 0 0 0 0 0 0 0 &.3.g t C } 2.1.=.4.5.3 Y t g l C 6.5.7.P 1.Z } B t g g g g g g g g g g g g ;     ",
		"    d d d 0 0 0 0 0 0 0 0 0 0 0 0 0 8.(.d d N B K Z :.n n 9.8.#.C N C ;.0.a.$.b.:.Z } B N d d d d d d d d d N B K Z     ",
		"    B B B 0 0 0 0 0 0 0 0 0 0 0 0 c.(.C C C B Y } $.:.d.e.f.g.h.K u F i.g.j.k.d.:.$.Q F B C C C C B B B B C B Y Q _.    ",
		"    F F F Z Z Z Z Z Z Z 0 0 0 0 ..3.F F F F F W (.$.b.l.m.8 n.o.P K #.p.n.q.b.l.b.$.(.W F F F F F F F F F F F K #.=.    ",
		"    K K K K K K K W W W 0 0 0 m (.W W W K K W K (.$.1.l.}.m.{ { b.#./.: { _.@.l.1.Z 3.} K K W W K K K K K K K Q k.%.    ",
		"    } } } } } } } } } } 0 0 f.(.} } } } } } } } (.>.e.m.}.m.r.g.7.2.s.g.o.1.}.m.e.>.(.} } } } } } } } } } } } (.P e.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 t.(.Q Q Q Q Q Q Q Q Q 3.P /.u.}.v.w.5.f.e.r.5.v ~.}.u./.P 3.Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q x.(.Q Q Q Q Q Q Q Q Q Q (.#.2.b.~.y.m.&.n.[ a.z.%.A.~.b.2.#.(.Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.e.l.A.@.x.[.B.[.C.d.}.m.e.>.3.Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.P /.n v.A.v e {.e D.v.v.n /.P 3.Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q (.#.Z :.~.y.E.F.{.G.d.y.E.:.Z #.(.Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.%.m.}.}.R H.o.~.}.m.%.>.3.Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q (.P /.n v.v.F.'.z.m.v.n /.k.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q (.#.Z 1.~.s.I.I.I.. l.1.Z #.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.%.@.J.J c.G j m.=.>.3.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q x Q Q Q Q Q Q Q Q Q Q Q Q Q Q (.k._.[ 9.I K.G g.~._.k.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 t.(.Q Q Q Q Q Q Q Q Q Q Q Q (.#.1.L.M.w i.N.M.O.=.#.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 0 f.3.Q Q Q Q Q Q Q Q Q Q Q Q 3.~.w  .P.[ ~  .Q.n 3.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 0 0 m k.Q Q Q Q Q Q Q Q Q Q (.k.z G {.R.` R.G J [ k.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q =.=.=.=.=.=.=.0 0 0 0 ..$.Q Q Q Q Q Q Q Q Q (.:.3 V q S.T.[ Q.V 7 =.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 U.2.Q Q Q Q Q Q Q Q 3.i.X V.T ` T.R.6.V.U.m.3.Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 z.=.Q Q Q Q Q Q (.$.W.V.5.T.T.X.T.S.I S D.P (.Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 0 Y.:.Q Q Q Q Q (.m.J.0 t.` ` T.` [ q Z.`.1.(.Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9.n Q Q Q Q 3.X.n.Z. +[ S.[ S.[ .+++a.~.3.Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 G.Q Q Q (._.4.y -.@+#+i.A.i.#+R.[.y !.$.(.Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9.u.Q Q Q 3.}.w $+R ` A.v.~.v.y.[ r.%+&+n 3.Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 0 { :.Q Q Q Q 3.. *+b q.i.v.m.u.l.}.i.q.$+=+S.3.Q Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 0 z.=.Q Q Q Q (.1.-+;+: D.A.E.>+1.>+E.y.` a.;+L._.(.Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q 0 0 0 0 0 0 0 0 0 0 0 0 U.2.Q Q Q Q Q 3.S.,+'+C.` }.u.e./.e.d.}.S.x.'+..m.3.Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q =.=.=.=.=.=.=.0 0 0 0 0.$.Q Q Q Q Q Q #.w.y Z.W.y.~.b._.Z /.>+@.i.  f 0 U #.Q Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 0 0 D k.Q Q Q Q Q Q (.d.o.)+G.z }.l.e.$.P $.1.E.A.T.!+)+3 e.(.Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 0 f.3.Q Q Q Q Q Q Q 3.~+9.5 -+R.v.n /.P #.>./.u.}.S.{+| : @.3.Q Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q 0 t.(.Q Q Q Q Q Q Q (.$.4 )+S v y.~.:.2.#.3.k.2.b.~.y.h.%+'+]+P (.Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q x.(.Q Q Q Q Q Q Q Q (.~.f.< N.D.}.m.%.>.3.(.3.>.e.l.A.X.U.< o.b.(.Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q 3.K.^+< /+[ v.n /.P (.Q 3.P /.n }.S.7 (+[.i.3.Q Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q Q (.#.}.^.9.]+A.E.1.Z #.(.Q (.#.2.:.~.y.h.I &+m.#.(.Q Q Q Q Q Q Q Q Q 3.>.1.    ",
		"    3.3.3.3.3.3.3.3.3.3.3.3.3.3.3.3.3.3.3.k.$.%.T._+U y.l.1.Z k.3.3.3.k.Z :.E.y.T.D.i.%.$.#.3.3.3.3.3.3.3.3.3.k.Z b.    ",
		"    >.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.>.Z =.n v.S.R.i.l.1._.$.>.>.>.$./.:.E.#+R.S.v.n =.Z >.>.>.>.>.>.>.>.>.Z =.u.    ",
		"    e.e.e.e.e.e.e.e.e.e.e.e.e.e.e.e.e.e.1.b.m.A.T.~+~+` }.d.:.1.e.e.e.1.b.m.A.T.D.D.T.A.m.b.1.e.e.e.e.e.e.e.1.:.u.@.    ",
		"                                        v + !.7.O.6.4.8 w.s.v           v s. +T L.6.O.7.!.+ v                           ",
		"                                        v + !..+/ O.4 :+!.+ v           v + !..+O.4./ .+!.+ v                           "};
	elseif pic == '1' then
		Image = {
		"60 60 218 2",
		"  	c #9F9F9F",
		". 	c #9D9D9D",
		"+ 	c #9C9C9C",
		"@ 	c #FFFFFF",
		"# 	c #F1F1F1",
		"$ 	c #F0F0F0",
		"% 	c #FDFDFD",
		"& 	c #EEEEEE",
		"* 	c #EFEFEF",
		"= 	c #FBFBFB",
		"- 	c #EDEDED",
		"; 	c #EBEBEB",
		"> 	c #E8E8E8",
		", 	c #FAFAFA",
		"' 	c #ECECEC",
		") 	c #E9E9E9",
		"! 	c #838383",
		"~ 	c #383838",
		"{ 	c #E5E5E5",
		"] 	c #515151",
		"^ 	c #8D8D8D",
		"/ 	c #F9F9F9",
		"( 	c #E3E3E3",
		"_ 	c #3D3D3D",
		": 	c #040404",
		"< 	c #AFAFAF",
		"[ 	c #EAEAEA",
		"} 	c #D1D1D1",
		"| 	c #393939",
		"1 	c #F8F8F8",
		"2 	c #060606",
		"3 	c #5F5F5F",
		"4 	c #E6E6E6",
		"5 	c #7E7E7E",
		"6 	c #909090",
		"7 	c #787878",
		"8 	c #F7F7F7",
		"9 	c #E7E7E7",
		"0 	c #111111",
		"a 	c #191919",
		"b 	c #DDDDDD",
		"c 	c #2C2C2C",
		"d 	c #0F0F0F",
		"e 	c #DFDFDF",
		"f 	c #6E6E6E",
		"g 	c #161616",
		"h 	c #F6F6F6",
		"i 	c #DEDEDE",
		"j 	c #545454",
		"k 	c #0D0D0D",
		"l 	c #E4E4E4",
		"m 	c #BDBDBD",
		"n 	c #646464",
		"o 	c #E2E2E2",
		"p 	c #DCDCDC",
		"q 	c #D8D8D8",
		"r 	c #9E9E9E",
		"s 	c #121212",
		"t 	c #E0E0E0",
		"u 	c #6D6D6D",
		"v 	c #A5A5A5",
		"w 	c #5B5B5B",
		"x 	c #F3F3F3",
		"y 	c #D6D6D6",
		"z 	c #D0D0D0",
		"A 	c #D5D5D5",
		"B 	c #252525",
		"C 	c #1C1C1C",
		"D 	c #282828",
		"E 	c #242424",
		"F 	c #D3D3D3",
		"G 	c #D7D7D7",
		"H 	c #525252",
		"I 	c #F2F2F2",
		"J 	c #DADADA",
		"K 	c #D2D2D2",
		"L 	c #CBCBCB",
		"M 	c #6A6A6A",
		"N 	c #1B1B1B",
		"O 	c #8F8F8F",
		"P 	c #A9A9A9",
		"Q 	c #1A1A1A",
		"R 	c #E1E1E1",
		"S 	c #4A4A4A",
		"T 	c #D9D9D9",
		"U 	c #C8C8C8",
		"V 	c #ACACAC",
		"W 	c #1F1F1F",
		"X 	c #4D4D4D",
		"Y 	c #626262",
		"Z 	c #B6B6B6",
		"` 	c #CDCDCD",
		" .	c #434343",
		"..	c #DBDBDB",
		"+.	c #C9C9C9",
		"@.	c #C3C3C3",
		"#.	c #3B3B3B",
		"$.	c #2B2B2B",
		"%.	c #3C3C3C",
		"&.	c #D4D4D4",
		"*.	c #CACACA",
		"=.	c #C4C4C4",
		"-.	c #7C7C7C",
		";.	c #272727",
		">.	c #858585",
		",.	c #999999",
		"'.	c #818181",
		").	c #363636",
		"!.	c #B7B7B7",
		"~.	c #494949",
		"{.	c #585858",
		"].	c #2A2A2A",
		"^.	c #C6C6C6",
		"/.	c #C5C5C5",
		"(.	c #CECECE",
		"_.	c #CFCFCF",
		":.	c #C0C0C0",
		"<.	c #505050",
		"[.	c #2D2D2D",
		"}.	c #B4B4B4",
		"|.	c #C7C7C7",
		"1.	c #2E2E2E",
		"2.	c #C1C1C1",
		"3.	c #8B8B8B",
		"4.	c #303030",
		"5.	c #797979",
		"6.	c #898989",
		"7.	c #929292",
		"8.	c #333333",
		"9.	c #424242",
		"0.	c #BFBFBF",
		"a.	c #414141",
		"b.	c #BBBBBB",
		"c.	c #5C5C5C",
		"d.	c #313131",
		"e.	c #A3A3A3",
		"f.	c #B1B1B1",
		"g.	c #606060",
		"h.	c #BABABA",
		"i.	c #484848",
		"j.	c #B9B9B9",
		"k.	c #767676",
		"l.	c #4E4E4E",
		"m.	c #3E3E3E",
		"n.	c #B5B5B5",
		"o.	c #B8B8B8",
		"p.	c #555555",
		"q.	c #CCCCCC",
		"r.	c #C2C2C2",
		"s.	c #2F2F2F",
		"t.	c #9B9B9B",
		"u.	c #BCBCBC",
		"v.	c #969696",
		"w.	c #636363",
		"x.	c #B2B2B2",
		"y.	c #353535",
		"z.	c #3F3F3F",
		"A.	c #B3B3B3",
		"B.	c #6C6C6C",
		"C.	c #4F4F4F",
		"D.	c #717171",
		"E.	c #A6A6A6",
		"F.	c #464646",
		"G.	c #696969",
		"H.	c #292929",
		"I.	c #6B6B6B",
		"J.	c #262626",
		"K.	c #676767",
		"L.	c #474747",
		"M.	c #666666",
		"N.	c #323232",
		"O.	c #8A8A8A",
		"P.	c #212121",
		"Q.	c #878787",
		"R.	c #828282",
		"S.	c #565656",
		"T.	c #ADADAD",
		"U.	c #535353",
		"V.	c #AEAEAE",
		"W.	c #ABABAB",
		"X.	c #4C4C4C",
		"Y.	c #454545",
		"Z.	c #9A9A9A",
		"`.	c #AAAAAA",
		" +	c #151515",
		".+	c #6F6F6F",
		"++	c #141414",
		"@+	c #959595",
		"#+	c #131313",
		"$+	c #343434",
		"%+	c #A8A8A8",
		"&+	c #B0B0B0",
		"*+	c #5E5E5E",
		"=+	c #202020",
		"-+	c #232323",
		";+	c #3A3A3A",
		">+	c #7A7A7A",
		",+	c #0C0C0C",
		"'+	c #BEBEBE",
		")+	c #444444",
		"!+	c #0A0A0A",
		"~+	c #0E0E0E",
		"{+	c #070707",
		"]+	c #050505",
		"^+	c #757575",
		"/+	c #8E8E8E",
		"(+	c #A2A2A2",
		"_+	c #101010",
		":+	c #030303",
		"<+	c #848484",
		"[+	c #020202",
		"}+	c #A1A1A1",
		"|+	c #A0A0A0",
		"1+	c #A7A7A7",
		"2+	c #989898",
		"3+	c #919191",
		"4+	c #8C8C8C",
		"5+	c #939393",
		"                                                                                                                        ",
		"              . . . . . . . + . . + . . + . . . . + + + . + . + . + . . . . . . + + + + . . . . + . . . . . +           ",
		"    @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @     ",
		"    # $ $ $ # # $ $ $ $ $ $ $ $ $ # # $ # $ # $ $ $ # # # $ # # # # $ $ $ $ $ # # # $ $ $ $ # # $ $ # $ $ $ $ # $ %     ",
		"    $ & & & & & & & & & & * * & * & & * & & & & & & * & & & & & & & & & * * & & & & & & & & & & & & & & & & & & & =     ",
		"    & - - - - - - - - - - & & - ; > ; - - - - - - - - & - - - - & $ * - & & - - - - - - - - - - - - - - - - - - - ,     ",
		"    & - - ' - ' ' - - - - - - ) ! ~ { - - - - - - - ' ' ' - - - $ ] ^ * - - ' - - - - - - - - - - - - ' - - - - - /     ",
		"    ' ; ; ; ; ; ; ; ' ; ; ' ' ( _ : < [ ' ; ; ' ; ; ; ; ; ; ; ' } : | * ; ; ; ; ; ; ; ' ; ; ; ; ; ; ' ' ; ; ' ; ; 1     ",
		"    ; [ [ ; [ ; [ [ [ [ ; ; [ { ^ 2 3 4 [ [ [ [ ; [ [ [ ; ; [ ; 5 2 6 ' [ [ [ [ [ [ ; [ [ ) 7 ; [ [ [ [ [ ; ; [ [ 8     ",
		"    [ ) ) ) [ [ ) ) ) ) [ ) 9 { } 0 a b > ) [ ) ) ) ) ) ) ) > - c d e > > > ) ) ) ) ) ) > f g [ ) ) ) ) ) [ [ ) ) h     ",
		"    [ ) ) ) ) ) ) ) ) ) ) 9 { ( i j k   l > > ) ) ) ) ) ) > > m k j [ l { 9 ) ) ) ) ) 9 n g g > ) ) ) ) ) ) ) ) ) h     ",
		"    9 4 > 9 9 9 > 4 9 9 4 l o p q r s j t { 9 > 4 > > > 9 4 9 u 0 v t p o { 9 9 9 > o w g g g 9 > 9 9 9 > > 9 9 9 x     ",
		"    9 4 9 4 4 4 4 9 4 4 { o i y z A B C z ( { 9 9 9 9 4 9 ( ( D E l F G b o 4 4 4 t H g g g g q q q q q q q 4 4 4 I     ",
		"    { { { { { { 4 { { { l o J K L } M N O e l { { { { { l o P Q u p L K J R l { J S g g g g g g g g g g g g { { { I     ",
		"    l l l l l l l l l l ( t T z U U V W X J o l l l l l R R Y W Z ` U z T t ( y  .g g g g g g g g g g g g g l l l $     ",
		"    ( l l l ( ( l l l l ( e ..K +.@.K #.E @.e ( l l ( ( t q $.#.( @.+.K ..t } %.g g g g g g g g g g g g g g ( l l &     ",
		"    o ( ( o ( ( ( o o o ( t p &.*.=.*.-.;.>.J R o ( ( o i ,.;.'.F =.L F ..+.).g g g g g g g g g g g g g g g o o o &     ",
		"    R R R R o o o o R R R R p y ` =.@.!.$.~.y i R R o e p {.].=.^./.(.G p S g g g g g g g g g g g g g g g g R o o -     ",
		"    R t t t t t t t t t t e b G _.^.:.L <.[.}...e t e b |.1.H q 2.^._.G b L ).g g g g g g g g g g g g g g g t t t ;     ",
		"    e e e e e e e e e e e e b T } |.2.=.3.4.5.y b e i T 6.4.7.L 2.|.} q b e (._ g g g g g g g g g g g g g g e e e [     ",
		"    p p p p p p p p p p p p ..q K U :.m m 8.9.` T ..T &.X 8.+.0.:.U } q ..p p _.a.g g g g g g g g g g g g g ..q K U     ",
		"    q q q q q T T T T T T T q y } +.:.b.@.c.d.e.F G A f.4.g.L h.0.+.} y q T T T z i.g g g g g g g g g g g g q y z ^.    ",
		"    A A A A A A A A A A A A A F _.+.0.j.h.6 d.M L K ` k.4.,.0.j.0.+._.F A A A A A (.l.g g g g U U U U U U U A K ` =.    ",
		"    K K K K K K K F F F F F F K _.+.2.j.}.h.~ ~ :.(.^.m.~ /.n.o.:.U (.K F F F F F K (.p.g g g F K K K K K K K z q.@.    ",
		"    } } } } } } } } } } } } } } _.*.r.h.}.h.n s.6 |.t.4.M 2.}.h.r.*._.} } } } } } } } _.c.g g } } } } } } } } _.L r.    ",
		"    z z z z z z z z z z z z z z (.L /.u.}.n.v.s.w r.n s.r !.}.u./.L (.z z z z z z z z z _.w.g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z _.` |.0.!.x.h.#.d.< y.z.@.A.!.0.|.` _.z z z z z z z z z z z u z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z (.*.r.j.A.Z B.[.C.[.D.b.}.h.r.*.(.z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z (.L /.m n.A.r c c c E.n.n.m /.L (.z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z _.` U :.!.x.o.a.].F.b.x.o.:.U ` _.z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z (.*.@.h.}.}.G.H.I.!.}.h.@.*.(.z z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z _.L /.m n.n.9.;.z.h.n.m /.q._.z z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z _.` U 2.!.t.J.J.J.+ j.2.U ` _.z z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z (.*.@.Z K.B L.E M.h.=.*.(.z z z z z z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z _.q.^.< N.D e.B 4.!.^.q._.z z z z z z z z z z z z z _.B.z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z _.` 2.O.P.p.f.l.P.^ =.` _.z z z z z z z z z z z z _.w.g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z z (.!.p.W Q.< R.W S.m (.z z z z z z z z z z z z (.w g g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z _.q.v B $.T.V T.B E < q._.z z z z z z z z z z q.U.g g g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z _.:.5.N w V.W.< S.N 5 =._.z z z z z z z z z +.X.g g g g =.=.=.=.=.=.=.z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z z (.f. .a O V W.T.6.a Y.h.(.z z z z z z z z |.Y.g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z _.+.Z.a s.W.W.`.W.V.D a E.L _.z z z z z z =.z.g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z _.h.K. +Y V V W.V < c. +.+2._.z z z z z :.~ g g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z z z (.`.d.++@+< V.< V.< 7.#+$+!.(.z z z z u.8.g g g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z z _.^.3.0 ).%+&+f.A.f.&+T.[.s ,.+._.z z z F.g g g g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z z (.}.p.d G.V A.n.!.n.x.< n d *+m (.z z z m 8.g g g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z z (.. =+#+,.f.n.h.u.j.}.f.,.d -+V.(.z z z z :.;+g g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z _.2.>+,+_ E.A.o.'+2.'+o.x.V y.,+O.^._.z z z z =.z.g g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z (.V.)+!+D.V }.u.r./.r.b.}.V.B.!+l.h.(.z z z z z |.Y.g g g g g g g g g g g g z (.*.2.    ",
		"    z z z z z z z z z z z z z z ` v.s ++Z.x.!.0.^.U /.'+Z f.  ~+g P ` z z z z z z +.X g g g g =.=.=.=.=.=.=.z (.*.2.    ",
		"    z z z z z z z z z z z z z _.b.M {+F.v }.j.r.+.L +.2.o.A.W.%.{+>+r._.z z z z z z q.j g g g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z z (.%+8.]+>+T.n.m /.L ` *./.u.}.V.^+2 m.Z (.z z z z z z z (.w g g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z _.+./+{+Q r x.!.:.|.` (.q.|.0.!.x.(+_+!+(+L _.z z z z z z z _.w.g z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z _.!.w :+C.E.}.h.@.*.(._.(.*.r.j.A.`.Y.:+M 0._.z z z z z z z z z u z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z z (.e.E :+<+< n.m /.L _.z (.L /.m }.V.5 [+1.f.(.z z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    z z z z z z z z z z z _.` }.{.N.}+A.o.2.U ` _.z _.` |.:.!.x.(+H.3 h.` _.z z z z z z z z z z z z z z z z z (.*.2.    ",
		"    (.(.(.(.(.(.(.(.(.(.(.q.+.@.V |+P x.j.2.U q.(.(.(.q.U :.o.x.W.E.f.@.+.` (.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.(.q.U 0.    ",
		"    *.*.*.*.*.*.*.*.*.*.*.U =.m n.V.T.f.j.2.^.+.*.*.*.+./.:.o.&+T.V.n.m =.U *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.U =.u.    ",
		"    r.r.r.r.r.r.r.r.r.r.2.0.h.A.W.1+1+V }.b.:.2.r.r.r.2.0.h.A.W.E.E.W.A.h.0.2.r.r.r.r.r.r.r.r.r.r.r.r.r.r.r.2.:.u.Z     ",
		"                        r + 2+3+4+6.3.6 v.t.r           r t.@+O O.6.4+3+2++ r                                           ",
		"                        r + 2+7.^ 4+/+5+2++ r           r + 2+7.4+3.^ 7.2++ r                                           "};
	elseif pic == '2' then
		Image = {
		"60 60 211 2",
		"  	c #9F9F9F",
		". 	c #9D9D9D",
		"+ 	c #9C9C9C",
		"@ 	c #FFFFFF",
		"# 	c #F1F1F1",
		"$ 	c #F0F0F0",
		"% 	c #FDFDFD",
		"& 	c #EEEEEE",
		"* 	c #EFEFEF",
		"= 	c #FBFBFB",
		"- 	c #EDEDED",
		"; 	c #FAFAFA",
		"> 	c #ECECEC",
		", 	c #F9F9F9",
		"' 	c #EBEBEB",
		") 	c #F8F8F8",
		"! 	c #EAEAEA",
		"~ 	c #F7F7F7",
		"{ 	c #E9E9E9",
		"] 	c #F6F6F6",
		"^ 	c #E8E8E8",
		"/ 	c #E7E7E7",
		"( 	c #E6E6E6",
		"_ 	c #F3F3F3",
		": 	c #F2F2F2",
		"< 	c #E5E5E5",
		"[ 	c #E4E4E4",
		"} 	c #E3E3E3",
		"| 	c #E2E2E2",
		"1 	c #CFCFCF",
		"2 	c #C0C0C0",
		"3 	c #D1D1D1",
		"4 	c #E0E0E0",
		"5 	c #E1E1E1",
		"6 	c #CDCDCD",
		"7 	c #686868",
		"8 	c #2A2A2A",
		"9 	c #6B6B6B",
		"0 	c #AAAAAA",
		"a 	c #C5C5C5",
		"b 	c #D4D4D4",
		"c 	c #DDDDDD",
		"d 	c #939393",
		"e 	c #3F3F3F",
		"f 	c #868686",
		"g 	c #BFBFBF",
		"h 	c #090909",
		"i 	c #080808",
		"j 	c #0D0D0D",
		"k 	c #3E3E3E",
		"l 	c #7E7E7E",
		"m 	c #B3B3B3",
		"n 	c #C9C9C9",
		"o 	c #D7D7D7",
		"p 	c #A5A5A5",
		"q 	c #555555",
		"r 	c #101010",
		"s 	c #3D3D3D",
		"t 	c #DFDFDF",
		"u 	c #BEBEBE",
		"v 	c #9A9A9A",
		"w 	c #636363",
		"x 	c #121212",
		"y 	c #1E1E1E",
		"z 	c #545454",
		"A 	c #919191",
		"B 	c #B9B9B9",
		"C 	c #DADADA",
		"D 	c #B4B4B4",
		"E 	c #232323",
		"F 	c #222222",
		"G 	c #696969",
		"H 	c #B6B6B6",
		"I 	c #DBDBDB",
		"J 	c #D9D9D9",
		"K 	c #D2D2D2",
		"L 	c #C3C3C3",
		"M 	c #B5B5B5",
		"N 	c #909090",
		"O 	c #5C5C5C",
		"P 	c #1D1D1D",
		"Q 	c #303030",
		"R 	c #A1A1A1",
		"S 	c #C1C1C1",
		"T 	c #CECECE",
		"U 	c #DCDCDC",
		"V 	c #7D7D7D",
		"W 	c #383838",
		"X 	c #242424",
		"Y 	c #5F5F5F",
		"Z 	c #A6A6A6",
		"` 	c #D8D8D8",
		" .	c #D6D6D6",
		"..	c #C8C8C8",
		"+.	c #D5D5D5",
		"@.	c #D0D0D0",
		"#.	c #CACACA",
		"$.	c #ACACAC",
		"%.	c #878787",
		"&.	c #565656",
		"*.	c #2D2D2D",
		"=.	c #282828",
		"-.	c #292929",
		";.	c #464646",
		">.	c #7A7A7A",
		",.	c #ADADAD",
		"'.	c #C4C4C4",
		").	c #C6C6C6",
		"!.	c #8C8C8C",
		"~.	c #4E4E4E",
		"{.	c #989898",
		"].	c #D3D3D3",
		"^.	c #9E9E9E",
		"/.	c #CBCBCB",
		"(.	c #C7C7C7",
		"_.	c #CCCCCC",
		":.	c #A7A7A7",
		"<.	c #505050",
		"[.	c #313131",
		"}.	c #333333",
		"|.	c #575757",
		"1.	c #898989",
		"2.	c #979797",
		"3.	c #5E5E5E",
		"4.	c #2F2F2F",
		"5.	c #4C4C4C",
		"6.	c #BABABA",
		"7.	c #BDBDBD",
		"8.	c #747474",
		"9.	c #393939",
		"0.	c #969696",
		"a.	c #424242",
		"b.	c #BCBCBC",
		"c.	c #C2C2C2",
		"d.	c #B8B8B8",
		"e.	c #BBBBBB",
		"f.	c #3C3C3C",
		"g.	c #707070",
		"h.	c #A3A3A3",
		"i.	c #A4A4A4",
		"j.	c #6A6A6A",
		"k.	c #B7B7B7",
		"l.	c #B2B2B2",
		"m.	c #B0B0B0",
		"n.	c #8D8D8D",
		"o.	c #5D5D5D",
		"p.	c #2E2E2E",
		"q.	c #484848",
		"r.	c #6D6D6D",
		"s.	c #444444",
		"t.	c #929292",
		"u.	c #2B2B2B",
		"v.	c #4D4D4D",
		"w.	c #AEAEAE",
		"x.	c #ABABAB",
		"y.	c #838383",
		"z.	c #515151",
		"A.	c #262626",
		"B.	c #676767",
		"C.	c #414141",
		"D.	c #272727",
		"E.	c #A9A9A9",
		"F.	c #585858",
		"G.	c #626262",
		"H.	c #323232",
		"I.	c #B1B1B1",
		"J.	c #A8A8A8",
		"K.	c #8E8E8E",
		"L.	c #949494",
		"M.	c #5A5A5A",
		"N.	c #777777",
		"O.	c #181818",
		"P.	c #1A1A1A",
		"Q.	c #767676",
		"R.	c #AFAFAF",
		"S.	c #858585",
		"T.	c #494949",
		"U.	c #1B1B1B",
		"V.	c #454545",
		"W.	c #959595",
		"X.	c #373737",
		"Y.	c #141414",
		"Z.	c #131313",
		"`.	c #656565",
		" +	c #999999",
		".+	c #191919",
		"++	c #525252",
		"@+	c #6F6F6F",
		"#+	c #0E0E0E",
		"$+	c #8B8B8B",
		"%+	c #252525",
		"&+	c #0F0F0F",
		"*+	c #434343",
		"=+	c #0A0A0A",
		"-+	c #151515",
		";+	c #474747",
		">+	c #7C7C7C",
		",+	c #161616",
		"'+	c #6E6E6E",
		")+	c #060606",
		"!+	c #050505",
		"~+	c #8A8A8A",
		"{+	c #0B0B0B",
		"]+	c #606060",
		"^+	c #8F8F8F",
		"/+	c #797979",
		"(+	c #363636",
		"_+	c #4B4B4B",
		":+	c #535353",
		"<+	c #5B5B5B",
		"[+	c #6C6C6C",
		"                                                                                                                        ",
		"              . . . . . . . + . . + . . + . . . . + + + . + . + . + . . . . . . + + + + . . . . + . . . . . +           ",
		"    @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @     ",
		"    # $ $ $ # # $ $ $ $ $ $ $ $ $ # # $ # $ # $ $ $ # # # $ # # # # $ $ $ $ $ # # # $ $ $ $ # # $ $ # $ $ $ $ # $ %     ",
		"    $ & & & & & & & & & & * * & * & & * & & & & & & * & & & & & & & & & * * & & & & & & & & & & & & & & & & & & & =     ",
		"    & - - - - - - - - - - & & - & - - - - - - - - - - & - - - - - - - - & & - - - - - - - - - - - - - - - - - - - ;     ",
		"    & - - > - > > - - - - - - - - - - - - - - - - - > > > - - - - - - - - - > - - - - - - - - - - - - > - - - - - ,     ",
		"    > ' ' ' ' ' ' ' > ' ' > > ' ' ' ' ' > ' ' > ' ' ' ' ' ' ' ' ' > ' ' ' ' ' ' ' ' ' > ' ' ' ' ' ' > > ' ' > ' ' )     ",
		"    ' ! ! ' ! ' ! ! ! ! ' ' ! ! ! ! ! ' ! ! ! ! ' ! ! ! ' ' ! ! ! ! ! ! ! ! ! ! ! ! ' ! ! ! ! ' ! ! ! ! ! ' ' ! ! ~     ",
		"    ! { { { ! ! { { { { ! ! { { { { { ! { { ! { { { { { { { { ! ! { { ! { { { { { { { { { { { ! { { { { { ! ! { { ]     ",
		"    ! { { { { { { { { { { { { { { { { { { { ^ { { { { { { { { { { { { { { { { { { { { { { { { ^ { { { { { { { { { ]     ",
		"    / ( ^ / / / ^ ( / / / / ^ / / ^ / / ^ / / ^ ( ^ ^ ^ / / ^ ^ ( ^ ^ / ^ ^ ^ / / ^ / / / ^ ^ / ^ / / / ^ ^ / / / _     ",
		"    / ( / ( ( ( ( / ( ( ( ( / ( ( / ( ( ( ( ( / / / / ( / ( ( ( ( ( / ( ( ( / ( ( / ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( :     ",
		"    < < < < < < ( < < < < ( < < < ( < < < < < < < < < < < < < < < < < < < < < < < < < ( < < < < < < < < < < < < < :     ",
		"    [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ } [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ [ } [ [ [ [ [ [ [ [ [ [ $     ",
		"    } [ [ [ } } [ [ [ [ [ } [ [ [ [ } [ } [ [ [ [ [ } [ } [ [ [ } } [ [ [ [ [ } [ [ [ [ } [ [ [ [ [ [ [ [ } } [ [ &     ",
		"    | } } 1 2 3 4 | | | } } } | | } } } } } | | | } } } | } } | } } } | | | } } } | | } | | | } } | | ( { ( | | | &     ",
		"    5 5 6 7 8 9 0 a b 4 5 | 5 5 5 5 | 5 | | | 5 5 5 | 5 5 5 5 5 | | | | 5 5 5 | 5 5 5 5 5 5 | | [ ( c d e f [ | | -     ",
		"    5 4 g e h i j k l m n o 4 4 4 4 4 4 4 4 4 4 4 4 4 4 5 4 4 4 4 4 4 4 4 4 4 4 4 5 4 4 4 | } | p q r i i s ( 4 4 '     ",
		"    t t 3 u v w 8 x x y z A B 6 C t t t t t t t t t t t t t t t t t t t t t t t t 4 t 4 5 D 9 E x x F G H / | t t !     ",
		"    I C J J K L M N O 8 P y Q G R S T J U U U U U U U U U U U U U U U U U U U U I I 2 V W P P X Y Z t t I J `  .3 ..    ",
		"    o +.K @.T 1 3 #.u $.%.&.*.=.-.;.>.,.'.1 ` J J J J J ` ` ` ` ` J J J J o +.).!.~.=.=.-.q {.].I +.@.T T 3 K ].T ).    ",
		"  ^.].@./.(.'.L '.(.#._.'.B :.l <.[.Q }.|.1.M a 1 +.+.+.+.+.+.+.+.+.K 1 (.2.3.}.Q 4.5.1.'. .].T #...'.'.'.)./._./.L     ",
		"  ^.1 /.a g 6.B B 7.g L )...n S H R 8.;.Q Q 9.w 0.6.(.1 K K K 1 #.'.^.7 W [.[.a.>.D @.1 _...).L g b.B B 6.u '.n n c.    ",
		"  ^.T #.L 7.d.D D D H B e.u c.a (.(.u M {.G f.Q Q e g.h.2 ).c.i.g.k Q Q 9.j.h./.6 /.(.a c.g b.B H D m D k.b.c.(...S     ",
		"  ^.T #.a u B M m l.l.m D M d.e.u S a (.a b.m.n.o.}.p.*.q.r.s.*.p.Q O t.2 n n (.a S g b.d.H D l.l.l.l.D d.7.L (.(.2     ",
		"  ^.T _.n a 2 b.d.H D m l.l.m D H B b.g c.a (.c.e.i.5.8 u.u.u.u.v.w.'.....a c.g b.B H D m l.l.l.D M d.e.g L ..n ..2     ",
		"    1 T _.#.(.a S u e.d.M D l.l.l.m D k.H D x.y.z.8 A.A.k B.C.A.D.*.o.0.S S e.k.D m l.l.l.m D k.6.7.2 L ).n _._.n S     ",
		"    @.1 T T _.#.n ).L S 7.6.k.M D m.,.E.1.F.8 F F 4.G.0.B u b.  j.}.F F H.G p c.b.M m D k.B 7.2 c.a ..#._.T T 6 #.S     ",
		"    @.@.@.@.1 T T _.#...a L 7.I.J.K.o.p.P P X z.f w.H b.2 S 2 b.6.e.L.M.A.P P 9.N.m '.S 2 c.a (.#./.6 T 1 1 @.T #.S     ",
		"    @.@.@.@.@.@.1 1 T #.6.x.t.w [.O.O.P.C.Q.p ,.R.m.m D H k.H D l.m.m d.d.S.T.U.O.P.V.S.2 /./.6 T 1 1 @.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.1 2 ,.W.G X.Y.Z.Z.[.`. +$.m.I.w.$.x.$.w.R.m.R.w.$.x.$.w.I.d.u l.N.W Z.Z..+++L...1 @.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.L R.2.@+f.x #+#+F &.$+0 H u b.k.m R.x.0 x.x.$.,.$.x.x.0 x.R.m k.b.S L '.:.B.%+#+&+y 3.p 1 @.@.@.@.T #.S     ",
		"    @.@.b.2.N.*+Z.h =+-+;+>+. D L a c.u B M I.w.$.x.$.w.R.m.R.w.$.x.$.w.I.M 6.u c.)...(.'. +&.,+h h =.'+H 3 3 T #.S     ",
		"    @.@.p =.)+!+=+W r.2.R.2 (.a S u e.d.D l.m.m.m.m.l.D H k.H D m m.m.m.m.m M d.b.g c.a (.n n L ~+*+{+)+)+;+3 T #.S     ",
		"    @.@.d.|.-.]+^+E.e.).a c.g b.d.H D l.l.l.l.D M d.e.7.2 S 2 7.e.d.M D l.l.l.m D k.B 7.2 L a ..n /.7./+Q /+@.T #.S     ",
		"    @.1 6 k.Z k.a a c.2 7.B k.D m l.l.l.m M k.6.7.S L ).......).'.S 7.6.d.M D m l.l.D M k.6.7.S L ).n #._.T T 6 #.S     ",
		"    1 T _.n ).L 2 7.6.k.D m l.l.l.m D k.B 7.2 L a ..#._.6 T 6 _.#...a L 2 7.6.k.D m l.l.l.D M d.e.u S a (.#._._.n S     ",
		"  ^.T /...L g e.d.M D l.I.l.m i.e :.b.g c.a ..#./.6 T 1 1 @.1 1 T 6 _.#...a c.g b.J.e h.m l.l.m D H d.b.2 a n #...2     ",
		"  ^.6 n L 7.d.D l.l.l.l.D M 0 Q ,+[.H (.#./.6 T 1 1 @.@.@.@.@.@.@.1 1 T 6 /.#.(.H [.,+Q 0 M D m l.l.m M B u a ....2     ",
		"  ^.6 ..S e.H m l.D M d.6.l.X.,+,+,+X.S T T 1 @.@.@.@.@.@.@.@.@.@.@.@.@.1 T T S 9.,+,+,+(+l.6.d.M D m D k.b.c.(.(.2     ",
		"  ^.6 n c.7.d.k.d.6.7.2 e.s ,+,+,+,+,+e (.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.(.e ,+,+,+,+,+f.6.2 7.6.d.k.d.7.L (.(.2     ",
		"  ^.T #.).S g u 2 L a c.s.,+,+,+,+,+,+,+V.n @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.n V.,+,+,+,+,+,+,+*+c.a c.2 u g c.).n ..2     ",
		"    T 6 #...).)...#.(.5.,+,+,+,+,+,+,+,+,+5._.@.@.@.@.@.@.@.@.@.@.@.@.@._.v.,+,+,+,+,+,+,+,+,+_+(.#...).)...#./.n S     ",
		"    1 T T 6 _._.6 _.z ,+,+,+,+,+,+,+,+,+,+,+:+T @.@.@.@.@.@.@.@.@.@.@.T z ,+,+,+,+,+,+,+,+,+,+,+:+_.6 _._.6 T _.n S     ",
		"    @.@.1 1 1 1 T <+,+,+,+,+,+,+,+,+,+,+,+,+,+<+1 @.@.@.@.@.@.@.@.@.1 <+,+,+,+,+,+,+,+,+,+,+,+,+,+<+T 1 1 1 1 T #.S     ",
		"    @.@.@.@.@.@.w ,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+w 1 @.@.@.@.@.@.@.@.w ,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+w 1 @.@.@.T #.S     ",
		"    @.@.@.@.@.r.,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+[+@.@.@.@.@.@.@.r.,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+,+[+@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    @.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.'.,+,+,+,+,+,+,+,+,+'.@.@.@.@.@.@.@.T #.S     ",
		"    T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T _...g     ",
		"    #.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#...'.b.    ",
		"    c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.c.S 2 b.H     ",
		"                                                                                                                        ",
		"                                                                                                                        "};
	elseif pic == '3' then
		Image = {
		"60 60 212 2",
		"  	c #9F9F9F",
		". 	c #9D9D9D",
		"+ 	c #9C9C9C",
		"@ 	c #FFFFFF",
		"# 	c #F1F1F1",
		"$ 	c #F0F0F0",
		"% 	c #FDFDFD",
		"& 	c #EEEEEE",
		"* 	c #EFEFEF",
		"= 	c #FBFBFB",
		"- 	c #EDEDED",
		"; 	c #DFDFDF",
		"> 	c #161616",
		", 	c #E0E0E0",
		"' 	c #FAFAFA",
		") 	c #ECECEC",
		"! 	c #F9F9F9",
		"~ 	c #EBEBEB",
		"{ 	c #DDDDDD",
		"] 	c #F8F8F8",
		"^ 	c #EAEAEA",
		"/ 	c #DCDCDC",
		"( 	c #F7F7F7",
		"_ 	c #E9E9E9",
		": 	c #DBDBDB",
		"< 	c #F6F6F6",
		"[ 	c #E8E8E8",
		"} 	c #DADADA",
		"| 	c #E7E7E7",
		"1 	c #E6E6E6",
		"2 	c #D9D9D9",
		"3 	c #F3F3F3",
		"4 	c #767676",
		"5 	c #787878",
		"6 	c #777777",
		"7 	c #F2F2F2",
		"8 	c #E5E5E5",
		"9 	c #E4E4E4",
		"0 	c #6C6C6C",
		"a 	c #E3E3E3",
		"b 	c #626262",
		"c 	c #636363",
		"d 	c #E2E2E2",
		"e 	c #5A5A5A",
		"f 	c #5B5B5B",
		"g 	c #515151",
		"h 	c #525252",
		"i 	c #DEDEDE",
		"j 	c #E1E1E1",
		"k 	c #494949",
		"l 	c #4A4A4A",
		"m 	c #D6D6D6",
		"n 	c #424242",
		"o 	c #434343",
		"p 	c #D2D2D2",
		"q 	c #3B3B3B",
		"r 	c #3D3D3D",
		"s 	c #CBCBCB",
		"t 	c #353535",
		"u 	c #D8D8D8",
		"v 	c #C8C8C8",
		"w 	c #C4C4C4",
		"x 	c #484848",
		"y 	c #C5C5C5",
		"z 	c #D0D0D0",
		"A 	c #C6C6C6",
		"B 	c #D5D5D5",
		"C 	c #CDCDCD",
		"D 	c #C0C0C0",
		"E 	c #B3B3B3",
		"F 	c #C2C2C2",
		"G 	c #CFCFCF",
		"H 	c #D3D3D3",
		"I 	c #D7D7D7",
		"J 	c #CCCCCC",
		"K 	c #C3C3C3",
		"L 	c #D1D1D1",
		"M 	c #BFBFBF",
		"N 	c #616161",
		"O 	c #272727",
		"P 	c #646464",
		"Q 	c #9E9E9E",
		"R 	c #B7B7B7",
		"S 	c #D4D4D4",
		"T 	c #8B8B8B",
		"U 	c #3C3C3C",
		"V 	c #7F7F7F",
		"W 	c #B2B2B2",
		"X 	c #090909",
		"Y 	c #080808",
		"Z 	c #0C0C0C",
		"` 	c #3A3A3A",
		" .	c #A7A7A7",
		"..	c #BCBCBC",
		"+.	c #0F0F0F",
		"@.	c #CECECE",
		"#.	c #CACACA",
		"$.	c #C1C1C1",
		"%.	c #B1B1B1",
		"&.	c #919191",
		"*.	c #5D5D5D",
		"=.	c #282828",
		"-.	c #121212",
		";.	c #1C1C1C",
		">.	c #505050",
		",.	c #888888",
		"'.	c #AEAEAE",
		").	c #ABABAB",
		"!.	c #666666",
		"~.	c #222222",
		"{.	c #212121",
		"].	c #656565",
		"^.	c #ADADAD",
		"/.	c #C7C7C7",
		"(.	c #B8B8B8",
		"_.	c #ACACAC",
		":.	c #898989",
		"<.	c #585858",
		"[.	c #2A2A2A",
		"}.	c #1E1E1E",
		"|.	c #1D1D1D",
		"1.	c #2F2F2F",
		"2.	c #999999",
		"3.	c #B9B9B9",
		"4.	c #373737",
		"5.	c #242424",
		"6.	c #A0A0A0",
		"7.	c #C9C9C9",
		"8.	c #B6B6B6",
		"9.	c #A5A5A5",
		"0.	c #838383",
		"a.	c #545454",
		"b.	c #2D2D2D",
		"c.	c #444444",
		"d.	c #4D4D4D",
		"e.	c #292929",
		"f.	c #535353",
		"g.	c #939393",
		"h.	c #BEBEBE",
		"i.	c #B5B5B5",
		"j.	c #A4A4A4",
		"k.	c #7C7C7C",
		"l.	c #4F4F4F",
		"m.	c #313131",
		"n.	c #323232",
		"o.	c #565656",
		"p.	c #868686",
		"q.	c #949494",
		"r.	c #303030",
		"s.	c #4C4C4C",
		"t.	c #878787",
		"u.	c #BDBDBD",
		"v.	c #BABABA",
		"w.	c #B4B4B4",
		"x.	c #747474",
		"y.	c #464646",
		"z.	c #393939",
		"A.	c #686868",
		"B.	c #797979",
		"C.	c #979797",
		"D.	c #6A6A6A",
		"E.	c #3F3F3F",
		"F.	c #707070",
		"G.	c #A3A3A3",
		"H.	c #3E3E3E",
		"I.	c #696969",
		"J.	c #A2A2A2",
		"K.	c #BBBBBB",
		"L.	c #B0B0B0",
		"M.	c #8D8D8D",
		"N.	c #5E5E5E",
		"O.	c #333333",
		"P.	c #6D6D6D",
		"Q.	c #929292",
		"R.	c #2B2B2B",
		"S.	c #262626",
		"T.	c #676767",
		"U.	c #969696",
		"V.	c #A9A9A9",
		"W.	c #A8A8A8",
		"X.	c #8E8E8E",
		"Y.	c #181818",
		"Z.	c #1A1A1A",
		"`.	c #414141",
		" +	c #AFAFAF",
		".+	c #858585",
		"++	c #1B1B1B",
		"@+	c #191919",
		"#+	c #454545",
		"$+	c #959595",
		"%+	c #141414",
		"&+	c #131313",
		"*+	c #383838",
		"=+	c #6F6F6F",
		"-+	c #0E0E0E",
		";+	c #AAAAAA",
		">+	c #252525",
		",+	c #0A0A0A",
		"'+	c #151515",
		")+	c #474747",
		"!+	c #555555",
		"~+	c #171717",
		"{+	c #6E6E6E",
		"]+	c #060606",
		"^+	c #050505",
		"/+	c #0B0B0B",
		"(+	c #8A8A8A",
		"_+	c #070707",
		":+	c #575757",
		"<+	c #606060",
		"[+	c #8F8F8F",
		"}+	c #A6A6A6",
		"                                                                                                                        ",
		"              . . . . . . . + . . + . . + . . . . + + + . + . + . + . . . . . . + + + + . . . . + . . . . . +           ",
		"    @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @     ",
		"    # $ $ $ # # $ $ $ $ $ $ $ $ $ # # $ # $ # $ $ $ # # # $ # # # # $ $ $ $ $ # # # $ $ $ $ # # $ $ # $ $ $ $ # $ %     ",
		"    $ & & & & & & & & & & * * & * & & * & & & & & & * & & & & & & & & & * * & & & & & & & & & & & & & & & & & & & =     ",
		"    & - - - - - - - - ; > > > > > > > > > ; - - - - - & - - - - - - - - & , > > > > > > > > > ; - - - - - - - - - '     ",
		"    & - - ) - ) ) - - ; > > > > > > > > > ; - - - - ) ) ) - - - - - - - - ; > > > > > > > > > ; - - - ) - - - - - !     ",
		"    ) ~ ~ ~ ~ ~ ~ ~ ) { > > > > > > > > > { ~ ) ~ ~ ~ ~ ~ ~ ~ ~ ~ ) ~ ~ ~ { > > > > > > > > > { ~ ~ ) ) ~ ~ ) ~ ~ ]     ",
		"    ~ ^ ^ ~ ^ ~ ^ ^ ^ / > > > > > > > > > / ^ ^ ~ ^ ^ ^ ~ ~ ^ ^ ^ ^ ^ ^ ^ / > > > > > > > > > { ^ ^ ^ ^ ^ ~ ~ ^ ^ (     ",
		"    ^ _ _ _ ^ ^ _ _ _ : > > > > > > > > > : ^ _ _ _ _ _ _ _ _ ^ ^ _ _ ^ _ : > > > > > > > > > / _ _ _ _ _ ^ ^ _ _ <     ",
		"    ^ _ _ _ _ _ _ _ _ : > > > > > > > > > : [ _ _ _ _ _ _ _ _ _ _ _ _ _ _ : > > > > > > > > > } _ _ _ _ _ _ _ _ _ <     ",
		"    | 1 [ | | | [ 1 | 2 > > > > > > > > > 2 | [ 1 [ [ [ | | [ [ 1 [ [ | [ } > > > > > > > > > 2 [ | | | [ [ | | | 3     ",
		"    | 1 | 1 1 4 > > > > > > > > > > > > > > > > > 5 | 1 | 1 1 1 1 4 > > > > > > > > > > > > > > > > > 6 1 1 1 1 1 7     ",
		"    8 8 8 8 8 9 0 > > > > > > > > > > > > > > > 0 8 8 8 8 8 8 8 8 9 0 > > > > > > > > > > > > > > > 0 8 8 8 8 8 8 7     ",
		"    9 9 9 9 9 9 a b > > > > > > > > > > > > > c a 9 9 9 a 9 9 9 9 9 a b > > > > > > > > > > > > > c a 9 9 9 9 9 9 $     ",
		"    a 9 9 9 a a 9 d e > > > > > > > > > > > f d 9 9 a 9 a 9 9 9 a a 9 d e > > > > > > > > > > > f d 9 9 9 a a 9 9 &     ",
		"    d a a d a a a d { g > > > > > > > > > h { d d a a a d a a d a a a d { g > > > > > > > > > h i d d a a a d d d &     ",
		"    j j j j d d d d j } k > > > > > > > l : d j j j d j j j j j d d d d j } k > > > > > > > l : d j j d d d j d d -     ",
		"    j , , , , , , , , , m n > > > > > n m , , , , , , , j , , , , , , , , , m n > > > > > o m , j j , , , , , , , ~     ",
		"    ; ; ; ; ; ; ; ; ; ; ; p q > > > r p ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; p q > > > r p ; ; ; ; ; ; ; ; ; ; ; ^     ",
		"    / / / / / / / / / / / / s t > t s / / / / / / / / / / / / / / / / / / / / / s t > t s / / / / / / / / / : u p v     ",
		"    u u u u u 2 2 2 2 2 2 2 2 w x y 2 2 2 2 2 2 2 2 2 2 u u u u u 2 2 2 2 2 2 2 2 w x w 2 2 2 2 2 u u u u 2 u m z A     ",
		"    B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B B p C w     ",
		"    p p p D E F G H H H H H H H H H H H p p H H H H H H p p p p p p p H H H H H H p p p p p H H p p H m : I p z J K     ",
		"    L L M N O P Q R y z L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L L S 2 p T U V m G s F     ",
		"    z z W q X Y Z ` 4  ...v z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z p B m + g +.Y Y ` } @.#.$.    ",
		"    z z K %.&.*.=.-.-.;.>.,.'.D s z z z z z z z z z z z z z z z z z z z z z z z z z L H B ).!.~.-.-.{.].^./ S @.#.$.    ",
		"    G @.@.C /.(._.:.<.[.}.|.1.].2.(.w @.z z z z z z z z z z z z z z z z z z z z z p 3.5 4.}.|.5.f 6.m B z C @.J 7.$.    ",
		"    G C #.v A A v F 8.9.0.a.b.=.=.c.6  .../.G z z z z z z z z z z z z z z G G $.,.d.=.e.[.f.g.C S G v A A v #.s v $.    ",
		"  Q @.s A F M h.D F y /.D i.j.k.l.m.1.n.o.p.%.D #.z z z z z z z z z C s w q.*.n.1.r.s.t.D p @.7.y K D M M $.A v v D     ",
		"  Q C 7.K u.(.R (.v.u.D K y A h.w.  x.y.m.r.z.c q.(.w J z z z C 7.F . A.4.r.r.n B.E G C #.A K $.u.v.(.R (.u.F /./.D     ",
		"  Q C 7.F ..R w.E w.i.(.v.u.$.w A A u.w.C.D.U r.r.E.F.G.D y $.G.F.H.r.1.z.I.J.#.J #.A w $.h.K.(.i.w.W E 8.K.$.A /.D     ",
		"  Q @.#.y h.3.i.E W W E w.i.(.K.h.$.y /.y ..L.M.N.O.b.b.x P.c.b.b.r.f Q.D 7.7./.y $.M ..(.8.w.W W W W w.(.u.K /./.D     ",
		"  Q @.J 7.y D ..(.8.w.E W W E w.8.3...M F y /.F K.j.s.R.[.[.R.[.d.'.w v v y F M ..3.8.w.E W W W w.i.(.K.M K v 7.v D     ",
		"    G @.J #./.y $.h.K.(.i.w.W W W E w.R 8.w.).0.h R.S.S.r T.n O O b.*.U.$.$.K.R w.E W W W E w.R v.u.D K A 7.J J 7.$.    ",
		"    z G @.@.J #.7.A K $.u.v.R i.w.L.^.V.:.<.e.~.~.1.b U.3.h...  D.O.~.~.n.I.9.F ..i.E w.R 3.u.D F y v #.J @.@.C #.$.    ",
		"    z z z z G @.@.J #.v y K u.%.W.X.*.b.}.|.5.g p.'.8...D $.D ..v.K.q.e S.|.}.z.6 E w $.D F y /.#.s C @.G G z @.#.$.    ",
		"    z z z z z z G G @.#.v.).Q.c m.Y.Y.Z.`.4 9.^. +L.E w.8.R 8.w.W L.E (.(..+k ++@+@+#+.+D s s C @.G G z z z z @.#.$.    ",
		"    z z z z z z G D ^.$+I.4.%+&+&+m.].2._.L.%.'._.)._.'. +L. +'._.)._.'.%.(.h.W 6 *+&+&+@+g q.v G z z z z z z @.#.$.    ",
		"    z z z z K  +C.=+U -.+.-+~.o.T ;+8.h...R E  +).;+).)._.^._.).).;+). +E R ..$.K w  .T.>+-+-+}.N.9.G z z z z @.#.$.    ",
		"    z z ..C.6 c.%+,+X '+)+k.. w.K y F h.3.i.%.'._.)._.'. +L. +'._.)._.'.%.i.v.h.F A v /.w 2.!+~+X ,+=.{+8.L L @.#.$.    ",
		"    z z 9.=.]+^+/+4.P.C. +D /.y $.h.K.(.w.W L.L.L.L.W w.8.R 8.w.E L.L.L.L.E i.(...M F y /.7.7.K (+o /+]+_+x L @.#.$.    ",
		"    z z (.:+[.<+[+V.K.A y F M ..(.8.w.W W W W w.i.(.K.u.D $.D u.K.(.i.w.W W W E w.R 3.u.D K y v 7.s u.B.m.B.z @.#.$.    ",
		"    z G C R }+R y y F D u.3.R w.E W W W E i.R v.u.$.K A v v v A w $.u.v.(.i.w.E W W w.i.R v.u.$.K A 7.#.J @.@.C #.$.    ",
		"    G @.J 7.A K D u.v.R w.E W W W E w.R 3.u.D K y v #.J C @.C J #.v y K D u.v.R w.E W W W w.i.(.K.h.$.y /.#.J J 7.$.    ",
		"  Q @.s v K M K.(.i.w.W %.W E w.8.3...M F y v #.s C @.G G z G G @.C J #.v y F M ..3.8.w.E W W E w.8.(...D y 7.#.v D     ",
		"  Q C 7.K u.(.w.W W W W w.i.(.K.h.$.y /.#.s C @.G G z z z z z z z G G @.C s #./.y $.h.K.(.i.w.E W W E i.3.h.y v v D     ",
		"  Q C v $.K.8.E W w.i.(.v.u.$.w A 7.s C @.@.G z z z z z z z z z z z z z G @.@.C s 7.A w $.u.v.(.i.w.E w.R ..F /./.D     ",
		"  Q C 7.F u.(.R (.v.u.D K A v #.J @.@.G z z z z z z z z z z z z z z z z z z z G @.@.J #.v y K D u.v.(.R (.u.K /./.D     ",
		"  Q @.#.A $.M h.D K y v #.J C @.G z z z z z z z z z z z z z z z z z z z z z z z z z G @.C J #.v y F D h.M F A 7.v D     ",
		"    @.C #.v A A v #.s C @.G G z z z z z z z z z z z z z z z z z z z z z z z z z z z z z G G @.C s #.v A A v #.s 7.$.    ",
		"    G @.@.C J J C @.G G z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z G @.@.C J J C @.J 7.$.    ",
		"    z z G G G G G z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z G G G G G @.#.$.    ",
		"    z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z @.#.$.    ",
		"    z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z z @.#.$.    ",
		"    @.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.@.J v M     ",
		"    #.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.v w ..    ",
		"    F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F F $.D ..8.    ",
		"                                                                                                                        ",
		"                                                                                                                        "};
	end
	return Image
end

function ImageZOnly(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 417 2",
		"  	c None",
		". 	c #A0A0A0",
		"+ 	c #9B9B9B",
		"@ 	c #979797",
		"# 	c #939393",
		"$ 	c #959595",
		"% 	c #989898",
		"& 	c #9C9C9C",
		"* 	c #9F9F9F",
		"= 	c #A1A1A1",
		"- 	c #A2A2A2",
		"; 	c #A2A2A3",
		"> 	c #A4A4A4",
		", 	c #A5A5A6",
		"' 	c #A6A6A6",
		") 	c #999999",
		"! 	c #F7F7F7",
		"~ 	c #EEEEEE",
		"{ 	c #F1F1F1",
		"] 	c #C4C4C5",
		"^ 	c #B2B2B0",
		"/ 	c #9F9FA0",
		"( 	c #8C8D8D",
		"_ 	c #8E8D8E",
		": 	c #90908F",
		"< 	c #91908F",
		"[ 	c #8E8E8B",
		"} 	c #797877",
		"| 	c #6D6C6B",
		"1 	c #70706F",
		"2 	c #F9F9F9",
		"3 	c #E2E2E2",
		"4 	c #E5E5E5",
		"5 	c #DDDDDD",
		"6 	c #B3B3B2",
		"7 	c #9A9C9A",
		"8 	c #999997",
		"9 	c #959594",
		"0 	c #91928F",
		"a 	c #868584",
		"b 	c #757573",
		"c 	c #727272",
		"d 	c #949493",
		"e 	c #F0F0F0",
		"f 	c #E3E3E3",
		"g 	c #BFBFBE",
		"h 	c #A5A7A6",
		"i 	c #9C9C9B",
		"j 	c #989A99",
		"k 	c #929190",
		"l 	c #878786",
		"m 	c #787677",
		"n 	c #747473",
		"o 	c #80807F",
		"p 	c #AEAEAD",
		"q 	c #EDEDEE",
		"r 	c #E4E4E4",
		"s 	c #DFDFDF",
		"t 	c #B3B4B3",
		"u 	c #A09FA0",
		"v 	c #979795",
		"w 	c #8A8A8A",
		"x 	c #7A7A79",
		"y 	c #727270",
		"z 	c #808180",
		"A 	c #989896",
		"B 	c #9C9B9A",
		"C 	c #EFEFEF",
		"D 	c #E6E6E6",
		"E 	c #C1C1C1",
		"F 	c #A4A6A4",
		"G 	c #9C9E9C",
		"H 	c #7F7E7F",
		"I 	c #717170",
		"J 	c #7D7F7F",
		"K 	c #9B9996",
		"L 	c #747372",
		"M 	c #F2F2F2",
		"N 	c #E8E8E8",
		"O 	c #BCBCBC",
		"P 	c #A8A8A9",
		"Q 	c #A6A5A6",
		"R 	c #999B9A",
		"S 	c #888786",
		"T 	c #747474",
		"U 	c #7C7D7D",
		"V 	c #919191",
		"W 	c #9D9C99",
		"X 	c #8C8B89",
		"Y 	c #656563",
		"Z 	c #F5F5F5",
		"` 	c #E9E9E9",
		" .	c #F8F8F8",
		"..	c #FFFFFF",
		"+.	c #C3C3C1",
		"@.	c #ACAEAC",
		"#.	c #A3A3A3",
		"$.	c #7D7F7D",
		"%.	c #787979",
		"&.	c #919192",
		"*.	c #7E7E7C",
		"=.	c #636362",
		"-.	c #F5F5F6",
		";.	c #5A5A5A",
		">.	c #000000",
		",.	c #B4B4B4",
		"'.	c #AFAFAF",
		").	c #A0A2A0",
		"!.	c #8F9090",
		"~.	c #7D7D7D",
		"{.	c #8C8D8C",
		"].	c #939391",
		"^.	c #969794",
		"/.	c #898887",
		"(.	c #787776",
		"_.	c #686866",
		":.	c #717171",
		"<.	c #C5C5C5",
		"[.	c #909090",
		"}.	c #929392",
		"|.	c #949392",
		"1.	c #91918E",
		"2.	c #7C7D7A",
		"3.	c #737372",
		"4.	c #787877",
		"5.	c #DEDEDE",
		"6.	c #B4B4B3",
		"7.	c #90908E",
		"8.	c #838281",
		"9.	c #757574",
		"0.	c #737373",
		"a.	c #9A9A9A",
		"b.	c #A4A5A6",
		"c.	c #999899",
		"d.	c #868683",
		"e.	c #747475",
		"f.	c #848483",
		"g.	c #B1B1B2",
		"h.	c #DCDCDC",
		"i.	c #9EA09E",
		"j.	c #949694",
		"k.	c #878788",
		"l.	c #777776",
		"m.	c #717172",
		"n.	c #848484",
		"o.	c #9A9996",
		"p.	c #8F8F8E",
		"q.	c #EFEFF0",
		"r.	c #E7E7E7",
		"s.	c #BAB9B9",
		"t.	c #A5A6A5",
		"u.	c #9D9D9D",
		"v.	c #7C7C7C",
		"w.	c #818182",
		"x.	c #979796",
		"y.	c #999795",
		"z.	c #6F6E6D",
		"A.	c #F3F3F3",
		"B.	c #B8BAB8",
		"C.	c #AAABAB",
		"D.	c #858585",
		"E.	c #737473",
		"F.	c #828183",
		"G.	c #929291",
		"H.	c #9C9C98",
		"I.	c #878785",
		"J.	c #646362",
		"K.	c #B7B7B7",
		"L.	c #ADAEAF",
		"M.	c #A2A3A2",
		"N.	c #929492",
		"O.	c #949594",
		"P.	c #969594",
		"Q.	c #959492",
		"R.	c #7B7C7B",
		"S.	c #656564",
		"T.	c #B4B4B2",
		"U.	c #A1A0A0",
		"V.	c #8D8D8D",
		"W.	c #7F7E7E",
		"X.	c #939392",
		"Y.	c #959693",
		"Z.	c #858683",
		"`.	c #6B6B6A",
		" +	c #F4F4F4",
		".+	c #EAEAEA",
		"++	c #D1D1D1",
		"@+	c #AEADAE",
		"#+	c #909191",
		"$+	c #8E8C8B",
		"%+	c #7A7978",
		"&+	c #727271",
		"*+	c #838282",
		"=+	c #3B3B3B",
		"-+	c #202020",
		";+	c #B8B8B8",
		">+	c #A2A3A3",
		",+	c #989796",
		"'+	c #8E8D8C",
		")+	c #80807D",
		"!+	c #767775",
		"~+	c #A3A3A2",
		"{+	c #161616",
		"]+	c #010101",
		"^+	c #C2C2C2",
		"/+	c #A1A3A1",
		"(+	c #9B9B9C",
		"_+	c #989897",
		":+	c #8E8E8D",
		"<+	c #818180",
		"[+	c #777777",
		"}+	c #8B8B8A",
		"|+	c #AFAFAE",
		"1+	c #EDEDED",
		"2+	c #D5D5D5",
		"3+	c #AAAAAC",
		"4+	c #9E9E9E",
		"5+	c #9E9F9E",
		"6+	c #949492",
		"7+	c #858584",
		"8+	c #888988",
		"9+	c #9A9A96",
		"0+	c #868685",
		"a+	c #D4D4D4",
		"b+	c #BFBFBF",
		"c+	c #797978",
		"d+	c #878889",
		"e+	c #92908E",
		"f+	c #6C6C6B",
		"g+	c #F3F3F4",
		"h+	c #F6F6F6",
		"i+	c #AEAEAE",
		"j+	c #B9B9B9",
		"k+	c #A9ABAB",
		"l+	c #A2A4A2",
		"m+	c #979695",
		"n+	c #818281",
		"o+	c #898A8A",
		"p+	c #9B9A97",
		"q+	c #82827F",
		"r+	c #FBFBFB",
		"s+	c #838383",
		"t+	c #646464",
		"u+	c #FEFEFE",
		"v+	c #B1B2B1",
		"w+	c #ACADAC",
		"x+	c #797A7B",
		"y+	c #828182",
		"z+	c #959491",
		"A+	c #8F8D8D",
		"B+	c #797977",
		"C+	c #676766",
		"D+	c #515151",
		"E+	c #353535",
		"F+	c #BBBBBB",
		"G+	c #ACADAE",
		"H+	c #9B9D9D",
		"I+	c #8A8B8B",
		"J+	c #828383",
		"K+	c #909290",
		"L+	c #949292",
		"M+	c #80817E",
		"N+	c #EBEBEB",
		"O+	c #FDFDFD",
		"P+	c #252525",
		"Q+	c #0F0F0F",
		"R+	c #ECECEC",
		"S+	c #DADADA",
		"T+	c #989A9A",
		"U+	c #949394",
		"V+	c #919390",
		"W+	c #8F8F8F",
		"X+	c #888886",
		"Y+	c #767675",
		"Z+	c #FAFAFA",
		"`+	c #C0BEBF",
		" @	c #A4A4A1",
		".@	c #969796",
		"+@	c #8E908F",
		"@@	c #8A8B89",
		"#@	c #858382",
		"$@	c #767673",
		"%@	c #696966",
		"&@	c #6A6A6B",
		"*@	c #9E9E9C",
		"=@	c #ECECED",
		"-@	c #E1E1E1",
		";@	c #090909",
		">@	c #323232",
		",@	c #3A3A3A",
		"'@	c #4E4E4E",
		")@	c #595959",
		"!@	c #565656",
		"~@	c #555555",
		"{@	c #5C5C5C",
		"]@	c #6D6D6D",
		"^@	c #7E7E7E",
		"/@	c #888888",
		"(@	c #C1C2C2",
		"_@	c #CCCCCC",
		":@	c #D2D2D2",
		"<@	c #E0E0E0",
		"[@	c #D9D9D9",
		"}@	c #141414",
		"|@	c #3C3C3C",
		"1@	c #575757",
		"2@	c #535353",
		"3@	c #616161",
		"4@	c #696969",
		"5@	c #707070",
		"6@	c #7F7F7F",
		"7@	c #868686",
		"8@	c #ACACAC",
		"9@	c #A8A8A8",
		"0@	c #B1B1B1",
		"a@	c #C0C0C0",
		"b@	c #BDBDBD",
		"c@	c #C4C4C4",
		"d@	c #CACACA",
		"e@	c #DBDBDB",
		"f@	c #404040",
		"g@	c #5B5B5B",
		"h@	c #636363",
		"i@	c #6B6B6B",
		"j@	c #686868",
		"k@	c #6C6C6C",
		"l@	c #949494",
		"m@	c #B0B0B0",
		"n@	c #C7C7C7",
		"o@	c #CDCDCD",
		"p@	c #0D0D0D",
		"q@	c #383838",
		"r@	c #3F3F3F",
		"s@	c #5D5D5D",
		"t@	c #828282",
		"u@	c #8C8C8C",
		"v@	c #929292",
		"w@	c #B3B3B3",
		"x@	c #B6B6B6",
		"y@	c #BEBEBE",
		"z@	c #C9C9C9",
		"A@	c #040404",
		"B@	c #303030",
		"C@	c #4D4D4D",
		"D@	c #6F6F6F",
		"E@	c #818181",
		"F@	c #AAAAAA",
		"G@	c #C6C6C6",
		"H@	c #060606",
		"I@	c #282828",
		"J@	c #2B2B2B",
		"K@	c #ABABAB",
		"L@	c #B2B2B2",
		"M@	c #242424",
		"N@	c #626262",
		"O@	c #6A6A6A",
		"P@	c #121212",
		"Q@	c #4C4C4C",
		"R@	c #545454",
		"S@	c #6E6E6E",
		"T@	c #808080",
		"U@	c #878787",
		"V@	c #111111",
		"W@	c #232323",
		"X@	c #2A2A2A",
		"Y@	c #2F2F2F",
		"Z@	c #373737",
		"`@	c #3D3D3D",
		" #	c #656565",
		".#	c #262626",
		"+#	c #212121",
		"@#	c #292929",
		"##	c #313131",
		"$#	c #505050",
		"%#	c #4B4B4B",
		"&#	c #0C0C0C",
		"*#	c #363636",
		"=#	c #4F4F4F",
		"-#	c #8B8B8B",
		";#	c #A9A9A9",
		">#	c #070707",
		",#	c #393939",
		"'#	c #8E8E8E",
		")#	c #969696",
		"!#	c #0E0E0E",
		"~#	c #151515",
		"{#	c #606060",
		"]#	c #030303",
		"^#	c #131313",
		"/#	c #1A1A1A",
		"(#	c #222222",
		"_#	c #1F1F1F",
		":#	c #424242",
		"<#	c #4A4A4A",
		"[#	c #585858",
		"}#	c #797979",
		"|#	c #757575",
		"1#	c #7B7B7B",
		"2#	c #898989",
		"3#	c #A5A5A5",
		"4#	c #BABABA",
		"5#	c #C3C3C3",
		"6#	c #CBCBCB",
		"7#	c #CECECE",
		"8#	c #D0D0D0",
		"9#	c #D3D3D3",
		"0#	c #D6D6D6",
		"a#	c #D8D8D8",
		"b#	c #676767",
		"c#	c #D7D7D7",
		"d#	c #787878",
		"e#	c #7A7A7A",
		"f#	c #767676",
		"g#	c #A7A7A7",
		"h#	c #666666",
		"i#	c #ADADAD",
		"j#	c #C8C8C8",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # $ % & * = - - ; > , ' . ) # # # @ + . ",
		". @ ! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { ] ^ / ( _ : < [ } | 1 2 ~ ~ ~ ! @ . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 4 5 6 - 7 8 9 0 a b c d e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f f g h i j k l m n o p q 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 r s t = u v w x y z A B C 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 D E ' F G : H I J d K L M 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N O P Q R S T U V W X Y Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 `  ........... .` 3 3 3 N +.@.#.$ $.%.&.9 A *.=.-.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 e ;.>.>.>.>.>.;.e 3 3 3 N ,.'.).!.~.{.].^./.(._.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 D <.p * [.}.d |.1.2.3.4.M 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 r 5.6.- & 8 9 7.8.9.0.a.C 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 f f E b.i c.< d.9.e.f.g.~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 4 h.'.. i.j.k.l.m.n.o.p.q.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 r.s.' t.u.p.v.:.w.x.y.z.A.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 ` B.C.F % D.E.F.G.H.I.J.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 ` K.L.M.N.U U O.P.Q.R.S.-.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 N T.'.U.V.W.: X.Y.Z.9.`. +3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .+! ......n.>.>.>.>.>.n....... .C ++@+* #+# d ].$+%+&+*+{ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .+=+>.>.>.>.>.>.>.>.>.>.>.>.>.-+~ 3 ;+>+a.,+d '+)+3.!+~+~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .+2 {+>.>.>.>.>.>.>.>.>.>.>.]+{ ~ f ^+/+(+_+:+<+c [+}+|+~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 C 1+>.>.>.>.>.>.>.>.>.>.>.5.{ D 2+3+4+5+6+7+b T 8+9+0+e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f M a+>.>.>.>.>.>.>.>.>.b+Z r r.,.> > + }+c+c d+_+e+f+g+3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 r h+i+>.>.>.>.>.>.>.# 2 4 3 ` j+k+l+m+n+T o+X.p+q+S.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 D r+s+>.>.>.>.>.t+u+r.3 3 ` v+w+. !.x+y+9 z+A+B+C+Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N ..D+>.>.>.E+...+3 3 3 r.F+G+H+I+J+K+[.L+M+3.&+A.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N+O+P+>.Q+! R+3 3 3 3 4 S+@+T+V U+V+W+X+Y+c p.e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 R+h+..u+....-+Z+..2 ! Z A.A.A.~ `+ @.@+@@@#@$@%@&@*@=@3 3 -@~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ! ;@>@=+,@'@)@!@~@{@)@]@T ^@v./@$ % '.j+K.^+(@_@:@a+<@[@3 R+1+# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..}@|@'@1@2@{@t+3@4@5@s+6@7@V.$ # + % 8@9@0@;+a@b@c@d@e@f 1+~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..{+f@|@'@1@2@g@h@i@j@5@k@6@D.V.$ l@V ) 8@9@m@;+b+n@o@<@e@[@C # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..p@q@r@|@'@!@s@;.h@i@4@5@t@~.D.V.u@$ v@) 8@w@'.x@y@<.^+z@e@e # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..A@B@q@r@|@C@!@s@;.h@i@j@D@E@/@7@n.V.$ V @ F@0@;+a@b@G@o@5 { # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..H@I@B@q@r@|@C@!@s@;.h@i@j@D@t@6@~.n.u@# a.8@w@'.K.b+n@c@z@M # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.J@I@B@q@r@|@C@!@s@;.h@i@j@5@k@6@7@V.$ & % K@L@j+x@b+n@a@A.# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.M@J@I@B@q@r@|@C@!@s@;.N@O@j@5@E@/@n.u@l@+ % K@0@j+x@b+^+ +# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.P@M@J@I@B@q@r@=+Q@R@g@h@k@O@c S@T@U@n.u@l@+ % K@0@j+x@j+Z # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.{+V@W@X@>@Y@Z@`@'@!@s@ #h@3@O@:.S@T@U@n.u@l@+ % K@0@j+'.h+# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.p@}@.#+#@###q@r@$#%#R@s@g@)@N@O@:.S@T@U@n.u@l@+ % K@0@0@! # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.Q+&#}@P+J@>@Y@*#`@=#%#!@R@{@t+3@4@:.S@T@U@n.-## + % K@;# .# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.>#A@&#V@W@X@##,#*#`@$#C@%#R@{@h@k@4@:.]@6@7@'#)## + @ . 2 # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 ..>.>.>#!#~#.#+#@###,#*#r@=+=#%#R@g@h@{#4@5@t@^@D.V.-#l@a.#.Z+# . ",
		". # ~ 3 3 3 N ~ A.A.A.M M { { e e C C ~ ~ ~ 1+1+R+R+N+..>.>.>.>.>.>.]#&#;@^#V@/#(#_#>@|@,#:#<#2@$#[#O@j@:.}#[+6@T@Z # . ",
		". # ~ 3 3 3 ~  #|#|#}#~.1#t@7@w 2#V.V $ l@+ a.4+= 3#3#K.o@S+5.<@s -@f -@r f ` r..+R+C { C Z ! Z+ .r+O+..u+........{ # . ",
		". # ~ 3 3 3  +:.s+U@w 2#u@# )#l@% @ a.4+u.. ' ;#9@8@'.i+0@m@K.4#b@O a@b+5#^+<.6#7#o@8#9#0#5 h.s 3 D 4 f r..+e ~ h+N+# . ",
		". # ~ 3 3 3 Z S@T@s+U@w 2#u@v@V $ % + a.4+u.. ' ;#9@8@'.i+L@m@x@4#b@b@O a@5#^+<.6#7#++a+a#:@2+h.s 5 -@4 N r..+e ! N+# . ",
		". # ~ 3 3 3 Z b#E@T@s+U@7@2#u@v@V l@% @ + 4+= . ' 3#9@8@'.i+0@;+x@4#j+b@O a@5#G@c@d@7#_@8#a+c#2+h.s 3 -@r N N+.+A.R+# . ",
		". # ~ 3 3 3 h+h@1#t@T@n.U@7@2#u@# V $ % @ a.4+= . ' ;#9@8@'.i+0@;+K.x@4#b@O b+^+<._@d@7#++8#9#0#5 e@5.3 4 r N N+R+R+# . ",
		". # ~ 3 3 3 h+{#d#v.e#E@n.U@7@2#V.-#v@$ % @ + 4+u.. ' ;#9@8@'.i+L@0@m@x@j+b@a@5#^+<.6#7#o@++a+9#0#h.s 5.3 4 r N 1+1+# . ",
		". # ~ 3 3 3 ! {#|#}#v.1#E@n.U@7@w V.u@v@$ l@@ + 4+u.. ' 3#9@8@'.'.i+0@K.4#b@O a@5#G@<.6#7#o@++a+9#0#h.s 5.3 4 r ` 1+# . ",
		". # ~ 3 3 3 ! {@f#|#}#v.1#E@n.s+7@w V.u@v@$ l@@ + 4+u.. ' 3#9@8@K@'.L@;+x@4#b@O b+5#G@<.6#7#o@++a+c#0#h.s 5.3 4 4 ~ # . ",
		". # ~ 3 3 3  .)@0.c |#}#v.1#E@n.s+7@w V.u@v@$ l@@ + 4+u.. ' ;#9@8@K@i+0@;+x@4#b@O b+5#G@<.6#7#o@8#a+c#0#h.s 5.3 D ~ # . ",
		". # ~ 3 3 3  .!@D@0.f#|#}#v.e#E@n.U@7@w V.-#v@$ % @ a.4+= g#3#;#9@8@K@i+L@m@K.4#b@O b+5#G@<.6#7#o@8#a+9#0#h.s 5.3 ~ # . ",
		". # ~ 3 3 3  .1@]@D@0.f#|#d#1#t@T@n.U@7@2#u@# V l@% + 4+u.& g#' 3#;#8@K@'.L@m@x@4#b@O a@5#^+<.6#7#o@++a+9#0#h.s 5.C # . ",
		". # ~ 3 3 3  .1@]@5@D@c f#}#d#1#E@T@s+U@w '#u@v@$ l@@ + a.u.= . ' 3#9@8@K@'.L@;+x@4#j+O a@5#^+<.6#7#o@++a+9#0#h.s C # . ",
		". # ~ 3 3 3  .1@]@]@5@0.c |#}#~.1#E@n./@t@7@2#u@v@$ ) # + 4+4+u.. ' ;#9@8@K@i+0@K.x@4#b@O a@5#^+<.6#d@o@++a+9#0#e@e # . ",
		". # ~ 3 3 3  .1@S@]@]@D@0.[+f#T d#1#E@T@s+U@w V.u@v@[.) @ + a.4+u.. ' ;#9@8@K@i+0@K.x@4#b@O a@5#G@<.6#d@o@++8#9#a+e # . ",
		". @ ! ~ ~ ~ O+~@t+t+t+h@h# #4@]@:.5@T e#^@~.E@D.2#/@W+v@V )#$ ) u.& . g#' F@i+i#0@,.F+4#y@^+E <.z@j#_@9#c#0#S+5.<@ .@ . ",
		". + @ # # # a.- ;#;#;#;#;#;#9@9@g#g#' ' 3#3#> > #.#.- - = = = . . . * * 4+4+u.u.u.& + + a.a.a.) ) % % @ @ )#)#$ l@% + . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '1' then
		Image = {
		"60 60 436 2",
		"  	c None",
		". 	c #A0A0A0",
		"+ 	c #9B9B9B",
		"@ 	c #979797",
		"# 	c #939393",
		"$ 	c #969696",
		"% 	c #A2A2A2",
		"& 	c #A7A7A7",
		"* 	c #ABABAB",
		"= 	c #ACACAC",
		"- 	c #ACACAD",
		"; 	c #ADADAD",
		"> 	c #AFAFAF",
		", 	c #B2B2B2",
		"' 	c #B3B3B4",
		") 	c #A8A9A9",
		"! 	c #9D9D9D",
		"~ 	c #F7F7F7",
		"{ 	c #EEEEEE",
		"] 	c #F2F2F2",
		"^ 	c #B1B1B1",
		"/ 	c #8D8F8C",
		"( 	c #6D6F6E",
		"_ 	c #4B4D4D",
		": 	c #4D4E4D",
		"< 	c #535351",
		"[ 	c #545250",
		"} 	c #50504A",
		"| 	c #2A2927",
		"1 	c #151312",
		"2 	c #1B1B1A",
		"3 	c #FFFFFF",
		"4 	c #E2E2E2",
		"5 	c #E5E5E5",
		"6 	c #E4E4E4",
		"7 	c #989897",
		"8 	c #7A7B7A",
		"9 	c #6D6E6D",
		"0 	c #6A6967",
		"a 	c #626262",
		"b 	c #5D5D5A",
		"c 	c #484745",
		"d 	c #2A2A28",
		"e 	c #262625",
		"f 	c #636361",
		"g 	c #F9F9F9",
		"h 	c #E3E3E3",
		"i 	c #EFEFEF",
		"j 	c #AEAEAD",
		"k 	c #818281",
		"l 	c #706F6E",
		"m 	c #6A6C69",
		"n 	c #5D5D5B",
		"o 	c #4A4A48",
		"p 	c #2F2E2D",
		"q 	c #292928",
		"r 	c #3E3E3E",
		"s 	c #929290",
		"t 	c #F5F5F5",
		"u 	c #E7E7E7",
		"v 	c #989998",
		"w 	c #787978",
		"x 	c #757675",
		"y 	c #676764",
		"z 	c #50504F",
		"A 	c #333332",
		"B 	c #252524",
		"C 	c #3E403F",
		"D 	c #6A6865",
		"E 	c #71706E",
		"F 	c #EAEAEA",
		"G 	c #E8E8E8",
		"H 	c #B1B0B1",
		"I 	c #818382",
		"J 	c #808180",
		"K 	c #717271",
		"L 	c #5A5C59",
		"M 	c #3C3C3B",
		"N 	c #242423",
		"O 	c #393B3C",
		"P 	c #61615F",
		"Q 	c #6D6B65",
		"R 	c #2C2A28",
		"S 	c #FDFDFD",
		"T 	c #3B3B3B",
		"U 	c #FAFAFA",
		"V 	c #EBEBEB",
		"W 	c #ABAAA9",
		"X 	c #858685",
		"Y 	c #6B6C6B",
		"Z 	c #4C4C4B",
		"` 	c #292A29",
		" .	c #383A3A",
		"..	c #5D5D5C",
		"+.	c #71706B",
		"@.	c #54524E",
		"#.	c #11100E",
		"$.	c #000000",
		"%.	c #0F0F0F",
		"&.	c #F3F3F3",
		"*.	c #ECECEC",
		"=.	c #B5B4B3",
		"-.	c #8C8E8C",
		";.	c #7B7C7D",
		">.	c #636363",
		",.	c #3B3C3A",
		"'.	c #303131",
		").	c #5C5E5E",
		"!.	c #636360",
		"~.	c #696863",
		"{.	c #3B3B38",
		"].	c #0E0D0A",
		"^.	c #CCCCCC",
		"/.	c #F8F8F8",
		"(.	c #E6E6E6",
		"_.	c #9A9A9A",
		":.	c #909190",
		"<.	c #797A79",
		"[.	c #58595A",
		"}.	c #393A3A",
		"|.	c #555655",
		"1.	c #5F5F5D",
		"2.	c #676663",
		"3.	c #4E4D4A",
		"4.	c #302F2D",
		"5.	c #151513",
		"6.	c #FCFCFC",
		"7.	c #A5A5A5",
		"8.	c #E9E9E9",
		"9.	c #B9B9B9",
		"0.	c #90908E",
		"a.	c #5A5B5B",
		"b.	c #5E5F5E",
		"c.	c #626260",
		"d.	c #62605E",
		"e.	c #5C5D58",
		"f.	c #373834",
		"g.	c #282726",
		"h.	c #31312F",
		"i.	c #FDFDFE",
		"j.	c #393939",
		"k.	c #515151",
		"l.	c #717171",
		"m.	c #999998",
		"n.	c #797B7B",
		"o.	c #6F706F",
		"p.	c #696968",
		"q.	c #5A5B57",
		"r.	c #444341",
		"s.	c #2B2A29",
		"t.	c #6E6E6D",
		"u.	c #3C3C3C",
		"v.	c #F0F0F0",
		"w.	c #F1F1F1",
		"x.	c #B0B0B0",
		"y.	c #7E8180",
		"z.	c #70706F",
		"A.	c #6B6B6A",
		"B.	c #484846",
		"C.	c #2B2B29",
		"D.	c #2A2A29",
		"E.	c #474745",
		"F.	c #111111",
		"G.	c #929192",
		"H.	c #767776",
		"I.	c #747574",
		"J.	c #636462",
		"K.	c #4D4D4C",
		"L.	c #30302E",
		"M.	c #262627",
		"N.	c #454546",
		"O.	c #6C6965",
		"P.	c #595957",
		"Q.	c #F8F8F9",
		"R.	c #B3B3B3",
		"S.	c #818280",
		"T.	c #585857",
		"U.	c #383837",
		"V.	c #242424",
		"W.	c #404142",
		"X.	c #676765",
		"Y.	c #6A6762",
		"Z.	c #23211F",
		"`.	c #FEFEFF",
		" +	c #212121",
		".+	c #B0B2AF",
		"++	c #898B8A",
		"@+	c #7E807F",
		"#+	c #696A69",
		"$+	c #474847",
		"%+	c #272927",
		"&+	c #424244",
		"*+	c #5D5F5D",
		"=+	c #706F6A",
		"-+	c #4B4A47",
		";+	c #100E0C",
		">+	c #4A4A4A",
		",+	c #FBFBFB",
		"'+	c #8E8F8F",
		")+	c #60605F",
		"!+	c #383939",
		"~+	c #373838",
		"{+	c #616362",
		"]+	c #656360",
		"^+	c #64615E",
		"/+	c #373634",
		"(+	c #12100E",
		"_+	c #F6F6F6",
		":+	c #7A7A7A",
		"<+	c #8F8F8F",
		"[+	c #A4A4A4",
		"}+	c #747474",
		"|+	c #9A9A98",
		"1+	c #777879",
		"2+	c #555657",
		"3+	c #3C3D3D",
		"4+	c #5A5A59",
		"5+	c #60605E",
		"6+	c #656461",
		"7+	c #484744",
		"8+	c #2C2C2A",
		"9+	c #1C1B1A",
		"0+	c #EDEDED",
		"a+	c #A6A6A6",
		"b+	c #CECECE",
		"c+	c #908F8E",
		"d+	c #5B5C5D",
		"e+	c #616161",
		"f+	c #61615E",
		"g+	c #565551",
		"h+	c #33312F",
		"i+	c #252525",
		"j+	c #454443",
		"k+	c #FBFBFC",
		"l+	c #C7C7C7",
		"m+	c #ECECED",
		"n+	c #A1A1A1",
		"o+	c #7B7D7C",
		"p+	c #6C6D6C",
		"q+	c #676866",
		"r+	c #585654",
		"s+	c #3E3D3B",
		"t+	c #282826",
		"u+	c #2D2D2C",
		"v+	c #7F7D7C",
		"w+	c #030303",
		"x+	c #E0E0E0",
		"y+	c #F4F4F4",
		"z+	c #F0EFEF",
		"A+	c #B3B2B2",
		"B+	c #706F70",
		"C+	c #676966",
		"D+	c #585856",
		"E+	c #40403E",
		"F+	c #272726",
		"G+	c #2D2F2E",
		"H+	c #525250",
		"I+	c #949392",
		"J+	c #202020",
		"K+	c #D7D7D7",
		"L+	c #87898A",
		"M+	c #737474",
		"N+	c #737473",
		"O+	c #474746",
		"P+	c #2A2A2B",
		"Q+	c #4D4F4E",
		"R+	c #6E6C67",
		"S+	c #F9F9FA",
		"T+	c #9C9C9C",
		"U+	c #7E7F7F",
		"V+	c #6C6E6C",
		"W+	c #535251",
		"X+	c #313130",
		"Y+	c #272627",
		"Z+	c #6A6A66",
		"`+	c #5D5C57",
		" @	c #1B1B19",
		".@	c #A4A5A4",
		"+@	c #878889",
		"@@	c #7B7C7B",
		"#@	c #656563",
		"$@	c #424342",
		"%@	c #292929",
		"&@	c #4F5051",
		"*@	c #6C6B66",
		"=@	c #43413E",
		"-@	c #11110F",
		";@	c #969796",
		">@	c #8C8E8D",
		",@	c #767777",
		"'@	c #333435",
		")@	c #414243",
		"!@	c #626261",
		"~@	c #63615E",
		"{@	c #585754",
		"]@	c #32312F",
		"^@	c #131411",
		"/@	c #A9A9A9",
		"(@	c #8C8F8D",
		"_@	c #6F6F70",
		":@	c #4F5252",
		"<@	c #424344",
		"[@	c #5C5D5C",
		"}@	c #61605D",
		"|@	c #403E3B",
		"1@	c #282927",
		"2@	c #292927",
		"3@	c #DEDEDE",
		"4@	c #6A6B6C",
		"5@	c #606160",
		"6@	c #5D5E5C",
		"7@	c #2E2E2C",
		"8@	c #5C5C59",
		"9@	c #A09F9F",
		"0@	c #71716C",
		"a@	c #5A5B5A",
		"b@	c #505150",
		"c@	c #484946",
		"d@	c #403E3C",
		"e@	c #252521",
		"f@	c #0F0F0D",
		"g@	c #151516",
		"h@	c #727270",
		"i@	c #777777",
		"j@	c #7D7D7D",
		"k@	c #7C7C7C",
		"l@	c #818181",
		"m@	c #878787",
		"n@	c #858585",
		"o@	c #8B8B8B",
		"p@	c #909090",
		"q@	c #8E8E8E",
		"r@	c #999999",
		"s@	c #9E9E9E",
		"t@	c #A3A3A3",
		"u@	c #B7B7B7",
		"v@	c #BEBEBE",
		"w@	c #CDCDCD",
		"x@	c #D4D4D5",
		"y@	c #D5D4D5",
		"z@	c #DCDCDD",
		"A@	c #DFDFDF",
		"B@	c #DCDCDC",
		"C@	c #E1E1E1",
		"D@	c #676767",
		"E@	c #7F7F7F",
		"F@	c #888888",
		"G@	c #8C8C8C",
		"H@	c #919191",
		"I@	c #959595",
		"J@	c #989898",
		"K@	c #B5B5B5",
		"L@	c #BCBCBC",
		"M@	c #C1C1C1",
		"N@	c #C5C5C5",
		"O@	c #CACACA",
		"P@	c #CBCBCB",
		"Q@	c #CFCFCF",
		"R@	c #D9D9D9",
		"S@	c #DDDDDD",
		"T@	c #696969",
		"U@	c #A8A8A8",
		"V@	c #B4B4B4",
		"W@	c #C0C0C0",
		"X@	c #C9C9C9",
		"Y@	c #D1D1D1",
		"Z@	c #DBDBDB",
		"`@	c #D6D6D6",
		" #	c #8D8D8D",
		".#	c #929292",
		"+#	c #C2C2C2",
		"@#	c #BFBFBF",
		"##	c #C4C4C4",
		"$#	c #C8C8C8",
		"%#	c #D8D8D8",
		"&#	c #5E5E5E",
		"*#	c #787878",
		"=#	c #AAAAAA",
		"-#	c #BDBDBD",
		";#	c #5F5F5F",
		">#	c #5A5A5A",
		",#	c #767676",
		"'#	c #C6C6C6",
		")#	c #4F4F4F",
		"!#	c #727272",
		"~#	c #949494",
		"{#	c #4B4B4B",
		"]#	c #737373",
		"^#	c #4C4C4C",
		"/#	c #666666",
		"(#	c #757575",
		"_#	c #808080",
		":#	c #464646",
		"<#	c #646464",
		"[#	c #686868",
		"}#	c #707070",
		"|#	c #797979",
		"1#	c #898989",
		"2#	c #474747",
		"3#	c #BBBBBB",
		"4#	c #484848",
		"5#	c #7E7E7E",
		"6#	c #868686",
		"7#	c #B6B6B6",
		"8#	c #424242",
		"9#	c #5B5B5B",
		"0#	c #656565",
		"a#	c #B8B8B8",
		"b#	c #3A3A3A",
		"c#	c #4E4E4E",
		"d#	c #525252",
		"e#	c #565656",
		"f#	c #6D6D6D",
		"g#	c #7B7B7B",
		"h#	c #828282",
		"i#	c #8A8A8A",
		"j#	c #D4D4D4",
		"k#	c #D2D2D2",
		"l#	c #D5D5D5",
		"m#	c #DADADA",
		"n#	c #FEFEFE",
		"o#	c #838383",
		"p#	c #AEAEAE",
		"q#	c #BABABA",
		"r#	c #C3C3C3",
		"s#	c #D0D0D0",
		"t#	c #D3D3D3",
		"u#	c #6E6E6E",
		"v#	c #848484",
		"w#	c #606060",
		"x#	c #5C5C5C",
		"y#	c #595959",
		"z#	c #6F6F6F",
		"A#	c #575757",
		"B#	c #555555",
		"C#	c #9F9F9F",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # $ + % & * = - ; > , ' ) ! # # # @ + . ",
		". @ ~ { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { { ] ^ / ( _ : < [ } | 1 2 3 { { { ~ @ . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 5 6 7 8 9 0 a b c d e f g 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 h i j k l m n o p q r s t 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 5 u v w x y z A B C D E ~ 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 F F F 4 4 4 4 4 4 G H I J K L M N O P Q R S 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 ~ T U i h 4 4 4 4 V W X J Y Z `  ...+.@.#.3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.%.F &.6 4 4 4 *.=.-.;.>.,.'.).!.~.{.].3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.^./.(.4 4 V _.:.<.[.}.|.1.2.3.4.5.3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 F &.6.6.6.6.6.6.6.6.3 $.$.$.$.7.6.8.4 G 9.0.x a.b.c.d.e.f.g.h.i.4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 g j.k.k.k.k.k.k.k.k.>.$.$.$.$.$.l.3 *.5 (.m.n.o.p.!.q.r.s.q t.~ 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.u.S v.w.x.y.z.A.b B.C.D.E.7 t 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.F.8.i G.H.I.J.K.L.M.N.O.P.Q.4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.%.R.J S.K T.U.V.W.X.Y.Z.`.4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$. +6..+++@+#+$+%+&+*+=+-+;+3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.$.$.$.$.$.$.$.$.$.$.$.$.$.>+,+g % '+8 )+!+~+{+]+^+/+(+3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 _+:+<+<+<+<+<+<+<+<+[+$.$.$.$.$.}+3 V V |+:.1+2+3+4+5+6+7+8+9+3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 u 0+&.&.&.&.&.&.&.&.3 $.$.$.$.a+6.8.4 u b+c+x d+e+c.f+g+h+i+j+k+4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.$.$.l+/.(.4 4 h m+n+o+p+q+c.r+s+t+u+v+_+4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 3 $.w+x+y+5 4 4 4 h z+A+8 B+C+D+E+F+G+H+I+t 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 /.J+w.w.h 4 4 4 4 u K+L+M+N+)+O+q P+Q+R+>+S+4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 V *.*.4 4 4 4 4 4 F T+U+U+V+W+X+Y+_ Z+`+ @3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 0+.@+@@@#@$@%@&@)+*@=@-@3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 0+;@>@,@a.'@)@!@~@{@]@^@3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 F /@(@_@:@<@[@n }@|@1@2@3 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 (.3@c+4@d+5@6@4+3.7@e 8@U 4 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 G { &.] ] w.w.v.v.i { { 0+*.0+] 9@0@a@b@c@d@e@f@g@h@] h 4 4 { # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 { e+i@j@k@l@m@n@o@p@q@r@s@t@% * u@v@w@x@y@z@3@5 (.A@A@K+B@C@i # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 t D@E@F@q@G@H@I@# J@T+& 7./@; , x.K@R.v@L@M@N@O@l+P@Q@R@S@4 i # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 t T@l@E@F@q@G@p@I@_.@ T+_.7.U@; , ^ > V@v@L@W@N@X@w@Y@Z@R@`@v.# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 _+>.j@l@E@F@ #.#p@I@r@J@T+& [+U@; = ^ > V@v@+#@###$#^.O@b+%#v.# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 _+&#*#j@l@E@F@ #H@p@I@r@@ T+a+=#/@U@; ^ > R.-#M@N@O@$#w@Y@R@w.# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 ~ ;#}+*#j@l@E@F@ #H@p@I@r@@ + a+7.t@U@= x.V@v@+#@###X@b+P@w@w.# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 /.>#,#}+*#j@l@E@F@ #H@p@I@r@@ T+_.7./@; ^ K@R.-#M@'###X@w@$#] # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 g )#!#,#}+*#j@l@E@F@ #H@<+~#r@@ T+a+=#U@= ^ K@R.-#M@N@##X@X@&.# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 U {#D@l.,#]#*#j@l@E@m@G@p@I@_.r@! + 7.=#U@= ^ K@R.-#M@N@####&.# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 U ^#T@/#l.(#:+i@k@_#F@ #H@$ I@~#r@! + 7.=#U@= ^ K@R.-#M@N@@#y+# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 U :#<#[#]#}#}+|#j@l@1#m@G@H@p@<+~#r@! + 7.=#U@= ^ K@R.-#M@W@y+# . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 ,+2#/#<#[#!#,#:+i@k@_#1#m@ #G@H@$ # J@! + 7.=#& = x.K@R.-#3#t # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 ,+4#e+;#>.D@l.(#|#5#k@_#1#F@6#G@H@I@_.J@! _.7./@; , x.K@, 7#t # . ",
		". # { 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 ,+8#9#e+0#T@]#}#}+|#5#k@l@E@1#6#G@p@I@# J@T+& [+U@; * ^ K@a#_+# . ",
		". # { 4 4 4 G { &.&.&.] ] w.w.v.v.i i { { { 0+0+*.*.V 6.b#>+)#c#d#e#e+0#<#T@[#f#l.}#*#E@j@l@6#o@1# #J@$ + . s@% t@] # . ",
		". # { 4 4 4 { 0#(#(#|#j@g#h#6#i#1# #H@I@~#+ _.s@n+7.7.^ M@$#^.Q@b+Y@j#k#`@l#Z@m#S@x+h (.6 V 0+w.i ] _+g /.n#3 3 3 i # . ",
		". # { 4 4 4 y+l.o#m@i#1#G@# $ ~#J@@ _.s@! . a+/@U@= > p#^ x.u@q#-#L@W@@#r#+#N@P@b+w@s#t#`@S@B@A@4 (.5 h u F v.{ _+V # . ",
		". # { 4 4 4 t u#_#o#m@i#1#G@.#H@I@J@+ _.s@! . a+/@U@= > p#, x.7#q#-#-#L@W@r#+#N@P@b+Y@j#%#k#l#B@A@S@C@5 G u F v.~ V # . ",
		". # { 4 4 4 t D@l@_#o#m@6#1#G@.#H@~#J@@ + s@n+. a+7.U@= > p#^ a#7#q#9.-#L@W@r#'###O@b+^.s#j#K+l#B@A@4 C@6 G V F &.*.# . ",
		". # { 4 4 4 _+>.g#h#_#v#m@6#1#G@# H@I@J@@ _.s@n+. a+/@U@= > p#^ a#u@7#q#-#L@@#+#N@^.O@b+Y@s#t#`@S@Z@3@4 5 6 G V *.*.# . ",
		". # { 4 4 4 _+w#*#k@:+l@v#m@6#1# #o@.#I@J@@ + s@! . a+/@U@= > p#, ^ x.7#9.-#W@r#+#N@P@b+w@Y@j#t#`@B@A@3@4 5 6 G 0+0+# . ",
		". # { 4 4 4 ~ w#(#|#k@g#l@v#m@6#i# #G@.#I@~#@ + s@! . a+7.U@= > > p#^ u@q#-#L@W@r#'#N@P@b+w@Y@j#t#`@B@A@3@4 5 6 8.0+# . ",
		". # { 4 4 4 ~ x#,#(#|#k@g#l@v#o#6#i# #G@.#I@~#@ + s@! . a+7.U@= * > , a#7#q#-#L@@#r#'#N@P@b+w@Y@j#K+`@B@A@3@4 5 5 { # . ",
		". # { 4 4 4 /.y#]#!#(#|#k@g#l@v#o#6#i# #G@.#I@~#@ + s@! . a+/@U@= * p#^ a#7#q#-#L@@#r#'#N@P@b+w@s#j#K+`@B@A@3@4 (.{ # . ",
		". # { 4 4 4 /.e#z#]#,#(#|#k@:+l@v#m@6#i# #o@.#I@J@@ _.s@n+& 7./@U@= * p#, x.u@q#-#L@@#r#'#N@P@b+w@s#j#t#`@B@A@3@4 { # . ",
		". # { 4 4 4 /.A#f#z#]#,#(#*#g#h#_#v#m@6#1#G@# H@~#J@+ s@! T+& a+7./@= * > , x.7#q#-#L@W@r#+#N@P@b+w@Y@j#t#`@B@A@3@i # . ",
		". # { 4 4 4 /.A#f#}#z#!#,#|#*#g#l@_#o#m@i#q@G@.#I@~#@ + _.! n+. a+7.U@= * > , a#7#q#9.L@W@r#+#N@P@b+w@Y@j#t#`@B@A@i # . ",
		". # { 4 4 4 /.A#f#f#}#]#!#(#|#j@g#l@v#F@h#6#1#G@.#I@r@# + s@s@! . a+/@U@= * p#^ u@7#q#-#L@W@r#+#N@P@O@w@Y@j#t#`@Z@v.# . ",
		". # { 4 4 4 /.A#u#f#f#z#]#i@,#}+*#g#l@_#o#m@i# #G@.#p@r@@ + _.s@! . a+/@U@= * p#^ u@7#q#-#L@W@r#'#N@P@O@w@Y@s#t#j#v.# . ",
		". @ ~ { { { S B#<#<#<#>./#0#T@f#l.}#}+:+5#j@l@n@1#F@<+.#H@$ I@r@! T+. & a+=#p#; ^ V@3#q#v@+#M@N@X@$#^.t#K+`@m#3@x+/.@ . ",
		". + @ # # # _.% /@/@/@/@/@/@U@U@& & a+a+7.7.[+[+t@t@% % n+n+n+. . . C#C#s@s@! ! ! T++ + _._._.r@r@J@J@@ @ $ $ I@~#J@+ . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '2' then
		Image = {
		"60 60 430 2",
		"  	c None",
		". 	c #A0A0A0",
		"+ 	c #9B9B9B",
		"@ 	c #979797",
		"# 	c #939393",
		"$ 	c #959595",
		"% 	c #989898",
		"& 	c #9C9C9C",
		"* 	c #9F9F9F",
		"= 	c #A1A1A1",
		"- 	c #A2A2A2",
		"; 	c #A2A2A3",
		"> 	c #A4A4A4",
		", 	c #A5A5A6",
		"' 	c #A6A6A6",
		") 	c #999999",
		"! 	c #F7F7F7",
		"~ 	c #EEEEEE",
		"{ 	c #F1F1F1",
		"] 	c #C4C4C5",
		"^ 	c #B2B2B0",
		"/ 	c #9F9FA0",
		"( 	c #8C8D8D",
		"_ 	c #8E8D8E",
		": 	c #90908F",
		"< 	c #91908F",
		"[ 	c #8E8E8B",
		"} 	c #797877",
		"| 	c #6D6C6B",
		"1 	c #70706F",
		"2 	c #F9F9F9",
		"3 	c #E2E2E2",
		"4 	c #E5E5E5",
		"5 	c #DDDDDD",
		"6 	c #B3B3B2",
		"7 	c #9A9C9A",
		"8 	c #999997",
		"9 	c #959594",
		"0 	c #91928F",
		"a 	c #868584",
		"b 	c #757573",
		"c 	c #727272",
		"d 	c #949493",
		"e 	c #F0F0F0",
		"f 	c #E3E3E3",
		"g 	c #BFBFBE",
		"h 	c #A5A7A6",
		"i 	c #9C9C9B",
		"j 	c #989A99",
		"k 	c #929190",
		"l 	c #878786",
		"m 	c #787677",
		"n 	c #747473",
		"o 	c #80807F",
		"p 	c #AEAEAD",
		"q 	c #EDEDEE",
		"r 	c #E4E4E4",
		"s 	c #DFDFDF",
		"t 	c #B3B4B3",
		"u 	c #A09FA0",
		"v 	c #979795",
		"w 	c #8A8A8A",
		"x 	c #7A7A79",
		"y 	c #727270",
		"z 	c #808180",
		"A 	c #989896",
		"B 	c #9C9B9A",
		"C 	c #EFEFEF",
		"D 	c #E6E6E6",
		"E 	c #C1C1C1",
		"F 	c #A4A6A4",
		"G 	c #9C9E9C",
		"H 	c #7F7E7F",
		"I 	c #717170",
		"J 	c #7D7F7F",
		"K 	c #9B9996",
		"L 	c #747372",
		"M 	c #F2F2F2",
		"N 	c #E8E8E8",
		"O 	c #BCBCBC",
		"P 	c #A8A8A9",
		"Q 	c #A6A5A6",
		"R 	c #999B9A",
		"S 	c #888786",
		"T 	c #747474",
		"U 	c #7C7D7D",
		"V 	c #919191",
		"W 	c #9D9C99",
		"X 	c #8C8B89",
		"Y 	c #656563",
		"Z 	c #F5F5F5",
		"` 	c #C3C3C1",
		" .	c #ACAEAC",
		"..	c #A3A3A3",
		"+.	c #7D7F7D",
		"@.	c #787979",
		"#.	c #919192",
		"$.	c #7E7E7C",
		"%.	c #636362",
		"&.	c #F5F5F6",
		"*.	c #B4B4B4",
		"=.	c #AFAFAF",
		"-.	c #A0A2A0",
		";.	c #8F9090",
		">.	c #7D7D7D",
		",.	c #8C8D8C",
		"'.	c #939391",
		").	c #969794",
		"!.	c #898887",
		"~.	c #787776",
		"{.	c #686866",
		"].	c #C5C5C5",
		"^.	c #909090",
		"/.	c #929392",
		"(.	c #949392",
		"_.	c #91918E",
		":.	c #7C7D7A",
		"<.	c #737372",
		"[.	c #787877",
		"}.	c #DEDEDE",
		"|.	c #B4B4B3",
		"1.	c #90908E",
		"2.	c #838281",
		"3.	c #757574",
		"4.	c #737373",
		"5.	c #9A9A9A",
		"6.	c #A4A5A6",
		"7.	c #999899",
		"8.	c #868683",
		"9.	c #747475",
		"0.	c #848483",
		"a.	c #B1B1B2",
		"b.	c #DCDCDC",
		"c.	c #9EA09E",
		"d.	c #949694",
		"e.	c #878788",
		"f.	c #777776",
		"g.	c #717172",
		"h.	c #848484",
		"i.	c #9A9996",
		"j.	c #8F8F8E",
		"k.	c #EFEFF0",
		"l.	c #E7E7E7",
		"m.	c #BAB9B9",
		"n.	c #A5A6A5",
		"o.	c #9D9D9D",
		"p.	c #7C7C7C",
		"q.	c #717171",
		"r.	c #818182",
		"s.	c #979796",
		"t.	c #999795",
		"u.	c #6F6E6D",
		"v.	c #F3F3F3",
		"w.	c #E9E9E9",
		"x.	c #B8BAB8",
		"y.	c #AAABAB",
		"z.	c #858585",
		"A.	c #737473",
		"B.	c #828183",
		"C.	c #929291",
		"D.	c #9C9C98",
		"E.	c #878785",
		"F.	c #646362",
		"G.	c #B7B7B7",
		"H.	c #ADAEAF",
		"I.	c #A2A3A2",
		"J.	c #929492",
		"K.	c #949594",
		"L.	c #969594",
		"M.	c #959492",
		"N.	c #7B7C7B",
		"O.	c #656564",
		"P.	c #B4B4B2",
		"Q.	c #A1A0A0",
		"R.	c #8D8D8D",
		"S.	c #7F7E7E",
		"T.	c #939392",
		"U.	c #959693",
		"V.	c #858683",
		"W.	c #6B6B6A",
		"X.	c #F4F4F4",
		"Y.	c #D1D1D1",
		"Z.	c #AEADAE",
		"`.	c #909191",
		" +	c #8E8C8B",
		".+	c #7A7978",
		"++	c #727271",
		"@+	c #838282",
		"#+	c #B8B8B8",
		"$+	c #A2A3A3",
		"%+	c #989796",
		"&+	c #8E8D8C",
		"*+	c #80807D",
		"=+	c #767775",
		"-+	c #A3A3A2",
		";+	c #C2C2C2",
		">+	c #A1A3A1",
		",+	c #9B9B9C",
		"'+	c #989897",
		")+	c #8E8E8D",
		"!+	c #818180",
		"~+	c #777777",
		"{+	c #8B8B8A",
		"]+	c #AFAFAE",
		"^+	c #D5D5D5",
		"/+	c #AAAAAC",
		"(+	c #9E9E9E",
		"_+	c #9E9F9E",
		":+	c #949492",
		"<+	c #858584",
		"[+	c #888988",
		"}+	c #9A9A96",
		"|+	c #868685",
		"1+	c #797978",
		"2+	c #878889",
		"3+	c #92908E",
		"4+	c #6C6C6B",
		"5+	c #F3F3F4",
		"6+	c #F8F8F8",
		"7+	c #FFFFFF",
		"8+	c #B9B9B9",
		"9+	c #A9ABAB",
		"0+	c #A2A4A2",
		"a+	c #979695",
		"b+	c #818281",
		"c+	c #898A8A",
		"d+	c #9B9A97",
		"e+	c #82827F",
		"f+	c #5A5A5A",
		"g+	c #000000",
		"h+	c #B1B2B1",
		"i+	c #ACADAC",
		"j+	c #797A7B",
		"k+	c #828182",
		"l+	c #959491",
		"m+	c #8F8D8D",
		"n+	c #797977",
		"o+	c #676766",
		"p+	c #BBBBBB",
		"q+	c #ACADAE",
		"r+	c #9B9D9D",
		"s+	c #8A8B8B",
		"t+	c #828383",
		"u+	c #909290",
		"v+	c #949292",
		"w+	c #80817E",
		"x+	c #DADADA",
		"y+	c #989A9A",
		"z+	c #949394",
		"A+	c #919390",
		"B+	c #8F8F8F",
		"C+	c #888886",
		"D+	c #767675",
		"E+	c #EDEDED",
		"F+	c #ECECEC",
		"G+	c #BBB9B9",
		"H+	c #A0A09D",
		"I+	c #8B8D8B",
		"J+	c #878886",
		"K+	c #828180",
		"L+	c #737371",
		"M+	c #676764",
		"N+	c #696969",
		"O+	c #9D9D9C",
		"P+	c #ECECED",
		"Q+	c #616161",
		"R+	c #818181",
		"S+	c #878787",
		"T+	c #8B8B8B",
		"U+	c #8E8E8E",
		"V+	c #AAAAAA",
		"W+	c #CBCBCB",
		"X+	c #CACACA",
		"Y+	c #D1D1D2",
		"Z+	c #D8D8D8",
		"`+	c #D7D7D7",
		" @	c #E1E1E1",
		".@	c #676767",
		"+@	c #7F7F7F",
		"@@	c #888888",
		"#@	c #8C8C8C",
		"$@	c #A7A7A7",
		"%@	c #A5A5A5",
		"&@	c #A9A9A9",
		"*@	c #ADADAD",
		"=@	c #B2B2B2",
		"-@	c #B0B0B0",
		";@	c #B5B5B5",
		">@	c #B3B3B3",
		",@	c #BEBEBE",
		"'@	c #C7C7C7",
		")@	c #CFCFCF",
		"!@	c #D9D9D9",
		"~@	c #A8A8A8",
		"{@	c #B1B1B1",
		"]@	c #C0C0C0",
		"^@	c #C9C9C9",
		"/@	c #CDCDCD",
		"(@	c #DBDBDB",
		"_@	c #D6D6D6",
		":@	c #F6F6F6",
		"<@	c #636363",
		"[@	c #929292",
		"}@	c #ACACAC",
		"|@	c #BFBFBF",
		"1@	c #C4C4C4",
		"2@	c #C8C8C8",
		"3@	c #CCCCCC",
		"4@	c #CECECE",
		"5@	c #5E5E5E",
		"6@	c #787878",
		"7@	c #BDBDBD",
		"8@	c #EAEAEA",
		"9@	c #EBEBEB",
		"0@	c #5F5F5F",
		"a@	c #3B3B3B",
		"b@	c #202020",
		"c@	c #767676",
		"d@	c #C6C6C6",
		"e@	c #161616",
		"f@	c #010101",
		"g@	c #4F4F4F",
		"h@	c #949494",
		"i@	c #FAFAFA",
		"j@	c #4B4B4B",
		"k@	c #D4D4D4",
		"l@	c #4C4C4C",
		"m@	c #666666",
		"n@	c #757575",
		"o@	c #7A7A7A",
		"p@	c #808080",
		"q@	c #969696",
		"r@	c #AEAEAE",
		"s@	c #464646",
		"t@	c #646464",
		"u@	c #686868",
		"v@	c #707070",
		"w@	c #797979",
		"x@	c #898989",
		"y@	c #FBFBFB",
		"z@	c #838383",
		"A@	c #FEFEFE",
		"B@	c #474747",
		"C@	c #515151",
		"D@	c #353535",
		"E@	c #484848",
		"F@	c #7E7E7E",
		"G@	c #868686",
		"H@	c #B6B6B6",
		"I@	c #FDFDFD",
		"J@	c #252525",
		"K@	c #0F0F0F",
		"L@	c #424242",
		"M@	c #5B5B5B",
		"N@	c #656565",
		"O@	c #ABABAB",
		"P@	c #242424",
		"Q@	c #FCFCFC",
		"R@	c #454545",
		"S@	c #545454",
		"T@	c #595959",
		"U@	c #575757",
		"V@	c #5C5C5C",
		"W@	c #6A6A6A",
		"X@	c #6E6E6E",
		"Y@	c #6C6C6C",
		"Z@	c #6F6F6F",
		"`@	c #828282",
		" #	c #0A0A0A",
		".#	c #090909",
		"+#	c #101010",
		"@#	c #141414",
		"##	c #222222",
		"$#	c #272727",
		"%#	c #2F2F2F",
		"&#	c #393939",
		"*#	c #414141",
		"=#	c #3F3F3F",
		"-#	c #4D4D4D",
		";#	c #585858",
		">#	c #5D5D5D",
		",#	c #C3C3C3",
		"'#	c #D2D2D2",
		")#	c #040404",
		"!#	c #2D2D2D",
		"~#	c #333333",
		"{#	c #313131",
		"]#	c #363636",
		"^#	c #434343",
		"/#	c #494949",
		"(#	c #555555",
		"_#	c #535353",
		":#	c #D3D3D3",
		"<#	c #D0D0D0",
		"[#	c #404040",
		"}#	c #2B2B2B",
		"|#	c #505050",
		"1#	c #626262",
		"2#	c #181818",
		"3#	c #232323",
		"4#	c #282828",
		"5#	c #2C2C2C",
		"6#	c #4A4A4A",
		"7#	c #131313",
		"8#	c #191919",
		"9#	c #373737",
		"0#	c #343434",
		"a#	c #0E0E0E",
		"b#	c #171717",
		"c#	c #2E2E2E",
		"d#	c #323232",
		"e#	c #444444",
		"f#	c #262626",
		"g#	c #6D6D6D",
		"h#	c #080808",
		"i#	c #292929",
		"j#	c #050505",
		"k#	c #0D0D0D",
		"l#	c #565656",
		"m#	c #030303",
		"n#	c #151515",
		"o#	c #121212",
		"p#	c #383838",
		"q#	c #0B0B0B",
		"r#	c #1A1A1A",
		"s#	c #303030",
		"t#	c #212121",
		"u#	c #1B1B1B",
		"v#	c #3A3A3A",
		"w#	c #BABABA",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # $ % & * = - - ; > , ' . ) # # # @ + . ",
		". @ ! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { ] ^ / ( _ : < [ } | 1 2 ~ ~ ~ ! @ . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 4 5 6 - 7 8 9 0 a b c d e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f f g h i j k l m n o p q 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 r s t = u v w x y z A B C 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 D E ' F G : H I J d K L M 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N O P Q R S T U V W X Y Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N `  ...$ +.@.#.9 A $.%.&.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N *.=.-.;.>.,.'.).!.~.{.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 D ].p * ^./.d (._.:.<.[.M 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 r }.|.- & 8 9 1.2.3.4.5.C 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f f E 6.i 7.< 8.3.9.0.a.~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 4 b.=.. c.d.e.f.g.h.i.j.k.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 l.m.' n.o.j.p.q.r.s.t.u.v.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 w.x.y.F % z.A.B.C.D.E.F.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 w.G.H.I.J.U U K.L.M.N.O.&.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N P.=.Q.R.S.: T.U.V.3.W.X.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 D Y.Z.* `.# d '. +.+++@+{ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f 3 #+$+5.%+d &+*+<.=+-+~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f f ;+>+,+'+)+!+c ~+{+]+~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 4 ^+/+(+_+:+<+b T [+}+|+e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 l.*.> > + {+1+c 2+'+3+4+5+3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 w.6+7+7+7+7+7+6+w.3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 w.8+9+0+a+b+T c+T.d+e+O.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 e f+g+g+g+g+g+f+e 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 w.h+i+. ;.j+k+9 l+m+n+o+Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 l.p+q+r+s+t+u+^.v+w+<.++v.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 4 x+Z.y+V z+A+B+C+D+c j.e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 N ~ v.M M { { e e C ~ ~ E+F+E+w.G+H+/.I+J+K+L+M+N+O+P+f 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 ~ Q+~+>.p.R+S+z.T+^.U+) (+..- V+*.G.] W+X+Y.Y+Z+x+Z+b.`+b. @C # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 Z .@+@@@U+#@V $ # % & $@%@&@*@=@-@;@>@,@O E ].X+'@W+)@!@5 3 C # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 Z N+R++@@@U+#@^.$ 5.@ & 5.%@~@*@=@{@=.*.,@O ]@].^@/@Y.(@!@_@e # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 :@<@>.R++@@@R.[@^.$ ) % & $@> ~@*@}@{@=.*.,@;+|@1@2@3@X+4@Z+e # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 6+q.g+g+g+g+g+q.6+3 3 3 3 3 :@5@6@>.R++@@@R.V ^.$ ) @ & ' V+&@~@*@{@=.>@7@E ].X+2@/@Y.!@{ # . ",
		". # ~ 3 3 3 3 3 3 8@! 7+7+7+h.g+g+g+g+g+h.7+7+7+6+9@3 ! 0@T 6@>.R++@@@R.V ^.$ ) @ + ' %@..~@}@-@*.,@;+|@1@^@4@W+/@{ # . ",
		". # ~ 3 3 3 3 3 3 8@a@g+g+g+g+g+g+g+g+g+g+g+g+g+b@F+3 6+f+c@T 6@>.R++@@@R.V ^.$ ) @ & 5.%@&@*@{@;@>@7@E d@1@^@/@2@M # . ",
		". # ~ 3 3 3 3 3 3 8@2 e@g+g+g+g+g+g+g+g+g+g+g+f@{ F+3 2 g@c c@T 6@>.R++@@@R.V B+h@) @ & ' V+~@}@{@;@>@7@E ].1@^@^@v.# . ",
		". # ~ 3 3 3 3 3 3 3 C E+g+g+g+g+g+g+g+g+g+g+g+}.{ 3 3 i@j@.@q.c@4.6@>.R++@S+#@^.$ 5.) o.+ %@V+~@}@{@;@>@7@E ].1@1@v.# . ",
		". # ~ 3 3 3 3 3 3 3 f M k@g+g+g+g+g+g+g+g+g+|@Z r 3 3 i@l@N+m@q.n@o@~+p.p@@@R.V q@$ h@) o.+ %@V+~@}@{@;@>@7@E ].|@X.# . ",
		". # ~ 3 3 3 3 3 3 3 3 r :@r@g+g+g+g+g+g+g+# 2 4 3 3 3 i@s@t@u@4.v@T w@>.R+x@S+#@V ^.B+h@) o.+ %@V+~@}@{@;@>@7@E ]@X.# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 D y@z@g+g+g+g+g+t@A@l.3 3 3 3 y@B@m@t@u@c c@o@~+p.p@x@S+R.#@V q@# % o.+ %@V+$@}@-@;@>@7@p+Z # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 N 7+C@g+g+g+D@7+8@3 3 3 3 3 y@E@Q+0@<@.@q.n@w@F@p.p@x@@@G@#@V $ 5.% o.5.%@&@*@=@-@;@=@H@Z # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 9@I@J@g+K@! F+3 3 3 3 3 3 y@L@M@Q+N@N+4.v@T w@F@p.R++@x@G@#@^.$ # % & $@> ~@*@O@{@;@#+:@# . ",
		". # ~ 3 3 3 ~ 2 7+7+7+7+7+7+7+7+7+P@I@7+Q@y@i@2 6+! ! 7+R@S@T@U@V@0@W@X@Y@q.Z@T 6@c@+@z.`@S+w B+R.V + ) o.- * > > v.# . ",
		". # ~ 3 3 3 i@g+ #.#+#e@@###$#%#&#*#B@L@=#-#j@C@;#5@>#Y@z@x@B+$ # ) * o...= =.}@=@#+7@,#]@/@'#Z+_@b.3 N D v.6+A@y@e # . ",
		". # ~ 3 3 3 7+)#$#!#~#{#]#^#B@R@j@/#g@(#_#T@N@W@u@X@4.q.~+n@`@S+#@T+V ^.q@h@5.' O@~@r@>@#+d@,#2@/@:#'#<#^+x+l.r F+F+# . ",
		". # ~ 3 3 3 7+g+##$#!#~#{#]#L@[#s@j@C@g@(#_#;#t@W@u@X@4.c 6@n@`@S+R.#@w V q@h@) %@V+-@;@p+{@H@,#2@d@3@'#Z+^+x+l.~ E+# . ",
		". # ~ 3 3 3 7+g+P@##$#!#}#{#]#L@[#R@j@/#|#(#f+;#N@1#u@X@4.c ~+h.R+S+G@#@T+V q@+ % %@V+$@r@*.8+H@,#2@4@W+Y.`+b.x+N ~ # . ",
		". # ~ 3 3 3 7+g+2#J@3#4#!#5#{#]#^#*#s@j@6#g@(#f+;#N@W@u@X@4.q.~+h.z@R+S+#@w ^.$ 5.$@> V+=.*@>@#+].;+'@/@:#Y.`+b.x+C # . ",
		". # ~ 3 3 3 7+g+7#8#e@3#4#!#5#{#9#0#*#s@l@6#|#(#_#;#N@W@u@X@4.q.6@c@T R+G@#@V @ h@) ' O@&@=.;@=@#+1@^@'@/@'#Y.`+b.e # . ",
		". # ~ 3 3 3 7+g+a#@#8#b#3#4#c#5#d#9#D@*#s@e#6#|#(#_#;#N@<@u@X@T 4.q.c@z@S+R.T+V q@+ ) %@O@&@=.*.=@G.,#^@'@/@'#Y.^+{ # . ",
		". # ~ 3 3 3 7+g++#a#@#8#b#3#4#f#5#d#9#D@*#B@R@6#|#(#_#T@N@<@u@X@g#4.6@h.R+S+#@T+^.q@+ ) %@O@&@=.*.8+G.,#^@'@/@'#4@{ # . ",
		". # ~ 3 3 3 7+g+ #h#a#@#8#b#3#i#f#5#d#9#D@*#B@e#6#|#(#_#;#t@N+u@X@g#c ~+h.`@S+#@T+^.q@+ ) %@O@&@r@*.8+G.1@^@'@/@<#M # . ",
		". # ~ 3 3 3 7+g+j# #+#a#@#8#e@3#4#c#5#d#9#0#*#s@l@/#g@(#f+m@t@N+u@X@g#c 6@n@`@S+#@T+^.q@+ ) ' O@&@r@*.=@G.1@^@'@^@M # . ",
		". # ~ 3 3 3 7+g+g+)# #K@k#7#2#J@##4#!#}#{#]#^#[#R@j@|#l#S@C@m@t@<@N+X@g#4.6@n@`@S+R.T+V q@h@) ' O@&@=.*.=@G.1@^@;+v.# . ",
		". # ~ 3 3 3 7+g+g+j#m#.#K@n#o#b#P@##$#!#~#p#]#L@B@e#6#|#g@S@f+;#N@<@u@X@g#4.6@h.R+S+z.T+V q@h@) ' O@&@=.*.=@G.1@1@X.# . ",
		". # ~ 3 3 3 7+g+g+g+j#q#h#a#@#r#2#P@i#%#J@}#s#D@*#B@l@^#|#l#(#_#T@N@W@u@X@g#c ~+z@R+S+R.T+V q@h@) ' > &@=.;@>@#+,@Z # . ",
		". # ~ 3 3 3 7+g+g+g+g+j# #+#K@k#o#b#P@t#$#!#d#9#D@*#=#l@6#|#g@(#_#;#N@W@u@X@g#c ~+z@R+S+#@T+V q@& ) ' > &@=.*@=@{@:@# . ",
		". @ ! ~ ~ ~ 7+g+g+g+g+g+g+g+g+g+g+g+g+ #+#K@n#u###b@c#0#d#v#p#=#s@e#6#;#l#>#t@1#u@X@p.o@R+@@G@R.# [@% %@}@V+{@G.8+Q@@ . ",
		". + @ # # # = -@|@|@|@,@,@7@7@O p+w#w##+G.G.H@;@*.>@=@{@{@-@-@=.r@r@*@}@O@V+V+&@~@$@' %@> > ..- - = . * (+o.o.& % 5.+ . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	elseif pic == '3' then
		Image = {
		"60 60 437 2",
		"  	c None",
		". 	c #A0A0A0",
		"+ 	c #9B9B9B",
		"@ 	c #979797",
		"# 	c #939393",
		"$ 	c #959595",
		"% 	c #989898",
		"& 	c #9C9C9C",
		"* 	c #9F9F9F",
		"= 	c #A1A1A1",
		"- 	c #A2A2A2",
		"; 	c #A2A2A3",
		"> 	c #A4A4A4",
		", 	c #A5A5A6",
		"' 	c #A6A6A6",
		") 	c #999999",
		"! 	c #F7F7F7",
		"~ 	c #EEEEEE",
		"{ 	c #F1F1F1",
		"] 	c #C4C4C5",
		"^ 	c #B2B2B0",
		"/ 	c #9F9FA0",
		"( 	c #8C8D8D",
		"_ 	c #8E8D8E",
		": 	c #90908F",
		"< 	c #91908F",
		"[ 	c #8E8E8B",
		"} 	c #797877",
		"| 	c #6D6C6B",
		"1 	c #70706F",
		"2 	c #F9F9F9",
		"3 	c #E2E2E2",
		"4 	c #E5E5E5",
		"5 	c #DDDDDD",
		"6 	c #B3B3B2",
		"7 	c #9A9C9A",
		"8 	c #999997",
		"9 	c #959594",
		"0 	c #91928F",
		"a 	c #868584",
		"b 	c #757573",
		"c 	c #727272",
		"d 	c #949493",
		"e 	c #F0F0F0",
		"f 	c #E3E3E3",
		"g 	c #BFBFBE",
		"h 	c #A5A7A6",
		"i 	c #9C9C9B",
		"j 	c #989A99",
		"k 	c #929190",
		"l 	c #878786",
		"m 	c #787677",
		"n 	c #747473",
		"o 	c #80807F",
		"p 	c #AEAEAD",
		"q 	c #EDEDEE",
		"r 	c #E4E4E4",
		"s 	c #DFDFDF",
		"t 	c #B3B4B3",
		"u 	c #A09FA0",
		"v 	c #979795",
		"w 	c #8A8A8A",
		"x 	c #7A7A79",
		"y 	c #727270",
		"z 	c #808180",
		"A 	c #989896",
		"B 	c #9C9B9A",
		"C 	c #EFEFEF",
		"D 	c #E6E6E6",
		"E 	c #C1C1C1",
		"F 	c #A4A6A4",
		"G 	c #9C9E9C",
		"H 	c #7F7E7F",
		"I 	c #717170",
		"J 	c #7D7F7F",
		"K 	c #9B9996",
		"L 	c #747372",
		"M 	c #F2F2F2",
		"N 	c #E8E8E8",
		"O 	c #BCBCBC",
		"P 	c #A8A8A9",
		"Q 	c #A6A5A6",
		"R 	c #999B9A",
		"S 	c #888786",
		"T 	c #747474",
		"U 	c #7C7D7D",
		"V 	c #919191",
		"W 	c #9D9C99",
		"X 	c #8C8B89",
		"Y 	c #656563",
		"Z 	c #F5F5F5",
		"` 	c #E9E9E9",
		" .	c #F8F8F8",
		"..	c #FFFFFF",
		"+.	c #C3C3C1",
		"@.	c #ACAEAC",
		"#.	c #A3A3A3",
		"$.	c #7D7F7D",
		"%.	c #787979",
		"&.	c #919192",
		"*.	c #7E7E7C",
		"=.	c #636362",
		"-.	c #F5F5F6",
		";.	c #5A5A5A",
		">.	c #000000",
		",.	c #B4B4B4",
		"'.	c #AFAFAF",
		").	c #A0A2A0",
		"!.	c #8F9090",
		"~.	c #7D7D7D",
		"{.	c #8C8D8C",
		"].	c #939391",
		"^.	c #969794",
		"/.	c #898887",
		"(.	c #787776",
		"_.	c #686866",
		":.	c #717171",
		"<.	c #C5C5C5",
		"[.	c #909090",
		"}.	c #929392",
		"|.	c #949392",
		"1.	c #91918E",
		"2.	c #7C7D7A",
		"3.	c #737372",
		"4.	c #787877",
		"5.	c #DEDEDE",
		"6.	c #B4B4B3",
		"7.	c #90908E",
		"8.	c #838281",
		"9.	c #757574",
		"0.	c #737373",
		"a.	c #9A9A9A",
		"b.	c #A4A5A6",
		"c.	c #999899",
		"d.	c #868683",
		"e.	c #747475",
		"f.	c #848483",
		"g.	c #B1B1B2",
		"h.	c #DCDCDC",
		"i.	c #9EA09E",
		"j.	c #949694",
		"k.	c #878788",
		"l.	c #777776",
		"m.	c #717172",
		"n.	c #848484",
		"o.	c #9A9996",
		"p.	c #8F8F8E",
		"q.	c #EFEFF0",
		"r.	c #E7E7E7",
		"s.	c #BAB9B9",
		"t.	c #A5A6A5",
		"u.	c #9D9D9D",
		"v.	c #7C7C7C",
		"w.	c #818182",
		"x.	c #979796",
		"y.	c #999795",
		"z.	c #6F6E6D",
		"A.	c #F3F3F3",
		"B.	c #B8BAB8",
		"C.	c #AAABAB",
		"D.	c #858585",
		"E.	c #737473",
		"F.	c #828183",
		"G.	c #929291",
		"H.	c #9C9C98",
		"I.	c #878785",
		"J.	c #646362",
		"K.	c #B7B7B7",
		"L.	c #ADAEAF",
		"M.	c #A2A3A2",
		"N.	c #929492",
		"O.	c #949594",
		"P.	c #969594",
		"Q.	c #959492",
		"R.	c #7B7C7B",
		"S.	c #656564",
		"T.	c #B4B4B2",
		"U.	c #A1A0A0",
		"V.	c #8D8D8D",
		"W.	c #7F7E7E",
		"X.	c #939392",
		"Y.	c #959693",
		"Z.	c #858683",
		"`.	c #6B6B6A",
		" +	c #F4F4F4",
		".+	c #EAEAEA",
		"++	c #D1D1D1",
		"@+	c #AEADAE",
		"#+	c #909191",
		"$+	c #8E8C8B",
		"%+	c #7A7978",
		"&+	c #727271",
		"*+	c #838282",
		"=+	c #3B3B3B",
		"-+	c #202020",
		";+	c #B8B8B8",
		">+	c #A2A3A3",
		",+	c #989796",
		"'+	c #8E8D8C",
		")+	c #80807D",
		"!+	c #767775",
		"~+	c #A3A3A2",
		"{+	c #161616",
		"]+	c #010101",
		"^+	c #C2C2C2",
		"/+	c #A1A3A1",
		"(+	c #9B9B9C",
		"_+	c #989897",
		":+	c #8E8E8D",
		"<+	c #818180",
		"[+	c #777777",
		"}+	c #8B8B8A",
		"|+	c #AFAFAE",
		"1+	c #EDEDED",
		"2+	c #D5D5D5",
		"3+	c #AAAAAC",
		"4+	c #9E9E9E",
		"5+	c #9E9F9E",
		"6+	c #949492",
		"7+	c #858584",
		"8+	c #888988",
		"9+	c #9A9A96",
		"0+	c #868685",
		"a+	c #D4D4D4",
		"b+	c #BFBFBF",
		"c+	c #797978",
		"d+	c #878889",
		"e+	c #92908E",
		"f+	c #6C6C6B",
		"g+	c #F3F3F4",
		"h+	c #F6F6F6",
		"i+	c #AEAEAE",
		"j+	c #B9B9B9",
		"k+	c #A9ABAB",
		"l+	c #A2A4A2",
		"m+	c #979695",
		"n+	c #818281",
		"o+	c #898A8A",
		"p+	c #9B9A97",
		"q+	c #82827F",
		"r+	c #FBFBFB",
		"s+	c #838383",
		"t+	c #646464",
		"u+	c #FEFEFE",
		"v+	c #B1B2B1",
		"w+	c #ACADAC",
		"x+	c #797A7B",
		"y+	c #828182",
		"z+	c #959491",
		"A+	c #8F8D8D",
		"B+	c #797977",
		"C+	c #676766",
		"D+	c #515151",
		"E+	c #353535",
		"F+	c #BBBBBB",
		"G+	c #ACADAE",
		"H+	c #9B9D9D",
		"I+	c #8A8B8B",
		"J+	c #828383",
		"K+	c #909290",
		"L+	c #949292",
		"M+	c #80817E",
		"N+	c #EBEBEB",
		"O+	c #FDFDFD",
		"P+	c #252525",
		"Q+	c #0F0F0F",
		"R+	c #ECECEC",
		"S+	c #DADADA",
		"T+	c #989A9A",
		"U+	c #949394",
		"V+	c #919390",
		"W+	c #8F8F8F",
		"X+	c #888886",
		"Y+	c #767675",
		"Z+	c #FAFAFA",
		"`+	c #C0BEBF",
		" @	c #A4A4A1",
		".@	c #969796",
		"+@	c #8E908F",
		"@@	c #8A8B89",
		"#@	c #858382",
		"$@	c #767673",
		"%@	c #696966",
		"&@	c #6A6A6B",
		"*@	c #9E9E9C",
		"=@	c #ECECED",
		"-@	c #E1E1E1",
		";@	c #090909",
		">@	c #323232",
		",@	c #3A3A3A",
		"'@	c #4E4E4E",
		")@	c #595959",
		"!@	c #565656",
		"~@	c #555555",
		"{@	c #5C5C5C",
		"]@	c #6D6D6D",
		"^@	c #7E7E7E",
		"/@	c #888888",
		"(@	c #C1C2C2",
		"_@	c #CCCCCC",
		":@	c #D2D2D2",
		"<@	c #E0E0E0",
		"[@	c #D9D9D9",
		"}@	c #141414",
		"|@	c #3C3C3C",
		"1@	c #575757",
		"2@	c #535353",
		"3@	c #616161",
		"4@	c #696969",
		"5@	c #707070",
		"6@	c #7F7F7F",
		"7@	c #868686",
		"8@	c #ACACAC",
		"9@	c #A8A8A8",
		"0@	c #B1B1B1",
		"a@	c #C0C0C0",
		"b@	c #BDBDBD",
		"c@	c #C4C4C4",
		"d@	c #CACACA",
		"e@	c #DBDBDB",
		"f@	c #404040",
		"g@	c #5B5B5B",
		"h@	c #636363",
		"i@	c #6B6B6B",
		"j@	c #686868",
		"k@	c #6C6C6C",
		"l@	c #949494",
		"m@	c #B0B0B0",
		"n@	c #C7C7C7",
		"o@	c #CDCDCD",
		"p@	c #0D0D0D",
		"q@	c #383838",
		"r@	c #3F3F3F",
		"s@	c #5D5D5D",
		"t@	c #828282",
		"u@	c #8C8C8C",
		"v@	c #929292",
		"w@	c #B3B3B3",
		"x@	c #B6B6B6",
		"y@	c #BEBEBE",
		"z@	c #C9C9C9",
		"A@	c #040404",
		"B@	c #303030",
		"C@	c #4D4D4D",
		"D@	c #6F6F6F",
		"E@	c #818181",
		"F@	c #AAAAAA",
		"G@	c #C6C6C6",
		"H@	c #060606",
		"I@	c #282828",
		"J@	c #2B2B2B",
		"K@	c #ABABAB",
		"L@	c #B2B2B2",
		"M@	c #242424",
		"N@	c #626262",
		"O@	c #6A6A6A",
		"P@	c #121212",
		"Q@	c #4C4C4C",
		"R@	c #545454",
		"S@	c #6E6E6E",
		"T@	c #808080",
		"U@	c #878787",
		"V@	c #111111",
		"W@	c #232323",
		"X@	c #2A2A2A",
		"Y@	c #2F2F2F",
		"Z@	c #373737",
		"`@	c #3D3D3D",
		" #	c #656565",
		".#	c #262626",
		"+#	c #212121",
		"@#	c #292929",
		"##	c #313131",
		"$#	c #505050",
		"%#	c #4B4B4B",
		"&#	c #0C0C0C",
		"*#	c #363636",
		"=#	c #4F4F4F",
		"-#	c #8B8B8B",
		";#	c #A9A9A9",
		">#	c #070707",
		",#	c #393939",
		"'#	c #8E8E8E",
		")#	c #969696",
		"!#	c #0E0E0E",
		"~#	c #151515",
		"{#	c #606060",
		"]#	c #FCFCFC",
		"^#	c #1B1B1B",
		"/#	c #181818",
		"(#	c #424242",
		"_#	c #474747",
		":#	c #7B7B7B",
		"<#	c #787878",
		"[#	c #0A0A0A",
		"}#	c #101010",
		"|#	c #222222",
		"1#	c #272727",
		"2#	c #414141",
		"3#	c #585858",
		"4#	c #5E5E5E",
		"5#	c #BABABA",
		"6#	c #CECECE",
		"7#	c #CBCBCB",
		"8#	c #D8D8D8",
		"9#	c #2D2D2D",
		"0#	c #333333",
		"a#	c #434343",
		"b#	c #454545",
		"c#	c #494949",
		"d#	c #757575",
		"e#	c #C3C3C3",
		"f#	c #C8C8C8",
		"g#	c #D3D3D3",
		"h#	c #D0D0D0",
		"i#	c #464646",
		"j#	c #A5A5A5",
		"k#	c #B5B5B5",
		"l#	c #A7A7A7",
		"m#	c #D7D7D7",
		"n#	c #2C2C2C",
		"o#	c #4A4A4A",
		"p#	c #ADADAD",
		"q#	c #131313",
		"r#	c #191919",
		"s#	c #343434",
		"t#	c #767676",
		"u#	c #171717",
		"v#	c #2E2E2E",
		"w#	c #444444",
		"x#	c #080808",
		"y#	c #050505",
		"z#	c #666666",
		"A#	c #030303",
		"B#	c #0B0B0B",
		"C#	c #1A1A1A",
		"D#	c #7A7A7A",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ",
		". + @ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # $ % & * = - - ; > , ' . ) # # # @ + . ",
		". @ ! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ { ] ^ / ( _ : < [ } | 1 2 ~ ~ ~ ! @ . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 4 5 6 - 7 8 9 0 a b c d e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f f g h i j k l m n o p q 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 r s t = u v w x y z A B C 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 D E ' F G : H I J d K L M 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 N O P Q R S T U V W X Y Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 `  ........... .` 3 3 3 N +.@.#.$ $.%.&.9 A *.=.-.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 e ;.>.>.>.>.>.;.e 3 3 3 N ,.'.).!.~.{.].^./.(._.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 D <.p * [.}.d |.1.2.3.4.M 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 r 5.6.- & 8 9 7.8.9.0.a.C 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 f f E b.i c.< d.9.e.f.g.~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 4 h.'.. i.j.k.l.m.n.o.p.q.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 r.s.' t.u.p.v.:.w.x.y.z.A.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 ` B.C.F % D.E.F.G.H.I.J.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 ` K.L.M.N.U U O.P.Q.R.S.-.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 N T.'.U.V.W.: X.Y.Z.9.`. +3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .+! ......n.>.>.>.>.>.n....... .C ++@+* #+# d ].$+%+&+*+{ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .+=+>.>.>.>.>.>.>.>.>.>.>.>.>.-+~ 3 ;+>+a.,+d '+)+3.!+~+~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .+2 {+>.>.>.>.>.>.>.>.>.>.>.]+{ ~ f ^+/+(+_+:+<+c [+}+|+~ 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 C 1+>.>.>.>.>.>.>.>.>.>.>.5.{ D 2+3+4+5+6+7+b T 8+9+0+e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 f M a+>.>.>.>.>.>.>.>.>.b+Z r r.,.> > + }+c+c d+_+e+f+g+3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 `  ........... .` 3 3 3 3 3 r h+i+>.>.>.>.>.>.>.# 2 4 3 ` j+k+l+m+n+T o+X.p+q+S.Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 e ;.>.>.>.>.>.;.e 3 3 3 3 3 3 D r+s+>.>.>.>.>.t+u+r.3 3 ` v+w+. !.x+y+9 z+A+B+C+Z 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 3 3 N ..D+>.>.>.E+...+3 3 3 r.F+G+H+I+J+K+[.L+M+3.&+A.3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 3 3 3 N+O+P+>.Q+! R+3 3 3 3 4 S+@+T+V U+V+W+X+Y+c p.e 3 3 3 ~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 R+h+..u+....-+Z+..2 ! Z A.A.A.~ `+ @.@+@@@#@$@%@&@*@=@3 3 -@~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 ! ;@>@=+,@'@)@!@~@{@)@]@T ^@v./@$ % '.j+K.^+(@_@:@a+<@[@3 R+1+# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 ..}@|@'@1@2@{@t+3@4@5@s+6@7@V.$ # + % 8@9@0@;+a@b@c@d@e@f 1+~ # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 ..{+f@|@'@1@2@g@h@i@j@5@k@6@D.V.$ l@V ) 8@9@m@;+b+n@o@<@e@[@C # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 ..p@q@r@|@'@!@s@;.h@i@4@5@t@~.D.V.u@$ v@) 8@w@'.x@y@<.^+z@e@e # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3  .:.>.>.>.>.>.:. .3 3 3 3 3 ..A@B@q@r@|@C@!@s@;.h@i@j@D@E@/@7@n.V.$ V @ F@0@;+a@b@G@o@5 { # . ",
		". # ~ 3 3 3 3 3 3 .+! ......n.>.>.>.>.>.n....... .N+3 ..H@I@B@q@r@|@C@!@s@;.h@i@j@D@t@6@~.n.u@# a.8@w@'.K.b+n@c@z@M # . ",
		". # ~ 3 3 3 3 3 3 .+=+>.>.>.>.>.>.>.>.>.>.>.>.>.-+R+3 ..>.J@I@B@q@r@|@C@!@s@;.h@i@j@5@k@6@7@V.$ & % K@L@j+x@b+n@a@A.# . ",
		". # ~ 3 3 3 3 3 3 .+2 {+>.>.>.>.>.>.>.>.>.>.>.]+{ R+3 ..>.M@J@I@B@q@r@|@C@!@s@;.N@O@j@5@E@/@n.u@l@+ % K@0@j+x@b+^+ +# . ",
		". # ~ 3 3 3 3 3 3 3 C 1+>.>.>.>.>.>.>.>.>.>.>.5.{ 3 3 ..>.P@M@J@I@B@q@r@=+Q@R@g@h@k@O@c S@T@U@n.u@l@+ % K@0@j+x@j+Z # . ",
		". # ~ 3 3 3 3 3 3 3 f M a+>.>.>.>.>.>.>.>.>.b+Z r 3 3 ..>.{+V@W@X@>@Y@Z@`@'@!@s@ #h@3@O@:.S@T@U@n.u@l@+ % K@0@j+'.h+# . ",
		". # ~ 3 3 3 3 3 3 3 3 r h+i+>.>.>.>.>.>.>.# 2 4 3 3 3 ..>.p@}@.#+#@###q@r@$#%#R@s@g@)@N@O@:.S@T@U@n.u@l@+ % K@0@0@! # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 D r+s+>.>.>.>.>.t+u+r.3 3 3 3 ..>.Q+&#}@P+J@>@Y@*#`@=#%#!@R@{@t+3@4@:.S@T@U@n.-## + % K@;# .# . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 N ..D+>.>.>.E+...+3 3 3 3 3 ..>.>#A@&#V@W@X@##,#*#`@$#C@%#R@{@h@k@4@:.]@6@7@'#)## + @ . 2 # . ",
		". # ~ 3 3 3 3 3 3 3 3 3 3 3 N+O+P+>.Q+! R+3 3 3 3 3 3 ..>.>.>#!#~#.#+#@###,#*#r@=+=#%#R@g@h@{#4@5@t@^@D.V.-#l@a.#.Z+# . ",
		". # ~ 3 3 3 ~ 2 ..................M@O+..]#r+Z+2  .! ! ..>.>.>.>.>.>.&#~#P@^#/#+#@#.#q@(#r@_#'@1@R@g@S@i@0.:#<#T@E@h+# . ",
		". # ~ 3 3 3 Z+>.[#;@}#{+}@|#1#Y@,#2#_#(#r@C@%#D+3#4#s@c W++ = ' > ;#i+K@L@m@b@5#b+c@z@6#7#8#h.3 s r .+C 1+2 u+....{ # . ",
		". # ~ 3 3 3 ..A@1#9#0###*#a#_#b#%#c#=#~@2@)@ #O@j@S@0.:.[+d#t@U@u@-#V [.)#l@a.' K@9@i+w@;+G@e#f#o@g#:@h#2+S+r.r R+R+# . ",
		". # ~ 3 3 3 ..>.|#1#9#0###*#(#f@i#%#D+=#~@2@3#t+O@j@S@0.c <#d#t@U@V.u@w V )#l@) j#F@m@k#F+0@x@e#f#G@_@:@8#2+S+r.~ 1+# . ",
		". # ~ 3 3 3 ..>.M@|#1#9#J@##*#(#f@b#%#c#$#~@;.3# #N@j@S@0.c [+n.E@U@7@u@-#V )#+ % j#F@l#i+,.j+x@e#f#6#7#++m#h.S+N ~ # . ",
		". # ~ 3 3 3 ..>./#P+W@I@9#n###*#a#2#i#%#o#=#~@;.3# #O@j@S@0.:.[+n.s+E@U@u@w [.$ a.l#> F@'.p#w@;+<.^+n@o@g#++m#h.S+C # . ",
		". # ~ 3 3 3 ..>.q#r#{+W@I@9#n###Z@s#2#i#Q@o#$#~@2@3# #O@j@S@0.:.<#t#T E@7@u@V @ l@) ' K@;#'.k#L@;+c@z@n@o@:@++m#h.e # . ",
		". # ~ 3 3 3 ..>.!#}@r#u#W@I@v#n#>@Z@E+2#i#w#o#$#~@2@3# #h@j@S@T 0.:.t#s+U@V.-#V )#+ ) j#K@;#'.,.L@K.e#z@n@o@:@++2+{ # . ",
		". # ~ 3 3 3 ..>.}#!#}@r#u#W@I@.#n#>@Z@E+2#_#b#o#$#~@2@)@ #h@j@S@]@0.<#n.E@U@u@-#[.)#+ ) j#K@;#'.,.j+K.e#z@n@o@:@6#{ # . ",
		". # ~ 3 3 3 ..>.[#x#!#}@r#u#W@@#.#n#>@Z@E+2#_#w#o#$#~@2@3#t+4@j@S@]@c [+n.t@U@u@-#[.)#+ ) j#K@;#i+,.j+K.c@z@n@o@h#M # . ",
		". # ~ 3 3 3 ..>.y#[#}#!#}@r#{+W@I@v#n#>@Z@s#2#i#Q@c#=#~@;.z#t+4@j@S@]@c <#d#t@U@u@-#[.)#+ ) ' K@;#i+,.L@K.c@z@n@z@M # . ",
		". # ~ 3 3 3 ..>.>.A@[#Q+p@q#/#P+|#I@9#J@##*#a#f@b#%#$#!@R@D+z#t+h@4@S@]@0.<#d#t@U@V.-#V )#l@) ' K@;#'.,.L@K.c@z@^+A.# . ",
		". # ~ 3 3 3 ..>.>.y#A#;@Q+~#P@u#M@|#1#9#0#q@*#(#_#w#o#$#=#R@;.3# #h@j@S@]@0.<#n.E@U@D.-#V )#l@) ' K@;#'.,.L@K.c@c@ +# . ",
		". # ~ 3 3 3 ..>.>.>.y#B#x#!#}@C#/#M@@#Y@P+J@B@E+2#_#Q@a#$#!@~@2@)@ #O@j@S@]@c [+s+E@U@V.-#V )#l@) ' > ;#'.k#w@;+y@Z # . ",
		". # ~ 3 3 3 ..>.>.>.>.y#[#}#Q+p@P@u#M@+#1#9#>@Z@E+2#r@Q@o#$#=#~@2@3# #O@j@S@]@c [+s+E@U@u@-#V )#& ) ' > ;#'.p#L@0@h+# . ",
		". @ ! ~ ~ ~ ..>.>.>.>.>.>.>.>.>.>.>.>.[#}#Q+~#^#|#-+v#s#>@,@q@r@i#w#o#3#!@s@t+N@j@S@v.D#E@/@7@V.# v@% j#8@F@0@K.j+]#@ . ",
		". + @ # # # = m@b+b+b+y@y@b@b@O F+5#5#;+K.K.x@k#,.w@L@0@0@m@m@'.i+i+p#8@K@F@F@;#9@l#' j#> > #.- - = . * 4+u.u.& % a.+ . ",
		". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
	end
	return Image
end
	
function ImageCompass(pic)
	if (pic == nil) then
		pic = '0'
	end
	
	if pic == '0' then
		Image = {
		"60 60 2 1",
		" 	c None",
		".	c #000000",
		"                                                            ",
		"                                                            ",
		"                                                            ",
		"                                                            ",
		"                         .   .                              ",
		"                         .   .   .                          ",
		"                          . .    .                          ",
		"                           .    ....                        ",
		"                           .     .                          ",
		"                           .                                ",
		"                           .                                ",
		"                                                            ",
		"                                                            ",
		"                                                            ",
		"                             ..                             ",
		"                             ..                             ",
		"                            ....                            ",
		"                            ....                            ",
		"                           ......                           ",
		"                           ......                           ",
		"                          ........                          ",
		"                          ........                          ",
		"                         ..........                         ",
		"                              .                             ",
		"                              .                             ",
		"                      .       .       .                     ",
		"                    ...       .       ...                   ",
		"    .   .         .....       .       .....     .   .       ",
		"     . .        .......       .       .......    . .    .   ",
		"     ..       .........      ..       .........  ...    .   ",
		"      .       .................................   .    .... ",
		"     . .  ...   .......       .       .......    . .    .   ",
		"    .  ..         .....       .       .....     .  ..       ",
		"    .   .           ...       .       ...       .   .       ",
		"                      .       .       .                     ",
		"                              .                             ",
		"                              .                             ",
		"                              .                             ",
		"                         ..........                         ",
		"                          ........                          ",
		"                          ........                          ",
		"                           ......                           ",
		"                           ......                           ",
		"                            ....                            ",
		"                            ....                            ",
		"                             ..                             ",
		"                             ..                             ",
		"                                                            ",
		"                                                            ",
		"                          .   .                             ",
		"                          .  .                              ",
		"                           . .                              ",
		"                           ..                               ",
		"                            .   ...                         ",
		"                            .                               ",
		"                            .                               ",
		"                                                            ",
		"                                                            ",
		"                                                            ",
		"                                                            "};
	elseif pic == '1' then
		Image = {
		--XPM Image Here
		};
	end
	return Image
end


return mcTouchOff -- Module End

--Button script
--Touch Button script
--if (Tframe == nil) then
--    --TouchOff module
--    package.loaded.mcTouchOff = nil
--	mcTouchOff = require "mcTouchOff"
--    
--	Tframe = mcTouchOff.Dialog()
--else
--	Tframe:Show()
--	Tframe:Raise()
--end
