local addonName, SimpleTools = ...

local GetTime = GetTime
local GetMoney = GetMoney

-- Gold Tracker state
SimpleTools.goldRunning = false
SimpleTools.goldStartTime = 0
SimpleTools.goldElapsedAtPause = 0
SimpleTools.goldStartValue = 0
SimpleTools.goldGained = 0

local function FormatMoney(copper)
    local negative = copper < 0
    copper = math.abs(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local str = ""
    if gold > 0 then
        str = str .. gold .. "g "
    end
    if silver > 0 or gold > 0 then
        str = str .. silver .. "s "
    end
    str = str .. cop .. "c"
    if negative then
        str = "-" .. str
    end
    return str
end

function SimpleTools:CreateSimpleGoldUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    -- Gold Gained Display
    local gainedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gainedLabel:SetPoint("TOP", 0, -10)
    gainedLabel:SetText("Gold Gained:")

    self.goldGainedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.goldGainedDisplay:SetPoint("TOP", 0, -25)
    self.goldGainedDisplay:SetText("0c")

    -- Gold/hr Display
    local goldPerHourLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldPerHourLabel:SetPoint("TOP", 0, -45)
    goldPerHourLabel:SetText("Gold/hr:")

    self.goldPerHourDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.goldPerHourDisplay:SetPoint("TOP", 0, -60)
    self.goldPerHourDisplay:SetText("0c")

    -- Elapsed Time Display
    self.goldElapsedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.goldElapsedDisplay:SetPoint("TOP", 0, -85)
    self.goldElapsedDisplay:SetText("Elapsed: 00:00:00")

    -- Project Button
    self.goldProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.goldProjectButton:SetSize(110, 25)
    self.goldProjectButton:SetPoint("BOTTOM", 0, 10)
    self.goldProjectButton:SetText("Send to screen")
    self.goldProjectButton:SetScript("OnClick", function() SimpleTools:ToggleGoldProjected() end)

    -- Start/Pause Button
    self.goldStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.goldStartPauseButton:SetSize(80, 25)
    self.goldStartPauseButton:SetPoint("BOTTOMLEFT", 10, 10)
    self.goldStartPauseButton:SetText("Start")
    self.goldStartPauseButton:SetScript("OnClick", function() SimpleTools:ToggleGoldTracker() end)

    -- Reset Button
    self.goldResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.goldResetButton:SetSize(80, 25)
    self.goldResetButton:SetPoint("BOTTOMRIGHT", -10, 10)
    self.goldResetButton:SetText("Reset")
    self.goldResetButton:SetScript("OnClick", function() SimpleTools:ResetGoldTracker() end)

    return frame
end

function SimpleTools:ToggleGoldTracker()
    if self.goldRunning then
        self:PauseGoldTracker()
    else
        self:StartGoldTracker()
    end
end

function SimpleTools:StartGoldTracker()
    if not self.goldRunning then
        self.goldStartTime = GetTime()
        self.goldStartValue = GetMoney()
        self.goldRunning = true
        self.goldStartPauseButton:SetText("Pause")
        self:SaveVariables()
    end
end

function SimpleTools:PauseGoldTracker()
    if self.goldRunning then
        -- Capture any gold change since last update
        local currentGold = GetMoney()
        self.goldGained = self.goldGained + (currentGold - self.goldStartValue)
        self.goldStartValue = currentGold

        self.goldElapsedAtPause = self.goldElapsedAtPause + (GetTime() - self.goldStartTime)
        self.goldRunning = false
        self.goldStartPauseButton:SetText("Resume")
        self:SaveVariables()
    end
end

function SimpleTools:ResetGoldTracker()
    local wasRunning = self.goldRunning
    self.goldRunning = false
    self.goldStartTime = 0
    self.goldElapsedAtPause = 0
    self.goldStartValue = 0
    self.goldGained = 0
    self.goldGainedDisplay:SetText("0c")
    self.goldPerHourDisplay:SetText("0c")
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
        self:SaveVariables()
    end
end

function SimpleTools:UpdateGoldTracker()
    -- Track gold changes while running
    if self.goldRunning then
        local currentGold = GetMoney()
        local diff = currentGold - self.goldStartValue
        if diff ~= 0 then
            self.goldGained = self.goldGained + diff
            self.goldStartValue = currentGold
        end
    end

    local elapsed = self.goldElapsedAtPause
    if self.goldRunning then
        elapsed = elapsed + (GetTime() - self.goldStartTime)
    end

    self.goldElapsedDisplay:SetText("Elapsed: " .. self:FormatElapsedTime(math.floor(elapsed)))
    if self.goldProjectedFrame then
        self.goldProjElapsed:SetText("Elapsed: " .. self:FormatElapsedTime(math.floor(elapsed)))
    end

    self.goldGainedDisplay:SetText(FormatMoney(self.goldGained))
    if self.goldProjectedFrame then
        self.goldProjGained:SetText("Gained: " .. FormatMoney(self.goldGained))
    end

    if elapsed > 0 then
        local goldPerHour = math.floor((self.goldGained / elapsed) * 3600)
        self.goldPerHourDisplay:SetText(FormatMoney(goldPerHour))
        if self.goldProjectedFrame then
            self.goldProjPerHour:SetText("Gold/hr: " .. FormatMoney(goldPerHour))
        end
    else
        self.goldPerHourDisplay:SetText("0c")
        if self.goldProjectedFrame then
            self.goldProjPerHour:SetText("Gold/hr: 0c")
        end
    end
end

function SimpleTools:CreateGoldProjectedFrame()
    local frame = CreateFrame("Frame", "SimpleGoldProjectedFrame", UIParent)
    frame:SetSize(140, 55)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
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

    self.goldProjGained = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldProjGained:SetPoint("TOP", 0, -5)
    self.goldProjGained:SetText("Gained: 0c")

    self.goldProjPerHour = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldProjPerHour:SetPoint("TOP", 0, -20)
    self.goldProjPerHour:SetText("Gold/hr: 0c")

    self.goldProjElapsed = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.goldProjElapsed:SetPoint("TOP", 0, -35)
    self.goldProjElapsed:SetText("Elapsed: 00:00:00")

    frame:SetScript("OnEnter", function(selfObj)
        GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
        GameTooltip:SetText("Gold Tracker (Projected)")
        GameTooltip:AddLine("Left-click and drag to move", 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(selfObj)
        GameTooltip:Hide()
    end)

    frame:Hide()
    self.goldProjectedFrame = frame
end

function SimpleTools:ToggleGoldProjected()
    if not self.goldProjectedFrame then
        self:CreateGoldProjectedFrame()
    end

    if self.goldProjectedFrame:IsShown() then
        self.goldProjectedFrame:Hide()
        self.goldProjectButton:SetText("Send to screen")
        self.goldProjected = false
    else
        self.goldProjectedFrame:Show()
        self.goldProjectButton:SetText("Unproject")
        self.goldProjected = true
        self:UpdateGoldTracker()
    end
    self:SaveVariables()
end
