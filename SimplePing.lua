--[[
  Ping wheel, merged from JhakPing.
  Hold the bound key, aim, release to send a Blizzard /ping.
  The bind UI lives on the Ping tab. The catcher name stays JhakPingCatcher
  so an existing keybind keeps working after the old addon is disabled.
]]

local addonName, ST = ...

local CMD = "CLICK JhakPingCatcher:LeftButton"
local RADIUS = 118
local DEADZONE = 28

BINDING_HEADER_JHAKPING = "SimpleTools"
_G["BINDING_NAME_" .. CMD] = "Ping Wheel"

local SLICES = {
    { id = "attack",  label = "Attack",    macro = "/ping attack",  angle = math.pi,      r = 0.86, g = 0.27, b = 0.24, letter = "A" },
    { id = "warning", label = "Warning",   macro = "/ping warning", angle = math.pi / 2,  r = 0.90, g = 0.72, b = 0.28, letter = "!" },
    { id = "onmyway", label = "On My Way", macro = "/ping onmyway", angle = 0,            r = 0.32, g = 0.58, b = 0.86, letter = "GO" },
    { id = "assist",  label = "Assist",    macro = "/ping assist",  angle = -math.pi / 2, r = 0.22, g = 0.68, b = 0.42, letter = "+" },
}

local CONTEXT = { id = "ping", label = "Ping", macro = "/ping", r = 0.93, g = 0.90, b = 0.82, letter = "P" }

local JP = {}
ST.ping = JP

local catcher
local wheel
local buttons = {}
local panel
local captureArmed = false

local function Print(msg)
    ST:Print(msg)
end

local function DB()
    local root = ST.db
    if type(root) ~= "table" then
        return { quickTap = true }
    end
    if type(root.ping) ~= "table" then
        root.ping = { quickTap = true }
    end
    if root.ping.quickTap == nil then
        root.ping.quickTap = true
    end
    if not root.ping.migrated and type(JhakPingDB) == "table" then
        if JhakPingDB.quickTap ~= nil then
            root.ping.quickTap = JhakPingDB.quickTap and true or false
        end
        if JhakPingDB.key and not root.ping.key then
            root.ping.key = JhakPingDB.key
        end
        root.ping.migrated = true
    end
    return root.ping
end

local function PrettyKey(key)
    if not key or key == "" then
        return "Unbound"
    end
    key = key:gsub("^ALT%-", "Alt+")
    key = key:gsub("^CTRL%-", "Ctrl+")
    key = key:gsub("^SHIFT%-", "Shift+")
    key = key:gsub("ALT%-", "Alt+")
    key = key:gsub("CTRL%-", "Ctrl+")
    key = key:gsub("SHIFT%-", "Shift+")
    key = key:gsub("BUTTON(%d+)", "Mouse %1")
    key = key:gsub("^Mouse 1$", "Left Mouse")
    key = key:gsub("^Mouse 2$", "Right Mouse")
    key = key:gsub("^Mouse 3$", "Middle Mouse")
    return key
end

local function CurrentKey()
    if not GetBindingKey then
        return DB().key
    end
    local a, b = GetBindingKey(CMD)
    return a or b or DB().key
end

local function BindingFromKey(key)
    if not key or key == "UNKNOWN" or key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
        return nil
    end
    if key == "ESCAPE" then
        return nil
    end
    local parts = {}
    if IsAltKeyDown() then
        parts[#parts + 1] = "ALT"
    end
    if IsControlKeyDown() then
        parts[#parts + 1] = "CTRL"
    end
    if IsShiftKeyDown() then
        parts[#parts + 1] = "SHIFT"
    end
    parts[#parts + 1] = key
    return table.concat(parts, "-")
end

local function Pick(px, py)
    if (px * px + py * py) < 1 then
        if DB().quickTap then
            return "ping"
        end
        return nil
    end
    if math.abs(px) > math.abs(py) then
        if px >= 0 then
            return "onmyway"
        end
        return "attack"
    end
    if py >= 0 then
        return "warning"
    end
    return "assist"
end

local function SliceById(id)
    if id == "ping" then
        return CONTEXT
    end
    for i = 1, #SLICES do
        if SLICES[i].id == id then
            return SLICES[i]
        end
    end
end

local function TryAtlas(tex, names)
    if not (C_Texture and C_Texture.GetAtlasInfo and tex.SetAtlas) then
        return false
    end
    for i = 1, #names do
        local name = names[i]
        local info = C_Texture.GetAtlasInfo(name)
        if info then
            tex:SetAtlas(name)
            return true
        end
    end
    return false
end

local ATLAS = {
    attack = { "Ping_Marker_Attack", "ping_marker_attack" },
    warning = { "Ping_Marker_Warning", "ping_marker_warning" },
    assist = { "Ping_Marker_Assist", "ping_marker_assist" },
    onmyway = { "Ping_Marker_OnMyWay", "ping_marker_onmyway" },
    ping = { "Ping_Marker_NonThreat", "ping_marker_nonthreat" },
}

local function Decorate(parent, slice, size)
    local disc = parent:CreateTexture(nil, "BACKGROUND")
    disc:SetSize(size, size)
    disc:SetPoint("CENTER")
    disc:SetColorTexture(0.08, 0.07, 0.06, 0.94)
    local edge = parent:CreateTexture(nil, "BORDER")
    edge:SetSize(size + 4, size + 4)
    edge:SetPoint("CENTER")
    edge:SetColorTexture(slice.r, slice.g, slice.b, 0.95)
    local mask = parent:CreateTexture(nil, "ARTWORK")
    mask:SetSize(size - 6, size - 6)
    mask:SetPoint("CENTER")
    mask:SetColorTexture(0.11, 0.10, 0.09, 1)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetSize(math.max(8, size - 22), math.max(8, size - 22))
    icon:SetPoint("CENTER", 0, 6)
    local letter = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    letter:SetPoint("CENTER", 0, 2)
    letter:SetText(slice.letter)
    letter:SetTextColor(slice.r, slice.g, slice.b)
    if TryAtlas(icon, ATLAS[slice.id] or {}) then
        letter:Hide()
    else
        icon:Hide()
    end
    local name = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("TOP", parent, "BOTTOM", 0, -2)
    name:SetText(slice.label)
    name:SetTextColor(0.93, 0.90, 0.82)
    parent.jhakEdge = edge
    parent.jhakName = name
    return parent
end

local function MakeSecureButton(name, slice)
    local btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    btn:SetSize(1, 1)
    btn:SetPoint("CENTER", UIParent, "CENTER", 0, -400)
    btn:SetAlpha(0)
    btn:EnableMouse(false)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", slice.macro)
    btn:SetAttribute("useOnKeyDown", false)
    btn:SetScript("PostClick", function()
        if JP.secure then
            return
        end
        JP:ShutdownFallback()
    end)
    buttons[slice.id] = btn
    return btn
end

local SNIPPET = [[
if button ~= "LeftButton" then
  return false
end
local pressed = down
if pressed == nil then
  pressed = self:GetAttribute("open") ~= "1"
end
if pressed then
  local x, y = self:GetMousePosition()
  if x and y then
    self:SetAttribute("ax", x)
    self:SetAttribute("ay", y)
  end
  self:SetAttribute("open", "1")
  self:SetAttribute("type", nil)
  self:SetAttribute("macrotext", nil)
  return false
end
if self:GetAttribute("open") ~= "1" then
  return false
end
local x, y = self:GetMousePosition()
local ax = self:GetAttribute("ax")
local ay = self:GetAttribute("ay")
if not x or not y or not ax or not ay then
  self:SetAttribute("open", "0")
  self:SetAttribute("type", nil)
  return false
end
local dx = x - ax
local dy = y - ay
local deadx = self:GetAttribute("deadx") or 0.02
local deady = self:GetAttribute("deady") or 0.02
if deadx == 0 then
  deadx = 0.02
end
if deady == 0 then
  deady = 0.02
end
local px = dx / deadx
local py = dy / deady
local which = nil
if (px * px + py * py) >= 1 then
  if abs(px) > abs(py) then
    if dx >= 0 then
      which = "onmyway"
    else
      which = "attack"
    end
  else
    if dy >= 0 then
      which = "warning"
    else
      which = "assist"
    end
  end
elseif self:GetAttribute("quicktap") then
  which = "ping"
end
self:SetAttribute("open", "0")
self:SetAttribute("slice", which or "")
if not which then
  self:SetAttribute("type", nil)
  self:SetAttribute("macrotext", nil)
  return false
end
local macro = self:GetAttribute("m-" .. which)
if not macro then
  self:SetAttribute("type", nil)
  return false
end
self:SetAttribute("macrotext", macro)
self:SetAttribute("type", "macro")
]]

local function SnippetsWork(frame)
    if type(frame.Execute) ~= "function" then
        return false
    end
    local ok = pcall(frame.Execute, frame, [[ self:SetAttribute("jhakProbe", 1) ]])
    return ok and frame:GetAttribute("jhakProbe") == 1
end

function JP:UpdateDeadzone()
    if not catcher or InCombatLockdown() then
        self.deadDirty = true
        return
    end
    local w = catcher:GetWidth()
    local h = catcher:GetHeight()
    if not w or w <= 0 then
        w = GetScreenWidth()
    end
    if not h or h <= 0 then
        h = GetScreenHeight()
    end
    catcher:SetAttribute("deadx", DEADZONE / w)
    catcher:SetAttribute("deady", DEADZONE / h)
    if DB().quickTap then
        catcher:SetAttribute("quicktap", true)
    else
        catcher:SetAttribute("quicktap", nil)
    end
    self.deadDirty = nil
end

function JP:CloseVisual()
    if not wheel then
        return
    end
    wheel.preview = nil
    wheel:EnableKeyboard(false)
    wheel:Hide()
    if wheel.hubText then
        wheel.hubText:SetText("")
    end
end

function JP:PlaceWheel(nx, ny)
    nx = tonumber(nx) or 0.5
    ny = tonumber(ny) or 0.5
    wheel.anchorNX = nx
    wheel.anchorNY = ny
    wheel:ClearAllPoints()
    wheel:SetPoint("CENTER", catcher, "BOTTOMLEFT", nx * catcher:GetWidth(), ny * catcher:GetHeight())
    wheel:Show()
end

function JP:OpenAtCursor()
    local x, y = GetCursorPosition()
    local scale = catcher:GetEffectiveScale()
    if scale and scale > 0 then
        x, y = x / scale, y / scale
    end
    local left, bottom, width, height = catcher:GetRect()
    local nx, ny = 0.5, 0.5
    if left and width and width > 0 and height and height > 0 then
        nx = (x - left) / width
        ny = (y - bottom) / height
    end
    self:PlaceWheel(nx, ny)
end

function JP:CursorNorm()
    local x, y = GetCursorPosition()
    local scale = catcher:GetEffectiveScale()
    if scale and scale > 0 then
        x, y = x / scale, y / scale
    end
    local left, bottom, width, height = catcher:GetRect()
    if not (left and width and width > 0 and height and height > 0) then
        return nil
    end
    return (x - left) / width, (y - bottom) / height
end

function JP:Highlight()
    if not wheel:IsShown() then
        return
    end
    if self.secure and catcher and catcher:GetAttribute("open") == "1" then
        local ax = tonumber(catcher:GetAttribute("ax"))
        local ay = tonumber(catcher:GetAttribute("ay"))
        if ax and ay then
            wheel.anchorNX = ax
            wheel.anchorNY = ay
        end
    end
    local nx, ny = self:CursorNorm()
    if not nx then
        return
    end
    local deadx = DEADZONE / math.max(catcher:GetWidth(), 1)
    local deady = DEADZONE / math.max(catcher:GetHeight(), 1)
    local px = (nx - (wheel.anchorNX or nx)) / deadx
    local py = (ny - (wheel.anchorNY or ny)) / deady
    local id = Pick(px, py)
    for i = 1, #SLICES do
        local slice = SLICES[i]
        local visual = wheel.nodes[slice.id]
        local on = id == slice.id
        visual:SetScale(on and 1.12 or 1)
        if visual.jhakEdge then
            visual.jhakEdge:SetAlpha(on and 1 or 0.45)
        end
    end
    local hubOn = id == "ping"
    wheel.hub:SetScale(hubOn and 1.08 or 1)
    local slice = SliceById(id)
    if slice then
        wheel.hubText:SetText(slice.label)
        wheel.hubText:SetTextColor(slice.r, slice.g, slice.b)
    else
        wheel.hubText:SetText("Release")
        wheel.hubText:SetTextColor(0.75, 0.70, 0.60)
    end
end

function JP:ParkButtons()
    if InCombatLockdown() then
        self.pendingDisarm = true
        return
    end
    for _, btn in pairs(buttons) do
        btn:EnableMouse(false)
        btn:SetAlpha(0)
        btn:SetSize(1, 1)
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", UIParent, "CENTER", 0, -400)
    end
    self.fallbackArmed = nil
    self.pendingDisarm = nil
end

function JP:ArmFallback()
    if self.secure then
        return
    end
    if InCombatLockdown() then
        Print("Click-to-ping can't move its buttons during combat. Leave combat and press the key again.")
        self:CloseVisual()
        return
    end
    local function parkOn(id, visual, size)
        local btn = buttons[id]
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", visual, "CENTER")
        btn:SetSize(size, size)
        btn:SetAlpha(0)
        btn:SetFrameStrata("TOOLTIP")
        btn:SetFrameLevel(400)
        btn:EnableMouse(true)
        btn:Show()
    end
    for i = 1, #SLICES do
        local slice = SLICES[i]
        parkOn(slice.id, wheel.nodes[slice.id], 72)
    end
    parkOn("ping", wheel.hub, 64)
    self.fallbackArmed = true
end

function JP:ShutdownFallback()
    self:CloseVisual()
    self:ParkButtons()
end

function JP:ToggleFallback()
    if wheel:IsShown() and not wheel.preview then
        self:ShutdownFallback()
        return
    end
    self:OpenAtCursor()
    self:ArmFallback()
end

function JP:Preview()
    if ST.frame then
        ST.frame:Hide()
    end
    wheel.preview = true
    self:PlaceWheel(0.5, 0.5)
    wheel:EnableKeyboard(true)
    wheel:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            JP:CloseVisual()
        end
        self:SetPropagateKeyboardInput(key ~= "ESCAPE")
    end)
end

local function ApplyBinding(key)
    if InCombatLockdown() then
        JP.pendingKey = key
        Print("In combat. The bind will apply when combat ends.")
        return false
    end
    local old1, old2 = nil, nil
    if GetBindingKey then
        old1, old2 = GetBindingKey(CMD)
    end
    if old1 then
        SetBinding(old1)
    end
    if old2 then
        SetBinding(old2)
    end
    local replaced = key and GetBindingAction and GetBindingAction(key) or nil
    if key then
        local ok = SetBinding(key, CMD)
        if not ok then
            Print("Couldn't bind " .. PrettyKey(key) .. ".")
            return false
        end
    end
    local set = 1
    if GetCurrentBindingSet then
        set = GetCurrentBindingSet() or 1
    end
    if SaveBindings then
        SaveBindings(set)
    end
    DB().key = key
    if ST.SaveDB then
        ST:SaveDB()
    end
    if key and replaced and replaced ~= "" and replaced ~= CMD then
        Print("Bound " .. PrettyKey(key) .. ". Replaced " .. replaced .. ".")
    elseif key then
        Print("Bound " .. PrettyKey(key) .. ".")
    else
        Print("Ping wheel unbound.")
    end
    return true
end

local function RefreshBindLabel()
    if panel and panel.bindText then
        if captureArmed then
            panel.bindText:SetText("Press a key")
        else
            panel.bindText:SetText(PrettyKey(CurrentKey()))
        end
    end
end

local function StopCapture()
    captureArmed = false
    if panel then
        panel:EnableKeyboard(false)
        panel:SetPropagateKeyboardInput(true)
    end
    RefreshBindLabel()
end

local function StartCapture()
    captureArmed = true
    if panel then
        panel:EnableKeyboard(true)
    end
    RefreshBindLabel()
end

function ST:CreateSimplePingUI(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:EnableMouse(true)
    f:Hide()

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOP", 0, -4)
    sub:SetText("Hold the key, aim, release.")
    sub:SetTextColor(0.75, 0.70, 0.60)

    local bind = CreateFrame("Button", nil, f, "BackdropTemplate")
    bind:SetSize(220, 28)
    bind:SetPoint("TOP", 0, -36)
    bind:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bind:SetBackdropColor(0.16, 0.14, 0.11, 1)
    bind:SetBackdropBorderColor(0.55, 0.42, 0.22, 1)
    local bindLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bindLabel:SetPoint("BOTTOM", bind, "TOP", 0, 2)
    bindLabel:SetText("Ping wheel")
    bindLabel:SetTextColor(0.93, 0.90, 0.82)
    local bindText = bind:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bindText:SetPoint("CENTER")
    bindText:SetTextColor(0.96, 0.93, 0.84)
    f.bindText = bindText

    bind:RegisterForClicks("AnyUp")
    bind:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            StopCapture()
            ApplyBinding(nil)
            RefreshBindLabel()
            return
        end
        if captureArmed then
            StopCapture()
        else
            StartCapture()
        end
    end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", bind, "BOTTOM", 0, -4)
    hint:SetText("Click, press a key. Right-click clears. Esc cancels.")

    local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    check:SetPoint("TOP", hint, "BOTTOM", -110, -6)
    check:SetChecked(DB().quickTap)
    local checkText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    checkText:SetPoint("LEFT", check, "RIGHT", 2, 0)
    checkText:SetText("Quick tap sends a contextual ping")
    checkText:SetTextColor(0.93, 0.90, 0.82)
    check:SetScript("OnClick", function(self)
        DB().quickTap = self:GetChecked() and true or false
        JP:UpdateDeadzone()
        if ST.SaveDB then
            ST:SaveDB()
        end
    end)
    f.check = check

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    status:SetPoint("BOTTOM", 0, 36)
    status:SetWidth(460)
    status:SetJustifyH("CENTER")
    f.status = status

    local preview = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    preview:SetSize(120, 22)
    preview:SetPoint("BOTTOM", 0, 8)
    preview:SetText("Preview")
    preview:SetScript("OnClick", function()
        if wheel then
            JP:Preview()
        end
    end)

    f:SetScript("OnKeyDown", function(self, key)
        if not captureArmed then
            self:SetPropagateKeyboardInput(true)
            return
        end
        self:SetPropagateKeyboardInput(false)
        if key == "ESCAPE" then
            StopCapture()
            return
        end
        if key == "BUTTON1" or key == "LeftButton" then
            return
        end
        local bindKey = BindingFromKey(key)
        if not bindKey then
            return
        end
        StopCapture()
        ApplyBinding(bindKey)
        RefreshBindLabel()
    end)

    f:SetScript("OnMouseDown", function(_, button)
        if not captureArmed then
            return
        end
        local map = {
            MiddleButton = "BUTTON3",
            Button4 = "BUTTON4",
            Button5 = "BUTTON5",
        }
        local key = map[button]
        if not key then
            return
        end
        local bindKey = BindingFromKey(key)
        if not bindKey then
            return
        end
        StopCapture()
        ApplyBinding(bindKey)
        RefreshBindLabel()
    end)

    f:SetScript("OnHide", function()
        StopCapture()
    end)

    f:SetScript("OnShow", function(self)
        if self.check then
            self.check:SetChecked(DB().quickTap)
        end
        if self.secureNote and self.status then
            self.status:SetText(self.secureNote)
        end
        RefreshBindLabel()
    end)

    panel = f
    return f
end

function JP:SetModeText()
    local note
    if self.secure then
        note = "Release on a ping to send it. Works in combat."
    else
        note = "Secure menus are off on this client. Press the key, then click a ping. Not during combat."
    end
    if panel then
        panel.secureNote = note
        if panel.status then
            panel.status:SetText(note)
        end
    end
end

function JP:OpenTab()
    if not ST.frame then
        return
    end
    ST.frame:Show()
    if ST.SelectTab then
        ST:SelectTab(6)
    end
end

function JP:RestoreBinding()
    if InCombatLockdown() then
        return
    end
    local saved = DB().key
    if not saved or saved == "" then
        return
    end
    if not GetBindingKey then
        return
    end
    local a, b = GetBindingKey(CMD)
    if a or b then
        return
    end
    SetBinding(saved, CMD)
    if SaveBindings and GetCurrentBindingSet then
        SaveBindings(GetCurrentBindingSet() or 1)
    end
end

function JP:ApplyPending()
    if InCombatLockdown() then
        return
    end
    if self.deadDirty then
        self:UpdateDeadzone()
    end
    if self.pendingDisarm then
        self:ParkButtons()
    end
    if self.pendingKey ~= nil then
        local key = self.pendingKey
        self.pendingKey = nil
        ApplyBinding(key)
        RefreshBindLabel()
    end
end

local function BuildWheel()
    local f = CreateFrame("Frame", "JhakPingWheel", UIParent)
    f:SetSize(320, 320)
    f:SetFrameStrata("TOOLTIP")
    f:EnableMouse(false)
    f:Hide()

    local disc = f:CreateTexture(nil, "BACKGROUND")
    disc:SetSize(250, 250)
    disc:SetPoint("CENTER")
    disc:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    disc:SetVertexColor(0.05, 0.04, 0.03, 0.88)

    f.nodes = {}
    for i = 1, #SLICES do
        local slice = SLICES[i]
        local node = CreateFrame("Frame", nil, f)
        node:SetSize(64, 64)
        local ox = math.cos(slice.angle) * RADIUS
        local oy = math.sin(slice.angle) * RADIUS
        node:SetPoint("CENTER", f, "CENTER", ox, oy)
        Decorate(node, slice, 64)
        f.nodes[slice.id] = node
    end

    local hub = CreateFrame("Frame", nil, f)
    hub:SetSize(54, 54)
    hub:SetPoint("CENTER")
    Decorate(hub, CONTEXT, 54)
    hub.jhakName:SetText("")
    f.hub = hub

    local hubText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hubText:SetPoint("CENTER", hub, "CENTER", 0, -36)
    hubText:SetText("")
    f.hubText = hubText

    f:SetScript("OnUpdate", function()
        JP:Highlight()
    end)

    wheel = f
end

local function BuildCatcher()
    catcher = CreateFrame("Button", "JhakPingCatcher", UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("BACKGROUND")
    catcher:SetAlpha(0)
    catcher:EnableMouse(false)
    if catcher.SetMouseClickEnabled then
        catcher:SetMouseClickEnabled(false)
    end
    if catcher.SetMouseMotionEnabled then
        catcher:SetMouseMotionEnabled(false)
    end
    catcher:RegisterForClicks("AnyDown", "AnyUp")
    catcher:SetAttribute("useOnKeyDown", false)
    catcher:Show()

    for i = 1, #SLICES do
        local slice = SLICES[i]
        MakeSecureButton("JhakPing" .. slice.id, slice)
        catcher:SetAttribute("m-" .. slice.id, slice.macro)
    end
    MakeSecureButton("JhakPingping", CONTEXT)
    catcher:SetAttribute("m-ping", CONTEXT.macro)

    JP.secure = false
    if SnippetsWork(catcher) then
        local wrapped = pcall(catcher.WrapScript, catcher, catcher, "OnClick", SNIPPET)
        JP.secure = wrapped and true or false
    end

    catcher:SetScript("PreClick", function(_, button, down)
        if button ~= "LeftButton" then
            return
        end
        if JP.secure then
            local pressed = down
            if pressed == nil then
                pressed = catcher:GetAttribute("open") ~= "1"
            end
            if pressed then
                if not InCombatLockdown() then
                    JP:UpdateDeadzone()
                end
                if wheel.preview then
                    JP:CloseVisual()
                end
                JP:OpenAtCursor()
            else
                JP:CloseVisual()
            end
            return
        end
        if not down then
            return
        end
        if not InCombatLockdown() then
            JP:UpdateDeadzone()
        end
        if wheel.preview then
            JP:CloseVisual()
        end
        JP:ToggleFallback()
    end)

    local watch = CreateFrame("Frame")
    watch:SetScript("OnUpdate", function()
        if not JP.secure or not catcher then
            return
        end
        if wheel.preview then
            return
        end
        local open = catcher:GetAttribute("open") == "1"
        if open and not wheel:IsShown() then
            JP:PlaceWheel(catcher:GetAttribute("ax"), catcher:GetAttribute("ay"))
        elseif not open and wheel:IsShown() then
            JP:CloseVisual()
        end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        BuildWheel()
        BuildCatcher()
        JP:UpdateDeadzone()
        JP:SetModeText()
        JP:RestoreBinding()
        RefreshBindLabel()
        if not CurrentKey() then
            Print("Ping wheel is unbound. Open the Ping tab, or type /jp.")
        end
        if not JP.secure then
            Print("Secure menus did not start. The wheel will wait for a click.")
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        JP:ApplyPending()
    elseif event == "UI_SCALE_CHANGED" then
        JP:UpdateDeadzone()
    end
end)

SLASH_SIMPLETOOLSPING1 = "/jhakping"
SLASH_SIMPLETOOLSPING2 = "/jp"
SlashCmdList.SIMPLETOOLSPING = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "test" or msg == "preview" then
        if wheel then
            JP:Preview()
        end
        return
    end
    if msg == "status" then
        local mode = JP.secure and "release to ping" or "click a ping"
        Print(mode .. ". Key: " .. PrettyKey(CurrentKey()) .. ".")
        return
    end
    JP:OpenTab()
end
