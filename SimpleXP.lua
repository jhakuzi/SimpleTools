local addonName, SimpleTools = ...

local GetTime = GetTime
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax

-- XP Tracker state
SimpleTools.xpRunning = false
SimpleTools.xpStartTime = 0
SimpleTools.xpElapsedAtPause = 0
SimpleTools.xpStartValue = 0
SimpleTools.xpMaxAtStart = 0
SimpleTools.xpGained = 0

function SimpleTools:CreateSimpleXPUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    -- XP Gained Display
    local gainedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gainedLabel:SetPoint("TOP", 0, -10)
    gainedLabel:SetText("XP Gained:")

    self.xpGainedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.xpGainedDisplay:SetPoint("TOP", 0, -25)
    self.xpGainedDisplay:SetText("0")

    -- XP/hr Display
    local xpPerHourLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpPerHourLabel:SetPoint("TOP", 0, -45)
    xpPerHourLabel:SetText("XP/hr:")

    self.xpPerHourDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.xpPerHourDisplay:SetPoint("TOP", 0, -60)
    self.xpPerHourDisplay:SetText("0")
    
    -- Time to level display
    self.xpTimeToLevelDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.xpTimeToLevelDisplay:SetPoint("TOP", 0, -80)
    self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")

    -- Elapsed Time Display
    self.xpElapsedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.xpElapsedDisplay:SetPoint("TOP", 0, -100)
    self.xpElapsedDisplay:SetText("Elapsed: 00:00:00")

    -- Project Button
    self.xpProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.xpProjectButton:SetSize(110, 25)
    self.xpProjectButton:SetPoint("BOTTOM", 0, 10)
    self.xpProjectButton:SetText("Send to screen")
    self.xpProjectButton:SetScript("OnClick", function() SimpleTools:ToggleXPProjected() end)

    -- Start/Pause Button
    self.xpStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.xpStartPauseButton:SetSize(80, 25)
    self.xpStartPauseButton:SetPoint("BOTTOMLEFT", 10, 10)
    self.xpStartPauseButton:SetText("Start")
    self.xpStartPauseButton:SetScript("OnClick", function() SimpleTools:ToggleXPTracker() end)

    -- Reset Button
    self.xpResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.xpResetButton:SetSize(80, 25)
    self.xpResetButton:SetPoint("BOTTOMRIGHT", -10, 10)
    self.xpResetButton:SetText("Reset")
    self.xpResetButton:SetScript("OnClick", function() SimpleTools:ResetXPTracker() end)

    -- Events
    frame:RegisterEvent("PLAYER_XP_UPDATE")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_XP_UPDATE" then
            SimpleTools:OnXPUpdate()
        end
    end)

    return frame
end

function SimpleTools:ToggleXPTracker()
    if self.xpRunning then
        self:PauseXPTracker()
    else
        self:StartXPTracker()
    end
end

function SimpleTools:StartXPTracker()
    if not self.xpRunning then
        self.xpStartTime = GetTime()
        self.xpStartValue = UnitXP("player") or 0
        self.xpMaxAtStart = UnitXPMax("player") or 1
        self.xpRunning = true
        self.xpStartPauseButton:SetText("Pause")
        self:SaveVariables()
    end
end

function SimpleTools:PauseXPTracker()
    if self.xpRunning then
        self.xpElapsedAtPause = self.xpElapsedAtPause + (GetTime() - self.xpStartTime)
        self.xpRunning = false
        self.xpStartPauseButton:SetText("Resume")
        self:SaveVariables()
    end
end

function SimpleTools:ResetXPTracker()
    local wasRunning = self.xpRunning
    self.xpRunning = false
    self.xpStartTime = 0
    self.xpElapsedAtPause = 0
    self.xpStartValue = 0
    self.xpMaxAtStart = 0
    self.xpGained = 0
    self.xpGainedDisplay:SetText("0")
    self.xpPerHourDisplay:SetText("0")
    self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")
    self.xpElapsedDisplay:SetText("Elapsed: 00:00:00")
    if self.xpProjectedFrame then
        self.xpProjGained:SetText("Gained: 0")
        self.xpProjPerHour:SetText("XP/hr: 0")
        self.xpProjTTL:SetText("TTL: --:--:--")
        self.xpProjElapsed:SetText("Elapsed: 00:00:00")
    end
    
    if wasRunning then
        self:StartXPTracker()
    else
        self.xpStartPauseButton:SetText("Start")
        self:SaveVariables()
    end
end

function SimpleTools:OnXPUpdate()
    if self.xpRunning then
        local currentXP = UnitXP("player") or 0
        local maxXP = UnitXPMax("player") or 1
        
        if currentXP < self.xpStartValue or maxXP > self.xpMaxAtStart then
            -- We probably leveled up
            self.xpGained = self.xpGained + (self.xpMaxAtStart - self.xpStartValue) + currentXP
        else
            self.xpGained = self.xpGained + (currentXP - self.xpStartValue)
        end
        
        self.xpStartValue = currentXP
        self.xpMaxAtStart = maxXP
        
        self.xpGainedDisplay:SetText(tostring(self.xpGained))
        if self.xpProjectedFrame then
            self.xpProjGained:SetText("Gained: " .. tostring(self.xpGained))
        end
        -- Save optionally, but skip frequently. Wait till close/pause.
    end
end

function SimpleTools:FormatElapsedTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function SimpleTools:UpdateXPTracker()
    local elapsed = self.xpElapsedAtPause
    if self.xpRunning then
        elapsed = elapsed + (GetTime() - self.xpStartTime)
    end
    
    self.xpElapsedDisplay:SetText("Elapsed: " .. self:FormatElapsedTime(math.floor(elapsed)))
    if self.xpProjectedFrame then
        self.xpProjElapsed:SetText("Elapsed: " .. self:FormatElapsedTime(math.floor(elapsed)))
    end
    
    if elapsed > 0 then
        local xpPerHour = math.floor((self.xpGained / elapsed) * 3600)
        self.xpPerHourDisplay:SetText(tostring(xpPerHour))
        if self.xpProjectedFrame then
            self.xpProjPerHour:SetText("XP/hr: " .. tostring(xpPerHour))
        end
        
        if xpPerHour > 0 then
            local currentXP = UnitXP("player") or 0
            local maxXP = UnitXPMax("player") or 1
            local xpNeeded = maxXP - currentXP
            if xpNeeded > 0 then
                local secondsToLevel = (xpNeeded / xpPerHour) * 3600
                self.xpTimeToLevelDisplay:SetText("TTL: " .. self:FormatElapsedTime(math.floor(secondsToLevel)))
                if self.xpProjectedFrame then
                    self.xpProjTTL:SetText("TTL: " .. self:FormatElapsedTime(math.floor(secondsToLevel)))
                end
            else
                self.xpTimeToLevelDisplay:SetText("TTL: 00:00:00")
                if self.xpProjectedFrame then
                    self.xpProjTTL:SetText("TTL: 00:00:00")
                end
            end
        else
            self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")
            if self.xpProjectedFrame then
                self.xpProjTTL:SetText("TTL: --:--:--")
            end
        end
    else
        self.xpPerHourDisplay:SetText("0")
        self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")
        if self.xpProjectedFrame then
            self.xpProjPerHour:SetText("XP/hr: 0")
            self.xpProjTTL:SetText("TTL: --:--:--")
        end
    end
end

function SimpleTools:CreateXPProjectedFrame()
    local frame = CreateFrame("Frame", "SimpleXPProjectedFrame", UIParent)
    frame:SetSize(120, 70)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(selfObj)
        selfObj:StopMovingOrSizing()
        SimpleTools:SaveVariables()
    end)
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)

    self.xpProjGained = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjGained:SetPoint("TOP", 0, -5)
    self.xpProjGained:SetText("Gained: 0")

    self.xpProjPerHour = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjPerHour:SetPoint("TOP", 0, -20)
    self.xpProjPerHour:SetText("XP/hr: 0")

    self.xpProjTTL = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjTTL:SetPoint("TOP", 0, -35)
    self.xpProjTTL:SetText("TTL: --:--:--")
    
    self.xpProjElapsed = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjElapsed:SetPoint("TOP", 0, -50)
    self.xpProjElapsed:SetText("Elapsed: 00:00:00")

    frame:SetScript("OnEnter", function(selfObj)
        GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
        GameTooltip:SetText("XP Tracker (Projected)")
        GameTooltip:AddLine("Left-click and drag to move", 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(selfObj)
        GameTooltip:Hide()
    end)

    frame:Hide()
    self.xpProjectedFrame = frame
end

function SimpleTools:ToggleXPProjected()
    if not self.xpProjectedFrame then
        self:CreateXPProjectedFrame()
    end

    if self.xpProjectedFrame:IsShown() then
        self.xpProjectedFrame:Hide()
        self.xpProjectButton:SetText("Send to screen")
        self.xpProjected = false
    else
        self.xpProjectedFrame:Show()
        self.xpProjectButton:SetText("Unproject")
        self.xpProjected = true
        self:UpdateXPTracker()
        self.xpProjGained:SetText("Gained: " .. tostring(self.xpGained))
    end
    self:SaveVariables()
end
