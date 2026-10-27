local addonName, ST = ...
local CreateFrame = CreateFrame

-- Reset completes one independent tracker session; pause remains resumable.
function ST:RecordTrackerSession(kind, state, elapsed)
    if not self.db or not self.db.history or type(elapsed) ~= "number" or elapsed <= 0 then return end
    local entry = {kind = kind, duration = elapsed, partial = state.partial == true,
        completed = date("%Y-%m-%d %H:%M")}
    if kind == "gather" then
        entry.nodes = state.nodes
        entry.items = {}
        for _, item in pairs(state.items or {}) do
            if type(item.name) == "string" and type(item.count) == "number" then
                entry.items[#entry.items + 1] = {name = item.name, count = item.count}
            end
        end
        table.sort(entry.items, function(a, b) return a.name < b.name end)
        entry.rate = state.nodes * 3600 / elapsed
    else
        entry.gained = state.gained
        entry.rate = state.gained * 3600 / elapsed
    end
    table.insert(self.db.history, 1, entry)
    if #self.db.history > 100 then table.remove(self.db.history) end
    self:RefreshHistory()
    self:SaveDB()
end

function ST:HistoryText(entry)
    local duration = self:FormatTime(entry.duration)
    local prefix = entry.kind == "xp" and "XP" or (entry.kind == "gold" and "Gold" or "Gather")
    local total = entry.kind == "gather" and (tostring(entry.nodes) .. " nodes")
        or (entry.kind == "gold" and self:FormatMoney(entry.gained) or tostring(entry.gained) .. " XP")
    local rate = entry.kind == "gold" and self:FormatMoney(entry.rate) or tostring(math.floor(entry.rate))
    local text = string.format("%s  %s  |  %s  |  %s  |  %s/hr%s", entry.completed, prefix, duration, total, rate, entry.partial and " (partial)" or "")
    for _, item in ipairs(entry.items or {}) do text = text .. "\n  " .. item.name .. " x" .. item.count end
    return text
end

function ST:RefreshHistory()
    if not self.historyChild then return end
    local history = self.db and self.db.history or {}
    for i = 1, math.max(#history, #self.historyRows) do
        local entry, row = history[i], self.historyRows[i]
        if entry then
            if not row then
                row = CreateFrame("Frame", nil, self.historyChild)
                row:SetPoint("TOPLEFT", 0, -(i - 1) * 24)
                row:SetPoint("TOPRIGHT", 0, -(i - 1) * 24)
                row:SetHeight(24)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.text:SetPoint("LEFT", 4, 0)
                row.text:SetPoint("RIGHT", -26, 0)
                row.text:SetJustifyH("LEFT")
                row.text:SetWordWrap(false)
                local selectButton = CreateFrame("Button", nil, row)
                selectButton:SetPoint("TOPLEFT", 0, 0)
                selectButton:SetPoint("BOTTOMRIGHT", -24, 0)
                selectButton:SetScript("OnClick", function()
                    ST.historyDetails:SetText(ST:HistoryText(row.entry))
                    ST.historyDetailsChild:SetHeight(math.max(40, ST.historyDetails:GetStringHeight() + 4))
                    ST.historyDetailsScroll:SetVerticalScroll(0)
                end)
                local remove = CreateFrame("Button", nil, row)
                remove:SetSize(20, 20)
                remove:SetPoint("RIGHT", 0, 0)
                local label = remove:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                label:SetPoint("CENTER")
                label:SetText("x")
                remove:SetScript("OnClick", function()
                    for index, item in ipairs(ST.db.history) do
                        if item == row.entry then table.remove(ST.db.history, index); break end
                    end
                    ST.historyDetails:SetText("")
                    ST:RefreshHistory()
                    ST:SaveDB()
                end)
                self.historyRows[i] = row
            end
            row.entry = entry
            local summary = self:HistoryText(entry):match("^[^\n]+")
            row.text:SetText(summary)
            row:Show()
        elseif row then row.entry = nil; row:Hide() end
    end
    self.historyChild:SetHeight(math.max(20, #history * 24))
end

function ST:CreateHistoryUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", 8, -4)
    scroll:SetPoint("BOTTOMRIGHT", -8, 74)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(s, delta)
        s:SetVerticalScroll(math.max(0, math.min(s:GetVerticalScrollRange(), s:GetVerticalScroll() - delta * 24)))
    end)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(400, 20)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(_, width) child:SetWidth(math.max(1, width)) end)
    self.historyChild, self.historyRows = child, {}
    local detailsScroll = CreateFrame("ScrollFrame", nil, frame)
    detailsScroll:SetPoint("BOTTOMLEFT", 12, 36)
    detailsScroll:SetPoint("BOTTOMRIGHT", -130, 36)
    detailsScroll:SetHeight(36)
    detailsScroll:EnableMouseWheel(true)
    detailsScroll:SetScript("OnMouseWheel", function(s, delta)
        s:SetVerticalScroll(math.max(0, math.min(s:GetVerticalScrollRange(), s:GetVerticalScroll() - delta * 16)))
    end)
    local detailsChild = CreateFrame("Frame", nil, detailsScroll)
    detailsChild:SetSize(250, 40)
    detailsScroll:SetScrollChild(detailsChild)
    detailsScroll:SetScript("OnSizeChanged", function(_, width) detailsChild:SetWidth(math.max(1, width)) end)
    self.historyDetailsChild, self.historyDetailsScroll = detailsChild, detailsScroll
    self.historyDetails = detailsChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.historyDetails:SetPoint("TOPLEFT", 0, 0)
    self.historyDetails:SetPoint("TOPRIGHT", 0, 0)
    self.historyDetails:SetJustifyH("LEFT")
    local clear = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clear:SetSize(112, 25)
    clear:SetPoint("BOTTOMRIGHT", -8, 8)
    clear:SetText("Clear history")
    clear:SetScript("OnClick", function()
        StaticPopup_Show("SIMPLETOOLS_CLEAR_HISTORY")
    end)
    StaticPopupDialogs.SIMPLETOOLS_CLEAR_HISTORY = {
        text = "Delete all saved sessions?", button1 = YES, button2 = NO,
        OnAccept = function() ST.db.history = {}; ST.historyDetails:SetText(""); ST:RefreshHistory(); ST:SaveDB() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    return frame
end
