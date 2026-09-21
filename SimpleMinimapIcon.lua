local addonName, ST = ...

-- Addon compartment (minimap cluster dropdown in Midnight / Forever).
function SimpleTools_OnAddonCompartmentClick()
    ST:ToggleWindow()
end

local function PositionMinimapButton(button, angle)
    local radius = 80
    local rad = math.rad(angle or 200)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
end

function ST:CreateMinimapButton()
    if self.minimapButton then
        self:UpdateMinimapButton()
        return
    end
    if not Minimap then
        return
    end

    local button = CreateFrame("Button", "SimpleToolsMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AddOns\\SimpleTools\\Media\\2-icon")
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ST:OpenSettings()
        else
            ST:ToggleWindow()
        end
    end)
    button:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("SimpleTools")
        GameTooltip:AddLine("Left-click: toggle window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: move button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnDragStart", function()
        button:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if ST.db and ST.db.options then
                ST.db.options.minimapAngle = angle
            end
            PositionMinimapButton(button, angle)
        end)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
        ST:SaveDB()
    end)

    self.minimapButton = button
    local angle = self.db and self.db.options and self.db.options.minimapAngle or 200
    PositionMinimapButton(button, angle)
    self:UpdateMinimapButton()
end

function ST:UpdateMinimapButton()
    if not self.minimapButton then
        return
    end
    local show = not self.db or not self.db.options or self.db.options.minimap ~= false
    self.minimapButton:SetShown(show)
end
