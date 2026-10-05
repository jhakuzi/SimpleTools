local addonName, ST = ...
local CreateFrame = CreateFrame
ST.calculatorExpression = ""
ST.calculatorHistory = {}
ST.calculatorViews = {}

-- A bounded arithmetic parser. Never evaluate an expression as Lua code.
function ST:Calculate(expression)
    if type(expression) ~= "string" or #expression > 160 then return nil, "Use at most 160 characters." end
    local index, depth = 1, 0
    local parseExpression, parseUnary
    local function skip()
        while expression:sub(index, index):match("%s") do index = index + 1 end
    end
    local function finite(value)
        if not value or value ~= value or math.abs(value) == math.huge then error("Result is too large.", 0) end
        return value
    end
    local function primary()
        skip()
        if expression:sub(index, index) == "(" then
            index = index + 1
            local value = parseExpression()
            skip()
            if expression:sub(index, index) ~= ")" then error("Missing closing parenthesis.", 0) end
            index = index + 1
            return value
        end
        local rest = expression:sub(index)
        local number = rest:match("^%d+%.?%d*") or rest:match("^%.%d+")
        if not number then error("Expected a number or parenthesis.", 0) end
        index = index + #number
        local exponent = expression:sub(index):match("^[eE][+-]?%d+")
        if exponent then number = number .. exponent; index = index + #exponent end
        return finite(tonumber(number))
    end
    parseUnary = function()
        depth = depth + 1
        if depth > 32 then error("Too many nested parentheses or signs.", 0) end
        skip()
        local sign = expression:sub(index, index)
        local value
        if sign == "+" or sign == "-" then
            index = index + 1
            value = parseUnary()
            if sign == "-" then value = -value end
        else value = primary() end
        depth = depth - 1
        return value
    end
    local function term()
        local value = parseUnary()
        while true do
            skip()
            local op = expression:sub(index, index)
            if op ~= "*" and op ~= "/" then return value end
            index = index + 1
            local right = parseUnary()
            if op == "/" and right == 0 then error("Cannot divide by zero.", 0) end
            value = finite(op == "*" and value * right or value / right)
        end
    end
    parseExpression = function()
        local value = term()
        while true do
            skip()
            local op = expression:sub(index, index)
            if op ~= "+" and op ~= "-" then return value end
            index = index + 1
            local right = term()
            value = finite(op == "+" and value + right or value - right)
        end
    end
    local ok, value = pcall(function()
        local result = parseExpression()
        skip()
        if index <= #expression then error("Use numbers and + - * / ( ).", 0) end
        return finite(result)
    end)
    if not ok then return nil, value end
    return value
end

function ST:UpdateCalculatorViews()
    for _, view in ipairs(self.calculatorViews) do
        if view.input:GetText() ~= self.calculatorExpression then
            view.input:SetText(self.calculatorExpression)
        end
        view.result:SetText(self.calculatorResult or "")
    end
    if not self.calculatorHistoryRows then return end
    for i, row in ipairs(self.calculatorHistoryRows) do
        local entry = self.calculatorHistory[i]
        row.entry = entry
        row:SetShown(entry ~= nil)
        if entry then row.text:SetText(entry.expression .. " = " .. entry.result) end
    end
    self.calculatorHistoryChild:SetHeight(math.max(20, #self.calculatorHistory * 20))
    self.calculatorHistoryClear:SetEnabled(#self.calculatorHistory > 0)
end

function ST:RemoveCalculatorHistory(entry)
    for index, item in ipairs(self.calculatorHistory) do
        if item == entry then
            table.remove(self.calculatorHistory, index)
            self:UpdateCalculatorViews()
            return
        end
    end
end

function ST:ClearCalculatorHistory()
    self.calculatorHistory = {}
    self:UpdateCalculatorViews()
end

function ST:EvaluateCalculator()
    local expression = strtrim(self.calculatorExpression)
    if expression == "" and self.calculatorAnswer then return tonumber(self.calculatorAnswer) end
    if expression:match("^[+*/%-]") and self.calculatorAnswer then
        expression = "(" .. self.calculatorAnswer .. ")" .. expression
    end
    local value, message = self:Calculate(expression)
    if value == nil then
        self.calculatorResult = message
    else
        local result = string.format("%.12g", value == 0 and 0 or value)
        self.calculatorResult = "= " .. result
        self.calculatorAnswer = result
        local last = self.calculatorHistory[1]
        if not last or last.expression ~= expression or last.result ~= result then
            table.insert(self.calculatorHistory, 1, {expression = expression, result = result})
            if #self.calculatorHistory > 10 then table.remove(self.calculatorHistory) end
        end
        self.calculatorExpression = ""
    end
    self:UpdateCalculatorViews()
    if value ~= nil then
        for _, view in ipairs(self.calculatorViews) do view.input:SetCursorPosition(0) end
    end
    return value
end

function ST:CreateCalculatorControls(parent, x, y, width)
    local view = {}
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width, 20)
    input:SetPoint("TOPLEFT", x, y)
    input:SetAutoFocus(false)
    input:SetMaxLetters(160)
    input:SetScript("OnTextChanged", function(selfBox, userInput)
        if userInput then
            ST.calculatorExpression = selfBox:GetText()
            ST.calculatorResult = nil
            ST:UpdateCalculatorViews()
        end
    end)
    input:SetScript("OnEnterPressed", function() ST:EvaluateCalculator() end)
    input:SetScript("OnEscapePressed", function(selfBox) selfBox:ClearFocus() end)
    view.input = input
    view.result = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.result:SetPoint("TOPLEFT", x, y - 25)
    view.result:SetWidth(width)
    view.result:SetJustifyH("LEFT")
    view.result:SetWordWrap(false)
    table.insert(self.calculatorViews, view)
    local keys = {"7", "8", "9", "/", "C", "4", "5", "6", "*", "Back", "1", "2", "3", "-", "(", "0", ".", "=", "+", ")"}
    view.keys = {}
    local gap = 3
    local keyWidth = (width - 4 * gap) / 5
    for i, key in ipairs(keys) do
        local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
        button:SetSize(keyWidth, 20)
        button:SetPoint("TOPLEFT", x + ((i - 1) % 5) * (keyWidth + gap), y - 50 - math.floor((i - 1) / 5) * 23)
        button:SetNormalFontObject("GameFontNormalSmall")
        button:SetText(key)
        button:SetScript("OnClick", function()
            if key == "=" then ST:EvaluateCalculator(); return end
            if key == "C" then
                ST.calculatorExpression, ST.calculatorResult = "", nil
                ST.calculatorAnswer = nil
                ST:UpdateCalculatorViews()
            elseif key == "Back" then
                local text, cursor = input:GetText(), input:GetCursorPosition()
                if cursor > 0 then
                    ST.calculatorExpression = text:sub(1, cursor - 1) .. text:sub(cursor + 1)
                    ST.calculatorResult = nil
                    ST:UpdateCalculatorViews()
                    input:SetCursorPosition(cursor - 1)
                end
            else
                input:Insert(key)
                -- Programmatic Insert can fire OnTextChanged with userInput=false.
                ST.calculatorExpression = input:GetText()
                ST.calculatorResult = nil
                ST:UpdateCalculatorViews()
            end
            input:SetFocus()
        end)
        view.keys[key] = button
    end
    self:UpdateCalculatorViews()
    return view
end

function ST:ShowCalculatorProjected(show, pos)
    if not self.calculatorProjectedFrame and show then
        local frame = self:CreateOverlayFrame("SimpleToolsCalculatorOverlay", 246, 180, 240, -120, "Calculator", function()
            ST:ShowCalculatorProjected(false)
        end)
        frame.overlayHint = "Type arithmetic or use the keypad. Drag the border to move."
        self:CreateCalculatorControls(frame, 12, -12, 222)
        self.calculatorProjectedFrame = frame
    end
    self.calculatorProjected = show == true
    if self.calculatorProjectedFrame then
        if show then self:PlaceOverlay(self.calculatorProjectedFrame, pos) end
        self.calculatorProjectedFrame:SetShown(self.calculatorProjected)
    end
    if self.calculatorProjectButton then self.calculatorProjectButton:SetText(show and "Unproject" or "Send to screen") end
    self:SaveDB()
end

function ST:CreateCalculatorUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self:CreateCalculatorControls(frame, 8, -2, 192)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 216, -5)
    title:SetText("History")
    local clear = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clear:SetSize(60, 20)
    clear:SetPoint("TOPRIGHT", -8, -2)
    clear:SetText("Clear")
    clear:SetScript("OnClick", function() ST:ClearCalculatorHistory() end)
    self.calculatorHistoryClear = clear
    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 212, -26)
    box:SetPoint("BOTTOMRIGHT", -8, 38)
    self:ApplyOverlayBackdrop(box)
    local scroll = CreateFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", 6, -4)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfScroll, delta)
        selfScroll:SetVerticalScroll(math.max(0, math.min(selfScroll:GetVerticalScrollRange(), selfScroll:GetVerticalScroll() - delta * 20)))
    end)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(240, 20)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(_, width) child:SetWidth(math.max(1, width)) end)
    self.calculatorHistoryChild, self.calculatorHistoryRows = child, {}
    for i = 1, 10 do
        local row = CreateFrame("Button", nil, child)
        row:SetHeight(20)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 20)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * 20)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetPoint("RIGHT", -22, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        local remove = CreateFrame("Button", nil, row)
        remove:SetSize(16, 16)
        remove:SetPoint("RIGHT", -2, 0)
        local label = remove:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER")
        label:SetText("x")
        remove:SetScript("OnClick", function() ST:RemoveCalculatorHistory(row.entry) end)
        row.remove = remove
        row:SetScript("OnClick", function(selfRow)
            if selfRow.entry then
                ST.calculatorExpression = selfRow.entry.expression
                ST.calculatorResult = "= " .. selfRow.entry.result
                ST.calculatorAnswer = selfRow.entry.result
                ST:UpdateCalculatorViews()
            end
        end)
        self.calculatorHistoryRows[i] = row
    end
    local project = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    project:SetSize(112, 25)
    project:SetPoint("BOTTOMRIGHT", -8, 8)
    project:SetText("Send to screen")
    project:SetScript("OnClick", function() ST:ShowCalculatorProjected(not ST.calculatorProjected) end)
    self.calculatorProjectButton = project
    self:UpdateCalculatorViews()
    return frame
end
