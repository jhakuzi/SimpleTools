local addonName, ST = ...

local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown

local ROW_HEIGHT = 18
local MAX_ROWS = 40

function ST:ParseItemLink(link)
    if type(link) ~= "string" or link == "" then
        return nil
    end
    local id = tonumber(link:match("item:(%d+)"))
    local name = link:match("%[([^%]]+)%]")
    if not id and not name then
        return nil
    end
    if not name or name == "" then
        name = "Item " .. tostring(id or "?")
    end
    return {
        id = id or 0,
        name = name,
        link = link,
    }
end

function ST:IsShopListening()
    return self.frame and self.frame:IsShown() and self.shopFrame and self.shopFrame:IsShown()
end

function ST:TryCaptureShopLink(link)
    if not self:IsShopListening() then
        return false
    end
    if self.shopQtyFrame and self.shopQtyFrame:IsShown() then
        return true
    end
    local item = self:ParseItemLink(link)
    if not item then
        return false
    end
    self:PromptShopQuantity(item)
    return true
end

function ST:PromptShopQuantity(item)
    self.pendingShopItem = item
    if not self.shopQtyFrame then
        self:CreateShopQtyFrame()
    end
    local frame = self.shopQtyFrame
    frame.label:SetText("How many  " .. (item.link or item.name) .. "?")
    frame.edit:SetText("1")
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

function ST:CreateShopQtyFrame()
    local frame = CreateFrame("Frame", "SimpleToolsShopQty", UIParent, "BackdropTemplate")
    frame:SetSize(300, 108)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    self:ApplyOverlayBackdrop(frame)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOP", 0, -14)
    label:SetWidth(270)
    label:SetWordWrap(true)
    frame.label = label

    local edit = CreateFrame("EditBox", "SimpleToolsShopQtyEdit", frame, "InputBoxTemplate")
    edit:SetSize(80, 20)
    edit:SetPoint("TOP", 0, -42)
    edit:SetAutoFocus(false)
    edit:SetNumeric(true)
    edit:SetMaxLetters(5)
    edit:SetText("1")
    edit:SetScript("OnEnterPressed", function()
        ST:ConfirmShopQuantity()
    end)
    edit:SetScript("OnEscapePressed", function()
        ST:CancelShopQuantity()
    end)
    frame.edit = edit

    local ok = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    ok:SetSize(80, 22)
    ok:SetPoint("BOTTOM", -48, 12)
    ok:SetText("Add")
    ok:SetScript("OnClick", function()
        ST:ConfirmShopQuantity()
    end)

    local cancel = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    cancel:SetSize(80, 22)
    cancel:SetPoint("BOTTOM", 48, 12)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        ST:CancelShopQuantity()
    end)

    frame:Hide()
    self.shopQtyFrame = frame
end

function ST:ConfirmShopQuantity()
    local item = self.pendingShopItem
    local n = 1
    if self.shopQtyFrame and self.shopQtyFrame.edit then
        n = tonumber(self.shopQtyFrame.edit:GetText()) or 1
    end
    n = math.floor(math.max(1, math.min(9999, n)))
    self:CancelShopQuantity()
    if item then
        self:AddShopItem(item, n)
    end
end

function ST:CancelShopQuantity()
    self.pendingShopItem = nil
    if self.shopQtyFrame then
        self.shopQtyFrame:Hide()
        if self.shopQtyFrame.edit then
            self.shopQtyFrame.edit:ClearFocus()
        end
    end
end

function ST:AddShopItem(item, count)
    if not item then
        return
    end
    count = count or 1
    if not self.shopItems then
        self.shopItems = {}
    end
    local list = self.shopItems
    local found
    for _, row in ipairs(list) do
        if (item.id ~= 0 and row.id == item.id) or (item.id == 0 and row.name == item.name) then
            found = row
            break
        end
    end
    if found then
        found.count = math.min(9999, (found.count or 0) + count)
        if item.link then
            found.link = item.link
        end
    else
        list[#list + 1] = {
            id = item.id,
            name = item.name,
            link = item.link,
            count = count,
        }
    end
    self:RefreshShopList()
    self:SaveDB()
end

function ST:RemoveShopItem(index)
    table.remove(self.shopItems, index)
    self:RefreshShopList()
    self:SaveDB()
end

function ST:ClearShopList()
    wipe(self.shopItems)
    self:CancelShopQuantity()
    self:RefreshShopList()
    self:SaveDB()
end

function ST:ShopSearchAH(entry)
    if not entry then
        return
    end
    local name = entry.name
    if not name or name == "" then
        return
    end

    local searched = false
    local ah = _G.AuctionHouseFrame
    if ah and ah:IsShown() then
        local bar = ah.SearchBar
        if bar then
            if bar.SearchBox then
                bar.SearchBox:SetText(name)
                bar.SearchBox:SetFocus()
            end
            if type(bar.StartSearch) == "function" then
                bar:StartSearch()
                searched = true
            elseif bar.SearchButton then
                bar.SearchButton:Click()
                searched = true
            end
        end
    end

    local classicAH = _G.AuctionFrame
    if not searched and classicAH and classicAH:IsShown() and _G.BrowseName then
        _G.BrowseName:SetText(name)
        if _G.AuctionFrameBrowse_Search then
            _G.AuctionFrameBrowse_Search()
        end
        searched = true
    end

    if searched then
        self:Print("AH search: " .. name)
        return
    end

    if ChatEdit_InsertLink and entry.link then
        ChatEdit_InsertLink(entry.link)
    elseif ChatFrameUtil and ChatFrameUtil.InsertLink and entry.link then
        ChatFrameUtil.InsertLink(entry.link)
    else
        self:Print("Open the auction house, then shift-click a row to search for " .. name .. ".")
    end
end

function ST:CreateSimpleShopUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 8, -4)
    hint:SetPoint("TOPRIGHT", -8, -4)
    hint:SetJustifyH("LEFT")
    hint:SetText("Shift-click bag items to add. Shift-click a row to paste into AH search.")

    local listBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listBox:SetPoint("TOPLEFT", 8, -22)
    listBox:SetPoint("BOTTOMRIGHT", -8, 38)
    self:ApplyOverlayBackdrop(listBox)

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsShopScroll", listBox)
    scroll:SetPoint("TOPLEFT", 6, -4)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(400, 20)
    scroll:SetScrollChild(child)

    self.shopListChild = child
    self.shopListRows = {}
    self.shopEmpty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.shopEmpty:SetPoint("TOPLEFT", 4, -4)
    self.shopEmpty:SetText("List is empty.")

    local clear = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clear:SetSize(90, 25)
    clear:SetPoint("BOTTOM", 0, 8)
    clear:SetText("Clear list")
    clear:SetScript("OnClick", function()
        ST:ClearShopList()
    end)

    self.shopFrame = frame
    self:HookShopClicks()
    self:RefreshShopList()
    return frame
end

function ST:AcquireShopRow(i)
    local row = self.shopListRows[i]
    if row then
        return row
    end
    local child = self.shopListChild
    row = CreateFrame("Button", nil, child)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -16, -(i - 1) * ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -18, 0)
    row.text:SetJustifyH("LEFT")
    if row.text.SetWordWrap then
        row.text:SetWordWrap(false)
    end

    row.remove = CreateFrame("Button", nil, row)
    row.remove:SetSize(16, 16)
    row.remove:SetPoint("RIGHT", -2, 0)
    row.remove.label = row.remove:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.remove.label:SetPoint("CENTER")
    row.remove.label:SetText("x")
    row.remove:SetScript("OnClick", function()
        ST:RemoveShopItem(row.index)
    end)

    row:SetScript("OnEnter", function(selfObj)
        if selfObj.entry and selfObj.entry.link then
            GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(selfObj.entry.link)
            GameTooltip:AddLine("Shift-click: AH search. Right-click or x: remove.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(selfObj, button)
        if button == "RightButton" then
            ST:RemoveShopItem(selfObj.index)
            return
        end
        if IsShiftKeyDown() then
            ST:ShopSearchAH(selfObj.entry)
        elseif selfObj.entry and selfObj.entry.link and SetItemRef then
            SetItemRef(selfObj.entry.link:match("|H(.-)|h") or selfObj.entry.link, selfObj.entry.link, button)
        end
    end)

    self.shopListRows[i] = row
    return row
end

function ST:RefreshShopList()
    if not self.shopListChild then
        return
    end
    local list = self.shopItems or {}
    local shown = math.min(#list, MAX_ROWS)
    for i = 1, math.max(shown, #self.shopListRows) do
        local row = self.shopListRows[i]
        if i <= shown then
            row = self:AcquireShopRow(i)
            local entry = list[i]
            row.index = i
            row.entry = entry
            local link = entry.link or entry.name
            row.text:SetText(tostring(entry.count) .. " x " .. link)
            row:SetWidth(self.shopListChild:GetWidth() or 400)
            row:Show()
        elseif row then
            row:Hide()
            row.entry = nil
        end
    end
    if self.shopEmpty then
        self.shopEmpty:SetShown(shown == 0)
    end
    self.shopListChild:SetHeight(math.max(20, shown * ROW_HEIGHT + 4))
end

function ST:HookShopClicks()
    if self.shopHooks then
        return
    end
    self.shopHooks = true

    if type(_G.HandleModifiedItemClick) == "function" then
        local orig = _G.HandleModifiedItemClick
        _G.HandleModifiedItemClick = function(link, ...)
            if ST:TryCaptureShopLink(link) then
                return true
            end
            return orig(link, ...)
        end
    end

    if type(_G.ChatEdit_InsertLink) == "function" then
        local orig = _G.ChatEdit_InsertLink
        _G.ChatEdit_InsertLink = function(link, ...)
            if ST:TryCaptureShopLink(link) then
                return true
            end
            return orig(link, ...)
        end
    end

    local util = _G.ChatFrameUtil
    if util and type(util.InsertLink) == "function" then
        local orig = util.InsertLink
        util.InsertLink = function(link, ...)
            if ST:TryCaptureShopLink(link) then
                return true
            end
            return orig(link, ...)
        end
    end
end
