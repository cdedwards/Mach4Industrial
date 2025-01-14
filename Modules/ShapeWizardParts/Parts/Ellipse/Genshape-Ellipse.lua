require("ShapeLibShapeFunctions")

local Origin = {["x"] = 0,["y"] = 0}
local Rotation = 0
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("Ellipse", PartConfig)

local XSize = 2
local YSize = 3
local FiletRad = .5
local Ellipse = {}
Ellipse.Config = {
	["XSize"] = {["Name"] = "L2", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L1", ["Value"] = YSize}
	}
Ellipse.ShapePosition = 1
Ellipse.FunctionsName = "Ellipse"
Part = AddEllipse(Part, Ellipse)

	return Part