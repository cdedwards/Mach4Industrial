local mcPR = {}
local EnableLogging = false
--(string Name, bool? Reload, string? PackageName)
-- name is the module name, 
--reload is a bool of whether to unload the package and 
--PackageName is the name of the modules variable if it's different from the module name
function mcPR.prequire(name, reload, PackageName) 
	local Module
	if tostring(name) == nil then
		mc.mcCntlSetLastError(mc.mcGetInstance(), "nil module name")
		return nil, "nil module name"
	end
	local packageName = name
	if PackageName ~= nil then
		packageName = PackageName
	end
	if reload == true then
		package.loaded[packageName] = nil
	end
	local val = package.loaded[packageName]
	if val == nil then
		-- If module has no return "Module" will be nil this is expected
		rc, Module = pcall(require, name)
		if rc == false then
			mc.mcCntlSetLastError(mc.mcGetInstance(), "Execution Aborted: " .. tostring(Module))
			_G.ModuleLoadFailed = true
			return  nil, "Execution Aborted: " .. tostring(Module)
		end
		if EnableLogging == true then
			Log("Module Loaded Succesfully" .. tostring(name))
		end
		return Module
	end
	return package.loaded[packageName]
end
if EnableLogging == true then
	mcPR.prequire("mcLog")
	if Log == nil then
		EnableLogging = false
	end
end
return mcPR