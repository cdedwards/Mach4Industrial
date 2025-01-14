-- filename: 
-- version: lua53
-- line: [0, 0] id: 0
local acHoming = {}
local inst = mc.mcGetInstance("acHoming module")
local r2_0 = "acHoming module: "
local rc = mc.MERROR_NOERROR
local r4_0 = {
  mc.X_AXIS,
  mc.Y_AXIS,
  mc.Z_AXIS,
  mc.A_AXIS,
  mc.B_AXIS
}

acHoming = acHoming
--- pf = pf or require("PanelFunctions")

function acHoming.GetAxesActiveForHoming(r0_1)

  local inst = mc.mcGetInstance("acHoming GetAxesActiveForHoming()")
  local function r2_1(r0_2)
    mc.mcCntlLog(inst, string.format("%s%s", r2_0, r0_2)("@acHoming:GetAxesActiveForHoming"), 0)
  end
  
  local r3_1 = {}
  
  for r7_1, r8_1 in pairs(r4_0) do
    local r9_1, rc = mc.mcAxisGetHomeOrder(inst, r8_1)
    if rc ~= mc.MERROR_NOERROR then
      r2_1(string.format("failure to get %s home order, rc = %s", r8_1, rc))
      return {}, rc
    end
    local r11_1, r12_1 = mc.mcAxisIsEnabled(inst, r8_1)
    if r12_1 ~= mc.MERROR_NOERROR then
      r2_1(string.format("failure to get %s enabled state, rc = %s", r8_1, r12_1))
      return {}, r12_1
    end
    if r9_1 ~= 0 and r11_1 == 1 then
      table.insert(r3_1, r8_1)
    end
  end
  return r3_1, mc.MERROR_NOERROR -- returns a table or nil
end


function acHoming.GetAllAxesHomed(r0_3, r1_3)
  local inst = mc.mcGetInstance("acHoming GetAllAxesHomed()")
  local rc = mc.MERROR_NOERROR
  
  local function r4_3(r0_4)
    mc.mcCntlLog(inst, string.format("%s%s", r2_0, r0_4), "@acHoming:GetAllAxesHomed", 0)
  end
  if r1_3 ~= nil and type(r1_3) ~= "table" then
    r4_3(string.format("invalid parameter type, expected = table, actual = ", type(r1_3)))
    return false, mc.MERROR_INVALID_PARAM
  end
  if not r1_3 then
    r1_3, rc = acHoming:GetAxesActiveForHoming()
    if rc ~= mc.MERROR_NOERROR then
      r4_3(string.format("failed to get axes active for homing, rc = %s", rc))
      return false, rc
    end
  end
  
  for r8_3, r9_3 in pairs(r1_3) do
    local r10_3, rc = mc.mcAxisIsHomed(inst, r9_3)
    if rc ~= mc.MERROR_NOERROR then
      r4_3(string.format("failed to get homed state of %s, rc = %s", r9_3, rc))
      return false, rc
    elseif r10_3 ~= 1 then
      return false, mc.MERROR_NOERROR
    end
  end
  
  return true, mc.MERROR_NOERROR
end


function acHoming.DerefAllAxes(r0_5)

  local inst = mc.mcGetInstance("acHoming DerefAllAxes()")
  local function r2_5(r0_6)
    mc.mcCntlLog(inst, string.format("%s%s", r2_0, r0_6), "@acHoming:GetAllAxesHomed", 0)
  end
  
  local rc = mc.mcAxisDerefAll(inst)
  if rc ~= mc.MERROR_NOERROR then
    r2_5(string.format("failed to deref all axes, rc = %s", rc))
    return rc
  end
  --pf.DisableSoftLimitAll()
  return mc.MERROR_NOERROR
end
return acHoming
