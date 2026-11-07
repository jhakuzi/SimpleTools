local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame

local GROUPS = {
    { key = "time", label = "Time", width = 64 },
    { key = "track", label = "Track", width = 64 },
    { key = "lists", label = "Lists", width = 64 },
    { key = "utility", label = "Utility", width = 72 },
}

local TOOLS = {
    { id = 1, group = "time", label = "Clocks", width = 62 },
    { id = 7, group = "time", label = "Break", width = 56 },
    { id = 2, group = "track", label = "XP/Gold", width = 72 },
    { id = 3, group = "track", label = "Gather", width = 62 },
    { id = 4, group = "lists", label = "Notepad", width = 70 },
    { id = 5, group = "lists", label = "Shop", width = 52 },
    { id = 10, group = "lists", label = "Checklist", width = 76 },
    { id = 6, group = "lists", label = "Locations", width = 76 },
    { id = 9, group = "utility", label = "Calc", width = 50 },
    { id = 8, group = "utility", label = "Logs", width = 50 },
    { id = 11, group = "utility", label = "Options", width = 68 },
}

local TOOL_GROUP = {}
for _, tool in ipairs(TOOLS) do
    TOOL_GROUP[tool.id] = tool.group
end

local function StyleToolButton(btn, label, width)
    btn.naturalWidth = width
    btn:SetSize(width, 18)
    if btn.SetNormalFontObject then
        btn:SetNormalFontObject("GameFontNormalSmall")
    end
    if btn.Text and btn.Text.SetFontObject then
        btn.Text:SetFontObject("GameFontNormalSmall")
    end
    btn:SetText(label)
end

function ST:CreateMainFrame()
    local frame = self:CreateThemedPanel("SimpleToolsFrame")
    self.frame = frame
    self:ApplyMainPanelBackground(frame)
    self:ApplyMainFrameSize(ST.FRAME_W, ST.FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        ST:SaveDB()
    end)
    tinsert(UISpecialFrames, "SimpleToolsFrame")
    self:SetPanelTitle(frame, "SimpleTools")
    self:EnsurePanelClose(frame)
    self:AttachResizeGrip(frame, ST.FRAME_MIN_W, ST.FRAME_MIN_H, ST.FRAME_MAX_W, ST.FRAME_MAX_H, function()
        ST:OnMainFrameSizeChanged()
    end)
    frame:SetScript("OnSizeChanged", function()
        ST:OnMainFrameSizeChanged()
        ST:ScheduleSave()
    end)
    frame:HookScript("OnShow", function()
        -- DefaultPanelTemplate can snap to a huge preferred size the first time
        -- it is shown. Re-apply the compact (or player-resized) size after that.
        local w, h = ST.frameW or ST.FRAME_W, ST.frameH or ST.FRAME_H
        C_Timer.After(0, function()
            if ST.frame and ST.frame:IsShown() then
                ST:ApplyMainFrameSize(w, h)
            end
        end)
    end)
    self.groupButtons = {}
    self.tabButtons = {}
    self.tabFrames = {}

    for _, group in ipairs(GROUPS) do
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        StyleToolButton(btn, group.label, group.width)
        btn.groupKey = group.key
        btn:SetScript("OnClick", function()
            if ST.activeGroup == group.key then
                return
            end
            for _, tool in ipairs(TOOLS) do
                if tool.group == group.key then
                    ST:SelectTab(tool.id)
                    return
                end
            end
        end)
        self.groupButtons[#self.groupButtons + 1] = btn
    end

    for _, tool in ipairs(TOOLS) do
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        StyleToolButton(btn, tool.label, tool.width)
        btn.groupKey = tool.group
        btn:SetScript("OnClick", function()
            self:SelectTab(tool.id)
        end)
        self.tabButtons[tool.id] = btn
    end

    self.contentFrame = CreateFrame("Frame", nil, frame)
    self.contentFrame:SetPoint("TOPLEFT", 10, -56)
    self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
    self:LayoutTabButtons()

    self.tabFrames[1] = self:CreateTimeTab(self.contentFrame)
    self.tabFrames[2] = self:CreateXPGoldTab(self.contentFrame)
    self.tabFrames[3] = self:CreateSimpleGatherUI(self.contentFrame)
    self.tabFrames[4] = self:CreateSimpleNotepadUI(self.contentFrame)
    self.tabFrames[5] = self:CreateSimpleShopUI(self.contentFrame)
    self.tabFrames[6] = self:CreateLocationsUI(self.contentFrame)
    self.tabFrames[7] = self:CreateBreakUI(self.contentFrame)
    self.tabFrames[8] = self:CreateLoggingUI(self.contentFrame)
    self.tabFrames[9] = self:CreateCalculatorUI(self.contentFrame)
    self.tabFrames[10] = self:CreateChecklistUI(self.contentFrame)
    self.tabFrames[11] = self:CreateOptionsUI(self.contentFrame)

    self.timerFrame = self.tabFrames[1]
    self.simpleXPFrame = self.tabFrames[2]
    self.simpleGatherFrame = self.tabFrames[3]
    self.simpleNotepadFrame = self.tabFrames[4]
    self.shopFrame = self.tabFrames[5]

    -- LoadState selects the saved tab after all frames have been created.
    frame:Hide()
end

function ST:LayoutTabButtons()
    local frame = self.frame
    local groups = self.groupButtons
    local tools = self.tabButtons
    if not frame or not groups or not tools then
        return
    end
    local active = self.activeGroup or "time"
    for _, btn in ipairs(tools) do
        if btn.groupKey == active then
            btn:Show()
        else
            btn:Hide()
        end
    end

    local function place(buttons, y)
        local frameWidth = frame:GetWidth() or ST.FRAME_W
        local gap, height = 4, 18
        local visible, total = {}, 0
        for _, btn in ipairs(buttons) do
            if not btn.IsShown or btn:IsShown() then
                visible[#visible + 1] = btn
                total = total + (btn.naturalWidth or btn:GetWidth() or 50)
            end
        end
        if #visible == 0 then
            return
        end
        total = total + gap * (#visible - 1)
        local x = math.max(8, (frameWidth - total) / 2)
        for _, btn in ipairs(visible) do
            local width = btn.naturalWidth or btn:GetWidth() or 50
            btn:SetSize(width, height)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
            x = x + width + gap
        end
    end

    place(groups, -30)
    place(tools, -51)
    if self.contentFrame then
        self.contentFrame:ClearAllPoints()
        self.contentFrame:SetPoint("TOPLEFT", 10, -76)
        self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 8)
    end
end

function ST:OnMainFrameSizeChanged()
    self:LayoutTabButtons()
    if self.LayoutShopProfButtons then
        self:LayoutShopProfButtons()
    end
    if self.shopListChild and self.RefreshShopList then
        self:RefreshShopList()
    end
end

function ST:SelectTab(id)
    if not self.tabFrames or not self.tabFrames[id] then
        id = 1
    end
    self.activeGroup = TOOL_GROUP[id] or "time"
    for i, tabFrame in ipairs(self.tabFrames) do
        if i == id then
            tabFrame:Show()
        else
            tabFrame:Hide()
        end
    end
    for _, btn in ipairs(self.groupButtons or {}) do
        if btn.groupKey == self.activeGroup then
            btn:Disable()
        else
            btn:Enable()
        end
    end
    for i, btn in ipairs(self.tabButtons or {}) do
        if i == id then
            btn:Disable()
        else
            btn:Enable()
        end
    end
    if self.db and self.db.ui then
        self.db.ui.selectedTab = id
    end
    if self.LayoutTabButtons then
        self:LayoutTabButtons()
    end
    if id == 5 and self.HookShopClicks then
        self:HookShopClicks()
    end
    if id == 11 and self.UpdateOptionsDisplay then
        self:UpdateOptionsDisplay()
    end
    self:RefreshTicker()
end

function ST:ToggleOption(key)
    if not self.db or not self.db.options then
        return
    end
    self.db.options[key] = self.db.options[key] == false
    self:SaveDB()
    if self.UpdateOptionsDisplay then
        self:UpdateOptionsDisplay()
    end
end

function ST:UpdateOptionsDisplay()
    if not self.optionsSoundButton or not self.db or not self.db.options then
        return
    end
    local options = self.db.options
    self.optionsSoundButton:SetText(options.sound == false and "Alert sounds: Off" or "Alert sounds: On")
    self.optionsChatButton:SetText(options.chat == false and "Chat messages: Off" or "Chat messages: On")
    self.optionsNotepadButton:SetText(options.notepadPerCharacter and "Notepad: This character" or "Notepad: Shared")
    self.optionsChecklistButton:SetText(options.checklistPerCharacter and "Checklist: This character" or "Checklist: Shared")
    self.optionsLocationsButton:SetText(options.locationsPerCharacter and "Locations: This character" or "Locations: Shared")
end

function ST:CreateOptionsUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 12, -4)
    hint:SetPoint("TOPRIGHT", -12, -4)
    if hint.SetJustifyH then
        hint:SetJustifyH("LEFT")
    end
    if hint.SetWordWrap then
        hint:SetWordWrap(true)
    end
    hint:SetText("XP, gold, and gather sessions always follow this character. Shared lists stay shared until you switch them.")

    local function optionButton(y, onClick)
        local button = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        button:SetSize(240, 20)
        button:SetPoint("TOP", 0, y)
        button:SetScript("OnClick", onClick)
        return button
    end

    self.optionsSoundButton = optionButton(-28, function()
        ST:ToggleOption("sound")
    end)
    self.optionsChatButton = optionButton(-50, function()
        ST:ToggleOption("chat")
    end)
    self.optionsNotepadButton = optionButton(-78, function()
        ST:SetListScope("notepadPerCharacter", not ST.db.options.notepadPerCharacter)
    end)
    self.optionsChecklistButton = optionButton(-100, function()
        ST:SetListScope("checklistPerCharacter", not ST.db.options.checklistPerCharacter)
    end)
    self.optionsLocationsButton = optionButton(-122, function()
        ST:SetListScope("locationsPerCharacter", not ST.db.options.locationsPerCharacter)
    end)
    self:UpdateOptionsDisplay()
    return frame
end

function ST:CreateTimeTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local cols = self:SplitColumns(frame, 3)
    self:CreateTimerUI(cols[1])
    self:CreateSimpleWatchUI(cols[2])
    self:CreateSimpleReminderUI(cols[3])
    return frame
end

function ST:CreateXPGoldTab(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local cols = self:SplitColumns(frame, 2)
    self:CreateSimpleXPUI(cols[1])
    self:CreateSimpleGoldUI(cols[2])
    return frame
end

function ST:CreateTimerUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOP", 0, -2)
    heading:SetText("Timer")

    self.timerDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self:SetHeadlineFont(self.timerDisplay)
    self.timerDisplay:SetPoint("TOP", 0, -22)
    self.timerDisplay:SetText("00:00")

    self.durationInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.durationInput:SetSize(44, 18)
    self.durationInput:SetPoint("TOP", self.timerDisplay, "BOTTOM", 0, -4)
    self.durationInput:SetAutoFocus(false)
    self.durationInput:SetNumeric(true)
    self.durationInput:SetMaxLetters(4)
    local defaultDuration = 10
    if self.db and self.db.options and self.db.options.defaultDuration then
        defaultDuration = self.db.options.defaultDuration
    end
    self.durationInput:SetText(tostring(defaultDuration))

    self.startPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.startPauseButton:SetText("Start")
    self.startPauseButton:SetScript("OnClick", function()
        ST:ToggleTimer()
    end)

    self.timerProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.timerProjectButton:SetText("Send to screen")
    self.timerProjectButton:SetScript("OnClick", function()
        ST:ToggleTimerProjected()
    end)

    self.resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.resetButton:SetText("Reset")
    self.resetButton:SetScript("OnClick", function()
        ST:ResetTimer()
    end)

    self:LayoutColumnButtons(frame, self.startPauseButton, self.timerProjectButton, self.resetButton)

    return frame
end

function ST:UpdateDisplay()
    if not self.timerDisplay then
        return
    end
    local displayTime = self.timer.remaining
    if self.timer.running then
        displayTime = math.max(0, self.timer.remaining - (GetTime() - self.timer.anchor))
    end
    local text = self:FormatTime(displayTime)
    self.timerDisplay:SetText(text)
    if self.timerProjTime then
        self.timerProjTime:SetText(text)
    end
end

function ST:StartTimer()
    local duration = tonumber(self.durationInput:GetText())
    if not duration or duration <= 0 then
        self:Print("Enter a duration in minutes.")
        return
    end
    self.timer.total = duration * 60
    self.timer.remaining = self.timer.total
    self.timer.anchor = GetTime()
    self.timer.running = true
    self.startPauseButton:SetText("Pause")
    if self.db and self.db.options then
        self.db.options.defaultDuration = duration
    end
    self:SaveDB()
    self:UpdateDisplay()
    self:RefreshTicker()
end

function ST:PauseTimer()
    if not self.timer.running then
        return
    end
    self.timer.remaining = math.max(0, self.timer.remaining - (GetTime() - self.timer.anchor))
    self.timer.running = false
    self.startPauseButton:SetText("Resume")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateDisplay()
end

function ST:ResumeTimer()
    if self.timer.running or self.timer.remaining <= 0 then
        return
    end
    self.timer.anchor = GetTime()
    self.timer.running = true
    self.startPauseButton:SetText("Pause")
    self:SaveDB()
    self:RefreshTicker()
end

function ST:ResetTimer()
    self.timer.running = false
    self.timer.remaining = 0
    self.timer.total = 0
    self.timer.anchor = 0
    self.startPauseButton:SetText("Start")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateDisplay()
end

function ST:ToggleTimer()
    if self.timer.running then
        self:PauseTimer()
    elseif self.timer.remaining > 0 then
        self:ResumeTimer()
    else
        self:StartTimer()
    end
end

function ST:TimerFinished()
    self:ResetTimer()
    self:PlayAlert()
    self:Print("Timer finished.")
    self:UpdateDisplay()
end

function ST:CreateTimerProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleTimerProjectedFrame", 140, 52, 180, 120, "Timer", function()
        ST:ShowTimerProjected(false)
    end)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    label:SetPoint("TOP", 0, -8)
    label:SetText("Timer")
    self.timerProjTime = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.timerProjTime:SetPoint("TOP", 0, -22)
    self.timerProjTime:SetText("00:00")
    self.timerProjectedFrame = frame
end

function ST:ShowTimerProjected(show, pos)
    if not self.timerProjectedFrame then
        self:CreateTimerProjectedFrame()
    end
    if show then
        self:PlaceOverlay(self.timerProjectedFrame, pos)
        self.timerProjectedFrame:Show()
        if self.timerProjectButton then
            self.timerProjectButton:SetText("Unproject")
        end
        self.timer.projected = true
        self:UpdateDisplay()
    else
        self.timerProjectedFrame:Hide()
        if self.timerProjectButton then
            self.timerProjectButton:SetText("Send to screen")
        end
        self.timer.projected = false
    end
end

function ST:ToggleTimerProjected()
    self:ShowTimerProjected(not (self.timerProjectedFrame and self.timerProjectedFrame:IsShown()))
    self:SaveDB()
end

function ST:ToggleWindow()
    if not self.frame then
        return
    end
    self.frame:SetShown(not self.frame:IsShown())
end

function ST:RegisterSlash()
    SLASH_SIMPLETOOLS1 = "/tools"
    SLASH_SIMPLETOOLS2 = "/simpletools"
    SLASH_SIMPLETOOLS3 = "/st"
    SlashCmdList["SIMPLETOOLS"] = function(msg)
        msg = strtrim(strlower(msg or ""))
        if msg == "options" or msg == "config" or msg == "settings" then
            if self.frame and not self.frame:IsShown() then
                self.frame:Show()
            end
            self:SelectTab(11)
        elseif msg == "sound" then
            self:ToggleOption("sound")
            self:Print("Alert sounds " .. (self.db.options.sound == false and "off." or "on."))
        elseif msg == "chat" then
            local enabling = self.db.options.chat == false
            self:ToggleOption("chat")
            if enabling then
                self:Print("Chat messages on.")
            end
        elseif msg == "resetpos" then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("CENTER")
            self:ApplyMainFrameSize(ST.FRAME_W, ST.FRAME_H)
            self:SaveDB()
            self:Print("Window position and size reset.")
        else
            self:ToggleWindow()
        end
    end
end

function ST:Initialize()
    self:InitDB()
    self:CreateMainFrame()
    self:LoadState()
    self:RegisterEvents()
    self:RegisterSlash()
    self:RegisterSettings()
    self:RefreshTicker()

    if not self.db.seenWelcome then
        self:Print("Loaded. Type /tools to open, /tools options for settings.")
        self.db.seenWelcome = true
        self:SaveDB()
    end
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded(addonName, function()
        ST:Initialize()
    end)
else
    local boot = CreateFrame("Frame")
    boot:RegisterEvent("ADDON_LOADED")
    boot:SetScript("OnEvent", function(self, event, name)
        if name == addonName then
            ST:Initialize()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end
