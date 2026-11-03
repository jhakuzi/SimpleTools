-- Run from the repository root: lua5.1 tests/release.lua
-- Character sessions, gold load versus a real empty purse, shop search, links, logging.
local checks = 0
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
    checks = checks + 1
end
local function noop() end
local function widget()
    local self = { shown = true, text = "", scripts = {} }
    local methods = {}
    function methods:SetScript(name, fn) self.scripts[name] = fn end
    function methods:GetScript(name) return self.scripts[name] end
    function methods:SetText(value) self.text = value end
    function methods:GetText() return self.text end
    function methods:Show() self.shown = true end
    function methods:Hide()
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:IsShown() return self.shown end
    function methods:CreateFontString() return widget() end
    return setmetatable(self, {
        __index = function(_, key)
            return methods[key] or noop
        end,
    })
end
CreateFrame = function() return widget() end
GetTime = function() return 0 end
C_Timer = { After = function() end, NewTicker = function() return { Cancel = noop } end }
PlaySound = noop
strtrim = function(value) return (value or ""):match("^%s*(.-)%s*$") end
UIParent = {}
tinsert = table.insert
UISpecialFrames = {}
local guid
local money = 0
GetMoney = function() return money end
UnitGUID = function() return guid end
local ST = {}
for line in io.lines("SimpleTools.toc") do
    local file = line:match("^%s*(.-)%s*$")
    if file:match("%.lua$") then
        assert(loadfile(file))("SimpleTools", ST)
    end
end

SimpleToolsDB = nil
ST:InitDB()
ST.db.options.chat = false
ST.xp.gained = 500
ST.xp.elapsed = 10
ST.xp.startValue = 100
ST.xp.maxAtStart = 1000
ST.xp.running = true
ST.xp.anchor = 0
ST.gold.gained = 250
ST.gold.startValue = 1000
ST.gold.running = true
ST.gold.anchor = 0
ST.gather.running = true
ST.gather.elapsed = 12
ST.gather.nodes = 4
ST.gather.herbNodes = 4
ST.gather.anchor = 0
ST.gather.items = { [2447] = { name = "Peacebloom", count = 4, kind = "herb" } }
guid = "Player-A"
ST:BindCharacter()
equal(ST.db.trackerMigrated, true)
equal(ST.boundGuid, "Player-A")
equal(ST.db.characters["Player-A"].xp.gained, 500)
equal(ST.db.characters["Player-A"].xp.running, true)
equal(ST.db.characters["Player-A"].gold.gained, 250)
equal(ST.db.characters["Player-A"].gold.startValue, 1000)
equal(ST.db.characters["Player-A"].gather.nodes, 4)
equal(ST.db.characters["Player-A"].gather.items[2447].count, 4)

guid = "Player-B"
ST:BindCharacter()
equal(ST.xp.gained, 0)
equal(ST.xp.running, false)
equal(ST.gold.gained, 0)
equal(ST.gold.running, false)
equal(ST.gather.nodes, 0)
equal(ST.gather.running, false)
equal(ST.gather.items[2447], nil)
equal(ST.db.characters["Player-A"].xp.gained, 500)
equal(ST.db.characters["Player-A"].gold.running, true)
equal(ST.db.characters["Player-A"].gather.items[2447].count, 4)

guid = "Player-A"
ST:BindCharacter()
equal(ST.xp.gained, 500)
equal(ST.xp.running, true)
equal(ST.gold.gained, 250)
equal(ST.gold.running, true)
equal(ST.gold.startValue, 1000)
equal(ST.gather.nodes, 4)
equal(ST.gather.running, true)
equal(ST.gather.items[2447].count, 4)

-- Loading-screen 0 is not a transaction. The same balance reported twice is not either.
money = 0
ST:BeginGoldLoad()
ST:OnMoneyUpdate()
ST:ReconcileGold()
equal(ST.gold.startValue, 1000)
equal(ST.gold.gained, 250)
money = 1300
ST:OnMoneyUpdate()
ST:ReconcileGold()
equal(ST.gold.gained, 550)
equal(ST.gold.startValue, 1300)
ST:OnPlayerEnteringWorld()
equal(ST.gold.gained, 550)
equal(ST.gold.startValue, 1300)

-- /reload restores the running session, then a later real balance applies once.
ST.gold.startValue = 2000
ST.gold.gained = 10
ST.gold.running = true
ST:SaveDB()
ST.gold.running = false
ST.gold.gained = 0
ST.gold.startValue = 0
ST:ApplyTrackerRuntime({ gold = ST.db.characters["Player-A"].gold })
equal(ST.gold.running, true)
equal(ST.gold.startValue, 2000)
equal(ST.gold.gained, 10)
money = 0
ST:OnPlayerEnteringWorld()
equal(ST.gold.startValue, 2000)
equal(ST.gold.gained, 10)
money = 1800
ST:OnMoneyUpdate()
ST:OnPlayerEnteringWorld()
equal(ST.gold.startValue, 1800)
equal(ST.gold.gained, -190)
money = 0
ST:OnPlayerEnteringWorld()
equal(ST.gold.startValue, 1800)
equal(ST.gold.gained, -190)

-- Spending the last copper outside a load is real, and a second event does not apply it again.
ST.gold.suppressZero = false
money = 0
ST:OnMoneyUpdate()
equal(ST.gold.startValue, 0)
equal(ST.gold.gained, -1990)
ST:OnMoneyUpdate()
ST:ReconcileGold()
equal(ST.gold.gained, -1990)

-- A zero that stays zero through the load window is accepted once.
local pending = {}
C_Timer.After = function(_, fn) pending[#pending + 1] = fn end
money = 0
ST.gold.running = true
ST.gold.startValue = 400
ST.gold.gained = 5
ST:BeginGoldLoad()
ST:ReconcileGold()
equal(ST.gold.startValue, 400)
local guard = 0
while #pending > 0 and guard < 12 do
    local fn = table.remove(pending, 1)
    fn()
    guard = guard + 1
end
equal(ST.gold.startValue, 0)
equal(ST.gold.gained, 5 - 400)
equal(ST.gold.suppressZero, false)
ST:OnMoneyUpdate()
equal(ST.gold.gained, 5 - 400)

-- The confirm sample must not book a blip that has already recovered.
pending = {}
money = 0
ST.gold.startValue = 400
ST.gold.gained = 5
ST.gold.running = true
ST:BeginGoldLoad()
ST:ReconcileGold()
money = 900
guard = 0
while #pending > 0 and guard < 12 do
    local fn = table.remove(pending, 1)
    fn()
    guard = guard + 1
end
equal(ST.gold.startValue, 900)
equal(ST.gold.gained, 505)
equal(ST.gold.suppressZero, false)

-- Start, pause, and resume. A load-screen 0 cannot become the new baseline.
C_Timer.After = function() end
ST.goldStartPauseButton = { SetText = function(self, text) self.text = text end }
ST.gold.suppressZero = false
ST.gold.running = false
ST.gold.gained = 0
ST.gold.elapsed = 0
money = 1000
ST:StartGoldTracker()
equal(ST.gold.running, true)
equal(ST.gold.startValue, 1000)
equal(ST.goldStartPauseButton.text, "Pause")
money = 800
ST:OnMoneyUpdate()
equal(ST.gold.gained, -200)
equal(ST.gold.startValue, 800)
ST:PauseGoldTracker()
equal(ST.gold.running, false)
equal(ST.goldStartPauseButton.text, "Resume")
money = 700
ST:OnMoneyUpdate()
equal(ST.gold.gained, -200)
ST:StartGoldTracker()
equal(ST.gold.running, true)
equal(ST.gold.startValue, 700)
equal(ST.gold.gained, -200)
ST:PauseGoldTracker()
money = 0
ST:BeginGoldLoad()
ST:StartGoldTracker()
equal(ST.gold.running, false)
equal(ST.gold.startValue, 700)
ST.gold.suppressZero = false
money = 0
ST.gold.running = false
ST.gold.gained = 0
ST:StartGoldTracker()
equal(ST.gold.running, true)
equal(ST.gold.startValue, 0)

ST.gather.running = true
ST.gather.items = {}
local party = "Thrall receives loot: |cffffffff|Hitem:2447|h[Peacebloom]|h|rx2."
ST:OnGatherLoot(party)
equal(ST.gather.items[2447], nil)
local mine = "You receive loot: |cffffffff|Hitem:2447|h[Peacebloom]|h|rx2."
ST:OnGatherLoot(mine)
equal(ST.gather.items[2447].count, 2)

local function catalogNames(key)
    local names = {}
    for _, group in ipairs(ST:ShopCatalogGroups(ST.SHOP_PROFESSIONS[key])) do
        for _, mat in ipairs(group.mats) do
            names[#names + 1] = mat.name
        end
    end
    return names
end
local allAlchemy = catalogNames("alchemy")
equal(allAlchemy[1] ~= nil, true)
local foundPeace = false
for _, name in ipairs(allAlchemy) do
    if name == "Peacebloom" then foundPeace = true end
end
equal(foundPeace, true)

local query = ""
ST.shopSearchInput = { GetText = function() return query end }
query = "peace"
local filtered = catalogNames("alchemy")
equal(#filtered, 1)
equal(filtered[1], "Peacebloom")
query = "zzzz-no-such-herb"
equal(#catalogNames("alchemy"), 0)

query = ""
ST.shopProfOpen = nil
ST.shopProfMenu = nil
ST:ShowShopProfMenu("alchemy", nil)
local function openMats()
    local names = {}
    for _, row in ipairs(ST.shopProfMenu.rows) do
        local mat = rawget(row, "mat")
        if row.shown and type(mat) == "table" then
            names[#names + 1] = mat.name
        end
    end
    return names
end
equal(#openMats() > 1, true)
query = "peace"
ST:OnShopSearchChanged("peace")
local live = openMats()
equal(#live, 1)
equal(live[1], "Peacebloom")
query = "silverleaf"
ST:HideShopProfMenu()
equal(ST.shopProfOpen, nil)
ST:ShowShopProfMenu("alchemy", nil)
local reopened = openMats()
equal(#reopened, 1)
equal(reopened[1], "Silverleaf")
query = "nope"
ST:OnShopSearchChanged("nope")
equal(#openMats(), 0)
equal(ST.shopProfMenu.rows[1].text.text, "No matching reagents")

-- Native menus take the filter when opened again. Nothing is polled.
local built = {}
MenuUtil = {
    CreateContextMenu = function(_, builder)
        built = {}
        local root = {
            CreateTitle = function() end,
            SetScrollMode = function() end,
            CreateDivider = function() end,
            CreateButton = function(_, name) built[#built + 1] = name end,
        }
        builder(nil, root)
    end,
}
query = "peace"
ST:ToggleShopProfMenu("alchemy", {})
equal(#built, 1)
equal(built[1], "Peacebloom")
query = "earthroot"
ST:ToggleShopProfMenu("alchemy", {})
equal(#built, 1)
equal(built[1], "Earthroot")
MenuUtil = nil

local linked
ChatFrame_OpenChat = function(text) linked = text end
ST.selectedLocation = { name = "Vendor", zone = "Elwynn Forest", x = 0.25, y = 0.5, mapID = 1 }
equal(ST:LinkSelectedLocation(), true)
equal(linked, "Vendor — Elwynn Forest (25.0, 50.0)")
ST.selectedLocation = nil
equal(ST:LinkSelectedLocation(), false)

local inside = false
IsInInstance = function() return inside, inside and "party" or "none" end
local writes, enabled = 0, false
LoggingCombat = function(value)
    if value ~= nil then
        enabled = value
        writes = writes + 1
    end
    return enabled
end
ST.db.logging.autoStart = true
ST.loggingInside = false
inside = true
money = 1800
equal(ST:AutoStartCombatLogging(), true)
equal(writes, 1)
ST:OnPlayerEnteringWorld()
equal(writes, 1)
equal(enabled, true)
inside = false
ST.loggingInside = true
ST:OnPlayerEnteringWorld()
equal(writes, 1)
equal(enabled, true)
enabled = false
inside = true
ST.loggingInside = false
ST:OnPlayerEnteringWorld()
equal(writes, 2)
equal(enabled, true)
ST:OnPlayerEnteringWorld()
equal(writes, 2)

print(string.format("PASS: %d release assertions", checks))
