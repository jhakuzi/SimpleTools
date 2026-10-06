-- Run from the repository root: lua5.1 tests/new-tools.lua
-- Game API and frame stubs; real new-tool UI constructors, state and callbacks.
local checks, now, alerts = 0, 0, 0
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    checks = checks + 1
end
local methods = {}
local function widget()
    return setmetatable({scripts={}, shown=true, enabled=true, width=540, height=240, text=''}, {__index=methods})
end
for _, name in ipairs({'SetAllPoints','SetMovable','EnableMouse','SetClampedToScreen',
    'SetFrameStrata','RegisterForDrag','RegisterForClicks','SetNormalFontObject',
    'SetFontObject','SetJustifyH','SetTextColor','SetWordWrap','SetHighlightTexture',
    'SetAutoFocus','SetNumeric','SetMaxLetters','EnableMouseWheel','SetBackdrop',
    'SetBackdropColor','SetBackdropBorderColor','SetResizable','SetResizeBounds',
    'SetNormalTexture','SetPushedTexture','SetFrameLevel','StartMoving','StopMovingOrSizing',
    'StartSizing','RegisterEvent','UnregisterEvent','HighlightText'}) do
    methods[name] = function() end
end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:GetPoint() if self.point then return unpack(self.point) end end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:HookScript(name,fn)
    local previous=self.scripts[name]
    self.scripts[name]=function(...) if previous then previous(...) end; fn(...) end
end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown=value end
function methods:SetEnabled(value) self.enabled=value end
function methods:Disable() self.enabled=false end
function methods:Enable() self.enabled=true end
function methods:SetFocus() self.focused=true end
function methods:ClearFocus() self.focused=false end
function methods:HasFocus() return self.focused end
function methods:CreateFontString() return widget() end
function methods:GetFrameLevel() return 1 end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScrollRange() return 100 end
function methods:SetScrollChild(child) self.child=child end
CreateFrame=widget
GetTime=function() return now end
C_Timer={NewTicker=function(interval,callback) return {Cancel=function() end,callback=callback,interval=interval} end}
PlaySound=function() alerts=alerts+1 end
GameTooltip_Hide=function() end
strtrim=function(value) return value:match('^%s*(.-)%s*$') end
UISpecialFrames,tinsert={},table.insert
UIParent=widget()
local ST={}
local count=0
for line in io.lines('SimpleTools.toc') do
    local file=line:match('^%s*(.-)%s*$')
    if file:match('%.lua$') then assert(loadfile(file))('SimpleTools',ST); count=count+1 end
end
equal(count,15)
-- Build the actual main frame and the two new panels; stub only old tab constructors.
for _,name in ipairs({'CreateTimeTab','CreateXPGoldTab','CreateSimpleGatherUI','CreateSimpleNotepadUI','CreateSimpleShopUI','CreateLoggingUI','CreateCalculatorUI','CreateChecklistUI'}) do
    ST[name]=function() return widget() end
end
ST:InitDB()
ST.db.options.chat=false
ST:CreateMainFrame()
ST:LoadState()
equal(#ST.tabFrames,10)
equal(ST.locationMapButton.enabled,false)
equal(ST.breakSnoozeButton.enabled,false)
-- Tabs fit on one row even at the minimum frame width.
ST.frame:SetWidth(480)
ST:LayoutTabButtons()
local right=0
for _,button in ipairs(ST.tabButtons) do
    assert(button.point[5] == -30 or button.point[5] == -51); checks=checks+1
    right=math.max(right,button.point[4]+button.width)
end
assert(right <= 480); checks=checks+1
ST:SelectTab(6)
equal(ST.db.ui.selectedTab,6)
ST:SelectTab(7)
equal(ST.db.ui.selectedTab,7)
-- Locations: absence, save, navigation, copies, persistence, unbounded scrolling.
equal(ST:SaveCurrentLocation('No map'),false)
equal(#ST.locationBookmarks,0)
C_Map={GetBestMapForUnit=function() return 42 end,
    GetPlayerMapPosition=function() return {GetXY=function() return 0.25,0.75 end} end,
    GetMapInfo=function() return {name='Test Zone'} end}
equal(ST:SaveCurrentLocation('  Vendor  '),true)
local entry=ST.locationBookmarks[1]
equal(entry.name,'Vendor')
equal(entry.mapID,42)
equal(entry.x,0.25)
equal(ST.db.locations.bookmarks[1].name,'Vendor')
assert(ST.db.locations.bookmarks[1]~=entry); checks=checks+1
equal(ST.locationMapButton.enabled,true)
local marker,tracked
C_Map.SetUserWaypoint=function(point) marker=point end
C_Map.CanSetUserWaypointOnMap=function() return true end
UiMapPoint={CreateFromCoordinates=function(mapID,x,y) return {mapID=mapID,x=x,y=y} end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function(value) tracked=value end}
WorldMapFrame=widget()
WorldMapFrame.SetMapID=function(self,mapID) self.mapID=mapID end
equal(ST:ShowSelectedLocation(),true)
equal(marker.mapID,42)
equal(marker.y,0.75)
equal(tracked,true)
equal(WorldMapFrame.mapID,42)
C_Map.CanSetUserWaypointOnMap=function() return false end
marker=nil
equal(ST:ShowSelectedLocation(),true)
equal(marker,nil)
WorldMapFrame=nil
equal(ST:ShowSelectedLocation(),false)
C_Map.GetPlayerMapPosition=function() return nil end
equal(ST:SaveCurrentLocation('Instance'),false)
equal(#ST.locationBookmarks,1)
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return 0.25,0.75 end} end
equal(ST:SaveCurrentLocation('  '),true)
equal(ST.locationBookmarks[2].name,'Test Zone')
ST:RemoveSelectedLocation()
equal(#ST.locationBookmarks,1)
equal(ST.locationMapButton.enabled,false)
ST.locationRows[1].scripts.OnClick(ST.locationRows[1])
equal(ST.selectedLocation,entry)
equal(ST.locationMapButton.enabled,true)
local clean=ST:CopyLocationBookmarks({entry,{mapID=42,x=2,y=0},{mapID=42,x=0/0,y=0},false})
equal(#clean,1)
for i=2,45 do ST.locationBookmarks[i]={name='Spot '..i,zone='Zone',mapID=42,x=0.1,y=0.2} end
ST:RefreshLocationList()
equal(#ST.locationRows,45)
equal(ST.locationRows[45].shown,true)
equal(ST.locationListChild.height,45*22)
-- Breaks: single alert, pause/resume, snooze, reload and stop.
ST.breakIntervalInput:SetText('1')
ST.breakSnoozeInput:SetText('2')
equal(ST:StartBreakReminder(),true)
equal(ST.breakTimer.remaining,60)
equal(ST.tickerInterval,1)
now=20
ST:ToggleBreakReminder()
equal(ST.breakTimer.remaining,40)
equal(ST.breakTimer.running,false)
now=50
ST:ToggleBreakReminder()
equal(ST.breakTimer.remaining,40)
now=91
ST:OnTick()
equal(ST.breakTimer.due,true)
equal(ST.breakTimer.running,false)
equal(ST.breakAlertFrame.shown,true)
equal(alerts,1)
ST:OnTick()
equal(alerts,1)
equal(ST:StartBreakReminder(true),true)
equal(ST.breakTimer.remaining,120)
equal(ST.breakAlertFrame.shown,false)
now=101
ST:SaveDB()
equal(ST.db.breakReminder.remaining,110)
ST:LoadBreakState(ST.db.breakReminder)
equal(ST:BreakRemaining(),110)
now=211
ST:OnTick()
equal(alerts,2)
equal(ST.db.breakReminder.due,true)
ST:LoadBreakState(ST.db.breakReminder)
equal(ST.breakAlertFrame.shown,true)
equal(alerts,2)
equal(ST:StartBreakReminder(),true)
equal(ST.breakTimer.remaining,60)
ST:StopBreakReminder()
equal(ST.breakTimer.remaining,0)
equal(ST.breakTimer.due,false)
equal(ST.breakAlertFrame.shown,false)
equal(ST.ticker,nil)
ST.breakIntervalInput:SetText('0')
equal(ST:StartBreakReminder(),false)
ST.breakIntervalInput:SetText('241')
equal(ST:StartBreakReminder(),false)
ST.breakIntervalInput:SetText('abc')
equal(ST:StartBreakReminder(),false)
ST.breakIntervalInput:SetText('1.5')
equal(ST:StartBreakReminder(),false)
-- Real SaveDB/LoadState retain new state and selected tab without saved clocks.
ST.breakIntervalInput:SetText('1')
ST:StartBreakReminder()
now=221
ST:SaveDB()
equal(ST.db.breakReminder.anchor,nil)
equal(ST.db.breakReminder.remaining,50)
ST.locationBookmarks={}
ST:LoadState()
equal(#ST.locationBookmarks,45)
equal(ST.db.ui.selectedTab,7)
equal(ST:BreakRemaining(),50)
-- A break reminder must not slow an existing fast tracker or stop its ticker.
ST.watch.running=true
ST.watch.anchor=now
ST:RefreshTicker()
equal(ST.tickerInterval,0.25)
ST:StopBreakReminder()
equal(ST.tickerInterval,0.25)
-- The due alert's close callback really stops the reminder.
ST.watch.running=false
ST.breakIntervalInput:SetText('1')
ST:StartBreakReminder()
now=281
ST:OnTick()
ST.breakAlertFrame.closeButton.scripts.OnClick()
equal(ST.breakTimer.due,false)
equal(ST.breakTimer.running,false)
equal(ST.breakAlertFrame.shown,false)
equal(ST.ticker,nil)
print(string.format('PASS: %d new-tool assertions',checks))
