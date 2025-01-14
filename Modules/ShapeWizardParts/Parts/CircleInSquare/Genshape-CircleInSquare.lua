local rc, mcSP = pcall(require, "./Modules/mcSysPaths")
if rc == false then
	mc.mcCntlSetLastError(inst, string.format("Require in '%s' could not find file. Error: %s", tostring(debug.getinfo(1).short_src), mcSP))
	return
end
mcSP.SetupPaths(".")
require("ShapeLibShapeFunctions")
local XSize = 5
local YSize = 3
local Origin = {["x"] = XSize/2, ["y"] = YSize/2}
local Rotation = 0
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("CircleInSquare", PartConfig)


local FiletRad = 0
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
	if self.Shapes[1].Config.HoleDiameter.Value >= mod then
		return
	end
	return 0
end
Part.Modifiers[Rect.Config.YSize.Name] = function(self, mod)
	if self.Shapes[1].Config.HoleDiameter.Value >= mod then
		return
	end
	return 0
end

local HoleDiameter = 1
local Shape = {}
Shape.Config = {
	["HoleDiameter"] = {["Name"] = "D", ["Value"] = HoleDiameter},
	["Direction"] = {["Value"] = "CCW"}
	}
Shape.ShapePosition = 1
Shape.FunctionsName = "Circle"
Part = AddCircle(Part, Shape)

Part.Modifiers[Shape.Config.HoleDiameter.Name] = function(self, mod)
	if self.Shapes[2].Config.XSize.Value <= mod then
		return
	end
	if self.Shapes[2].Config.YSize.Value <= mod then
		return
	end
	return 0
end
	return Part