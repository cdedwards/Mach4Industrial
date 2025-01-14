require("ShapeLibShapeFunctions")
local Origin = {["x"] = 0,["y"] = 0}
local Rotation = 0
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("Right Triangle", PartConfig)

local LegSize1 = 2
local LegSize2 = 5
local FiletRad = 0
local Rect = {}
Rect.Config = {
	["Leg1Size"] = {["Name"] = "L1", ["Value"] = LegSize1},
	["Leg2Size"] = {["Name"] = "L2", ["Value"] = LegSize2},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
	}
Rect.ShapePosition = 1
Rect.FunctionsName = "RightTri"
Part = AddRightTri(Part, Rect)

return Part