local addonName, ST = ...

local CreateFrame = CreateFrame
local date = date

function ST:CreateSimpleReminderUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.reminderFrame = frame

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    label:SetPoint("TOP", 0, -10)
    label:SetText("Set reminder (HH:MM)")

    self.reminderInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.reminderInput:SetSize(80, 20)
    self.reminderInput:SetPoint("TOP", 0, -40)
    self.reminderInput:SetAutoFocus(false)
    self.reminderInput:SetMaxLetters(5)
    self.reminderInput:SetText(date("%H:%M"))

    self.remSetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.remSetButton:SetSize(80, 25)
    self.remSetButton:SetPoint("BOTTOMLEFT", 10, 8)
    self.remSetButton:SetText("Set")
    self.remSetButton:SetScript("OnClick", function()
        ST:SetReminder(self.reminderInput:GetText())
    end)

    self.remClearButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.remClearButton:SetSize(80, 25)
    self.remClearButton:SetPoint("BOTTOMRIGHT", -10, 8)
    self.remClearButton:SetText("Clear")
    self.remClearButton:SetScript("OnClick", function()
        ST:ClearReminder()
    end)

    self.reminderStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.reminderStatus:SetPoint("TOP", 0, -78)
    self.reminderStatus:SetText("No reminder set")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", self.reminderStatus, "BOTTOM", 0, -8)
    hint:SetText("24-hour clock. Fires once per day until cleared.")

    return frame
end

function ST:SetReminder(timeStr)
    timeStr = strtrim(timeStr or "")
    local h, m = timeStr:match("^(%d%d):(%d%d)$")
    h, m = tonumber(h), tonumber(m)
    if not h or not m or h > 23 or m > 59 then
        self:Print("Invalid time. Use HH:MM (00:00–23:59).")
        return
    end
    timeStr = string.format("%02d:%02d", h, m)
    self.reminder.time = timeStr
    self.reminder.set = true
    self.reminder.lastFired = ""
    self.reminderStatus:SetText("Alarm set for: " .. timeStr)
    self:Print("Alarm set for " .. timeStr)
    self:SaveDB()
    self:RefreshTicker()
end

function ST:ClearReminder()
    self.reminder.time = nil
    self.reminder.set = false
    self.reminder.lastFired = ""
    self.reminderStatus:SetText("No reminder set")
    self:Print("Reminder cleared.")
    self:SaveDB()
    self:RefreshTicker()
end

function ST:CheckReminder()
    if not self.reminder.set or not self.reminder.time then
        return
    end
    local currentTime = date("%H:%M")
    if currentTime == self.reminder.time and self.reminder.lastFired ~= currentTime then
        self:PlayAlert()
        self:Print("Reminder — it is " .. currentTime)
        self.reminder.lastFired = currentTime
    end
end
