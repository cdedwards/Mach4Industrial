-- filename: 
-- version: lua53
-- line: [0, 0] id: 0
local r0_0 = mc.mcGetInstance("SpindleWarmUp")
local r2_0 = mc.mcCntlGetMachDir(r0_0) .. "\\Modules\\AvidCNC\\?.luac"
local r3_0 = mc.MERROR_NOERROR
local r4_0 = {}
SpindleWarmUp = r4_0
local r5_0 = {
  msgBase = "Spindle Warm-Up: ",
  configFile = "Spindle.json",
  preState = {},
}
if not string.find(package.path, r2_0) then
  package.path = package.path .. ";" .. r2_0 .. ";"
end
pf = pf or require("PanelFunctions")
function r4_0.Log(r0_1)
  -- line: [20, 27] id: 1
  mc.mcCntlLog(r0_0, string.format("%s%s", r5_0.msgBase, r0_1), "", -1)
end
function r4_0.History(r0_2, r1_2)
  -- line: [29, 38] id: 2
  mc.mcCntlSetLastError(r0_0, string.format("%s%s", r5_0.msgBase, r0_2))
  if r1_2 then
    wx.wxMessageBox(r0_2, "Spindle Warm-Up")
  end
end
function r4_0.Dialog()
  -- line: [40, 158] id: 3
  local r0_3 = ""
  local r1_3 = ""
  local r2_3 = pf.GetSpindleTypeName(mc.mcProfileGetInt(r0_0, "AvidCNC_Profile", "iConfigSpindleType", 0))
  local r3_3 = pf.ReadJSON(string.format("\\Modules\\AvidCNC\\Config\\%s", r5_0.configFile))
  if not r3_3 then
    r4_0.Log(string.format("Failed to load configuration file (%s)", r5_0.configFile))
    r4_0.History("Failed to load spindle configuration data.", true)
    return 
  elseif not r3_3.Spindles[r2_3] then
    r4_0.Log(string.format("Failed to load spindle data for spindle name: %s", r2_3))
    r4_0.History("Failed to load spindle configuration data.", true)
    return 
  else
    r4_0.Log("Spindle data loaded for " .. r2_3)
  end
  r5_0.preState.rpm, r3_0 = mc.mcSpindleGetCommandRPM(r0_0)
  r5_0.preState.override, r3_0 = mc.mcSpindleGetOverride(r0_0)
  r5_0.start = avd.WarningDialog("Spindle Warm-Up", "Spindle warm-up procedure for " .. r2_3 .. "." .. "\n\n" .. r3_3.WarnBeforeSequenceMessage .. "\n\nClick OK to start warm-up procedure", "iShowWarningSpindleWarmUp", false)
  if r5_0.start ~= 0 then
    return 
  end
  r3_0 = mc.mcSpindleSetOverride(r0_0, 1)
  r4_0.Log("Spindle override set to 1 before warm-up, rc=" .. r3_0)
  r5_0.sequence = r3_3.Spindles[r2_3].WarmUp
  r5_0.max = r3_3.Spindles[r2_3].DefaultVMax
  warmUpRunning = true
  for r7_3 = 1, #r5_0.sequence, 1 do
    if warmUpRunning then
      local r8_3 = r5_0.max * r5_0.sequence[r7_3].Speed
      local r9_3 = r5_0.sequence[r7_3].Duration * 60
      r4_0.History(string.format("Step %s of %s, %.0f RPM for %.0f minutes", r7_3, #r5_0.sequence, r8_3, r9_3 / 60))
      r0_3 = string.format("M3 S%s\nG04 P%.1f", r8_3, r9_3)
      if r7_3 == #r5_0.sequence then
        r0_3 = r0_3 .. "\nM5"
        if r0_3 then
          r0_3 = r0_3
        end
      end
      r3_0 = mc.mcCntlMdiExecute(r0_0, r0_3)
      r4_0.Log(string.format("Starting step %s/%s, command: %s, rc=%s", r7_3, #r5_0.sequence, r0_3, r3_0))
      coroutine.yield()
      if r7_3 == #r5_0.sequence then
        r3_0 = mc.mcSpindleSetDirection(r0_0, 0)
      end
    else
      break
    end
  end
  if warmUpRunning then
    r4_0.History("Warm-up complete!", true)
    r4_0.Log("Sequence complete, resetting spindle pre-state.")
    mc.mcSpindleSetCommandRPM(r0_0, r5_0.preState.rpm)
    mc.mcSpindleSetOverride(r0_0, r5_0.preState.override)
  end
  warmUpRunning = false
  return 0
end
return SpindleWarmUp
