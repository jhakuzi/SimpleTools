local addonName, ST = ...
local CreateFrame = CreateFrame

function ST:GetLoggingState()
    if type(LoggingCombat) ~= "function" then return nil end
    local ok, enabled = pcall(LoggingCombat)
    if ok and type(enabled) == "boolean" then return enabled end
    return nil
end

function ST:IsLoggingVisible()
    return self.loggingProjected or (self.frame and self.frame:IsShown()
        and self.loggingFrame and self.loggingFrame:IsShown())
end

function ST:UpdateLoggingDisplay()
    local enabled = self:GetLoggingState()
    local status = enabled == nil and "Logging unavailable" or (enabled and "Logging: Running" or "Logging: Stopped")
    for _, label in ipairs({self.loggingStatus, self.loggingProjStatus}) do
        label:SetText(status)
        if enabled then label:SetTextColor(0.3, 1, 0.3)
        elseif enabled == nil then label:SetTextColor(1, 0.8, 0.3)
        else label:SetTextColor(0.8, 0.8, 0.8) end
    end
    for _, button in ipairs({self.loggingToggleButton, self.loggingProjButton}) do
        button:SetText(enabled and "Stop logging" or "Start logging")
        button:SetEnabled(enabled ~= nil)
    end
    if self.loggingAutoButton then
        self.loggingAutoButton:SetText(self.db and self.db.logging.autoStart and "Auto logging: On" or "Auto logging: Off")
    end
end

function ST:SetCombatLogging(enabled)
    local previous = self:GetLoggingState()
    if previous == nil then
        self:Print("Combat logging is unavailable on this client.")
        self:UpdateLoggingDisplay()
        return false
    end
    if previous == enabled then
        self:UpdateLoggingDisplay()
        return true
    end
    local ok = pcall(LoggingCombat, enabled)
    local current = self:GetLoggingState()
    self:UpdateLoggingDisplay()
    if not ok or current ~= enabled then
        self:Print("Unable to change combat logging. Try /combatlog.")
        return false
    end
    self:Print(current and "Combat logging started." or "Combat logging stopped.")
    return true
end

function ST:ToggleCombatLogging()
    return self:SetCombatLogging(not self:GetLoggingState())
end

function ST:AutoStartCombatLogging()
    if not self.db or not self.db.logging.autoStart or type(IsInInstance) ~= "function" then return false end
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then return false end
    return self:SetCombatLogging(true)
end

function ST:ToggleAutoCombatLogging()
    self.db.logging.autoStart = not self.db.logging.autoStart
    self:SaveDB()
    self:UpdateLoggingDisplay()
    if self.db.logging.autoStart then self:AutoStartCombatLogging() end
end

function ST:CreateLoggingProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleToolsLoggingOverlay", 198, 80, 0, -240, "Combat logging", function()
        ST:ShowLoggingProjected(false)
    end)
    frame.overlayHint = "Drag to move. Start/stop controls WoW's combat log. Closing this overlay does not stop logging."
    self.loggingProjStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.loggingProjStatus:SetPoint("TOP", 0, -12)
    self.loggingProjButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.loggingProjButton:SetSize(112, 22)
    self.loggingProjButton:SetPoint("BOTTOM", 0, 10)
    self.loggingProjButton:SetScript("OnClick", function() ST:ToggleCombatLogging() end)
    self.loggingProjectedFrame = frame
end

function ST:ShowLoggingProjected(show, pos)
    if not self.loggingProjectedFrame and show then self:CreateLoggingProjectedFrame() end
    self.loggingProjected = show == true
    if self.loggingProjectedFrame then
        if show then self:PlaceOverlay(self.loggingProjectedFrame, pos) end
        self.loggingProjectedFrame:SetShown(self.loggingProjected)
    end
    if self.loggingProjectButton then
        self.loggingProjectButton:SetText(show and "Unproject" or "Send to screen")
    end
    self:UpdateLoggingDisplay()
    self:SaveDB()
    self:RefreshTicker()
end

function ST:CreateLoggingUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.loggingFrame = frame
    self.loggingStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.loggingStatus:SetPoint("TOP", 0, -8)
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 16, -38)
    hint:SetPoint("TOPRIGHT", -16, -38)
    hint:SetJustifyH("CENTER")
    hint:SetText("Auto logging starts on entering a dungeon or raid. Stop logging manually.\nHiding the window or overlay does not stop logging.\nManage log files in WoW's Logs folder outside the addon.")
    self.loggingToggleButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.loggingToggleButton:SetScript("OnClick", function() ST:ToggleCombatLogging() end)
    self.loggingProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.loggingProjectButton:SetText("Send to screen")
    self.loggingProjectButton:SetScript("OnClick", function() ST:ShowLoggingProjected(not ST.loggingProjected) end)
    self.loggingAutoButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.loggingAutoButton:SetScript("OnClick", function() ST:ToggleAutoCombatLogging() end)
    self:LayoutTrackerButtons(frame, self.loggingToggleButton, self.loggingProjectButton, self.loggingAutoButton)
    local function refresh()
        ST:UpdateLoggingDisplay()
        ST:RefreshTicker()
    end
    frame:SetScript("OnShow", refresh)
    frame:SetScript("OnHide", function() ST:RefreshTicker() end)
    self.frame:HookScript("OnShow", refresh)
    self.frame:HookScript("OnHide", function() ST:RefreshTicker() end)
    self:UpdateLoggingDisplay()
    return frame
end
