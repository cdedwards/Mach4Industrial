require("ShapeLibShapeFunctions")
local Origin = {["x"] = 0, ["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}}
Part = InitPart("Circle", PartConfig)

local HoleDiameter = 6

local Shape = {}
Shape.Config = {
	["HoleDiameter"] = {["Name"] = "D", ["Value"] = HoleDiameter},
	["Direction"] = {["Value"] = "CCW"},
	
	}
Shape.ShapePosition = 1
Shape.FunctionsName = "Circle"
Part = AddCircle(Part, Shape)

return Part