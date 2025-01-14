function MakeLuaInterpreter(version, name)

	local function tprint (tbl, indent)
		if not indent then indent = 0 end
		local toprint = string.rep(" ", indent) .. "{\r\n"
		indent = indent + 2 
		for k, v in pairs(tbl) do
			toprint = toprint .. string.rep(" ", indent)
			if (type(k) == "number") then
				toprint = toprint .. "[" .. k .. "] = "
			elseif (type(k) == "string") then
				toprint = toprint  .. k ..  "= "   
			end
			if (type(v) == "number") then
				toprint = toprint .. v .. ",\r\n"
			elseif (type(v) == "string") then
				toprint = toprint .. "\"" .. v .. "\",\r\n"
			elseif (type(v) == "table") then
				toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
			else
				toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
			end
		end
		toprint = toprint .. string.rep(" ", indent-2) .. "}"
		return toprint
	end

	local function exePath(self, version)
		local lversion = tostring(version or ""):gsub('%.','')
		local mainpath = ide:GetRootPath()
		local macExe = mainpath..([[bin/lua.app/Contents/MacOS/lua%s]]):format(lversion)
		return (ide.config.path['lua'..lversion]
			or (ide.osname == "Windows" and mainpath..([[bin\lua%s.exe]]):format(lversion))
			or (ide.osname == "Unix" and mainpath..([[bin/linux/%s/lua%s]]):format(ide.osarch, lversion))
			or (wx.wxFileExists(macExe) and macExe or mainpath..([[bin/lua%s]]):format(lversion))),
			ide.config.path['lua'..lversion] ~= nil
	end

	local function StringTokenizer(str, delim)
		if string.find(str, delim) == nil then 
			retval[1] = str
			return retval
		end
		local match = "([^" .. tostring(delim) .. "]+)"
		local retval = {}
		local index = 1
		for token in str:gmatch(match) do 
			retval[index] = token
			index = index + 1
		end
		return retval
	end

	return {
		name = ("%s"):format(name or "Mach4"),
		description = ("Lua %s interpreter with debugger"):format(name or version or ""),
		api = {"baselib", "mc", "scr", "wxwidgets"},
		luaversion = version or '5.1',
		fexepath = exePath,
		frun = function(self,wfilename,rundebug)
			local exe, iscustom = self:fexepath(version or "")
			local filepath = wfilename:GetFullPath()

			do
				-- if running on Windows and can't open the file, this may mean that
				-- the file path includes unicode characters that need special handling
				local fh = io.open(filepath, "r")
				if fh then fh:close() end
				if ide.osname == 'Windows' and pcall(require, "winapi") and wfilename:FileExists() and not fh then
					winapi.set_encoding(winapi.CP_UTF8)
					local shortpath = winapi.short_path(filepath)
					if shortpath == filepath then
						ide:Print(
							("Can't get short path for a Unicode file name '%s' to open the file.")
							:format(filepath))
						ide:Print(
							("You can enable short names by using `fsutil 8dot3name set %s: 0` and recreate the file or directory.")
							:format(wfilename:GetVolume()))
					end
					filepath = shortpath
				end
			end

			if rundebug then
				ide:GetDebugger():SetOptions({runstart = ide.config.debugger.runonstart == true})
				local m4conf = ide.config.mach4 or { hostname = 'localhost', instance = 0 }
				local ipaddr = m4conf.hostname or "localhost"
				local instance = m4conf.instance or 0
				array = StringTokenizer(ipaddr, ":")
				local machipcPort = 48000
				if (#array > 1) then 
					ipaddr = array[1]
					machipcPort = tonumber(array[2])
				end
				local screenipcPort = machipcPort + 500
				local machIpcInit = "mc=require('machipc');mc.mcIpcInit('" .. ipaddr .. ":" .. tostring(machipcPort) .."');"
				local screenIpcInit = "scr=require('screenipc');scr.scIpcInit('" .. ipaddr .. ":" .. tostring(screenipcPort) .."');"
				local fn = wx.wxFileName(ide.editorFilename)
				fn:RemoveLastDir()
				local machDir = fn:GetPathWithSep()
				local prefix = "do;"
				local pkgcpath = "package.cpath=[[" .. machDir .. "Modules/?.dll;" .. machDir .. "ZeroBraneStudio/bin/clibs53/?.dll;]]..package.cpath;"
				local pkgpath = "package.path=[[" .. machDir .. "Modules/?.lua;" .. machDir .. "ZeroBraneStudio/lualibs/mobdebug/?.lua;]]..package.path;"
				local machReq = "__IN_EDITOR__=1;__MINSTANCE__="..tostring(instance)..";" .. machIpcInit .. screenIpcInit .. "require('wx');"
				local suffix = "end;"
				local machInit = prefix .. pkgcpath .. pkgpath .. machReq .. suffix
				--ide:Print(machInit)
				
				-- update arg to point to the proper file
				rundebug = ('if arg then arg[0] = [[%s]] end '):format(filepath)..machInit..rundebug

				local tmpfile = wx.wxFileName()
				tmpfile:AssignTempFileName(".")
				filepath = tmpfile:GetFullPath()
				local f = io.open(filepath, "w")
				if not f then
					ide:Print("Can't open temporary file '"..filepath.."' for writing.")
					return
				end
				f:write(rundebug)
				f:close()
			end
			local params = self:GetCommandLineArg("lua")
			local code = ([[-e "io.stdout:setvbuf('no')" "%s"]]):format(filepath)
			local cmd = '"'..exe..'" '..code..(params and " "..params or "")

			-- modify LUA_CPATH and LUA_PATH to work with other Lua versions
			local envcpath = "LUA_CPATH"
			local envlpath = "LUA_PATH"
			if version then
				local env = "PATH_"..string.gsub(version, '%.', '_')
				if os.getenv("LUA_C"..env) then envcpath = "LUA_C"..env end
				if os.getenv("LUA_"..env) then envlpath = "LUA_"..env end
			end

			local cpath = os.getenv(envcpath)
			if rundebug and cpath and not iscustom then
				-- prepend osclibs as the libraries may be needed for debugging,
				-- but only if no path.lua is set as it may conflict with system libs
				wx.wxSetEnv(envcpath, ide.osclibs..';'..cpath)
			end
			if version and cpath then
				-- adjust references to /clibs/ folders to point to version-specific ones
				local cpath = os.getenv(envcpath)
				local clibs = string.format('/clibs%s/', version):gsub('%.','')
				if not cpath:find(clibs, 1, true) then cpath = cpath:gsub('/clibs/', clibs) end
				wx.wxSetEnv(envcpath, cpath)
			end

			local lpath = version and (not iscustom) and os.getenv(envlpath)
			if lpath then
				-- add oslibs libraries when LUA_PATH_5_x variables are set to allow debugging to work
				wx.wxSetEnv(envlpath, lpath..';'..ide.oslibs)
			end

			-- CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
			local pid = CommandLineRun(cmd,self:fworkdir(wfilename),true,false,nil,nil,
				function() if rundebug then wx.wxRemoveFile(filepath) end end)

			if (rundebug or version) and cpath then wx.wxSetEnv(envcpath, cpath) end
			if lpath then wx.wxSetEnv(envlpath, lpath) end
			return pid
		end,
		hasdebugger = true,
		scratchextloop = false,
		unhideanywindow = true,
		takeparameters = true,
	}
end

--dofile 'interpreters/machbase.lua'
local interpreter = MakeLuaInterpreter(5.3, 'Mach4')
interpreter.skipcompile = true
return interpreter
