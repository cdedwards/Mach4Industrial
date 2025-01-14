local rc, mcSP = pcall(require, "./Modules/mcSysPaths")
if rc == false then
	mc.mcCntlSetLastError(inst, string.format("Require in '%s' could not find file. Error: %s", tostring(debug.getinfo(1).short_src), mcSP))
	return
end
mcSP.SetupPaths(".")
require("ShapeLibShapeFunctions")
--(Start, Center, End, Direction)
local Origin = {["x"] = 0,["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}}
Part = InitPart("Capped Rectangle", PartConfig)
local XSize = 4
local YSize = 2

local Rotation = 0
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L1", ["Value"] = XSize},
	["YSize"] = {["Name"] = "W1", ["Value"] = YSize},
	["Rotation"] = {["Name"] = "R", ["Value"] = Rotation},
	["Filet"] = {["Value"] = YSize/2}
	}
Rect.ShapePosition = 1
Rect.FunctionsName = "Slot"
Part = AddRectangle(Part, Rect)

return Part