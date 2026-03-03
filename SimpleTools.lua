local addonName, SimpleTools = ...

-- Localize WoW API for performance
local GetTime = GetTime
local CreateFrame = CreateFrame

-- Timer variables
SimpleTools.remainingTime = 0
SimpleTools.totalTime = 0
SimpleTools.isRunning = false
SimpleTools.startTime = 0

function SimpleTools:SaveVariables()
    SimpleToolsDB = SimpleToolsDB or {}
    SimpleToolsDB.timer = {
        remainingTime = self.remainingTime,
        totalTime = self.totalTime,
        isRunning = self.isRunning,
        startTime = self.startTime
    }
    
    -- We also need to save watch and reminder state, but they are in this table's fields
    SimpleToolsDB.watch = {
        running = self.stopwatchRunning,
        startTime = self.stopwatchStartTime,
        elapsedAtPause = self.stopwatchElapsedAtPause
    }
    
    SimpleToolsDB.reminder = {
        time = self.reminderTime,
        set = self.reminderSet
    }
    
    local projPoint, projRelativePoint, projX, projY
    if self.xpProjectedFrame then
        projPoint, _, projRelativePoint, projX, projY = self.xpProjectedFrame:GetPoint()
    elseif SimpleToolsDB and SimpleToolsDB.xp then
        projPoint = SimpleToolsDB.xp.projPoint
        projRelativePoint = SimpleToolsDB.xp.projRelativePoint
        projX = SimpleToolsDB.xp.projX
        projY = SimpleToolsDB.xp.projY
    end

    SimpleToolsDB.xp = {
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

    local goldProjPoint, goldProjRelativePoint, goldProjX, goldProjY
    if self.goldProjectedFrame then
        goldProjPoint, _, goldProjRelativePoint, goldProjX, goldProjY = self.goldProjectedFrame:GetPoint()
    elseif SimpleToolsDB and SimpleToolsDB.gold then
        goldProjPoint = SimpleToolsDB.gold.projPoint
        goldProjRelativePoint = SimpleToolsDB.gold.projRelativePoint
        goldProjX = SimpleToolsDB.gold.projX
        goldProjY = SimpleToolsDB.gold.projY
    end

    SimpleToolsDB.gold = {
        running = self.goldRunning,
        startTime = self.goldStartTime,
        elapsedAtPause = self.goldElapsedAtPause,
        startValue = self.goldStartValue,
        gained = self.goldGained,
        projected = self.goldProjected,
        projPoint = goldProjPoint,
        projRelativePoint = goldProjRelativePoint,
        projX = goldProjX,
        projY = goldProjY
    }
end

function SimpleTools:LoadVariables()
    if not SimpleToolsDB then return end
    
    -- Load Timer
    if SimpleToolsDB.timer then
        self.remainingTime = SimpleToolsDB.timer.remainingTime or 0
        self.totalTime = SimpleToolsDB.timer.totalTime or 0
        self.isRunning = SimpleToolsDB.timer.isRunning or false
        self.startTime = SimpleToolsDB.timer.startTime or 0
        
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
    if SimpleToolsDB.watch then
        self.stopwatchRunning = SimpleToolsDB.watch.running or false
        self.stopwatchStartTime = SimpleToolsDB.watch.startTime or 0
        self.stopwatchElapsedAtPause = SimpleToolsDB.watch.elapsedAtPause or 0
        
        if self.stopwatchRunning then
            self.swStartPauseButton:SetText("Pause")
        elseif self.stopwatchElapsedAtPause > 0 then
             self.swStartPauseButton:SetText("Resume")
        end
        self:UpdateStopwatch()
    end
    
    -- Load Reminder
    if SimpleToolsDB.reminder then
        self.reminderTime = SimpleToolsDB.reminder.time
        self.reminderSet = SimpleToolsDB.reminder.set
        if self.reminderSet and self.reminderTime then
            self.reminderStatus:SetText("Alarm set for: " .. self.reminderTime)
        end
    end
    
    -- Load XP Tracker
    if SimpleToolsDB.xp then
        self.xpRunning = SimpleToolsDB.xp.running or false
        self.xpStartTime = SimpleToolsDB.xp.startTime or 0
        self.xpElapsedAtPause = SimpleToolsDB.xp.elapsedAtPause or 0
        self.xpStartValue = SimpleToolsDB.xp.startValue or 0
        self.xpMaxAtStart = SimpleToolsDB.xp.maxAtStart or 1
        self.xpGained = SimpleToolsDB.xp.gained or 0
        self.xpProjected = SimpleToolsDB.xp.projected or false
        
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
            if self.xpProjectedFrame and SimpleToolsDB.xp.projPoint then
                self.xpProjectedFrame:ClearAllPoints()
                self.xpProjectedFrame:SetPoint(SimpleToolsDB.xp.projPoint, UIParent, SimpleToolsDB.xp.projRelativePoint, SimpleToolsDB.xp.projX, SimpleToolsDB.xp.projY)
            end
        end
    end

    -- Load Gold Tracker
    if SimpleToolsDB.gold then
        self.goldRunning = SimpleToolsDB.gold.running or false
        self.goldStartTime = SimpleToolsDB.gold.startTime or 0
        self.goldElapsedAtPause = SimpleToolsDB.gold.elapsedAtPause or 0
        self.goldStartValue = SimpleToolsDB.gold.startValue or 0
        self.goldGained = SimpleToolsDB.gold.gained or 0
        self.goldProjected = SimpleToolsDB.gold.projected or false

        if self.goldRunning then
            self.goldStartPauseButton:SetText("Pause")
        elseif self.goldElapsedAtPause > 0 then
            self.goldStartPauseButton:SetText("Resume")
        end
        self:UpdateGoldTracker()

        if self.goldProjected then
            self.goldProjected = false
            self:ToggleGoldProjected()
            if self.goldProjectedFrame and SimpleToolsDB.gold.projPoint then
                self.goldProjectedFrame:ClearAllPoints()
                self.goldProjectedFrame:SetPoint(SimpleToolsDB.gold.projPoint, UIParent, SimpleToolsDB.gold.projRelativePoint, SimpleToolsDB.gold.projX, SimpleToolsDB.gold.projY)
            end
        end
    end
end

-- Create the main frame with tabs
function SimpleTools:CreateMainFrame()
    -- Main frame
    self.frame = CreateFrame("Frame", "SimpleToolsFrame", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(420, 180)
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
    self.tab1:SetPoint("TOPLEFT", self.frame, "TOP", -205, -35)
    self.tab1:SetText("Timer")
    self.tab1:SetScript("OnClick", function() self:SelectTab(1) end)

    -- Tab 2: Stopwatch
    self.tab2 = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    self.tab2:SetSize(90, 20)
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

    -- Tab 5: Gold Tracker
    self.tab5 = CreateFrame("Button", nil, self.frame, "GameMenuButtonTemplate")
    self.tab5:SetSize(80, 20)
    self.tab5:SetPoint("LEFT", self.tab4, "RIGHT", 0, 0)
    self.tab5:SetText("Gold")
    self.tab5:SetScript("OnClick", function() self:SelectTab(5) end)

    -- Content Container
    self.contentFrame = CreateFrame("Frame", nil, self.frame)
    self.contentFrame:SetPoint("TOPLEFT", 10, -60)
    self.contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)

    -- Create Views
    self.timerFrame = self:CreateTimerUI(self.contentFrame)
    self.simpleWatchFrame = self:CreateSimpleWatchUI(self.contentFrame)
    self.simpleReminderFrame = self:CreateSimpleReminderUI(self.contentFrame)
    self.simpleXPFrame = self:CreateSimpleXPUI(self.contentFrame)
    self.simpleGoldFrame = self:CreateSimpleGoldUI(self.contentFrame)

    -- Initial Select
    self:SelectTab(1)

    -- Hide the frame initially
    self.frame:Hide()
end

function SimpleTools:SelectTab(id)
    self.timerFrame:Hide()
    self.simpleWatchFrame:Hide()
    self.simpleReminderFrame:Hide()
    self.simpleXPFrame:Hide()
    self.simpleGoldFrame:Hide()
    
    self.tab1:Enable()
    self.tab2:Enable()
    self.tab3:Enable()
    self.tab4:Enable()
    self.tab5:Enable()

    if id == 1 then
        self.timerFrame:Show()
        self.tab1:Disable()
    elseif id == 2 then
        self.simpleWatchFrame:Show()
        self.tab2:Disable()
    elseif id == 3 then
        self.simpleReminderFrame:Show()
        self.tab3:Disable()
    elseif id == 4 then
        self.simpleXPFrame:Show()
        self.tab4:Disable()
    elseif id == 5 then
        self.simpleGoldFrame:Show()
        self.tab5:Disable()
    end
end

function SimpleTools:CreateTimerUI(parent)
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
    self.startPauseButton:SetScript("OnClick", function() SimpleTools:ToggleTimer() end)

    -- Reset button
    self.resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.resetButton:SetSize(80, 25)
    self.resetButton:SetPoint("BOTTOMRIGHT", -10, 10)
    self.resetButton:SetText("Reset")
    self.resetButton:SetScript("OnClick", function() SimpleTools:ResetTimer() end)

    return frame
end

-- Format time as MM:SS
function SimpleTools:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

-- Update timer display
function SimpleTools:UpdateDisplay()
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
function SimpleTools:StartTimer()
    local duration = tonumber(self.durationInput:GetText())
    if not duration or duration <= 0 then
        print("SimpleTools: Please enter a valid duration in minutes.")
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
function SimpleTools:PauseTimer()
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
function SimpleTools:ResumeTimer()
    if not self.isRunning and self.remainingTime > 0 then
        self.startTime = GetTime()
        self.isRunning = true
        self.startPauseButton:SetText("Pause")
        self:SaveVariables()
    end
end

-- Reset the timer
function SimpleTools:ResetTimer()
    self.isRunning = false
    self.remainingTime = 0
    self.startTime = 0
    self.startPauseButton:SetText("Start")
    self:SaveVariables()
    self:UpdateDisplay()
end

-- Toggle timer (start/pause/resume)
function SimpleTools:ToggleTimer()
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
function SimpleTools:OnUpdate(elapsed)
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

        -- Gold Tracker Logic
        if self.goldRunning then
            self:UpdateGoldTracker()
        end

        -- Check Reminder
        self:CheckReminder()

        self.lastUpdate = 0
    end
end

-- Handle timer completion
function SimpleTools:TimerFinished()
    self:ResetTimer()

    -- Play sound or show notification
    PlaySound(8960, "Master")

    -- You could add more notification options here
    print("SimpleTools: Timer finished!")
end

-- Toggle the timer window
function SimpleTools:ToggleWindow()
    self.frame:SetShown(not self.frame:IsShown())
end

-- Initialize the addon
function SimpleTools:Initialize()
    self:CreateMainFrame()
    self:LoadVariables()

    -- Register slash commands
    SLASH_SIMPLETOOLS1 = "/tools"
    SLASH_SIMPLETOOLS2 = "/simpletools"
    SlashCmdList["SIMPLETOOLS"] = function() self:ToggleWindow() end

    -- Set up update handler
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function(_, elapsed) self:OnUpdate(elapsed) end)

    print("SimpleTools loaded! Use /timer to toggle the timer window.")
end

-- Event handler
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == "SimpleTools" then
        SimpleTools:Initialize()
    end
end

-- Register events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
