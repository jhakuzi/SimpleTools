local addonName, ST = ...

local CreateFrame = CreateFrame

function ST:CreateSimpleNotepadUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 8, -6)
    box:SetPoint("BOTTOMRIGHT", -8, 38)
    self:ApplyOverlayBackdrop(box)
    box:EnableMouse(true)

    local scrollFrame = CreateFrame("ScrollFrame", "SimpleToolsNotepadScrollFrame", box)
    scrollFrame:SetPoint("TOPLEFT", 6, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -6, 4)
    scrollFrame:EnableMouse(true)
    scrollFrame:EnableMouseWheel(true)

    local editBox = CreateFrame("EditBox", "SimpleToolsNotepadEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetTextInsets(4, 4, 2, 2)
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
        ST:UpdateNotepadProjected()
        ST:ScheduleSave()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        ST:SaveDB()
    end)
    editBox:SetScript("OnCursorChanged", function(selfBox, _, y, _, cursorHeight)
        local height = scrollFrame:GetHeight() or 0
        if height <= 0 then
            return
        end
        local offset = -(y or 0)
        local cursorBottom = offset + (cursorHeight or 14)
        local current = scrollFrame:GetVerticalScroll() or 0
        if offset < current then
            scrollFrame:SetVerticalScroll(offset)
        elseif cursorBottom > current + height then
            scrollFrame:SetVerticalScroll(cursorBottom - height)
        end
    end)

    local function FocusNotes()
        editBox:SetFocus()
    end
    box:SetScript("OnMouseDown", FocusNotes)
    scrollFrame:SetScript("OnMouseDown", FocusNotes)
    scrollFrame:SetScrollChild(editBox)
    scrollFrame:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)
    scrollFrame:SetScript("OnSizeChanged", function(selfScroll, width, height)
        editBox:SetWidth(math.max(100, (width or 200) - 4))
        local textHeight = editBox:GetHeight() or 0
        if textHeight < (height or 0) then
            editBox:SetHeight(math.max(height or 0, 20))
        end
    end)

    self.notepadClearButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.notepadClearButton:SetText("Clear")
    self.notepadClearButton:SetScript("OnClick", function()
        ST:ClearNotepad()
    end)

    self.notepadProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.notepadProjectButton:SetText("Send to screen")
    self.notepadProjectButton:SetScript("OnClick", function()
        ST:ToggleNotepadProjected()
    end)

    self:LayoutBottomPair(frame, self.notepadClearButton, self.notepadProjectButton)

    self.notepadEditBox = editBox
    self.simpleNotepadFrame = frame
    return frame
end

function ST:CreateNotepadProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleNotepadProjectedFrame", 260, 200, 260, 20, "Notes", function()
        ST:ShowNotepadProjected(false)
    end)
    frame.overlayHint = "Click to edit. Drag the title to move. Corner to resize. Hover for × to hide."

    local titleHit = CreateFrame("Frame", nil, frame)
    titleHit:SetPoint("TOPLEFT", 6, -2)
    titleHit:SetPoint("TOPRIGHT", -22, -2)
    titleHit:SetHeight(20)
    titleHit:EnableMouse(true)
    titleHit:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    titleHit:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        ST:SaveDB()
    end)

    local title = titleHit:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 4, 0)
    title:SetText("Notes")

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsNotepadOverlayScroll", frame)
    scroll:SetPoint("TOPLEFT", 8, -24)
    scroll:SetPoint("BOTTOMRIGHT", -8, 16)
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)

    local edit = CreateFrame("EditBox", "SimpleToolsNotepadOverlayEdit", scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetTextInsets(4, 4, 2, 2)
    edit:SetWidth(240)
    edit:SetHeight(160)
    edit:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    edit:SetScript("OnTextChanged", function(selfBox, userInput)
        if not userInput then
            return
        end
        ST.notepadText = selfBox:GetText()
        if ST.notepadEditBox and not ST.notepadEditBox:HasFocus() then
            ST.notepadEditBox:SetText(ST.notepadText)
        end
        ST:ScheduleSave()
    end)
    edit:SetScript("OnEditFocusLost", function()
        ST:SaveDB()
    end)
    edit:SetScript("OnCursorChanged", function(selfBox, _, y, _, cursorHeight)
        local height = scroll:GetHeight() or 0
        if height <= 0 then
            return
        end
        local offset = -(y or 0)
        local cursorBottom = offset + (cursorHeight or 14)
        local current = scroll:GetVerticalScroll() or 0
        if offset < current then
            scroll:SetVerticalScroll(offset)
        elseif cursorBottom > current + height then
            scroll:SetVerticalScroll(cursorBottom - height)
        end
    end)

    local function FocusNotes()
        edit:SetFocus()
    end
    scroll:SetScript("OnMouseDown", FocusNotes)
    scroll:SetScrollChild(edit)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)
    scroll:SetScript("OnSizeChanged", function(selfScroll, width, height)
        edit:SetWidth(math.max(80, (width or 200) - 4))
        if (edit:GetHeight() or 0) < (height or 0) then
            edit:SetHeight(math.max(height or 0, 20))
        end
    end)

    self:AttachResizeGrip(frame, 180, 90, 640, 520, function()
        ST:LayoutNotepadProjected()
    end)

    frame:SetScript("OnSizeChanged", function()
        ST:LayoutNotepadProjected()
    end)

    self.notepadProjEdit = edit
    self.notepadProjScroll = scroll
    self.notepadProjectedFrame = frame
end

function ST:LayoutNotepadProjected()
    if not self.notepadProjectedFrame or not self.notepadProjEdit then
        return
    end
    local scroll = self.notepadProjScroll
    if not scroll then
        return
    end
    local width = scroll:GetWidth() or 220
    self.notepadProjEdit:SetWidth(math.max(80, width - 4))
end

function ST:UpdateNotepadProjected()
    if not self.notepadProjEdit then
        return
    end
    if self.notepadProjEdit:HasFocus() then
        return
    end
    self.notepadProjEdit:SetText(self.notepadText or "")
end

function ST:ShowNotepadProjected(show, pos)
    if not self.notepadProjectedFrame then
        self:CreateNotepadProjectedFrame()
    end
    if show then
        self:PlaceOverlay(self.notepadProjectedFrame, pos)
        local w = (pos and pos.projWidth) or 260
        local h = (pos and pos.projHeight) or 200
        self.notepadProjectedFrame:SetSize(math.max(180, w), math.max(90, h))
        self.notepadProjectedFrame:Show()
        if self.notepadProjectButton then
            self.notepadProjectButton:SetText("Unproject")
        end
        self.notepadProjected = true
        self:LayoutNotepadProjected()
        self:UpdateNotepadProjected()
    else
        self.notepadProjectedFrame:Hide()
        if self.notepadProjectButton then
            self.notepadProjectButton:SetText("Send to screen")
        end
        self.notepadProjected = false
    end
end

function ST:ClearNotepad()
    self.notepadText = ""
    if self.notepadEditBox then
        self.notepadEditBox:SetText("")
    end
    self:UpdateNotepadProjected()
    self:SaveDB()
end

function ST:ToggleNotepadProjected()
    self:ShowNotepadProjected(not (self.notepadProjectedFrame and self.notepadProjectedFrame:IsShown()))
    self:SaveDB()
end
