-- filename: 
-- version: lua53
-- line: [0, 0] id: 0
local r0_0 = mc.mcGetInstance("AvidDialogs")
local r1_0 = {}
local r3_0 = mc.mcCntlGetMachDir(r0_0) .. "\\Modules\\AvidCNC\\?.luac;"
if not string.find(package.path, r3_0) then
  package.path = package.path .. ";" .. r3_0 .. ";"
end
if package.loaded.PanelFunctions == nil then
  pf = require("PanelFunctions")
end
local r4_0 = wx.wxFont(-1, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD)
function r1_0.MultipleToolWarning(r0_1, r1_1)
  -- line: [33, 269] id: 1
  local r2_1 = {}
  local r3_1 = mc.mcProfileGetInt(r0_0, "AvidCNC_Profile", "iShowWarningMultipleTools", 1)
  if r3_1 == 0 then
    r3_1 = true or false
  else
    goto label_13	-- block#2 is visited secondly
  end
  local function r4_1(r0_2, r1_2)
    -- line: [37, 44] id: 2
    local r2_2, r3_2 = mc.mcRegGetHandle(r0_0, r0_2)
    if r3_2 ~= mc.MERROR_NOERROR then
      mc.mcCntlLog(r0_0, "Avid: Failure to acquire register handle, rc=" .. r3_2, "", -1)
    else
      mc.mcRegSetValueString(r2_2, tostring(r1_2))
    end
  end
  local r5_1 = {
    [1] = {
      label = "Continue ignoring tool changes.",
      action = function()
        -- line: [50, 50] id: 3
      end,
      tooltip = "Continue ignoring tool changes even though multiple tools have been detected.",
    },
    [2] = {
      label = "Stop ignoring tool changes for all programs",
      action = function()
        -- line: [55, 58] id: 4
        pf.WriteIniParams(r0_0, "int", "AvidCNC_Profile", "iConfigIgnoreToolChanges", 0, true)
        r4_1("iRegs0/AvidCNC/ToolChange/Ignore_Tool_Changes", 0)
      end,
      tooltip = "Tool changes will be respected for this and all future G-Code programs.",
    },
    [3] = {
      label = "Stop ignoring tool changes for this G-Code program during the current session.",
      action = function()
        -- line: [63, 73] id: 5
        r4_1("iRegs0/AvidCNC/ToolChange/Ignore_Tool_Changes", 0)
        local r0_5, r1_5 = mc.mcRegGetHandle(r0_0, "iRegs0/AvidCNC/ToolChange/Respect_File_Name")
        if r1_5 ~= mc.MERROR_NOERROR then
          mc.mcCntlLog(r0_0, "Avid: Failure to acquire register handle, rc=" .. r1_5, "", -1)
        else
          mc.mcRegSetValueString(r0_5, r0_1)
        end
      end,
      tooltip = "During the current session of Mach4, tool changes will be respected for this G-Code program. This is based on the name of the file.",
    },
  }
  if r3_1 then
    return 0
  end
  r2_1.dialog = wx.wxDialog(wx.NULL, wx.wxID_ANY, "Ignore Tool Change Warning", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxCAPTION + wx.wxSYSTEM_MENU)
  r2_1.dialog:SetSizeHints(wx.wxDefaultSize, wx.wxDefaultSize)
  r2_1.m_panelMain = wx.wxPanel(r2_1.dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
  r2_1.m_panelTools = wx.wxPanel(r2_1.dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL + wx.wxBORDER_SUNKEN)
  r2_1.m_panelTools:SetBackgroundColour(wx.wxColour(255, 255, 255))
  r2_1.bSizerMain = wx.wxBoxSizer(wx.wxVERTICAL)
  r2_1.bSizerContent = wx.wxBoxSizer(wx.wxVERTICAL)
  r2_1.bSizerTools = wx.wxBoxSizer(wx.wxVERTICAL)
  r2_1.bSizerToolsList = wx.wxBoxSizer(wx.wxVERTICAL)
  r2_1.bSizerFooter = wx.wxBoxSizer(wx.wxHORIZONTAL)
  for r9_1 = 1, 2, 1 do
    r2_1["m_staticLine" .. r9_1] = wx.wxStaticLine(r2_1.m_panelMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL)
  end
  r2_1.m_staticTextHeader = wx.wxStaticText(r2_1.m_panelMain, wx.wxID_ANY, "Multiple tool changes have been detected the current G-Code program, but Mach4 is currently configured to ignore all tool changes. Please select one of the options below.", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER_HORIZONTAL)
  r2_1.m_staticTextHeader:Wrap(500)
  r2_1.m_staticTextToolChanges = wx.wxStaticText(r2_1.m_panelMain, wx.wxID_ANY, "Detected tool changes: ", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r2_1.bSizerToolsList:Add(0, 3, 0, 0, 0)
  for r9_1, r10_1 in pairs(r1_1) do
    r2_1["m_staticTextTC" .. r10_1] = wx.wxStaticText(r2_1.m_panelTools, wx.wxID_ANY, "Tool #" .. r9_1 .. " on line #" .. r10_1, wx.wxDefaultPosition, wx.wxDefaultSize, 0)
    r2_1.bSizerToolsList:Add(r2_1["m_staticTextTC" .. r10_1], 0, wx.wxLEFT + wx.wxRIGHT, 7)
  end
  r2_1.bSizerToolsList:Add(0, 3, 0, 0, 0)
  for r9_1 = 1, #r5_1, 1 do
    local r10_1 = "m_radioBtn" .. r9_1
    local r11_1 = wx.wxRadioButton
    local r12_1 = r2_1.m_panelMain
    local r13_1 = r9_1
    local r14_1 = r5_1[r9_1].label
    local r15_1 = wx.wxDefaultPosition
    local r16_1 = wx.wxDefaultSize
    local r17_1 = nil	-- notice: implicit variable refs by block#[15]
    if r9_1 == 1 then
      r17_1 = wx.wxRB_GROUP
      if not r17_1 then
        ::label_262::
        r17_1 = 0
      end
    else
      goto label_262	-- block#14 is visited secondly
    end
    r2_1[r10_1] = r11_1(r12_1, r13_1, r14_1, r15_1, r16_1, r17_1)
    r2_1["m_radioBtn" .. r9_1]:SetToolTip(r5_1[r9_1].tooltip)
  end
  r2_1.m_radioBtn1:SetValue(true)
  r2_1.m_checkBoxWarnIgnore = wx.wxCheckBox(r2_1.m_panelMain, wx.wxID_ANY, "Don\'t show this message again", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r2_1.m_buttonOK = wx.wxButton(r2_1.m_panelMain, wx.wxID_ANY, "Ok", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r2_1.bSizerContent:Add(r2_1.m_staticTextHeader, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  r2_1.bSizerContent:Add(r2_1.m_staticLine1, 0, wx.wxEXPAND + wx.wxALL, 5)
  r2_1.bSizerTools:Add(r2_1.m_staticTextToolChanges, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  r2_1.m_panelTools:SetSizer(r2_1.bSizerToolsList)
  r2_1.m_panelTools:Layout()
  r2_1.bSizerToolsList:Fit(r2_1.m_panelTools)
  r2_1.bSizerTools:Add(r2_1.m_panelTools, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALL, 5)
  r2_1.bSizerContent:Add(r2_1.bSizerTools, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  for r9_1 = 1, #r5_1, 1 do
    r2_1.bSizerContent:Add(r2_1["m_radioBtn" .. r9_1], 0, wx.wxALL, 5)
  end
  r2_1.bSizerContent:Add(r2_1.m_staticLine2, 0, wx.wxEXPAND + wx.wxALL, 5)
  r2_1.bSizerFooter:Add(r2_1.m_checkBoxWarnIgnore, 1, wx.wxALL + wx.wxALIGN_LEFT, 5)
  r2_1.bSizerFooter:Add(r2_1.m_buttonOK, 0, wx.wxALL + wx.wxALIGN_RIGHT, 5)
  r2_1.bSizerContent:Add(r2_1.bSizerFooter, 0, wx.wxALL + wx.wxEXPAND, 5)
  r2_1.m_panelMain:SetSizer(r2_1.bSizerContent)
  r2_1.m_panelMain:Layout()
  r2_1.bSizerContent:Fit(r2_1.m_panelMain)
  r2_1.bSizerMain:Add(r2_1.m_panelMain, 1, wx.wxEXPAND + wx.wxALL, 5)
  r2_1.dialog:SetSizer(r2_1.bSizerMain)
  r2_1.dialog:Layout()
  r2_1.bSizerMain:Fit(r2_1.dialog)
  r2_1.dialog:Centre(wx.wxBOTH)
  r2_1.dialog:Connect(wx.wxEVT_INIT_DIALOG, function(r0_6)
    -- line: [230, 233] id: 6
    r0_6:Skip()
  end)
  r2_1.dialog:Connect(wx.wxEVT_CLOSE_WINDOW, function(r0_7)
    -- line: [236, 239] id: 7
    r0_7:Skip()
  end)
  r2_1.m_buttonOK:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function(r0_8)
    -- line: [242, 263] id: 8
    for r4_8 = 1, #r5_1, 1 do
      if r2_1.dialog:FindWindow(r4_8):DynamicCast("wxRadioButton"):GetValue() then
        r5_1[r4_8].action()
        break
      end
    end
    local r1_8 = pf.WriteIniParams
    local r2_8 = r0_0
    local r3_8 = "int"
    local r4_8 = "AvidCNC_Profile"
    local r5_8 = "iShowWarningMultipleTools"
    local r6_8 = r2_1.m_checkBoxWarnIgnore:GetValue()
    if r6_8 then
      r6_8 = 0 or 1
    else
      goto label_35	-- block#6 is visited secondly
    end
    r1_8(r2_8, r3_8, r4_8, r5_8, r6_8, true)
    r2_1.dialog:Destroy()
    wx.wxGetApp():GetTopWindow():Refresh()
  end)
  r2_1.dialog:Show()
end
function r1_0.WarningDialog(r0_9, r1_9, r2_9, r3_9)
  -- line: [274, 406] id: 9
  local r4_9 = {}
  local r5_9 = nil	-- notice: implicit variable refs by block#[6, 13]
  if r2_9 then
    r5_9 = true
    if not r5_9 then
      ::label_6::
      r5_9 = false
    end
  else
    goto label_6	-- block#2 is visited secondly
  end
  local r6_9 = nil	-- notice: implicit variable refs by block#[16, 20]
  if not r3_9 then
    r6_9 = true
    if not r6_9 then
      ::label_12::
      r6_9 = false
    end
  else
    goto label_12	-- block#5 is visited secondly
  end
  if r5_9 then
    local r7_9 = false
    if r2_9 ~= nil then
      if mc.mcProfileGetInt(r0_0, "AvidCNC_Profile", r2_9, 1) == 0 then
        r7_9 = true or false
      else
        goto label_30	-- block#10 is visited secondly
      end
    end
    if r7_9 then
      return 0
    end
  end
  r4_9.dialog = wx.wxDialog(wx.NULL, wx.wxID_ANY, r0_9, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDEFAULT_DIALOG_STYLE)
  r4_9.dialog:SetSizeHints(wx.wxDefaultSize, wx.wxDefaultSize)
  r4_9.m_panelMain = wx.wxPanel(r4_9.dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
  r4_9.bSizerMain = wx.wxBoxSizer(wx.wxVERTICAL)
  r4_9.bSizerContent = wx.wxBoxSizer(wx.wxVERTICAL)
  r4_9.bSizerButtons = wx.wxBoxSizer(wx.wxHORIZONTAL)
  r4_9.m_staticLine1 = wx.wxStaticLine(r4_9.m_panelMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL)
  r4_9.m_staticTextMessage = wx.wxStaticText(r4_9.m_panelMain, wx.wxID_ANY, r1_9, wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r4_9.m_staticTextMessage:Wrap(300)
  if r5_9 and r2_9 ~= nil then
    r4_9.m_checkBoxDontShow = wx.wxCheckBox(r4_9.m_panelMain, wx.wxID_ANY, "Don\'t show this message again", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  end
  r4_9.m_buttonOK = wx.wxButton(r4_9.m_panelMain, wx.wxID_OK, "Ok", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  if r6_9 then
    r4_9.m_buttonCancel = wx.wxButton(r4_9.m_panelMain, wx.wxID_CANCEL, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  end
  r4_9.bSizerContent:Add(r4_9.m_staticTextMessage, 0, wx.wxALL, 5)
  r4_9.bSizerContent:Add(0, 20, 0, 0, 0)
  if r4_9.m_checkBoxDontShow then
    r4_9.bSizerContent:Add(r4_9.m_checkBoxDontShow, 0, wx.wxALL, 5)
  end
  r4_9.bSizerContent:Add(r4_9.m_staticLine1, 0, wx.wxALL + wx.wxEXPAND, 5)
  r4_9.bSizerButtons:Add(r4_9.m_buttonOK, 0, wx.wxALL, 5)
  if r6_9 then
    r4_9.bSizerButtons:Add(r4_9.m_buttonCancel, 0, wx.wxALL, 5)
  end
  r4_9.bSizerContent:Add(r4_9.bSizerButtons, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  r4_9.m_panelMain:SetSizer(r4_9.bSizerContent)
  r4_9.m_panelMain:Layout()
  r4_9.bSizerContent:Fit(r4_9.m_panelMain)
  r4_9.bSizerMain:Add(r4_9.m_panelMain, 1, wx.wxEXPAND + wx.wxALL, 5)
  r4_9.dialog:SetSizer(r4_9.bSizerMain)
  r4_9.dialog:Layout()
  r4_9.bSizerMain:Fit(r4_9.dialog)
  r4_9.dialog:Centre(wx.wxBOTH)
  local r7_9 = r4_9.dialog:ShowModal()
  local r8_9 = r4_9.m_checkBoxDontShow
  if r8_9 then
    r8_9 = r4_9.m_checkBoxDontShow:GetValue() or nil
  else
    goto label_279	-- block#24 is visited secondly
  end
  r4_9.dialog:Destroy()
  wx.wxGetApp():GetTopWindow():Refresh()
  if r7_9 == wx.wxID_OK then
    if r8_9 ~= nil and r2_9 ~= nil then
      local r11_9 = pf.WriteIniParams
      local r12_9 = r0_0
      local r13_9 = "int"
      local r14_9 = "AvidCNC_Profile"
      local r15_9 = r2_9
      local r16_9 = nil	-- notice: implicit variable refs by block#[31]
      if r8_9 then
        r16_9 = 0
        if not r16_9 then
          ::label_309::
          r16_9 = 1
        end
      else
        goto label_309	-- block#30 is visited secondly
      end
      r11_9(r12_9, r13_9, r14_9, r15_9, r16_9, true)
    end
    return 0
  else
    return 1
  end
end
function r1_0.Welcome(r0_10)
  -- line: [412, 672] id: 10
  local r1_10 = r0_10 or "Update"
  local r2_10 = mc.mcGetInstance("AvidDialogs.Welcome")
  local r3_10 = {}
  local r4_10 = mc.mcCntlGetMachDir(r2_10)
  local r5_10 = pf.GetInternetConnectionStatus()
  local r6_10 = pf.ReadJSON("\\Modules\\AvidCNC\\AvidCNC.json")
  local r7_10 = mc.mcProfileGetString(r2_10, "AvidCNC_Profile", "sProfileVersion", "0.0.0")
  local r8_10 = 1
  local r9_10 = 0
  local r10_10 = {}
  local r11_10 = {}
  local r12_10 = wx.wxID_HIGHEST
  r3_10.hypers = {}
  if not r6_10 or not r6_10.Welcome_Dialog then
    return 
  end
  pf.WriteIniParams(r2_10, "int", "AvidCNC_Profile", "iShowWelcomeMessage", 0, true)
  local function r13_10(r0_11, r1_11)
    -- line: [433, 446] id: 11
    return wx.wxStaticText(r3_10.m_panelMain, wx.wxID_ANY, r0_11, wx.wxDefaultPosition, wx.wxDefaultSize, r1_11 or 0)
  end
  local function r14_10(r0_12, r1_12)
    -- line: [448, 467] id: 12
    r12_10 = r12_10 + 1
    local r2_12 = r6_10.Documentation[r1_12]
    local r3_12 = wx.wxHyperlinkCtrl(r3_10.m_panelMain, r12_10, r0_12, r2_12.Website, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHL_DEFAULT_STYLE)
    table.insert(r3_10.hypers, r12_10)
    r3_10.hypers[r12_10] = r2_12
    return r3_12
  end
  r3_10.dialog = wx.wxDialog(wx.NULL, wx.wxID_ANY, "Welcome!", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDEFAULT_DIALOG_STYLE)
  r3_10.dialog:SetSizeHints(wx.wxDefaultSize, wx.wxDefaultSize)
  r3_10.m_panelMain = wx.wxPanel(r3_10.dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
  r3_10.bSizerMain = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.bSizerHeader = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.bSizerContent = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.bSizerWelcome = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.bSizerWhatsNew = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.bSizerDocs = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.bSizerButtons = wx.wxBoxSizer(wx.wxVERTICAL)
  r3_10.m_staticLine1 = wx.wxStaticLine(r3_10.m_panelMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL)
  r3_10.m_staticLine2 = wx.wxStaticLine(r3_10.m_panelMain, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL)
  r3_10.m_bitmapLogo = wx.wxStaticBitmap(r3_10.m_panelMain, wx.wxID_ANY, wx.wxBitmap(r4_10 .. "\\Modules\\AvidCNC\\Images\\AvidLogo2.png", wx.wxBITMAP_TYPE_ANY), wx.wxDefaultPosition, wx.wxSize(-1, -1), wx.wxALIGN_CENTER_HORIZONTAL)
  r3_10.bSizerHeader:Add(r3_10.m_bitmapLogo, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  r3_10.m_staticTextHeader = r13_10(string.format("Mach4 for Avid CNC Machines v%s", r6_10.AvidCNC_Profile_Version))
  r3_10.bSizerHeader:Add(r3_10.m_staticTextHeader, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  r3_10.m_staticTextWelcome = r13_10(r6_10.Welcome_Dialog.Message)
  r3_10.m_staticTextWelcome:Wrap(350)
  r3_10.bSizerWelcome:Add(r3_10.m_staticTextWelcome, 0, wx.wxALL + wx.wxEXPAND, 5)
  r3_10.m_staticTextNew = r13_10("New features and updates:")
  r3_10.bSizerWhatsNew:Add(r3_10.m_staticTextNew, 0, wx.wxALL + wx.wxALIGN_LEFT, 5)
  r3_10.m_staticTextNew:SetFont(r4_0)
  while r6_10.Welcome_Dialog.Whats_New do
    local r15_10 = r6_10.Welcome_Dialog.Whats_New[r8_10]
    if r15_10 then
      r15_10 = 1
      if r8_10 == 1 then
        r10_10[1], r10_10[2], r10_10[3] = r7_10:match("(%d+).(%d+).(%d+)")
      end
      for r19_10, r20_10 in pairs(r6_10.Welcome_Dialog.Whats_New[r8_10]) do
        r11_10[1], r11_10[2], r11_10[3] = r19_10:match("(%d+).(%d+).(%d+)")
        for r24_10 = 1, 3, 1 do
          if tonumber(r10_10[r24_10]) < tonumber(r11_10[r24_10]) then
            while r20_10[r15_10] do
              e = r13_10("- " .. r20_10[r15_10])
              e:Wrap(400)
              r3_10.bSizerWhatsNew:Add(e, 0, wx.wxLEFT + wx.wxALIGN_LEFT, 15)
              r15_10 = r15_10 + 1
              r9_10 = r9_10 + 1
            end
          elseif tonumber(r11_10[r24_10]) < tonumber(r10_10[r24_10]) then
            break
          end
        end
      end
      r8_10 = r8_10 + 1
    else
      break
    end
  end
  if r0_10 == "Update" and r9_10 == 0 then
    return 1
  end
  r3_10.bSizerDocs:Add(0, 20, 0, 0)
  r3_10.m_staticTextDocs = r13_10("Documentation:")
  r3_10.bSizerDocs:Add(r3_10.m_staticTextDocs, 0, wx.wxALL + wx.wxALIGN_LEFT, 5)
  r3_10.m_staticTextDocs:SetFont(r4_0)
  r3_10.m_hyperlinkReleaseNotes = r14_10("Release Notes", "Change_Log")
  r3_10.m_hyperlinkUsersGuide = r14_10("Mach4 for Avid CNC Machines User\'s Guide", "Users_Guide")
  r3_10.bSizerDocs:Add(r3_10.m_hyperlinkReleaseNotes, 0, wx.wxLEFT + wx.wxALIGN_LEFT, 15)
  r3_10.bSizerDocs:Add(0, 3, 0, 0)
  r3_10.bSizerDocs:Add(r3_10.m_hyperlinkUsersGuide, 0, wx.wxLEFT + wx.wxALIGN_LEFT, 15)
  r3_10.m_buttonOK = wx.wxButton(r3_10.m_panelMain, wx.wxID_OK, "Ok", wx.wxDefaultPosition, wx.wxDefaultSize, 0)
  r3_10.bSizerButtons:Add(r3_10.m_buttonOK, 0, wx.wxALL + wx.wxALIGN_CENTER_HORIZONTAL, 5)
  r3_10.bSizerContent:Add(r3_10.bSizerHeader, 0, wx.wxALL + wx.wxEXPAND, 5)
  r3_10.bSizerContent:Add(r3_10.m_staticLine1, 0, wx.wxALL + wx.wxEXPAND, 5)
  r3_10.bSizerContent:Add(r3_10.bSizerWelcome, 0, wx.wxALL + wx.wxEXPAND, 0)
  r3_10.bSizerContent:Add(r3_10.bSizerWhatsNew, 0, wx.wxRIGHT, 10)
  r3_10.bSizerContent:Add(r3_10.bSizerDocs, 0, wx.wxRIGHT, 10)
  r3_10.bSizerContent:Add(r3_10.m_staticLine2, 0, wx.wxALL + wx.wxEXPAND, 5)
  r3_10.bSizerContent:Add(r3_10.bSizerButtons, 0, wx.wxALL + wx.wxEXPAND, 5)
  if r1_10 == "New" then
    r3_10.bSizerContent:Show(r3_10.bSizerWhatsNew, false, false)
  elseif r1_10 == "Update" then
    r3_10.bSizerContent:Show(r3_10.bSizerWelcome, false, false)
  end
  r3_10.m_panelMain:SetSizer(r3_10.bSizerContent)
  r3_10.m_panelMain:Layout()
  r3_10.bSizerContent:Fit(r3_10.m_panelMain)
  r3_10.bSizerMain:Add(r3_10.m_panelMain, 1, wx.wxEXPAND + wx.wxALL, 5)
  r3_10.dialog:SetSizer(r3_10.bSizerMain)
  r3_10.dialog:Layout()
  r3_10.bSizerMain:Fit(r3_10.dialog)
  r3_10.dialog:Centre(wx.wxBOTH)
  r3_10.dialog:Connect(wx.wxEVT_INIT_DIALOG, function(r0_13)
    -- line: [640, 644] id: 13
    r3_10.m_panelMain:SetFocusIgnoringChildren()
    r0_13:Skip()
  end)
  r3_10.dialog:Connect(wx.wxEVT_CLOSE_WINDOW, function(r0_14)
    -- line: [647, 650] id: 14
    r0_14:Skip()
  end)
  r3_10.dialog:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_HYPERLINK, function(r0_15)
    -- line: [653, 663] id: 15
    local r1_15 = r0_15:GetId()
    if r5_10 then
      r0_15:Skip()
    else
      wx.wxLaunchDefaultBrowser(string.format("%s\\%s", r4_10, r3_10.hypers[r1_15].PDF))
    end
  end)
  if r3_10.dialog:ShowModal(true) then
    return 0
  end
  return 0
end
return r1_0
