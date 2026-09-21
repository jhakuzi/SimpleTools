local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame

local TABS = {
    { key = "timer",    label = "Timer",     width = 80 },
    { key = "watch",    label = "Stopwatch", width = 92 },
    { key = "reminder", label = "Reminder",  width = 86 },
    { key = "xp",       label = "XP",        width = 70 },
    { key = "gold",     label = "Gold",      width = 70 },
    { key = "notepad",  label = "Notepad",   width = 84 },
}

function ST:CreateMainFrame()
    local frame = CreateFrame("Frame", "SimpleToolsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(520, 248)
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

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("SimpleTools")

    self.frame = frame
    self.tabButtons = {}
    self.tabFrames = {}

    local prev
    for i, tab in ipairs(TABS) do
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        btn:SetSize(tab.width, 20)
        if prev then
            btn:SetPoint("LEFT", prev, "RIGHT", 2, 0)
        else
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
        end
        btn:SetText(tab.label)
        btn:SetScript("OnClick", function()
            self:SelectTab(i)
        end)
        self.tabButtons[i] = btn
        prev = btn
    end

    self.contentFrame = CreateFrame("Frame", nil, frame)
    self.contentFrame:SetPoint("TOPLEFT", 10, -56)
    self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)

    self.tabFrames[1] = self:CreateTimerUI(self.contentFrame)
    self.tabFrames[2] = self:CreateSimpleWatchUI(self.contentFrame)
    self.tabFrames[3] = self:CreateSimpleReminderUI(self.contentFrame)
    self.tabFrames[4] = self:CreateSimpleXPUI(self.contentFrame)
    self.tabFrames[5] = self:CreateSimpleGoldUI(self.contentFrame)
    self.tabFrames[6] = self:CreateSimpleNotepadUI(self.contentFrame)

    -- Keep old field names so modules stay readable
    self.timerFrame = self.tabFrames[1]
    self.simpleWatchFrame = self.tabFrames[2]
    self.simpleReminderFrame = self.tabFrames[3]
    self.simpleXPFrame = self.tabFrames[4]
    self.simpleGoldFrame = self.tabFrames[5]
    self.simpleNotepadFrame = self.tabFrames[6]

    self:SelectTab(1)
    frame:Hide()
end

function ST:SelectTab(id)
    for i, tabFrame in ipairs(self.tabFrames) do
        if i == id then
            tabFrame:Show()
            self.tabButtons[i]:Disable()
        else
            tabFrame:Hide()
            self.tabButtons[i]:Enable()
        end
    end
    if self.db and self.db.ui then
        self.db.ui.selectedTab = id
    end
end

function ST:CreateTimerUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local durationLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durationLabel:SetPoint("TOP", -48, -8)
    durationLabel:SetText("Duration (min):")

    self.durationInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.durationInput:SetSize(50, 20)
    self.durationInput:SetPoint("LEFT", durationLabel, "RIGHT", 10, 0)
    self.durationInput:SetAutoFocus(false)
    self.durationInput:SetNumeric(true)
    self.durationInput:SetMaxLetters(4)
    local defaultDuration = 10
    if self.db and self.db.options and self.db.options.defaultDuration then
        defaultDuration = self.db.options.defaultDuration
    end
    self.durationInput:SetText(tostring(defaultDuration))

    self.timerDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.timerDisplay:SetPoint("CENTER", 0, 6)
    self.timerDisplay:SetText("00:00")

    self.startPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.startPauseButton:SetSize(80, 25)
    self.startPauseButton:SetPoint("BOTTOMLEFT", 10, 8)
    self.startPauseButton:SetText("Start")
    self.startPauseButton:SetScript("OnClick", function()
        ST:ToggleTimer()
    end)

    self.resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.resetButton:SetSize(80, 25)
    self.resetButton:SetPoint("BOTTOMRIGHT", -10, 8)
    self.resetButton:SetText("Reset")
    self.resetButton:SetScript("OnClick", function()
        ST:ResetTimer()
    end)

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
    self.timerDisplay:SetText(self:FormatTime(displayTime))
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
            self:OpenSettings()
        elseif msg == "resetpos" then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("CENTER")
            self:SaveDB()
            self:Print("Window position reset.")
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
    self:CreateMinimapButton()
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
