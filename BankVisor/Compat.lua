local ADDON, ns = ...

local Compat = {}
ns.Compat = Compat

ns.GUILD_SLOTS = MAX_GUILDBANK_SLOTS_PER_TAB or 98

function Compat.GetNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

function Compat.GetSlot(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.hyperlink, info.stackCount, info.iconFileID end
        return nil
    elseif GetContainerItemInfo then
        local tex, count = GetContainerItemInfo(bag, slot)
        local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
        if link then return link, count, tex end
    end
    return nil
end

function Compat.PlayerBagMax()
    return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
end

function Compat.BankBags()
    local pmax = Compat.PlayerBagMax()
    local excluded = {}
    for id = 0, pmax do excluded[id] = true end
    if Enum and Enum.BagIndex and type(Enum.BagIndex.ReagentBag) == "number" then
        excluded[Enum.BagIndex.ReagentBag] = true
    end
    if REAGENTBAG_CONTAINER then excluded[REAGENTBAG_CONTAINER] = true end
    if KEYRING_CONTAINER then excluded[KEYRING_CONTAINER] = true end

    local seen, list = {}, {}
    local function add(id)
        if type(id) == "number" and not excluded[id] and not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end

    add(BANK_CONTAINER or -1)
    if Enum and type(Enum.BagIndex) == "table" then
        for k, v in pairs(Enum.BagIndex) do
            if type(k) == "string" and (k:find("^BankBag") or k:find("^CharacterBankTab")) then
                add(v)
            end
        end
    end
    local first = pmax + 1
    for id = first, first + (NUM_BANKBAGSLOTS or 7) - 1 do
        add(id)
    end
    table.sort(list)
    return list
end

function Compat.GuildTabCount()
    return GetNumGuildBankTabs and GetNumGuildBankTabs() or 0
end

function Compat.GuildTabInfo(tab)
    if GetGuildBankTabInfo then
        local name, icon, isViewable = GetGuildBankTabInfo(tab)
        return name, icon, isViewable
    end
    return nil, nil, false
end

function Compat.GuildSlot(tab, slot)
    if GetGuildBankItemInfo and GetGuildBankItemLink then
        local tex, count = GetGuildBankItemInfo(tab, slot)
        local link = GetGuildBankItemLink(tab, slot)
        if link then return link, count, tex end
    end
    return nil
end

function Compat.CurrentGuildTab()
    return GetCurrentGuildBankTab and GetCurrentGuildBankTab() or 1
end
