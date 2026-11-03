--[[
  SimpleTools core: saved variables, ticker, formatters, events, settings.
  Shared by every module. Must load first.
]]

local addonName, ST = ...
_G.SimpleTools = ST

ST.ADDON_NAME = addonName
ST.VERSION = "2.10.0"
ST.DB_VERSION = 2
ST.FRAME_W = 540
ST.FRAME_H = 240
ST.FRAME_MIN_W = 480
ST.FRAME_MIN_H = 240
ST.FRAME_MAX_W = 900
ST.FRAME_MAX_H = 640

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
        tabs = "v2",
        compact241 = true,
        width = 540,
        height = 240,
    },
    options = {
        sound = true,
        chat = true,
        minimap = true,
        minimapAngle = 200,
        defaultDuration = 10,
        notepadPerCharacter = false,
        checklistPerCharacter = false,
        locationsPerCharacter = false,
    },
    locations = { bookmarks = {} },
    breakReminder = { interval = 60, snooze = 5, remaining = 0, running = false, due = false, message = nil },
    logging = { autoStart = false, projected = false, projPoint = "CENTER", projRelativePoint = "CENTER", projX = 0, projY = -240 },
    calculator = { projected = false, projPoint = "CENTER", projRelativePoint = "CENTER", projX = 240, projY = -120 },
    checklist = { items = {}, projected = false, projPoint = "CENTER", projRelativePoint = "CENTER", projX = 260, projY = -180 },
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
    reminder = { time = nil, set = false, message = nil },
    xp = {
        running = false,
        elapsed = 0,
        startValue = 0,
        maxAtStart = 1,
        gained = 0,
        kill = 0,
        quest = 0,
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
    characters = {},
    trackerMigrated = false,
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
ST.reminder = { time = nil, set = false, lastFired = "", message = nil }
ST.notepadText = ""
ST.notepadProjected = false
ST.shopItems = {}
ST.shopProjected = false
ST.locationBookmarks = {}
ST.loggingProjected = false
ST.calculatorProjected = false
ST.checklistItems = {}
ST.checklistProjected = false
ST.breakTimer = { interval = 60, snooze = 5, remaining = 0, running = false, due = false, anchor = 0 }

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

function ST:CharacterKey()
    if type(UnitGUID) ~= "function" then
        return nil
    end
    local guid = UnitGUID("player")
    if type(guid) ~= "string" or guid == "" or guid == "none" then
        return nil
    end
    return guid
end

function ST:TrackerReady()
    local guid = self:CharacterKey()
    if not guid then
        return true
    end
    return self.boundGuid == guid
end

function ST:EnsureCharacter(guid)
    guid = guid or self:CharacterKey()
    if not guid or not self.db then
        return nil
    end
    self.db.characters = self.db.characters or {}
    local bucket = self.db.characters[guid]
    if type(bucket) ~= "table" then
        bucket = {}
        self.db.characters[guid] = bucket
    end
    if type(UnitName) == "function" then
        local name, realm = UnitName("player")
        if type(name) == "string" and name ~= "" then
            bucket.name = name
            bucket.realm = realm
        end
    end
    return bucket
end

function ST:TrackerRoot()
    if self.boundGuid and self.db and self.db.characters and type(self.db.characters[self.boundGuid]) == "table" then
        return self.db.characters[self.boundGuid]
    end
    return self.db
end

function ST:ScopedListTable(optionKey, field)
    if self.db.options and self.db.options[optionKey] and self.boundGuid then
        local bucket = self:EnsureCharacter(self.boundGuid)
        if bucket then
            if type(bucket[field]) ~= "table" then
                bucket[field] = {}
            end
            return bucket[field]
        end
    end
    return self.db[field]
end

function ST:LoadScopedLists()
    if not self.db then
        return
    end
    local notes = self:ScopedListTable("notepadPerCharacter", "notepad")
    self.notepadText = notes.text or ""
    if self.notepadEditBox then
        self.notepadEditBox:SetText(self.notepadText)
    end
    if self.UpdateNotepadProjected then
        self:UpdateNotepadProjected()
    end

    local tasks = self:ScopedListTable("checklistPerCharacter", "checklist")
    self.checklistItems = self:CopyChecklistItems(tasks.items)
    if self.RefreshChecklistViews then
        self:RefreshChecklistViews()
    end

    local places = self:ScopedListTable("locationsPerCharacter", "locations")
    self.locationBookmarks = self:CopyLocationBookmarks(places.bookmarks)
    self.selectedLocation = nil
    if self.RefreshLocationList then
        self:RefreshLocationList()
    end
end

function ST:SetListScope(optionKey, perCharacter)
    if not self.db or not self.db.options then
        return
    end
    self:SaveDB()
    self.db.options[optionKey] = perCharacter and true or false
    self:LoadScopedLists()
    self:SaveDB()
    if self.UpdateOptionsDisplay then
        self:UpdateOptionsDisplay()
    end
    local label = optionKey == "notepadPerCharacter" and "Notepad"
        or (optionKey == "checklistPerCharacter" and "Checklist" or "Locations")
    if perCharacter then
        self:Print(label .. " now follows this character. The shared copy is kept.")
    else
        self:Print(label .. " is shared by every character again.")
    end
end

function ST:BindCharacter()
    local guid = self:CharacterKey()
    if not guid or not self.db or self.boundGuid == guid then
        return
    end
    if self.boundGuid then
        self:SaveDB()
    end
    local inherit = not self.db.trackerMigrated
    self.boundGuid = guid
    self:EnsureCharacter(guid)
    if inherit then
        -- Whoever logs in first after this update keeps the old account session.
        self:SaveDB()
        self.db.trackerMigrated = true
        self:LoadScopedLists()
        self:Print("Saved sessions now follow each character. This character kept the previous session.")
    else
        self:ApplyTrackerRuntime(self.db.characters[guid])
        self:LoadScopedLists()
    end
    if self.RefreshTicker then
        self:RefreshTicker()
    end
end

function ST:BeginGoldLoad()
    if not self.gold then
        return
    end
    self.gold.suppressZero = true
    self.gold.zeroConfirm = nil
    self.goldReconcileTries = 0
    self.goldLoadEpoch = (self.goldLoadEpoch or 0) + 1
end

function ST:AcceptSettledGold()
    local epoch = self.goldLoadEpoch
    local function finish()
        if self.goldLoadEpoch ~= epoch or not self.gold or not self.gold.suppressZero then
            return
        end
        local money = self.RawMoney and self:RawMoney() or nil
        if money == nil then
            return
        end
        if money > 0 then
            self.gold.suppressZero = false
            self.gold.zeroConfirm = nil
            self:ApplyMoneyValue(money)
            return
        end
        if not self.gold.zeroConfirm then
            self.gold.zeroConfirm = true
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, finish)
                return
            end
        end
        self.gold.suppressZero = false
        self.gold.zeroConfirm = nil
        self:ApplyMoneyValue(0)
    end
    finish()
end

function ST:ReconcileGold()
    if not self.gold or not self.gold.running or not self.ReadableMoney then
        return
    end
    local epoch = self.goldLoadEpoch
    local money = self:ReadableMoney()
    if money ~= nil then
        self.goldReconcileTries = 0
        self:ApplyMoneyValue(money)
        return
    end
    if not self.gold.suppressZero then
        return
    end
    self.goldReconcileTries = (self.goldReconcileTries or 0) + 1
    if self.goldReconcileTries > 3 or not (C_Timer and C_Timer.After) then
        self:AcceptSettledGold()
        return
    end
    C_Timer.After(1, function()
        if self.goldLoadEpoch ~= epoch or not self.gold.suppressZero then
            return
        end
        self:ReconcileGold()
    end)
end

function ST:OnPlayerEnteringWorld()
    self:BindCharacter()
    self:BeginGoldLoad()
    self:ReconcileGold()
    if self.AutoStartCombatLogging then
        self:AutoStartCombatLogging()
    end
    if self.UpdateXPTracker then
        self:UpdateXPTracker()
    end
    if self.UpdateGoldTracker then
        self:UpdateGoldTracker()
    end
    if self.UpdateGatherTracker then
        self:UpdateGatherTracker()
    end
    if self.RefreshShopList then
        self:RefreshShopList()
    end
end

function ST:InsertChatText(text)
    if type(text) ~= "string" or text == "" then
        return false
    end
    if type(ChatFrame_OpenChat) == "function" then
        ChatFrame_OpenChat(text)
        return true
    end
    local box = _G.ChatFrame1EditBox
    if type(ChatEdit_GetActiveWindow) == "function" then
        box = ChatEdit_GetActiveWindow() or box
    end
    if box and box.Insert then
        if box.IsShown and not box:IsShown() and type(ChatEdit_ActivateChat) == "function" then
            ChatEdit_ActivateChat(box)
        end
        box:Insert(text)
        return true
    end
    self:Print(text)
    return true
end

function ST:CreateListRow(parent, index, rowHeight)
    local height = rowHeight or 22
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(height)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * height)
    row:SetPoint("TOPRIGHT", 0, -(index - 1) * height)
    if row.SetHighlightTexture then
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    end
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    if row.text.SetJustifyH then
        row.text:SetJustifyH("LEFT")
    end
    if row.text.SetWordWrap then
        row.text:SetWordWrap(false)
    end
    return row
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

function ST:SetHeadlineFont(fs)
    fs:SetFontObject("GameFontHighlight")
    local font, size, flags = fs:GetFont()
    if font and size then
        fs:SetFont(font, size + 2, flags)
    end
end

function ST:FormatElapsedTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%02d:%02d", hours, minutes)
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

-- Per-hour numbers drift if recomputed every tick. Hold them, then refresh
-- once each 30s of session time. The first half-minute stays live so a
-- brand-new session is not stuck on a one-second spike.
function ST:HeldRate(state, elapsed, gained)
    elapsed = tonumber(elapsed) or 0
    gained = tonumber(gained) or 0
    if elapsed <= 0 then
        state.shownRate = 0
        state.rateBucket = nil
        return 0
    end
    if elapsed < 30 then
        state.rateBucket = nil
        state.shownRate = math.floor((gained / elapsed) * 3600)
        return state.shownRate
    end
    local bucket = math.floor(elapsed / 30)
    if state.rateBucket ~= bucket or state.shownRate == nil then
        state.rateBucket = bucket
        state.shownRate = math.floor((gained / elapsed) * 3600)
    end
    return state.shownRate
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
    if self.breakTimer.running then
        self.breakTimer.remaining = math.max(0, self.breakTimer.remaining - (now - self.breakTimer.anchor))
        self.breakTimer.anchor = now
    end
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
    local places = self:ScopedListTable("locationsPerCharacter", "locations")
    places.bookmarks = self:CopyLocationBookmarks(self.locationBookmarks)
    local breakTimer = self.breakTimer
    db.breakReminder.interval = breakTimer.interval
    db.breakReminder.snooze = breakTimer.snooze
    db.breakReminder.remaining = breakTimer.remaining
    db.breakReminder.running = breakTimer.running
    db.breakReminder.due = breakTimer.due
    db.breakReminder.message = self.BreakMessage and self:BreakMessage() or breakTimer.message
    db.logging.projected = self.loggingProjected
    local logPoint, logRel, logX, logY = SnapshotPoint(self.loggingProjectedFrame, db.logging)
    db.logging.projPoint, db.logging.projRelativePoint = logPoint, logRel
    db.logging.projX, db.logging.projY = logX, logY
    db.calculator.projected = self.calculatorProjected
    local calcPoint, calcRel, calcX, calcY = SnapshotPoint(self.calculatorProjectedFrame, db.calculator)
    db.calculator.projPoint, db.calculator.projRelativePoint = calcPoint, calcRel
    db.calculator.projX, db.calculator.projY = calcX, calcY
    local tasks = self:ScopedListTable("checklistPerCharacter", "checklist")
    tasks.items = self:CopyChecklistItems(self.checklistItems)
    db.checklist.projected = self.checklistProjected
    local taskPoint, taskRel, taskX, taskY = SnapshotPoint(self.checklistProjectedFrame, db.checklist)
    db.checklist.projPoint, db.checklist.projRelativePoint = taskPoint, taskRel
    db.checklist.projX, db.checklist.projY = taskX, taskY

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
    db.reminder.message = self.reminder.message

    local track = self:TrackerRoot()
    local function Dest(key)
        if type(track[key]) ~= "table" then
            track[key] = {}
        end
        return track[key]
    end

    local xpSaved = Dest("xp")
    local xpPoint, xpRel, xpX, xpY = SnapshotPoint(self.xpProjectedFrame, xpSaved.projPoint and xpSaved or db.xp)
    xpSaved.running = self.xp.running
    xpSaved.elapsed = self.xp.elapsed
    xpSaved.startValue = self.xp.startValue
    xpSaved.maxAtStart = self.xp.maxAtStart
    xpSaved.gained = self.xp.gained
    xpSaved.kill = self.xp.kill or 0
    xpSaved.quest = self.xp.quest or 0
    xpSaved.projected = self.xp.projected
    xpSaved.projPoint = xpPoint
    xpSaved.projRelativePoint = xpRel
    xpSaved.projX = xpX
    xpSaved.projY = xpY

    local goldSaved = Dest("gold")
    local goldPoint, goldRel, goldX, goldY = SnapshotPoint(self.goldProjectedFrame, goldSaved.projPoint and goldSaved or db.gold)
    goldSaved.running = self.gold.running
    goldSaved.elapsed = self.gold.elapsed
    goldSaved.startValue = self.gold.startValue
    goldSaved.gained = self.gold.gained
    goldSaved.projected = self.gold.projected
    goldSaved.projPoint = goldPoint
    goldSaved.projRelativePoint = goldRel
    goldSaved.projX = goldX
    goldSaved.projY = goldY

    local gatherSaved = Dest("gather")
    local gatherPoint, gatherRel, gatherX, gatherY = SnapshotPoint(self.gatherProjectedFrame, gatherSaved.projPoint and gatherSaved or db.gather)
    gatherSaved.running = self.gather.running
    gatherSaved.elapsed = self.gather.elapsed
    gatherSaved.nodes = self.gather.nodes
    gatherSaved.herbNodes = self.gather.herbNodes
    gatherSaved.oreNodes = self.gather.oreNodes
    gatherSaved.skinNodes = self.gather.skinNodes
    gatherSaved.items = CopyItems(self.gather.items)
    gatherSaved.projected = self.gather.projected
    gatherSaved.projPoint = gatherPoint
    gatherSaved.projRelativePoint = gatherRel
    gatherSaved.projX = gatherX
    gatherSaved.projY = gatherY

    local notes = self:ScopedListTable("notepadPerCharacter", "notepad")
    notes.text = self.notepadText or ""
    local notePoint, noteRel, noteX, noteY = SnapshotPoint(self.notepadProjectedFrame, db.notepad)
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
    if self.shopProjectedFrame then
        db.shop.projWidth = math.floor((self.shopProjectedFrame:GetWidth() or 220) + 0.5)
        db.shop.projHeight = math.floor((self.shopProjectedFrame:GetHeight() or 140) + 0.5)
    end

    if self.frame then
        local point, _, relativePoint, x, y = self.frame:GetPoint()
        if point then
            db.ui.point = point
            db.ui.relativePoint = relativePoint
            db.ui.x = x
            db.ui.y = y
        end
        db.ui.width = math.floor((self.frame:GetWidth() or ST.FRAME_W) + 0.5)
        db.ui.height = math.floor((self.frame:GetHeight() or ST.FRAME_H) + 0.5)
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

function ST:ApplyTrackerRuntime(source)
    source = source or {}
    local xp = source.xp or {}
    self.xp.running = xp.running or false
    self.xp.elapsed = xp.elapsed or 0
    self.xp.startValue = xp.startValue or 0
    self.xp.maxAtStart = xp.maxAtStart or 1
    self.xp.gained = xp.gained or 0
    self.xp.kill = xp.kill or 0
    self.xp.quest = xp.quest or 0
    self.xp.projected = xp.projected and true or false
    self.xp.shownRate = nil
    self.xp.rateBucket = nil
    self.xp.pendingKill = 0
    self.xp.pendingQuest = 0
    self.xp.unclassified = 0
    if self.xp.running then
        self.xp.anchor = GetTime()
        if self.xpStartPauseButton then
            self.xpStartPauseButton:SetText("Pause")
        end
    else
        self.xp.anchor = 0
        if self.xpStartPauseButton then
            self.xpStartPauseButton:SetText(self.xp.elapsed > 0 and "Resume" or "Start")
        end
    end
    if self.xpGainedDisplay then
        self.xpGainedDisplay:SetText(tostring(self.xp.gained))
    end
    if self.RefreshXPSplit then
        self:RefreshXPSplit()
    end
    if self.UpdateXPTracker then
        self:UpdateXPTracker()
    end
    if self.xp.projected and self.ShowXPProjected then
        self:ShowXPProjected(true, xp)
    elseif self.xpProjectedFrame then
        self.xpProjectedFrame:Hide()
        if self.xpProjectButton then
            self.xpProjectButton:SetText("Send to screen")
        end
    end

    local gold = source.gold or {}
    self.gold.running = gold.running or false
    self.gold.elapsed = gold.elapsed or 0
    self.gold.startValue = gold.startValue or 0
    self.gold.gained = gold.gained or 0
    self.gold.projected = gold.projected and true or false
    self.gold.shownRate = nil
    self.gold.rateBucket = nil
    if self.gold.running then
        self.gold.anchor = GetTime()
        if self.goldStartPauseButton then
            self.goldStartPauseButton:SetText("Pause")
        end
    else
        self.gold.anchor = 0
        if self.goldStartPauseButton then
            self.goldStartPauseButton:SetText(self.gold.elapsed > 0 and "Resume" or "Start")
        end
    end
    if self.UpdateGoldTracker then
        self:UpdateGoldTracker()
    end
    if self.gold.projected and self.ShowGoldProjected then
        self:ShowGoldProjected(true, gold)
    elseif self.goldProjectedFrame then
        self.goldProjectedFrame:Hide()
        if self.goldProjectButton then
            self.goldProjectButton:SetText("Send to screen")
        end
    end

    local gather = source.gather or {}
    self.gather.running = gather.running or false
    self.gather.elapsed = gather.elapsed or 0
    self.gather.nodes = gather.nodes or 0
    self.gather.herbNodes = gather.herbNodes or 0
    self.gather.oreNodes = gather.oreNodes or 0
    self.gather.skinNodes = gather.skinNodes or 0
    self.gather.items = CopyItems(gather.items)
    self.gather.projected = gather.projected and true or false
    self.gather.shownRate = nil
    self.gather.rateBucket = nil
    if self.gather.running then
        self.gather.anchor = GetTime()
        if self.gatherStartPauseButton then
            self.gatherStartPauseButton:SetText("Pause")
        end
    else
        self.gather.anchor = 0
        if self.gatherStartPauseButton then
            self.gatherStartPauseButton:SetText(self.gather.elapsed > 0 and "Resume" or "Start")
        end
    end
    if self.UpdateGatherTracker then
        self:UpdateGatherTracker()
    end
    if self.gather.projected and self.ShowGatherProjected then
        self:ShowGatherProjected(true, gather)
    elseif self.gatherProjectedFrame then
        self.gatherProjectedFrame:Hide()
        if self.gatherProjectButton then
            self.gatherProjectButton:SetText("Send to screen")
        end
    end
end

function ST:LoadState()
    local db = self.db
    if not db then
        return
    end
    self:LoadScopedLists()

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
    self.reminder.message = db.reminder.message
    if self.reminderMessageInput and type(db.reminder.message) == "string" then
        self.reminderMessageInput:SetText(db.reminder.message)
    end
    if self.reminder.set and self.reminder.time and self.reminderStatus then
        self.reminderStatus:SetText("Alarm set for: " .. self.reminder.time)
    end

    if not db.trackerMigrated or not self:CharacterKey() then
        self:ApplyTrackerRuntime(db)
    end

    self.notepadProjected = db.notepad.projected or false
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
        local width = db.ui.width or ST.FRAME_W
        local height = db.ui.height or ST.FRAME_H
        -- Fold the old default and the resize-jump sizes back to compact once.
        -- After this, a player resize is saved as usual.
        if not db.ui.compact241 then
            width, height = ST.FRAME_W, ST.FRAME_H
            db.ui.compact241 = true
        elseif width == 580 and height == 300 then
            width, height = ST.FRAME_W, ST.FRAME_H
        end
        self:ApplyMainFrameSize(width, height)
    end

    if db.ui and db.ui.selectedTab then
        if db.ui.tabs ~= "v2" then
            local legacy = { 1, 1, 1, 2, 2, 3, 4, 5 }
            db.ui.selectedTab = legacy[db.ui.selectedTab] or 1
            db.ui.tabs = "v2"
        end
        if db.ui.selectedTab > #self.tabFrames then
            db.ui.selectedTab = 1
        end
        self:SelectTab(db.ui.selectedTab)
    end
    self:LoadBreakState(db.breakReminder)
    self:UpdateLoggingDisplay()
    if db.logging.projected then self:ShowLoggingProjected(true, db.logging) end
    if db.calculator.projected then self:ShowCalculatorProjected(true, db.calculator) end
    if db.checklist.projected then self:ShowChecklistProjected(true, db.checklist) end
    self:BindCharacter()
end

function ST:IsBusy()
    return self.timer.running or self.watch.running or self.xp.running or self.gold.running or self.gather.running or self.reminder.set or self.breakTimer.running
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
    if self.breakTimer.running and not needFast then
        interval = 1
    end
    if self:IsLoggingVisible() and not needFast then interval = 1 end

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
    self:CheckBreakReminder()
    if self:IsLoggingVisible() then self:UpdateLoggingDisplay() end
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
    f:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
    f:RegisterEvent("QUEST_TURNED_IN")
    f:RegisterEvent("BAG_UPDATE")
    pcall(function()
        f:RegisterEvent("BAG_UPDATE_DELAYED")
    end)
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGOUT" then
            self:SaveDB()
        elseif event == "PLAYER_MONEY" then
            self:OnMoneyUpdate()
        elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
            self:OnXPUpdate()
        elseif event == "PLAYER_ENTERING_WORLD" then
            self:OnPlayerEnteringWorld()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if self.OnGatherSpell then
                self:OnGatherSpell(...)
            end
        elseif event == "CHAT_MSG_LOOT" then
            if self.OnGatherLoot then
                self:OnGatherLoot(...)
            end
        elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
            if self.OnCombatXPGain then
                self:OnCombatXPGain(...)
            end
        elseif event == "QUEST_TURNED_IN" then
            if self.OnQuestTurnedIn then
                self:OnQuestTurnedIn(...)
            end
        elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
            if self.ScheduleShopBagRefresh then
                self:ScheduleShopBagRefresh()
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
            self:SaveDB()
        end)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    AddCheck("sound", "Play alert sounds", "Play a sound when a timer or reminder fires.", true)
    AddCheck("chat", "Chat messages", "Print timer, reminder, and load messages in chat.", true)

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

-- Forever windows use DefaultPanelTemplate (brown metal nine-slice).
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

function ST:LayoutColumnButtons(parent, ...)
    local btns = { ... }
    local function layout()
        local pw = parent:GetWidth() or 120
        local width = math.min(112, math.max(64, pw - 8))
        local height, gap, bottom = 20, 3, 4
        local y = bottom
        for i = #btns, 1, -1 do
            local btn = btns[i]
            btn:SetSize(width, height)
            btn:ClearAllPoints()
            btn:SetPoint("BOTTOM", parent, "BOTTOM", 0, y)
            y = y + height + gap
        end
    end
    if not parent.stColumnButtonsHooked then
        parent.stColumnButtonsHooked = true
        parent:HookScript("OnSizeChanged", layout)
    end
    layout()
end

function ST:SplitColumns(parent, count)
    local cols = {}
    for i = 1, count do
        cols[i] = CreateFrame("Frame", nil, parent)
    end
    local dividers = {}
    for i = 1, count - 1 do
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(0.78, 0.58, 0.28, 0.28)
        line:SetWidth(1)
        dividers[i] = line
    end
    local function layout()
        local width = parent:GetWidth() or 400
        local gap = 10
        local colW = math.max(80, (width - gap * (count - 1)) / count)
        for i, col in ipairs(cols) do
            local x = (i - 1) * (colW + gap)
            col:ClearAllPoints()
            col:SetPoint("TOPLEFT", x, 0)
            col:SetPoint("BOTTOMLEFT", x, 0)
            col:SetWidth(colW)
        end
        for i, line in ipairs(dividers) do
            local x = i * colW + (i - 1) * gap + gap / 2
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -4)
            line:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, 4)
        end
    end
    parent:HookScript("OnSizeChanged", layout)
    layout()
    return cols
end

function ST:ApplyMainFrameSize(width, height)
    width = math.max(ST.FRAME_MIN_W, math.min(ST.FRAME_MAX_W, math.floor((width or ST.FRAME_W) + 0.5)))
    height = math.max(ST.FRAME_MIN_H, math.min(ST.FRAME_MAX_H, math.floor((height or ST.FRAME_H) + 0.5)))
    self.frameW, self.frameH = width, height
    if not self.frame then
        return
    end
    self.sizingApply = true
    self.frame:SetSize(width, height)
    self.sizingApply = false
    if self.OnMainFrameSizeChanged then
        self:OnMainFrameSizeChanged()
    end
end

function ST:PinFrameForResize(frame)
    if not frame then
        return
    end
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    local width, height = frame:GetWidth(), frame:GetHeight()
    if not left or not bottom or not width or not height then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    frame:SetSize(width, height)
end

function ST:AttachResizeGrip(frame, minW, minH, maxW, maxH, onStop)
    if not frame then
        return
    end
    if frame.ResizeButton then
        frame.ResizeButton:Hide()
        frame.ResizeButton:EnableMouse(false)
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
    if frame.resizeGrip then
        return frame.resizeGrip
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
        ST:PinFrameForResize(frame)
        if frame.SetResizeBounds then
            frame:SetResizeBounds(minW, minH, maxW, maxH)
        end
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        if ST.frame == frame then
            ST.frameW = frame:GetWidth()
            ST.frameH = frame:GetHeight()
        end
        if onStop then
            onStop()
        end
        ST:SaveDB()
    end)
    frame.resizeGrip = grip
    return grip
end
