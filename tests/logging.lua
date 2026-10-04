-- Run from the repository root: lua5.1 tests/logging.lua
-- Reuse frame/game stubs, then restore the actual logging UI constructor.
dofile('tests/new-tools.lua')
local ST = SimpleTools
assert(loadfile('SimpleLogging.lua'))('SimpleTools', ST)
local checks, enabled, writes = 0, false, 0
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    checks = checks + 1
end
LoggingCombat = function(value)
    if value ~= nil then enabled = value; writes = writes + 1 end
    return enabled
end
local frame = ST:CreateLoggingUI(ST.contentFrame)
ST.tabFrames[8] = frame
ST:SelectTab(8)
equal(ST.loggingStatus.text, 'Logging: Stopped')
equal(ST.loggingToggleButton.enabled, true)
equal(writes, 0)
ST.loggingToggleButton.scripts.OnClick()
equal(enabled, true)
equal(ST.loggingStatus.text, 'Logging: Running')
equal(ST.loggingToggleButton.text, 'Stop logging')
ST:ShowLoggingProjected(true)
equal(ST.loggingProjectedFrame.shown, true)
equal(ST.loggingProjStatus.text, 'Logging: Running')
equal(ST.loggingProjButton.text, 'Stop logging')
equal(ST.tickerInterval, 1)
ST.loggingProjButton.scripts.OnClick()
equal(enabled, false)
equal(ST.loggingStatus.text, 'Logging: Stopped')
equal(ST.loggingProjStatus.text, 'Logging: Stopped')
-- External changes are detected while projected, even on a different tab.
ST:SelectTab(1)
enabled = true
ST:OnTick()
equal(ST.loggingProjStatus.text, 'Logging: Running')
local before = writes
ST.loggingProjectedFrame.closeButton.scripts.OnClick()
equal(ST.loggingProjected, false)
equal(enabled, true)
equal(writes, before)
equal(ST.ticker, nil)
-- Restore only overlay preferences, never a stored logging command.
ST:ShowLoggingProjected(true)
ST.loggingProjectedFrame:SetPoint('CENTER', UIParent, 'CENTER', 12, 34)
ST:SaveDB()
equal(ST.db.logging.projX, 12)
equal(ST.db.logging.projY, 34)
enabled = false
before = writes
ST:LoadState()
equal(writes, before)
equal(enabled, false)
equal(ST.loggingProjectedFrame.shown, true)
equal(ST.loggingProjStatus.text, 'Logging: Stopped')
equal(ST.loggingProjectedFrame.point[4], 12)
-- Unsupported or failed APIs never show a guessed running state.
LoggingCombat = nil
ST:UpdateLoggingDisplay()
equal(ST.loggingProjStatus.text, 'Logging unavailable')
equal(ST.loggingProjButton.enabled, false)
equal(ST:ToggleCombatLogging(), false)
LoggingCombat = function() error('Unavailable') end
equal(ST:GetLoggingState(), nil)
equal(ST:ToggleCombatLogging(), false)
LoggingCombat = function(value) return false end
equal(ST:ToggleCombatLogging(), false)
equal(ST.loggingStatus.text, 'Logging: Stopped')
-- Automatic logging is opt-in and restricted to dungeon/raid entry.
local instanceType = 'none'
IsInInstance = function() return instanceType ~= 'none', instanceType end
LoggingCombat = function(value)
    if value ~= nil then enabled = value; writes = writes + 1 end
    return enabled
end
enabled = false
ST.db.logging.autoStart = false
before = writes
instanceType = 'party'
equal(ST:AutoStartCombatLogging(), false)
equal(writes, before)
ST.loggingAutoButton.scripts.OnClick()
equal(ST.db.logging.autoStart, true)
equal(enabled, true)
equal(ST.loggingAutoButton.text, 'Auto logging: On')
before = writes
ST:AutoStartCombatLogging()
equal(writes, before)
ST.loggingAutoButton.scripts.OnClick()
equal(ST.db.logging.autoStart, false)
equal(enabled, true)
ST.db.logging.autoStart = true
for _, kind in ipairs({'none', 'pvp', 'arena', 'scenario'}) do
    instanceType = kind
    enabled = false
    before = writes
    equal(ST:AutoStartCombatLogging(), false)
    equal(writes, before)
end
-- Exercise the actual event handler, not just the helper.
ST:RegisterEvents()
instanceType = 'raid'
enabled = false
ST.eventFrame.scripts.OnEvent(ST.eventFrame, 'PLAYER_ENTERING_WORLD')
equal(enabled, true)
instanceType = 'none'
ST.eventFrame.scripts.OnEvent(ST.eventFrame, 'PLAYER_ENTERING_WORLD')
equal(enabled, true)
ST:SaveDB()
ST:LoadState()
equal(ST.db.logging.autoStart, true)
LoggingCombat = function() error('Unavailable') end
instanceType = 'party'
equal(ST:AutoStartCombatLogging(), false)
print(string.format('PASS: %d logging assertions', checks))
