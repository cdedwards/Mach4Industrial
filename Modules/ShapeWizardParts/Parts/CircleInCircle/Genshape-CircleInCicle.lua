require("ShapeLibShapeFunctions")
local Origin = {["x"] = 0, ["y"] = 0}
PartConfig = {["Origin"] = {["Value"] = Origin}}
Part = InitPart("CircleInCircle", PartConfig, Blank, Dia)

local IHoleDiameter = 4

local Shape1 = {}
Shape1.Config = {
	["HoleDiameter"] = {["Name"] = "D1", ["Value"] = IHoleDiameter},
	["Direction"] = {["Value"] = "CCW"},
	
	}
Shape1.ShapePosition = 1
Shape1.FunctionsName = "Circle"
Part = AddCircle(Part, Shape1)

local OutsideHoleDia = 6
local Shape2 = {}
Shape2.Config = {
	["HoleDiameter"] = {["Name"] = "D2", ["Value"] = OutsideHoleDia},
	["Direction"] = {["Value"] = "CCW"}
	}
Shape2.ShapePosition = 2
Shape2.FunctionsName = "Circle"
Part = AddCircle(Part, Shape2)
Part.Modifiers[Shape1.Config.HoleDiameter.Name] = function(self, mod)
	if self.Shapes[2].Config.HoleDiameter.Value <= mod then
		return
	end
	return 0
end
Part.Modifiers[Shape2.Config.HoleDiameter.Name] = function(self, mod)
	if self.Shapes[1].Config.HoleDiameter.Value >= mod then
		return
	end
	return 0
end
return Part