-- Run from the repository root: lua5.1 tests/regression.lua
-- These focused UI stubs validate callbacks and state, not the WoW client.
local checks = 0
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    checks = checks + 1
end
local function noop() end
local frame = setmetatable({Text = {SetFontObject = noop}}, {
    __index = function(_, key)
        if key == 'GetWidth' then return function() return 540 end end
        return noop
    end,
})
CreateFrame = function() return frame end
GetTime = function() return 0 end
C_Timer = {NewTicker = function() return {Cancel = noop} end}
UISpecialFrames, tinsert = {}, table.insert
local ST = {}
for line in io.lines('SimpleTools.toc') do
    local file = line:match('^%s*(.-)%s*$')
    if file:match('%.lua$') then assert(loadfile(file))('SimpleTools', ST) end
end
ST.CreateThemedPanel = function() return frame end
for _, name in ipairs({'ApplyMainFrameSize', 'SetPanelTitle', 'EnsurePanelClose',
    'AttachResizeGrip', 'LayoutTabButtons', 'UpdateXPTracker', 'UpdateGoldTracker',
    'UpdateGatherTracker'}) do
    ST[name] = noop
end
for _, name in ipairs({'CreateTimeTab', 'CreateXPGoldTab', 'CreateSimpleGatherUI',
    'CreateSimpleNotepadUI', 'CreateSimpleShopUI'}) do
    ST[name] = function() return frame end
end
-- Exercise both frame construction and the real restoration path for every tab.
for tab = 1, 5 do
    SimpleToolsDB = {version = 2, ui = {selectedTab = tab, tabs = 'v2'}}
    ST:InitDB()
    ST:CreateMainFrame()
    equal(ST.db.ui.selectedTab, tab)
    ST:LoadState()
    equal(ST.db.ui.selectedTab, tab)
end
SimpleToolsDB = nil
ST:InitDB()
ST:CreateMainFrame()
ST:LoadState()
equal(ST.db.ui.selectedTab, 1)
ST:SelectTab(4)
equal(ST.db.ui.selectedTab, 4)

local commits
ST.SaveDB = function() commits = commits + 1 end
local function editList()
    commits = 0
    ST.shopItems = {{id=1,name='First',count=1},
        {id=2,name='Second',count=2}, {id=3,name='Third',count=3}}
    local box = {scripts = {}, focused = false}
    function box:SetScript(name, fn) self.scripts[name] = fn end
    function box:GetText() return self.value end
    function box:SetText(value) self.value = value end
    function box:SetFocus()
        self.focused = true
        self.scripts.OnEditFocusGained(self)
    end
    function box:ClearFocus()
        if not self.focused then return end
        self.focused = false
        self.scripts.OnEditFocusLost(self)
    end
    local row = {index = 1, entry = ST.shopItems[1], qty = box}
    ST.RefreshShopList = function(self)
        row.entry = self.shopItems[row.index]
        if not box.focused and row.entry then box.value = tostring(row.entry.count) end
    end
    ST:BindShopQty(row)
    box:SetFocus()
    return box, row
end
local box = editList()
box.value = '0'
box.scripts.OnEnterPressed(box)
equal(#ST.shopItems, 2)
equal(ST.shopItems[1].name, 'Second')
equal(ST.shopItems[1].count, 2)
equal(commits, 1)
box = editList()
box.value = '8'
box.scripts.OnEnterPressed(box)
equal(ST.shopItems[1].count, 8)
equal(commits, 1)
box = editList()
box.value = '7'
box:ClearFocus()
equal(ST.shopItems[1].count, 7)
equal(commits, 1)
box = editList()
box.value = '99'
box.scripts.OnEscapePressed(box)
equal(ST.shopItems[1].count, 1)
equal(commits, 0)
box = editList()
box.value = ''
box.scripts.OnEnterPressed(box)
equal(#ST.shopItems, 3)
equal(ST.shopItems[1].count, 1)
-- If an edited item is removed elsewhere, focus loss cannot edit its replacement.
box = editList()
box.value = '0'
ST:RemoveShopItem(1)
box:ClearFocus()
equal(#ST.shopItems, 2)
equal(ST.shopItems[1].name, 'Second')
equal(commits, 1)
-- An edited item retains its identity when a preceding row is removed.
local row
box, row = editList()
box:ClearFocus()
row.index, row.entry = 2, ST.shopItems[2]
box:SetFocus()
box.value = '9'
ST:RemoveShopItem(1)
box:ClearFocus()
equal(ST.shopItems[1].name, 'Second')
equal(ST.shopItems[1].count, 9)
equal(ST.shopItems[2].count, 3)
print(string.format('PASS: %d regression assertions', checks))
