local addonName, ST = ...

local CreateFrame = CreateFrame
local date = date

function ST:CreateSimpleReminderUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.reminderFrame = frame

    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOP", 0, -2)
    heading:SetText("Reminder")

    self.reminderInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.reminderInput:SetSize(56, 18)
    self.reminderInput:SetPoint("TOP", heading, "BOTTOM", 0, -6)
    self.reminderInput:SetAutoFocus(false)
    self.reminderInput:SetMaxLetters(5)
    self.reminderInput:SetText(date("%H:%M"))

    self.reminderMessageInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.reminderMessageInput:SetHeight(18)
    self.reminderMessageInput:SetPoint("TOPLEFT", 8, -48)
    self.reminderMessageInput:SetPoint("TOPRIGHT", -8, -48)
    self.reminderMessageInput:SetAutoFocus(false)
    self.reminderMessageInput:SetMaxLetters(80)
    self.reminderMessageInput:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    self.reminderMessageInput:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)

    self.reminderStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.reminderStatus:SetPoint("TOPLEFT", 4, -72)
    self.reminderStatus:SetPoint("TOPRIGHT", -4, -72)
    self.reminderStatus:SetText("No reminder set")

    self.remSetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.remSetButton:SetText("Set")
    self.remSetButton:SetScript("OnClick", function()
        ST:SetReminder(self.reminderInput:GetText())
    end)

    self.remClearButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.remClearButton:SetText("Clear")
    self.remClearButton:SetScript("OnClick", function()
        ST:ClearReminder()
    end)

    self:LayoutColumnButtons(frame, self.remSetButton, self.remClearButton)

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
    local message = ""
    if self.reminderMessageInput then
        message = strtrim(self.reminderMessageInput:GetText() or "")
    end
    self.reminder.time = timeStr
    self.reminder.message = message
    self.reminder.set = true
    self.reminder.lastFired = ""
    self.reminderStatus:SetText("Alarm set for: " .. timeStr)
    self:Print("Alarm set for " .. timeStr)
    self:SaveDB()
    self:RefreshTicker()
end

function ST:ClearReminder()
    self.reminder.time = nil
    self.reminder.message = nil
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
        local message = self.reminder.message
        if type(message) == "string" and message ~= "" then
            self:Print(message)
        else
            self:Print("Reminder — it is " .. currentTime)
        end
        self.reminder.lastFired = currentTime
    end
end
