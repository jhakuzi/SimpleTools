local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame

local TABS = {
    { key = "timer",    label = "Timer",     width = 70 },
    { key = "watch",    label = "Stopwatch", width = 86 },
    { key = "reminder", label = "Reminder",  width = 80 },
    { key = "xp",       label = "XP",        width = 50 },
    { key = "gold",     label = "Gold",      width = 54 },
    { key = "gather",   label = "Gather",    width = 62 },
    { key = "notepad",  label = "Notepad",   width = 70 },
    { key = "shop",     label = "Shop",      width = 50 },
}

function ST:CreateMainFrame()
    local frame = self:CreateThemedPanel("SimpleToolsFrame")
    frame:SetSize(580, 300)
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
    self:AttachResizeGrip(frame, 560, 260, 900, 640, function()
        ST:OnMainFrameSizeChanged()
    end)
    frame:SetScript("OnSizeChanged", function()
        ST:OnMainFrameSizeChanged()
        ST:ScheduleSave()
    end)

    self.frame = frame
    self.tabButtons = {}
    self.tabFrames = {}

    for i, tab in ipairs(TABS) do
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        btn:SetSize(tab.width, 20)
        btn:SetText(tab.label)
        btn:SetScript("OnClick", function()
            self:SelectTab(i)
        end)
        self.tabButtons[i] = btn
    end

    self.contentFrame = CreateFrame("Frame", nil, frame)
    self.contentFrame:SetPoint("TOPLEFT", 10, -56)
    self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
    self:LayoutTabButtons()

    self.tabFrames[1] = self:CreateTimerUI(self.contentFrame)
    self.tabFrames[2] = self:CreateSimpleWatchUI(self.contentFrame)
    self.tabFrames[3] = self:CreateSimpleReminderUI(self.contentFrame)
    self.tabFrames[4] = self:CreateSimpleXPUI(self.contentFrame)
    self.tabFrames[5] = self:CreateSimpleGoldUI(self.contentFrame)
    self.tabFrames[6] = self:CreateSimpleGatherUI(self.contentFrame)
    self.tabFrames[7] = self:CreateSimpleNotepadUI(self.contentFrame)
    self.tabFrames[8] = self:CreateSimpleShopUI(self.contentFrame)

    self.timerFrame = self.tabFrames[1]
    self.simpleWatchFrame = self.tabFrames[2]
    self.simpleReminderFrame = self.tabFrames[3]
    self.simpleXPFrame = self.tabFrames[4]
    self.simpleGoldFrame = self.tabFrames[5]
    self.simpleGatherFrame = self.tabFrames[6]
    self.simpleNotepadFrame = self.tabFrames[7]
    self.shopFrame = self.tabFrames[8]

    self:SelectTab(1)
    frame:Hide()
end

function ST:LayoutTabButtons()
    local frame = self.frame
    local buttons = self.tabButtons
    if not frame or not buttons or #buttons == 0 then
        return
    end
    local frameWidth = frame:GetWidth() or 580
    local inner = math.max(200, frameWidth - 24)
    local gap, height, rowGap, top = 2, 20, 4, 32
    local i, rows, y = 1, 0, -top
    while i <= #buttons do
        local rowWidth, count = 0, 0
        for j = i, #buttons do
            local w = buttons[j]:GetWidth() or 50
            local nextWidth = count == 0 and w or (rowWidth + gap + w)
            if count > 0 and nextWidth > inner then
                break
            end
            rowWidth = nextWidth
            count = count + 1
        end
        if count < 1 then
            count = 1
            rowWidth = buttons[i]:GetWidth() or 50
        end
        local x = (frameWidth - rowWidth) / 2
        for k = 0, count - 1 do
            local btn = buttons[i + k]
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
            x = x + (btn:GetWidth() or 50) + gap
        end
        i = i + count
        rows = rows + 1
        y = y - height - rowGap
    end
    if self.contentFrame then
        local inset = top + rows * (height + rowGap) + 2
        self.contentFrame:ClearAllPoints()
        self.contentFrame:SetPoint("TOPLEFT", 10, -inset)
        self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
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
    self.timerDisplay:SetPoint("CENTER", 0, 10)
    self.timerDisplay:SetText("00:00")

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

    self:LayoutTrackerButtons(frame, self.startPauseButton, self.timerProjectButton, self.resetButton)

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
            self:OpenSettings()
        elseif msg == "resetpos" then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("CENTER")
            self.frame:SetSize(580, 300)
            self:OnMainFrameSizeChanged()
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
