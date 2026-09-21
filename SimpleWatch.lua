local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame

function ST:CreateSimpleWatchUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.stopwatchFrame = frame

    self.stopwatchDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.stopwatchDisplay:SetPoint("CENTER", 0, 10)
    self.stopwatchDisplay:SetText("00:00")

    self.swStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.swStartPauseButton:SetSize(80, 25)
    self.swStartPauseButton:SetPoint("BOTTOMLEFT", 10, 8)
    self.swStartPauseButton:SetText("Start")
    self.swStartPauseButton:SetScript("OnClick", function()
        ST:ToggleStopwatch()
    end)

    self.swResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.swResetButton:SetSize(80, 25)
    self.swResetButton:SetPoint("BOTTOMRIGHT", -10, 8)
    self.swResetButton:SetText("Reset")
    self.swResetButton:SetScript("OnClick", function()
        ST:ResetStopwatch()
    end)

    return frame
end

function ST:StopwatchElapsed()
    local elapsed = self.watch.elapsed
    if self.watch.running then
        elapsed = elapsed + (GetTime() - self.watch.anchor)
    end
    return elapsed
end

function ST:UpdateStopwatch()
    if not self.stopwatchDisplay then
        return
    end
    self.stopwatchDisplay:SetText(self:FormatTime(self:StopwatchElapsed()))
end

function ST:StartStopwatch()
    self.watch.anchor = GetTime()
    self.watch.running = true
    self.swStartPauseButton:SetText("Pause")
    self:SaveDB()
    self:RefreshTicker()
end

function ST:PauseStopwatch()
    if not self.watch.running then
        return
    end
    self.watch.elapsed = self:StopwatchElapsed()
    self.watch.running = false
    self.swStartPauseButton:SetText("Resume")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateStopwatch()
end

function ST:ResetStopwatch()
    self.watch.running = false
    self.watch.elapsed = 0
    self.watch.anchor = 0
    self.stopwatchDisplay:SetText("00:00")
    self.swStartPauseButton:SetText("Start")
    self:SaveDB()
    self:RefreshTicker()
end

function ST:ToggleStopwatch()
    if self.watch.running then
        self:PauseStopwatch()
    else
        self:StartStopwatch()
    end
end
