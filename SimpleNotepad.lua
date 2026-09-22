local addonName, ST = ...

local CreateFrame = CreateFrame

function ST:CreateSimpleNotepadUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local scrollFrame = CreateFrame("ScrollFrame", "SimpleToolsNotepadScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 38)

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
        ST:UpdateNotepadProjected()
        ST:ScheduleSave()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        ST:SaveDB()
    end)

    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    scrollFrame:SetScrollChild(editBox)

    scrollFrame:SetScript("OnSizeChanged", function(selfScroll, width)
        editBox:SetWidth(math.max(100, width - 4))
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
    frame.overlayHint = "Drag to move. Drag the bottom-right corner to resize. Hover for × to hide."

    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(180, 90, 640, 520)
    else
        if frame.SetMinResize then
            frame:SetMinResize(180, 90)
        end
        if frame.SetMaxResize then
            frame:SetMaxResize(640, 520)
        end
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("Notes")

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsNotepadOverlayScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -24)
    scroll:SetPoint("BOTTOMRIGHT", -28, 16)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(220, 160)
    scroll:SetScrollChild(child)

    local body = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", 0, 0)
    body:SetWidth(214)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    if body.SetWordWrap then
        body:SetWordWrap(true)
    end
    body:SetText("No notes yet.")

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:SetFrameLevel(frame:GetFrameLevel() + 6)
    grip:EnableMouse(true)
    local up = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"
    local hi = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight"
    local down = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down"
    grip:SetNormalTexture(up)
    grip:SetHighlightTexture(hi)
    grip:SetPushedTexture(down)
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        ST:LayoutNotepadProjected()
        ST:SaveDB()
    end)

    frame:SetScript("OnSizeChanged", function()
        ST:LayoutNotepadProjected()
    end)

    self.notepadProjBody = body
    self.notepadProjChild = child
    self.notepadProjectedFrame = frame
end

function ST:LayoutNotepadProjected()
    if not self.notepadProjectedFrame or not self.notepadProjBody then
        return
    end
    local width = self.notepadProjectedFrame:GetWidth() or 260
    local inner = math.max(80, width - 46)
    self.notepadProjBody:SetWidth(inner)
    if self.notepadProjChild then
        self.notepadProjChild:SetWidth(inner)
    end
    self:UpdateNotepadProjected()
end

function ST:UpdateNotepadProjected()
    if not self.notepadProjBody then
        return
    end
    local text = self.notepadText or ""
    if text == "" then
        text = "No notes yet."
    end
    self.notepadProjBody:SetText(text)
    local height = 160
    if self.notepadProjBody.GetStringHeight then
        height = math.max(160, self.notepadProjBody:GetStringHeight() + 8)
    end
    if self.notepadProjChild then
        self.notepadProjChild:SetHeight(height)
    end
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
