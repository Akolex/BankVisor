local ADDON, ns = ...

local Scan = {}
ns.Scan = Scan

ns.bankOpen = false
ns.guildOpen = false

local function refreshUI()
    if ns.UI and ns.UI.IsShown and ns.UI.Refresh and ns.UI.IsShown() then
        ns.UI.Refresh()
    end
end

local function getChar()
    local db = ns.DB()
    local key = ns.CharKey()
    local c = db.chars[key]
    if not c then
        c = {}
        db.chars[key] = c
    end
    return c
end

function Scan.UpdateChar()
    local c = getChar()
    local _, class = UnitClass("player")
    if class then c.class = class end
    local gk = ns.GuildKey()
    if gk then
        c.guild = gk
    elseif IsInGuild and not IsInGuild() then
        c.guild = nil
    end
    return c
end

function Scan.Bank()
    if not ns.bankOpen then return end
    local c = Scan.UpdateChar()
    local bags = {}
    local ids = ns.Compat.BankBags()
    for i = 1, #ids do
        local id = ids[i]
        local size = ns.Compat.GetNumSlots(id)
        if size and size > 0 then
            local items = {}
            local found = 0
            for slot = 1, size do
                local link, count, icon = ns.Compat.GetSlot(id, slot)
                if link then
                    items[slot] = { link = link, count = count or 1, icon = icon }
                    found = found + 1
                end
            end
            if found > 0 then
                bags[#bags + 1] = { id = id, size = size, items = items }
            end
        end
    end
    c.bank = { time = time(), bags = bags }
    refreshUI()
end

function Scan.GuildTab(tab)
    if not ns.guildOpen then return end
    tab = tab or ns.Compat.CurrentGuildTab()
    local c = Scan.UpdateChar()
    local gk = ns.GuildKey() or c.guild
    if not gk then return end

    local db = ns.DB()
    local g = db.guilds[gk]
    if not g then
        g = { numTabs = 0, tabs = {} }
        db.guilds[gk] = g
    end
    g.tabs = g.tabs or {}

    local numTabs = ns.Compat.GuildTabCount()
    if numTabs and numTabs > 0 then g.numTabs = numTabs end

    local name, icon, isViewable = ns.Compat.GuildTabInfo(tab)
    local t = g.tabs[tab]
    if not t then
        t = { items = {} }
        g.tabs[tab] = t
    end
    t.items = t.items or {}
    t.name = name or t.name
    t.icon = icon or t.icon
    t.viewable = isViewable and true or false

    if t.viewable then
        local items = {}
        local found = 0
        for slot = 1, ns.GUILD_SLOTS do
            local link, count, tex = ns.Compat.GuildSlot(tab, slot)
            if link then
                items[slot] = { link = link, count = count or 1, icon = tex }
                found = found + 1
            end
        end
        if found > 0 or next(t.items) == nil then
            t.items = items
            t.time = time()
        end
    end
    refreshUI()
end

local function bankOpened()
    ns.bankOpen = true
    Scan.Bank()
end

local function bankClosed()
    ns.bankOpen = false
end

local function guildOpened()
    ns.guildOpen = true
    Scan.UpdateChar()
    if QueryGuildBankTab then
        QueryGuildBankTab(ns.Compat.CurrentGuildTab())
    end
end

local function guildClosed()
    ns.guildOpen = false
end

local function bankChanged()
    if not ns.bankOpen then return end
    ns.Debounce("bank", 0.2, Scan.Bank)
end

ns.On("BANKFRAME_OPENED", bankOpened)
ns.On("BANKFRAME_CLOSED", bankClosed)
ns.On("PLAYERBANKSLOTS_CHANGED", bankChanged)
ns.On("BAG_UPDATE", bankChanged)

ns.SafeOn("GUILDBANKFRAME_OPENED", guildOpened)
ns.SafeOn("GUILDBANKFRAME_CLOSED", guildClosed)
ns.SafeOn("GUILDBANKBAGSLOTS_CHANGED", function()
    Scan.GuildTab(ns.Compat.CurrentGuildTab())
end)

if Enum and Enum.PlayerInteractionType then
    local T = Enum.PlayerInteractionType
    ns.SafeOn("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
        if T.Banker and kind == T.Banker then
            bankOpened()
        elseif T.GuildBanker and kind == T.GuildBanker then
            guildOpened()
        end
    end)
    ns.SafeOn("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
        if T.Banker and kind == T.Banker then
            bankClosed()
        elseif T.GuildBanker and kind == T.GuildBanker then
            guildClosed()
        end
    end)
end

ns.On("PLAYER_LOGIN", function() Scan.UpdateChar() end)
ns.SafeOn("PLAYER_GUILD_UPDATE", function() Scan.UpdateChar() end)
