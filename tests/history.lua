dofile('tests/new-tools.lua')
local ST = SimpleTools
date = function() return '2026-10-27 12:00' end
ST.db.history = {}
local gather = {nodes = 10, partial = true, items = {[1]={name='Copper',count=5}}}
ST:RecordTrackerSession('gather', gather, 1800)
assert(#ST.db.history == 1 and ST.db.history[1].rate == 20)
assert(ST.db.history[1].partial and ST.db.history[1].items[1].count == 5)
gather.items[1].count = 99
assert(ST.db.history[1].items[1].count == 5)
ST:RecordTrackerSession('xp', {gained=100, partial=true}, 60)
assert(ST.db.history[1].gained == 100 and ST.db.history[1].rate == 6000 and ST.db.history[1].partial)
ST:RecordTrackerSession('gold', {gained=-50}, 0)
assert(#ST.db.history == 2)
ST:SaveDB()
ST:LoadState()
assert(#ST.db.history == 2 and ST.db.history[2].items[1].count == 5)
for i=1,105 do ST:RecordTrackerSession('gold', {gained=i}, 60) end
assert(#ST.db.history == 100)
print('PASS: session history snapshots, partial data, persistence and limit')
