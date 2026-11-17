local ADDON, ns = ...
local handlers = {}
local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        list[i](event, ...)
    end
end)

function ns.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(handlers[event], fn)
end

function ns.SafeOn(event, fn)
    if not handlers[event] then
        local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if not ok then return false end
        handlers[event] = {}
    end
    table.insert(handlers[event], fn)
    return true
end

local pending = {}
function ns.Debounce(key, delay, fn)
    if not (C_Timer and C_Timer.After) then
        fn()
        return
    end
    if pending[key] then return end
    pending[key] = true
    C_Timer.After(delay, function()
        pending[key] = nil
        fn()
    end)
end

function ns.DB()
    if type(BankVisorDB) ~= "table" then BankVisorDB = {} end
    local db = BankVisorDB
    if db.version == nil then db.version = 1 end
    if type(db.chars) ~= "table" then db.chars = {} end
    if type(db.guilds) ~= "table" then db.guilds = {} end
    if type(db.minimap) ~= "table" then db.minimap = {} end
    if db.minimap.angle == nil then db.minimap.angle = 225 end
    if db.minimap.hide == nil then db.minimap.hide = false end
    if db.lang == nil then db.lang = "auto" end
    return db
end

function ns.CharKey()
    local name = UnitName("player") or "?"
    local realm = GetRealmName() or "?"
    return name .. "-" .. realm
end

function ns.GuildKey()
    local guild = GetGuildInfo and GetGuildInfo("player")
    if not guild then return nil end
    return guild .. "-" .. (GetRealmName() or "?")
end

ns.On("ADDON_LOADED", function(_, name)
    if name == ADDON then
        ns.DB()
    end
end)

ns.On("PLAYER_LOGIN", function()
    ns.DB()
    if ns.Minimap and ns.Minimap.Init then
        ns.Minimap.Init()
    end
end)

SLASH_BANKVISOR1 = "/vb"
SLASH_BANKVISOR2 = "/bankvisor"
local function DebugDump()
    local function out(s) print("Bank Visor: " .. s) end
    out("NUM_BAG_SLOTS=" .. tostring(NUM_BAG_SLOTS)
        .. " NUM_TOTAL_EQUIPPED_BAG_SLOTS=" .. tostring(NUM_TOTAL_EQUIPPED_BAG_SLOTS)
        .. " NUM_BANKBAGSLOTS=" .. tostring(NUM_BANKBAGSLOTS)
        .. " BANK_CONTAINER=" .. tostring(BANK_CONTAINER)
        .. " REAGENTBAG_CONTAINER=" .. tostring(REAGENTBAG_CONTAINER))
    if Enum and type(Enum.BagIndex) == "table" then
        local arr = {}
        for k, v in pairs(Enum.BagIndex) do
            arr[#arr + 1] = { k = tostring(k), v = v }
        end
        table.sort(arr, function(a, b)
            if type(a.v) == "number" and type(b.v) == "number" and a.v ~= b.v then
                return a.v < b.v
            end
            return a.k < b.k
        end)
        for i = 1, #arr do
            out("Enum.BagIndex." .. arr[i].k .. " = " .. tostring(arr[i].v))
        end
    else
        out("Enum.BagIndex no existe")
    end
    if ns.Compat then
        local okb, ids = pcall(ns.Compat.BankBags)
        if okb and type(ids) == "table" then
            out("BankBags() = " .. table.concat(ids, ", "))
        else
            out("BankBags() fallo: " .. tostring(ids))
        end
        for id = -3, 20 do
            local okn, size = pcall(ns.Compat.GetNumSlots, id)
            if okn and size and size > 0 then
                local n = 0
                for slot = 1, size do
                    local oks, link = pcall(ns.Compat.GetSlot, id, slot)
                    if oks and link then n = n + 1 end
                end
                out("id=" .. id .. " ranuras=" .. size .. " con objeto=" .. n)
            end
        end
    end
end

SlashCmdList["BANKVISOR"] = function(msg)
    local arg = strtrim and strtrim(msg or "") or (msg or "")
    arg = arg:lower()
    if arg == "debug" then
        DebugDump()
    elseif ns.UI and ns.UI.Toggle then
        ns.UI.Toggle()
    else
        print("Bank Visor: " .. (ns.T and ns.T("UI_UNAVAILABLE") or "UI_UNAVAILABLE"))
    end
end
