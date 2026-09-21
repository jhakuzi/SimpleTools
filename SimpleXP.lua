local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local UnitLevel = UnitLevel

function ST:GetPlayerXP()
    return self:PlainNumber(UnitXP("player")), self:PlainNumber(UnitXPMax("player"))
end

function ST:CreateSimpleXPUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local gainedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gainedLabel:SetPoint("TOP", 0, -6)
    gainedLabel:SetText("XP gained")

    self.xpGainedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.xpGainedDisplay:SetPoint("TOP", 0, -22)
    self.xpGainedDisplay:SetText("0")

    self.xpPerHourDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.xpPerHourDisplay:SetPoint("TOP", 0, -44)
    self.xpPerHourDisplay:SetText("XP/hr: 0")

    self.xpTimeToLevelDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.xpTimeToLevelDisplay:SetPoint("TOP", 0, -62)
    self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")

    self.xpRestedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.xpRestedDisplay:SetPoint("TOP", 0, -80)
    self.xpRestedDisplay:SetText("Rested: --")

    self.xpElapsedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.xpElapsedDisplay:SetPoint("TOP", 0, -96)
    self.xpElapsedDisplay:SetText("Elapsed: 00:00:00")

    self.xpProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.xpProjectButton:SetText("Send to screen")
    self.xpProjectButton:SetScript("OnClick", function()
        ST:ToggleXPProjected()
    end)

    self.xpStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.xpStartPauseButton:SetText("Start")
    self.xpStartPauseButton:SetScript("OnClick", function()
        ST:ToggleXPTracker()
    end)

    self.xpResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.xpResetButton:SetText("Reset")
    self.xpResetButton:SetScript("OnClick", function()
        ST:ResetXPTracker()
    end)

    self:LayoutTrackerButtons(frame, self.xpStartPauseButton, self.xpProjectButton, self.xpResetButton)

    return frame
end

function ST:ToggleXPTracker()
    if self.xp.running then
        self:PauseXPTracker()
    else
        self:StartXPTracker()
    end
end

function ST:StartXPTracker()
    local currentXP, maxXP = self:GetPlayerXP()
    if not currentXP or not maxXP then
        self:Print("XP values are unavailable (secret or missing). Rates cannot be calculated.")
        return
    end
    self.xp.anchor = GetTime()
    self.xp.startValue = currentXP
    self.xp.maxAtStart = maxXP
    self.xp.running = true
    self.xpStartPauseButton:SetText("Pause")
    self:SaveDB()
    self:RefreshTicker()
end

function ST:PauseXPTracker()
    if not self.xp.running then
        return
    end
    self.xp.elapsed = self.xp.elapsed + (GetTime() - self.xp.anchor)
    self.xp.running = false
    self.xpStartPauseButton:SetText("Resume")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateXPTracker()
end

function ST:ResetXPTracker()
    local wasRunning = self.xp.running
    self.xp.running = false
    self.xp.elapsed = 0
    self.xp.anchor = 0
    self.xp.startValue = 0
    self.xp.maxAtStart = 0
    self.xp.gained = 0
    self.xpGainedDisplay:SetText("0")
    self.xpPerHourDisplay:SetText("XP/hr: 0")
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
        self:SaveDB()
        self:RefreshTicker()
    end
end

function ST:OnXPUpdate()
    if not self.xp.running then
        return
    end
    local currentXP, maxXP = self:GetPlayerXP()
    if not currentXP or not maxXP then
        return
    end

    if currentXP < self.xp.startValue or maxXP > self.xp.maxAtStart then
        self.xp.gained = self.xp.gained + (self.xp.maxAtStart - self.xp.startValue) + currentXP
    else
        self.xp.gained = self.xp.gained + (currentXP - self.xp.startValue)
    end
    self.xp.startValue = currentXP
    self.xp.maxAtStart = maxXP
    self.xpGainedDisplay:SetText(tostring(self.xp.gained))
    if self.xpProjectedFrame then
        self.xpProjGained:SetText("Gained: " .. tostring(self.xp.gained))
    end
    self:UpdateXPTracker()
end

function ST:XPElapsed()
    local elapsed = self.xp.elapsed
    if self.xp.running then
        elapsed = elapsed + (GetTime() - self.xp.anchor)
    end
    return elapsed
end

function ST:UpdateXPTracker()
    if not self.xpElapsedDisplay then
        return
    end

    local elapsed = self:XPElapsed()
    local elapsedText = "Elapsed: " .. self:FormatElapsedTime(elapsed)
    self.xpElapsedDisplay:SetText(elapsedText)
    if self.xpProjectedFrame then
        self.xpProjElapsed:SetText(elapsedText)
    end

    local rested = self:PlainNumber(GetXPExhaustion and GetXPExhaustion())
    if self.xpRestedDisplay then
        if rested and rested > 0 then
            self.xpRestedDisplay:SetText("Rested: " .. tostring(rested))
        else
            self.xpRestedDisplay:SetText("Rested: none")
        end
    end

    local level = self:PlainNumber(UnitLevel("player"))
    local maxLevel = self:PlainNumber(GetMaxPlayerLevel and GetMaxPlayerLevel())
    if level and maxLevel and level >= maxLevel then
        self.xpTimeToLevelDisplay:SetText("TTL: max level")
        if self.xpProjectedFrame then
            self.xpProjTTL:SetText("TTL: max level")
        end
        self.xpPerHourDisplay:SetText("XP/hr: 0")
        if self.xpProjectedFrame then
            self.xpProjPerHour:SetText("XP/hr: 0")
        end
        return
    end

    if elapsed > 0 then
        local xpPerHour = math.floor((self.xp.gained / elapsed) * 3600)
        self.xpPerHourDisplay:SetText("XP/hr: " .. tostring(xpPerHour))
        if self.xpProjectedFrame then
            self.xpProjPerHour:SetText("XP/hr: " .. tostring(xpPerHour))
        end
        if xpPerHour > 0 then
            local currentXP, maxXP = self:GetPlayerXP()
            if currentXP and maxXP then
                local xpNeeded = maxXP - currentXP
                if xpNeeded > 0 then
                    local ttl = self:FormatElapsedTime((xpNeeded / xpPerHour) * 3600)
                    self.xpTimeToLevelDisplay:SetText("TTL: " .. ttl)
                    if self.xpProjectedFrame then
                        self.xpProjTTL:SetText("TTL: " .. ttl)
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
            self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")
            if self.xpProjectedFrame then
                self.xpProjTTL:SetText("TTL: --:--:--")
            end
        end
    else
        self.xpPerHourDisplay:SetText("XP/hr: 0")
        self.xpTimeToLevelDisplay:SetText("TTL: --:--:--")
        if self.xpProjectedFrame then
            self.xpProjPerHour:SetText("XP/hr: 0")
            self.xpProjTTL:SetText("TTL: --:--:--")
        end
    end
end

function ST:CreateXPProjectedFrame()
    local frame = CreateFrame("Frame", "SimpleXPProjectedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(140, 78)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(selfObj)
        selfObj:StopMovingOrSizing()
        ST:SaveDB()
    end)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.45)
        frame:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.6)
    end

    self.xpProjGained = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjGained:SetPoint("TOP", 0, -8)
    self.xpProjGained:SetText("Gained: 0")

    self.xpProjPerHour = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjPerHour:SetPoint("TOP", 0, -24)
    self.xpProjPerHour:SetText("XP/hr: 0")

    self.xpProjTTL = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjTTL:SetPoint("TOP", 0, -40)
    self.xpProjTTL:SetText("TTL: --:--:--")

    self.xpProjElapsed = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.xpProjElapsed:SetPoint("TOP", 0, -56)
    self.xpProjElapsed:SetText("Elapsed: 00:00:00")

    frame:SetScript("OnEnter", function(selfObj)
        GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
        GameTooltip:SetText("XP Tracker")
        GameTooltip:AddLine("Drag to move. Hidden overlays keep running.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)

    frame:Hide()
    self.xpProjectedFrame = frame
end

function ST:ShowXPProjected(show, pos)
    if not self.xpProjectedFrame then
        self:CreateXPProjectedFrame()
    end
    if show then
        if pos and pos.projPoint then
            self.xpProjectedFrame:ClearAllPoints()
            self.xpProjectedFrame:SetPoint(pos.projPoint, UIParent, pos.projRelativePoint or "CENTER", pos.projX or 0, pos.projY or 0)
        end
        self.xpProjectedFrame:Show()
        self.xpProjectButton:SetText("Unproject")
        self.xp.projected = true
        self:UpdateXPTracker()
        self.xpProjGained:SetText("Gained: " .. tostring(self.xp.gained))
    else
        self.xpProjectedFrame:Hide()
        self.xpProjectButton:SetText("Send to screen")
        self.xp.projected = false
    end
end

function ST:ToggleXPProjected()
    self:ShowXPProjected(not (self.xpProjectedFrame and self.xpProjectedFrame:IsShown()))
    self:SaveDB()
end
