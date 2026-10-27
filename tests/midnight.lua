-- Run from the repository root with Lua 5.1.
-- Check client manifests and exercise secret-value fallbacks with mocked APIs.
dofile('tests/new-tools.lua')
local ST = SimpleTools
local function read(path)
    local f = assert(io.open(path)); local value = f:read('*a'); f:close(); return value
end
local retail, forever = read('SimpleTools.toc'), read('SimpleTools_Camelot.toc')
assert(retail:match('## Interface: 120107'))
assert(retail:match('## Interface%-Camelot: 16001'))
assert(not retail:match('## AllowLoadGameType: camelot'))
assert(forever:match('## Interface: 16001'))
assert(forever:match('## AllowLoadGameType: camelot'))
local function files(toc)
    local result = {}
    for line in toc:gmatch('[^\r\n]+') do if line:match('%.lua$') then result[#result+1] = line end end
    return table.concat(result, '\n')
end
assert(files(retail) == files(forever), 'Both clients must load the same addon modules')
local secret = {}
local original = ST.IsSecret
ST.IsSecret = function(_, value) return value == secret end
C_Map.GetBestMapForUnit = function() return secret end
assert(ST:GetCurrentLocation() == nil)
C_Map.GetBestMapForUnit = function() return 42 end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return secret, 0.5 end } end
assert(ST:GetCurrentLocation() == nil)
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return 0.5, 0.5 end } end
C_Map.GetMapInfo = function() return {name = secret} end
assert(ST:GetCurrentLocation().zone == 'Unknown zone')
C_Timer.After = function(_, callback) callback() end
ST.gather.running = true
ST.gather.partial = false
ST:OnGatherLoot(secret)
assert(ST.gather.partial and ST.db.gather.partial)
ST.gather.partial = false
ST:OnGatherSpell("player", nil, secret)
assert(ST.gather.partial)
C_Item = {GetItemInfoInstant = function() return secret end}
local _, _, unavailable = ST:ClassifyGatherItem("item:765")
assert(unavailable)
LoggingCombat = function() return secret end
assert(ST:GetLoggingState() == nil)
ST.IsSecret = original
print('PASS: Midnight manifests and secret-value fallbacks')
