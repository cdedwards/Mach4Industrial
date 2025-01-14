local function SetToolTip(self, editor)
    local notebook = ide:GetEditorNotebook()
    local index = notebook:GetPageIndex(editor)
    local doc = ide:GetDocument(editor)
    notebook:SetPageToolTip(index, doc and doc:GetFilePath() or "new document")
end

return {
    name = "Editor Tab Hover",
    description = "Displays a tooltip with the full path of the file loaded in the editor when the mouse hovers the editor's tab.",
    author = "Steve Murphree",
    version = 0.1,
    dependencies = "1.20",

    onEditorLoad = function(self, editor) 
        SetToolTip(self, editor)
    end,

    onEditorNew = function(self, editor) 
        SetToolTip(self, editor)
    end,

    onEditorSave = function(self, editor) 
        SetToolTip(self, editor)
    end,
}

