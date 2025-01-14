return {
  name = "Flush Clipboard",
  description = "Flushes the clipboard when the editor app is closed.  This allows pasting from the clipboard in other apps after the editor is closed",
  author = "Steve Murphree",
  version = 0.1,
  dependencies = "1.20",

  onAppShutdown = function(self, app) 
      clipboard = wx.wxClipboard:Get()
      clipboard:Flush()
  end,
}

