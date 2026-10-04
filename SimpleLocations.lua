local addonName, ST = ...
local CreateFrame = CreateFrame

local function ValidPosition(mapID, x, y)
    return type(mapID) == "number" and mapID > 0 and mapID < math.huge and mapID == math.floor(mapID)
        and type(x) == "number" and x >= 0 and x <= 1
        and type(y) == "number" and y >= 0 and y <= 1
end

function ST:CopyLocationBookmarks(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for _, entry in ipairs(source) do
        if type(entry) == "table" and ValidPosition(entry.mapID, entry.x, entry.y) then
            result[#result + 1] = {
                name = type(entry.name) == "string" and entry.name or "Bookmark",
                zone = type(entry.zone) == "string" and entry.zone or "Unknown zone",
                mapID = entry.mapID, x = entry.x, y = entry.y,
            }
        end
    end
    return result
end

function ST:GetCurrentLocation()
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return nil end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end
    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then return nil end
    local x, y = position:GetXY()
    if not ValidPosition(mapID, x, y) then return nil end
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return { mapID = mapID, x = x, y = y, zone = info and info.name or "Unknown zone" }
end

function ST:SaveCurrentLocation(name)
    local entry = self:GetCurrentLocation()
    if not entry then
        self:Print("Your location is unavailable here. Try outdoors in a mapped zone.")
        if self.locationStatus then self.locationStatus:SetText("Location unavailable here. Try a mapped zone.") end
        return false
    end
    name = strtrim(type(name) == "string" and name or "")
    entry.name = name ~= "" and name or entry.zone
    self.locationBookmarks[#self.locationBookmarks + 1] = entry
    self.selectedLocation = entry
    self:RefreshLocationList()
    if self.locationScroll then
        self.locationScroll:SetVerticalScroll(self.locationScroll:GetVerticalScrollRange())
    end
    self:SaveDB()
    return true
end

function ST:RemoveSelectedLocation()
    for index, entry in ipairs(self.locationBookmarks) do
        if entry == self.selectedLocation then
            table.remove(self.locationBookmarks, index)
            self.selectedLocation = nil
            self:RefreshLocationList()
            self:SaveDB()
            return
        end
    end
end

function ST:ShowSelectedLocation()
    local entry = self.selectedLocation
    if not entry then return false end
    local waypoint = C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates
        and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(entry.mapID))
    if waypoint then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(entry.mapID, entry.x, entry.y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end
    if not WorldMapFrame then
        local loadAddon = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
        if loadAddon then loadAddon("Blizzard_WorldMap") end
    end
    if WorldMapFrame and WorldMapFrame.SetMapID then
        WorldMapFrame:Show()
        WorldMapFrame:SetMapID(entry.mapID)
    elseif not waypoint then
        self:Print("Map navigation is unavailable on this client.")
        if self.locationStatus then self.locationStatus:SetText("Map navigation is unavailable on this client.") end
        return false
    end
    if self.locationStatus then
        self.locationStatus:SetText(waypoint and "Waypoint set. Follow the map marker." or "Map opened; waypoints are unavailable in this zone.")
    end
    return true
end

function ST:RefreshLocationList()
    if not self.locationListChild then return end
    local rows, list = self.locationRows, self.locationBookmarks
    for i = 1, math.max(#list, #rows) do
        local row = rows[i]
        local entry = list[i]
        if entry then
            if not row then
                row = CreateFrame("Button", nil, self.locationListChild)
                row:SetHeight(22)
                row:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
                row:SetPoint("TOPRIGHT", 0, -(i - 1) * 22)
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.text:SetPoint("LEFT", 4, 0)
                row.text:SetPoint("RIGHT", -4, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetWordWrap(false)
                row:SetScript("OnClick", function(selfRow)
                    ST.selectedLocation = selfRow.entry
                    ST:RefreshLocationList()
                end)
                rows[i] = row
            end
            row.entry = entry
            row.text:SetText(string.format("%s  ·  %s  (%.1f, %.1f)", entry.name, entry.zone, entry.x * 100, entry.y * 100))
            if entry == self.selectedLocation then
                row.text:SetTextColor(1, 0.82, 0)
            else
                row.text:SetTextColor(0.9, 0.9, 0.9)
            end
            row:Show()
        elseif row then
            row.entry = nil
            row:Hide()
        end
    end
    self.locationEmpty:SetShown(#list == 0)
    self.locationListChild:SetHeight(math.max(20, #list * 22))
    self.locationMapButton:SetEnabled(self.selectedLocation ~= nil)
    self.locationRemoveButton:SetEnabled(self.selectedLocation ~= nil)
end

function ST:CreateLocationsUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 8, -7)
    label:SetText("Name")
    local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    input:SetHeight(20)
    input:SetPoint("TOPLEFT", 50, -2)
    input:SetPoint("TOPRIGHT", -132, -2)
    input:SetAutoFocus(false)
    input:SetMaxLetters(48)
    local function save()
        if ST:SaveCurrentLocation(input:GetText()) then
            input:SetText("")
            input:ClearFocus()
        end
    end
    input:SetScript("OnEnterPressed", save)
    input:SetScript("OnEscapePressed", function(selfBox) selfBox:ClearFocus() end)
    local saveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    saveButton:SetSize(112, 22)
    saveButton:SetPoint("TOPRIGHT", -8, -2)
    saveButton:SetText("Save here")
    saveButton:SetScript("OnClick", save)
    self.locationStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.locationStatus:SetPoint("TOPLEFT", 8, -28)
    self.locationStatus:SetPoint("TOPRIGHT", -8, -28)
    self.locationStatus:SetJustifyH("LEFT")
    self.locationStatus:SetText("Save your position, then select a bookmark to show on the map.")
    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 8, -46)
    box:SetPoint("BOTTOMRIGHT", -8, 38)
    self:ApplyOverlayBackdrop(box)
    local scroll = CreateFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", 6, -4)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfScroll, delta)
        selfScroll:SetVerticalScroll(math.max(0, math.min(selfScroll:GetVerticalScrollRange(), selfScroll:GetVerticalScroll() - delta * 22)))
    end)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(400, 20)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(_, width) child:SetWidth(math.max(1, width)) end)
    self.locationListChild, self.locationRows = child, {}
    self.locationScroll = scroll
    self.locationEmpty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.locationEmpty:SetPoint("TOPLEFT", 4, -4)
    self.locationEmpty:SetText("No bookmarks yet. Save a vendor, gathering spot, or meeting place.")
    self.locationMapButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.locationMapButton:SetText("Show on map")
    self.locationMapButton:SetScript("OnClick", function() ST:ShowSelectedLocation() end)
    self.locationRemoveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.locationRemoveButton:SetText("Remove")
    self.locationRemoveButton:SetScript("OnClick", function() ST:RemoveSelectedLocation() end)
    self:LayoutBottomPair(frame, self.locationMapButton, self.locationRemoveButton)
    self:RefreshLocationList()
    return frame
end
