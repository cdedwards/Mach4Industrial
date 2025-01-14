keymap[ID.STEP] = "F11"
keymap[ID.STEPOVER] = "F10"
keymap[ID.STEPOUT] = "Shift-F11"
keymap[ID.BREAKPOINTTOGGLE] = "F9"
keymap[ID.BREAKPOINTNEXT] = "Ctrl-F9"
keymap[ID.BREAKPOINTPREV] = "Shift-F9"

-- to modify loaded configuration for recognized extensions for lua files
local luaspec = ide.specs.lua
luaspec.exts[#luaspec.exts+1] = "pst"

-- to change font size to 12
--editor.fontsize = 12 -- this is mapped to ide.config.editor.fontsize
--editor.fontname = "Courier New"
--filehistorylength = 20 -- this is mapped to ide.config.filehistorylength

-- to specify full path to lua interpreter if you need to use your own version
--path.lua = 'd:/lua/lua'

-- to have 4 spaces when TAB is used in the editor
editor.tabwidth = 4

-- to have TABs stored in the file (to allow mixing tabs and spaces)
editor.usetabs  = true

-- to disable wrapping of long lines in the editor
editor.usewrap = false

-- to turn dynamic words on and to start suggestions after 4 characters
acandtip.nodynwords = false
acandtip.startat = 4

-- to automatically open files requested during debugging
editor.autoactivate = true

-- to disable indicators (underlining) on function calls
-- styles.indicator.fncall = nil

-- to change the color of the indicator used for function calls
--styles.indicator.fncall.fg = {240,0,0}

-- to change the type of the indicator used for function calls
--styles.indicator.fncall.st = wxstc.wxSTC_INDIC_PLAIN
  --[[ other possible values are:
  wxSTC_INDIC_DOTS   Dotted underline; wxSTC_INDIC_PLAIN       Single-line underline
  wxSTC_INDIC_TT     Line of Tshapes;  wxSTC_INDIC_SQUIGGLE    Squiggly underline
  wxSTC_INDIC_STRIKE Strike-out;       wxSTC_INDIC_SQUIGGLELOW Squiggly underline (2 pixels)
  wxSTC_INDIC_BOX    Box;              wxSTC_INDIC_ROUNDBOX    Rounded Box
  wxSTC_INDIC_DASH   Dashed underline; wxSTC_INDIC_STRAIGHTBOX Box with trasparency
  wxSTC_INDIC_DOTBOX Dotted rectangle; wxSTC_INDIC_DIAGONAL    Diagonal hatching
  wxSTC_INDIC_HIDDEN No visual effect;
  --]]

-- to enable additional spec files (like spec/glsl.lua)
-- (no longer needed in v1.51+) load.specs(function(file) return file:find('spec[/\\]glsl%.lua$') end)

-- to specify a default EOL encoding to be used for new files:
-- `wxstc.wxSTC_EOL_CRLF` or `wxstc.wxSTC_EOL_LF`;
-- `nil` means OS default: CRLF on Windows and LF on Linux/Unix and OSX.
-- (OSX had CRLF as a default until v0.36, which fixed it).
editor.defaulteol = wxstc.wxSTC_EOL_CRLF

-- to turn off checking for mixed end-of-line encodings in loaded files
editor.checkeol = false

-- to force execution to continue immediately after starting debugging;
-- set to `false` to disable (the interpreter will stop on the first line or
-- when debugging starts); some interpreters may use `true` or `false`
-- by default, but can be still reconfigured with this setting.
--debugger.runonstart = true

-- to set compact fold that doesn't include empty lines after a block
editor.foldcompact = true

-- to disable zoom with mouse wheel as it may be too sensitive on OSX
editor.nomousezoom = true
package.path = "./Modules/?.lua;" .. package.path
package.cpath = "./Modules/?.dll;" .. package.cpath
