local debug = false
local inst = mc.mcGetInstance()
local function PrintError(msg, Debug)
	if Debug == nil then
		Debug = debug
	end
	mc.mcCntlSetLastError(mc.mcGetInstance(), msg)
	if Debug == true then
		print(msg)
	end
end
local _, mcFile = pcall(require, "mcFile")
local BaseFuncs = {["register"] = {}, ["command"] = {}}
BaseFuncs.register.Get = function(item)
	if item == nil then
		PrintError("NIL values sent into register Get function")
		return -1
	end
	if item.ValueType == "string" then
		response, rc = mc.mcRegGetValueString(item.RegHandle)
	else
		response, rc = mc.mcRegGetValue(item.RegHandle)
	end
	return response, rc
end	
BaseFuncs.register.Set = function(item, val)
	if val == nil or item == nil or item.Name == nil then
		PrintError("NIL values sent into register Set function")
		return -1
	end
	if item.ValueType == "string" then
		local newValue = tostring(val)
		if newValue ~= nil then
			response = mc.mcRegSetValueString(item.RegHandle, newValue)
		end
	else
		local newValue = tonumber(val)
		if newValue ~= nil then
			response = mc.mcRegSetValue(item.RegHandle, newValue)
		end
	end
	if response == nil then
		PrintError("Invalid value sent to " .. tostring(item.Name))
		response = -1
	end
	return response
end
BaseFuncs.command.Get = function(item)
	if item == nil or item.Name == nil then
		PrintError("NIL values sent into command Get function")
		return -1
	end
	local str = string.format("GET " .. tostring(item.Name))
	local response, rc = mc.mcRegSendCommand(item.RegHandle, tostring(str))
	local subbed = string.gsub(response, ",","")
	return subbed, rc
end	
BaseFuncs.command.Set = function(item, val)
	if val == nil or item == nil or item.Name == nil then
		PrintError("NIL values sent into command Set function")
		return -1
	end
	if item.Name == nil then
		return -1
	end
	local str = string.format("SET " .. tostring(item.Name) .. "=" .. tostring(val))
	local response = mc.mcRegSendCommand(item.RegHandle, tostring(str))
	if response == "OK," then
		local inst = mc.mcGetInstance()
		if type(item.Info) ~= "table" then 
			return
		end
		if item.Info.DefValue ~= nil then
			rc = mcFile.IniSet(item.Info.Section, item.Info.Key, val, item.Info.Type)
			if rc ~= mc.MERROR_NOERROR then
				mc.mcCntlSetLastError(inst, "Error setting ini value for " .. tostring(item.Name) .. ", " .. tostring(rc) .." was returned")
			end
		end
	end
	return response
end	

if mcReg == nil then
	mcReg = require('mcRegister')
end
local AddAbstrationsRun = 0
function CreateRegister(Path, MMInfo)
	if MMInfo == nil then
		return 0
	end
	if MMInfo.Description == nil or MMInfo.IntialValue == nil or MMInfo.Persist == nil then
		return -1, "Register Creation Info Missing. Descrition = " .. tostring(MMInfo.Description) .. " Initial Value = " .. tostring(MMInfo.IntialValue) .. " Persist = " .. tostring(MMInfo.Persist)
	end
	if mcReg == nil then
		return -1, "Register Creation canceled because MachMaster module was missing"
	end
	local devStart, devEnd = Path:find("/")
	local device = Path:sub(0, devEnd-1)
	local path = Path:sub(devEnd+1)
	if type(MMInfo.IntialValue) == "function" then
		local tmp = MMInfo.IntialValue()
		if tmp ~= nil then
			MMInfo.IntialValue = tmp
		else
			return -1, "Initial Value Function Returned Nil for path: " .. path
		end
	end
	response, rc = mcReg.mcRegAddDel(inst, "ADD", device, path, MMInfo.Description, MMInfo.IntialValue, MMInfo.Persist) 
	if rc == mc.MERROR_NOERROR then
		PrintError("Register Successfully created with path: " .. tostring(Path))
		return 0
	end
	return -1, response
end
local function GetItem(self, Name)
	if self["Abstractions"] ~= nil then
		if self["Abstractions"][Name] == nil then
			self["Abstractions"][Name] = {}
		end
		item = self["Abstractions"][Name]
	else
		if self[Name] == nil then
			self[Name] = {}
		end
		item = self[Name]
	end
	return item
end
local mcAB = {}
mcAB.Abstractions = {}
-- Name is a String
-- Rpath can be a handle or path(String)
-- MMInfo is a string or nil
-- item is the abstraction item currently being edited or nil
function mcAB:SetPath(Name, Rpath, MMInfo, Item) 
	if Item == nil then
		Item = GetItem(self, Name)
	end
	local registerMissing = false
	if type(Rpath) == "string" then
		local hdl, rc = mc.mcRegGetHandle(inst, Rpath) 
		if rc ~= mc.MERROR_NOERROR then
			rc, response = CreateRegister(Rpath, MMInfo)
			if rc ~= mc.MERROR_NOERROR then
				registerMissing = true
				PrintError("Issue creating register for " .. tostring(Name) .. ". Return Code of " .. tostring(rc) .. ". String Response of " .. response .. ". Path of " .. tostring(Rpath))
			end
		end
		item.Path = Rpath
		item.RegHandle = hdl
	elseif type(Rpath) == "number" then
		item.RegHandle = Rpath
	else
		PrintError("Invalid path for " .. tostring(Name) .. ". Either input a handle or path for the register")
		return -1
	end
	if registerMissing == true then
		item.Get = function ()
		end
		item.Set = function ()
		end
		return -1
	end
end
-- MMInfo can be a table or nil. If it's a table then it should contain certain data depending on the type of register
function mcAB:AddToAbstractionLayer(itemName, Rtype, Rpath, MMInfo, ValType, GetFunc, SetFunc, Maxfunc, Minfunc)
	if type(self) ~= "table" then
		mc.mcCntlSetLastError(mc.mcGetInstance(), "AddToAbstractionLayer failed because first variable was supposed to be the mcAbstractions Table return")
		return
	end
	if debug == true then
		AddAbstrationsRun = AddAbstrationsRun + 1
	end
	local Name
	--itemName can be a string or a table so the name dosent have to be identical to the name thats sent to the command register
	if type(itemName) == "string" then
		Name = tostring(itemName)
	elseif type(itemName) == "table" then
		if tostring(itemName[1]) ~= nil then
			Name = tostring(itemName[1])
		end
	end
	if Name == nil then
		if debug then
			PrintError("Invalid name in Abstraction Layer at count " .. tostring(AddAbstrationsRun))
		else
			PrintError("Invalid name in Abstraction Layer. To find the position of issue enable debug in abstraction layer")
		end
	end
	local item = GetItem(self, Name)
	if type(itemName) == "string" then
		item.Name = tostring(itemName)
	elseif type(itemName) == "table" then
		if tostring(itemName[2]) ~= nil then
			item.Name = tostring(itemName[2])
		else
			item.Name = tostring(itemName[1])
		end
	end
	if type(Rtype) ~= "string" then
		PrintError("Invalid RegisterType for" .. tostring(Name) .. ". Currently is type(" .. type(Rtype) .. ") Must be a string value. ")
	end
	item.RegType = Rtype;
	if Rtype == "command" then
		item.Info = MMInfo
	elseif type(MMInfo) ~= "table" then
		MMInfo = {}
	end
	local rc = mcAB:SetPath(Name, Rpath, MMInfo, item)
	if rc == -1 then
		return
	end
	if type(ValType) ~= "string" then
		PrintError("Invalid ValueType for" .. tostring(Name) .. ". Currently is type(" .. type(ValType) .. ") Must be a string value. ")
	end
	
	item.ValueType = ValType;
	item.RunMinFunc = type(Minfunc) == "function"
	item.RunMaxFunc = type(Maxfunc) == "function"
	item.RunGetFunc = type(GetFunc) == "function"
	item.RunSetFunc = type(SetFunc) == "function"
	item.Get = function ()
		local num, rc = BaseFuncs[Rtype].Get(item)
		if item.RunMaxFunc == true then
			num = Maxfunc(num);
		end
		if item.RunMinFunc == true then
			num = Minfunc(num);
		end
		if item.RunGetFunc == true then
			num = GetFunc(num);
		end
		return num, rc-- should return any error 
	end
	item.Set = function(num)
		if item.RunSetFunc == true then
			num = SetFunc(num);
		end
		if item.RunMaxFunc == true then
			num = Maxfunc(num);
		end
		if item.RunMinFunc == true then
			num = Minfunc(num);
		end
		if num == nil and rc == mc.MERROR_NOERROR then
			PrintError("Possible issue with Set Modifier functions for " .. Name .. ". Returning because set value is NIL")
			return -1
		end
		return BaseFuncs[Rtype].Set(item, num) --Should return error
	end
	--Make Command Registers persist
	if Rtype == "command" and type(MMInfo) == "table" then
		local INIValue, rc = mcFile.IniGet(item.Info.Section, item.Info.Key, item.Info.DefValue, item.Info.Type)
		if rc ~= -1 then
			item.Set(INIValue)
		end
	end
end
function mcAB:AddAbstractionFunctionsToTable(TableToAddTo)
	TableToAddTo.AddToAbstractionLayer = mcAB.AddToAbstractionLayer
	TableToAddTo.SetPath = mcAB.SetPath
end
function mcAB:AddAbstractionsToTable(TableToAddTo)
	for name, tbl in pairs(mcAB["Abstractions"]) do
		TableToAddTo[name] = tbl
	end
end
function mcAB:PopulateCutStartSettings(ABC, CutStartSettingsDRORegisters)
	for droName, name in pairs(CutStartSettingsDRORegisters) do
		local selection = scr.GetProperty(droName, "Register")
		if ABC[name] ~= nil then
			if tostring(ABC[name].Path) ~= nil and selection ~= tostring(ABC[name].Path) then
				scr.SetProperty(droName, "Register", tostring(ABC[name].Path))
			end
		else
			mc.mcCntlSetLastError(mc.mcGetInstance(), "Value expected by dro init missing from Abstraction")
		end
	end
end
return mcAB