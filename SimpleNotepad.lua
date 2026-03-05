local addonName, SimpleTools = ...

local CreateFrame = CreateFrame

SimpleTools.notepadText = ""

function SimpleTools:CreateSimpleNotepadUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    -- Create ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "SimpleToolsNotepadScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    -- Create EditBox
    local editBox = CreateFrame("EditBox", "SimpleToolsNotepadEditBox", scrollFrame)
    editBox:SetWidth(440)
    editBox:SetHeight(200)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            SimpleTools.notepadText = self:GetText()
            SimpleTools:SaveVariables()
        end
    end)
    
    -- Allow clicking anywhere in the ScrollFrame to focus the edit box
    scrollFrame:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    scrollFrame:SetScrollChild(editBox)

    self.notepadEditBox = editBox
    self.simpleNotepadFrame = frame

    return frame
end
