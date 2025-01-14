require("ShapeLibShapeFunctions")
local Origin = {["x"] = 0,["y"] = 0}
local Rotation = 0
PartConfig = {["Origin"] = {["Value"] = Origin}, ["Rotation"] = {["Name"] = "R", ["Value"] = Rotation}}
Part = InitPart("Fish Plate", PartConfig)

local XSize = 3
local YSize = 3
local LegSize = 5
local FiletRad = .5
local Rect = {}
Rect.Config = {
	["XSize"] = {["Name"] = "L1", ["Value"] = XSize},
	["YSize"] = {["Name"] = "L3", ["Value"] = YSize},
	["LegSize"] = {["Name"] = "L2", ["Value"] = LegSize, AllowNonPositive = {Negative = true, Zero = false}},
	["Filet"] = {["Name"] = "F", ["Value"] = FiletRad}
	}
Rect.ShapePosition = 1
Rect.FunctionsName = "FishPlate"
Part = AddFishPlate(Part, Rect)

	return Part