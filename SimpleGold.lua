local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame
local GetMoney = GetMoney

function ST:CreateSimpleGoldUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local gainedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gainedLabel:SetPoint("TOP", 0, -8)
    gainedLabel:SetText("Gold gained")

    self.goldGainedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.goldGainedDisplay:SetPoint("TOP", 0, -24)
    self.goldGainedDisplay:SetText("0c")

    self.goldPerHourDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.goldPerHourDisplay:SetPoint("TOP", 0, -48)
    self.goldPerHourDisplay:SetText("Gold/hr: 0c")

    self.goldElapsedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.goldElapsedDisplay:SetPoint("TOP", 0, -72)
    self.goldElapsedDisplay:SetText("Elapsed: 00:00:00")

    self.goldProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.goldProjectButton:SetText("Send to screen")
    self.goldProjectButton:SetScript("OnClick", function()
        ST:ToggleGoldProjected()
    end)

    self.goldStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.goldStartPauseButton:SetText("Start")
    self.goldStartPauseButton:SetScript("OnClick", function()
        ST:ToggleGoldTracker()
    end)

    self.goldResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.goldResetButton:SetText("Reset")
    self.goldResetButton:SetScript("OnClick", function()
        ST:ResetGoldTracker()
    end)

    self:LayoutTrackerButtons(frame, self.goldStartPauseButton, self.goldProjectButton, self.goldResetButton)

    return frame
end

function ST:ToggleGoldTracker()
    if self.gold.running then
        self:PauseGoldTracker()
    else
        self:StartGoldTracker()
    end
end

function ST:StartGoldTracker()
    local money = self:PlainNumber(GetMoney())
    if not money then
        self:Print("Gold value is unavailable.")
        return
    end
    self.gold.anchor = GetTime()
    self.gold.startValue = money
    self.gold.running = true
    self.goldStartPauseButton:SetText("Pause")
    self:SaveDB()
    self:RefreshTicker()
end

function ST:OnMoneyUpdate()
    if not self.gold.running then
        return
    end
    local currentGold = self:PlainNumber(GetMoney())
    if not currentGold then
        return
    end
    local diff = currentGold - self.gold.startValue
    if diff ~= 0 then
        self.gold.gained = self.gold.gained + diff
        self.gold.startValue = currentGold
        self:UpdateGoldTracker()
    end
end

function ST:PauseGoldTracker()
    if not self.gold.running then
        return
    end
    self:OnMoneyUpdate()
    self.gold.elapsed = self.gold.elapsed + (GetTime() - self.gold.anchor)
    self.gold.running = false
    self.goldStartPauseButton:SetText("Resume")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateGoldTracker()
end

function ST:ResetGoldTracker()
    local wasRunning = self.gold.running
    self.gold.running = false
    self.gold.elapsed = 0
    self.gold.anchor = 0
    self.gold.startValue = 0
    self.gold.gained = 0
    self.goldGainedDisplay:SetText("0c")
    self.goldPerHourDisplay:SetText("Gold/hr: 0c")
    self.goldElapsedDisplay:SetText("Elapsed: 00:00:00")
    if self.goldProjectedFrame then
        self.goldProjGained:SetText("Gained: 0c")
        self.goldProjPerHour:SetText("Gold/hr: 0c")
        self.goldProjElapsed:SetText("Elapsed: 00:00:00")
    end
    if wasRunning then
        self:StartGoldTracker()
    else
        self.goldStartPauseButton:SetText("Start")
        self:SaveDB()
        self:RefreshTicker()
    end
end

function ST:GoldElapsed()
    local elapsed = self.gold.elapsed
    if self.gold.running then
        elapsed = elapsed + (GetTime() - self.gold.anchor)
    end
    return elapsed
end

function ST:UpdateGoldTracker()
    if not self.goldElapsedDisplay then
        return
    end

    local elapsed = self:GoldElapsed()
    local elapsedText = "Elapsed: " .. self:FormatElapsedTime(elapsed)
    self.goldElapsedDisplay:SetText(elapsedText)
    if self.goldProjectedFrame then
        self.goldProjElapsed:SetText(elapsedText)
    end

    local gainedText = self:FormatMoney(self.gold.gained)
    self.goldGainedDisplay:SetText(gainedText)
    if self.goldProjectedFrame then
        self.goldProjGained:SetText("Gained: " .. gainedText)
    end

    if elapsed > 0 then
        local goldPerHour = math.floor((self.gold.gained / elapsed) * 3600)
        local rateText = self:FormatMoney(goldPerHour)
        self.goldPerHourDisplay:SetText("Gold/hr: " .. rateText)
        if self.goldProjectedFrame then
            self.goldProjPerHour:SetText("Gold/hr: " .. rateText)
        end
    else
        self.goldPerHourDisplay:SetText("Gold/hr: 0c")
        if self.goldProjectedFrame then
            self.goldProjPerHour:SetText("Gold/hr: 0c")
        end
    end
end

function ST:CreateGoldProjectedFrame()
    local frame = CreateFrame("Frame", "SimpleGoldProjectedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(160, 62)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
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
    self:ApplyOverlayBackdrop(frame)

    self.goldProjGained = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldProjGained:SetPoint("TOP", 0, -8)
    self.goldProjGained:SetText("Gained: 0c")

    self.goldProjPerHour = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldProjPerHour:SetPoint("TOP", 0, -24)
    self.goldProjPerHour:SetText("Gold/hr: 0c")

    self.goldProjElapsed = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldProjElapsed:SetPoint("TOP", 0, -40)
    self.goldProjElapsed:SetText("Elapsed: 00:00:00")

    frame:SetScript("OnEnter", function(selfObj)
        GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
        GameTooltip:SetText("Gold Tracker")
        GameTooltip:AddLine("Drag to move. Hidden overlays keep running.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)

    self:AttachOverlayClose(frame, function()
        ST:ShowGoldProjected(false)
    end)

    frame:Hide()
    self.goldProjectedFrame = frame
end

function ST:ShowGoldProjected(show, pos)
    if not self.goldProjectedFrame then
        self:CreateGoldProjectedFrame()
    end
    if show then
        if pos and pos.projPoint then
            self.goldProjectedFrame:ClearAllPoints()
            self.goldProjectedFrame:SetPoint(pos.projPoint, UIParent, pos.projRelativePoint or "CENTER", pos.projX or 0, pos.projY or 0)
        end
        self.goldProjectedFrame:Show()
        self.goldProjectButton:SetText("Unproject")
        self.gold.projected = true
        self:UpdateGoldTracker()
    else
        self.goldProjectedFrame:Hide()
        self.goldProjectButton:SetText("Send to screen")
        self.gold.projected = false
    end
end

function ST:ToggleGoldProjected()
    self:ShowGoldProjected(not (self.goldProjectedFrame and self.goldProjectedFrame:IsShown()))
    self:SaveDB()
end
