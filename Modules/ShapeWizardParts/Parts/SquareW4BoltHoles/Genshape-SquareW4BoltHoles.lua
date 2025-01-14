require("ShapeLibShapeFunctions")
local HoleDiameter = .5
local XHoleCount = 2
local YHoleCount = 2
local YOffset = 3
local XOffset = 3
local XSize = 4
local YSize = 4

local Origin = {["x"] = 0,["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = 0}}
Part = InitPart("SquareW4BoltHoles", PartConfig)
local FiletRad = .25
local Rotation = 0
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L1", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L2", ["Value"] = YSize},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
	}
Rect.ShapePosition = 2
Rect.FunctionsName = "Rectangle"
Part = AddRectangle(Part, Rect)

Part.Modifiers[Rect.Config.XSize.Name] = function(self, mod)
	if self.Shapes[1].Config.XExtent.Value + self.Shapes[1].Config.HoleDiameter.Value >= mod then
		return
	end
	return 0
end
Part.Modifiers[Rect.Config.YSize.Name] = function(self, mod)
	if self.Shapes[1].Config.YExtent.Value + self.Shapes[1].Config.HoleDiameter.Value >= mod then
		return
	end
	return 0
end

local Shape = {}
Shape.Config = {
	["HoleDiameter"] = {["Name"] = "D", ["Value"] = HoleDiameter},
	["Direction"] = {["Value"] = "CCW"},
	["XExtent"] = {["Name"] = "L3", ["Value"] = XOffset},
	["YExtent"] = {["Name"] = "L4", ["Value"] = YOffset},
	["XHoleCount"] = {["Value"] = XHoleCount},
	["YHoleCount"] = {["Value"] = YHoleCount}
	}
Shape.ShapePosition = 1
Shape.FunctionsName = "HolePattern"
Part = AddHolePattern(Part, Shape)

Part.Modifiers[Shape.Config.HoleDiameter.Name] = function(self, mod)
	if self.Shapes[2].Config.XSize.Value <= mod + self.Shapes[1].Config.XExtent.Value then
		return
	end
	if self.Shapes[2].Config.YSize.Value <= mod + self.Shapes[1].Config.YExtent.Value then
		return
	end
	return 0
end
Part.Modifiers[Shape.Config.XExtent.Name] = function(self, mod)
	if self.Shapes[2].Config.XSize.Value <= self.Shapes[1].Config.HoleDiameter.Value + mod then
		return
	end
	return 0
end
Part.Modifiers[Shape.Config.YExtent.Name] = function(self, mod)
	if self.Shapes[2].Config.YSize.Value <= self.Shapes[1].Config.HoleDiameter.Value + mod then
		return
	end
	return 0
end

return Part