local addonName, ST = ...

local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown
local GetItemInfo = GetItemInfo

local ROW_HEIGHT = 18
local MAX_ROWS = 40
local PROF_BTN_W = 128
local PROF_BTN_H = 22
local PROF_GAP = 4
local MENU_ROW = 16

function ST:ShopCatalogGroups(prof)
    local query = self.shopSearchText or ""
    if self.shopSearchInput and self.shopSearchInput.GetText then
        query = self.shopSearchInput:GetText() or ""
    end
    if strtrim then
        query = strtrim(query)
    end
    query = string.lower(query)
    local groups = {}
    for _, group in ipairs(prof.groups or {}) do
        local mats = {}
        for _, mat in ipairs(group.mats or {}) do
            local name = string.lower(mat.name or "")
            if query == "" or string.find(name, query, 1, true) then
                mats[#mats + 1] = mat
            end
        end
        if #mats > 0 then
            groups[#groups + 1] = { label = group.label, mats = mats }
        end
    end
    return groups
end

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

function ST:MakeShopCatalogLink(mat)
    if not mat then
        return nil
    end
    if type(mat.link) == "string" and mat.link ~= "" then
        return mat.link
    end
    local id = mat.id or 0
    local name = mat.name or "Item"
    if id > 0 and GetItemInfo then
        local ok, itemName, itemLink = pcall(GetItemInfo, id)
        if ok and type(itemLink) == "string" and itemLink ~= "" then
            return itemLink
        end
        if ok and type(itemName) == "string" and itemName ~= "" then
            -- GetItemInfo returns name as first value; some clients put link second only
        end
    end
    return "|Hitem:" .. id .. "::::::::|h[" .. name .. "]|h"
end

function ST:IsShopListening()
    return self.frame and self.frame:IsShown() and self.shopFrame and self.shopFrame:IsShown()
end

function ST:TryCaptureShopLink(link)
    if not self:IsShopListening() then
        return false
    end
    if self.shopQtyFrame and self.shopQtyFrame:IsShown() then
        return false
    end
    local item = self:ParseItemLink(link)
    if not item then
        return false
    end
    self:PromptShopQuantity(item)
    return true
end

function ST:PromptShopFromCatalog(mat)
    if not mat then
        return
    end
    self:HideShopProfMenu()
    self:PromptShopQuantity({
        id = mat.id or 0,
        name = mat.name,
        link = self:MakeShopCatalogLink(mat),
    })
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

function ST:SetShopItemCount(index, count)
    local entry = self.shopItems and self.shopItems[index]
    if not entry then
        return
    end
    count = tonumber(count)
    if not count or count <= 0 then
        self:RemoveShopItem(index)
        return
    end
    entry.count = math.min(9999, math.floor(count + 0.5))
    self:RefreshShopList()
    self:SaveDB()
end

function ST:ClearShopList()
    wipe(self.shopItems)
    self:CancelShopQuantity()
    self:RefreshShopList()
    self:SaveDB()
end

function ST:ShopBagCount(entry)
    if not entry then
        return nil
    end
    local item = entry.id
    if not item or item == 0 then
        item = entry.link or entry.name
    end
    if not item or item == "" then
        return nil
    end
    local count
    if C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(item, false)
    elseif GetItemCount then
        count = GetItemCount(item, false)
    end
    if count == nil or self:IsSecret(count) then
        return nil
    end
    return self:PlainNumber(count) or 0
end

function ST:ShopProgressText(entry)
    local need = math.max(1, math.floor(tonumber(entry and entry.count) or 1))
    local have = self:ShopBagCount(entry)
    if have == nil then
        return "|cff9a9a9a?/" .. need .. "|r"
    end
    local label = have .. "/" .. need
    if have >= need then
        return "|cff3dcc3d" .. label .. " ✓|r"
    end
    return "|cffe8c478" .. label .. "|r"
end

function ST:ScheduleShopBagRefresh()
    if self.shopBagPending then
        return
    end
    self.shopBagPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, function()
            self.shopBagPending = false
            if self.RefreshShopList then
                self:RefreshShopList()
            end
        end)
    else
        self.shopBagPending = false
        if self.RefreshShopList then
            self:RefreshShopList()
        end
    end
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

function ST:HideShopProfMenu()
    if self.shopProfMenu then
        self.shopProfMenu:Hide()
    end
    self.shopProfOpen = nil
end

function ST:CreateShopProfMenu()
    local frame = CreateFrame("Frame", "SimpleToolsShopProfMenu", UIParent, "BackdropTemplate")
    frame:SetSize(220, 240)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(10)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    self:ApplyOverlayBackdrop(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", 0, -8)

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsShopProfScroll", frame)
    scroll:SetPoint("TOPLEFT", 8, -24)
    scroll:SetPoint("BOTTOMRIGHT", -8, 8)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(200, 20)
    scroll:SetScrollChild(child)
    frame.child = child
    frame.scroll = scroll
    frame.rows = {}
    frame:Hide()
    frame:SetScript("OnHide", function()
        ST.shopProfOpen = nil
    end)
    self.shopProfMenu = frame
end

function ST:AcquireShopProfRow(i)
    local row = self.shopProfMenu.rows[i]
    if row then
        return row
    end
    local child = self.shopProfMenu.child
    row = self:CreateListRow(child, i, MENU_ROW)
    row:SetScript("OnClick", function(selfObj)
        if selfObj.mat then
            ST:PromptShopFromCatalog(selfObj.mat)
        end
    end)
    row:SetScript("OnEnter", function(selfObj)
        if selfObj.mat then
            selfObj.text:SetTextColor(1, 0.82, 0)
            local link = ST:MakeShopCatalogLink(selfObj.mat)
            if link and GameTooltip then
                GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(link)
                GameTooltip:Show()
            end
        end
    end)
    row:SetScript("OnLeave", function(selfObj)
        if selfObj.isHeader then
            selfObj.text:SetTextColor(0.6, 0.6, 0.6)
        else
            selfObj.text:SetTextColor(1, 1, 1)
        end
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    self.shopProfMenu.rows[i] = row
    return row
end

function ST:ToggleShopProfMenu(key, anchor)
    local prof = self.SHOP_PROFESSIONS[key]
    if not prof then
        return
    end
    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        self:HideShopProfMenu()
        MenuUtil.CreateContextMenu(anchor, function(_, root)
            if root.CreateTitle then
                root:CreateTitle(prof.label)
            end
            if root.SetScrollMode then
                root:SetScrollMode(280)
            end
            for gi, group in ipairs(self:ShopCatalogGroups(prof)) do
                if gi > 1 and root.CreateDivider then
                    root:CreateDivider()
                end
                if root.CreateTitle then
                    root:CreateTitle(group.label)
                end
                for _, mat in ipairs(group.mats or {}) do
                    root:CreateButton(mat.name, function()
                        ST:PromptShopFromCatalog(mat)
                    end)
                end
            end
        end)
        return
    end
    if self.shopProfOpen == key then
        self:HideShopProfMenu()
        return
    end
    self:ShowShopProfMenu(key, anchor)
end

function ST:ShowShopProfMenu(key, anchor)
    local prof = self.SHOP_PROFESSIONS[key]
    if not prof then
        return
    end
    if not self.shopProfMenu then
        self:CreateShopProfMenu()
    end
    local frame = self.shopProfMenu
    frame.title:SetText(prof.label)

    local groups = self:ShopCatalogGroups(prof)
    if #groups == 0 then
        groups = { { label = "No matching reagents", mats = {} } }
    end
    self.shopProfAnchor = anchor
    local lines = {}
    for _, group in ipairs(groups) do
        lines[#lines + 1] = { header = group.label }
        for _, mat in ipairs(group.mats or {}) do
            lines[#lines + 1] = { mat = mat }
        end
    end

    for i = 1, math.max(#lines, #frame.rows) do
        local row = frame.rows[i]
        if i <= #lines then
            row = self:AcquireShopProfRow(i)
            local line = lines[i]
            if line.header then
                row.mat = nil
                row.isHeader = true
                row.text:SetText(line.header)
                row.text:SetTextColor(0.6, 0.6, 0.6)
                row:EnableMouse(false)
                row:Show()
            else
                row.mat = line.mat
                row.isHeader = false
                row.text:SetText(line.mat.name)
                row.text:SetTextColor(1, 1, 1)
                row:EnableMouse(true)
                row:Show()
            end
        elseif row then
            row:Hide()
            row.mat = nil
        end
    end

    frame.child:SetHeight(math.max(20, #lines * MENU_ROW + 4))
    frame.scroll:SetVerticalScroll(0)

    frame:ClearAllPoints()
    if anchor then
        frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    else
        frame:SetPoint("CENTER")
    end
    frame:Show()
    self.shopProfOpen = key
end

function ST:CreateSimpleShopUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local findLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    findLabel:SetPoint("TOPLEFT", 8, -8)
    findLabel:SetText("Find")
    self.shopSearchInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.shopSearchInput:SetHeight(20)
    self.shopSearchInput:SetPoint("TOPLEFT", 40, -2)
    self.shopSearchInput:SetPoint("TOPRIGHT", -8, -2)
    self.shopSearchInput:SetAutoFocus(false)
    self.shopSearchInput:SetMaxLetters(40)
    self.shopSearchInput:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    self.shopSearchInput:SetScript("OnTextChanged", function(selfBox, userInput)
        if userInput == false then
            return
        end
        ST.shopSearchText = selfBox:GetText()
        if ST.shopProfOpen then
            ST:ShowShopProfMenu(ST.shopProfOpen, ST.shopProfAnchor)
        end
    end)

    self.shopProfButtons = {}
    for i, key in ipairs(self.SHOP_PROFESSION_ORDER) do
        local prof = self.SHOP_PROFESSIONS[key]
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        btn:SetSize(PROF_BTN_W, PROF_BTN_H)
        btn:SetText(prof.label)
        btn:SetScript("OnClick", function(selfBtn)
            ST:ToggleShopProfMenu(key, selfBtn)
        end)
        self.shopProfButtons[i] = btn
    end

    local listBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listBox:SetPoint("TOPLEFT", 8, -82)
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
    clear:SetText("Clear list")
    clear:SetScript("OnClick", function()
        ST:ClearShopList()
    end)

    self.shopProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.shopProjectButton:SetText("Send to screen")
    self.shopProjectButton:SetScript("OnClick", function()
        ST:ToggleShopProjected()
    end)

    self:LayoutBottomPair(frame, clear, self.shopProjectButton)

    frame:SetScript("OnHide", function()
        ST:HideShopProfMenu()
    end)

    self.shopFrame = frame
    self:LayoutShopProfButtons()
    self:RefreshShopList()
    return frame
end

function ST:LayoutShopProfButtons()
    local frame = self.shopFrame
    local buttons = self.shopProfButtons
    if not frame or not buttons then
        return
    end
    local inner = math.max(400, (frame:GetWidth() or 560) - 16)
    local gap = PROF_GAP
    local width = math.floor((inner - 3 * gap) / 4)
    width = math.max(96, math.min(168, width))
    for i, btn in ipairs(buttons) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        btn:SetSize(width, PROF_BTN_H)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 8 + col * (width + gap), -28 - row * (PROF_BTN_H + gap))
    end
end

function ST:BindShopQty(row)
    if not row.qty then
        return
    end
    row.qty:SetScript("OnEditFocusGained", function(selfBox)
        -- Rows can be rebound by a list refresh while this edit has focus.
        selfBox.shopEntry = row.entry
    end)
    row.qty:SetScript("OnEnterPressed", function(selfBox)
        -- Focus loss is the single commit path, including removal with zero.
        selfBox:ClearFocus()
    end)
    row.qty:SetScript("OnEditFocusLost", function(selfBox)
        local entry = selfBox.shopEntry
        selfBox.shopEntry = nil
        if not entry then
            return
        end
        for index, item in ipairs(ST.shopItems or {}) do
            if item == entry then
                ST:SetShopItemCount(index, tonumber(selfBox:GetText()) or entry.count)
                break
            end
        end
    end)
    row.qty:SetScript("OnEscapePressed", function(selfBox)
        local entry = selfBox.shopEntry
        selfBox.shopEntry = nil
        if entry then
            selfBox:SetText(tostring(entry.count or 1))
        end
        selfBox:ClearFocus()
    end)
end

function ST:BindShopEntryRow(row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", function(selfObj)
        if selfObj.entry then
            GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
            if selfObj.entry.link then
                GameTooltip:SetHyperlink(selfObj.entry.link)
            else
                GameTooltip:SetText(selfObj.entry.name or "Item")
            end
            GameTooltip:AddLine("Bags " .. (ST:ShopProgressText(selfObj.entry):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) .. ". Shift-click: AH search. Right-click or x: remove.", 0.8, 0.8, 0.8, true)
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
        else
            ST:ShopSearchAH(selfObj.entry)
        end
    end)
end

function ST:AcquireShopRow(i)
    return self:CreateShopItemRow(self.shopListChild, self.shopListRows, i)
end

function ST:CreateShopItemRow(child, store, i)
    local row = store[i]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, child)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -16, -(i - 1) * ROW_HEIGHT)

    -- Same plain number as the projected list. No input-box end caps.
    row.qty = CreateFrame("EditBox", nil, row)
    row.qty:SetSize(32, 14)
    row.qty:SetPoint("LEFT", 2, 0)
    row.qty:SetAutoFocus(false)
    row.qty:SetNumeric(true)
    row.qty:SetMaxLetters(4)
    row.qty:SetJustifyH("RIGHT")
    row.qty:SetFontObject("GameFontHighlightSmall")
    row.qty:SetTextInsets(0, 1, 0, 0)
    row.qty:SetTextColor(0.95, 0.9, 0.78)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.qty, "RIGHT", 6, 0)
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

    self:BindShopQty(row)
    row.qty:HookScript("OnEditFocusGained", function(selfBox)
        selfBox:HighlightText()
        selfBox:SetTextColor(1, 0.86, 0.45)
    end)
    row.qty:HookScript("OnEditFocusLost", function(selfBox)
        selfBox:SetTextColor(0.95, 0.9, 0.78)
    end)
    self:BindShopEntryRow(row)
    store[i] = row
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
            row.text:SetText(self:ShopProgressText(entry) .. "  x " .. link)
            if row.qty and not row.qty:HasFocus() then
                row.qty:SetText(tostring(entry.count or 1))
            end
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
    self:RefreshShopProjected()
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

function ST:CreateShopProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleShopProjectedFrame", 220, 160, 180, -80, "Shop", function()
        ST:ShowShopProjected(false)
    end)
    frame.overlayHint = "Edit qty in place. Shift-click a row for AH search. Corner to resize. Hover for × to hide."

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("Shop")

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsShopOverlayScroll", frame)
    scroll:SetPoint("TOPLEFT", 8, -24)
    scroll:SetPoint("BOTTOMRIGHT", -8, 16)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(200, 20)
    scroll:SetScrollChild(child)

    self.shopProjEmpty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.shopProjEmpty:SetPoint("TOPLEFT", 4, -4)
    self.shopProjEmpty:SetText("List is empty.")

    self:AttachResizeGrip(frame, 160, 90, 560, 480, function()
        ST:LayoutShopProjected()
    end)
    frame:SetScript("OnSizeChanged", function()
        ST:LayoutShopProjected()
    end)

    self.shopProjChild = child
    self.shopProjScroll = scroll
    self.shopProjRows = {}
    self.shopProjectedFrame = frame
end

function ST:LayoutShopProjected()
    if not self.shopProjChild or not self.shopProjScroll then
        return
    end
    local width = self.shopProjScroll:GetWidth() or 200
    self.shopProjChild:SetWidth(math.max(80, width))
    for _, row in ipairs(self.shopProjRows or {}) do
        row:SetWidth(width)
    end
end

function ST:AcquireShopProjRow(i)
    return self:CreateShopItemRow(self.shopProjChild, self.shopProjRows, i)
end

function ST:RefreshShopProjected()
    if not self.shopProjectedFrame then
        return
    end
    local list = self.shopItems or {}
    local shown = math.min(#list, MAX_ROWS)
    for i = 1, math.max(shown, #(self.shopProjRows or {})) do
        local row = self.shopProjRows[i]
        if i <= shown then
            row = self:AcquireShopProjRow(i)
            local entry = list[i]
            row.index = i
            row.entry = entry
            local link = entry.link or entry.name
            row.text:SetText(self:ShopProgressText(entry) .. "  x " .. link)
            if row.qty and not row.qty:HasFocus() then
                row.qty:SetText(tostring(entry.count or 1))
            end
            row:SetWidth(self.shopProjChild:GetWidth() or 200)
            row:Show()
        elseif row then
            row:Hide()
            row.entry = nil
        end
    end
    if self.shopProjEmpty then
        self.shopProjEmpty:SetShown(shown == 0)
    end
    self.shopProjChild:SetHeight(math.max(20, shown * ROW_HEIGHT + 4))
    self:LayoutShopProjected()
end

function ST:ShowShopProjected(show, pos)
    if not self.shopProjectedFrame then
        self:CreateShopProjectedFrame()
    end
    if show then
        self:PlaceOverlay(self.shopProjectedFrame, pos)
        local w = (pos and pos.projWidth) or 220
        local h = (pos and pos.projHeight) or 160
        self.shopProjectedFrame:SetSize(math.max(160, w), math.max(90, h))
        self.shopProjectedFrame:Show()
        if self.shopProjectButton then
            self.shopProjectButton:SetText("Unproject")
        end
        self.shopProjected = true
        self:RefreshShopProjected()
    else
        self.shopProjectedFrame:Hide()
        if self.shopProjectButton then
            self.shopProjectButton:SetText("Send to screen")
        end
        self.shopProjected = false
    end
end

function ST:ToggleShopProjected()
    self:ShowShopProjected(not (self.shopProjectedFrame and self.shopProjectedFrame:IsShown()))
    self:SaveDB()
end
