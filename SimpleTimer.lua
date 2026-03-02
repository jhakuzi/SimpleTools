local addonName, SimpleTimer = ...

-- Localize WoW API for performance
local GetTime = GetTime
local CreateFrame = CreateFrame

-- Timer variables
SimpleTimer.remainingTime = 0
SimpleTimer.totalTime = 0
SimpleTimer.isRunning = false
SimpleTimer.startTime = 0

function SimpleTimer:SaveVariables()
    SimpleTimerDB = SimpleTimerDB or {}
    SimpleTimerDB.timer = {
        remainingTime = self.remainingTime,
        totalTime = self.totalTime,
        isRunning = self.isRunning,
        startTime = self.startTime
    }
    
    -- We also need to save watch and reminder state, but they are in this table's fields
    SimpleTimerDB.watch = {
        running = self.stopwatchRunning,
        startTime = self.stopwatchStartTime,
        elapsedAtPause = self.stopwatchElapsedAtPause
    }
    
    SimpleTimerDB.reminder = {
        time = self.reminderTime,
        set = self.reminderSet
    }
    
    local projPoint, projRelativePoint, projX, projY
    if self.xpProjectedFrame then
        projPoint, _, projRelativePoint, projX, projY = self.xpProjectedFrame:GetPoint()
    elseif SimpleTimerDB and SimpleTimerDB.xp then
        projPoint = SimpleTimerDB.xp.projPoint
        projRelativePoint = SimpleTimerDB.xp.projRelativePoint
        projX = SimpleTimerDB.xp.projX
        projY = SimpleTimerDB.xp.projY
    end

    SimpleTimerDB.xp = {
        running = self.xpRunning,
        startTime = self.xpStartTime,
        elapsedAtPause = self.xpElapsedAtPause,
        startValue = self.xpStartValue,
        maxAtStart = self.xpMaxAtStart,
        gained = self.xpGained,
        projected = self.xpProjected,
        projPoint = projPoint,
        projRelativePoint = projRelativePoint,
        projX = projX,
        projY = projY
    }
end

function SimpleTimer:LoadVariables()
    if not SimpleTimerDB then return end
    
    -- Load Timer
    if SimpleTimerDB.timer then
        self.remainingTime = SimpleTimerDB.timer.remainingTime or 0
        self.totalTime = SimpleTimerDB.timer.totalTime or 0
        self.isRunning = SimpleTimerDB.timer.isRunning or false
        self.startTime = SimpleTimerDB.timer.startTime or 0
        
        if self.isRunning then
            self.startPauseButton:SetText("Pause")
        else
            if self.remainingTime > 0 and self.remainingTime < self.totalTime then
                 self.startPauseButton:SetText("Resume")
            else
                 self.startPauseButton:SetText("Start")
            end
        end
        self:UpdateDisplay()
    end
    
    -- Load Watch
    if SimpleTimerDB.watch then
        self.stopwatchRunning = SimpleTimerDB.watch.running or false
        self.stopwatchStartTime = SimpleTimerDB.watch.startTime or 0
        self.stopwatchElapsedAtPause = SimpleTimerDB.watch.elapsedAtPause or 0
        
        if self.stopwatchRunning then
            self.swStartPauseButton:SetText("Pause")
        elseif self.stopwatchElapsedAtPause > 0 then
             self.swStartPauseButton:SetText("Resume")
        end
        self:UpdateStopwatch()
    end
    
    -- Load Reminder
    if SimpleTimerDB.reminder then
        self.reminderTime = SimpleTimerDB.reminder.time
        self.reminderSet = SimpleTimerDB.reminder.set
        if self.reminderSet and self.reminderTime then
            self.reminderStatus:SetText("Alarm set for: " .. self.reminderTime)
        end
    end
    
    -- Load XP Tracker
    if SimpleTimerDB.xp then
        self.xpRunning = SimpleTimerDB.xp.running or false
        self.xpStartTime = SimpleTimerDB.xp.startTime or 0
        self.xpElapsedAtPause = SimpleTimerDB.xp.elapsedAtPause or 0
        self.xpStartValue = SimpleTimerDB.xp.startValue or 0
        self.xpMaxAtStart = SimpleTimerDB.xp.maxAtStart or 1
        self.xpGained = SimpleTimerDB.xp.gained or 0
        self.xpProjected = SimpleTimerDB.xp.projected or false
        
        if self.xpRunning then
            self.xpStartPauseButton:SetText("Pause")
        elseif self.xpElapsedAtPause > 0 then
            self.xpStartPauseButton:SetText("Resume")
        end
        self:UpdateXPTracker()
        self.xpGainedDisplay:SetText(tostring(self.xpGained))

        if self.xpProjected then
            self.xpProjected = false
            self:ToggleXPProjected()
            if self.xpProjectedFrame and SimpleTimerDB.xp.projPoint then
                self.xpProjectedFrame:ClearAllPoints()
                self.xpProjectedFrame:SetPoint(SimpleTimerDB.xp.projPoint, UIParent, SimpleTimerDB.xp.projRelativePoint, SimpleTimerDB.xp.projX, SimpleTimerDB.xp.projY)
            end
        end
    end
end

-- Create the main frame with tabs
function SimpleTimer:CreateMainFrame()
    -- Main frame
    self.frame = CreateFrame("Frame", "SimpleTimerFrame", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(350, 180)
    self.frame:SetPoint("CENTER")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    
    -- Title
    self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.frame.title:SetPoint("TOP", 0, -5)
    self.frame.title:SetText("Simple Timer")

    -- Tab 1: Timer
    self.tab1 = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    self.tab1:SetSize(80, 20)
    self.tab1:SetPoint("TOPLEFT", self.frame, "TOP", -170, -35)
    self.tab1:SetText("Timer")
    self.tab1:SetScript("OnClick", function() self:SelectTab(1) end)

    -- Tab 2: Stopwatch
    self.tab2 = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    self.tab2:SetSize(100, 20)
    self.tab2:SetPoint("LEFT", self.tab1, "RIGHT", 0, 0)
    self.tab2:SetText("Stopwatch")
    self.tab2:SetScript("OnClick", function() self:SelectTab(2) end)

    -- Tab 3: Reminder
    self.tab3 = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    self.tab3:SetSize(80, 20)
    self.tab3:SetPoint("LEFT", self.tab2, "RIGHT", 0, 0)
    self.tab3:SetText("Reminder")
    self.tab3:SetScript("OnClick", function() self:SelectTab(3) end)

    -- Tab 4: XP Tracker
    self.tab4 = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    self.tab4:SetSize(80, 20)
    self.tab4:SetPoint("LEFT", self.tab3, "RIGHT", 0, 0)
    self.tab4:SetText("XP")
    self.tab4:SetScript("OnClick", function() self:SelectTab(4) end)

    -- Content Container
    self.contentFrame = CreateFrame("Frame", nil, self.frame)
    self.contentFrame:SetPoint("TOPLEFT", 10, -60)
    self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)

    -- Create Views
    self.timerFrame = self:CreateTimerUI(self.contentFrame)
    self.simpleWatchFrame = self:CreateSimpleWatchUI(self.contentFrame)
    self.simpleReminderFrame = self:CreateSimpleReminderUI(self.contentFrame)
    self.simpleXPFrame = self:CreateSimpleXPUI(self.contentFrame)

    -- Initial Select
    self:SelectTab(1)

    -- Hide the frame initially
    self.frame:Hide()
end

function SimpleTimer:SelectTab(id)
    self.timerFrame:Hide()
    self.simpleWatchFrame:Hide()
    self.simpleReminderFrame:Hide()
    self.simpleXPFrame:Hide()
    
    self.tab1:Enable()
    self.tab2:Enable()
    self.tab3:Enable()
    self.tab4:Enable()

    if id == 1 then
        self.timerFrame:Show()
        self.tab1:Disable()
    elseif id == 2 then
        self.simpleWatchFrame:Show()
        self.tab2:Disable()
    elseif id == 3 then
        self.simpleReminderFrame:Show()
        self.tab3:Disable()
    else
        self.simpleXPFrame:Show()
        self.tab4:Disable()
    end
end

function SimpleTimer:CreateTimerUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    -- Duration input label
    local durationLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durationLabel:SetPoint("TOPLEFT", 10, -10)
    durationLabel:SetText("Duration (min):")

    -- Duration input box
    self.durationInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.durationInput:SetSize(50, 20)
    self.durationInput:SetPoint("TOPLEFT", 120, -5)
    self.durationInput:SetAutoFocus(false)
    self.durationInput:SetNumeric(true)
    self.durationInput:SetText("10") -- Default 10 minutes
    self.durationInput:SetMaxLetters(3)

    -- Timer display
    self.timerDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.timerDisplay:SetPoint("CENTER", 0, 10)
    self.timerDisplay:SetText("00:00")

    -- Start/Pause button
    self.startPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.startPauseButton:SetSize(80, 25)
    self.startPauseButton:SetPoint("BOTTOMLEFT", 10, 10)
    self.startPauseButton:SetText("Start")
    self.startPauseButton:SetScript("OnClick", function() SimpleTimer:ToggleTimer() end)

    -- Reset button
    self.resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.resetButton:SetSize(80, 25)
    self.resetButton:SetPoint("BOTTOMRIGHT", -10, 10)
    self.resetButton:SetText("Reset")
    self.resetButton:SetScript("OnClick", function() SimpleTimer:ResetTimer() end)

    return frame
end

-- Format time as MM:SS
function SimpleTimer:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

-- Update timer display
function SimpleTimer:UpdateDisplay()
    local displayTime = self.remainingTime
    if self.isRunning then
        local elapsed = GetTime() - self.startTime
        displayTime = math.max(0, self.remainingTime - elapsed)
    end

    if displayTime > 0 then
        self.timerDisplay:SetText(self:FormatTime(displayTime))
    else
        self.timerDisplay:SetText("00:00")
    end
end

-- Start the timer
function SimpleTimer:StartTimer()
    local duration = tonumber(self.durationInput:GetText())
    if not duration or duration <= 0 then
        print("SimpleTimer: Please enter a valid duration in minutes.")
        return
    end

    self.totalTime = duration * 60 -- Convert to seconds
    self.remainingTime = self.totalTime
    self.startTime = GetTime()
    self.isRunning = true
    self.startPauseButton:SetText("Pause")
    self:SaveVariables()
    self:UpdateDisplay()
end

-- Pause the timer
function SimpleTimer:PauseTimer()
    if self.isRunning then
        -- Calculate remaining time when paused
        local elapsed = GetTime() - self.startTime
        self.remainingTime = math.max(0, self.remainingTime - elapsed)
        self.isRunning = false
        self.startPauseButton:SetText("Resume")
        self:SaveVariables()
    end
end

-- Resume the timer
function SimpleTimer:ResumeTimer()
    if not self.isRunning and self.remainingTime > 0 then
        self.startTime = GetTime()
        self.isRunning = true
        self.startPauseButton:SetText("Pause")
        self:SaveVariables()
    end
end

-- Reset the timer
function SimpleTimer:ResetTimer()
    self.isRunning = false
    self.remainingTime = 0
    self.startTime = 0
    self.startPauseButton:SetText("Start")
    self:SaveVariables()
    self:UpdateDisplay()
end

-- Toggle timer (start/pause/resume)
function SimpleTimer:ToggleTimer()
    if not self.isRunning then
        if self.remainingTime > 0 then
            self:ResumeTimer()
        else
            self:StartTimer()
        end
    else
        self:PauseTimer()
    end
end

-- Update timer on each frame
function SimpleTimer:OnUpdate(elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed

    -- Only update once per 0.1s for smoother stopwatch, but timer logic can check every 1s
    if self.lastUpdate >= 0.1 then
        
        -- Timer Logic
        if self.isRunning then
             local elapsedTime = GetTime() - self.startTime
             local currentRemaining = math.max(0, self.remainingTime - elapsedTime)
             self:UpdateDisplay()
             
             if currentRemaining <= 0 then
                 self:TimerFinished()
             end
        end

        -- Stopwatch Logic
        if self.stopwatchRunning then
            self:UpdateStopwatch()
        end

        -- XP Tracker Logic
        if self.xpRunning then
            self:UpdateXPTracker()
        end

        -- Check Reminder
        self:CheckReminder()

        self.lastUpdate = 0
    end
end

-- Handle timer completion
function SimpleTimer:TimerFinished()
    self:ResetTimer()

    -- Play sound or show notification
    PlaySound(8960, "Master")

    -- You could add more notification options here
    print("SimpleTimer: Timer finished!")
end

-- Toggle the timer window
function SimpleTimer:ToggleWindow()
    self.frame:SetShown(not self.frame:IsShown())
end

-- Initialize the addon
function SimpleTimer:Initialize()
    self:CreateMainFrame()
    self:LoadVariables()

    -- Register slash commands
    SLASH_SIMPLETIMER1 = "/timer"
    SLASH_SIMPLETIMER2 = "/simpletimer"
    SlashCmdList["SIMPLETIMER"] = function() self:ToggleWindow() end

    -- Set up update handler
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)

    print("SimpleTimer loaded! Use /timer to toggle the timer window.")
end

-- Event handler
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == "SimpleTimer" then
        SimpleTimer:Initialize()
    end
end

-- Register events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
