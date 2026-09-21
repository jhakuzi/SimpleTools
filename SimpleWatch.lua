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
    self.swStartPauseButton:SetText("Start")
    self.swStartPauseButton:SetScript("OnClick", function()
        ST:ToggleStopwatch()
    end)

    self.swProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.swProjectButton:SetText("Send to screen")
    self.swProjectButton:SetScript("OnClick", function()
        ST:ToggleWatchProjected()
    end)

    self.swResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.swResetButton:SetText("Reset")
    self.swResetButton:SetScript("OnClick", function()
        ST:ResetStopwatch()
    end)

    self:LayoutTrackerButtons(frame, self.swStartPauseButton, self.swProjectButton, self.swResetButton)

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
    local text = self:FormatTime(self:StopwatchElapsed())
    self.stopwatchDisplay:SetText(text)
    if self.watchProjTime then
        self.watchProjTime:SetText(text)
    end
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
    self.swStartPauseButton:SetText("Start")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateStopwatch()
end

function ST:ToggleStopwatch()
    if self.watch.running then
        self:PauseStopwatch()
    else
        self:StartStopwatch()
    end
end

function ST:CreateWatchProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleWatchProjectedFrame", 140, 52, 180, 60, "Stopwatch")
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    label:SetPoint("TOP", 0, -8)
    label:SetText("Stopwatch")
    self.watchProjTime = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.watchProjTime:SetPoint("TOP", 0, -22)
    self.watchProjTime:SetText("00:00")
    self.watchProjectedFrame = frame
end

function ST:ShowWatchProjected(show, pos)
    if not self.watchProjectedFrame then
        self:CreateWatchProjectedFrame()
    end
    if show then
        self:PlaceOverlay(self.watchProjectedFrame, pos)
        self.watchProjectedFrame:Show()
        if self.swProjectButton then
            self.swProjectButton:SetText("Unproject")
        end
        self.watch.projected = true
        self:UpdateStopwatch()
    else
        self.watchProjectedFrame:Hide()
        if self.swProjectButton then
            self.swProjectButton:SetText("Send to screen")
        end
        self.watch.projected = false
    end
end

function ST:ToggleWatchProjected()
    self:ShowWatchProjected(not (self.watchProjectedFrame and self.watchProjectedFrame:IsShown()))
    self:SaveDB()
end
