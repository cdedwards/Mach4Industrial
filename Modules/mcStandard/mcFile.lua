local mcFile = {}
local File = {}
function mcFile.escape_magic(pattern)
  return (pattern:gsub("[^%w]", "%%%1"))
end
function mcFile.Write(path, data, bKeepOpen)
	if mcFile.OpenPath ~= path then
		if mcFile.OpenFile ~= nil then
			mcFile.OpenFile:close()
		end
		if wx.wxFileExists(path) ~= true then
			mc.mcCntlSetLastError(mc.mcGetInstance(), "mcFile: Path does not exist")
			return
		end
		mcFile.OpenFile = io.open(path, "w") 
		mcFile.OpenPath = path
	end
	if type(data) ~= "string" then
		data = tostring(data)
	end
	mcFile.OpenFile:write(data)
	if bKeepOpen ~= true then
		mcFile.Close()
	end
end
function mcFile.Append(path, data, bKeepOpen)
	if mcFile.OpenPath ~= path then
		if mcFile.OpenFile ~= nil then
			mcFile.OpenFile:close()
		end
		if wx.wxFileExists(path) ~= true then
			mc.mcCntlSetLastError(mc.mcGetInstance(), "mcFile: Path does not exist")
			return
		end
		mcFile.OpenFile = io.open(path, "a") 
		mcFile.OpenPath = path
	end
	if type(data) ~= "string" then
		data = tostring(data)
	end
	mcFile.OpenFile:write(data)
	if bKeepOpen ~= true then
		mcFile.Close()
	end
end
function mcFile.Close()
	if mcFile.OpenFile ~= nil then
		mcFile.OpenFile:close()
		mcFile.OpenFile = nil
		mcFile.OpenPath = nil
	end
end
--Gets all the files in the directory sent. (It does not look in sub directories)
function mcFile.findFiles(Dir, Sort, Extentions) 
	if wx.wxDirExists(Dir) == false then
		return -1
	end
	local file = wx.wxFindFirstFile(Dir)
	local FilePaths = wx.wxArrayString()
	local FileNames = wx.wxArrayString()
	if file ~= "" then
		while file ~= "" do
			local wxFileName = wx.wxFileName(file)
			local FileName = wxFileName:GetName()
			if Extentions == true then
				FileName = FileName .. wxFileName:GetExt()
			end
			FileNames:Add(FileName)
			FilePaths:Add(file)
			file = wx.wxFindNextFile()
		end
	else
		return -1
	end
	if Sort == true then
		FilePaths:Sort(false)
		FileNames:Sort(false)
	end
	return FilePaths, FileNames
end
-- Very different purpose from findFiles. This function will look in ever directory and each subdirectory for a matching file
function mcFile.FindFile(Directory, Name, Ignore) 
	local inst = mc.mcGetInstance()
	if wx.wxDirExists(Directory) == false then
		mc.mcCntlSetLastError(inst, "Directory Path does not exist")
		return -1
	end
	local function RunAllDirs(Path)
		local Directory = wx.wxDir(Path)
		local opened = Directory:IsOpened()
		local rc, fileOrDir = Directory:GetFirst()
		while rc ~= false do
			if wx.wxFileExists(Path .. fileOrDir) == true then
				if fileOrDir == Name then
					return Path .. fileOrDir
				end
			elseif wx.wxDirExists(Path .. fileOrDir) == true then
				if Ignore == nil or Ignore[fileOrDir] == nil then
					local TrueDir = fileOrDir .. "\\"
					rc = RunAllDirs(Path .. TrueDir)
					if rc ~= nil then
						return rc
					end
				end
			end
			rc, fileOrDir = Directory:GetNext()
		end
	end
	noErr, rc = pcall(RunAllDirs, Directory)
	return rc
end
function mcFile.ParseNumberedFileNames(Dir, Markers) -- returns table of numbered file names in the directory
	if wx.wxDirExists(Dir) == false then
		return
	end
	local file = wx.wxFindFirstFile(Dir)
	local FileNames = {}
	while file ~= "" do
		local wxFileName = wx.wxFileName(file)
		local FileName = wxFileName:GetName()
		local _, markerStart = FileName:find(mcFile.escape_magic(Markers.Open))
		local markerEnd = FileName:find(mcFile.escape_magic(Markers.Close))
		if markerStart ~= nil and markerEnd ~= nil then
			local FileNumber = FileName:sub(markerStart+1, markerEnd-1)
			if tonumber(FileNumber) ~= nil then
				FileNames[tonumber(FileNumber)] = FileName
			end
		end
		file = wx.wxFindNextFile()
	end
	return FileNames
end
function mcFile.extractStrValue(str, target, toEnd)
	local eqpos = string.find(str, target);
	if eqpos == nil then
		return
	end
	local subbed = ""
	if toEnd == true then
		return string.gsub(string.sub(str, eqpos+1, string.len(str)), target, "")
	else
		return string.gsub(string.sub(str, 0, eqpos-1), target, "")
	end
end
function mcFile.DeleteFilesWExt(Directory, TargetExt, Ignore)
	local inst = mc.mcGetInstance()
	if wx.wxDirExists(Directory) == false then
		mc.mcCntlSetLastError(inst, "Directory Path does not exist")
		return -1
	end
	local function RunAllDirs(Path)
		local Directory = wx.wxDir(Path)
		local opened = Directory:IsOpened()
		local rc, fileOrDir = Directory:GetFirst()
		while rc ~= false do
			if wx.wxFileExists(Path .. fileOrDir) == true then
				local wxFileName = wx.wxFileName(fileOrDir)
				local ext = wxFileName:GetExt()
				if ext == TargetExt then
					wx.wxRemoveFile(Path .. fileOrDir)
				end
			elseif wx.wxDirExists(Path .. fileOrDir) == true then
				if Ignore == nil or Ignore[fileOrDir] == nil then
					local TrueDir = fileOrDir .. "/"
					RunAllDirs(Path .. TrueDir)
				end
			end
			rc, fileOrDir = Directory:GetNext()
		end
	end
	noErr, rc = pcall(RunAllDirs, Directory)
	return rc
end
function File.Init(mcFile, TableStart, TableEnd, Equal)
	function mcFile.LoadTableFromFile(file_name) -- this function stopped being recognized by lua at one point
		local function Addtotable(thefile, tableindex)
			local str = thefile:read("line");
			while (str ~= nil )do  
				if (string.find(str, TableStart) ~= nil) then
					-- Get the name of the table
					str = string.gsub(str," " .. TableStart, "")
					local newTable = {} 
					table.insert(tableindex, Addtotable(thefile, newTable))
				elseif (string.find(str, TableEnd) ~= nil) then
					return tableindex
				else
					-- This is normal data and needs to be placed into the table
					local length = string.len(str);
					local eqpos = string.find(str,Equal);
					local varname = string.sub(str, 0,eqpos-1)
					local val = string.sub(str, eqpos+1, length)
					tableindex[varname] = val
				
				end
				str = thefile:read("line");
			end
			return tableindex
		end
		if wx.wxFileExists(file_name) then
			local myfile = assert(io.open(file_name , "r"))
			if myfile ~= nil then  
				local dataTable = {}; -- Blank table to put the data
				dataTable = Addtotable(myfile, dataTable)
				myfile:close();
				return dataTable;
			end
		end
		return {}
	end
	function mcFile.SaveTableToFile(file_name, tabletoSave)
		local function TableToString(tbl)
			local str = ""
				for var,value in pairs(tbl) do 
					if (type(value) == "table") then
						str = str .. tostring(var) .. " " .. TableStart .. "\n".. TableToString(value).. TableEnd .. "\n"
					else
						if tonumber(value) ~= nil then
							str = str .. tostring(var) .. Equal .. string.format("%.4f", tonumber(value)) .. "\n" 
						else
						str = str .. tostring(var) .. Equal .. tostring(value) .. "\n" 
						end
					end
				end
			return str
		end
		local str = TableToString(tabletoSave)
		local myfile = assert(io.open(file_name , "w"))
		myfile:write(str)
		myfile:flush();
		myfile:close();
		return 0
	end
	return mcFile
end
File.Init(mcFile, "<TABLE_START>", "<TABLE_END>", "=")
---------------------------------------------------------------
 -- Ini Saving
--------------------------------------------------------------- 
function mcFile.IniSet(section, key, val, Type) -- needs to get changed to work with wizard
	local inst = mc.mcGetInstance()
	if section == nil or key == nil or val == nil then
		return -1
	end
	if Type == "string" then
		local setTo = tostring(val)
		if setTo ~= nil then
			response = mc.mcProfileWriteString(inst, section, key, setTo)
		end
	elseif Type == "int" then
		local setTo = math.floor(tonumber(val))
		if setTo ~= nil then
			response = mc.mcProfileWriteInt(inst, section, key, setTo)
		else
			return -1
		end
	else
		local setTo = tonumber(val)
		if setTo ~= nil then
			response = mc.mcProfileWriteDouble(inst, section, key, setTo)
		else
			return -1
		end
	end
	if response == mc.MERROR_NOERROR then
		mc.mcProfileFlush(mc.mcGetInstance())
		return response
	else
		return response
	end
end
function mcFile.IniGet(section, key, defval, Type) 
	--Get Registers based on handle(Path or acutal location) and Type(Either "string" or "num") to denote if the register is a string or value
	local inst = mc.mcGetInstance()
	if section == nil or key == nil or defval == nil or Type == nil then
		return 0, -1
	end
	if Type == "string" then
		response,rc = mc.mcProfileGetString(inst, section, key, defval)
	elseif Type == "int" then
		response,rc =  mc.mcProfileGetInt(inst, section, key, defval)
	elseif Type == "double" then
		response, rc =  mc.mcProfileGetDouble(inst, section, key, defval)
	end
	if rc == mc.MERROR_NOERROR then
		return response, rc
	else
		return 0, -1
	end
end
--Call this to Change what the tbl to file functions use for end, start and equal
function mcFile:ReInit(Start, End, Equal)
	return File.Init(self, Start, End, Equal)
end
return mcFile