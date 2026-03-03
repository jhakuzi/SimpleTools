local addonName, SimpleTools = ...

-- Localize WoW API
local CreateFrame = CreateFrame
local date = date
local PlaySound = PlaySound

-- Reminder variables
SimpleTools.reminderTime = nil
SimpleTools.reminderSet = false
SimpleTools.lastReminderCheck = ""

-- Create Reminder UI
function SimpleTools:CreateSimpleReminderUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    
    self.reminderFrame = frame

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    label:SetPoint("TOP", 0, -10)
    label:SetText("Set Reminder Time (HH:MM)")

    -- Input Box
    self.reminderInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.reminderInput:SetSize(80, 20)
    self.reminderInput:SetPoint("TOP", 0, -40)
    self.reminderInput:SetAutoFocus(false)
    self.reminderInput:SetMaxLetters(5)
    self.reminderInput:SetText(date("%H:%M"))

    -- Set Button
    self.remSetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.remSetButton:SetSize(80, 25)
    self.remSetButton:SetPoint("TOPLEFT", frame, "CENTER", -85, -20)
    self.remSetButton:SetText("Set")
    self.remSetButton:SetScript("OnClick", function() 
        SimpleTools:SetReminder(self.reminderInput:GetText())
    end)

    -- Clear Button
    self.remClearButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.remClearButton:SetSize(80, 25)
    self.remClearButton:SetPoint("LEFT", self.remSetButton, "RIGHT", 10, 0)
    self.remClearButton:SetText("Clear")
    self.remClearButton:SetScript("OnClick", function() 
        SimpleTools:ClearReminder()
    end)
    
    -- Status Display
    self.reminderStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.reminderStatus:SetPoint("TOP", 0, -110)
    self.reminderStatus:SetText("No reminder set")

    return frame
end

-- Validate and set reminder
function SimpleTools:SetReminder(timeStr)
    -- Simple validation regex for HH:MM
    if not timeStr:match("^%d%d:%d%d$") then
        print("SimpleTools: Invalid format. Use HH:MM")
        return
    end

    self.reminderTime = timeStr
    self.reminderSet = true
    self.reminderStatus:SetText("Alarm set for: " .. timeStr)
    print("SimpleTools: Alarm set for " .. timeStr)
    SimpleTools:SaveVariables()
end

-- Clear reminder
function SimpleTools:ClearReminder()
    self.reminderTime = nil
    self.reminderSet = false
    self.reminderStatus:SetText("No reminder set")
    print("SimpleTools: Reminder cleared")
    SimpleTools:SaveVariables()
end

-- Check reminder loop
function SimpleTools:CheckReminder()
    if not self.reminderSet or not self.reminderTime then return end

    local currentTime = date("%H:%M")
    
    -- Check if times match and we haven't already fired for this minute
    if currentTime == self.reminderTime and self.lastReminderCheck ~= currentTime then
        PlaySound(8960, "Master") -- Same sound as timer finish
        print("SimpleTools: REMINDER! It is " .. currentTime)
        self.lastReminderCheck = currentTime
        
        -- Optional: clear after firing? Or keep it for next day? 
        -- For now, let's just let it ring once per minute (guarded by lastReminderCheck)
    end
end
