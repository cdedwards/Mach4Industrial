------------------------------------------------------------------------------
-- Name:        mcModulePaths
-- Author:      Steve Murphree
-- Created:     04/05/2023
-- Copyright:   (c) 2023 Newfangled Solutions. All rights reserved.
-- License:  	BSD license - This header can not be removed
------------------------------------------------------------------------------
local modulepaths = {ProfileName = ""}

function modulepaths.loadpaths(machDir, profileName)
	--Sets the profile name
	modulepaths.ProfileName = profileName
	-- Example for a new directoy under the Modules directory.  Case is important for 
	-- future Linux builds.
	-- The example directory is "MyModules"
	-- Note that machDir is passed as the fist parameter to this function.  However, 
	-- it isn't used as all paths are relative to the current working directory.  The 
	-- machDir parameter is provided just in case it is needed.
	
	--[[
		Extention Options
		.lua
		.lua
		.mcs
		.mcc
		.dll
	--]]
	
	-- Path for mcStandard
	modulepaths:AddModulePath("mcStandard", {".lua", ".mcs"})

end

function modulepaths:AddModulePath(Path, Extentions)
	for _, ext in pairs(Extentions) do
		if ext == ".dll" then
			package.cpath = package.cpath .. ";./Profiles/".. self.ProfileName .. "/Modules/" .. Path .. "/?" .. ext
			package.cpath = package.cpath .. ";./Modules/" .. Path .. "/?" .. ext	
		else
			package.path = package.path .. ";./Profiles/".. self.ProfileName .. "/Modules/" .. Path .. "/?" .. ext
			package.path = package.path .. ";./Modules/".. Path .. "/?" .. ext
		end
	end
end

return modulepaths

