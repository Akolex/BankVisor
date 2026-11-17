local ADDON, ns = ...
local SLOT_SIZE = 37
local SLOT_GAP = 2
local PER_ROW = 14
local STEP = SLOT_SIZE + SLOT_GAP
local LABEL_H = 18
local SECTION_GAP = 6
local EMPTY_SLOT_TEX = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

local frame                
local scroll, child
local tabBank, tabGuild
local dropdown
local footer, message
local buttons = {}         
local labels = {}          
local subTabs = {}         
local view = "bank"        
local sel                  
local guildTab = 1
local searchText = ""      
local searchBox, searchHint
local titleText, langDropdown
local footerBase = ""      

local UI = {}
ns.UI = UI


local function FormatTime(t)
    if t then
        return date(ns.T("DATE_FORMAT"), t)
    end
    return nil
end

local function ColorName(key, class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c and c.r and c.g and c.b then
        return string.format("|cff%02x%02x%02x%s|r",
            math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5), key)
    end
    return key
end

local function GetChars()
    local db = ns.DB and ns.DB()
    return db and db.chars or {}
end

local function GetGuilds()
    local db = ns.DB and ns.DB()
    return db and db.guilds or {}
end

local function SortedCharKeys()
    local chars = GetChars()
    local list, seen = {}, {}
    for k in pairs(chars) do
        list[#list + 1] = k
        seen[k] = true
    end
    local cur = ns.CharKey and ns.CharKey()
    if cur and not seen[cur] then
        list[#list + 1] = cur
    end
    table.sort(list)
    return list
end


local function SlotOnEnter(self)
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
        GameTooltip:Show()
    end
end

local function SlotOnLeave()
    GameTooltip:Hide()
end

local function SlotOnClick(self)
    if self.link and ChatEdit_InsertLink
        and ((IsModifiedClick and IsModifiedClick("CHATLINK")) or IsShiftKeyDown()) then
        ChatEdit_InsertLink(self.link)
    end
end

local function CreateSlot()
    local b = CreateFrame("Button", nil, child)
    b:SetSize(SLOT_SIZE, SLOT_SIZE)
    b:RegisterForClicks("LeftButtonUp")

    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetTexture(EMPTY_SLOT_TEX)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)

    b.border = b:CreateTexture(nil, "OVERLAY")
    b.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.border:SetBlendMode("ADD")
    b.border:SetAlpha(0.8)
    b.border:SetSize(SLOT_SIZE * 1.8, SLOT_SIZE * 1.8)
    b.border:SetPoint("CENTER")
    b.border:Hide()

    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)

    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

    b:SetScript("OnEnter", SlotOnEnter)
    b:SetScript("OnLeave", SlotOnLeave)
    b:SetScript("OnClick", SlotOnClick)
    return b
end

local function SetSlot(b, data)
    local link = data and data.link
    b.link = link
    if link and data then
        b.icon:SetTexture(data.icon)
        b.icon:Show()
        local count = tonumber(data.count)
        if count and count > 1 then
            b.count:SetText(count)
            b.count:Show()
        else
            b.count:Hide()
        end
        local quality
        if GetItemInfo then
            local _, _, q = GetItemInfo(link)
            quality = q
        end
        local qc = quality and quality > 1 and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        if qc then
            b.border:SetVertexColor(qc.r, qc.g, qc.b)
            b.border:Show()
        else
            b.border:Hide()
        end
    else
        b.icon:Hide()
        b.count:Hide()
        b.border:Hide()
    end
end


local used = { buttons = 0, labels = 0 }

local function ResetPools()
    used.buttons = 0
    used.labels = 0
end

local function HideUnused()
    for i = used.buttons + 1, #buttons do
        buttons[i]:Hide()
        buttons[i].link = nil
    end
    for i = used.labels + 1, #labels do
        labels[i]:Hide()
    end
end

local function AddLabel(text, y)
    used.labels = used.labels + 1
    local fs = labels[used.labels]
    if not fs then
        fs = child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetJustifyH("LEFT")
        labels[used.labels] = fs
    end
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y)
    fs:SetText(text)
    fs:Show()
    return y + LABEL_H
end

local function AddGrid(items, size, y)
    items = items or {}
    for i = 1, size do
        used.buttons = used.buttons + 1
        local b = buttons[used.buttons]
        if not b then
            b = CreateSlot()
            buttons[used.buttons] = b
        end
        local col = (i - 1) % PER_ROW
        local row = math.floor((i - 1) / PER_ROW)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", child, "TOPLEFT", col * STEP, -(y + row * STEP))
        SetSlot(b, items[i])
        b:Show()
    end
    return y + math.ceil(size / PER_ROW) * STEP
end

local function SetMessage(text)
    if text then
        message:SetText(text)
        message:Show()
    else
        message:Hide()
    end
end

local function RenderBank()
    local char = GetChars()[sel]
    local bank = char and char.bank
    local bags = bank and bank.bags
    if not bags or #bags == 0 then
        footer:SetText(ns.T("NO_DATA_BANK"))
        child:SetHeight(1)
        return
    end

    local pmax = ns.Compat and ns.Compat.PlayerBagMax and ns.Compat.PlayerBagMax() or 4
    local reagent = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
    local combined = {}
    local total, filled = 0, 0
    for _, bag in ipairs(bags) do
        local size = tonumber(bag.size) or 0
        local id = tonumber(bag.id)
        local skip = id and ((id >= 0 and id <= pmax) or (reagent and id == reagent)
            or (REAGENTBAG_CONTAINER and id == REAGENTBAG_CONTAINER))
        if size > 0 and not skip then
            local items = bag.items or {}
            for slot = 1, size do
                local it = items[slot]
                combined[total + slot] = it
                if it then filled = filled + 1 end
            end
            total = total + size
        end
    end

    if total == 0 then
        footer:SetText(ns.T("NO_DATA_BANK"))
        child:SetHeight(1)
        return
    end

    local y = AddGrid(combined, total, 0)
    child:SetHeight(math.max(y, 1))

    local t = FormatTime(bank.time)
    if t then
        footer:SetText(ns.T("UPDATED", t) .. "  -  " .. ns.T("SLOTS_USED", filled, total))
    else
        footer:SetText(ns.T("NO_DATA_BANK"))
    end
end

local function GuildKeyFor(key)
    local char = GetChars()[key]
    local gk = char and char.guild
    if not gk and key == (ns.CharKey and ns.CharKey()) then
        gk = ns.GuildKey and ns.GuildKey()
    end
    return gk
end

local function SubTabOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tabName or ns.T("GUILD_TAB", self.tabIndex or 0))
    GameTooltip:Show()
end

local function CreateSubTab()
    local b = CreateFrame("Button", nil, frame)
    b:SetSize(28, 28)
    b:RegisterForClicks("LeftButtonUp")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.sel = b:CreateTexture(nil, "OVERLAY")
    b.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    b.sel:SetBlendMode("ADD")
    b.sel:SetPoint("TOPLEFT", -4, 4)
    b.sel:SetPoint("BOTTOMRIGHT", 4, -4)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:SetScript("OnEnter", SubTabOnEnter)
    b:SetScript("OnLeave", SlotOnLeave)
    b:SetScript("OnClick", function(self)
        guildTab = self.tabIndex
        UI.Render(true)
    end)
    return b
end

local function HideSubTabs(from)
    for i = from, #subTabs do
        subTabs[i]:Hide()
    end
end

local function RenderGuild()
    local gk = GuildKeyFor(sel)
    if not gk then
        HideSubTabs(1)
        SetMessage(ns.T("NO_GUILD"))
        footer:SetText("")
        child:SetHeight(1)
        return
    end

    local g = GetGuilds()[gk]
    local tabs = g and g.tabs
    local maxTab = 0
    if tabs then
        for k in pairs(tabs) do
            if type(k) == "number" and k > maxTab then maxTab = k end
        end
    end
    local numTabs = math.max(tonumber(g and g.numTabs) or 0, maxTab)
    if not g or not tabs or next(tabs) == nil or numTabs == 0 then
        HideSubTabs(1)
        footer:SetText(ns.T("NO_DATA_GUILD"))
        child:SetHeight(1)
        return
    end

    if guildTab < 1 or guildTab > numTabs then guildTab = 1 end

    for i = 1, numTabs do
        local b = subTabs[i]
        if not b then
            b = CreateSubTab()
            subTabs[i] = b
        end
        local td = tabs[i]
        b.tabIndex = i
        b.tabName = td and td.name
        b.icon:SetTexture((td and td.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", 14 + (i - 1) * 32, -60)
        if i == guildTab then b.sel:Show() else b.sel:Hide() end
        b:Show()
    end
    HideSubTabs(numTabs + 1)

    local td = tabs[guildTab]
    local name = (td and td.name) or ns.T("GUILD_TAB", guildTab)
    if not td or td.viewable == false or not td.items then
        SetMessage(ns.T("NO_DATA_TAB"))
        footer:SetText(name)
        child:SetHeight(1)
        return
    end

    local size = tonumber(ns.GUILD_SLOTS) or 98
    local y = AddGrid(td.items, size, 0)
    child:SetHeight(math.max(y, 1))

    local t = FormatTime(td.time)
    if t then
        footer:SetText(name .. "  -  " .. ns.T("UPDATED", t))
    else
        footer:SetText(name)
    end
end

local function UpdateTabButtons()
    if view == "bank" then
        tabBank:Disable()
        tabGuild:Enable()
    else
        tabGuild:Disable()
        tabBank:Enable()
    end
end

local function UpdateDropdownText()
    local char = GetChars()[sel]
    UIDropDownMenu_SetText(dropdown, ColorName(sel or "?", char and char.class))
end

local function LinkMatches(link)
    if not link then return false end
    local name = link:match("%[(.-)%]")
    if name and string.find(string.lower(name), searchText, 1, true) then
        return true
    end
    if GetItemInfo then
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
        if itemType and string.find(string.lower(itemType), searchText, 1, true) then
            return true
        end
        if itemSubType and string.find(string.lower(itemSubType), searchText, 1, true) then
            return true
        end
    end
    return false
end

local function ApplyFilter()
    local matches = 0
    for i = 1, used.buttons do
        local b = buttons[i]
        if b then
            local normal = true
            if searchText ~= "" then
                normal = LinkMatches(b.link)
                if normal then matches = matches + 1 end
            end
            if normal then
                b:SetAlpha(1)
            else
                b:SetAlpha(0.25)
            end
            if b.icon and b.icon.SetDesaturated then
                b.icon:SetDesaturated(not normal)
            end
        end
    end
    if footer then
        if searchText ~= "" and footerBase ~= "" then
            footer:SetText(footerBase .. " - " .. ns.T("MATCHES", matches))
        else
            footer:SetText(footerBase)
        end
    end
end

function UI.Render(resetScroll)
    if not frame then return end
    if not sel then sel = ns.CharKey and ns.CharKey() end
    UpdateTabButtons()
    UpdateDropdownText()
    ResetPools()
    SetMessage(nil)
    if view == "bank" then
        HideSubTabs(1)
        RenderBank()
    else
        RenderGuild()
    end
    HideUnused()
    footerBase = footer:GetText() or ""
    ApplyFilter()
    if resetScroll then
        scroll:SetVerticalScroll(0)
    end
end


local function InitDropdown(self, level)
    local chars = GetChars()
    for _, key in ipairs(SortedCharKeys()) do
        local char = chars[key]
        local text = ColorName(key, char and char.class)
        local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
        info.text = text
        info.value = key
        info.checked = (key == sel)
        info.func = function()
            sel = key
            CloseDropDownMenus()
            UI.Render(true)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

local function CurrentLangCode()
    local db = ns.DB and ns.DB()
    return (db and db.lang) or "auto"
end

local function LangDisplayName(code)
    for _, l in ipairs(ns.LANGS or {}) do
        if l.code == code then
            return l.name or ns.T("LANG_AUTO")
        end
    end
    return ns.T("LANG_AUTO")
end

local function UpdateLangDropdownText()
    if langDropdown then
        UIDropDownMenu_SetText(langDropdown, LangDisplayName(CurrentLangCode()))
    end
end

local function InitLangDropdown(self, level)
    local cur = CurrentLangCode()
    for _, l in ipairs(ns.LANGS or {}) do
        local code = l.code
        local info = UIDropDownMenu_CreateInfo and UIDropDownMenu_CreateInfo() or {}
        info.text = l.name or ns.T("LANG_AUTO")
        info.value = code
        info.checked = (code == cur)
        info.func = function()
            CloseDropDownMenus()
            ns.SetLang(code)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

local function CreateMainFrame()
    local f
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local fancy = false
    local ok, res = pcall(CreateFrame, "Frame", "BankVisorFrame", UIParent, "BasicFrameTemplateWithInset")
    if ok and res then
        f = res
        fancy = true
    else
        f = CreateFrame("Frame", "BankVisorFrame", UIParent, template)
    end

    f:SetSize(600, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    if fancy then
        local title = f.TitleText or (f.TitleContainer and f.TitleContainer.TitleText)
        if title then
            title:SetText(ns.T("TITLE"))
        else
            title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOP", 0, -6)
            title:SetText(ns.T("TITLE"))
        end
        titleText = title
    else
        if f.SetBackdrop then
            f:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
        end
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -14)
        title:SetText(ns.T("TITLE"))
        titleText = title
        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
    end

    -- Pestanas superiores
    tabBank = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    tabBank:SetSize(80, 22)
    tabBank:SetPoint("TOPLEFT", 14, -30)
    tabBank:SetText(ns.T("TAB_BANK"))
    tabBank:SetScript("OnClick", function()
        view = "bank"
        UI.Render(true)
    end)

    tabGuild = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    tabGuild:SetSize(80, 22)
    tabGuild:SetPoint("LEFT", tabBank, "RIGHT", 4, 0)
    tabGuild:SetText(ns.T("TAB_GUILD"))
    tabGuild:SetScript("OnClick", function()
        view = "guild"
        UI.Render(true)
    end)

    local sok, sres = pcall(CreateFrame, "EditBox", "BankVisorSearchBox", f, "SearchBoxTemplate")
    local templated = sok and sres
    if templated then
        searchBox = sres
    else
        searchBox = CreateFrame("EditBox", "BankVisorSearchBox", f, "InputBoxTemplate")
    end
    searchBox:SetSize(150, 20)
    searchBox:SetPoint("LEFT", tabGuild, "RIGHT", 14, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    if not templated then
        searchBox:SetTextInsets(2, 2, 0, 0)
        searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        searchHint:SetPoint("LEFT", searchBox, "LEFT", 2, 0)
        searchHint:SetText(ns.T("SEARCH"))
    else
        if searchBox.Instructions and searchBox.Instructions.SetText then
            searchBox.Instructions:SetText(ns.T("SEARCH"))
        end
    end
    local function UpdateHint()
        if searchHint then
            if searchBox:GetText() ~= "" or searchBox:HasFocus() then
                searchHint:Hide()
            else
                searchHint:Show()
            end
        end
    end
    local function OnSearchChanged(self)
        local text = self:GetText() or ""
        text = string.lower(text:match("^%s*(.-)%s*$") or "")
        searchText = text
        UpdateHint()
        ApplyFilter()
    end
    if searchBox:GetScript("OnTextChanged") then
        searchBox:HookScript("OnTextChanged", OnSearchChanged)
    else
        searchBox:SetScript("OnTextChanged", OnSearchChanged)
    end
    searchBox:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
    searchBox:HookScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:HookScript("OnEditFocusGained", UpdateHint)
    searchBox:HookScript("OnEditFocusLost", UpdateHint)

    dropdown = CreateFrame("Frame", "BankVisorCharDropDown", f, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -27)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_Initialize(dropdown, InitDropdown)

    scroll = CreateFrame("ScrollFrame", "BankVisorScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -94)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 38)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(PER_ROW * STEP - SLOT_GAP, 1)
    scroll:SetScrollChild(child)

    message = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    message:SetPoint("CENTER", scroll, "CENTER", 0, 0)
    message:SetWidth(440)
    message:SetJustifyH("CENTER")
    message:Hide()

    footer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 16)
    footer:SetWidth(390)
    footer:SetWordWrap(false)
    footer:SetJustifyH("LEFT")

    langDropdown = CreateFrame("Frame", "BankVisorLangDropDown", f, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 6, 6)
    UIDropDownMenu_SetWidth(langDropdown, 110)
    UIDropDownMenu_Initialize(langDropdown, InitLangDropdown)
    UpdateLangDropdownText()

    f:SetScript("OnShow", function() UI.Render(false) end)

    tinsert(UISpecialFrames, "BankVisorFrame")
    f:Hide()
    return f
end


-- PUBLIC API

function UI.Toggle()
    if not frame then
        frame = CreateMainFrame()
        sel = ns.CharKey and ns.CharKey() or sel
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function UI.ApplyLanguage()
    if not frame then return end
    if titleText then titleText:SetText(ns.T("TITLE")) end
    if tabBank then tabBank:SetText(ns.T("TAB_BANK")) end
    if tabGuild then tabGuild:SetText(ns.T("TAB_GUILD")) end
    if searchHint then
        searchHint:SetText(ns.T("SEARCH"))
    elseif searchBox and searchBox.Instructions and searchBox.Instructions.SetText then
        searchBox.Instructions:SetText(ns.T("SEARCH"))
    end
    UpdateLangDropdownText()
    UI.Render(false)
end

function UI.Refresh()
    if frame and frame:IsShown() then
        UI.Render(false)
    end
end

function UI.IsShown()
    return frame ~= nil and frame:IsShown() or false
end
