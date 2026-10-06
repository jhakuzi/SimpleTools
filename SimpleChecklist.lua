local addonName, ST = ...
local CreateFrame = CreateFrame
ST.checklistViews = {}

local function TaskText(text)
    if type(text) ~= "string" then return nil end
    text = strtrim(text)
    if text == "" or #text > 120 then return nil end
    return text
end

function ST:CopyChecklistItems(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for _, item in ipairs(source) do
        local text = type(item) == "table" and TaskText(item.text)
        if text then result[#result + 1] = {text = text, checked = item.checked == true} end
    end
    return result
end

function ST:AddChecklistItem(text)
    text = TaskText(text)
    if not text then return false end
    self.checklistItems[#self.checklistItems + 1] = {text = text, checked = false}
    self:RefreshChecklistViews()
    self:SaveDB()
    return true
end

function ST:ChangeChecklistItem(entry, text)
    text = TaskText(text)
    if not text then return false end
    for _, item in ipairs(self.checklistItems) do
        if item == entry then
            item.text = text
            self:RefreshChecklistViews()
            self:SaveDB()
            return true
        end
    end
    return false
end

function ST:ToggleChecklistItem(entry)
    for _, item in ipairs(self.checklistItems) do
        if item == entry then
            item.checked = not item.checked
            self:RefreshChecklistViews()
            self:SaveDB()
            return true
        end
    end
    return false
end

function ST:RemoveChecklistItem(entry)
    for index, item in ipairs(self.checklistItems) do
        if item == entry then
            table.remove(self.checklistItems, index)
            if self.checklistEditing == entry then self:CancelChecklistEdit() end
            self:RefreshChecklistViews()
            self:SaveDB()
            return true
        end
    end
    return false
end

function ST:ResetChecklistChecks()
    for _, item in ipairs(self.checklistItems) do item.checked = false end
    self:RefreshChecklistViews()
    self:SaveDB()
end

function ST:CancelChecklistEdit()
    self.checklistEditing = nil
    if self.checklistEditFrame then self.checklistEditFrame:Hide() end
end

function ST:EditChecklistItem(entry)
    if not entry then return end
    if not self.checklistEditFrame then
        local frame = self:CreateOverlayFrame("SimpleToolsChecklistEdit", 320, 112, 0, 40, "Edit task", function()
            ST:CancelChecklistEdit()
        end)
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -8)
        title:SetText("Edit task")
        local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        input:SetHeight(20)
        input:SetPoint("TOPLEFT", 16, -32)
        input:SetPoint("TOPRIGHT", -16, -32)
        input:SetAutoFocus(false)
        input:SetMaxLetters(120)
        local function save()
            if ST:ChangeChecklistItem(ST.checklistEditing, input:GetText()) then ST:CancelChecklistEdit() end
        end
        input:SetScript("OnEnterPressed", save)
        input:SetScript("OnEscapePressed", function() ST:CancelChecklistEdit() end)
        local confirm = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        confirm:SetText("Save")
        confirm:SetScript("OnClick", save)
        local cancel = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        cancel:SetText("Cancel")
        cancel:SetScript("OnClick", function() ST:CancelChecklistEdit() end)
        self:LayoutBottomPair(frame, confirm, cancel)
        self.checklistEditFrame, self.checklistEditInput = frame, input
    end
    self.checklistEditing = entry
    self.checklistEditInput:SetText(entry.text)
    self.checklistEditFrame:Show()
    self.checklistEditInput:SetFocus()
    self.checklistEditInput:HighlightText()
end

function ST:RefreshChecklistViews()
    for _, view in ipairs(self.checklistViews) do
        for index = 1, math.max(#self.checklistItems, #view.rows) do
            local row, entry = view.rows[index], self.checklistItems[index]
            if entry then
                if not row then
                    row = CreateFrame("Button", nil, view.child)
                    row:SetHeight(24)
                    row:SetPoint("TOPLEFT", 0, -(index - 1) * 24)
                    row:SetPoint("TOPRIGHT", 0, -(index - 1) * 24)
                    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    row.check:SetSize(24, 24)
                    row.check:SetPoint("LEFT", 0, 0)
                    row.check:SetScript("OnClick", function() ST:ToggleChecklistItem(row.entry) end)
                    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    row.text:SetPoint("LEFT", 28, 0)
                    row.text:SetPoint("RIGHT", -24, 0)
                    row.text:SetJustifyH("LEFT")
                    row.text:SetWordWrap(false)
                    row.strike = row:CreateTexture(nil, "OVERLAY")
                    row.strike:SetColorTexture(0.6, 0.6, 0.6, 0.8)
                    row.strike:SetHeight(1)
                    row.strike:SetPoint("LEFT", row.text, "LEFT", 0, 0)
                    row:SetScript("OnClick", function(selfRow) ST:EditChecklistItem(selfRow.entry) end)
                    row.remove = CreateFrame("Button", nil, row)
                    row.remove:SetSize(16, 16)
                    row.remove:SetPoint("RIGHT", -2, 0)
                    local label = row.remove:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    label:SetPoint("CENTER")
                    label:SetText("x")
                    row.remove:SetScript("OnClick", function() ST:RemoveChecklistItem(row.entry) end)
                    view.rows[index] = row
                end
                row.entry = entry
                row.text:SetText(entry.text)
                if entry.checked then row.text:SetTextColor(0.6, 0.6, 0.6)
                else row.text:SetTextColor(0.95, 0.9, 0.78) end
                row.check:SetChecked(entry.checked)
                row.strike:SetWidth(math.min(row.text:GetStringWidth(), math.max(1, view.child:GetWidth() - 52)))
                row.strike:SetShown(entry.checked)
                row:Show()
            elseif row then row.entry = nil; row:Hide() end
        end
        view.child:SetHeight(math.max(20, #self.checklistItems * 24))
        view.empty:SetShown(#self.checklistItems == 0)
        view.reset:SetEnabled(#self.checklistItems > 0)
        view.scroll:SetVerticalScroll(math.min(view.scroll:GetVerticalScroll(), view.scroll:GetVerticalScrollRange()))
    end
end

function ST:CreateChecklistControls(frame, top, projected)
    local view = {rows = {}}
    local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    input:SetHeight(20)
    input:SetPoint("TOPLEFT", 12, top)
    input:SetPoint("TOPRIGHT", -82, top)
    input:SetAutoFocus(false)
    input:SetMaxLetters(120)
    local function add()
        if ST:AddChecklistItem(input:GetText()) then
            input:SetText("")
            input:ClearFocus()
            view.scroll:SetVerticalScroll(view.scroll:GetVerticalScrollRange())
        end
    end
    input:SetScript("OnEnterPressed", add)
    input:SetScript("OnEscapePressed", function(selfBox) selfBox:ClearFocus() end)
    view.input = input
    local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    button:SetSize(64, 22)
    button:SetPoint("TOPRIGHT", -8, top)
    button:SetText("Add")
    button:SetScript("OnClick", add)
    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 8, top - 30)
    box:SetPoint("BOTTOMRIGHT", -8, 38)
    self:ApplyOverlayBackdrop(box)
    local scroll = CreateFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", 6, -4)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfScroll, delta)
        selfScroll:SetVerticalScroll(math.max(0, math.min(selfScroll:GetVerticalScrollRange(), selfScroll:GetVerticalScroll() - delta * 24)))
    end)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(260, 20)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(_, width)
        child:SetWidth(math.max(1, width))
        ST:RefreshChecklistViews()
    end)
    view.child, view.scroll = child, scroll
    view.empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    view.empty:SetPoint("TOPLEFT", 4, -4)
    view.empty:SetText("No tasks yet.")
    view.reset = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    view.reset:SetText("Reset checks")
    view.reset:SetScript("OnClick", function() ST:ResetChecklistChecks() end)
    if projected then
        view.reset:SetSize(112, 25)
        view.reset:SetPoint("BOTTOM", 0, 8)
    else
        local project = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        project:SetText("Send to screen")
        project:SetScript("OnClick", function() ST:ShowChecklistProjected(not ST.checklistProjected) end)
        self.checklistProjectButton = project
        self:LayoutBottomPair(frame, view.reset, project)
    end
    table.insert(self.checklistViews, view)
    self:RefreshChecklistViews()
    return view
end

function ST:ShowChecklistProjected(show, pos)
    if not self.checklistProjectedFrame and show then
        local frame = self:CreateOverlayFrame("SimpleToolsChecklistOverlay", 300, 240, 260, -180, "Checklist", function()
            ST:ShowChecklistProjected(false)
        end)
        frame.overlayHint = "Tick tasks off, click their text to edit, or use x to delete. Drag the border to move."
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -8)
        title:SetText("Checklist")
        self:CreateChecklistControls(frame, -30, true)
        self.checklistProjectedFrame = frame
    end
    self.checklistProjected = show == true
    if self.checklistProjectedFrame then
        if show then self:PlaceOverlay(self.checklistProjectedFrame, pos) end
        self.checklistProjectedFrame:SetShown(self.checklistProjected)
    end
    if self.checklistProjectButton then self.checklistProjectButton:SetText(show and "Unproject" or "Send to screen") end
    self:SaveDB()
end

function ST:CreateChecklistUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self:CreateChecklistControls(frame, -2, false)
    return frame
end
