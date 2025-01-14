

local Module2025 = {}
local SlowProbeRate = 0.7
local FastProbeRate = 5.0
local JogRate =  60

function Module2025.WriteRegister(name, val)
	local inst = mc.mcGetInstance();
	local hreg, rc = mc.mcRegGetHandle(inst, name)
	rc = mc.mcRegSetValueLong(hreg, val)
	if (rc ~= mc.MERROR_NOERROR) then
		mc.mcCntlSetLastError(inst, "Error setting  " .. name .. "  " .. rc)
		return 0
	end
	return 1
end


--function Module2025.mcRegAddDel(hInst, mode, device, path, desc, intialVal, persistent) --"mode = ADD" or "DEL", 
function Module2025.mcRegAddDel(inst, mode, device, path, desc, intialVal, persistent) --"mode = ADD" or "DEL", 
	local hReg
	local rc
	local cmdstring = mode .. "|" .. path
	local device = tostring(device)
	local desc = tostring(desc)
	local val = tostring(intialVal) 
	local persist = "0"
	if (type(persistent) == "boolean") then
		if (persistent ~= false) then 
			persist = "1"
		end
	elseif (type(persistent) == "number") then
		if (persistent ~= 0) then 
			persist = "1"
		end
	end
	
	--Check to see if the device is available 
	local hCmdReg 
	hCmdReg, rc = mc.mcRegGetHandle(inst, device .. "/command")
	if (rc ~= mc.MERROR_NOERROR) then --The device is not available.
		return "The command register for the instance registers is not available. Device = " .. device, mc.MERROR_NOT_IMPLEMENTED
	end
	
	--Check to see if the register exist
	hReg, rc = mc.mcRegGetHandle(inst, device .. "/" .. path)
	if (rc == mc.MERROR_NOERROR) and (mode == "ADD") then --Reg already exist so don't create it
		--mc.mcCntlSetLastError(inst, device .. "/" .. path .. " Register already exist so we won't try to create it")
		return "The register already exist.", mc.MERROR_NOERROR
	elseif (rc == mc.MERROR_REG_NOT_FOUND) and (mode == "DEL") then --Reg does not exist so don't try to delete it
		--mc.mcCntlSetLastError(inst, device .. "/" .. path .. " Register does not exist so we won't try to delete it")
		return "The register does not exist.", mc.MERROR_NOERROR
	elseif (rc ~= mc.MERROR_NOERROR) and (mode == "ADD") then --Reg doesn't exist so add the rest of the parameters and create it.
	--elseif (rc == mc.MERROR_REG_NOT_FOUND) and (mode == "ADD") then --Reg doesn't exist so add the rest of the parameters and create it.
		if (rc == mc.MERROR_REG_NOT_FOUND) then
			cmdstring = cmdstring .. "|" .. desc .. "|" .. val  .. "|" .. persist
		else
			response = "Unexpected error"
			return response, rc
		end
		--mc.mcCntlSetLastError(inst, device .. "/" .. path .. " Register doesn't exist so create it")
	else
		--mc.mcCntlSetLastError(inst, device .. "/" .. path .. " Register does exist so delete it")
	end
		
	--hReg, rc = mc.mcRegGetHandle(inst, device .. "/command")
	response, rc = mc.mcRegSendCommand(hCmdReg, cmdstring)
	--mc.mcCntlSetLastError(inst, tostring(response))
	
	return response, rc
	
end
	
--function Module2025.doRegTable(mode, t, device, group)
function Module2025.doRegTable(inst, mode, t, device, group)
	local inst = inst & 0xFF
	local rc = mc.MERROR_NOERROR
	for v = 1, #t do
		local path = group .. t[v][1]
		local desc = t[v][2]
		local intialVal = t[v][3]
		local persistent = t[v][4]
		--response, rc = Module2025.mcRegAddDel(hInst, mode, device, path, desc, intialVal, persistent) --"ADD" or "DEL",
		response, rc = Module2025.mcRegAddDel(inst, mode, device, path, desc, intialVal, persistent) --"ADD" or "DEL",
		if ((rc ~= mc.MERROR_NOERROR) and (rc ~= mc.MERROR_REG_NOT_FOUND)) then
			break
		end
	end
	return rc
end

function Module2025.GetRegister(regname, num)
	local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
	local val = mc.mcRegGetValueString(hreg)
	if (num == 1) then
		val = tonumber(val)
	end
	return val
end

function Module2025.SetRegister(regname, val, num)
	local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", regname))
	if (num == 1) then
		mc.mcRegSetValue(hreg, tonumber(val))
	else
		mc.mcRegSetValueString(hreg, val)
	end
end

function Module2025.SaveRegister(ini, name)
    local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", name))
    local val = mc.mcRegGetValueString(hreg)
    mc.mcProfileWriteString(0, tostring(ini), name, val)
end

function Module2025.LoadRegister(ini, name)
	local val = mc.mcProfileGetString(inst , tostring(ini), name, "0.000")
	local hreg = mc.mcRegGetHandle(inst, string.format("iRegs0/%s", name))
	mc.mcRegSetValueString(hreg, val)
end

function Module2025.SaveRegisters()
	--Auto tool setter registers
	--Module2025.SaveRegister("AutoTool", "TS_XPos")
	--Module2025.SaveRegister("AutoTool", "TS_YPos")
	--Module2025.SaveRegister("AutoTool", "TS_TouchPos")
	--Module2025.SaveRegister("AutoTool", "TS_ProbeH")
	--Module2025.SaveRegister("AutoTool", "TS_DefaultL")
	--Module2025.SaveRegister("AutoTool", "TS_Retract")
	--Module2025.SaveRegister("AutoTool", "TS_GCode")
end

function Module2025.LoadRegisters()
	--Auto tool setter registers
	--Module2025.LoadRegister("AutoTool", "TS_XPos")
	--Module2025.LoadRegister("AutoTool", "TS_YPos")
	--Module2025.LoadRegister("AutoTool", "TS_TouchPos")
	--Module2025.LoadRegister("AutoTool", "TS_ProbeH")
	--Module2025.LoadRegister("AutoTool", "TS_DefaultL")
	--Module2025.LoadRegister("AutoTool", "TS_Retract")
	--Module2025.LoadRegister("AutoTool", "TS_GCode")
end

function Module2025.ReturnCode()

end

function probePlate()
  local inst = mc.mcGetInstance()
  local Pos

  -- Fast probe Z zero
  mc.mcCntlGcodeExecuteWait(inst,"G90 G53 G0 Z-2.5") -- Pre-position
  mc.mcCntlSetLastError(inst, "Probing for Z Zero . . .")
  mc.mcCntlGcodeExecute(inst,"G91 G31 Z-3.0 F".. FastProbeRate)

  -- Retract slightly  
  mc.mcCntlSetLastError(inst, "Retract . . .")
  mc.mcCntlGcodeExecute(inst,"G91     Z0.05  F".. JogRate)  
 
  -- Slow probe Z zero
  mc.mcCntlSetLastError(inst, "Slow Probing for Z Zero . . .")
  mc.mcCntlGcodeExecute(inst,"G91 G31 Z-0.07 F".. SlowProbeRate)  
  
    -- Get touch position and jog to it in case of overshoot  
  Pos = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, 0)  -- Get Touch Position (work coordinates)
  mc.mcCntlGcodeExecute(inst,"G90 Z".. Pos .. " F".. SlowProbeRate)
  
  return Pos  
end


local function CheckProbe(state)
	local check = true
	local hsig = mc.mcSignalGetHandle(inst, ProbeSignal)
	local ProbeState = mc.mcSignalGetState(hsig)
	local errmsg = _("ERROR: No contact with probe")
	if (state == 1) then
		errmsg = _("ERROR: Probe signal active")
	end
	if (ProbeState == state) then
		mc.mcCntlSetLastError(inst, errmsg)
		mc.mcCntlEStop(inst)
		check = false
	end
	return check
end

function Module2025.SimpleAutoZero()
-- Simple AutoZero

-- Based on the macros created be Big Tex -  May 25 2010
-- and modified by Poppa Bear 11dec10
-- Modified for use with Mach4 by Colten Edwards Jan 9/2024

local posmode = mc.mcCntlGetPoundVar(inst,  MOD_GROUP_3)

mc.mcCntlSetLastError(inst, "Starting Simple Auto Zero")

local hreg = mc.mcRegGetHandle(inst, "iRegs0/2010/PlateOffset")
local PlateOffset = mc.mcRegGetValue(hreg)
hreg = mc.mcRegGetHandle(inst, "iRegs0/2010/MaterialOffset")
local MatOffset = mc.mcRegGetValue(hreg)
hreg = mc.mcRegGetHandle(inst, "iRegs0/2010/UseMatOffset")
local MatOffsetYN = mc.mcRegGetValueLong(hreg)

hreg = mc.mcRegGetHandle(inst, "iRegs0/2010/ZClearance")
local ZClearance, rc = mc.mcRegGetValue(hreg)
if (rc ~= mc.MERROR_NOERROR) then
	mc.mcCntlSetLastError(inst, "ZClearance is not error free "..ZClearance)
end

hreg = mc.mcRegGetHandle(inst, "iRegs0/2010/UseMachineCoord")
local UseMachineCoord = mc.mcRegGetValueLong(hreg)
local TotalOffset

rc = CheckProbe(1)
if (rc ~= 0) then 
	mc.mcCntlSetLastError(inst, "Probe is active. Fix this first.")
	return 
end
 
 
if (PlateOffset < 0.0) then
	mc.mcCntlSetLastError(inst, "PlateOffset is LESS than 0. Please Correct This  ".. PlateOffset)
	return
end

local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_CORD)
local sig = mc.mcSignalGetState(hsig)

if (sig ~= 0) then
	mc.mcCntlSetLastError(inst, "In Machine Coords")	
end

if (MatOffsetYN == 1) then
	if (MatOffset < 0.0) then
		mc.mcCntlSetLastError(inst, "Warning - Material Offset  is < 0")
	end
	TotalOffset = PlateOffset - MatOffset
else
	TotalOffset =  PlateOffset
end

if (ZClearance <= 0.0) then
	mc.mcCntlSetLastError(inst, "ZClearance Plane must be > 0.0 - Please Reset")
	return
end


local Units = mc.mcCntlGetUnitsCurrent(inst)
local FirstProbeDist = 6.0 -- Probe down 6 inches
local FirstRetractDist = 0.05 -- Then retract .05 inch
local SecProbeDist = 0.25 -- Then probe down .25 inches
local FirstProbeFeed = 10.0 -- First probe feed @ 10 ipm
local SecondProbeFeed = 1.0 -- Second probe feed @ 1 ipm
local ClearAllow = 0.125

if (Units ~= 200 ) then -- not Inches if not 200 so lets switch to metric
	FirstProbeDist = 150.0 -- Probe down 150mm
	FirstRetractDist = 1.0 -- Then retract 1mm
	SecProbeDist = 6.0 -- Then probe down 6mm
	FirstProbeFeed = 250.0 -- First probe feed @ 250 mm/min
	SecondProbeFeed = 25.0 -- Second probe feed @ 25 mm/min
	ClearAllow = 2.0 -- Max Allowable Clearance = Z Machine Zero - 2mm
end


mc.mcCntlSetLastError(inst, "Probing for Z Zero....")
local ZNew = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)
ZNew = ZNew - FirstProbeDist
mc.mcCntlGcodeExecute(inst, "G90 F".. FirstProbeFeed.." G31 Z" ..ZNew)
coroutine.yield()

local rc = mc.mcCntlProbeGetStrikeStatus(inst)
if rc==0 then
    wx.wxMessageBox('Fault: No Probe Strike')
    return nil
end

local posWrk = mc.mcAxisGetProbePos(inst,mc.Z_AXIS,0)--probe Strike Position Work Coords
local posMach = mc.mcAxisGetProbePos(inst,mc.Z_AXIS,1)--probe Strike Position Machine Coords

ZNew = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)

mc.mcCntlGcodeExecute(inst, "G0 Z" .. ZNew + FirstRetractDist) -- move up .05 inch or 1mm for overshoot


ZNew = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS) - SecProbeDist
mc.mcCntlGcodeExecute(inst, "G90 F"..SecondProbeFeed .. " G31 Z" .. ZNew)
coroutine.yield()

ZNew = mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)
mc.mcCntlGcodeExecute(inst, "G0Z"..ZNew)
coroutine.yield()


mc.mcAxisSetPos(inst, mc.Z_AXIS, TotalOffset) -- Set Z axis to the Plate Offset + Material Offset

--'Make Sure Z Clearance Plane is below Home Switch. If not, Notify User and Proceed.
local ZMaxRetract = math.abs((mc.mcAxisGetMachinePos(inst, mc.Z_AXIS)) - ClearAllow) --' Distance to Home Switch - Clearance Allowance

--wxMessageBox Types
--2 = Yes, No
--4 = Ok
--16 = Ok, Cancel
--18 = Yes, No, Cancel

--wxMessageBox Return Values
--Yes = 2
--OK = 4
--No = 8

if (ZClearance - TotalOffset > ZMaxRetract) then
	local choice = wxMessageBox("WARNING !!! Z Clearance Plane is Above Z Axis Home Switch. Press OK to Retract Safely below Switch or Press Cancel to Retract Safely below switch or Press Cancel to Exit.",18)
	if (choice == 2) then -- Yes
		ZClear = TotalOffset + ZMaxRetract
	elseif (choice == 8) then -- Cancel
		return
	end
	ZClear = TotalOffset + ZMaxRetract
end

	mc.mcCntlGcodeExecute(inst, "G0 Z".. ZClear)
	coroutine.yield()

mc.mcCntlSetLastError(inst, "Z Axis is now Zero\'d")

mc.mcCntlSetPoundVar(inst, posmode)

--If CurrentAbsInc = 0 Then 'if G91 was in effect before then return to it
--Code "G91" 
--End If 

end


return Module2025


