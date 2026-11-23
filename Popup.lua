-- ForeverMacroDropdown - Popup
-- Secure frames: a hidden toggle button the macro /clicks, and the popup bar of secure action buttons.
-- Everything shown/hidden here goes through the restricted (secure) environment, so it also works in combat.

local ADDON, ns = ...

ns.frames = {} -- [bar.id] = { toggle, popup, buttons, anchor }

local GAP = 2 -- space between the action button and the popup
local PAD = 3 -- padding inside the popup
local DEFAULT_SIZE = 40 -- button size when the macro isn't on an action bar

-- popup point, anchor point, x, y
local ANCHORS = {
    UP    = { "BOTTOM", "TOP",    0,    GAP },
    DOWN  = { "TOP",    "BOTTOM", 0,   -GAP },
    RIGHT = { "LEFT",   "RIGHT",  GAP,  0   },
    LEFT  = { "RIGHT",  "LEFT",  -GAP,  0   },
}

-- Grid layout per direction: the popup corner the first button sits in, the x/y step "outward"
-- (away from the action button) and the x/y step "across" (to the next column/row of the same line).
local GRID = {
    UP    = { point = "BOTTOMLEFT", out = { 0,  1 }, across = { 1,  0 } },
    DOWN  = { point = "TOPLEFT",    out = { 0, -1 }, across = { 1,  0 } },
    RIGHT = { point = "TOPLEFT",    out = { 1,  0 }, across = { 0, -1 } },
    LEFT  = { point = "TOPRIGHT",   out = { -1, 0 }, across = { 0, -1 } },
}

local ACTION_ATTRIBUTES = { "type", "spell", "item", "toy", "macro", "macrotext" }

-- Runs in the restricted environment when the macro does /click FMDToggleN.
local TOGGLE_SNIPPET = [[
    local popup = self:GetFrameRef("popup")
    if not popup then return end
    if popup:IsShown() then
        popup:Hide()
    else
        popup:Show()
        local delay = popup:GetAttribute("fmd-autohide")
        -- no auto-hide while the config window is open, so the popup can be adjusted in place
        if delay and delay > 0 and not popup:GetAttribute("fmd-editing") then
            popup:RegisterAutoHide(delay)
            local anchor = self:GetFrameRef("anchor")
            if anchor then popup:AddToAutoHide(anchor) end
        end
    end
]]

-- Run on an open popup when the config window opens / closes.
local PAUSE_AUTOHIDE = [[ self:UnregisterAutoHide() ]]
local REARM_AUTOHIDE = [[
    local delay = self:GetAttribute("fmd-autohide")
    if delay and delay > 0 then
        self:RegisterAutoHide(delay)
        local anchor = self:GetFrameRef("anchor")
        if anchor then self:AddToAutoHide(anchor) end
    end
]]

-- Runs in the restricted environment after a popup button is clicked.
-- The action itself fires on key-down or key-up depending on the ActionButtonUseKeyDown CVar;
-- the release always comes last, so we close on release.
local CLOSE_AFTER_CLICK = [[
    if not down and self:GetAttribute("fmd-close") then
        owner:Hide()
    end
]]

local GetActionInfo = GetActionInfo or (C_ActionBar and C_ActionBar.GetActionInfo)
local GetActionText = GetActionText or (C_ActionBar and C_ActionBar.GetActionText)

---------------------------------------------------------------------------
-- Button visuals
---------------------------------------------------------------------------

local function UpdateCooldown(b, e)
    local start, duration
    if e.type == "spell" then
        if C_Spell and C_Spell.GetSpellCooldown then
            local info = C_Spell.GetSpellCooldown(e.id)
            if info then start, duration = info.startTime, info.duration end
        elseif GetSpellCooldown then
            start, duration = GetSpellCooldown(e.id)
        end
    elseif e.type == "item" or e.type == "toy" then
        local f = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
        if f then start, duration = f(e.id) end
    end
    if start and duration then
        b.cooldown:SetCooldown(start, duration)
    else
        b.cooldown:Clear()
    end
end

local function UpdateCount(b, e)
    if e.type == "item" then
        local f = (C_Item and C_Item.GetItemCount) or GetItemCount
        local count = f(e.id, false, true) or 0
        b.count:SetText(count ~= 1 and count or "")
        b.icon:SetDesaturated(count == 0)
    else
        b.count:SetText("")
        b.icon:SetDesaturated(false)
    end
end

-- Tint like the default action bars: blue when out of power, grey when unusable.
local function UpdateUsable(b, e)
    local usable, noPower = true, false
    if e.type == "spell" then
        local f = (C_Spell and C_Spell.IsSpellUsable) or IsUsableSpell
        if f then usable, noPower = f(e.id) end
    elseif e.type == "item" then
        local f = (C_Item and C_Item.IsUsableItem) or IsUsableItem
        if f then usable, noPower = f(e.id) end
    end
    if usable then
        b.icon:SetVertexColor(1, 1, 1)
    elseif noPower then
        b.icon:SetVertexColor(0.5, 0.5, 1)
    else
        b.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

function ns:UpdatePopupButtons(fr)
    for _, b in ipairs(fr.buttons) do
        local e = b.entry
        if e then
            local _, icon = self:EntryInfo(e)
            b.icon:SetTexture(icon or self.QUESTION_ICON)
            -- pcall: some combat values may be "secret" on Midnight-era clients
            pcall(UpdateCooldown, b, e)
            pcall(UpdateCount, b, e)
            pcall(UpdateUsable, b, e)
        end
    end
end

local updater = CreateFrame("Frame")
for _, e in ipairs({
    "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "BAG_UPDATE_COOLDOWN", "BAG_UPDATE_DELAYED", "UNIT_POWER_FREQUENT",
}) do
    pcall(updater.RegisterEvent, updater, e)
end
updater:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_POWER_FREQUENT" and unit ~= "player" then return end
    for _, fr in pairs(ns.frames) do
        if fr.popup:IsVisible() then ns:UpdatePopupButtons(fr) end
    end
end)

---------------------------------------------------------------------------
-- Frame creation
---------------------------------------------------------------------------

local function PopupButton_OnEnter(self)
    if not self.entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    ns:SetEntryTooltip(GameTooltip, self.entry)
end

local function PopupButton_OnLeave()
    GameTooltip:Hide()
end

function ns:CreatePopupButton(fr, i)
    local popup = fr.popup
    local b = CreateFrame("Button", popup:GetName() .. "Button" .. i, popup, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints()

    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)

    b:SetScript("OnEnter", PopupButton_OnEnter)
    b:SetScript("OnLeave", PopupButton_OnLeave)

    b:SetScript("PostClick", function() end) -- give the wrapper a script to wrap
    SecureHandlerWrapScript(b, "PostClick", popup, CLOSE_AFTER_CLICK)

    fr.buttons[i] = b
    return b
end

function ns:GetFrames(bar)
    local fr = self.frames[bar.id]
    if fr then return fr end

    local id = bar.id
    local popup = CreateFrame("Frame", "FMDPopup" .. id, UIParent, "SecureHandlerShowHideTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()
    popup.bg = popup:CreateTexture(nil, "BACKGROUND")
    popup.bg:SetAllPoints()
    popup.bg:SetColorTexture(0, 0, 0, 0.55)
    -- 1px border, drawn as four edge textures
    popup.edges = {}
    for i, pts in ipairs({
        { "TOPLEFT", "TOPRIGHT", 0, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -1 },
        { "TOPLEFT", "BOTTOMLEFT", -1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 },
    }) do
        local t = popup:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.45, 0.55, 0.65, 0.8)
        t:SetPoint(pts[1], popup, pts[1], pts[3], pts[4])
        t:SetPoint(pts[2], popup, pts[2], pts[3], pts[4])
        if pts[3] == 0 then t:SetHeight(1) else t:SetWidth(1) end
        popup.edges[i] = t
    end

    -- Secure "close" button. It is shown only while the popup is open and serves two purposes:
    --  * it covers the screen at BACKGROUND strata (below all other UI), so clicking the game world closes the popup
    --  * Escape is bound to it while the popup is open
    -- Both work in combat.
    local closer = CreateFrame("Button", "FMDPopup" .. id .. "Close", popup, "SecureHandlerClickTemplate")
    closer:SetFrameStrata("BACKGROUND")
    closer:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
    closer:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT")
    closer:EnableMouse(true)
    closer:RegisterForClicks("AnyDown")
    SecureHandlerSetFrameRef(closer, "popup", popup)
    closer:SetAttribute("_onclick", [[ self:GetFrameRef("popup"):Hide() ]])

    popup:SetAttribute("fmd-closer", closer:GetName())
    popup:SetAttribute("_onshow", [[ self:SetBindingClick(true, "ESCAPE", self:GetAttribute("fmd-closer")) ]])
    popup:SetAttribute("_onhide", [[ self:ClearBindings() ]])

    -- No size, so it's invisible; it exists only to be /clicked by the macro.
    local toggle = CreateFrame("Button", self.ToggleName(bar), UIParent, "SecureHandlerClickTemplate")
    toggle:RegisterForClicks("AnyUp", "AnyDown")
    toggle:SetAttribute("_onclick", TOGGLE_SNIPPET)
    SecureHandlerSetFrameRef(toggle, "popup", popup)
    SecureHandlerSetFrameRef(toggle, "anchor", popup)
    -- Out of combat, anchor the popup to whichever action button was actually clicked.
    toggle:SetScript("PreClick", function() ns:AnchorFromMouse(id) end)

    fr = { id = id, popup = popup, toggle = toggle, buttons = {} }
    popup:HookScript("OnShow", function()
        ns:UpdatePopupButtons(fr)
        ns:RefreshConfig()
    end)
    popup:HookScript("OnHide", function() ns:RefreshConfig() end)

    self.frames[id] = fr
    return fr
end

local function ConfigureButton(b, e, bar)
    for _, attr in ipairs(ACTION_ATTRIBUTES) do b:SetAttribute(attr, nil) end
    if e.type == "spell" then
        b:SetAttribute("type", "spell")
        -- the name casts the highest known rank; fall back to the ID
        b:SetAttribute("spell", ns.GetSpellName(e.id) or e.id)
    elseif e.type == "item" then
        b:SetAttribute("type", "item")
        b:SetAttribute("item", "item:" .. e.id)
    elseif e.type == "toy" then
        b:SetAttribute("type", "toy")
        b:SetAttribute("toy", e.id)
    elseif e.type == "macro" then
        b:SetAttribute("type", "macro")
        b:SetAttribute("macro", e.name)
    end
    b:SetAttribute("fmd-close", bar.closeOnUse and true or nil)
    b.entry = e
end

-- Position the popup's buttons for a given button size (in the popup's own scale).
-- bar.lines is the number of columns (vertical popups) or rows (horizontal popups).
-- The line nearest the action button fills first, then the popup grows outward.
local function LayoutBar(bar, fr, size)
    local popup = fr.popup
    local n, spacing = #bar.entries, bar.spacing
    local g = GRID[bar.direction] or GRID.UP
    local across = math.max(1, math.min(bar.lines or 1, math.max(n, 1)))
    local outward = math.max(1, math.ceil(n / across))
    local stride = size + spacing

    for i = 1, n do
        local b = fr.buttons[i]
        local o, a = math.floor((i - 1) / across), (i - 1) % across
        local x = g.out[1] * (PAD + o * stride) + g.across[1] * (PAD + a * stride)
        local y = g.out[2] * (PAD + o * stride) + g.across[2] * (PAD + a * stride)
        b:SetSize(size, size)
        b:ClearAllPoints()
        b:SetPoint(g.point, popup, g.point, x, y)
    end

    local long = outward * size + (outward - 1) * spacing + 2 * PAD
    local short = across * size + (across - 1) * spacing + 2 * PAD
    if bar.direction == "LEFT" or bar.direction == "RIGHT" then
        popup:SetSize(long, short)
    else
        popup:SetSize(short, long)
    end
end

function ns:BuildBar(bar)
    if InCombatLockdown() then self.pendingRefresh = true return end
    local fr = self:GetFrames(bar)
    local popup = fr.popup
    local n = #bar.entries

    popup:SetAttribute("fmd-autohide", bar.autoHide or 0)
    popup:SetAttribute("fmd-editing", self.editing or nil)
    local showBg = bar.showBackground ~= false
    popup.bg:SetShown(showBg)
    for _, t in ipairs(popup.edges) do t:SetShown(showBg) end

    for i, entry in ipairs(bar.entries) do
        local b = fr.buttons[i] or self:CreatePopupButton(fr, i)
        ConfigureButton(b, entry, bar)
        b:Show()
    end
    for i = n + 1, #fr.buttons do
        local b = fr.buttons[i]
        for _, attr in ipairs(ACTION_ATTRIBUTES) do b:SetAttribute(attr, nil) end
        b.entry = nil
        b:Hide()
    end

    self:ApplyAnchor(bar, fr.anchor) -- also lays out the buttons
    if popup:IsShown() then self:UpdatePopupButtons(fr) end
    self:RequestScan()
end

function ns:BuildAll()
    if InCombatLockdown() then self.pendingRefresh = true return end
    for _, bar in ipairs(self.db.bars) do self:BuildBar(bar) end
end

-- Frames can't be destroyed; a deleted bar's frames are emptied and left hidden.
function ns:ReleaseBar(id)
    local fr = self.frames[id]
    if not fr then return end
    fr.popup:Hide()
    for _, b in ipairs(fr.buttons) do
        for _, attr in ipairs(ACTION_ATTRIBUTES) do b:SetAttribute(attr, nil) end
        b.entry = nil
        b:Hide()
    end
    self.frames[id] = nil
end

---------------------------------------------------------------------------
-- Anchoring the popup to the action button that holds the macro
---------------------------------------------------------------------------

local function GetButtonSlot(f)
    local slot
    if f._state_type == "action" then slot = f._state_action end -- LibActionButton (Bartender4, ElvUI, ...)
    if type(slot) ~= "number" then slot = f.action end            -- Blizzard bars, Dominos, ...
    if type(slot) == "number" and slot > 0 then return slot end
end

local function ButtonHoldsMacro(f, name)
    local slot = GetButtonSlot(f)
    return slot and GetActionInfo(slot) == "macro" and GetActionText(slot) == name
end

function ns:ApplyAnchor(bar, anchor)
    if InCombatLockdown() then return end
    local fr = self.frames[bar.id]
    if not fr then return end
    local popup = fr.popup

    -- Match the action button's size and on-screen scale (bar addons and Edit Mode "Icon Size" scale bars).
    local size, scale = DEFAULT_SIZE, 1
    if anchor then
        local w = anchor:GetWidth()
        if w and w > 1 then
            size = w
            scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
        end
    end
    popup:SetScale(scale)
    LayoutBar(bar, fr, size)

    popup:ClearAllPoints()
    if anchor then
        local a = ANCHORS[bar.direction] or ANCHORS.UP
        popup:SetPoint(a[1], anchor, a[2], a[3], a[4])
        SecureHandlerSetFrameRef(fr.toggle, "anchor", anchor)
        SecureHandlerSetFrameRef(popup, "anchor", anchor)
    else
        -- macro isn't on a visible action button: show near the middle of the screen
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        SecureHandlerSetFrameRef(fr.toggle, "anchor", popup)
        SecureHandlerSetFrameRef(popup, "anchor", popup)
    end
    fr.anchor = anchor
end

function ns:AnchorFromMouse(id)
    if InCombatLockdown() then return end
    local bar = self:GetBar(id)
    if not bar then return end
    local focus
    if GetMouseFoci then
        focus = GetMouseFoci()[1]
    elseif GetMouseFocus then
        focus = GetMouseFocus()
    end
    if type(focus) == "table" then
        local ok, holds = pcall(ButtonHoldsMacro, focus, bar.name)
        if ok and holds then self:ApplyAnchor(bar, focus) end
    end
end

-- Walk all frames looking for visible action buttons that hold one of our macros.
function ns:ScanAnchors()
    if InCombatLockdown() then self.pendingRefresh = true return end
    local byName, found = {}, {}
    for _, bar in ipairs(self.db.bars) do byName[bar.name] = bar end

    if next(byName) then
        local function check(f)
            if f:IsVisible() then
                local slot = GetButtonSlot(f)
                if slot and GetActionInfo(slot) == "macro" then
                    local bar = byName[GetActionText(slot) or ""]
                    if bar and not found[bar.id] then found[bar.id] = f end
                end
            end
        end

        if EnumerateFrames then
            local f = EnumerateFrames()
            while f do
                if not (f.IsForbidden and f:IsForbidden()) then pcall(check, f) end
                f = EnumerateFrames(f)
            end
        elseif ActionBarButtonEventsFrame and ActionBarButtonEventsFrame.frames then
            for _, f in pairs(ActionBarButtonEventsFrame.frames) do pcall(check, f) end
        end
    end

    for _, bar in ipairs(self.db.bars) do
        self:ApplyAnchor(bar, found[bar.id])
    end
    self:RefreshConfig()
end

-- Coalesce bursts of action bar events into one scan.
function ns:RequestScan()
    if self.scanQueued then return end
    self.scanQueued = true
    C_Timer.After(0.25, function()
        ns.scanQueued = false
        if InCombatLockdown() then
            ns.pendingRefresh = true
        else
            ns:ScanAnchors()
        end
    end)
end

function ns:IsBarOnActionBar(bar)
    local fr = self.frames[bar.id]
    return fr and fr.anchor ~= nil
end

---------------------------------------------------------------------------
-- Editing mode: while the config window is open, popups stay open
-- (no auto-hide, no closing on UI clicks) so they can be adjusted on the action bar.
-- The macro toggle, Escape and world clicks still close them.
---------------------------------------------------------------------------

function ns:SetEditMode(on)
    self.editing = on and true or nil
    self:ApplyEditMode()
end

function ns:ApplyEditMode()
    if InCombatLockdown() then self.pendingRefresh = true return end
    for _, fr in pairs(self.frames) do
        local popup = fr.popup
        popup:SetAttribute("fmd-editing", self.editing)
        if popup:IsShown() and SecureHandlerExecute then
            SecureHandlerExecute(popup, self.editing and PAUSE_AUTOHIDE or REARM_AUTOHIDE)
        end
    end
end

function ns:IsPopupShown(bar)
    local fr = self.frames[bar.id]
    return fr and fr.popup:IsShown()
end

---------------------------------------------------------------------------
-- Out of combat: close when clicking any other UI element too
-- (in combat only world clicks and Escape close it, via the secure closer)
---------------------------------------------------------------------------

local clickWatcher = CreateFrame("Frame")
pcall(clickWatcher.RegisterEvent, clickWatcher, "GLOBAL_MOUSE_DOWN")
clickWatcher:SetScript("OnEvent", function()
    if InCombatLockdown() or ns.editing then return end
    local focus
    if GetMouseFoci then
        focus = GetMouseFoci()[1]
    elseif GetMouseFocus then
        focus = GetMouseFocus()
    end
    -- clicking the minimap button opens the config window: keep the popup so it can be edited
    if focus and focus == ns.minimapButton then return end
    for id, fr in pairs(ns.frames) do
        local popup = fr.popup
        if popup:IsShown() and not popup:IsMouseOver() and focus ~= ns.previewButton
            and not (fr.anchor and fr.anchor:IsMouseOver()) then
            -- leave it to the macro's own toggle if the click is on a button holding the macro
            local bar = ns:GetBar(id)
            local ok, onMacro = false, false
            if bar and type(focus) == "table" then ok, onMacro = pcall(ButtonHoldsMacro, focus, bar.name) end
            if not (ok and onMacro) then popup:Hide() end
        end
    end
end)

-- Show / hide a bar's popup from the config window.
-- Done directly rather than via fr.toggle:Click(): the toggle is registered for both down and up clicks
-- (needed for the macro's /click), so a scripted Click() can fire it twice and reopen-then-close the popup.
-- Showing a secure frame from addon code is allowed out of combat, and its _onshow still binds Escape.
function ns:PreviewBar(bar)
    if not self:CheckCombat() then return end
    if not self.frames[bar.id] then self:BuildBar(bar) end
    local fr = self.frames[bar.id]
    if not fr then return end
    local popup = fr.popup
    if popup:IsShown() then
        popup:Hide()
        return
    end
    self:ApplyAnchor(bar, fr.anchor) -- next to the macro's action button, or screen centre if it isn't on one
    popup:Show()
    if not self.editing and SecureHandlerExecute then
        SecureHandlerExecute(popup, REARM_AUTOHIDE)
    end
end
