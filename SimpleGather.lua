local addonName, ST = ...

local GetTime = GetTime
local CreateFrame = CreateFrame

local KIND_HERB = "herb"
local KIND_ORE = "ore"
local KIND_SKIN = "leather"

-- Vanilla + later ranks. Names resolved at runtime so Forever locales still match.
local SPELL_KIND = {
    [2366] = KIND_HERB, [2368] = KIND_HERB, [3570] = KIND_HERB, [11993] = KIND_HERB,
    [28695] = KIND_HERB, [50300] = KIND_HERB, [74519] = KIND_HERB, [110413] = KIND_HERB,
    [2575] = KIND_ORE, [2576] = KIND_ORE, [3564] = KIND_ORE, [10248] = KIND_ORE,
    [29354] = KIND_ORE, [50310] = KIND_ORE, [74517] = KIND_ORE, [102161] = KIND_ORE,
    [8613] = KIND_SKIN, [8617] = KIND_SKIN, [8618] = KIND_SKIN, [10768] = KIND_SKIN,
    [32678] = KIND_SKIN, [50305] = KIND_SKIN, [74522] = KIND_SKIN, [102216] = KIND_SKIN,
}

local FALLBACK_KIND = {
    [765] = KIND_HERB, [785] = KIND_HERB, [2447] = KIND_HERB, [2449] = KIND_HERB,
    [2450] = KIND_HERB, [2452] = KIND_HERB, [2453] = KIND_HERB, [3355] = KIND_HERB,
    [3356] = KIND_HERB, [3357] = KIND_HERB, [3358] = KIND_HERB, [3369] = KIND_HERB,
    [3818] = KIND_HERB, [3819] = KIND_HERB, [3820] = KIND_HERB, [3821] = KIND_HERB,
    [4625] = KIND_HERB, [8153] = KIND_HERB, [8831] = KIND_HERB, [8836] = KIND_HERB,
    [8838] = KIND_HERB, [8839] = KIND_HERB, [8845] = KIND_HERB, [8846] = KIND_HERB,
    [13463] = KIND_HERB, [13464] = KIND_HERB, [13465] = KIND_HERB, [13466] = KIND_HERB,
    [13467] = KIND_HERB, [13468] = KIND_HERB,
    [2770] = KIND_ORE, [2771] = KIND_ORE, [2772] = KIND_ORE, [2775] = KIND_ORE,
    [2776] = KIND_ORE, [2835] = KIND_ORE, [2836] = KIND_ORE, [2838] = KIND_ORE,
    [3858] = KIND_ORE, [7911] = KIND_ORE, [7912] = KIND_ORE, [10620] = KIND_ORE,
    [11370] = KIND_ORE, [12365] = KIND_ORE,
    [783] = KIND_SKIN, [2318] = KIND_SKIN, [2319] = KIND_SKIN, [4232] = KIND_SKIN,
    [4234] = KIND_SKIN, [4235] = KIND_SKIN, [4304] = KIND_SKIN, [5784] = KIND_SKIN,
    [5785] = KIND_SKIN, [6470] = KIND_SKIN, [6471] = KIND_SKIN, [7286] = KIND_SKIN,
    [7287] = KIND_SKIN, [8154] = KIND_SKIN, [8165] = KIND_SKIN, [8169] = KIND_SKIN,
    [8170] = KIND_SKIN, [8171] = KIND_SKIN, [15408] = KIND_SKIN, [15412] = KIND_SKIN,
    [15414] = KIND_SKIN, [15415] = KIND_SKIN, [15416] = KIND_SKIN, [15417] = KIND_SKIN,
    [15419] = KIND_SKIN, [17012] = KIND_SKIN,
}

local OVERLAY_ITEM_ROWS = 8
local nameKind

local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
end

function ST:GatherSpellKind(spellID)
    local kind = SPELL_KIND[spellID]
    if kind then
        return kind
    end
    if not nameKind then
        nameKind = {
            ["Herb Gathering"] = KIND_HERB,
            ["Mining"] = KIND_ORE,
            ["Skinning"] = KIND_SKIN,
        }
        for id, k in pairs(SPELL_KIND) do
            local n = SpellName(id)
            if n then
                nameKind[n] = k
            end
        end
    end
    local n = SpellName(spellID)
    return n and nameKind[n]
end

function ST:ClassifyGatherItem(item)
    local itemID, _, _, _, _, classID, subclassID
    if C_Item and C_Item.GetItemInfoInstant then
        itemID, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(item)
    elseif GetItemInfoInstant then
        itemID, _, _, _, _, classID, subclassID = GetItemInfoInstant(item)
    else
        itemID = tonumber(tostring(item):match("item:(%d+)"))
    end
    if itemID and FALLBACK_KIND[itemID] then
        return FALLBACK_KIND[itemID], itemID
    end
    if not classID then
        return nil
    end
    local trade = (Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7
    if classID ~= trade then
        return nil
    end
    local herb = (Enum and Enum.ItemTradegoodsSubclass and Enum.ItemTradegoodsSubclass.Herb) or 9
    local metal = (Enum and Enum.ItemTradegoodsSubclass and Enum.ItemTradegoodsSubclass.MetalAndStone) or 7
    local leather = (Enum and Enum.ItemTradegoodsSubclass and Enum.ItemTradegoodsSubclass.Leather) or 6
    if subclassID == herb then
        return KIND_HERB, itemID
    end
    if subclassID == metal then
        return KIND_ORE, itemID
    end
    if subclassID == leather then
        return KIND_SKIN, itemID
    end
end

function ST:GetGatherSortedItems()
    local list = {}
    for _, info in pairs(self.gather.items) do
        list[#list + 1] = info
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

function ST:CreateSimpleGatherUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    self.gatherNodesDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    self.gatherNodesDisplay:SetPoint("TOP", 0, -2)
    self.gatherNodesDisplay:SetText("0 nodes")

    self.gatherPerHourDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.gatherPerHourDisplay:SetPoint("TOP", 0, -18)
    self.gatherPerHourDisplay:SetText("Nodes/hr: 0")

    self.gatherKindsDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.gatherKindsDisplay:SetPoint("TOP", 0, -34)
    self.gatherKindsDisplay:SetText("Herbs 0  ·  Ore 0  ·  Leather 0")

    self.gatherElapsedDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.gatherElapsedDisplay:SetPoint("TOP", 0, -46)
    self.gatherElapsedDisplay:SetText("Elapsed: 00:00")

    -- Same width as the Start / Send to screen / Reset row (112 * 3 + 12 * 2).
    local rowWidth = 360
    local listBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listBox:SetWidth(rowWidth)
    listBox:SetPoint("TOP", 0, -62)
    listBox:SetPoint("BOTTOM", 0, 42)
    self:ApplyOverlayBackdrop(listBox)

    local listScroll = CreateFrame("ScrollFrame", "SimpleToolsGatherScroll", listBox)
    listScroll:SetPoint("TOPLEFT", 6, -4)
    listScroll:SetPoint("BOTTOMRIGHT", -6, 4)
    listScroll:EnableMouseWheel(true)
    listScroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 16))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetSize(rowWidth - 12, 20)
    listScroll:SetScrollChild(listChild)

    self.gatherListChild = listChild
    self.gatherListRows = {}

    self.gatherStartPauseButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.gatherStartPauseButton:SetText("Start")
    self.gatherStartPauseButton:SetScript("OnClick", function()
        ST:ToggleGatherTracker()
    end)

    self.gatherProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.gatherProjectButton:SetText("Send to screen")
    self.gatherProjectButton:SetScript("OnClick", function()
        ST:ToggleGatherProjected()
    end)

    self.gatherResetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.gatherResetButton:SetText("Reset")
    self.gatherResetButton:SetScript("OnClick", function()
        ST:ResetGatherTracker()
    end)

    -- Same size/layout as XP, Gold, Timer, Stopwatch.
    self:LayoutTrackerButtons(frame, self.gatherStartPauseButton, self.gatherProjectButton, self.gatherResetButton)

    return frame
end

function ST:ToggleGatherTracker()
    if self.gather.running then
        self:PauseGatherTracker()
    else
        self:StartGatherTracker()
    end
end

function ST:StartGatherTracker()
    self.gather.anchor = GetTime()
    self.gather.running = true
    self.gatherStartPauseButton:SetText("Pause")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateGatherTracker()
end

function ST:PauseGatherTracker()
    if not self.gather.running then
        return
    end
    self.gather.elapsed = self.gather.elapsed + (GetTime() - self.gather.anchor)
    self.gather.running = false
    self.gatherStartPauseButton:SetText("Resume")
    self:SaveDB()
    self:RefreshTicker()
    self:UpdateGatherTracker()
end

function ST:ResetGatherTracker()
    local wasRunning = self.gather.running
    self.gather.running = false
    self.gather.elapsed = 0
    self.gather.anchor = 0
    self.gather.nodes = 0
    self.gather.herbNodes = 0
    self.gather.oreNodes = 0
    self.gather.skinNodes = 0
    self.gather.items = {}
    if wasRunning then
        self:StartGatherTracker()
    else
        self.gatherStartPauseButton:SetText("Start")
        self:SaveDB()
        self:RefreshTicker()
        self:UpdateGatherTracker()
    end
end

function ST:GatherElapsed()
    local elapsed = self.gather.elapsed
    if self.gather.running then
        elapsed = elapsed + (GetTime() - self.gather.anchor)
    end
    return elapsed
end

function ST:OnGatherSpell(unit, _, spellID)
    if not self.gather.running then
        return
    end
    if unit ~= "player" then
        return
    end
    local kind = self:GatherSpellKind(spellID)
    if not kind then
        return
    end
    self.gather.nodes = self.gather.nodes + 1
    if kind == KIND_HERB then
        self.gather.herbNodes = self.gather.herbNodes + 1
    elseif kind == KIND_ORE then
        self.gather.oreNodes = self.gather.oreNodes + 1
    else
        self.gather.skinNodes = self.gather.skinNodes + 1
    end
    self:UpdateGatherTracker()
    self:ScheduleSave()
end

function ST:OnGatherLoot(text)
    if not self.gather.running then
        return
    end
    if type(text) ~= "string" then
        return
    end
    local link = text:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)")
    if not link then
        return
    end
    local kind, itemID = self:ClassifyGatherItem(link)
    if not kind or not itemID then
        return
    end
    local count = tonumber(text:match("|h|rx(%d+)")) or 1
    local name = link:match("%[(.-)%]") or tostring(itemID)
    local entry = self.gather.items[itemID]
    if not entry then
        entry = { name = name, count = 0, kind = kind }
        self.gather.items[itemID] = entry
    end
    entry.count = entry.count + count
    entry.name = name
    entry.kind = kind
    self:UpdateGatherTracker()
    self:ScheduleSave()
end

function ST:RefreshGatherList()
    local items = self:GetGatherSortedItems()
    local child = self.gatherListChild
    local rows = self.gatherListRows
    if not child or not rows then
        return
    end

    for i, item in ipairs(items) do
        local row = rows[i]
        if not row then
            row = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row:SetPoint("TOPLEFT", 0, -((i - 1) * 16))
            row:SetPoint("TOPRIGHT", -4, -((i - 1) * 16))
            row:SetJustifyH("LEFT")
            rows[i] = row
        end
        local tag = "H"
        if item.kind == KIND_ORE then
            tag = "O"
        elseif item.kind == KIND_SKIN then
            tag = "L"
        end
        row:SetText(string.format("%s  %s    %d", tag, item.name or "?", item.count or 0))
        row:Show()
    end
    for i = #items + 1, #rows do
        rows[i]:Hide()
    end
    child:SetHeight(math.max(20, #items * 16))
end

function ST:UpdateGatherTracker()
    if not self.gatherNodesDisplay then
        return
    end

    local elapsed = self:GatherElapsed()
    local nodes = self.gather.nodes or 0
    self.gatherNodesDisplay:SetText(tostring(nodes) .. (nodes == 1 and " node" or " nodes"))

    local elapsedText = "Elapsed: " .. self:FormatElapsedTime(elapsed)
    self.gatherElapsedDisplay:SetText(elapsedText)

    local kinds = string.format(
        "Herbs %d  ·  Ore %d  ·  Leather %d",
        self.gather.herbNodes or 0,
        self.gather.oreNodes or 0,
        self.gather.skinNodes or 0
    )
    self.gatherKindsDisplay:SetText(kinds)

    local rate = 0
    if elapsed > 0 then
        rate = math.floor((nodes / elapsed) * 3600)
    end
    local rateText = "Nodes/hr: " .. tostring(rate)
    self.gatherPerHourDisplay:SetText(rateText)

    self:RefreshGatherList()

    if not self.gatherProjectedFrame then
        return
    end
    self.gatherProjNodes:SetText(tostring(nodes) .. " nodes")
    self.gatherProjRate:SetText(rateText)
    self.gatherProjKinds:SetText(kinds)
    self.gatherProjElapsed:SetText(elapsedText)

    local items = self:GetGatherSortedItems()
    local extra = math.max(0, #items - OVERLAY_ITEM_ROWS)
    local shown = math.min(#items, OVERLAY_ITEM_ROWS)
    for i = 1, OVERLAY_ITEM_ROWS do
        local fs = self.gatherProjItems[i]
        local item = items[i]
        if item then
            local tag = "H"
            if item.kind == KIND_ORE then
                tag = "O"
            elseif item.kind == KIND_SKIN then
                tag = "L"
            end
            fs:SetText(string.format("%s  %s  %d", tag, item.name or "?", item.count or 0))
            fs:Show()
        else
            fs:SetText("")
            fs:Hide()
        end
    end
    if extra > 0 then
        self.gatherProjMore:SetText("+" .. extra .. " more")
        self.gatherProjMore:Show()
    else
        self.gatherProjMore:Hide()
    end
    local height = 78 + (shown * 14)
    if extra > 0 then
        height = height + 14
    end
    self.gatherProjectedFrame:SetHeight(height)
end

function ST:CreateGatherProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleGatherProjectedFrame", 200, 90, 0, -170, "Gather Tracker", function()
        ST:ShowGatherProjected(false)
    end)

    self.gatherProjNodes = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.gatherProjNodes:SetPoint("TOP", 0, -8)
    self.gatherProjNodes:SetText("0 nodes")

    self.gatherProjRate = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.gatherProjRate:SetPoint("TOP", 0, -24)
    self.gatherProjRate:SetText("Nodes/hr: 0")

    self.gatherProjKinds = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.gatherProjKinds:SetPoint("TOP", 0, -40)
    self.gatherProjKinds:SetText("Herbs 0  ·  Ore 0  ·  Leather 0")

    self.gatherProjElapsed = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.gatherProjElapsed:SetPoint("TOP", 0, -54)
    self.gatherProjElapsed:SetText("Elapsed: 00:00")

    self.gatherProjItems = {}
    for i = 1, OVERLAY_ITEM_ROWS do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 10, -(72 + (i - 1) * 14))
        fs:SetPoint("TOPRIGHT", -10, -(72 + (i - 1) * 14))
        fs:SetJustifyH("LEFT")
        fs:Hide()
        self.gatherProjItems[i] = fs
    end

    self.gatherProjMore = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.gatherProjMore:SetPoint("BOTTOM", 0, 6)
    self.gatherProjMore:Hide()

    self.gatherProjectedFrame = frame
end

function ST:ShowGatherProjected(show, pos)
    if not self.gatherProjectedFrame then
        self:CreateGatherProjectedFrame()
    end
    if show then
        self:PlaceOverlay(self.gatherProjectedFrame, pos)
        self.gatherProjectedFrame:Show()
        self.gatherProjectButton:SetText("Unproject")
        self.gather.projected = true
        self:UpdateGatherTracker()
    else
        self.gatherProjectedFrame:Hide()
        self.gatherProjectButton:SetText("Send to screen")
        self.gather.projected = false
    end
end

function ST:ToggleGatherProjected()
    self:ShowGatherProjected(not (self.gatherProjectedFrame and self.gatherProjectedFrame:IsShown()))
    self:SaveDB()
end
