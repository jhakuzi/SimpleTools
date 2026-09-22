local addonName, ST = ...

local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown
local GetItemInfo = GetItemInfo

local ROW_HEIGHT = 18
local MAX_ROWS = 40
local PROF_BTN_W = 128
local PROF_BTN_H = 22
local PROF_GAP = 4
local MENU_ROW = 16

ST.SHOP_PROFESSION_ORDER = {
    "alchemy",
    "blacksmithing",
    "enchanting",
    "engineering",
    "leatherworking",
    "tailoring",
    "cooking",
    "firstaid",
}

ST.SHOP_PROFESSIONS = {
    ["alchemy"] = {
        label = "Alchemy",
        groups = {
            {
                label = "Herbs",
                mats = {
                    { id = 2447, name = "Peacebloom" },
                    { id = 765, name = "Silverleaf" },
                    { id = 2449, name = "Earthroot" },
                    { id = 785, name = "Mageroyal" },
                    { id = 2450, name = "Briarthorn" },
                    { id = 2452, name = "Swiftthistle" },
                    { id = 2453, name = "Bruiseweed" },
                    { id = 3820, name = "Stranglekelp" },
                    { id = 3355, name = "Wild Steelbloom" },
                    { id = 3369, name = "Grave Moss" },
                    { id = 3356, name = "Kingsblood" },
                    { id = 3357, name = "Liferoot" },
                    { id = 3818, name = "Fadeleaf" },
                    { id = 3821, name = "Goldthorn" },
                    { id = 3358, name = "Khadgar's Whisker" },
                    { id = 3819, name = "Wintersbite" },
                    { id = 4625, name = "Firebloom" },
                    { id = 8831, name = "Purple Lotus" },
                    { id = 8836, name = "Arthas' Tears" },
                    { id = 8838, name = "Sungrass" },
                    { id = 8839, name = "Blindweed" },
                    { id = 8845, name = "Ghost Mushroom" },
                    { id = 8846, name = "Gromsblood" },
                    { id = 13464, name = "Golden Sansam" },
                    { id = 13463, name = "Dreamfoil" },
                    { id = 13465, name = "Mountain Silversage" },
                    { id = 13466, name = "Plaguebloom" },
                    { id = 13467, name = "Icecap" },
                    { id = 13468, name = "Black Lotus" },
                },
            },
            {
                label = "Vials & Oils",
                mats = {
                    { id = 3371, name = "Empty Vial" },
                    { id = 3372, name = "Leaded Vial" },
                    { id = 8925, name = "Crystal Vial" },
                    { id = 6358, name = "Oily Blackmouth" },
                    { id = 6359, name = "Firefin Snapper" },
                    { id = 13422, name = "Stonescale Eel" },
                    { id = 6370, name = "Blackmouth Oil" },
                    { id = 6371, name = "Fire Oil" },
                    { id = 13423, name = "Stonescale Oil" },
                },
            },
            {
                label = "Flask extras",
                mats = {
                    { id = 7078, name = "Essence of Fire" },
                    { id = 7076, name = "Essence of Earth" },
                    { id = 7082, name = "Essence of Air" },
                    { id = 7080, name = "Essence of Water" },
                    { id = 12808, name = "Essence of Undeath" },
                    { id = 12803, name = "Living Essence" },
                    { id = 9262, name = "Black Vitriol" },
                    { id = 12359, name = "Thorium Bar" },
                    { id = 11754, name = "Black Diamond" },
                },
            },
        },
    },
    ["blacksmithing"] = {
        label = "Smithing",
        groups = {
            {
                label = "Bars",
                mats = {
                    { id = 2840, name = "Copper Bar" },
                    { id = 3576, name = "Tin Bar" },
                    { id = 2841, name = "Bronze Bar" },
                    { id = 2842, name = "Silver Bar" },
                    { id = 3575, name = "Iron Bar" },
                    { id = 3577, name = "Gold Bar" },
                    { id = 3859, name = "Steel Bar" },
                    { id = 3860, name = "Mithril Bar" },
                    { id = 6037, name = "Truesilver Bar" },
                    { id = 12359, name = "Thorium Bar" },
                    { id = 12360, name = "Arcanite Bar" },
                    { id = 11371, name = "Dark Iron Bar" },
                    { id = 12655, name = "Enchanted Thorium Bar" },
                },
            },
            {
                label = "Stones",
                mats = {
                    { id = 2835, name = "Rough Stone" },
                    { id = 2836, name = "Coarse Stone" },
                    { id = 2838, name = "Heavy Stone" },
                    { id = 7912, name = "Solid Stone" },
                    { id = 12365, name = "Dense Stone" },
                    { id = 3470, name = "Rough Grinding Stone" },
                    { id = 3478, name = "Coarse Grinding Stone" },
                    { id = 3486, name = "Heavy Grinding Stone" },
                    { id = 7966, name = "Solid Grinding Stone" },
                    { id = 12644, name = "Dense Grinding Stone" },
                },
            },
            {
                label = "Flux & fuel",
                mats = {
                    { id = 2880, name = "Weak Flux" },
                    { id = 3466, name = "Strong Flux" },
                    { id = 18567, name = "Elemental Flux" },
                    { id = 3857, name = "Coal" },
                    { id = 7067, name = "Elemental Earth" },
                    { id = 7068, name = "Elemental Fire" },
                    { id = 7075, name = "Core of Earth" },
                    { id = 7077, name = "Heart of Fire" },
                    { id = 12809, name = "Guardian Stone" },
                    { id = 22202, name = "Small Obsidian Shard" },
                    { id = 22203, name = "Large Obsidian Shard" },
                },
            },
        },
    },
    ["enchanting"] = {
        label = "Enchant",
        groups = {
            {
                label = "Dusts",
                mats = {
                    { id = 247786, name = "Mote of Magic" },
                    { id = 10940, name = "Strange Dust" },
                    { id = 11083, name = "Soul Dust" },
                    { id = 11137, name = "Vision Dust" },
                    { id = 11176, name = "Dream Dust" },
                    { id = 16204, name = "Illusion Dust" },
                },
            },
            {
                label = "Essences",
                mats = {
                    { id = 10938, name = "Lesser Magic Essence" },
                    { id = 10939, name = "Greater Magic Essence" },
                    { id = 10998, name = "Lesser Astral Essence" },
                    { id = 11082, name = "Greater Astral Essence" },
                    { id = 11134, name = "Lesser Mystic Essence" },
                    { id = 11135, name = "Greater Mystic Essence" },
                    { id = 11174, name = "Lesser Nether Essence" },
                    { id = 11175, name = "Greater Nether Essence" },
                    { id = 16202, name = "Lesser Eternal Essence" },
                    { id = 16203, name = "Greater Eternal Essence" },
                },
            },
            {
                label = "Shards & rods",
                mats = {
                    { id = 10978, name = "Small Glimmering Shard" },
                    { id = 11084, name = "Large Glimmering Shard" },
                    { id = 11138, name = "Small Glowing Shard" },
                    { id = 11139, name = "Large Glowing Shard" },
                    { id = 11177, name = "Small Radiant Shard" },
                    { id = 11178, name = "Large Radiant Shard" },
                    { id = 14343, name = "Small Brilliant Shard" },
                    { id = 14344, name = "Large Brilliant Shard" },
                    { id = 20725, name = "Nexus Crystal" },
                    { id = 6217, name = "Copper Rod" },
                    { id = 6338, name = "Silver Rod" },
                    { id = 11128, name = "Golden Rod" },
                    { id = 11144, name = "Truesilver Rod" },
                    { id = 16206, name = "Arcanite Rod" },
                    { id = 4470, name = "Simple Wood" },
                    { id = 11291, name = "Star Wood" },
                },
            },
        },
    },
    ["engineering"] = {
        label = "Engineer",
        groups = {
            {
                label = "Bars & powder",
                mats = {
                    { id = 2840, name = "Copper Bar" },
                    { id = 2841, name = "Bronze Bar" },
                    { id = 3575, name = "Iron Bar" },
                    { id = 3859, name = "Steel Bar" },
                    { id = 3860, name = "Mithril Bar" },
                    { id = 12359, name = "Thorium Bar" },
                    { id = 12360, name = "Arcanite Bar" },
                    { id = 4357, name = "Rough Blasting Powder" },
                    { id = 4364, name = "Coarse Blasting Powder" },
                    { id = 4377, name = "Heavy Blasting Powder" },
                    { id = 10505, name = "Solid Blasting Powder" },
                    { id = 15992, name = "Dense Blasting Powder" },
                },
            },
            {
                label = "Parts",
                mats = {
                    { id = 4359, name = "Handful of Copper Bolts" },
                    { id = 4361, name = "Copper Tube" },
                    { id = 4371, name = "Bronze Tube" },
                    { id = 4375, name = "Whirring Bronze Gizmo" },
                    { id = 4382, name = "Bronze Framework" },
                    { id = 4387, name = "Iron Strut" },
                    { id = 4389, name = "Gyrochronatom" },
                    { id = 10558, name = "Gold Power Core" },
                    { id = 10559, name = "Mithril Tube" },
                    { id = 10560, name = "Unstable Trigger" },
                    { id = 10561, name = "Mithril Casing" },
                    { id = 15994, name = "Thorium Widget" },
                    { id = 16000, name = "Thorium Tube" },
                    { id = 16006, name = "Delicate Arcanite Converter" },
                    { id = 7191, name = "Fused Wiring" },
                },
            },
            {
                label = "Gems & extra",
                mats = {
                    { id = 774, name = "Malachite" },
                    { id = 818, name = "Tigerseye" },
                    { id = 1206, name = "Moss Agate" },
                    { id = 1529, name = "Jade" },
                    { id = 3864, name = "Citrine" },
                    { id = 7909, name = "Aquamarine" },
                    { id = 7910, name = "Star Ruby" },
                    { id = 12361, name = "Blue Sapphire" },
                    { id = 12800, name = "Azerothian Diamond" },
                    { id = 7067, name = "Elemental Earth" },
                    { id = 7068, name = "Elemental Fire" },
                    { id = 7069, name = "Elemental Air" },
                    { id = 7070, name = "Elemental Water" },
                    { id = 4402, name = "Small Flame Sac" },
                    { id = 4611, name = "Blue Pearl" },
                },
            },
        },
    },
    ["leatherworking"] = {
        label = "Leather",
        groups = {
            {
                label = "Leather & hides",
                mats = {
                    { id = 2318, name = "Light Leather" },
                    { id = 2319, name = "Medium Leather" },
                    { id = 4234, name = "Heavy Leather" },
                    { id = 4304, name = "Thick Leather" },
                    { id = 8170, name = "Rugged Leather" },
                    { id = 783, name = "Light Hide" },
                    { id = 4232, name = "Medium Hide" },
                    { id = 4235, name = "Heavy Hide" },
                    { id = 8169, name = "Thick Hide" },
                    { id = 8171, name = "Rugged Hide" },
                    { id = 15407, name = "Cured Rugged Hide" },
                    { id = 2934, name = "Ruined Leather Scraps" },
                    { id = 12810, name = "Enchanted Leather" },
                },
            },
            {
                label = "Thread, dye & salt",
                mats = {
                    { id = 2320, name = "Coarse Thread" },
                    { id = 2321, name = "Fine Thread" },
                    { id = 4291, name = "Silken Thread" },
                    { id = 8343, name = "Heavy Silken Thread" },
                    { id = 14341, name = "Rune Thread" },
                    { id = 4289, name = "Salt" },
                    { id = 8150, name = "Deeprock Salt" },
                    { id = 2325, name = "Black Dye" },
                    { id = 2604, name = "Red Dye" },
                    { id = 2605, name = "Green Dye" },
                    { id = 6260, name = "Blue Dye" },
                    { id = 4340, name = "Gray Dye" },
                },
            },
            {
                label = "Scales & special",
                mats = {
                    { id = 6470, name = "Deviate Scale" },
                    { id = 6471, name = "Perfect Deviate Scale" },
                    { id = 5784, name = "Slimy Murloc Scale" },
                    { id = 5785, name = "Thick Murloc Scale" },
                    { id = 7286, name = "Black Whelp Scale" },
                    { id = 7287, name = "Red Whelp Scale" },
                    { id = 8154, name = "Scorpid Scale" },
                    { id = 8165, name = "Turtle Scale" },
                    { id = 15408, name = "Heavy Scorpid Scale" },
                    { id = 15412, name = "Green Dragonscale" },
                    { id = 15414, name = "Red Dragonscale" },
                    { id = 15415, name = "Blue Dragonscale" },
                    { id = 15416, name = "Black Dragonscale" },
                    { id = 15417, name = "Devilsaur Leather" },
                    { id = 17012, name = "Core Leather" },
                },
            },
        },
    },
    ["tailoring"] = {
        label = "Tailor",
        groups = {
            {
                label = "Cloth",
                mats = {
                    { id = 2589, name = "Linen Cloth" },
                    { id = 2592, name = "Wool Cloth" },
                    { id = 4306, name = "Silk Cloth" },
                    { id = 4338, name = "Mageweave Cloth" },
                    { id = 14047, name = "Runecloth" },
                    { id = 14256, name = "Felcloth" },
                    { id = 14342, name = "Mooncloth" },
                    { id = 2996, name = "Bolt of Linen Cloth" },
                    { id = 2997, name = "Bolt of Woolen Cloth" },
                    { id = 4305, name = "Bolt of Silk Cloth" },
                    { id = 4339, name = "Bolt of Mageweave" },
                    { id = 14048, name = "Bolt of Runecloth" },
                },
            },
            {
                label = "Thread, dye & silk",
                mats = {
                    { id = 2320, name = "Coarse Thread" },
                    { id = 2321, name = "Fine Thread" },
                    { id = 4291, name = "Silken Thread" },
                    { id = 8343, name = "Heavy Silken Thread" },
                    { id = 14341, name = "Rune Thread" },
                    { id = 3182, name = "Spider's Silk" },
                    { id = 4337, name = "Thick Spider's Silk" },
                    { id = 10285, name = "Shadow Silk" },
                    { id = 14227, name = "Ironweb Spider Silk" },
                    { id = 2604, name = "Red Dye" },
                    { id = 6260, name = "Blue Dye" },
                    { id = 2325, name = "Black Dye" },
                    { id = 2324, name = "Bleach" },
                    { id = 6261, name = "Orange Dye" },
                    { id = 4342, name = "Purple Dye" },
                },
            },
            {
                label = "Special",
                mats = {
                    { id = 17056, name = "Light Feather" },
                    { id = 7071, name = "Iron Buckle" },
                    { id = 10286, name = "Heart of the Wild" },
                    { id = 7079, name = "Globe of Water" },
                    { id = 7080, name = "Essence of Water" },
                    { id = 7078, name = "Essence of Fire" },
                    { id = 7076, name = "Essence of Earth" },
                    { id = 7082, name = "Essence of Air" },
                    { id = 12810, name = "Enchanted Leather" },
                    { id = 13926, name = "Golden Pearl" },
                },
            },
        },
    },
    ["cooking"] = {
        label = "Cooking",
        groups = {
            {
                label = "Vendor spices",
                mats = {
                    { id = 2678, name = "Mild Spices" },
                    { id = 2692, name = "Hot Spices" },
                    { id = 3713, name = "Soothing Spices" },
                    { id = 159, name = "Refreshing Spring Water" },
                    { id = 1179, name = "Ice Cold Milk" },
                },
            },
            {
                label = "Meat & fish",
                mats = {
                    { id = 769, name = "Chunk of Boar Meat" },
                    { id = 2672, name = "Stringy Wolf Meat" },
                    { id = 6889, name = "Small Egg" },
                    { id = 5503, name = "Clam Meat" },
                    { id = 6522, name = "Deviate Fish" },
                    { id = 3730, name = "Big Bear Meat" },
                    { id = 12184, name = "Raptor Flesh" },
                    { id = 12037, name = "Mystery Meat" },
                    { id = 12205, name = "White Spider Meat" },
                    { id = 12202, name = "Tiger Meat" },
                    { id = 12208, name = "Tender Wolf Meat" },
                    { id = 12207, name = "Giant Egg" },
                    { id = 21071, name = "Raw Sagefish" },
                    { id = 21153, name = "Raw Greater Sagefish" },
                    { id = 4603, name = "Raw Spotted Yellowtail" },
                    { id = 7974, name = "Zesty Clam Meat" },
                    { id = 20424, name = "Sandworm Meat" },
                },
            },
        },
    },
    ["firstaid"] = {
        label = "First Aid",
        groups = {
            {
                label = "Cloth",
                mats = {
                    { id = 2589, name = "Linen Cloth" },
                    { id = 2592, name = "Wool Cloth" },
                    { id = 4306, name = "Silk Cloth" },
                    { id = 4338, name = "Mageweave Cloth" },
                    { id = 14047, name = "Runecloth" },
                },
            },
            {
                label = "Venom",
                mats = {
                    { id = 1475, name = "Small Venom Sac" },
                    { id = 1288, name = "Large Venom Sac" },
                    { id = 19441, name = "Huge Venom Sac" },
                },
            },
        },
    },
}


function ST:ParseItemLink(link)
    if type(link) ~= "string" or link == "" then
        return nil
    end
    local id = tonumber(link:match("item:(%d+)"))
    local name = link:match("%[([^%]]+)%]")
    if not id and not name then
        return nil
    end
    if not name or name == "" then
        name = "Item " .. tostring(id or "?")
    end
    return {
        id = id or 0,
        name = name,
        link = link,
    }
end

function ST:MakeShopCatalogLink(mat)
    if not mat then
        return nil
    end
    if type(mat.link) == "string" and mat.link ~= "" then
        return mat.link
    end
    local id = mat.id or 0
    local name = mat.name or "Item"
    if id > 0 and GetItemInfo then
        local ok, itemName, itemLink = pcall(GetItemInfo, id)
        if ok and type(itemLink) == "string" and itemLink ~= "" then
            return itemLink
        end
        if ok and type(itemName) == "string" and itemName ~= "" then
            -- GetItemInfo returns name as first value; some clients put link second only
        end
    end
    return "|Hitem:" .. id .. "::::::::|h[" .. name .. "]|h"
end

function ST:IsShopListening()
    return self.frame and self.frame:IsShown() and self.shopFrame and self.shopFrame:IsShown()
end

function ST:TryCaptureShopLink(link)
    if not self:IsShopListening() then
        return false
    end
    if self.shopQtyFrame and self.shopQtyFrame:IsShown() then
        return true
    end
    local item = self:ParseItemLink(link)
    if not item then
        return false
    end
    self:PromptShopQuantity(item)
    return true
end

function ST:PromptShopFromCatalog(mat)
    if not mat then
        return
    end
    self:HideShopProfMenu()
    self:PromptShopQuantity({
        id = mat.id or 0,
        name = mat.name,
        link = self:MakeShopCatalogLink(mat),
    })
end

function ST:PromptShopQuantity(item)
    self.pendingShopItem = item
    if not self.shopQtyFrame then
        self:CreateShopQtyFrame()
    end
    local frame = self.shopQtyFrame
    frame.label:SetText("How many  " .. (item.link or item.name) .. "?")
    frame.edit:SetText("1")
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

function ST:CreateShopQtyFrame()
    local frame = CreateFrame("Frame", "SimpleToolsShopQty", UIParent, "BackdropTemplate")
    frame:SetSize(300, 108)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    self:ApplyOverlayBackdrop(frame)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOP", 0, -14)
    label:SetWidth(270)
    label:SetWordWrap(true)
    frame.label = label

    local edit = CreateFrame("EditBox", "SimpleToolsShopQtyEdit", frame, "InputBoxTemplate")
    edit:SetSize(80, 20)
    edit:SetPoint("TOP", 0, -42)
    edit:SetAutoFocus(false)
    edit:SetNumeric(true)
    edit:SetMaxLetters(5)
    edit:SetText("1")
    edit:SetScript("OnEnterPressed", function()
        ST:ConfirmShopQuantity()
    end)
    edit:SetScript("OnEscapePressed", function()
        ST:CancelShopQuantity()
    end)
    frame.edit = edit

    local ok = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    ok:SetSize(80, 22)
    ok:SetPoint("BOTTOM", -48, 12)
    ok:SetText("Add")
    ok:SetScript("OnClick", function()
        ST:ConfirmShopQuantity()
    end)

    local cancel = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    cancel:SetSize(80, 22)
    cancel:SetPoint("BOTTOM", 48, 12)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        ST:CancelShopQuantity()
    end)

    frame:Hide()
    self.shopQtyFrame = frame
end

function ST:ConfirmShopQuantity()
    local item = self.pendingShopItem
    local n = 1
    if self.shopQtyFrame and self.shopQtyFrame.edit then
        n = tonumber(self.shopQtyFrame.edit:GetText()) or 1
    end
    n = math.floor(math.max(1, math.min(9999, n)))
    self:CancelShopQuantity()
    if item then
        self:AddShopItem(item, n)
    end
end

function ST:CancelShopQuantity()
    self.pendingShopItem = nil
    if self.shopQtyFrame then
        self.shopQtyFrame:Hide()
        if self.shopQtyFrame.edit then
            self.shopQtyFrame.edit:ClearFocus()
        end
    end
end

function ST:AddShopItem(item, count)
    if not item then
        return
    end
    count = count or 1
    if not self.shopItems then
        self.shopItems = {}
    end
    local list = self.shopItems
    local found
    for _, row in ipairs(list) do
        if (item.id ~= 0 and row.id == item.id) or (item.id == 0 and row.name == item.name) then
            found = row
            break
        end
    end
    if found then
        found.count = math.min(9999, (found.count or 0) + count)
        if item.link then
            found.link = item.link
        end
    else
        list[#list + 1] = {
            id = item.id,
            name = item.name,
            link = item.link,
            count = count,
        }
    end
    self:RefreshShopList()
    self:SaveDB()
end

function ST:RemoveShopItem(index)
    table.remove(self.shopItems, index)
    self:RefreshShopList()
    self:SaveDB()
end

function ST:ClearShopList()
    wipe(self.shopItems)
    self:CancelShopQuantity()
    self:RefreshShopList()
    self:SaveDB()
end

function ST:ShopSearchAH(entry)
    if not entry then
        return
    end
    local name = entry.name
    if not name or name == "" then
        return
    end

    local searched = false
    local ah = _G.AuctionHouseFrame
    if ah and ah:IsShown() then
        local bar = ah.SearchBar
        if bar then
            if bar.SearchBox then
                bar.SearchBox:SetText(name)
                bar.SearchBox:SetFocus()
            end
            if type(bar.StartSearch) == "function" then
                bar:StartSearch()
                searched = true
            elseif bar.SearchButton then
                bar.SearchButton:Click()
                searched = true
            end
        end
    end

    local classicAH = _G.AuctionFrame
    if not searched and classicAH and classicAH:IsShown() and _G.BrowseName then
        _G.BrowseName:SetText(name)
        if _G.AuctionFrameBrowse_Search then
            _G.AuctionFrameBrowse_Search()
        end
        searched = true
    end

    if searched then
        self:Print("AH search: " .. name)
        return
    end

    if ChatEdit_InsertLink and entry.link then
        ChatEdit_InsertLink(entry.link)
    elseif ChatFrameUtil and ChatFrameUtil.InsertLink and entry.link then
        ChatFrameUtil.InsertLink(entry.link)
    else
        self:Print("Open the auction house, then shift-click a row to search for " .. name .. ".")
    end
end

function ST:HideShopProfMenu()
    if self.shopProfMenu then
        self.shopProfMenu:Hide()
    end
    self.shopProfOpen = nil
end

function ST:CreateShopProfMenu()
    local frame = CreateFrame("Frame", "SimpleToolsShopProfMenu", UIParent, "BackdropTemplate")
    frame:SetSize(220, 240)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(10)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    self:ApplyOverlayBackdrop(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", 0, -8)

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsShopProfScroll", frame)
    scroll:SetPoint("TOPLEFT", 8, -24)
    scroll:SetPoint("BOTTOMRIGHT", -8, 8)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(200, 20)
    scroll:SetScrollChild(child)
    frame.child = child
    frame.scroll = scroll
    frame.rows = {}
    frame:Hide()
    frame:SetScript("OnHide", function()
        ST.shopProfOpen = nil
    end)
    self.shopProfMenu = frame
end

function ST:AcquireShopProfRow(i)
    local row = self.shopProfMenu.rows[i]
    if row then
        return row
    end
    local child = self.shopProfMenu.child
    row = CreateFrame("Button", nil, child)
    row:SetHeight(MENU_ROW)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * MENU_ROW)
    row:SetPoint("TOPRIGHT", 0, -(i - 1) * MENU_ROW)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    if row.text.SetWordWrap then
        row.text:SetWordWrap(false)
    end
    row:SetScript("OnClick", function(selfObj)
        if selfObj.mat then
            ST:PromptShopFromCatalog(selfObj.mat)
        end
    end)
    row:SetScript("OnEnter", function(selfObj)
        if selfObj.mat then
            selfObj.text:SetTextColor(1, 0.82, 0)
            local link = ST:MakeShopCatalogLink(selfObj.mat)
            if link and GameTooltip then
                GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(link)
                GameTooltip:Show()
            end
        end
    end)
    row:SetScript("OnLeave", function(selfObj)
        if selfObj.isHeader then
            selfObj.text:SetTextColor(0.6, 0.6, 0.6)
        else
            selfObj.text:SetTextColor(1, 1, 1)
        end
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    self.shopProfMenu.rows[i] = row
    return row
end

function ST:ToggleShopProfMenu(key, anchor)
    local prof = self.SHOP_PROFESSIONS[key]
    if not prof then
        return
    end
    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        self:HideShopProfMenu()
        MenuUtil.CreateContextMenu(anchor, function(_, root)
            if root.CreateTitle then
                root:CreateTitle(prof.label)
            end
            if root.SetScrollMode then
                root:SetScrollMode(280)
            end
            for gi, group in ipairs(prof.groups or {}) do
                if gi > 1 and root.CreateDivider then
                    root:CreateDivider()
                end
                if root.CreateTitle then
                    root:CreateTitle(group.label)
                end
                for _, mat in ipairs(group.mats or {}) do
                    root:CreateButton(mat.name, function()
                        ST:PromptShopFromCatalog(mat)
                    end)
                end
            end
        end)
        return
    end
    if self.shopProfOpen == key then
        self:HideShopProfMenu()
        return
    end
    self:ShowShopProfMenu(key, anchor)
end

function ST:ShowShopProfMenu(key, anchor)
    local prof = self.SHOP_PROFESSIONS[key]
    if not prof then
        return
    end
    if not self.shopProfMenu then
        self:CreateShopProfMenu()
    end
    local frame = self.shopProfMenu
    frame.title:SetText(prof.label)

    local lines = {}
    for _, group in ipairs(prof.groups or {}) do
        lines[#lines + 1] = { header = group.label }
        for _, mat in ipairs(group.mats or {}) do
            lines[#lines + 1] = { mat = mat }
        end
    end

    for i = 1, math.max(#lines, #frame.rows) do
        local row = frame.rows[i]
        if i <= #lines then
            row = self:AcquireShopProfRow(i)
            local line = lines[i]
            if line.header then
                row.mat = nil
                row.isHeader = true
                row.text:SetText(line.header)
                row.text:SetTextColor(0.6, 0.6, 0.6)
                row:EnableMouse(false)
                row:Show()
            else
                row.mat = line.mat
                row.isHeader = false
                row.text:SetText(line.mat.name)
                row.text:SetTextColor(1, 1, 1)
                row:EnableMouse(true)
                row:Show()
            end
        elseif row then
            row:Hide()
            row.mat = nil
        end
    end

    frame.child:SetHeight(math.max(20, #lines * MENU_ROW + 4))
    frame.scroll:SetVerticalScroll(0)

    frame:ClearAllPoints()
    if anchor then
        frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    else
        frame:SetPoint("CENTER")
    end
    frame:Show()
    self.shopProfOpen = key
end

function ST:CreateSimpleShopUI(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 8, -4)
    hint:SetPoint("TOPRIGHT", -8, -4)
    hint:SetJustifyH("LEFT")
    hint:SetText("Shift-click bags, or pick a profession reagent. Shift-click a row for AH search.")

    self.shopProfButtons = {}
    for i, key in ipairs(self.SHOP_PROFESSION_ORDER) do
        local prof = self.SHOP_PROFESSIONS[key]
        local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        btn:SetSize(PROF_BTN_W, PROF_BTN_H)
        btn:SetText(prof.label)
        btn:SetScript("OnClick", function(selfBtn)
            ST:ToggleShopProfMenu(key, selfBtn)
        end)
        self.shopProfButtons[i] = btn
    end

    local listBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listBox:SetPoint("TOPLEFT", 8, -72)
    listBox:SetPoint("BOTTOMRIGHT", -8, 38)
    self:ApplyOverlayBackdrop(listBox)

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsShopScroll", listBox)
    scroll:SetPoint("TOPLEFT", 6, -4)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(400, 20)
    scroll:SetScrollChild(child)

    self.shopListChild = child
    self.shopListRows = {}
    self.shopEmpty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.shopEmpty:SetPoint("TOPLEFT", 4, -4)
    self.shopEmpty:SetText("List is empty.")

    local clear = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clear:SetText("Clear list")
    clear:SetScript("OnClick", function()
        ST:ClearShopList()
    end)

    self.shopProjectButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    self.shopProjectButton:SetText("Send to screen")
    self.shopProjectButton:SetScript("OnClick", function()
        ST:ToggleShopProjected()
    end)

    self:LayoutBottomPair(frame, clear, self.shopProjectButton)

    frame:SetScript("OnHide", function()
        ST:HideShopProfMenu()
    end)

    self.shopFrame = frame
    self:LayoutShopProfButtons()
    self:HookShopClicks()
    self:RefreshShopList()
    return frame
end

function ST:LayoutShopProfButtons()
    local frame = self.shopFrame
    local buttons = self.shopProfButtons
    if not frame or not buttons then
        return
    end
    local inner = math.max(400, (frame:GetWidth() or 560) - 16)
    local gap = PROF_GAP
    local width = math.floor((inner - 3 * gap) / 4)
    width = math.max(96, math.min(168, width))
    for i, btn in ipairs(buttons) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        btn:SetSize(width, PROF_BTN_H)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 8 + col * (width + gap), -20 - row * (PROF_BTN_H + gap))
    end
end

function ST:BindShopEntryRow(row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", function(selfObj)
        if selfObj.entry then
            GameTooltip:SetOwner(selfObj, "ANCHOR_RIGHT")
            if selfObj.entry.link then
                GameTooltip:SetHyperlink(selfObj.entry.link)
            else
                GameTooltip:SetText(selfObj.entry.name or "Item")
            end
            GameTooltip:AddLine("Shift-click: AH search. Right-click or x: remove.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(selfObj, button)
        if button == "RightButton" then
            ST:RemoveShopItem(selfObj.index)
            return
        end
        if IsShiftKeyDown() then
            ST:ShopSearchAH(selfObj.entry)
        elseif selfObj.entry and selfObj.entry.link and SetItemRef then
            SetItemRef(selfObj.entry.link:match("|H(.-)|h") or selfObj.entry.link, selfObj.entry.link, button)
        else
            ST:ShopSearchAH(selfObj.entry)
        end
    end)
end

function ST:AcquireShopRow(i)
    local row = self.shopListRows[i]
    if row then
        return row
    end
    local child = self.shopListChild
    row = CreateFrame("Button", nil, child)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -16, -(i - 1) * ROW_HEIGHT)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -18, 0)
    row.text:SetJustifyH("LEFT")
    if row.text.SetWordWrap then
        row.text:SetWordWrap(false)
    end

    row.remove = CreateFrame("Button", nil, row)
    row.remove:SetSize(16, 16)
    row.remove:SetPoint("RIGHT", -2, 0)
    row.remove.label = row.remove:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.remove.label:SetPoint("CENTER")
    row.remove.label:SetText("x")
    row.remove:SetScript("OnClick", function()
        ST:RemoveShopItem(row.index)
    end)

    self:BindShopEntryRow(row)
    self.shopListRows[i] = row
    return row
end

function ST:RefreshShopList()
    if not self.shopListChild then
        return
    end
    local list = self.shopItems or {}
    local shown = math.min(#list, MAX_ROWS)
    for i = 1, math.max(shown, #self.shopListRows) do
        local row = self.shopListRows[i]
        if i <= shown then
            row = self:AcquireShopRow(i)
            local entry = list[i]
            row.index = i
            row.entry = entry
            local link = entry.link or entry.name
            row.text:SetText(tostring(entry.count) .. " x " .. link)
            row:SetWidth(self.shopListChild:GetWidth() or 400)
            row:Show()
        elseif row then
            row:Hide()
            row.entry = nil
        end
    end
    if self.shopEmpty then
        self.shopEmpty:SetShown(shown == 0)
    end
    self.shopListChild:SetHeight(math.max(20, shown * ROW_HEIGHT + 4))
    self:RefreshShopProjected()
end

function ST:HookShopClicks()
    if self.shopHooks then
        return
    end
    self.shopHooks = true

    if type(_G.HandleModifiedItemClick) == "function" then
        local orig = _G.HandleModifiedItemClick
        _G.HandleModifiedItemClick = function(link, ...)
            if ST:TryCaptureShopLink(link) then
                return true
            end
            return orig(link, ...)
        end
    end

    if type(_G.ChatEdit_InsertLink) == "function" then
        local orig = _G.ChatEdit_InsertLink
        _G.ChatEdit_InsertLink = function(link, ...)
            if ST:TryCaptureShopLink(link) then
                return true
            end
            return orig(link, ...)
        end
    end

    local util = _G.ChatFrameUtil
    if util and type(util.InsertLink) == "function" then
        local orig = util.InsertLink
        util.InsertLink = function(link, ...)
            if ST:TryCaptureShopLink(link) then
                return true
            end
            return orig(link, ...)
        end
    end
end

function ST:CreateShopProjectedFrame()
    local frame = self:CreateOverlayFrame("SimpleShopProjectedFrame", 220, 140, 180, -80, "Shop", function()
        ST:ShowShopProjected(false)
    end)
    frame.overlayHint = "Shift-click a row to paste into AH search. Drag to move. Hover for × to hide."

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("Shop")

    local scroll = CreateFrame("ScrollFrame", "SimpleToolsShopOverlayScroll", frame)
    scroll:SetPoint("TOPLEFT", 8, -24)
    scroll:SetPoint("BOTTOMRIGHT", -8, 8)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfObj, delta)
        local maxScroll = selfObj:GetVerticalScrollRange() or 0
        local nextScroll = math.min(maxScroll, math.max(0, selfObj:GetVerticalScroll() - delta * 18))
        selfObj:SetVerticalScroll(nextScroll)
    end)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(200, 20)
    scroll:SetScrollChild(child)

    self.shopProjEmpty = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.shopProjEmpty:SetPoint("TOPLEFT", 4, -4)
    self.shopProjEmpty:SetText("List is empty.")

    self.shopProjChild = child
    self.shopProjRows = {}
    self.shopProjectedFrame = frame
end

function ST:AcquireShopProjRow(i)
    local row = self.shopProjRows[i]
    if row then
        return row
    end
    local child = self.shopProjChild
    row = CreateFrame("Button", nil, child)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -16, -(i - 1) * ROW_HEIGHT)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -18, 0)
    row.text:SetJustifyH("LEFT")
    if row.text.SetWordWrap then
        row.text:SetWordWrap(false)
    end

    row.remove = CreateFrame("Button", nil, row)
    row.remove:SetSize(16, 16)
    row.remove:SetPoint("RIGHT", -2, 0)
    row.remove.label = row.remove:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.remove.label:SetPoint("CENTER")
    row.remove.label:SetText("x")
    row.remove:SetScript("OnClick", function()
        ST:RemoveShopItem(row.index)
    end)

    self:BindShopEntryRow(row)
    self.shopProjRows[i] = row
    return row
end

function ST:RefreshShopProjected()
    if not self.shopProjectedFrame then
        return
    end
    local list = self.shopItems or {}
    local shown = math.min(#list, MAX_ROWS)
    for i = 1, math.max(shown, #(self.shopProjRows or {})) do
        local row = self.shopProjRows[i]
        if i <= shown then
            row = self:AcquireShopProjRow(i)
            local entry = list[i]
            row.index = i
            row.entry = entry
            local link = entry.link or entry.name
            row.text:SetText(tostring(entry.count) .. " x " .. link)
            row:SetWidth(self.shopProjChild:GetWidth() or 200)
            row:Show()
        elseif row then
            row:Hide()
            row.entry = nil
        end
    end
    if self.shopProjEmpty then
        self.shopProjEmpty:SetShown(shown == 0)
    end
    self.shopProjChild:SetHeight(math.max(20, shown * ROW_HEIGHT + 4))
    local height = math.min(280, math.max(80, 32 + math.max(1, shown) * ROW_HEIGHT + 10))
    self.shopProjectedFrame:SetHeight(height)
end

function ST:ShowShopProjected(show, pos)
    if not self.shopProjectedFrame then
        self:CreateShopProjectedFrame()
    end
    if show then
        self:PlaceOverlay(self.shopProjectedFrame, pos)
        self.shopProjectedFrame:Show()
        if self.shopProjectButton then
            self.shopProjectButton:SetText("Unproject")
        end
        self.shopProjected = true
        self:RefreshShopProjected()
    else
        self.shopProjectedFrame:Hide()
        if self.shopProjectButton then
            self.shopProjectButton:SetText("Send to screen")
        end
        self.shopProjected = false
    end
end

function ST:ToggleShopProjected()
    self:ShowShopProjected(not (self.shopProjectedFrame and self.shopProjectedFrame:IsShown()))
    self:SaveDB()
end
