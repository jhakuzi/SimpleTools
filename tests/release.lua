-- Run from the repository root: lua5.1 tests/release.lua
-- Character sessions, gold rebase, own loot, shop search, and chat links.
local checks = 0
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    checks = checks + 1
end
local function noop() end
local frame = setmetatable({}, { __index = function() return noop end })
CreateFrame = function() return frame end
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
ST.xp.running = false
ST.gold.gained = 250
ST.gold.startValue = 1000
ST.gold.running = true
ST.gold.anchor = 0
guid = "Player-A"
ST:BindCharacter()
equal(ST.db.trackerMigrated, true)
equal(ST.boundGuid, "Player-A")
equal(ST.db.characters["Player-A"].xp.gained, 500)
equal(ST.db.characters["Player-A"].gold.gained, 250)
equal(ST.db.characters["Player-A"].gold.startValue, 1000)

guid = "Player-B"
ST:BindCharacter()
equal(ST.xp.gained, 0)
equal(ST.gold.gained, 0)
equal(ST.gold.running, false)
equal(ST.db.characters["Player-A"].xp.gained, 500)

guid = "Player-A"
ST:BindCharacter()
equal(ST.xp.gained, 500)
equal(ST.gold.gained, 250)
equal(ST.gold.running, true)
equal(ST.gold.startValue, 1000)

money = 0
ST.gold.running = true
ST.gold.startValue = 1000
ST.gold.gained = 50
ST:ReconcileGold()
equal(ST.gold.startValue, 1000)
equal(ST.gold.gained, 50)
money = 1300
ST:ReconcileGold()
equal(ST.gold.gained, 350)
equal(ST.gold.startValue, 1300)

ST.gather.running = true
ST.gather.items = {}
local party = "Thrall receives loot: |cffffffff|Hitem:2447|h[Peacebloom]|h|rx2."
ST:OnGatherLoot(party)
equal(ST.gather.items[2447], nil)
local mine = "You receive loot: |cffffffff|Hitem:2447|h[Peacebloom]|h|rx2."
ST:OnGatherLoot(mine)
equal(ST.gather.items[2447].count, 2)

local found = false
for _, group in ipairs(ST:ShopCatalogGroups(ST.SHOP_PROFESSIONS.alchemy)) do
    for _, mat in ipairs(group.mats) do
        if mat.name == "Peacebloom" then found = true end
    end
end
equal(found, true)
ST.shopSearchText = "peace"
local names = 0
for _, group in ipairs(ST:ShopCatalogGroups(ST.SHOP_PROFESSIONS.alchemy)) do
    for _, mat in ipairs(group.mats) do
        names = names + 1
        equal(mat.name, "Peacebloom")
    end
end
equal(names, 1)

ST.frame = { IsShown = function() return true end }
ST.shopFrame = ST.frame
ST.shopQtyFrame = { IsShown = function() return true end }
equal(ST:TryCaptureShopLink("|cffffffff|Hitem:2447|h[Peacebloom]|h|r"), false)
ST.shopQtyFrame = { IsShown = function() return false end }
equal(ST:TryCaptureShopLink("not an item"), false)

local linked
ChatFrame_OpenChat = function(text) linked = text end
ST.selectedLocation = { name = "Vendor", zone = "Elwynn Forest", x = 0.25, y = 0.5, mapID = 1 }
equal(ST:LinkSelectedLocation(), true)
equal(linked, "Vendor — Elwynn Forest (25.0, 50.0)")

local inside = false
IsInInstance = function() return inside, inside and "party" or "none" end
local writes, enabled = 0, false
LoggingCombat = function(value)
    if value ~= nil then enabled = value; writes = writes + 1 end
    return enabled
end
ST.db.logging.autoStart = true
ST.loggingInside = false
inside = true
equal(ST:AutoStartCombatLogging(), true)
equal(writes, 1)
equal(ST:AutoStartCombatLogging(), false)
equal(writes, 1)
inside = false
equal(ST:AutoStartCombatLogging(), false)
enabled = false
inside = true
equal(ST:AutoStartCombatLogging(), true)
equal(writes, 2)

print(string.format("PASS: %d release assertions", checks))
