--Bcs = require("mcBcs")
--Bcs.portOpen(inst)
--Bcs.portRead(inst)
--Bcs.portClose(inst)
--
--package.path = package.path .. ";./Modules/?.lua;"
--package.cpath = package.cpath .. ";./Modules/?.dll;"
-- Edit by Brian Barker 6/16/20 to get the path string from the file and the file extension 
-- EDIT by Brian Barker 11/19/2021 Return without trying to load the path for other uses cases if the DATA only is not nil 

	local mcBcs = {}
	--Screen load
	--Vars used in port functions
	local rs232 = require("luars232")
	local port_name = "COM5" -- This shouldn't need to be changed from the file
	local e = "rs232.RS232_ERR_NOERROR"
	local p = nil
	
	function mcBcs.runScan(inst, DataOnly) -- if DataOnly is set we will only 
		--machState, rc = mc.mcCntlGetState(inst);
		--Open or close our port
		if (p == nil)  then -- and (machState == 0)
			p = mcBcs.portOpen(inst)
		--elseif (p ~= nil) and (machState ~= 0) then
		--	mcBcs.portClose(inst, p)
	--		p = nil
		end
		
		--Read the ports queue
		if (p ~= nil) then --  and (machState == 0)
			return mcBcs.portRead(inst, p, DataOnly)
		end
	end
	
	function mcBcs.SetPort(name)
		port_name = name
	end 
	
	function mcBcs.portOpen(inst)
		local p = nil
		e, p = rs232.open(port_name)
		if e ~= rs232.RS232_ERR_NOERROR then -- handle error
			if mcBcs.FailedToOpen ~= true then
				io.stderr:write(string.format("can't open serial port '%s', error: '%s'\n", port_name, rs232.error_tostring(e)))
				mc.mcCntlSetLastError(inst, (string.format("can't open serial port '%s', error: '%s'\n", port_name, rs232.error_tostring(e))))
				mcBcs.FailedToOpen = true
			end
			return
		end
		if mcBcs.FailedToOpen == true then
			mc.mcCntlSetLastError(inst, string.format("Serial Port '%s' Opened Succesfully)", port_name))
			mcBcs.FailedToOpen = false
		end
		-- set port settings
		assert(p:set_baud_rate(rs232.RS232_BAUD_9600) == rs232.RS232_ERR_NOERROR)
		assert(p:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
		assert(p:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
		assert(p:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
		assert(p:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)
		
		--mc.mcCntlSetLastError(inst, (string.format("OK, port open with values '%s'\n", tostring(p))))
		return p
	end
	
	function mcBcs.portRead(inst, p, DataOnly)
		local read_len = 128 -- read one byte
		local data_read = ""
		local err = 0
		local bytes = 0
		local LastSize = 0
		err,bytes = p:in_queue();-- Test to see if we have bits in the buffer 
		assert(err == rs232.RS232_ERR_NOERROR)
		if bytes == 0 then return end
		
		local newBytes = 0 
		wx.wxMilliSleep(50)--Wait a little before we peek in to see if we have new data
		
		err,newBytes = p:in_queue();-- Test to see if we hafe bits in the buffer 
		assert(err == rs232.RS232_ERR_NOERROR)
		
		if(bytes ~= newBytes)then return end
		--p:read will lock your GUI up so only do it periodically
		err, data_read, size = p:read(read_len)--Read this all in one read (it is in a buffer in the 232 Lib)
		assert(err == rs232.RS232_ERR_NOERROR)
		if(DataOnly ~= nil) then -- The function ends here if we only want to have the data that is in the scanner 
			return tostring(data_read);
		end 
		--mc.mcCntlSetLastError(inst, 'Read: ' .. tostring(data_read))
		local machDir = mc.mcCntlGetMachDir(inst)
		local FilePath = (tostring(machDir) .. "/GcodeFiles/" .. tostring(data_read) .. ".tap") 
		--local FilePath =  "C:\\VeloxCNCHunterD\\GcodeFiles\\Zone1.tap"
		--local FilePath =   tostring(data_read)  --  Simply read the string and use it!
		FilePath = string.gsub(FilePath, "\n", "")--Remove New Line Feed
		FilePath = string.gsub(FilePath, "\r", "")--Remove any Return
		FilePath = string.gsub(FilePath, "\13", "")--Remove any Return
		--Loop here looking for a file
		local found = wx.wxFileExists(tostring(FilePath))
		if(found == true) then -- we found the file
			mc.mcCntlLoadGcodeFile(inst, tostring(FilePath))
			rc = mc.mcToolPathGenerate(inst)
			local percent
			repeat
				percent, rc = mc.mcToolPathGeneratedPercent(inst)
			until (percent == 100)
		else
			mc.mcCntlSetLastError(inst, "No such file exist!: " ..  tostring(FilePath))
		end
		return FilePath
	end
	
	function mcBcs.portClose(inst, p)
		assert(p:close() == rs232.RS232_ERR_NOERROR)
		p = nil
		mc.mcCntlSetLastError(inst, 'Port Closed')
	end

return mcBcs