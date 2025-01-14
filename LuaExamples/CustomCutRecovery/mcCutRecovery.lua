----------------------------------------------------------------------------
-- If this file exists in the base Modules directory or a profile's Modules 
-- directory, this will run instead of the stock cut recovery process.  
----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

ID_CUTRECOVERY = 1000
ID_BUTTON_FIRST_MOVE = 1001
ID_BUTTON_SEC_MOVE = 1002

local UI = {}

UI.m_inst = 0
UI.m_precision = .0001
UI.m_index = -1

UI.m_machpos = {}
UI.m_machpos[1] = 0
UI.m_machpos[2] = 0
UI.m_machpos[3] = 0
UI.m_machpos[4] = 0
UI.m_machpos[5] = 0
UI.m_machpos[6] = 0

UI.m_axisEnabled = {}
UI.m_axisEnabled[1] = 0
UI.m_axisEnabled[2] = 0
UI.m_axisEnabled[3] = 0
UI.m_axisEnabled[4] = 0
UI.m_axisEnabled[5] = 0
UI.m_axisEnabled[6] = 0

UI.m_pos = {}
UI.m_pos[1] = 0
UI.m_pos[2] = 0
UI.m_pos[3] = 0
UI.m_pos[4] = 0
UI.m_pos[5] = 0
UI.m_pos[6] = 0

UI.m_FirstMoveAxis = {}

-- create CutRecovery
UI.CutRecovery = wx.wxDialog (wx.NULL, ID_CUTRECOVERY, "Cut Recovery", wx.wxDefaultPosition, wx.wxSize( -1,-1 ), wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxRESIZE_BORDER + wx.wxSYSTEM_MENU+wx.wxTAB_TRAVERSAL )
	UI.CutRecovery:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	UI.CutRecovery:SetExtraStyle( UI.CutRecovery :GetExtraStyle() + wx.wxWS_EX_BLOCK_EVENTS + wx.wxWS_EX_VALIDATE_RECURSIVELY )
	
	UI.bSizer1 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.sbSizer1 = wx.wxStaticBoxSizer( wx.wxStaticBox( UI.CutRecovery, wx.wxID_ANY, "Distance To Go" ), wx.wxHORIZONTAL )
	
	UI.gSizer1 = wx.wxGridSizer( 2, 6, 0, 0 )
	
	UI.m_staticText1 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "X:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText1:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_staticText1, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_DistToGo1 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "000.0000", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_DistToGo1:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_DistToGo1, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_staticText3 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "Y:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText3:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_staticText3, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_DistToGo2 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "000.0000", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_DistToGo2:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_DistToGo2, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_staticText5 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "Z:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText5:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_staticText5, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_DistToGo3 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "000.0000", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_DistToGo3:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_DistToGo3, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_staticText7 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "A:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText7:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_staticText7, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_DistToGo4 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "000.0000", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_DistToGo4:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_DistToGo4, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_staticText9 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "B:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText9:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_staticText9, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_DistToGo5 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "000.0000", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_DistToGo5:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_DistToGo5, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_staticText11 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "C:", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText11:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_staticText11, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_DistToGo6 = wx.wxStaticText( UI.sbSizer1:GetStaticBox(), wx.wxID_ANY, "000.0000", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_DistToGo6:Wrap( -1 )
	
	UI.gSizer1:Add( UI.m_DistToGo6, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	
	UI.sbSizer1:Add( UI.gSizer1, 1, wx.wxEXPAND, 5 )
	
	
	UI.bSizer1:Add( UI.sbSizer1, 1, wx.wxEXPAND, 5 )
	
	UI.m_staticText19 = wx.wxStaticText( UI.CutRecovery, wx.wxID_ANY, "The closest point on the path to the current position has been determined.  Use the \"Move\" buttons to orient to this position.  If the position is acceptable, press OK.  Otherwise, press cancel and jog the machine to the desired restart point and try again.", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText19:Wrap( 280 )
	
	UI.bSizer1:Add( UI.m_staticText19, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.sbSizer2 = wx.wxStaticBoxSizer( wx.wxStaticBox( UI.CutRecovery, wx.wxID_ANY, "Move Axis to Start Position" ), wx.wxHORIZONTAL )
	
	UI.fgSizer1 = wx.wxFlexGridSizer( 2, 3, 0, 0 )
	UI.fgSizer1:SetFlexibleDirection( wx.wxBOTH )
	UI.fgSizer1:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	
	UI.m_FirstMoveAxis1 = wx.wxCheckBox( UI.sbSizer2:GetStaticBox(), wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.fgSizer1:Add( UI.m_FirstMoveAxis1, 0, wx.wxALL, 5 )
	
	UI.m_FirstMoveAxis2 = wx.wxCheckBox( UI.sbSizer2:GetStaticBox(), wx.wxID_ANY, "Y", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.fgSizer1:Add( UI.m_FirstMoveAxis2, 0, wx.wxALL, 5 )
	
	UI.m_FirstMoveAxis3 = wx.wxCheckBox( UI.sbSizer2:GetStaticBox(), wx.wxID_ANY, "Z", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.fgSizer1:Add( UI.m_FirstMoveAxis3, 0, wx.wxALL, 5 )
	
	UI.m_FirstMoveAxis4 = wx.wxCheckBox( UI.sbSizer2:GetStaticBox(), wx.wxID_ANY, "A", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.fgSizer1:Add( UI.m_FirstMoveAxis4, 0, wx.wxALL, 5 )
	
	UI.m_FirstMoveAxis5 = wx.wxCheckBox( UI.sbSizer2:GetStaticBox(), wx.wxID_ANY, "B", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.fgSizer1:Add( UI.m_FirstMoveAxis5, 0, wx.wxALL, 5 )
	
	UI.m_FirstMoveAxis6 = wx.wxCheckBox( UI.sbSizer2:GetStaticBox(), wx.wxID_ANY, "C", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_RIGHT )
	UI.fgSizer1:Add( UI.m_FirstMoveAxis6, 0, wx.wxALL, 5 )
	
	
	UI.sbSizer2:Add( UI.fgSizer1, 1, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.bSizer4 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.m_button_first_move = wx.wxButton( UI.sbSizer2:GetStaticBox(), ID_BUTTON_FIRST_MOVE, "Move Selected", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer4:Add( UI.m_button_first_move, 0, wx.wxBOTTOM + wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_button_sec_move = wx.wxButton( UI.sbSizer2:GetStaticBox(), ID_BUTTON_SEC_MOVE, "Move Unselected", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer4:Add( UI.m_button_sec_move, 0, wx.wxBOTTOM + wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	
	UI.sbSizer2:Add( UI.bSizer4, 1, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxEXPAND, 5 )
	
	
	UI.bSizer1:Add( UI.sbSizer2, 1, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxALIGN_TOP + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT, 5 )
	
	
	UI.bSizer1:Add( 0, 0, 0, wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	UI.m_sdbSizer1 = wx.wxStdDialogButtonSizer()
	UI.m_sdbSizer1OK = wx.wxButton( UI.CutRecovery, wx.wxID_OK, "" )
	UI.m_sdbSizer1:AddButton( UI.m_sdbSizer1OK )
	UI.m_sdbSizer1Cancel = wx.wxButton( UI.CutRecovery, wx.wxID_CANCEL, "" )
	UI.m_sdbSizer1:AddButton( UI.m_sdbSizer1Cancel )
	UI.m_sdbSizer1:Realize();
	
	UI.bSizer1:Add( UI.m_sdbSizer1, 0, wx.wxALIGN_CENTER_HORIZONTAL + wx.wxALIGN_CENTER_VERTICAL + wx.wxBOTTOM + wx.wxLEFT + wx.wxRIGHT + wx.wxTOP, 5 )
	
	
	UI.CutRecovery:SetSizer( UI.bSizer1 )
	UI.CutRecovery:Layout()
	UI.bSizer1:Fit( UI.CutRecovery )
	
	UI.CutRecovery:Centre( wx.wxBOTH )
	
	UI.m_FirstMoveAxis = {}
	UI.m_FirstMoveAxis[1] = UI.m_FirstMoveAxis1;
	UI.m_FirstMoveAxis[2] = UI.m_FirstMoveAxis2;
	UI.m_FirstMoveAxis[3] = UI.m_FirstMoveAxis3;
	UI.m_FirstMoveAxis[4] = UI.m_FirstMoveAxis4;
	UI.m_FirstMoveAxis[5] = UI.m_FirstMoveAxis5;
	UI.m_FirstMoveAxis[6] = UI.m_FirstMoveAxis6;
	
	UI.m_DistToGo = {}
	
	UI.m_DistToGo[1] = UI.m_DistToGo1
	UI.m_DistToGo[2] = UI.m_DistToGo2
	UI.m_DistToGo[3] = UI.m_DistToGo3
	UI.m_DistToGo[4] = UI.m_DistToGo4
	UI.m_DistToGo[5] = UI.m_DistToGo5
	UI.m_DistToGo[6] = UI.m_DistToGo6
	
	function UI.GetMachinePosition(updateDisplay)
		local str
		for i = 1, mc.MC_MAX_COORD_AXES, 1 do
			UI.m_machpos[i] = mc.mcAxisGetMachinePos(UI.m_inst, i - 1);
			if (updateDisplay == true) then 
				str = string.format("%0.4f", (UI.m_pos[i] - UI.m_machpos[i]))
				--Kill flicker.
				if (UI.m_DistToGo[i]:GetLabel() ~= str) then 
					UI.m_DistToGo[i]:SetLabel(str);
				end
				--UI.m_FirstMoveAxis[i]:Enable(not(math.abs(UI.m_pos[i] - UI.m_machpos[i]) < UI.m_precision))
			end
		end
	end

	function UI.UpdatePosDisplay()
		UI.GetMachinePosition(true) --update display
	end
	
	function UI.AxisInPosition(axis)
		if (UI.m_axisEnabled[axis] == 0) then
			return(true)
		end
		local delta = math.abs(UI.m_pos[axis] - UI.m_machpos[axis])
		if (delta < UI.m_precision) then 
			return(true)
		end
		return(false)
	end

	-- Connect Events
	
	UI.CutRecovery:Connect( wx.wxEVT_CLOSE_WINDOW, function(event)
		--implements --close event code
		UI.CutRecovery:EndModal(wx.wxID_CANCEL)
	end )
	
	UI.CutRecovery:Connect( wx.wxEVT_IDLE, function(event)
		--implements --idle event.
		if (UI.CutRecovery:IsShown() == true) then 
			UI.UpdatePosDisplay()
		end
		event:Skip()
	end )
	
	UI.CutRecovery:Connect( wx.wxEVT_INIT_DIALOG, function(event)
		--implements --Init event code
		local rc = 0
		local units = 0
		UI.m_inst = mc.mcGetInstance('Custom CutRecovery Dialog')
		for axis = 1, mc.MC_MAX_COORD_AXES, 1 do
			UI.m_axisEnabled[axis] = mc.mcAxisIsEnabled(UI.m_inst, axis - 1)
		end
		UI.m_pos[1], UI.m_pos[2], UI.m_pos[3], UI.m_pos[4], UI.m_pos[5], UI.m_pos[6], rc = mc.mcCntlGetCutRecoveryPoint(UI.m_inst, mc.MC_PLANE_XY)
		units, rc = mc.mcCntlGetUnitsDefault(UI.m_inst)
		if ((units / 10) == mc.MC_UNITS_INCH) then 
			UI.m_precision = .001
		else
			UI.m_precision = .005
		end
		UI.GetMachinePosition(false); --Don't update the display.
		event:Skip()
	end )
	
	UI.m_FirstMoveAxis1:Connect( wx.wxEVT_UPDATE_UI, function(event)
		--implements --X on update
		event:Enable(not UI.AxisInPosition(1))
	end )
	
	UI.m_FirstMoveAxis2:Connect( wx.wxEVT_UPDATE_UI, function(event)
		--implements --Y on update
		event:Enable(not UI.AxisInPosition(2))
	end )
	
	UI.m_FirstMoveAxis3:Connect( wx.wxEVT_UPDATE_UI, function(event)
		--implements --Z on update
		event:Enable(not UI.AxisInPosition(3))
	end )
	
	UI.m_FirstMoveAxis4:Connect( wx.wxEVT_UPDATE_UI, function(event)
		--implements --A on update
		event:Enable(not UI.AxisInPosition(4))
	end )
	
	UI.m_FirstMoveAxis5:Connect( wx.wxEVT_UPDATE_UI, function(event)
		--implements --B on update
		event:Enable(not UI.AxisInPosition(5))
	end )
	
	UI.m_FirstMoveAxis6:Connect( wx.wxEVT_UPDATE_UI, function(event)
		--implements --C on update
		event:Enable(not UI.AxisInPosition(6))
	end )
	
	UI.m_button_first_move:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		--implements --event code
		local axis
		local rc
		for axis = 1, mc.MC_MAX_COORD_AXES, 1 do
			if ((UI.m_FirstMoveAxis[axis]:GetValue() == true) and (UI.m_FirstMoveAxis[axis]:IsEnabled() == true)) then 
				local j = 0
				j, rc = mc.mcJogIsJogging(UI.m_inst, axis - 1)
				if (j == 0) then
					mc.mcJogIncStart(UI.m_inst, axis - 1, UI.m_pos[axis] - UI.m_machpos[axis]);
				end
			end
		end
	end )
	
	UI.m_button_first_move:Connect( wx.wxEVT_UPDATE_UI, function(event)
	--implements --OnUpdate
	
	event:Skip()
	end )
	
	UI.m_button_sec_move:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		--implements --event code
		local axis
		local rc
		for axis = 1, mc.MC_MAX_COORD_AXES, 1 do
			if ((UI.m_FirstMoveAxis[axis]:GetValue() == false) and (UI.m_FirstMoveAxis[axis]:IsEnabled() == true)) then
				local j = 0;
				j, rc = mc.mcJogIsJogging(UI.m_inst, axis - 1);
				if (j == 0) then 
					mc.mcJogIncStart(UI.m_inst, axis - 1, UI.m_pos[axis] - UI.m_machpos[axis]);
				end
			end
		end
	end )
	
	UI.m_button_sec_move:Connect( wx.wxEVT_UPDATE_UI, function(event)
	--implements --OnUpdate
	
	event:Skip()
	end )
	
	UI.m_sdbSizer1Cancel:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		--implements --cancel event
		UI.CutRecovery:EndModal(wx.wxID_CANCEL)
	end )
	
	UI.m_sdbSizer1OK:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		--implements --ok event
		--implements --cancel event
		UI.CutRecovery:EndModal(wx.wxID_OK)
	end )
	
	UI.m_sdbSizer1OK:Connect( wx.wxEVT_UPDATE_UI, function(event)
		UI.UpdatePosDisplay();
		local i
		for i = 1, mc.MC_MAX_COORD_AXES, 1 do
			if (UI.m_axisEnabled[i] ~= 0) then 
				local delta = UI.m_machpos[i] - UI.m_pos[i]
				delta = math.abs(delta)
				if (delta > UI.m_precision) then 
					event:Enable(false)
					return
				end
			end
		end
		event:Enable(true)
	end )
	
	-- This is the main entru point in the module.  It can call a dialog, or not.  It just depends on 
	-- how you want to handle cut recovery.  Regardless, this function needs to return either 
	-- wx.wxID_CANCEL to cancel the cut recovery operation of wx.wxID_OK to continue.
	function UI.DoCutRecovery()
		-- This is the minimum required for correct functionailty.  
		UI.m_inst = mc.mcGetInstance('Custom CutRecovery Dialog')
		for axis = 1, mc.MC_MAX_COORD_AXES, 1 do
			UI.m_axisEnabled[axis] = mc.mcAxisIsEnabled(UI.m_inst, axis - 1)
			mc.mcCntlSetLastError(UI.m_inst, "axis" .. tostring(axis - 1) .. " = " .. tostring(UI.m_axisEnabled[axis]))
		end
		return(UI.CutRecovery:ShowModal())
	end

	-- This is a hook that is run after the machine is on the path.  Do a dryrun.
	-- If success, return wx.wxID_OK.
	-- If failure, return wx.wxID_CANCEL.
	-- To run the default dry run code in the core, return wx.wxID_DEFAULT
	-- Additionally, If this function does not exist in this table, then the defualt dry run code will run.
	-- rc is if the return code of DoCutRecovery() above (wx.wxID_OK or wx.wxID_CANCEL)
	function UI.DoDryRun(rc)
		-- Basically call mcCntlCutRecoveryEx() a run a dry run progress dialog.  
		return(wx.wxID_DEFAULT)
	end

	-- This is a hook that is run after the dry run has completed.  Light the tourch, etc.  
	-- If success, return wx.wxID_OK.
	-- If failure, return wx.wxID_CANCEL.
	function UI.DoAfterDryRun(rc)
		return(rc)
	end
	
	return(UI)
	
--wx.wxGetApp():MainLoop();
