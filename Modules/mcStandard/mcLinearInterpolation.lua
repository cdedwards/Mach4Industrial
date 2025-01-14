LI = {}
function LI.GetClosestNumbers(target, tbl, target2) -- checks to make sure data exists in the table around the target(s)
	local below = nil
	local above = nil
	for thickness, angles in pairs(tbl) do
		if (below == nil or (math.abs(thickness - target) < math.abs(below - target))) and thickness < target then
			if target2 == nil then
				below = thickness
			else
				local close1, close2 = LI.GetClosestNumbers(target2, tbl[thickness])
				if close1 ~= nil and close2 ~= nil then
					below = thickness
				end
			end
		elseif (above == nil or (math.abs(thickness - target) < math.abs(above - target))) and thickness > target then
			if target2 == nil then
				above = thickness
			else
				local close1, close2 = LI.GetClosestNumbers(target2, tbl[thickness])
				if close1 ~= nil and close2 ~= nil then
					above = thickness
				end
			end
		elseif thickness == target then
			if target2 == nil then
				return thickness, thickness
			else
				local close1, close2 = LI.GetClosestNumbers(target2, tbl[thickness])
				if close1 ~= nil and close2 ~= nil then
					return thickness, thickness
				end
			end
		end
	end
	return below, above
end

function LI.GetSingleClosestNumber(target, tbl)
	local one = nil
	for thickness, angles in pairs(tbl) do
		if one == nil or (math.abs(thickness - target) <= one) then
			one = thickness
		end
	end
	return one
end

--[[------------------------------
	Config: Table - Of past information
	Thickness: Double - mm
]]--------------------------------
function LI.GetClosestNumberForSetting(target, tbl, setting) -- checks to make sure data exists in the table around the target(s)
	local below = nil
	local above = nil
	for thickness, angles in pairs(tbl) do
		if (below == nil or (math.abs(thickness - target) < math.abs(below - target))) and thickness <= target then
			if angles[setting] ~= nil then
				below = thickness
			end
		elseif (above == nil or (math.abs(thickness - target) < math.abs(above - target))) and thickness >= target then
			if angles[setting] ~= nil then
				above = thickness
			end
		end
	end
	
	return below, above
end
function LI.GetParameters(Config, indices, Thickness, EdgeCaseCheck)
	if Config ~= nil then -- checks if there's a missing name
		local returnThickness = Config[Thickness]
		if returnThickness == nil then
			returnThickness = {}
		end
		for _, name in pairs(indices) do
			if returnThickness[name] == nil then
				local CloseTx, CloseTy = LI.GetClosestNumberForSetting(Thickness,Config,name)
				if CloseTx == nil then
					return "Lack of Data Below Target For: " .. tostring(name)
				elseif CloseTy == nil then
					return "Lack of Data Above Target For: " .. tostring(name)
				else
					local RT
					if EdgeCaseCheck ~= nil then
						if type(EdgeCaseCheck) == "function" then
							RT = EdgeCaseCheck(Config, name, CloseTx, CloseTy, Thickness)
						end
					end
					if RT == nil then
						returnThickness[name] = LI.LinearInterpolation(Thickness, CloseTx, CloseTy, Config[CloseTx][name], Config[CloseTy][name])
					else
						returnThickness[name] = RT
					end
				end
			end
		end
		return returnThickness
	end
end
function LI.LinearInterpolation(x, x1, x2, y1, y2) -- is the known point of the cordinate
	local ans = y1 + (x-x1) * (y2 - y1) / (x2 - x1)
	return ans
end
return LI