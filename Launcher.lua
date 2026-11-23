-- ForeverMacroDropdown - Launchers
-- Minimap button, AddOns compartment entry and the page under Options > AddOns.

local ADDON, ns = ...

local STATUS_TEXT = {
    placed   = "|cff40ff40on action bar|r",
    unplaced = "|cffffd040not on a visible bar|r",
    missing  = "|cffff6040macro missing|r",
}

---------------------------------------------------------------------------
-- Shared tooltip
---------------------------------------------------------------------------

function ns:FillLauncherTooltip(tt, showDragHint)
    tt:SetText(self.TITLE .. (self.VERSION ~= "" and ("  |cff808080v" .. self.VERSION .. "|r") or ""), 1, 1, 1)
    local bars = self.db and self.db.bars or {}
    if #bars == 0 then
        tt:AddLine("No bars yet.", 0.6, 0.6, 0.6)
    else
        for i, bar in ipairs(bars) do
            if i > 12 then
                tt:AddLine(("...and %d more"):format(#bars - 12), 0.6, 0.6, 0.6)
                break
            end
            tt:AddDoubleLine(("|T%s:14:14:0:0:64:64:5:59:5:59|t %s"):format(self:BarIcon(bar), bar.name),
                STATUS_TEXT[self:BarStatus(bar)], 1, 1, 1)
        end
    end
    tt:AddLine(" ")
    tt:AddLine("Left-click: open the bar editor", 0.5, 0.8, 1)
    tt:AddLine("Right-click: settings (Options > AddOns)", 0.5, 0.8, 1)
    if showDragHint then tt:AddLine("Drag: move this button", 0.5, 0.8, 1) end
end

local function OnLauncherClick(button)
    if button == "RightButton" then
        ns:OpenOptions()
    else
        ns:ToggleConfig()
    end
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------

local minimapButton, dbIcon

local function PositionMinimapButton()
    local angle = math.rad(ns.db.minimap.minimapPos or 200)
    local r = (Minimap:GetWidth() / 2) + 10
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function MinimapButton_OnUpdate()
    local mx, my = Minimap:GetCenter()
    local x, y = GetCursorPosition()
    local s = Minimap:GetEffectiveScale()
    ns.db.minimap.minimapPos = math.deg(math.atan2(y / s - my, x / s - mx)) % 360
    PositionMinimapButton()
end

local function CreateMinimapButton()
    local b = CreateFrame("Button", "ForeverMacroDropdownMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("AnyUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = b:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(ns.ADDON_ICON)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    b.icon = icon

    b:SetScript("OnMouseDown", function() icon:SetPoint("TOPLEFT", 8, -7) end)
    b:SetScript("OnMouseUp", function() icon:SetPoint("TOPLEFT", 7, -6) end)
    b:SetScript("OnClick", function(_, button) OnLauncherClick(button) end)
    b:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", MinimapButton_OnUpdate)
        GameTooltip:Hide()
    end)
    b:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        ns:FillLauncherTooltip(GameTooltip, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    minimapButton = b
    ns.minimapButton = b
    PositionMinimapButton()
end

-- Prefer LibDBIcon when another addon has loaded it: it handles square minimaps and button collectors.
local function TryLibDBIcon()
    local LibStub = _G.LibStub
    if not LibStub then return false end
    local ldb = LibStub("LibDataBroker-1.1", true)
    local dbi = LibStub("LibDBIcon-1.0", true)
    if not (ldb and dbi) then return false end
    local obj = ldb:GetDataObjectByName(ADDON) or ldb:NewDataObject(ADDON, {
        type = "launcher",
        label = ns.TITLE,
        icon = ns.ADDON_ICON,
        OnClick = function(_, button) OnLauncherClick(button) end,
        OnTooltipShow = function(tt) ns:FillLauncherTooltip(tt, true) end,
    })
    if not obj then return false end
    local ok = pcall(dbi.Register, dbi, ADDON, obj, ns.db.minimap)
    if not ok then return false end
    dbIcon = dbi
    return true
end

function ns:SetMinimapShown(show)
    self.db.minimap.hide = not show
    if dbIcon then
        if show then dbIcon:Show(ADDON) else dbIcon:Hide(ADDON) end
    elseif minimapButton then
        minimapButton:SetShown(show)
    end
    self:RefreshConfig()
    if self.optionsPanel and self.optionsPanel:IsVisible() then self.optionsPanel:Refresh() end
end

function ns:InitLauncher()
    if not TryLibDBIcon() then
        CreateMinimapButton()
        minimapButton:SetShown(not self.db.minimap.hide)
    end
end

---------------------------------------------------------------------------
-- AddOns compartment (the puzzle-piece menu by the minimap)
---------------------------------------------------------------------------

function ForeverMacroDropdown_OnAddonCompartmentClick(_, button)
    OnLauncherClick(button)
end

function ForeverMacroDropdown_OnAddonCompartmentEnter(_, menuButton)
    GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
    ns:FillLauncherTooltip(GameTooltip, false)
    GameTooltip:Show()
end

function ForeverMacroDropdown_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Options > AddOns page
---------------------------------------------------------------------------

local panel = CreateFrame("Frame")
panel.name = ns.TITLE
panel:Hide()
ns.optionsPanel = panel

local icon = panel:CreateTexture(nil, "ARTWORK")
icon:SetSize(48, 48)
icon:SetPoint("TOPLEFT", 16, -16)
icon:SetTexture(ns.ADDON_ICON)

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4)
title:SetText(ns.TITLE)

local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
version:SetPoint("LEFT", title, "RIGHT", 8, 0)
version:SetText(ns.VERSION ~= "" and ("v" .. ns.VERSION) or "")

local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
desc:SetJustifyH("LEFT")
desc:SetText("Action-bar macros that open a popup bar of spells, items, toys, mounts and macros. Works in combat.")

local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
openBtn:SetSize(200, 26)
openBtn:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -20)
openBtn:SetText("Open Bar Editor")
openBtn:SetScript("OnClick", function()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
    ns:OpenConfig()
end)

local openHint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
openHint:SetPoint("LEFT", openBtn, "RIGHT", 10, 0)
openHint:SetText("or type /fbar")

local minimapCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
minimapCheck:SetSize(26, 26)
minimapCheck:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", -4, -14)
local minimapLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
minimapLabel:SetPoint("LEFT", minimapCheck, "RIGHT", 4, 0)
minimapLabel:SetText("Show minimap button")
minimapCheck:SetScript("OnClick", function(self) ns:SetMinimapShown(self:GetChecked()) end)

local loginCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
loginCheck:SetSize(26, 26)
loginCheck:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 0, -2)
local loginLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
loginLabel:SetPoint("LEFT", loginCheck, "RIGHT", 4, 0)
loginLabel:SetText("Show login message in chat")
loginCheck:SetScript("OnClick", function(self) ns.db.loginMessage = self:GetChecked() and true or false end)

local dockCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
dockCheck:SetSize(26, 26)
dockCheck:SetPoint("TOPLEFT", loginCheck, "BOTTOMLEFT", 0, -2)
local dockLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
dockLabel:SetPoint("LEFT", dockCheck, "RIGHT", 4, 0)
dockLabel:SetText("Open the bar editor together with the macro window (/macro), attached to it")
dockCheck:SetScript("OnClick", function(self) ns:SetDockToMacro(self:GetChecked()) end)

local barsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
barsHeader:SetPoint("TOPLEFT", dockCheck, "BOTTOMLEFT", 4, -20)
barsHeader:SetText("Your bars")

local barsText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
barsText:SetPoint("TOPLEFT", barsHeader, "BOTTOMLEFT", 0, -8)
barsText:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
barsText:SetJustifyH("LEFT")
barsText:SetSpacing(4)

local cmdHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
cmdHeader:SetPoint("TOPLEFT", barsText, "BOTTOMLEFT", 0, -20)
cmdHeader:SetText("Slash commands")

local cmdText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
cmdText:SetPoint("TOPLEFT", cmdHeader, "BOTTOMLEFT", 0, -8)
cmdText:SetJustifyH("LEFT")
cmdText:SetSpacing(3)
cmdText:SetText(table.concat({
    "|cffffd100/fbar|r  open or close the bar editor (with the macro window)",
    "|cffffd100/fbar options|r  open the bar editor",
    "|cffffd100/fbar settings|r  open this page",
    "|cffffd100/fbar new <name>|r  create a bar",
    "|cffffd100/fbar list|r  list your bars",
    "|cffffd100/fbar scan|r  re-find which action buttons hold your macros",
    "|cffffd100/fbar minimap|r  show or hide the minimap button",
}, "\n"))

local aboutHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
aboutHeader:SetPoint("TOPLEFT", cmdText, "BOTTOMLEFT", 0, -20)
aboutHeader:SetText("About")

local aboutText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
aboutText:SetPoint("TOPLEFT", aboutHeader, "BOTTOMLEFT", 0, -8)
aboutText:SetJustifyH("LEFT")
aboutText:SetText("Made by " .. ns.AUTHOR .. ". Bug reports, ideas and updates on GitHub (click the link, then Ctrl+C to copy):")

-- WoW can't open web links, so offer the URL in a read-only box for copying.
local urlBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
urlBox:SetSize(340, 20)
urlBox:SetPoint("TOPLEFT", aboutText, "BOTTOMLEFT", 6, -6)
urlBox:SetAutoFocus(false)
urlBox:SetText(ns.WEBSITE)
urlBox:SetCursorPosition(0)
urlBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(ns.WEBSITE) self:HighlightText() end
end)
urlBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
urlBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
urlBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
urlBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

function panel:Refresh()
    if not ns.db then return end
    minimapCheck:SetChecked(not ns.db.minimap.hide)
    loginCheck:SetChecked(ns.db.loginMessage ~= false)
    dockCheck:SetChecked(ns.db.dockToMacro ~= false)
    local lines = {}
    for _, bar in ipairs(ns.db.bars) do
        lines[#lines + 1] = ("|T%s:16:16:0:0:64:64:5:59:5:59|t  %s  |cff808080(%d entries)|r  %s"):format(
            ns:BarIcon(bar), bar.name, #bar.entries, STATUS_TEXT[ns:BarStatus(bar)])
    end
    barsText:SetText(#lines > 0 and table.concat(lines, "\n") or "|cff808080None yet. Click \"Open Bar Editor\" to create one.|r")
end
panel:SetScript("OnShow", panel.Refresh)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, ns.TITLE)
    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

function ns:OpenOptions()
    if InCombatLockdown() then
        self:Print("The settings page can't be opened in combat.")
        return
    end
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel) -- first call may only open the frame
    end
end
