-- filename: FixtureTable.lua
-- version: lua53
-- line: [0, 0] id: 0
local r0_0 = {}
local r1_0 = {}
local r2_0 = mc.mcGetInstance()
local r3_0 = mc.mcCntlGetMachDir(r2_0)
local r4_0 = r3_0 .. "\\Modules\\AvidCNC\\?.luac"
local r5_0 = r3_0 .. "\\Modules\\?.dll"
local r6_0 = mc.mcCntlGetUnitsDefault(r2_0)
local r7_0 = mc.mcCntlGetUnitsCurrent(r2_0)
local r8_0 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iRotaryActive", 0)
local r9_0 = nil
local r10_0 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iAdvancedLogging", 0)
if r10_0 == 1 then
  r10_0 = true or false
else
  goto label_43	-- block#2 is visited secondly
end
if string.find(package.path, r4_0) == nil then
  package.path = package.path .. ";" .. r4_0 .. ";"
end
if package.loaded.PanelFunctions == nil then
  pf = require("PanelFunctions")
end
local function r11_0()
  -- line: [28, 36] id: 1
  if r6_0 == 200 and r7_0 == 210 then
    r9_0 = 25.4
  elseif r6_0 == 210 and r7_0 == 200 then
    r9_0 = 0.03937007874015748
  else
    r9_0 = 1
  end
end
function r0_0.FixtureOffsets()
  -- line: [38, 258] id: 2
  r1_0.FixtureOffsets = mcLuaPanelParent
  local r1_2 = r1_0.FixtureOffsets:GetParent():GetSize()
  r1_0.FixtureOffsets:SetSize(580, 320)
  r1_0.bSizer62 = wx.wxBoxSizer(wx.wxVERTICAL)
  r1_0.bSizer64 = wx.wxBoxSizer(wx.wxVERTICAL)
  r1_0.bSizer64:SetMinSize(wx.wxSize(580, -1))
  r1_0.m_staticTextFixtureOffsets = wx.wxStaticText(r1_0.FixtureOffsets, wx.wxID_ANY, "Fixture Offsets", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r1_0.m_staticTextFixtureOffsets:Wrap(-1)
  r1_0.m_staticTextFixtureOffsets:SetFont(wx.wxFont(14, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer64:Add(r1_0.m_staticTextFixtureOffsets, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALL, 5)
  r1_0.bSizer62:Add(r1_0.bSizer64, 0, 0, 5)
  r1_0.bSizer35 = wx.wxBoxSizer(wx.wxHORIZONTAL)
  r1_0.bSizer36 = wx.wxBoxSizer(wx.wxVERTICAL)
  r1_0.bSizer36:Add(0, 31, 1, wx.wxEXPAND, 5)
  r1_0.m_buttonApplyG54 = wx.wxButton(r1_0.FixtureOffsets, wx.wxID_ANY, "Apply G54 Offset", wx.wxDefaultPosition, wx.wxSize(130, 25), 0)
  r1_0.m_buttonApplyG54:SetFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer36:Add(r1_0.m_buttonApplyG54, 0, wx.wxALL, 3)
  r1_0.m_buttonApplyG55 = wx.wxButton(r1_0.FixtureOffsets, wx.wxID_ANY, "Apply G55 Offset", wx.wxDefaultPosition, wx.wxSize(130, 25), 0)
  r1_0.m_buttonApplyG55:SetFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer36:Add(r1_0.m_buttonApplyG55, 0, wx.wxALL, 3)
  r1_0.m_buttonApplyG56 = wx.wxButton(r1_0.FixtureOffsets, wx.wxID_ANY, "Apply G56 Offset", wx.wxDefaultPosition, wx.wxSize(130, 25), 0)
  r1_0.m_buttonApplyG56:SetFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer36:Add(r1_0.m_buttonApplyG56, 0, wx.wxALL, 3)
  r1_0.m_buttonApplyG57 = wx.wxButton(r1_0.FixtureOffsets, wx.wxID_ANY, "Apply G57 Offset", wx.wxDefaultPosition, wx.wxSize(130, 25), 0)
  r1_0.m_buttonApplyG57:SetFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer36:Add(r1_0.m_buttonApplyG57, 0, wx.wxALL, 3)
  r1_0.m_buttonApplyG58 = wx.wxButton(r1_0.FixtureOffsets, wx.wxID_ANY, "Apply G58 Offset", wx.wxDefaultPosition, wx.wxSize(130, 25), 0)
  r1_0.m_buttonApplyG58:SetFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer36:Add(r1_0.m_buttonApplyG58, 0, wx.wxALL, 3)
  r1_0.m_buttonApplyG59 = wx.wxButton(r1_0.FixtureOffsets, wx.wxID_ANY, "Apply G59 Offset", wx.wxDefaultPosition, wx.wxSize(130, 25), 0)
  r1_0.m_buttonApplyG59:SetFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.bSizer36:Add(r1_0.m_buttonApplyG59, 0, wx.wxALL, 3)
  r1_0.bSizer35:Add(r1_0.bSizer36, 0, 0, 5)
  r1_0.m_gridFixtureOffsets = wx.wxGrid(r1_0.FixtureOffsets, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r1_0.m_gridFixtureOffsets:CreateGrid(7, 4)
  r1_0.m_gridFixtureOffsets:EnableEditing(true)
  r1_0.m_gridFixtureOffsets:EnableGridLines(true)
  r1_0.m_gridFixtureOffsets:SetGridLineColour(wx.wxColour(169, 169, 169))
  r1_0.m_gridFixtureOffsets:EnableDragGridSize(true)
  r1_0.m_gridFixtureOffsets:SetMargins(0, 0)
  r1_0.m_gridFixtureOffsets:EnableDragColSize(true)
  r1_0.m_gridFixtureOffsets:SetColLabelSize(30)
  r1_0.m_gridFixtureOffsets:SetColLabelValue(0, "X")
  r1_0.m_gridFixtureOffsets:SetColLabelValue(1, "Y")
  r1_0.m_gridFixtureOffsets:SetColLabelValue(2, "Z")
  r1_0.m_gridFixtureOffsets:SetColLabelValue(3, "A")
  r1_0.m_gridFixtureOffsets:SetColLabelAlignment(wx.wxALIGN_CENTER, wx.wxALIGN_CENTER)
  r1_0.m_gridFixtureOffsets:SetRowSize(0, 30)
  r1_0.m_gridFixtureOffsets:SetRowSize(1, 30)
  r1_0.m_gridFixtureOffsets:SetRowSize(2, 30)
  r1_0.m_gridFixtureOffsets:SetRowSize(3, 30)
  r1_0.m_gridFixtureOffsets:SetRowSize(4, 30)
  r1_0.m_gridFixtureOffsets:SetRowSize(5, 30)
  r1_0.m_gridFixtureOffsets:SetRowSize(6, 30)
  r1_0.m_gridFixtureOffsets:EnableDragRowSize(true)
  r1_0.m_gridFixtureOffsets:SetRowLabelSize(80)
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(0, "G54")
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(1, "G55")
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(2, "G56")
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(3, "G57")
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(4, "G58")
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(5, "G59")
  r1_0.m_gridFixtureOffsets:SetRowLabelValue(6, "G92")
  r1_0.m_gridFixtureOffsets:SetRowLabelAlignment(wx.wxALIGN_CENTER, wx.wxALIGN_CENTER)
  r1_0.m_gridFixtureOffsets:SetDefaultCellBackgroundColour(wx.wxColour(255, 255, 255))
  r1_0.m_gridFixtureOffsets:SetDefaultCellFont(wx.wxFont(wx.wxNORMAL_FONT:GetPointSize(), wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, False, ""))
  r1_0.m_gridFixtureOffsets:SetDefaultCellAlignment(wx.wxALIGN_CENTER, wx.wxALIGN_CENTER)
  r1_0.bSizer35:Add(r1_0.m_gridFixtureOffsets, 0, wx.wxALL, 5)
  r1_0.bSizer62:Add(r1_0.bSizer35, 1, wx.wxEXPAND, 5)
  r1_0.FixtureOffsets:SetSizer(r1_0.bSizer62)
  r1_0.FixtureOffsets:Layout()
  r1_0.bSizer62:Fit(r1_0.FixtureOffsets)
  r1_0.FixtureOffsets:GetParent():Connect(wx.wxID_ANY, wx.wxEVT_SIZE, function(r0_3)
    -- line: [155, 164] id: 3
    local r1_3 = r0_3:GetSize()
    r1_0.FixtureOffsets:SetSize(580, 320)
    r1_0.FixtureOffsets:FitInside()
    r11_0()
    PopulateFixOffsetTable()
    r0_3:Skip()
  end)
  r1_0.FixtureOffsets:Connect(wx.wxEVT_INIT_DIALOG, function(r0_4)
    -- line: [169, 172] id: 4
    r0_4:Skip()
  end)
  r1_0.FixtureOffsets:Connect(wx.wxEVT_UPDATE_UI, function(r0_5)
    -- line: [175, 179] id: 5
    FixtureOffsetsOnUpdateUI()
    r0_5:Skip()
  end)
  r1_0.m_buttonApplyG54:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_6)
    -- line: [182, 186] id: 6
    ApplyFixOffset(54, false)
    r0_6:Skip()
  end)
  r1_0.m_buttonApplyG55:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_7)
    -- line: [189, 193] id: 7
    ApplyFixOffset(55, false)
    r0_7:Skip()
  end)
  r1_0.m_buttonApplyG56:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_8)
    -- line: [196, 200] id: 8
    ApplyFixOffset(56, false)
    r0_8:Skip()
  end)
  r1_0.m_buttonApplyG57:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_9)
    -- line: [203, 207] id: 9
    ApplyFixOffset(57, false)
    r0_9:Skip()
  end)
  r1_0.m_buttonApplyG58:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_10)
    -- line: [210, 214] id: 10
    ApplyFixOffset(58, false)
    r0_10:Skip()
  end)
  r1_0.m_buttonApplyG59:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_11)
    -- line: [217, 221] id: 11
    ApplyFixOffset(59, false)
    r0_11:Skip()
  end)
  r1_0.m_gridFixtureOffsets:Connect(wx.wxEVT_GRID_CELL_CHANGED, function(r0_12)
    -- line: [224, 246] id: 12
    row = r0_12:GetRow()
    col = r0_12:GetCol()
    r0_12:Skip()
    if row <= 5 then
      local r2_12 = GetFixOffsetPoundVars(54 + row)
      local r3_12 = r1_0.m_gridFixtureOffsets:GetCellValue(row, col)
      mc.mcCntlSetPoundVar(r2_0, r2_12[col + 1], tonumber(r3_12) / r9_0)
      r1_0.m_gridFixtureOffsets:SetCellValue(row, col, string.format("%.4f", r3_12))
    end
    if row == 6 then
      local r1_12 = r1_0.m_gridFixtureOffsets:GetCellValue(row, col)
      mc.mcCntlSetPoundVar(r2_0, 5030 + col, tonumber(r1_12) / r9_0)
      r1_0.m_gridFixtureOffsets:SetCellValue(row, col, string.format("%.4f", r1_12))
    end
  end)
  r1_0.m_gridFixtureOffsets:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK, function(r0_13)
    -- line: [249, 252] id: 13
    r0_13:Skip()
  end)
  r1_0.FixtureOffsets:Show(true)
  return r1_0.FixtureOffsets
end
r2_0 = mc.mcGetInstance("FixtureOffsetsTable")
GetFixOffsetPoundVars = function(r0_14)
  -- line: [263, 276] id: 14
  local r1_14 = nil
  local r2_14 = nil
  local r3_14 = nil
  local r4_14 = {}
  r2_14, r3_14 = math.modf(r0_14)
  PoundVarX = mc.SV_FIXTURES_START - mc.SV_FIXTURES_INC + (r2_14 - 53) * mc.SV_FIXTURES_INC
  CurrentFixture = string.format("G" .. tostring(r0_14))
  for r8_14 = 0, 3, 1 do
    table.insert(r4_14, PoundVarX + r8_14)
  end
  return r4_14
end
PopulateFixOffsetTable = function(r0_15)
  -- line: [279, 326] id: 15
  local r1_15 = mc.mcGetInstance("PopulateFixOffsetTable()")
  local r2_15 = r1_0.m_gridFixtureOffsets:GetNumberCols()
  for r7_15 = 0, r1_0.m_gridFixtureOffsets:GetNumberRows() - 1 - 1, 1 do
    local r9_15 = GetFixOffsetPoundVars(54 + r7_15)
    for r13_15 = 0, r2_15 - 1, 1 do
      local r14_15 = mc.mcCntlGetPoundVar(r1_15, r9_15[(r13_15 + 1)]) * r9_0
      if r0_15 == true then
        if string.format("%.4f", tonumber(r1_0.m_gridFixtureOffsets:GetCellValue(r7_15, r13_15))) ~= string.format("%.4f", r14_15) then
          r1_0.m_gridFixtureOffsets:SetCellValue(r7_15, r13_15, string.format("%.4f", r14_15))
        end
      else
        r1_0.m_gridFixtureOffsets:SetCellValue(r7_15, r13_15, string.format("%.4f", r14_15))
      end
    end
  end
  for r7_15 = 0, r2_15 - 1, 1 do
    local r8_15 = mc.mcCntlGetPoundVar(r1_15, (5030 + r7_15)) * r9_0
    if r0_15 == true then
      local r9_15 = string.format("%.4f", tonumber(r1_0.m_gridFixtureOffsets:GetCellValue(6, r7_15)))
      local r10_15 = string.format("%.4f", r8_15)
      if r9_15 ~= r10_15 then
        r1_0.m_gridFixtureOffsets:SetCellValue(6, r7_15, r10_15)
      end
    else
      r1_0.m_gridFixtureOffsets:SetCellValue(6, r7_15, string.format("%.4f", r8_15))
    end
  end
end
ApplyFixOffset = function(r0_16, r1_16)
  -- line: [329, 386] id: 16
  local r2_16 = mc.mcGetInstance("ApplyFixOffset")
  local r3_16 = r0_16
  local r4_16 = r1_16
  local r5_16 = CurrentFixture
  local r6_16 = {
    {
      r1_0.m_buttonApplyG54,
      "G54"
    },
    {
      r1_0.m_buttonApplyG55,
      "G55"
    },
    {
      r1_0.m_buttonApplyG56,
      "G56"
    },
    {
      r1_0.m_buttonApplyG57,
      "G57"
    },
    {
      r1_0.m_buttonApplyG58,
      "G58"
    },
    {
      r1_0.m_buttonApplyG59,
      "G59"
    }
  }
  local r7_16, r8_16 = mc.mcSignalGetHandle(r2_16, mc.OSIG_MACHINE_ENABLED)
  if r8_16 ~= mc.MERROR_NOERROR then
    mc.mcCntlLog(r2_16, "Failure to acquire signal handle", "", -1)
  else
    local r9_16 = mc.mcSignalGetState(r7_16)
    if r9_16 == 0 and not r4_16 then
      wx.wxMessageBox("Enable Machine Before Applying Offsets")
    else
      if r4_16 then
        r3_16 = mc.mcCntlGetPoundVar(r2_16, mc.SV_MOD_GROUP_14)
      end
      if math.floor(r3_16) ~= r3_16 then
        r5_16 = "G" .. r3_16
      else
        r3_16 = math.floor(r3_16)
        r5_16 = "G" .. r3_16
      end
      for r13_16 = 1, #r6_16, 1 do
        if r5_16 ~= r6_16[r13_16][2] then
          r6_16[r13_16][1]:SetLabel("Apply " .. r6_16[r13_16][2] .. " Offset")
          r6_16[r13_16][1]:SetBackgroundColour(wx.wxColour(220, 220, 220))
        else
          r6_16[r13_16][1]:SetLabel("Current Offset: G" .. r3_16)
          r6_16[r13_16][1]:SetBackgroundColour(wx.wxColour(0, 255, 0))
        end
      end
      if r9_16 == 1 and not r4_16 then
        mc.mcCntlMdiExecute(r2_16, r5_16)
        mc.mcCntlSetLastError(r2_16, string.format("Current Fixture Offset Set to: " .. r5_16))
      end
    end
  end
end
FixtureOffsetsOnUpdateUI = function()
  -- line: [388, 459] id: 17
  local r0_17 = mc.mcCntlGetUnitsCurrent(r2_0)
  local r1_17 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iUpdateOffsetsCounter", 0)
  local r2_17 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iRotaryActive", 0)
  local r3_17 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iConfigRotary", 0)
  local r4_17 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iConfigCust4thAxisType", 0)
  local r5_17 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iConfigSettingsSavedFixtureTable", 0)
  local function r6_17()
    -- line: [396, 410] id: 18
    if r2_17 == 1 then
      if r3_17 == 1 then
        r1_0.m_gridFixtureOffsets:SetColLabelValue(3, "A")
      elseif r3_17 == 2 and r4_17 == 1 then
        r1_0.m_gridFixtureOffsets:SetColLabelValue(3, "A")
      else
        r1_0.m_gridFixtureOffsets:SetColLabelValue(3, "U")
      end
    else
      r1_0.m_gridFixtureOffsets:SetColLabelValue(3, "U")
    end
  end
  if r0_17 ~= r7_0 then
    r7_0 = r0_17
    r11_0()
  end
  PopulateFixOffsetTable(true)
  if r1_17 == 1 then
    newCounterVal = r1_17 + 1
    mc.mcProfileWriteInt(r2_0, "AvidCNC_Profile", "iUpdateOffsetsCounter", newCounterVal)
    local r8_17, r9_17 = math.modf(mc.mcCntlGetPoundVar(r2_0, mc.SV_MOD_GROUP_14))
    ApplyFixOffset(r8_17, true)
    r6_17()
  end
  if r5_17 == 1 then
    local r7_17 = mc.mcProfileGetInt(r2_0, "AvidCNC_Profile", "iAdvancedLogging", 0)
    if r7_17 == 1 then
      r7_17 = true or false
    else
      goto label_90	-- block#7 is visited secondly
    end
    r10_0 = r7_17
    pf.WriteIniParams(r2_0, "int", "AvidCNC_Profile", "iConfigSettingsSavedFixtureTable", 0, r10_0)
    r6_17()
  end
  if r8_0 ~= r2_17 then
    r8_0 = r2_17
    r6_17()
  end
end
return r0_0
