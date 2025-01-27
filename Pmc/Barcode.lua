-----------------------------------------------------------------------------
--   Name: PMC Module
--Created: 03/27/2015
-----------------------------------------------------------------------------
-- This is auto-generated code from PmcEditor. Do not edit this file! Go
-- back to the ladder diagram source for changes in the logic

-- U_xxx symbols correspond to user-defined names. There is such a symbol
-- for every internal relay, variable, timer, and so on in the ladder
-- program. I_xxx symbols are internally generated.

_G.bcode = require("mcBarcode")
_G.bcode.SetPort("COM3")

local Barcode = {}

local pmcvars = {} -- One local variable to conatain all pmc generated variables

local hIo, hReg, hSig, rc

-- Generated function for MachAPI.
local function Read_Register(mInst, path)
    local value
    if (path:find('AnalogInput/')) then
        local index = string.gsub(path, 'AnalogInput/', '')
        index = tonumber(index)
        value, rc = mc.mcAnalogInputRead(mInst, index)
        if (rc == mc.MERROR_NOERROR) then
            return value
        end
    elseif (path:find('AnalogOutput/')) then
        local index = string.gsub(path, 'AnalogOutput/', '')
        index = tonumber(index)
        value, rc = mc.mcAnalogOutputRead(mInst, index)
        if (rc == mc.MERROR_NOERROR) then
            return value
        end
    else
        hReg, rc = mc.mcRegGetHandle(mInst, path)
        if (rc == mc.MERROR_NOERROR) then
            value, rc = mc.mcRegGetValue(hReg)
            if (rc == mc.MERROR_NOERROR) then
                return value
            end
        end
    end
    return 0
end

-- Generated function for MachAPI.
local function Write_Register(mInst, path, value)
    if (path:find('AnalogOutput/')) then
        local index = string.gsub(path, 'AnalogOutput/', '')
        index = tonumber(index)
        rc = mc.mcAnalogOutputWrite(mInst, index, value)
        if (rc == mc.MERROR_NOERROR) then
            return
        end
    else
        hReg, rc = mc.mcRegGetHandle(mInst, path)
        if (rc == mc.MERROR_NOERROR) then
            rc = mc.mcRegSetValue(hReg, value)
            if (rc == mc.MERROR_NOERROR) then
                return
            end
        end
    end
    return
end

-- Generated function for MachAPI.
local function Read_Signal(mInst, path)
    hSig = 0
    rc = mc.MERROR_NOERROR
    hSig, rc = mc.mcSignalGetHandle(mInst, path)
    if (rc == mc.MERROR_NOERROR) then
        local state = 0;
        state, rc = mc.mcSignalGetState(hSig)
        if (rc == mc.MERROR_NOERROR) then
            return state
        end
    end
    return 0
end

-- Generated function for MachAPI.
local function Write_Signal(mInst, path, v)
    hSig = 0
    rc = mc.MERROR_NOERROR
    hSig, rc = mc.mcSignalGetHandle(mInst, path)
    if (rc == mc.MERROR_NOERROR) then
        mc.mcSignalSetState(hSig, v)
    end
end

-- Generated function for MachAPI.
local function Read_Io(mInst, path)
    hIo = 0
    rc = mc.MERROR_NOERROR
    hIo, rc = mc.mcIoGetHandle(mInst, path)
    if (rc == mc.MERROR_NOERROR) then
        local state = 0
        state, rc = mc.mcIoGetState(hIo)
        if (rc == mc.MERROR_NOERROR) then
            return state
        end
    end
    return 0
end

-- Generated function for MachAPI.
local function Write_Io(mInst, path, v)
    hIo, rc = mc.mcIoGetHandle(mInst, path)
    if (rc == mc.MERROR_NOERROR) then
        mc.mcIoSetState(hIo, v)
    end
end

-- Generated function for MachAPI.
local function JogStart(mInst, axis, dir)
    local type = 0
    type, rc = mc.mcJogGetType(mInst, axis)
    if (rc == mc.MERROR_NOERROR) then
        if (type == 0) then -- velocity
            mc.mcJogVelocityStart(mInst, axis, dir)
        else                -- incremental
            local inc = 0
            inc, rc = mc.mcJogGetInc(mInst, axis)
            if (rc == mc.MERROR_NOERROR) then
                inc = inc * dir
                mc.mcJogIncStart(mInst, axis, inc)
            end
        end
    end
end
local function JogStop(mInst, axis)
    local type = 0
    type, rc = mc.mcJogGetType(mInst, axis)
    if (rc == mc.MERROR_NOERROR) then
        if (type == 0) then -- velocity
            mc.mcJogVelocityStop(mInst, axis)
        end
    end
end

pmcvars.I_b_mcr = 0
local function Read_I_b_mcr() return pmcvars.I_b_mcr; end
local function Write_I_b_mcr(x) pmcvars.I_b_mcr = x; end
pmcvars.I_b_rung_top = 0
local function Read_I_b_rung_top() return pmcvars.I_b_rung_top; end
local function Write_I_b_rung_top(x) pmcvars.I_b_rung_top = x; end

-- Generated function for signal read.
local function Read_U_b_FGcodeRunning()
    return Read_Signal(0, 1114)
end

-- Generated function for signal write.
local function Write_U_b_FGcodeRunning(v)
    Write_Signal(0, 1114, v)
end
pmcvars.U_d_TUpdateTime = 0

-- Generated function for script execute.
local function SRunScript_func(inst, state)
	if(state == 1)then 
		-- We will make sure the machien is in Idle State
		if(mc.mcCntlGetState(inst) == mc.MC_STATE_IDLE) then 
			if(_G.bcode ~= nil)then
				_G.bcode.runScan(inst); --when The scan is run if anything is found a the file will be loaded 
			end 
		end 
	end 
end

-- Generated function for script only coil object.
local function Write_U_b_SRunScript(v)
    SRunScript_func(0, v)
end


-- Call this function to retrieve the PMC cycle time interval
-- that you specified in the PmcEditor.
function Barcode.GetCycleInterval()
    return 10
end


-- Call this function once per PLC cycle. You are responsible for calling
-- it at the interval that you specified in the MCU configuration when you
-- generated this code. */
function Barcode.PlcCycle()
    Write_I_b_mcr(1)
    
    -- start rung 1
    Write_I_b_rung_top(Read_I_b_mcr())
    
    -- start series [
    if(Read_U_b_FGcodeRunning() == 1) then
        Write_I_b_rung_top(0)
    end
    
    if(pmcvars.U_d_TUpdateTime < 500) then
        if(Read_I_b_rung_top() == 1) then
            pmcvars.U_d_TUpdateTime = pmcvars.U_d_TUpdateTime + 1
        end
        Write_I_b_rung_top(0)
    else
        Write_I_b_rung_top(1)
    end
    
    Write_U_b_SRunScript(Read_I_b_rung_top())
    
    -- ] finish series
end

return Barcode
