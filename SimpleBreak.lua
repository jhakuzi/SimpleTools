local addonName, ST = ...
local CreateFrame = CreateFrame
local GetTime = GetTime

local function Minutes(value, fallback)
    local number = tonumber(value)
    if not number or number ~= number or number < 1 or number > 240 or number ~= math.floor(number) then return fallback end
    return math.floor(number)
end

function ST:BreakRemaining()
    local timer = self.breakTimer
    return math.max(0, timer.remaining - (timer.running and (GetTime() - timer.anchor) or 0))
end

function ST:LoadBreakState(saved)
    local timer = self.breakTimer
    timer.interval = Minutes(saved.interval, 60)
    timer.snooze = Minutes(saved.snooze, 5)
    local remaining = tonumber(saved.remaining)
    timer.remaining = remaining and remaining >= 0 and remaining <= 240 * 60 and remaining or 0
    timer.due = saved.due == true
    timer.running = saved.running == true and not timer.due
    timer.anchor = GetTime()
    if self.breakIntervalInput then self.breakIntervalInput:SetText(tostring(timer.interval)) end
    if self.breakSnoozeInput then self.breakSnoozeInput:SetText(tostring(timer.snooze)) end
    self:UpdateBreakDisplay()
    if timer.due then self:ShowBreakAlert() end
end

function ST:StartBreakReminder(snooze)
    local timer = self.breakTimer
    local interval = Minutes(self.breakIntervalInput and self.breakIntervalInput:GetText() or timer.interval)
    local delay = Minutes(self.breakSnoozeInput and self.breakSnoozeInput:GetText() or timer.snooze)
    if not interval or not delay then
        self:Print("Enter whole minutes from 1 to 240 for the break interval and snooze.")
        if self.breakStatus then self.breakStatus:SetText("Enter 1–240 minutes for interval and snooze.") end
        return false
    end
    -- Resume a paused countdown unless its interval was changed.
    local remaining = self:BreakRemaining()
    if snooze then
        remaining = delay * 60
    elseif timer.due or remaining <= 0 or interval ~= timer.interval then
        remaining = interval * 60
    end
    timer.interval, timer.snooze = interval, delay
    timer.remaining, timer.anchor = remaining, GetTime()
    timer.running, timer.due = true, false
    if self.breakAlertFrame then self.breakAlertFrame:Hide() end
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateBreakDisplay()
    return true
end

function ST:ToggleBreakReminder()
    local timer = self.breakTimer
    if timer.running then
        timer.remaining = self:BreakRemaining()
        timer.running = false
        self:SaveDB()
        self:RefreshTicker()
        self:UpdateBreakDisplay()
    else
        self:StartBreakReminder()
    end
end

function ST:StopBreakReminder()
    local timer = self.breakTimer
    timer.running, timer.due, timer.remaining = false, false, 0
    if self.breakAlertFrame then self.breakAlertFrame:Hide() end
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateBreakDisplay()
end

function ST:CheckBreakReminder()
    local timer = self.breakTimer
    if timer.running and self:BreakRemaining() <= 0 then
        timer.remaining, timer.running, timer.due = 0, false, true
        self:ShowBreakAlert()
        self:PlayAlert()
        self:Print("Time for a break! Stretch, rest your eyes, or grab some water.")
        self:SaveDB()
        self:RefreshTicker()
    end
    self:UpdateBreakDisplay()
end

function ST:UpdateBreakDisplay()
    if not self.breakStatus then return end
    local timer = self.breakTimer
    local remaining = self:BreakRemaining()
    local status = "Choose an interval and press Start."
    if timer.due then
        status = "Time for a break! Snooze, or start the next interval."
    elseif timer.running then
        status = "Next break in " .. self:FormatTime(remaining)
    elseif remaining > 0 then
        status = "Paused · " .. self:FormatTime(remaining) .. " remaining"
    end
    self.breakStatus:SetText(status)
    self.breakStartButton:SetText(timer.running and "Pause" or (timer.due and "Next break" or (remaining > 0 and "Resume" or "Start")))
    self.breakSnoozeButton:SetEnabled(timer.due)
    self.breakStopButton:SetEnabled(timer.running or timer.due or remaining > 0)
end

function ST:ShowBreakAlert()
    if not self.breakAlertFrame then
        local frame = self:CreateOverlayFrame("SimpleToolsBreakAlert", 300, 108, 0, 80, "Break reminder", function()
            ST:StopBreakReminder()
        end)
        local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        heading:SetPoint("TOP", 0, -10)
        heading:SetText("Time for a break")
        local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOP", 0, -34)
        hint:SetText("Stretch, rest your eyes, or grab some water.")
        local snooze = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        snooze:SetText("Snooze")
        snooze:SetScript("OnClick", function() ST:StartBreakReminder(true) end)
        local nextBreak = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        nextBreak:SetText("Next break")
        nextBreak:SetScript("OnClick", function() ST:StartBreakReminder() end)
        self:LayoutBottomPair(frame, snooze, nextBreak)
        self.breakAlertFrame = frame
    end
    self.breakAlertFrame:Show()
end

function ST:CreateBreakUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local function input(label, x, value)
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("TOP", x, -8)
        text:SetText(label)
        local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        edit:SetSize(52, 20)
        edit:SetPoint("TOP", text, "BOTTOM", 0, -6)
        edit:SetAutoFocus(false)
        edit:SetNumeric(true)
        edit:SetMaxLetters(3)
        edit:SetText(tostring(value))
        edit:SetScript("OnEnterPressed", function(selfBox) selfBox:ClearFocus() end)
        edit:SetScript("OnEscapePressed", function(selfBox) selfBox:ClearFocus() end)
        return edit
    end
    self.breakIntervalInput = input("Every (minutes)", -85, 60)
    self.breakSnoozeInput = input("Snooze (minutes)", 85, 5)
    self.breakStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.breakStatus:SetPoint("TOPLEFT", 8, -64)
    self.breakStatus:SetPoint("TOPRIGHT", -8, -64)
    self.breakStatus:SetJustifyH("CENTER")
    self.breakStartButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.breakStartButton:SetScript("OnClick", function() ST:ToggleBreakReminder() end)
    self.breakSnoozeButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.breakSnoozeButton:SetText("Snooze")
    self.breakSnoozeButton:SetScript("OnClick", function() ST:StartBreakReminder(true) end)
    self.breakStopButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.breakStopButton:SetText("Stop")
    self.breakStopButton:SetScript("OnClick", function() ST:StopBreakReminder() end)
    self:LayoutTrackerButtons(frame, self.breakStartButton, self.breakSnoozeButton, self.breakStopButton)
    self:UpdateBreakDisplay()
    return frame
end
