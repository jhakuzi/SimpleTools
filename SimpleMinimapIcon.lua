local addonName, SimpleTimer = ...

-- AddonCompartment handler
-- Called when the user clicks SimpleTimer in the top-right addon dropdown menu.
function SimpleTimer_OnAddonCompartmentClick(addonName, buttonName)
    SimpleTimer:ToggleWindow()
end
