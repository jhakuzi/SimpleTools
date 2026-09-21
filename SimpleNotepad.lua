local addonName, ST = ...

local CreateFrame = CreateFrame

function ST:CreateSimpleNotepadUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local scrollFrame = CreateFrame("ScrollFrame", "SimpleToolsNotepadScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local editBox = CreateFrame("EditBox", "SimpleToolsNotepadEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(440)
    editBox:SetHeight(200)
    editBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(selfBox, userInput)
        if not userInput then
            return
        end
        ST.notepadText = selfBox:GetText()
        ST:ScheduleSave()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        ST:SaveDB()
    end)

    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    scrollFrame:SetScrollChild(editBox)

    -- Keep the edit box as wide as the scroll frame after layout.
    scrollFrame:SetScript("OnSizeChanged", function(selfScroll, width)
        editBox:SetWidth(math.max(100, width - 4))
    end)

    self.notepadEditBox = editBox
    self.simpleNotepadFrame = frame
    return frame
end
