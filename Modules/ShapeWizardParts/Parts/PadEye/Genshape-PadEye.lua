require("ShapeLibShapeFunctions")
local Origin = {["x"] = 0,["y"] = 0}
local Rotation = 0
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("PadEye", PartConfig)

local XSize = 2
local YSize = 2
local EyeWidth = .5
local Shape = {}
Shape.Config = {
	["XSize"] = {["Name"] = "L2", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L1", ["Value"] = YSize},
	["HoleDiameter"] = {Name = "D", Value = 1, AllowNonPositive = {Negative = false, Zero = true}},-- We still need name incase the image isn't there
	["Filet"] = {["Name"] = "F", ["Value"] = 0}
	}
Shape.ShapePosition = 1
Shape.FunctionsName = "PadEye"
Part = AddPadEye(Part, Shape)

return Part