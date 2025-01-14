require("ShapeLibShapeFunctions")
local Origin = {["x"] = 0,["y"] = 0}
local Rotation = 0
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("Equilateral Triangle", PartConfig)

local LegSize = 3
local FiletRad = .5
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L1", ["Value"] = LegSize},
	["Sides"] = {["Value"] = 3},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
	}
Rect.ShapePosition = 1
Rect.FunctionsName = "Polygon"
local Part, pos = CheckRequirements(Part, Rect)
-- If the program gets this far then everything required to run has been supplied
Part.RegeneratePoints[pos] = function(Part, i)
	local xOrigin, yOrigin = GetOrigin(Part, i)
	local Shape = Part.Shapes[i]
	Shape.Paths = CutPolygon(nil, {["x"] = xOrigin, ["y"] = yOrigin}, Shape.Config["Sides"].Value, Shape.Config["XSize"].Value, -30, 0, 0, 0)
	Shape["BeforeFilet"] = deepcopy(Shape.Paths)
	Part = Filet(Part,i)
	return Part
end
Part.RegeneratePoints[pos](Part, pos)

return Part