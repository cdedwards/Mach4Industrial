------------------------------------------------------------------------------
-- Name:        mcModulePaths
-- Author:      Dalton and Steve
-- Created:     09/19/2023
-- Copyright:   (c) 2023 Newfangled Solutions. All rights reserved.
-- License:  	BSD license - This header can not be removed
------------------------------------------------------------------------------

local mcSP = {}
function mcSP.SetupPaths(basedir)
	local inst = mc.mcGetInstance()
	local profile = mc.mcProfileGetName(inst)
	-- Make sure we're working with cross platform strings
	basedir = string.gsub(basedir, "\\", "/")
	if (string.sub(basedir, #basedir, #basedir) == "/") then
		basedir = string.sub(basedir, 0, #basedir-1)
	end
	
	-- Flag that the paths are already set
	bPathSet = true

	-- For ZeroBrane debugging.
	package.path = package.path .. ";" .. basedir .. "/ZeroBraneStudio/lualibs/mobdebug/?.lua"

	-- For installed profile modules support.
	package.path = package.path .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/?.lua"
	package.path = package.path .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/?.luac"
	package.path = package.path .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/?.mcs"
	package.path = package.path .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/?.mcc"
	package.cpath = package.cpath .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/?.dll"

	-- For installed global modules support.
	package.path = package.path .. ";" .. basedir .. "/Modules/?.lua"
	package.path = package.path .. ";" .. basedir .. "/Modules/?.luac"
	package.path = package.path .. ";" .. basedir .. "/Modules/?.mcs"
	package.path = package.path .. ";" .. basedir .. "/Modules/?.mcc"
	package.cpath = package.cpath .. ";" .. basedir .. "/Modules/?.dll"

	-- PMC genearated module load code.
	package.path = package.path .. ";" .. basedir .. "/Pmc/?.lua"
	package.path = package.path .. ";" .. basedir .. "/Pmc/?.luac"

	local function AddModulePath(Path, Extentions)
		for _, ext in pairs(Extentions) do
			if ext == ".dll" then
				package.cpath = package.cpath .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/" .. Path .. "/?" .. ext
				package.cpath = package.cpath .. ";" .. basedir .. "/Modules/" .. Path .. "/?" .. ext	
			else
				package.path = package.path .. ";" .. basedir .. "/Profiles/" .. profile .. "/Modules/" .. Path .. "/?" .. ext
				package.path = package.path .. ";" .. basedir .. "/Modules/" .. Path .. "/?" .. ext
			end
		end
	end

	-- Example for a new directoy under the Modules directory.  Case is important for 
	-- future Linux builds.
	-- The example directory is "mcStandard"
	-- Note that machDir is passed as the fist parameter to this function.  However, 
	-- it isn't used as all paths are relative to the current working directory.  The 
	-- machDir parameter is provided just in case it is needed.

	--[[
	Extention Options
	.lua
	.luac
	.mcs
	.mcc
	.dll
	--]]

	-- Path for mcStandard
	AddModulePath("mcStandard", {".lua", ".mcs"})
	
	if wx.wxFileExists(basedir .. "/Modules/mcEcatCommon.lua") then
		pcall(require, "mcEcatCommon")
	end
	
	if mcPR == nil then
		rc, mcPR = pcall(require, "mcPRequire") -- Table with protected require function that takes the following arguments
		--(string Name, bool? Reload, string? PackageName)
		-- name is the module name, 
		--reload is a bool of whether to unload the package and 
		--PackageName is the name of the modules variable if it's different from the module name
		if rc == false then
			wx.wxMessageBox("PRequire Execution Aborted: " .. tostring(mcPR))
			return
		end
	end
end
return mcSP