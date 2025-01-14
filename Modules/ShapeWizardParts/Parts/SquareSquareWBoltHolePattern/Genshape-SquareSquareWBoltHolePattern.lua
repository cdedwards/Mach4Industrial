require("ShapeLibShapeFunctions")

local Origin = {["x"] = 0,["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = 0}}
Part = InitPart("SquareWBoltHolePattern", PartConfig)

local XSizeI = 2
local YSizeI = 2
local FiletRadI = 0
local Rect1 = {}
Rect1.Config = {
	["XSize"] = {["Name"] = "L3", ["Value"] = XSizeI},
	["YSize"] = {["Name"] = "L4", ["Value"] = YSizeI},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRadI}
	}
Rect1.ShapePosition = 1
Rect1.FunctionsName = "Rectangle"
Part1 = AddRectangle(Part, Rect1)
-- Make sure that if HoleDiameter is 0 it's treated as a square with a center square
Part.Modifiers[Rect1.Config.XSize.Name] = function(self, mod)
	if self.Shapes[2].Config.HoleDiameter.Value > 0 then
		if self.Shapes[2].Config.XExtent.Value - self.Shapes[2].Config.HoleDiameter.Value <= mod then
			return
		end
	else
		if self.Shapes[3].Config.XSize.Value <= mod then
			return
		end
	end
	return 0
end
Part.Modifiers[Rect1.Config.YSize.Name] = function(self, mod)
	if self.Shapes[2].Config.HoleDiameter.Value > 0 then
		if self.Shapes[2].Config.YExtent.Value - self.Shapes[2].Config.HoleDiameter.Value <= mod then
			return
		end
	else
		if self.Shapes[3].Config.YSize.Value <= mod then
			return
		end
	end
	return 0
end

local HoleDiameter = .5
local YOffset = 3
local XOffset = 3
local XHoleCount = 3
local YHoleCount = 3
local XSize = 4
local YSize = 4

local Shape = {}
Shape.Config = {
	["HoleDiameter"] = {["Name"] = "D", ["Value"] = HoleDiameter},
	["Direction"] = {["Value"] = "CCW"},
	["XExtent"] = {["Name"] = "L5", ["Value"] = XOffset},
	["YExtent"] = {["Name"] = "L6", ["Value"] = YOffset},
	["XHoleCount"] = {["Name"] = "HL1", ["Prefix"] = "#", ["Value"] = XHoleCount},
	["YHoleCount"] = {["Name"] = "HL2", ["Prefix"] = "#", ["Value"] = YHoleCount}
	}
Shape.ShapePosition = 2
Shape.FunctionsName = "HolePattern"
Part = AddHolePattern(Part, Shape)


Part.Modifiers[Shape.Config.HoleDiameter.Name] = function(self, mod)
	-- Outside Square
	if self.Shapes[3].Config.XSize.Value <= mod + self.Shapes[2].Config.XExtent.Value then
		return
	end
	if self.Shapes[3].Config.YSize.Value <= mod + self.Shapes[2].Config.YExtent.Value then
		return
	end
	-- Inside Square
	if self.Shapes[1].Config.XSize.Value >= self.Shapes[2].Config.XExtent.Value - mod then
		return
	end
	if self.Shapes[1].Config.YSize.Value >= self.Shapes[2].Config.YExtent.Value - mod then
		return
	end
	return 0
end
Part.Modifiers[Shape.Config.XExtent.Name] = function(self, mod)
	-- Outside Square
	if self.Shapes[3].Config.XSize.Value <= self.Shapes[2].Config.HoleDiameter.Value + mod then
		return
	end
	-- Inside Square
	if self.Shapes[1].Config.XSize.Value >= mod - self.Shapes[2].Config.HoleDiameter.Value then
		return
	end
	return 0
end
Part.Modifiers[Shape.Config.YExtent.Name] = function(self, mod)
	if self.Shapes[3].Config.YSize.Value <= self.Shapes[2].Config.HoleDiameter.Value + mod then
		return
	end
	-- Inside Square
	if self.Shapes[1].Config.YSize.Value >= mod - self.Shapes[2].Config.HoleDiameter.Value then
		return
	end
	return 0
end

local FiletRad = .5
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L1", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L2", ["Value"] = YSize},
	["Filet"] = {["Name"] = "F2", ["Value"] = FiletRad}
	}
Rect.ShapePosition = 3
Rect.FunctionsName = "Rectangle"
Part = AddRectangle(Part, Rect)

Part.Modifiers[Rect.Config.XSize.Name] = function(self, mod)
	if self.Shapes[2].Config.HoleDiameter.Value > 0 then
		if self.Shapes[2].Config.XExtent.Value + self.Shapes[2].Config.HoleDiameter.Value >= mod then
			return
		end
	else
		if self.Shapes[1].Config.XSize.Value >= mod then
			return
		end
	end
	return 0
end
Part.Modifiers[Rect.Config.YSize.Name] = function(self, mod)
	if self.Shapes[2].Config.HoleDiameter.Value > 0 then
		if self.Shapes[2].Config.YExtent.Value + self.Shapes[2].Config.HoleDiameter.Value >= mod then
			return
		end
	else
		if self.Shapes[1].Config.YSize.Value >= mod then
			return
		end
	end
	return 0
end
Part.Modifiers[Rect.Config.Filet.Name] = function(self, mod)
	if self.Shapes[2].Config.XHoleCount == 1 and self.Shapes[2].Config.YHoleCount == 1 then -- Always valid if the filet is abiding by the default rectangle rules
		return 0
	end
	--local FiletX, FiletY = GetFiletTopRight(self.Shapes[3].Config.XSize.Value, self.Shapes[3].Config.YSize.Value, self.Shapes[3].Config.Filet.Value)
	local Dia = self.Shapes[2].Config.HoleDiameter.Value
	local XExtent, YExtent = self.Shapes[2].Config.XExtent.Value, self.Shapes[2].Config.YExtent.Value
	
	local Filet = mod
	
	local xOrigin = Part.Config["Origin"].Value.x
	local yOrigin = Part.Config["Origin"].Value.y
	
	local RadiusCenterX, RadiusCenterY = (xOrigin + self.Shapes[3].Config.XSize.Value/2) - Filet, (yOrigin + self.Shapes[3].Config.YSize.Value/2)- Filet
	
	local CenterX, CenterY = (xOrigin + XExtent/2), (yOrigin + YExtent/2) 
	
	if RadiusCenterX > CenterX and RadiusCenterY > CenterY then
		return 0
	end
	local DistFromHoleCenter = math.sqrt(((CenterX - RadiusCenterX)*(CenterX - RadiusCenterX)) + ((CenterY - RadiusCenterY)*(CenterY - RadiusCenterY)))
	
	print(DistFromHoleCenter + Dia/2)
	if DistFromHoleCenter + Dia/2 > Filet then
		return
	end
	return 0
end
return Part