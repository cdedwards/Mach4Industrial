-- Sets global functions for easier debugging
if mc.mcInEditor() == 1 then
	local rc, mcSP = pcall(require, "./Modules/mcSysPaths")
	if rc == false then
		mc.mcCntlSetLastError(inst, string.format("Require in '%s' could not find file. Error: %s", tostring(debug.getinfo(1).short_src), mcSP))
		return
	end
	mcSP.SetupPaths(".")
end
local function ParseFileName(name)
	local FileName = name:match("^.+[/\\](.+)$")
	if FileName == nil then
		return ""
	end
	local pos = FileName:reverse():find("%.")
	if pos == nil then
		return ""
	end
	return FileName:sub(0, #FileName-pos)
end
local inst = mc.mcGetInstance()
Print = function(msg, bDoPrintFull, info)
	local ToPrint 
	if info == nil then
		info = debug.getinfo(2)
	end
	local Prefix = ""
	if bDoPrintFull == true then
		if info.short_src ~= nil then
			Prefix = string.format("%s(%s): ", tostring(info.currentline), tostring(info.short_src))
		end
		ToPrint = string.format("%s%s", Prefix, tostring(msg))
	else
		Prefix = ParseFileName(tostring(info.short_src))
		if Prefix ~= "" then
			Prefix = Prefix .. ": "
		end
		ToPrint = string.format("%s%s", ParseFileName(tostring(info.short_src)), tostring(msg))
	end
	if mc.mcInEditor() == 1 then
		print(ToPrint)
	else
		mc.mcCntlSetLastError(inst, ToPrint)
	end
end
Log = function(msg, info)	
	if info == nil then
		info = debug.getinfo(2)
	end
	mc.mcCntlLog(inst, tostring(msg), tostring(info.short_src), info.currentline)
end
