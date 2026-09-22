--[[
  SimpleTools core: saved variables, ticker, formatters, events, settings.
  Shared by every module. Must load first.
]]

local addonName, ST = ...
_G.SimpleTools = ST

ST.ADDON_NAME = addonName
ST.VERSION = "2.3.4"
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
        width = 580,
        height = 300,
    },
    options = {
        sound = true,
        chat = true,
        minimap = true,
        minimapAngle = 200,
        defaultDuration = 10,
    },
    timer = {
        remaining = 0,
        total = 0,
        running = false,
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 180,
        projY = 120,
    },
    watch = {
        elapsed = 0,
        running = false,
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 180,
        projY = 60,
    },
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
    gather = {
        running = false,
        elapsed = 0,
        nodes = 0,
        herbNodes = 0,
        oreNodes = 0,
        skinNodes = 0,
        items = {},
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 0,
        projY = -170,
    },
    notepad = {
        text = "",
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 260,
        projY = 20,
        projWidth = 260,
        projHeight = 200,
    },
    shop = {
        items = {},
        projected = false,
        projPoint = "CENTER",
        projRelativePoint = "CENTER",
        projX = 180,
        projY = -80,
    },
}

-- Runtime clocks (GetTime is session-local and MUST NOT be persisted)
ST.timer = { remaining = 0, total = 0, running = false, anchor = 0, projected = false }
ST.watch = { elapsed = 0, running = false, anchor = 0, projected = false }
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
ST.gather = {
    running = false,
    elapsed = 0,
    anchor = 0,
    nodes = 0,
    herbNodes = 0,
    oreNodes = 0,
    skinNodes = 0,
    items = {},
    projected = false,
}
ST.reminder = { time = nil, set = false, lastFired = "" }
ST.notepadText = ""
ST.notepadProjected = false
ST.shopItems = {}
ST.shopProjected = false

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

local function CopyItems(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for k, v in pairs(src) do
        if type(v) == "table" then
            out[k] = {
                name = v.name,
                count = tonumber(v.count) or 0,
                kind = v.kind,
            }
        end
    end
    return out
end

local function CopyShopItems(src)
    local out = {}
    if type(src) ~= "table" then
        return out
    end
    for i, v in ipairs(src) do
        if type(v) == "table" then
            out[i] = {
                id = tonumber(v.id) or 0,
                name = v.name or "Item",
                link = v.link,
                count = tonumber(v.count) or 1,
            }
        end
    end
    return out
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
    if self.gather.running then
        self.gather.elapsed = self.gather.elapsed + (now - self.gather.anchor)
        self.gather.anchor = now
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
    local timerPoint, timerRel, timerX, timerY = SnapshotPoint(self.timerProjectedFrame, db.timer)
    db.timer.projected = self.timer.projected
    db.timer.projPoint = timerPoint
    db.timer.projRelativePoint = timerRel
    db.timer.projX = timerX
    db.timer.projY = timerY

    db.watch.elapsed = self.watch.elapsed
    db.watch.running = self.watch.running
    local watchPoint, watchRel, watchX, watchY = SnapshotPoint(self.watchProjectedFrame, db.watch)
    db.watch.projected = self.watch.projected
    db.watch.projPoint = watchPoint
    db.watch.projRelativePoint = watchRel
    db.watch.projX = watchX
    db.watch.projY = watchY

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

    local gatherPoint, gatherRel, gatherX, gatherY = SnapshotPoint(self.gatherProjectedFrame, db.gather)
    db.gather.running = self.gather.running
    db.gather.elapsed = self.gather.elapsed
    db.gather.nodes = self.gather.nodes
    db.gather.herbNodes = self.gather.herbNodes
    db.gather.oreNodes = self.gather.oreNodes
    db.gather.skinNodes = self.gather.skinNodes
    db.gather.items = CopyItems(self.gather.items)
    db.gather.projected = self.gather.projected
    db.gather.projPoint = gatherPoint
    db.gather.projRelativePoint = gatherRel
    db.gather.projX = gatherX
    db.gather.projY = gatherY

    local notePoint, noteRel, noteX, noteY = SnapshotPoint(self.notepadProjectedFrame, db.notepad)
    db.notepad.text = self.notepadText or ""
    db.notepad.projected = self.notepadProjected
    db.notepad.projPoint = notePoint
    db.notepad.projRelativePoint = noteRel
    db.notepad.projX = noteX
    db.notepad.projY = noteY
    if self.notepadProjectedFrame then
        db.notepad.projWidth = math.floor((self.notepadProjectedFrame:GetWidth() or 260) + 0.5)
        db.notepad.projHeight = math.floor((self.notepadProjectedFrame:GetHeight() or 200) + 0.5)
    end

    db.shop = db.shop or {}
    db.shop.items = CopyShopItems(self.shopItems)
    local shopPoint, shopRel, shopX, shopY = SnapshotPoint(self.shopProjectedFrame, db.shop)
    db.shop.projected = self.shopProjected
    db.shop.projPoint = shopPoint
    db.shop.projRelativePoint = shopRel
    db.shop.projX = shopX
    db.shop.projY = shopY

    if self.frame then
        local point, _, relativePoint, x, y = self.frame:GetPoint()
        if point then
            db.ui.point = point
            db.ui.relativePoint = relativePoint
            db.ui.x = x
            db.ui.y = y
        end
        db.ui.width = math.floor((self.frame:GetWidth() or 580) + 0.5)
        db.ui.height = math.floor((self.frame:GetHeight() or 300) + 0.5)
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
    if db.timer.projected and self.ShowTimerProjected then
        self:ShowTimerProjected(true, db.timer)
    end

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
    if self.UpdateStopwatch then
        self:UpdateStopwatch()
    end
    if db.watch.projected and self.ShowWatchProjected then
        self:ShowWatchProjected(true, db.watch)
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

    self.gather.running = db.gather.running or false
    self.gather.elapsed = db.gather.elapsed or 0
    self.gather.nodes = db.gather.nodes or 0
    self.gather.herbNodes = db.gather.herbNodes or 0
    self.gather.oreNodes = db.gather.oreNodes or 0
    self.gather.skinNodes = db.gather.skinNodes or 0
    self.gather.items = CopyItems(db.gather.items)
    if self.gather.running then
        self.gather.anchor = GetTime()
        if self.gatherStartPauseButton then
            self.gatherStartPauseButton:SetText("Pause")
        end
    elseif self.gather.elapsed > 0 and self.gatherStartPauseButton then
        self.gatherStartPauseButton:SetText("Resume")
    end
    if self.UpdateGatherTracker then
        self:UpdateGatherTracker()
    end
    if db.gather.projected and self.ShowGatherProjected then
        self:ShowGatherProjected(true, db.gather)
    end

    self.notepadText = db.notepad.text or ""
    self.notepadProjected = db.notepad.projected or false
    if self.notepadEditBox then
        self.notepadEditBox:SetText(self.notepadText)
    end
    if self.notepadProjected and self.ShowNotepadProjected then
        self:ShowNotepadProjected(true, db.notepad)
    end

    self.shopItems = CopyShopItems(db.shop and db.shop.items)
    if self.RefreshShopList then
        self:RefreshShopList()
    end
    self.shopProjected = db.shop and db.shop.projected or false
    if self.shopProjected and self.ShowShopProjected then
        self:ShowShopProjected(true, db.shop)
    end

    if self.frame and db.ui then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(db.ui.point or "CENTER", UIParent, db.ui.relativePoint or "CENTER", db.ui.x or 0, db.ui.y or 0)
        local width = db.ui.width or 580
        local height = db.ui.height or 300
        width = math.max(560, math.min(900, width))
        height = math.max(260, math.min(640, height))
        self.frame:SetSize(width, height)
        if self.OnMainFrameSizeChanged then
            self:OnMainFrameSizeChanged()
        end
    end

    if db.ui and db.ui.selectedTab then
        self:SelectTab(db.ui.selectedTab)
    end
end

function ST:IsBusy()
    return self.timer.running or self.watch.running or self.xp.running or self.gold.running or self.gather.running or self.reminder.set
end

function ST:RefreshTicker()
    local needFast = self.timer.running or self.watch.running or self.xp.running or self.gold.running or self.gather.running
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

    if self.gather.running and self.UpdateGatherTracker then
        self:UpdateGatherTracker()
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
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:RegisterEvent("CHAT_MSG_LOOT")
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
            if self.UpdateGatherTracker then
                self:UpdateGatherTracker()
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if self.OnGatherSpell then
                self:OnGatherSpell(...)
            end
        elseif event == "CHAT_MSG_LOOT" then
            if self.OnGatherLoot then
                self:OnGatherLoot(...)
            end
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

function ST:TryCreateFrame(name, parent, template)
    local ok, frame = pcall(CreateFrame, "Frame", name, parent, template)
    if ok and frame then
        return frame
    end
    return nil
end

function ST:TryCreateButton(name, parent, template)
    local ok, btn = pcall(CreateFrame, "Button", name, parent, template)
    if ok and btn then
        return btn
    end
    return nil
end

-- Forever / Midnight windows use DefaultPanelTemplate (brown metal nine-slice).
-- Fall back to the older inset frame if a client is missing the new kit.
function ST:CreateThemedPanel(name, parent)
    local frame = self:TryCreateFrame(name, parent or UIParent, "DefaultPanelTemplate")
        or self:TryCreateFrame(name, parent or UIParent, "ButtonFrameTemplateNoPortrait")
        or self:TryCreateFrame(name, parent or UIParent, "BasicFrameTemplateWithInset")
    if not frame then
        frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
        self:ApplyOverlayBackdrop(frame)
    end
    return frame
end

function ST:SetPanelTitle(frame, text)
    if not frame then
        return
    end
    if frame.SetTitle then
        frame:SetTitle(text)
        return
    end
    if frame.TitleContainer and frame.TitleContainer.TitleText then
        frame.TitleContainer.TitleText:SetText(text)
        frame.title = frame.TitleContainer.TitleText
        return
    end
    if frame.TitleText then
        frame.TitleText:SetText(text)
        frame.title = frame.TitleText
        return
    end
    if not frame.title then
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("TOP", 0, -5)
    end
    frame.title:SetText(text)
end

function ST:EnsurePanelClose(frame)
    if not frame or frame.CloseButton then
        return
    end
    local close = self:TryCreateButton(nil, frame, "UIPanelCloseButtonDefaultAnchors")
        or self:TryCreateButton(nil, frame, "UIPanelCloseButton")
    if not close then
        return
    end
    if not close:GetPoint() then
        close:SetPoint("TOPRIGHT", -4, -5)
    end
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.CloseButton = close
end

function ST:ApplyOverlayBackdrop(frame)
    if not frame or not frame.SetBackdrop then
        return
    end
    -- Small HUDs can't use the 32px dialog nine-slice. Tint the thin tooltip
    -- border bronze so it sits with Forever's brown metal instead of grey.
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.18, 0.12, 0.06, 0.94)
    frame:SetBackdropBorderColor(0.78, 0.58, 0.28, 0.95)
end

function ST:CreateOverlayFrame(globalName, width, height, defaultX, defaultY, tooltipTitle, onClose)
    local frame = CreateFrame("Frame", globalName, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER", defaultX or 0, defaultY or 0)
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
    if tooltipTitle then
        frame:SetScript("OnEnter", function(selfObj)
            GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipTitle)
            GameTooltip:AddLine(selfObj.overlayHint or "Drag to move. Hover for × to hide. Close the window — this overlay stays.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
    end
    self:AttachOverlayClose(frame, onClose)
    frame:Hide()
    return frame
end

function ST:AttachOverlayClose(frame, onClose)
    if not frame or frame.closeButton then
        return
    end
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetFrameLevel(frame:GetFrameLevel() + 5)
    close:RegisterForClicks("LeftButtonUp")
    close:Hide()

    local label = close:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", 0, 1)
    label:SetText("x")
    label:SetTextColor(0.75, 0.75, 0.75)
    close.label = label

    close:SetScript("OnEnter", function()
        close:Show()
        label:SetTextColor(1, 1, 1)
    end)
    close:SetScript("OnLeave", function()
        label:SetTextColor(0.75, 0.75, 0.75)
        if not frame:IsMouseOver() then
            close:Hide()
        end
    end)
    close:SetScript("OnClick", function()
        close:Hide()
        GameTooltip_Hide()
        if onClose then
            onClose()
        else
            frame:Hide()
        end
        ST:SaveDB()
    end)

    local prevEnter = frame:GetScript("OnEnter")
    local prevLeave = frame:GetScript("OnLeave")
    frame:SetScript("OnEnter", function(selfObj)
        close:Show()
        if prevEnter then
            prevEnter(selfObj)
        end
    end)
    frame:SetScript("OnLeave", function(selfObj)
        C_Timer.After(0.05, function()
            if not frame:IsShown() then
                return
            end
            if not frame:IsMouseOver() and not close:IsMouseOver() then
                close:Hide()
            end
        end)
        if prevLeave then
            prevLeave(selfObj)
        end
    end)
    frame.closeButton = close
end

function ST:PlaceOverlay(frame, pos)
    if not frame or not pos or not pos.projPoint then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint(pos.projPoint, UIParent, pos.projRelativePoint or "CENTER", pos.projX or 0, pos.projY or 0)
end

-- Start / Send to screen / Reset as a centered trio so they never overlap
-- each other or a right-side scrollbar.
function ST:LayoutTrackerButtons(parent, startBtn, projectBtn, resetBtn)
    local width, height, gap, bottom = 112, 25, 12, 8
    startBtn:SetSize(width, height)
    projectBtn:SetSize(width, height)
    resetBtn:SetSize(width, height)
    startBtn:ClearAllPoints()
    projectBtn:ClearAllPoints()
    resetBtn:ClearAllPoints()
    startBtn:SetPoint("BOTTOM", parent, "BOTTOM", -(width + gap), bottom)
    projectBtn:SetPoint("BOTTOM", parent, "BOTTOM", 0, bottom)
    resetBtn:SetPoint("BOTTOM", parent, "BOTTOM", (width + gap), bottom)
end

function ST:LayoutBottomPair(parent, leftBtn, rightBtn)
    local width, height, gap, bottom = 112, 25, 12, 8
    leftBtn:SetSize(width, height)
    rightBtn:SetSize(width, height)
    leftBtn:ClearAllPoints()
    rightBtn:ClearAllPoints()
    local offset = (width + gap) / 2
    leftBtn:SetPoint("BOTTOM", parent, "BOTTOM", -offset, bottom)
    rightBtn:SetPoint("BOTTOM", parent, "BOTTOM", offset, bottom)
end

function ST:AttachResizeGrip(frame, minW, minH, maxW, maxH, onStop)
    if not frame then
        return
    end
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(minW, minH, maxW, maxH)
    else
        if frame.SetMinResize then
            frame:SetMinResize(minW, minH)
        end
        if frame.SetMaxResize then
            frame:SetMaxResize(maxW, maxH)
        end
    end
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetFrameLevel(frame:GetFrameLevel() + 8)
    grip:EnableMouse(true)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        if onStop then
            onStop()
        end
        ST:SaveDB()
    end)
    frame.resizeGrip = grip
    return grip
end
