local addonName, SimpleTools = ...

-- Localize WoW API for performance
local GetTime = GetTime
local CreateFrame = CreateFrame

-- Stopwatch variables
SimpleTools.stopwatchRunning = false
SimpleTools.stopwatchStartTime = 0
SimpleTools.stopwatchElapsedAtPause = 0

-- Create the Stopwatch UI
function SimpleTools:CreateSimpleWatchUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    
    self.stopwatchFrame = frame

    -- Stopwatch display
    self.stopwatchDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.stopwatchDisplay:SetPoint("CENTER", 0, 10)
    self.stopwatchDisplay:SetText("00:00")

    -- Start/Pause button
    self.swStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.swStartPauseButton:SetSize(80, 25)
    self.swStartPauseButton:SetPoint("BOTTOMLEFT", 10, 10)
    self.swStartPauseButton:SetText("Start")
    self.swStartPauseButton:SetScript("OnClick", function() SimpleTools:ToggleStopwatch() end)

    -- Reset button
    self.swResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.swResetButton:SetSize(80, 25)
    self.swResetButton:SetPoint("BOTTOMRIGHT", -10, 10)
    self.swResetButton:SetText("Reset")
    self.swResetButton:SetScript("OnClick", function() SimpleTools:ResetStopwatch() end)

    return frame
end

-- Update stopwatch display
function SimpleTools:UpdateStopwatch()
    if self.stopwatchRunning then
        local currentTime = GetTime()
        local totalElapsed = (currentTime - self.stopwatchStartTime) + self.stopwatchElapsedAtPause
        self.stopwatchDisplay:SetText(self:FormatTime(totalElapsed))
    end
end

-- Start the stopwatch
function SimpleTools:StartStopwatch()
    self.stopwatchStartTime = GetTime()
    self.stopwatchRunning = true
    self.swStartPauseButton:SetText("Pause")
    SimpleTools:SaveVariables()
end

-- Pause the stopwatch
function SimpleTools:PauseStopwatch()
    if self.stopwatchRunning then
        local currentTime = GetTime()
        self.stopwatchElapsedAtPause = (currentTime - self.stopwatchStartTime) + self.stopwatchElapsedAtPause
        self.stopwatchRunning = false
        self.swStartPauseButton:SetText("Resume")
        SimpleTools:SaveVariables()
    end
end

-- Reset the stopwatch
function SimpleTools:ResetStopwatch()
    self.stopwatchRunning = false
    self.stopwatchStartTime = 0
    self.stopwatchElapsedAtPause = 0
    self.stopwatchDisplay:SetText("00:00")
    self.swStartPauseButton:SetText("Start")
    SimpleTools:SaveVariables()
end

-- Toggle stopwatch
function SimpleTools:ToggleStopwatch()
    if self.stopwatchRunning then
        self:PauseStopwatch()
    else
        self:StartStopwatch()
    end
end
