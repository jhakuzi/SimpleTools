local addonName, ST = ...

-- Addon compartment (minimap cluster dropdown). No floating minimap button.
function SimpleTools_OnAddonCompartmentClick()
    ST:ToggleWindow()
end
