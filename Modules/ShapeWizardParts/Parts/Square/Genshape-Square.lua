require("ShapeLibShapeFunctions")
local Origin = {["x"] = 1.5,["y"] = 1.5}
local Rotation = 0

PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("Square", PartConfig)

local XSize = 2
local YSize = 2
local FiletRad = .5
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L1", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L2", ["Value"] = YSize},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
	}
Rect.ShapePosition = 1
Rect.FunctionsName = "Rectangle"
Part = AddRectangle(Part, Rect)

	return Part