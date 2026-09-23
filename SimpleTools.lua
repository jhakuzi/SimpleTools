local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame

local TABS = {
    { key = "time",    label = "Time",     width = 56 },
    { key = "xp",      label = "XP/Gold",  width = 72 },
    { key = "gather",  label = "Gather",   width = 62 },
    { key = "notepad", label = "Notepad",  width = 70 },
    { key = "shop",    label = "Shop",     width = 50 },
    { key = "ping",    label = "Ping",     width = 48 },
}

function ST:CreateMainFrame()
    local frame = self:CreateThemedPanel("SimpleToolsFrame")
    self.frame = frame
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
    self.tabButtons = {}
    self.tabFrames = {}

    for i, tab in ipairs(TABS) do
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        btn.naturalWidth = tab.width
        btn:SetSize(tab.width, 18)
        if btn.SetNormalFontObject then
            btn:SetNormalFontObject("GameFontNormalSmall")
        end
        if btn.Text and btn.Text.SetFontObject then
            btn.Text:SetFontObject("GameFontNormalSmall")
        end
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

    self.tabFrames[1] = self:CreateTimeTab(self.contentFrame)
    self.tabFrames[2] = self:CreateXPGoldTab(self.contentFrame)
    self.tabFrames[3] = self:CreateSimpleGatherUI(self.contentFrame)
    self.tabFrames[4] = self:CreateSimpleNotepadUI(self.contentFrame)
    self.tabFrames[5] = self:CreateSimpleShopUI(self.contentFrame)
    self.tabFrames[6] = self:CreateSimplePingUI(self.contentFrame)

    self.timerFrame = self.tabFrames[1]
    self.simpleXPFrame = self.tabFrames[2]
    self.simpleGatherFrame = self.tabFrames[3]
    self.simpleNotepadFrame = self.tabFrames[4]
    self.shopFrame = self.tabFrames[5]
    self.pingFrame = self.tabFrames[6]

    self:SelectTab(1)
    frame:Hide()
end

function ST:LayoutTabButtons()
    local frame = self.frame
    local buttons = self.tabButtons
    if not frame or not buttons or #buttons == 0 then
        return
    end
    local frameWidth = frame:GetWidth() or ST.FRAME_W
    local inner = math.max(200, frameWidth - 32)
    local gap, height, rowGap, top = 2, 18, 3, 30
    local minW = 48
    local n = #buttons
    local natural, total = {}, 0
    for i, btn in ipairs(buttons) do
        natural[i] = btn.naturalWidth or 50
        total = total + natural[i]
        if i > 1 then
            total = total + gap
        end
    end
    local minTotal = n * minW + math.max(0, n - 1) * gap
    local rows = 1
    local y = -top

    if total <= inner or minTotal <= inner then
        local usable = math.min(inner, math.max(total, minTotal))
        if total > inner then
            usable = inner
        end
        local textWidth = total - math.max(0, n - 1) * gap
        local scale = 1
        if textWidth > 0 then
            scale = (usable - math.max(0, n - 1) * gap) / textWidth
        end
        local widths, used = {}, 0
        for i = 1, n do
            local w = math.max(minW, math.floor(natural[i] * scale + 0.5))
            widths[i] = w
            used = used + w
        end
        used = used + math.max(0, n - 1) * gap
        if used > usable and n > 0 then
            widths[n] = math.max(minW, widths[n] - (used - usable))
            used = usable
        end
        local x = (frameWidth - used) / 2
        for i, btn in ipairs(buttons) do
            btn:SetSize(widths[i], height)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
            x = x + widths[i] + gap
        end
        rows = 1
    else
        local i = 1
        rows = 0
        while i <= n do
            local rowWidth, count = 0, 0
            for j = i, n do
                local w = math.max(minW, natural[j])
                local nextWidth = count == 0 and w or (rowWidth + gap + w)
                if count > 0 and nextWidth > inner then
                    break
                end
                rowWidth = nextWidth
                count = count + 1
            end
            if count < 1 then
                count = 1
                rowWidth = math.max(minW, natural[i])
            end
            local x = (frameWidth - rowWidth) / 2
            for k = 0, count - 1 do
                local btn = buttons[i + k]
                local w = math.max(minW, natural[i + k])
                btn:SetSize(w, height)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
                x = x + w + gap
            end
            i = i + count
            rows = rows + 1
            y = y - height - rowGap
        end
    end
    if self.contentFrame then
        local inset = top + rows * (height + rowGap) + 2
        self.contentFrame:ClearAllPoints()
        self.contentFrame:SetPoint("TOPLEFT", 10, -inset)
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

    local durationLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    durationLabel:SetPoint("TOP", 0, -18)
    durationLabel:SetText("Duration (min)")

    self.durationInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.durationInput:SetSize(44, 18)
    self.durationInput:SetPoint("TOP", durationLabel, "BOTTOM", 0, -2)
    self.durationInput:SetAutoFocus(false)
    self.durationInput:SetNumeric(true)
    self.durationInput:SetMaxLetters(4)
    local defaultDuration = 10
    if self.db and self.db.options and self.db.options.defaultDuration then
        defaultDuration = self.db.options.defaultDuration
    end
    self.durationInput:SetText(tostring(defaultDuration))

    self.timerDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.timerDisplay:SetPoint("TOP", self.durationInput, "BOTTOM", 0, -8)
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
            self:OpenSettings()
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
