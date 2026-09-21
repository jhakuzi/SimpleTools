--[[
  SimpleTools core: saved variables, ticker, formatters, events, settings.
  Shared by every module. Must load first.
]]

local addonName, ST = ...
_G.SimpleTools = ST

ST.ADDON_NAME = addonName
ST.VERSION = "2.0.0"
ST.DB_VERSION = 2

local GetTime = GetTime
local CreateFrame = CreateFrame
local C_Timer = C_Timer

local issecretvalue = _G.issecretvalue or function() return false end

local DEFAULTS = {
    version = 2,
    ui = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        selectedTab = 1,
    },
    options = {
        sound = true,
        chat = true,
        minimap = true,
        minimapAngle = 200,
        defaultDuration = 10,
    },
    timer = { remaining = 0, total = 0, running = false },
    watch = { elapsed = 0, running = false },
    reminder = { time = nil, set = false },
    xp = {
        running = false,
        elapsed = 0,
        startValue = 0,
        maxAtStart = 1,
        gained = 0,
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 0,
        projY = 0,
    },
    gold = {
        running = false,
        elapsed = 0,
        startValue = 0,
        gained = 0,
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 0,
        projY = -80,
    },
    notepad = { text = "" },
}

-- Runtime clocks (GetTime is session-local and MUST NOT be persisted)
ST.timer = { remaining = 0, total = 0, running = false, anchor = 0 }
ST.watch = { elapsed = 0, running = false, anchor = 0 }
ST.xp = {
    running = false,
    elapsed = 0,
    anchor = 0,
    startValue = 0,
    maxAtStart = 1,
    gained = 0,
    projected = false,
}
ST.gold = {
    running = false,
    elapsed = 0,
    anchor = 0,
    startValue = 0,
    gained = 0,
    projected = false,
}
ST.reminder = { time = nil, set = false, lastFired = "" }
ST.notepadText = ""

local function CopyDefaults(src, dest)
    dest = dest or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

function ST:IsSecret(value)
    return value ~= nil and issecretvalue(value)
end

-- Returns a usable number, or nil if the value is secret / missing.
function ST:PlainNumber(value)
    if value == nil or self:IsSecret(value) then
        return nil
    end
    return tonumber(value)
end

function ST:Print(msg)
    if self.db and self.db.options and self.db.options.chat == false then
        return
    end
    local frame = DEFAULT_CHAT_FRAME
    if frame then
        frame:AddMessage("|cffc8ccd4SimpleTools|r: " .. tostring(msg))
    else
        print("SimpleTools: " .. tostring(msg))
    end
end

function ST:PlayAlert()
    if self.db and self.db.options and self.db.options.sound == false then
        return
    end
    local kit = (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8960
    PlaySound(kit, "Master")
end

function ST:FormatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%02d:%02d", minutes, secs)
end

function ST:FormatElapsedTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function ST:FormatMoney(copper)
    copper = tonumber(copper) or 0
    local negative = copper < 0
    copper = math.floor(math.abs(copper) + 0.5)
    if GetCoinTextureString then
        local ok, text = pcall(GetCoinTextureString, copper)
        if ok and text and text ~= "" then
            if negative then
                return "-" .. text
            end
            return text
        end
    end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local str = string.format("%dg %ds %dc", gold, silver, cop)
    if negative then
        return "-" .. str
    end
    return str
end

function ST:MigrateDB(db)
    if type(db) ~= "table" then
        return CopyDefaults(DEFAULTS, {})
    end

    -- v1 used GetTime() anchors, which reset on /reload. Drop them.
    if (db.version or 1) < 2 then
        if db.timer then
            db.timer.remaining = db.timer.remainingTime or db.timer.remaining or 0
            db.timer.total = db.timer.totalTime or db.timer.total or 0
            db.timer.running = db.timer.isRunning or db.timer.running or false
            db.timer.startTime = nil
            db.timer.remainingTime = nil
            db.timer.totalTime = nil
            db.timer.isRunning = nil
        end
        if db.watch then
            db.watch.elapsed = db.watch.elapsedAtPause or db.watch.elapsed or 0
            db.watch.running = db.watch.running or false
            db.watch.startTime = nil
            db.watch.elapsedAtPause = nil
        end
        if db.xp then
            db.xp.elapsed = db.xp.elapsedAtPause or db.xp.elapsed or 0
            db.xp.startTime = nil
            db.xp.elapsedAtPause = nil
        end
        if db.gold then
            db.gold.elapsed = db.gold.elapsedAtPause or db.gold.elapsed or 0
            db.gold.startTime = nil
            db.gold.elapsedAtPause = nil
        end
        db.version = 2
    end

    return CopyDefaults(DEFAULTS, db)
end

function ST:InitDB()
    SimpleToolsDB = self:MigrateDB(SimpleToolsDB)
    self.db = SimpleToolsDB
end

function ST:CaptureRunningDurations()
    local now = GetTime()
    if self.timer.running then
        self.timer.remaining = math.max(0, self.timer.remaining - (now - self.timer.anchor))
        self.timer.anchor = now
    end
    if self.watch.running then
        self.watch.elapsed = self.watch.elapsed + (now - self.watch.anchor)
        self.watch.anchor = now
    end
    if self.xp.running then
        self.xp.elapsed = self.xp.elapsed + (now - self.xp.anchor)
        self.xp.anchor = now
    end
    if self.gold.running then
        self.gold.elapsed = self.gold.elapsed + (now - self.gold.anchor)
        self.gold.anchor = now
    end
end

local function SnapshotPoint(frame, fallback)
    if frame then
        local point, _, relativePoint, x, y = frame:GetPoint()
        if point then
            return point, relativePoint, x, y
        end
    end
    if fallback then
        return fallback.projPoint, fallback.projRelativePoint, fallback.projX, fallback.projY
    end
    return "CENTER", "CENTER", 0, 0
end

function ST:SaveDB()
    if not self.db then
        return
    end
    self:CaptureRunningDurations()

    local db = self.db
    db.version = self.DB_VERSION

    db.timer.remaining = self.timer.remaining
    db.timer.total = self.timer.total
    db.timer.running = self.timer.running

    db.watch.elapsed = self.watch.elapsed
    db.watch.running = self.watch.running

    db.reminder.time = self.reminder.time
    db.reminder.set = self.reminder.set

    local xpPoint, xpRel, xpX, xpY = SnapshotPoint(self.xpProjectedFrame, db.xp)
    db.xp.running = self.xp.running
    db.xp.elapsed = self.xp.elapsed
    db.xp.startValue = self.xp.startValue
    db.xp.maxAtStart = self.xp.maxAtStart
    db.xp.gained = self.xp.gained
    db.xp.projected = self.xp.projected
    db.xp.projPoint = xpPoint
    db.xp.projRelativePoint = xpRel
    db.xp.projX = xpX
    db.xp.projY = xpY

    local goldPoint, goldRel, goldX, goldY = SnapshotPoint(self.goldProjectedFrame, db.gold)
    db.gold.running = self.gold.running
    db.gold.elapsed = self.gold.elapsed
    db.gold.startValue = self.gold.startValue
    db.gold.gained = self.gold.gained
    db.gold.projected = self.gold.projected
    db.gold.projPoint = goldPoint
    db.gold.projRelativePoint = goldRel
    db.gold.projX = goldX
    db.gold.projY = goldY

    db.notepad.text = self.notepadText or ""

    if self.frame then
        local point, _, relativePoint, x, y = self.frame:GetPoint()
        if point then
            db.ui.point = point
            db.ui.relativePoint = relativePoint
            db.ui.x = x
            db.ui.y = y
        end
    end
end

function ST:ScheduleSave()
    if self.savePending then
        return
    end
    self.savePending = true
    C_Timer.After(0.8, function()
        self.savePending = false
        self:SaveDB()
    end)
end

function ST:LoadState()
    local db = self.db
    if not db then
        return
    end

    self.timer.remaining = db.timer.remaining or 0
    self.timer.total = db.timer.total or 0
    self.timer.running = db.timer.running and self.timer.remaining > 0
    if self.timer.running then
        self.timer.anchor = GetTime()
        if self.startPauseButton then
            self.startPauseButton:SetText("Pause")
        end
    else
        self.timer.running = false
        if self.startPauseButton then
            if self.timer.remaining > 0 then
                self.startPauseButton:SetText("Resume")
            else
                self.startPauseButton:SetText("Start")
            end
        end
    end
    self:UpdateDisplay()

    self.watch.elapsed = db.watch.elapsed or 0
    self.watch.running = db.watch.running or false
    if self.watch.running then
        self.watch.anchor = GetTime()
        if self.swStartPauseButton then
            self.swStartPauseButton:SetText("Pause")
        end
    elseif self.watch.elapsed > 0 and self.swStartPauseButton then
        self.swStartPauseButton:SetText("Resume")
    end
    if self.stopwatchDisplay then
        self.stopwatchDisplay:SetText(self:FormatTime(self.watch.elapsed))
    end

    self.reminder.time = db.reminder.time
    self.reminder.set = db.reminder.set
    if self.reminder.set and self.reminder.time and self.reminderStatus then
        self.reminderStatus:SetText("Alarm set for: " .. self.reminder.time)
    end

    self.xp.running = db.xp.running or false
    self.xp.elapsed = db.xp.elapsed or 0
    self.xp.startValue = db.xp.startValue or 0
    self.xp.maxAtStart = db.xp.maxAtStart or 1
    self.xp.gained = db.xp.gained or 0
    if self.xp.running then
        self.xp.anchor = GetTime()
        if self.xpStartPauseButton then
            self.xpStartPauseButton:SetText("Pause")
        end
    elseif self.xp.elapsed > 0 and self.xpStartPauseButton then
        self.xpStartPauseButton:SetText("Resume")
    end
    if self.xpGainedDisplay then
        self.xpGainedDisplay:SetText(tostring(self.xp.gained))
    end
    self:UpdateXPTracker()
    if db.xp.projected then
        self:ShowXPProjected(true, db.xp)
    end

    self.gold.running = db.gold.running or false
    self.gold.elapsed = db.gold.elapsed or 0
    self.gold.startValue = db.gold.startValue or 0
    self.gold.gained = db.gold.gained or 0
    if self.gold.running then
        self.gold.anchor = GetTime()
        if self.goldStartPauseButton then
            self.goldStartPauseButton:SetText("Pause")
        end
    elseif self.gold.elapsed > 0 and self.goldStartPauseButton then
        self.goldStartPauseButton:SetText("Resume")
    end
    self:UpdateGoldTracker()
    if db.gold.projected then
        self:ShowGoldProjected(true, db.gold)
    end

    self.notepadText = db.notepad.text or ""
    if self.notepadEditBox then
        self.notepadEditBox:SetText(self.notepadText)
    end

    if self.frame and db.ui then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(db.ui.point or "CENTER", UIParent, db.ui.relativePoint or "CENTER", db.ui.x or 0, db.ui.y or 0)
    end

    if db.ui and db.ui.selectedTab then
        self:SelectTab(db.ui.selectedTab)
    end
end

function ST:IsBusy()
    return self.timer.running or self.watch.running or self.xp.running or self.gold.running or self.reminder.set
end

function ST:RefreshTicker()
    local needFast = self.timer.running or self.watch.running or self.xp.running or self.gold.running
    local needSlow = self.reminder.set
    local interval
    if needFast then
        interval = 0.25
    elseif needSlow then
        interval = 15
    end

    if self.tickerInterval == interval and self.ticker then
        return
    end
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
        self.tickerInterval = nil
    end
    if interval then
        self.tickerInterval = interval
        self.ticker = C_Timer.NewTicker(interval, function()
            self:OnTick()
        end)
    end
end

function ST:OnTick()
    local now = GetTime()

    if self.timer.running then
        local remaining = math.max(0, self.timer.remaining - (now - self.timer.anchor))
        self:UpdateDisplay()
        if remaining <= 0 then
            self:TimerFinished()
        end
    end

    if self.watch.running then
        self:UpdateStopwatch()
    end

    if self.xp.running then
        self:UpdateXPTracker()
    end

    if self.gold.running then
        self:UpdateGoldTracker()
    end

    self:CheckReminder()
end

function ST:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGOUT")
    f:RegisterEvent("PLAYER_MONEY")
    f:RegisterEvent("PLAYER_XP_UPDATE")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGOUT" then
            self:SaveDB()
        elseif event == "PLAYER_MONEY" then
            self:OnMoneyUpdate()
        elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
            self:OnXPUpdate()
        elseif event == "PLAYER_ENTERING_WORLD" then
            if self.gold.running then
                local money = self:PlainNumber(GetMoney())
                if money then
                    self.gold.startValue = money
                end
            end
            self:UpdateXPTracker()
            self:UpdateGoldTracker()
        end
    end)
    self.eventFrame = f
end

function ST:RegisterSettings()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    local db = self.db
    local category = Settings.RegisterVerticalLayoutCategory("SimpleTools")

    local function AddCheck(key, label, tooltip, defaultValue)
        local setting = Settings.RegisterAddOnSetting(
            category,
            "SimpleTools_" .. key,
            key,
            db.options,
            Settings.VarType and Settings.VarType.Boolean or "boolean",
            label,
            defaultValue
        )
        setting:SetValueChangedCallback(function()
            if key == "minimap" then
                self:UpdateMinimapButton()
            end
            self:SaveDB()
        end)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    AddCheck("sound", "Play alert sounds", "Play a sound when a timer or reminder fires.", true)
    AddCheck("chat", "Chat messages", "Print timer, reminder, and load messages in chat.", true)
    AddCheck("minimap", "Show minimap button", "Show a minimap button in addition to the addon compartment.", true)

    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end

function ST:OpenSettings()
    if Settings and Settings.OpenToCategory and self.settingsCategory then
        local id = self.settingsCategory
        if self.settingsCategory.GetID then
            id = self.settingsCategory:GetID()
        end
        Settings.OpenToCategory(id)
    else
        self:ToggleWindow()
    end
end
