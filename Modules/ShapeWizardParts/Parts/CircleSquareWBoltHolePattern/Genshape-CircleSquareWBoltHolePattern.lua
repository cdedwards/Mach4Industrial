require("ShapeLibShapeFunctions")

local Origin = {["x"] = 0,["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = 0}}
Part = InitPart("SquareWBoltHolePattern", PartConfig)

local IHoleDiameter = 1
local Circle = {}
Circle.Config = {
	["HoleDiameter"] = {["Name"] = "R2", ["Value"] = IHoleDiameter},
	["Direction"] = {["Value"] = "CCW"},
	}
Circle.ShapePosition = 1
Circle.FunctionsName = "Circle"
Part = AddCircle(Part, Circle)

Part.Modifiers[Circle.Config.HoleDiameter.Name] = function(self, mod)
	if self.Shapes[2].Config.HoleDiameter.Value > 0 then
		if self.Shapes[2].Config.XExtent.Value - self.Shapes[2].Config.HoleDiameter.Value <= mod then
			return
		end
		if self.Shapes[2].Config.YExtent.Value - self.Shapes[2].Config.HoleDiameter.Value <= mod then
			return
		end
	else
		if self.Shapes[3].Config.XSize.Value <= mod then
			return
		end
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
	["HoleDiameter"] = {["Name"] = "R1", ["Value"] = HoleDiameter},
	["Direction"] = {["Value"] = "CCW"},
	["XExtent"] = {["Name"] = "L6", ["Value"] = XOffset},
	["YExtent"] = {["Name"] = "L5", ["Value"] = YOffset},
	["XHoleCount"] = {["Name"] = "H L2", ["Prefix"] = "#", ["Value"] = XHoleCount},
	["YHoleCount"] = {["Name"] = "H L1", ["Prefix"] = "#", ["Value"] = YHoleCount}
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
	if self.Shapes[1].Config.HoleDiameter.Value >= self.Shapes[2].Config.XExtent.Value - mod then
		return
	end
	if self.Shapes[1].Config.HoleDiameter.Value >= self.Shapes[2].Config.YExtent.Value - mod then
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
	if self.Shapes[1].Config.HoleDiameter.Value >= mod - self.Shapes[2].Config.HoleDiameter.Value then
		return
	end
	return 0
end
Part.Modifiers[Shape.Config.YExtent.Name] = function(self, mod)
	if self.Shapes[3].Config.YSize.Value <= self.Shapes[2].Config.HoleDiameter.Value + mod then
		return
	end
	-- Inside Square
	if self.Shapes[1].Config.HoleDiameter.Value >= mod - self.Shapes[2].Config.HoleDiameter.Value then
		return
	end
	return 0
end

local FiletRad = .5
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L2", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L3", ["Value"] = YSize},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
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
		if self.Shapes[1].Config.HoleDiameter.Value >= mod then
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
		if self.Shapes[1].Config.HoleDiameter.Value >= mod then
			return
		end
	end
	return 0
end
return Part