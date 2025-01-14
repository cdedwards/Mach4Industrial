local rc, mcSP = pcall(require, "./Modules/mcSysPaths")
if rc == false then
	mc.mcCntlSetLastError(inst, string.format("Require in '%s' could not find file. Error: %s", tostring(debug.getinfo(1).short_src), mcSP))
	return
end
mcSP.SetupPaths(".")
require("ShapeLibShapeFunctions")

local Origin = {["x"] = 0,["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = 0}}
Part = InitPart("BoltHoleCircle", PartConfig)

local HoleDiameter = .5
local HoleCount = 6
local BoltCircleDiameter = 8
local Shape = {}
Shape.Config = {
	["HoleDiameter"] = {["Name"] = "D1", ["Value"] = HoleDiameter},
	["HoleCount"] = {["Name"] = "H", ["Prefix"] = "#", ["Value"] = HoleCount},
	["BoltCircleDiameter"] = {["Name"] = "D2", ["Value"] = BoltCircleDiameter}
	}
Shape.ShapePosition = 1
Shape.FunctionsName = "BoltHoleCircle"
Shape.Modifiers = {}
Shape.Modifiers["HoleDiameter"] = function(self, mod)
	local Config = Shape.Config
	local borerad = (self.Config.BoltCircleDiameter.Value/2) / math.cos(math.pi/self.Config.HoleCount.Value)
	local d = 2 * math.pi/self.Config.HoleCount.Value
	local sideLength = borerad * d
	if sideLength/2 < mod then
		return
	end
	return 0
end
Shape.Modifiers["HoleCount"] = function(self, mod)
	if mod == 1 then
		return 0
	end
	local Config = Shape.Config
	local borerad = (self.Config.BoltCircleDiameter.Value/2) / math.cos(math.pi/mod)
	local d = 2 * math.pi/mod
	local sideLength = borerad * d
	local vertexCount = math.pi / math.asin(sideLength / self.Config.BoltCircleDiameter.Value)
	if sideLength/2 < self.Config.HoleDiameter.Value then
		return
	end
	return 0
end
Shape.Modifiers["BoltCircleDiameter"] = function(self, mod)
	local Config = Shape.Config
	local borerad = (mod/2) / math.cos(math.pi/self.Config.HoleCount.Value)
	local d = 2*math.pi/self.Config.HoleCount.Value
	local sideLength = borerad * d
	if sideLength/2 < self.Config.HoleDiameter.Value then
		return
	end
	return 0
end
Part = AddBoltHoleCircle(Part, Shape)

return Part