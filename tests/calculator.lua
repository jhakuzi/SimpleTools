-- Run from the repository root: lua5.1 tests/calculator.lua
-- Reuse game/frame stubs; exercise real calculator controls and parser.
dofile('tests/new-tools.lua')
local ST, checks = SimpleTools, 0
assert(loadfile('SimpleCalculator.lua'))('SimpleTools', ST)
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
    checks = checks + 1
end
for _, sample in ipairs({{'2+3*4',14},{'(12+8)*3',60},{'10-3-2',5},{'20/2/2',5},
    {'-2*-3',6},{'-(2+3)',-5},{' .5 + 1.25 ',1.75},{'5.',5},{'1e-5*100000',1},
    {'2 + +3',5},{'0*4',0},{'(2+3)/(4-2)',2.5},{'1/4',0.25}}) do
    equal(ST:Calculate(sample[1]),sample[2])
end
for _, expression in ipairs({'', '1/0', '1/(2-2)', '(1+2', '1+2)', '1..2', '1 2',
    '2^3', '2(3)', 'math.sin(1)', 'os.execute("oops")', '1e999', '1e308*10', '1e308+1e308',
    string.rep('(',40)..'1'..string.rep(')',40), string.rep('-',40)..'1', string.rep('1',161)}) do
    local result, message=ST:Calculate(expression)
    equal(result,nil)
    assert(type(message)=='string' and #message>0); checks=checks+1
end
local frame=ST:CreateCalculatorUI(ST.contentFrame)
ST.tabFrames[9]=frame
local view=ST.calculatorViews[1]
local methods=getmetatable(view.input).__index
function methods:GetCursorPosition() return self.cursor or #self.text end
function methods:SetCursorPosition(value) self.cursor=value end
function methods:Insert(value)
    local cursor=self:GetCursorPosition()
    self.text=self.text:sub(1,cursor)..value..self.text:sub(cursor+1)
    self.cursor=cursor+#value
    self.scripts.OnTextChanged(self,false)
end
local function typed(text)
    view.input:SetText(text)
    view.input:SetCursorPosition(#text)
    view.input.scripts.OnTextChanged(view.input,true)
end
typed('12+8')
view.input.scripts.OnEnterPressed()
equal(ST.calculatorResult,'= 20')
equal(#ST.calculatorHistory,1)
view.keys['='].scripts.OnClick()
equal(#ST.calculatorHistory,1)
equal(ST.calculatorExpression,'')
equal(view.input:GetText(),'')
typed('12+8')
view.keys['Back'].scripts.OnClick()
equal(ST.calculatorExpression,'12+')
view.keys['3'].scripts.OnClick()
equal(ST.calculatorExpression,'12+3')
view.keys['='].scripts.OnClick()
equal(ST.calculatorResult,'= 15')
ST.calculatorHistoryRows[2].scripts.OnClick(ST.calculatorHistoryRows[2])
equal(ST.calculatorExpression,'12+8')
equal(ST.calculatorResult,'= 20')
typed('1/0')
ST:EvaluateCalculator()
equal(#ST.calculatorHistory,2)
equal(ST.calculatorResult,'Cannot divide by zero.')
view.keys['C'].scripts.OnClick()
equal(ST.calculatorExpression,'')
equal(ST.calculatorResult,nil)
for i=1,15 do typed(i..'+1'); ST:EvaluateCalculator() end
equal(#ST.calculatorHistory,10)
equal(ST.calculatorHistory[1].result,'16')
ST:ShowCalculatorProjected(true)
equal(ST.calculatorProjectedFrame.shown,true)
equal(ST.db.calculator.projected,true)
equal(#ST.calculatorViews,2)
equal(ST.calculatorViews[2].input:GetText(),ST.calculatorExpression)
local projected=ST.calculatorViews[2]
projected.input:SetText('5*6')
projected.input.scripts.OnTextChanged(projected.input,true)
projected.keys['='].scripts.OnClick()
equal(ST.calculatorResult,'= 30')
equal(view.input:GetText(),'')
equal(view.result.text,'= 30')
ST.calculatorProjectedFrame:SetPoint('CENTER',UIParent,'CENTER',20,30)
ST:SaveDB()
equal(ST.db.calculator.projX,20)
equal(ST.db.calculator.projY,30)
ST:SelectTab(9)
ST:LoadState()
equal(ST.db.ui.selectedTab,9)
equal(ST.calculatorProjectedFrame.point[4],20)
ST.calculatorProjectedFrame.closeButton.scripts.OnClick()
equal(ST.db.calculator.projected,false)
equal(ST.calculatorProjectedFrame.shown,false)
-- Backspace edits at the cursor rather than always removing the final digit.
typed('123')
view.input:SetCursorPosition(1)
view.keys['Back'].scripts.OnClick()
equal(ST.calculatorExpression,'23')
equal(view.input:GetCursorPosition(),0)
-- History deletion affects only the selected entry; clearing preserves the calculation.
local originalExpression, originalResult = ST.calculatorExpression, ST.calculatorResult
local removed, nextEntry = ST.calculatorHistory[1], ST.calculatorHistory[2]
ST.calculatorHistoryRows[1].remove.scripts.OnClick()
equal(#ST.calculatorHistory,9)
equal(ST.calculatorHistory[1],nextEntry)
equal(ST.calculatorHistoryRows[1].entry,nextEntry)
equal(ST.calculatorExpression,originalExpression)
equal(ST.calculatorResult,originalResult)
ST:RemoveCalculatorHistory(removed)
equal(#ST.calculatorHistory,9)
ST.calculatorHistoryClear.scripts.OnClick()
equal(#ST.calculatorHistory,0)
equal(ST.calculatorHistoryRows[1].shown,false)
equal(ST.calculatorHistoryClear.enabled,false)
equal(ST.calculatorExpression,originalExpression)
equal(ST.calculatorResult,originalResult)
equal(view.result.text,'')
-- Continue from the previous answer, with normal precedence within new operands.
typed('6+6')
view.input.scripts.OnEnterPressed()
equal(ST.calculatorAnswer,'12')
equal(view.input:GetText(),'')
typed('*8')
view.input.scripts.OnEnterPressed()
equal(ST.calculatorResult,'= 96')
equal(ST.calculatorHistory[1].expression,'(12)*8')
equal(projected.input:GetText(),'')
typed('/4')
equal(ST:EvaluateCalculator(),24)
typed('+2')
equal(ST:EvaluateCalculator(),26)
typed('-6')
equal(ST:EvaluateCalculator(),20)
typed('5+5')
equal(ST:EvaluateCalculator(),10)
local historyCount=#ST.calculatorHistory
view.keys['='].scripts.OnClick()
equal(#ST.calculatorHistory,historyCount)
typed('/0')
equal(ST:EvaluateCalculator(),nil)
equal(ST.calculatorExpression,'/0')
equal(ST.calculatorAnswer,'10')
typed('*3')
equal(ST:EvaluateCalculator(),30)
view.keys['C'].scripts.OnClick()
equal(ST.calculatorAnswer,nil)
typed('*8')
equal(ST:EvaluateCalculator(),nil)
print(string.format('PASS: %d calculator assertions',checks))
