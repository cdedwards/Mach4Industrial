local rc, mcSP = pcall(require, "./Modules/mcSysPaths")
if rc == false then
	mc.mcCntlSetLastError(inst, string.format("Require in '%s' could not find file. Error: %s", tostring(debug.getinfo(1).short_src), mcSP))
	return
end
mcSP.SetupPaths(".")
require("ShapeLibShapeFunctions")
local HoleDiameter = .5
local XHoleCount = 2
local YHoleCount = 2
local YOffset = 1.25
local XOffset = 1.25
local XSize = 2
local YSize = 2

local Origin = {["x"] = 0,["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = 0}}
Part = InitPart("Motor Plate", PartConfig)

local Shape = {}
local width = .25
local height = .5
Shape.Config = {
	["XSize"] = {Name = "L5", Value = width},
	["YSize"] = {["Name"] = "L6", ["Value"] = height},
	["XExtent"] = {["Name"] = "L3", ["Value"] = XOffset},
	["YExtent"] = {["Name"] = "L4", ["Value"] = YOffset},
	["Filet"] = {["Value"] = width/2},
	["XHoleCount"] = {["Value"] = 2},
	["YHoleCount"] = {["Value"] = 2}
}
Shape.ShapePosition = 1
Shape.FunctionsName = "SlotPattern"
Part = AddSlotPattern(Part, Shape)

Part.Modifiers[Shape.Config.XExtent.Name] = function(self, mod)
	if mod + self.Shapes[1].Config.XSize.Value > self.Shapes[2].Config.XSize.Value then
		return
	end
	return 0
end
Part.Modifiers[Shape.Config.YExtent.Name] = function(self, mod)
	if mod + self.Shapes[1].Config.YSize.Value > self.Shapes[2].Config.YSize.Value then
		return
	end
	return 0
end

local FiletRad = .25
local Rotation = 0
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L2", ["Value"] = 2},
	["YSize"] = {["Name"] = "L1", ["Value"] = 2},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
	}
Rect.ShapePosition = #Part["Shapes"] + 1
Rect.FunctionsName = "Rectangle"
Part = AddRectangle(Part, Rect)

Part.Modifiers[Rect.Config.XSize.Name] = function(self, mod)
	if self.Shapes[1].Config.XExtent.Value + self.Shapes[1].Config.XSize.Value > mod then
		return
	end
	return 0
end
Part.Modifiers[Rect.Config.YSize.Name] = function(self, mod)
	if self.Shapes[1].Config.YExtent.Value + self.Shapes[1].Config.YSize.Value > mod then
		return
	end
	return 0
end

return Part