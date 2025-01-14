if (inst == nil) then
    inst = mc.mcGetInstance()
end
MachDirectory = mc.mcCntlGetMachDir(inst)
Profile = mc.mcProfileGetName(inst)
ScriptPath = MachDirectory .. "\\Modules\\AddOns\\FontEngraving\\?.lua;"
local spos = string.find(package.path, ScriptPath)
if (spos == nil) then
	-- if the path isn't found, append it.
	package.path = package.path .. ScriptDirectory
end

--package.loaded.mcFPanel = nil -- clear the cache and force the module to reload.
if (package.loaded.mcFPanel == nil)
	fontEngravePanel = require "mcFPanel"
end
fontEngravePanel.Panel()