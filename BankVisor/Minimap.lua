local ADDON, ns = ...

local M = {}
ns.Minimap = M

local RADIUS = 80
local atan2 = math.atan2 or function(y, x) return math.atan(y / x) end

local function updatePosition(btn)
    local angle = math.rad(ns.DB().minimap.angle or 225)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

local function onDragUpdate(btn)
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    ns.DB().minimap.angle = math.deg(atan2(cy - my, cx - mx))
    updatePosition(btn)
end

function M.Init()
    if M.button then return end
    if ns.DB().minimap.hide then return end

    local btn = CreateFrame("Button", "BankVisorMinimapButton", Minimap)
    M.button = btn
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    btn:SetScript("OnClick", function()
        if ns.UI and ns.UI.Toggle then ns.UI.Toggle() end
    end)
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", onDragUpdate)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ns.T("TITLE"))
        GameTooltip:AddLine(ns.T("MINIMAP_TIP"), 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    updatePosition(btn)
end
