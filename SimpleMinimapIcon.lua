local addonName, SimpleTools = ...

-- AddonCompartment handler
-- Called when the user clicks SimpleTools in the top-right addon dropdown menu.
function SimpleTools_OnAddonCompartmentClick(addonName, buttonName)
    SimpleTools:ToggleWindow()
end
