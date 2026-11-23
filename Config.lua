-- ForeverMacroDropdown - Config window (/ffm)

local ADDON, ns = ...

local frame

local WIDTH, HEIGHT = 660, 492
local LIST_W, ROW_H = 168, 32
local GRID_COLS, SLOT, SLOT_GAP = 8, 40, 4

local COLOR = {
    error = { 1, 0.35, 0.3 },
    ok    = { 0.4, 1, 0.4 },
    info  = { 0.85, 0.85, 0.85 },
}

local STATUS_INDICATOR = {
    placed   = READY_CHECK_READY_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-Ready",
    unplaced = READY_CHECK_WAITING_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-Waiting",
    missing  = READY_CHECK_NOT_READY_TEXTURE or "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

local function SelectedBar()
    return ns.selectedBarId and ns:GetBar(ns.selectedBarId)
end

---------------------------------------------------------------------------
-- Widget helpers
---------------------------------------------------------------------------

local function CreateButton(parent, text, width)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    return b
end

local function CreateLabel(parent, text, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    return fs
end

local function SetTooltip(widget, title, ...)
    local lines = { ... }
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        for _, line in ipairs(lines) do GameTooltip:AddLine(line, nil, nil, nil, true) end
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", GameTooltip_Hide)
end

local function CreateEditBox(parent, width, numeric)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    if numeric then
        e:SetNumeric(true)
        e:SetMaxLetters(3)
        e:SetJustifyH("CENTER")
    end
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return e
end

-- Grey hint text shown in an empty, unfocused edit box.
local function AddPlaceholder(box, text)
    local ph = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ph:SetPoint("LEFT", 2, 0)
    ph:SetPoint("RIGHT", -2, 0)
    ph:SetJustifyH("LEFT")
    ph:SetText(text)
    local function update() ph:SetShown(box:GetText() == "" and not box:HasFocus()) end
    box:HookScript("OnTextChanged", update)
    box:HookScript("OnEditFocusGained", update)
    box:HookScript("OnEditFocusLost", update)
    box.placeholder = ph
end

-- Section title with a thin rule to its right.
local function CreateHeader(parent, text, y)
    local fs = CreateLabel(parent, text, "GameFontNormal")
    fs:SetPoint("TOPLEFT", 0, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.25)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    return fs
end

local function AddBorder(f, r, g, b, a)
    f.edges = {}
    for i, pts in ipairs({
        { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
        { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
    }) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(pts[1])
        t:SetPoint(pts[2])
        if pts[3] then t:SetHeight(1) else t:SetWidth(1) end
        f.edges[i] = t
    end
end

local function SetBorderColor(f, r, g, b, a)
    for _, t in ipairs(f.edges) do t:SetColorTexture(r, g, b, a) end
end

-- Flat toggle button used for the direction selector.
local function CreateSegment(parent, text, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 22)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetColorTexture(1, 1, 1, 0.08)
    b.sel = b:CreateTexture(nil, "BORDER")
    b.sel:SetAllPoints()
    b.sel:SetColorTexture(1, 0.82, 0, 0.35)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    AddBorder(b, 0, 0, 0, 0.6)
    function b:SetSelected(on)
        self.sel:SetShown(on)
        self.text:SetFontObject(on and "GameFontNormalSmall" or "GameFontHighlightSmall")
    end
    return b
end

-- [-] [ n ] [+] number input. onCommit(value) is called with the clamped value.
local function CreateStepper(parent, min, max, onCommit)
    local box = CreateEditBox(parent, 30, true)
    local minus = CreateButton(parent, "-", 22)
    local plus = CreateButton(parent, "+", 22)
    minus:SetPoint("RIGHT", box, "LEFT", -6, 0)
    plus:SetPoint("LEFT", box, "RIGHT", 2, 0)

    local function commit(v)
        v = tonumber(v)
        if v then onCommit(math.max(min, math.min(max, math.floor(v)))) end
        ns:RefreshConfig()
    end
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:HookScript("OnEditFocusLost", function(self) commit(self:GetText()) end)
    minus:SetScript("OnClick", function() commit((tonumber(box:GetText()) or min) - 1) end)
    plus:SetScript("OnClick", function() commit((tonumber(box:GetText()) or min) + 1) end)

    box.minus, box.plus = minus, plus
    return box
end

local function CreateCheck(parent, text, onClick)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(24, 24)
    c.label = CreateLabel(parent, text, "GameFontHighlight")
    c.label:SetPoint("LEFT", c, "RIGHT", 2, 0)
    c:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
        ns:RefreshConfig()
    end)
    return c
end

-- Change a simple per-bar setting from the UI.
local function SetOption(key, value)
    local bar = SelectedBar()
    if not bar or bar[key] == value or not ns:CheckCombat() then return end
    bar[key] = value
    ns:OnBarChanged(bar)
end

---------------------------------------------------------------------------
-- Inline feedback (used by ns:Notify)
---------------------------------------------------------------------------

function ns:ShowConfigFeedback(msg, level)
    if not frame or not frame:IsShown() then return false end
    local c = COLOR[level] or COLOR.error
    frame.feedback:SetText(msg)
    frame.feedback:SetTextColor(c[1], c[2], c[3])
    frame.feedback:SetAlpha(1)
    if frame.feedbackTimer then frame.feedbackTimer:Cancel() end
    frame.feedbackTimer = C_Timer.NewTimer(level == "error" and 8 or 4, function()
        frame.feedback:SetText("")
    end)
    return true
end

---------------------------------------------------------------------------
-- Drag & drop from outside (spellbook, bags, toy box, mount journal, macro UI)
---------------------------------------------------------------------------

local lastDrop
function ns:ConfigDrop(index)
    local bar = SelectedBar()
    if not bar or not GetCursorInfo() then return end
    -- OnReceiveDrag and OnClick can both fire for the same release
    local now = GetTime()
    if lastDrop == now then return end
    lastDrop = now

    local entry, err = self:EntryFromCursor()
    if entry then
        if self:AddEntry(bar, entry, index) then ClearCursor() end
    elseif err then
        self:Notify(err)
    end
end

-- Highlight the grid while the cursor holds something we can accept.
local function UpdateDropHint()
    if not frame or not frame:IsShown() then return end
    local kind = GetCursorInfo()
    local accept = (kind == "spell" or kind == "item" or kind == "mount" or kind == "macro" or kind == "companion")
        and SelectedBar() ~= nil
    if accept then SetBorderColor(frame.grid, 1, 0.82, 0, 0.9) else SetBorderColor(frame.grid, 1, 1, 1, 0.15) end
    frame.grid.dropText:SetShown(accept)
    frame.gridHint:SetShown(not accept)
end

---------------------------------------------------------------------------
-- Reordering inside the grid (drag an entry to another slot)
---------------------------------------------------------------------------

local ghost

local function SlotUnderMouse()
    for _, s in ipairs(frame.slots) do
        if s:IsVisible() and s:IsMouseOver() then return s end
    end
end

local function StartSlotDrag(slot)
    local bar = SelectedBar()
    if not bar or not bar.entries[slot.index] or InCombatLockdown() then return end
    if not ghost then
        ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:SetSize(SLOT, SLOT)
        ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
        ghost.icon:SetAllPoints()
        ghost.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        ghost:SetAlpha(0.75)
        ghost:SetScript("OnUpdate", function(self)
            local x, y = GetCursorPosition()
            local s = self:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
            local over = SlotUnderMouse()
            for _, sl in ipairs(frame.slots) do sl.dropMark:SetShown(sl == over and sl.index ~= self.from) end
        end)
    end
    ghost.from = slot.index
    ghost:SetScale(frame:GetEffectiveScale() / UIParent:GetEffectiveScale())
    ghost.icon:SetTexture(select(2, ns:EntryInfo(bar.entries[slot.index])))
    ghost:Show()
    slot.icon:SetAlpha(0.3)
    GameTooltip:Hide()
end

local function StopSlotDrag()
    if not ghost or not ghost:IsShown() then return end
    ghost:Hide()
    for _, s in ipairs(frame.slots) do s.dropMark:Hide() end
    local bar = SelectedBar()
    local target = SlotUnderMouse()
    if bar and target then
        ns:MoveEntryTo(bar, ghost.from, target.index)
    elseif bar and frame.grid:IsMouseOver() then
        ns:MoveEntryTo(bar, ghost.from, #bar.entries)
    end
    ns:RefreshConfig()
end

---------------------------------------------------------------------------
-- Bar list
---------------------------------------------------------------------------

local function CreateListButton(i)
    local b = CreateFrame("Button", nil, frame.listChild)
    b:SetSize(LIST_W, ROW_H - 2)
    b:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)

    b.selected = b:CreateTexture(nil, "BACKGROUND")
    b.selected:SetAllPoints()
    b.selected:SetColorTexture(1, 0.82, 0, 0.18)
    b.selectedBar = b:CreateTexture(nil, "BORDER")
    b.selectedBar:SetPoint("TOPLEFT")
    b.selectedBar:SetPoint("BOTTOMLEFT")
    b.selectedBar:SetWidth(2)
    b.selectedBar:SetColorTexture(1, 0.82, 0, 0.9)

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(24, 24)
    b.icon:SetPoint("LEFT", 5, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.status = b:CreateTexture(nil, "OVERLAY")
    b.status:SetSize(14, 14)
    b.status:SetPoint("RIGHT", -2, 0)

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.text:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 6, 1)
    b.text:SetPoint("RIGHT", b.status, "LEFT", -2, 0)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)

    b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.sub:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMRIGHT", 6, -1)
    b.sub:SetJustifyH("LEFT")

    b:SetScript("OnClick", function(self)
        ns.selectedBarId = self.barId
        ns:RefreshConfig()
    end)

    -- dragging a bar name picks up its macro, ready to drop on an action bar
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
        local bar = ns:GetBar(self.barId)
        if bar then ns:PickupBarMacro(bar) end
    end)
    b:SetScript("OnEnter", function(self)
        local bar = ns:GetBar(self.barId)
        if not bar then return end
        local status = ns:BarStatus(bar)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(bar.name, 1, 1, 1)
        GameTooltip:AddLine(#bar.entries .. " entries, opens " .. bar.direction:lower(), nil, nil, nil, true)
        if status == "placed" then
            GameTooltip:AddLine("On your action bar.", 0.4, 1, 0.4)
        elseif status == "unplaced" then
            GameTooltip:AddLine("Not on a visible action bar.", 1, 0.82, 0.25)
        else
            GameTooltip:AddLine("Macro not created on this character yet.", 1, 0.4, 0.3)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag onto an action bar to place the macro.", 0.5, 0.8, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    frame.listButtons[i] = b
    return b
end

---------------------------------------------------------------------------
-- Entry grid slot
---------------------------------------------------------------------------

local function CreateSlot(parent, i)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(SLOT, SLOT)
    local col, row = (i - 1) % GRID_COLS, math.floor((i - 1) / GRID_COLS)
    s:SetPoint("TOPLEFT", 3 + col * (SLOT + SLOT_GAP), -(3 + row * (SLOT + SLOT_GAP)))

    s.bg = s:CreateTexture(nil, "BACKGROUND")
    s.bg:SetAllPoints()
    s.bg:SetColorTexture(1, 1, 1, 0.06)

    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.icon:SetAllPoints()
    s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    s.num = s:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    s.num:SetPoint("TOPLEFT", 2, -2)

    -- "+" in the first free slot
    s.plus = s:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    s.plus:SetPoint("CENTER")
    s.plus:SetText("+")

    -- gold frame on the first entry: it sets the macro's icon
    AddBorder(s, 0, 0, 0, 0)

    s.dropMark = s:CreateTexture(nil, "OVERLAY")
    s.dropMark:SetPoint("TOPLEFT", -2, 0)
    s.dropMark:SetPoint("BOTTOMLEFT", -2, 0)
    s.dropMark:SetWidth(3)
    s.dropMark:SetColorTexture(1, 0.82, 0, 1)
    s.dropMark:Hide()

    s:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    s.index = i
    s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    s:RegisterForDrag("LeftButton")

    s:SetScript("OnReceiveDrag", function(self) ns:ConfigDrop(self.index) end)
    s:SetScript("OnDragStart", StartSlotDrag)
    s:SetScript("OnDragStop", StopSlotDrag)
    s:SetScript("OnClick", function(self, button)
        if GetCursorInfo() then
            ns:ConfigDrop(self.index)
            return
        end
        local bar = SelectedBar()
        if not bar or not bar.entries[self.index] then return end
        if button == "RightButton" then
            ns:RemoveEntry(bar, self.index)
        elseif IsShiftKeyDown() then
            ns:MoveEntryTo(bar, self.index, 1)
        end
    end)
    s:SetScript("OnEnter", function(self)
        local bar = SelectedBar()
        local e = bar and bar.entries[self.index]
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if not e then
            GameTooltip:SetText("Empty slot", 1, 1, 1)
            GameTooltip:AddLine("Drop a spell, item, toy, mount or macro here.", nil, nil, nil, true)
            GameTooltip:Show()
            return
        end
        ns:SetEntryTooltip(GameTooltip, e)
        GameTooltip:AddLine(" ")
        if self.index == 1 then GameTooltip:AddLine("First entry: sets the macro's icon and cooldown.", 1, 0.82, 0, true) end
        GameTooltip:AddLine("Drag: move to another slot", 0.5, 0.8, 1)
        if self.index > 1 then GameTooltip:AddLine("Shift-click: make first (macro icon)", 0.5, 0.8, 1) end
        GameTooltip:AddLine("Right-click: remove", 0.5, 0.8, 1)
        GameTooltip:Show()
    end)
    s:SetScript("OnLeave", GameTooltip_Hide)
    return s
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.db.window = { point = point, relPoint = relPoint, x = x, y = y }
end

local function RestorePosition()
    local w = ns.db.window
    frame:ClearAllPoints()
    if w and w.point then
        frame:SetPoint(w.point, UIParent, w.relPoint or w.point, w.x or 0, w.y or 0)
    else
        frame:SetPoint("CENTER")
    end
end

local HELP_LINES = {
    "1. Create a bar and give it a name (this is also the macro name).",
    "2. Drag spells, items, toys, mounts or macros into the grid.",
    "3. Drag the macro icon (or the bar in the list) onto an action bar.",
    "4. Click that action button to open the popup. Click again, press Escape, or click elsewhere to close it.",
    " ",
    "The popup works in combat. Bars can only be edited out of combat.",
}

function ns:CreateConfig()
    if frame then return frame end

    frame = CreateFrame("Frame", "ForeverMacroDropdownConfig", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not self.docked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not self.docked then SavePosition() end
    end)
    frame:SetScript("OnShow", function()
        PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN or 839)
        ns:ApplyDock()
        ns:SetEditMode(true) -- open popups stay open while editing
        ns:RefreshConfig()
    end)
    frame:SetScript("OnHide", function()
        PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_CLOSE or 840)
        StopSlotDrag()
        ns:SetEditMode(false)
        -- the two windows belong together: if we opened the macro window, close it with the editor
        if ns.openedMacroWindow then
            ns.openedMacroWindow = false
            local mf = _G.MacroFrame
            if mf and mf:IsShown() then HideUIPanel(mf) end
        end
    end)
    frame:Hide()
    RestorePosition()
    tinsert(UISpecialFrames, frame:GetName()) -- close with Escape

    -- title bar: icon, title, version, combat indicator, help
    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("TOPLEFT", 8, -4)
    titleIcon:SetTexture(ns.ADDON_ICON)
    local titleText = ns.TITLE .. (ns.VERSION ~= "" and ("  |cff808080v" .. ns.VERSION .. "|r") or "")
    if frame.TitleText then
        frame.TitleText:SetText(titleText)
    else
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
        title:SetText(titleText)
    end

    frame.combatText = CreateLabel(frame, "|cffff4040In combat - editing paused|r", "GameFontNormalSmall")
    frame.combatText:SetPoint("TOPLEFT", titleIcon, "TOPRIGHT", 6, -2)

    local help = CreateFrame("Button", nil, frame)
    help:SetSize(18, 18)
    help:SetPoint("TOPRIGHT", -28, -3)
    help:SetNormalFontObject("GameFontNormal")
    help:SetHighlightFontObject("GameFontHighlight")
    help:SetText("?")
    help:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("How to use", 1, 1, 1)
        for _, line in ipairs(HELP_LINES) do GameTooltip:AddLine(line, nil, nil, nil, true) end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("/ffm new <name>, /ffm list, /ffm scan, /ffm minimap, /ffm settings", 0.5, 0.8, 1, true)
        GameTooltip:Show()
    end)
    help:SetScript("OnLeave", GameTooltip_Hide)

    -------------------------------------------------------------- left side
    CreateLabel(frame, "Bars"):SetPoint("TOPLEFT", 16, -34)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -52)
    scroll:SetSize(LIST_W, 336)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(LIST_W, 1)
    scroll:SetScrollChild(child)
    frame.listChild = child
    frame.listButtons = {}

    frame.listEmpty = CreateLabel(frame, "No bars yet.\nCreate one below.", "GameFontDisableSmall")
    frame.listEmpty:SetPoint("TOP", scroll, "TOP", 0, -20)
    frame.listEmpty:SetJustifyH("CENTER")

    CreateLabel(frame, "New bar", "GameFontNormalSmall"):SetPoint("TOPLEFT", 16, -398)
    local newBox = CreateEditBox(frame, 112)
    newBox:SetPoint("TOPLEFT", 22, -414)
    newBox:SetMaxLetters(ns.MAX_NAME)
    AddPlaceholder(newBox, "Name (max " .. ns.MAX_NAME .. ")")
    frame.newBox = newBox
    local newBtn = CreateButton(frame, "Create", 64)
    newBtn:SetPoint("LEFT", newBox, "RIGHT", 6, 0)
    local function DoCreate()
        local bar = ns:CreateBar(newBox:GetText())
        if bar then
            newBox:SetText("")
            newBox:ClearFocus()
            ns.selectedBarId = bar.id
            ns:Notify("Created \"" .. bar.name .. "\". Now drag spells or items into the grid.", "ok")
            ns:RefreshConfig()
        end
    end
    newBtn:SetScript("OnClick", DoCreate)
    newBox:SetScript("OnEnterPressed", DoCreate)

    frame.minimapCheck = CreateCheck(frame, "Minimap button", function(on) ns:SetMinimapShown(on) end)
    frame.minimapCheck:SetPoint("BOTTOMLEFT", 12, 8)
    frame.minimapCheck.label:SetFontObject("GameFontHighlightSmall")

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 1, 1, 0.1)
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", 214, -30)
    divider:SetPoint("BOTTOMLEFT", 214, 10)

    -------------------------------------------------------------- right side
    local right = CreateFrame("Frame", nil, frame)
    right:SetPoint("TOPLEFT", 228, -30)
    right:SetPoint("BOTTOMRIGHT", -14, 12)
    frame.right = right

    -- welcome / empty state
    local empty = CreateFrame("Frame", nil, frame)
    empty:SetAllPoints(right)
    frame.empty = empty
    local welcomeIcon = empty:CreateTexture(nil, "ARTWORK")
    welcomeIcon:SetSize(64, 64)
    welcomeIcon:SetPoint("TOP", 0, -40)
    welcomeIcon:SetTexture(ns.ADDON_ICON)
    local welcome = CreateLabel(empty, "Welcome to " .. ns.TITLE, "GameFontNormalLarge")
    welcome:SetPoint("TOP", welcomeIcon, "BOTTOM", 0, -12)
    local steps = CreateLabel(empty, table.concat(HELP_LINES, "\n"), "GameFontHighlight")
    steps:SetPoint("TOP", welcome, "BOTTOM", 0, -16)
    steps:SetWidth(340)
    steps:SetSpacing(4)
    local startBtn = CreateButton(empty, "Create your first bar", 170)
    startBtn:SetPoint("TOP", steps, "BOTTOM", 0, -20)
    startBtn:SetScript("OnClick", function() newBox:SetFocus() end)

    -- header: draggable macro icon + name + status
    local macroBtn = CreateFrame("Button", nil, right)
    macroBtn:SetSize(44, 44)
    macroBtn:SetPoint("TOPLEFT", 0, -4)
    macroBtn.icon = macroBtn:CreateTexture(nil, "ARTWORK")
    macroBtn.icon:SetAllPoints()
    macroBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local mbBorder = macroBtn:CreateTexture(nil, "OVERLAY")
    mbBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    mbBorder:SetSize(78, 78)
    mbBorder:SetPoint("CENTER", 0, -1)
    macroBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    macroBtn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    macroBtn:RegisterForDrag("LeftButton")
    local function Pickup()
        local bar = SelectedBar()
        if bar then ns:PickupBarMacro(bar) end
    end
    macroBtn:SetScript("OnDragStart", Pickup)
    macroBtn:SetScript("OnClick", Pickup)
    SetTooltip(macroBtn, "Macro", "Drag (or click) to pick up this bar's macro, then drop it on an action bar.")
    frame.macroBtn = macroBtn

    local nameBox = CreateEditBox(right, 150)
    nameBox:SetPoint("TOPLEFT", macroBtn, "TOPRIGHT", 16, -2)
    nameBox:SetMaxLetters(ns.MAX_NAME)
    nameBox:SetFontObject("GameFontHighlightLarge")
    frame.nameBox = nameBox
    local renameBtn = CreateButton(right, "Rename", 70)
    renameBtn:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)
    local function DoRename()
        local bar = SelectedBar()
        if bar and ns:RenameBar(bar, nameBox:GetText()) then nameBox:ClearFocus() end
        ns:RefreshConfig()
    end
    renameBtn:SetScript("OnClick", DoRename)
    nameBox:SetScript("OnEnterPressed", DoRename)
    nameBox:SetScript("OnEscapePressed", function(self)
        local bar = SelectedBar()
        if bar then self:SetText(bar.name) end
        self:ClearFocus()
    end)
    renameBtn:SetMotionScriptsWhileDisabled(true)
    SetTooltip(renameBtn, "Rename", "Renames the bar and its macro. The macro stays on the same action bar slots.")

    frame.status = CreateLabel(right, "", "GameFontHighlightSmall")
    frame.status:SetPoint("TOPLEFT", macroBtn, "TOPRIGHT", 12, -26)
    frame.status:SetPoint("RIGHT", right, "RIGHT", 0, 0)
    frame.status:SetWordWrap(true)

    -- layout section
    CreateHeader(right, "Popup", -62)

    CreateLabel(right, "Opens", "GameFontHighlight"):SetPoint("TOPLEFT", 0, -88)
    frame.dirButtons = {}
    local prev
    for _, d in ipairs({ { "UP", "Up" }, { "DOWN", "Down" }, { "LEFT", "Left" }, { "RIGHT", "Right" } }) do
        local b = CreateSegment(right, d[2], 52)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 2, 0) else b:SetPoint("TOPLEFT", 60, -84) end
        b:SetScript("OnClick", function() SetOption("direction", d[1]) ns:RefreshConfig() end)
        SetTooltip(b, "Open " .. d[2]:lower(), (d[1] == "UP" or d[1] == "DOWN") and "Vertical popup." or "Horizontal popup.")
        frame.dirButtons[d[1]] = b
        prev = b
    end

    frame.spacingBox = CreateStepper(right, 0, 20, function(v) SetOption("spacing", v) end)
    frame.spacingBox:SetPoint("TOPRIGHT", -26, -85)
    local spacingLabel = CreateLabel(right, "Spacing", "GameFontHighlight")
    spacingLabel:SetPoint("RIGHT", frame.spacingBox.minus, "LEFT", -8, 0)
    SetTooltip(frame.spacingBox, "Spacing", "Gap between the popup's buttons, in pixels.")

    frame.closeCheck = CreateCheck(right, "Close after use", function(on) SetOption("closeOnUse", on) end)
    frame.closeCheck:SetPoint("TOPLEFT", -4, -112)
    SetTooltip(frame.closeCheck, "Close after use", "Hide the popup after you click one of its buttons.")

    frame.bgCheck = CreateCheck(right, "Background", function(on) SetOption("showBackground", on) end)
    frame.bgCheck:SetPoint("TOPLEFT", 136, -112)
    SetTooltip(frame.bgCheck, "Background", "Show a dark backdrop and border behind the popup's buttons.")

    frame.hideBox = CreateStepper(right, 0, 30, function(v) SetOption("autoHide", v) end)
    frame.hideBox:SetPoint("TOPRIGHT", -26, -113)
    local hideLabel = CreateLabel(right, "Auto-hide (s)", "GameFontHighlight")
    hideLabel:SetPoint("RIGHT", frame.hideBox.minus, "LEFT", -8, 0)
    SetTooltip(frame.hideBox, "Auto-hide",
        "Seconds the mouse can be away from the popup before it closes.", "0 = stay open until toggled.")

    frame.charCheck = CreateCheck(right, "Character only", function(on)
        local bar = SelectedBar()
        if bar then ns:SetBarScope(bar, on) end
    end)
    frame.charCheck:SetPoint("TOPLEFT", -4, -138)

    frame.linesBox = CreateStepper(right, 1, 12, function(v) SetOption("lines", v) end)
    frame.linesBox:SetPoint("TOPRIGHT", -26, -139)
    frame.linesLabel = CreateLabel(right, "Columns", "GameFontHighlight")
    frame.linesLabel:SetPoint("RIGHT", frame.linesBox.minus, "LEFT", -8, 0)
    frame.linesBox:HookScript("OnEnter", function(self)
        local bar = SelectedBar()
        local horizontal = bar and (bar.direction == "LEFT" or bar.direction == "RIGHT")
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(horizontal and "Rows" or "Columns", 1, 1, 1)
        GameTooltip:AddLine(("How many %s the popup has. Entries fill the %s nearest the action button first, then the popup grows %s."):format(
            horizontal and "rows" or "columns", horizontal and "column" or "row",
            bar and bar.direction:lower() or "outward"), nil, nil, nil, true)
        GameTooltip:AddLine("1 = a single line.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    frame.linesBox:HookScript("OnLeave", GameTooltip_Hide)
    SetTooltip(frame.charCheck, "Character-specific macro",
        "Checked: the macro goes in this character's macros.",
        "Unchecked: it goes in the account-wide (General) macros.",
        "Switching keeps the macro on the same action bar slots.")

    -- contents section
    frame.contentsHeader = CreateHeader(right, "Contents", -172)
    local hint = CreateLabel(right, "Drag to reorder, right-click to remove, shift-click to make first.",
        "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 0, -190)
    hint:SetPoint("RIGHT", right, "RIGHT")
    hint:SetWordWrap(false) -- a second line would run into the grid
    frame.gridHint = hint

    local grid = CreateFrame("Button", nil, right)
    grid:SetPoint("TOPLEFT", 0, -210)
    grid:SetSize(GRID_COLS * (SLOT + SLOT_GAP) + 2, 3 * (SLOT + SLOT_GAP) + 2)
    grid.bg = grid:CreateTexture(nil, "BACKGROUND")
    grid.bg:SetAllPoints()
    grid.bg:SetColorTexture(0, 0, 0, 0.3)
    AddBorder(grid, 1, 1, 1, 0.15)
    grid.dropText = CreateLabel(grid, "Drop here to add it", "GameFontNormalSmall")
    grid.dropText:SetPoint("TOPLEFT", hint, "TOPLEFT") -- replaces the hint while dragging
    grid.dropText:Hide()
    grid:SetScript("OnReceiveDrag", function() ns:ConfigDrop() end)
    grid:SetScript("OnMouseUp", function() ns:ConfigDrop() end)
    frame.grid = grid
    frame.slots = {}
    for i = 1, ns.MAX_ENTRIES do frame.slots[i] = CreateSlot(grid, i) end

    -- add by text
    local addBox = CreateEditBox(right, 180)
    addBox:SetPoint("TOPLEFT", 6, -354)
    AddPlaceholder(addBox, "Name, ID, or shift-click a link")
    frame.addBox = addBox
    local function Adder(kind)
        return function()
            local bar = SelectedBar()
            if not bar then return end
            local entry, err = ns:EntryFromText(kind, addBox:GetText())
            if entry then
                if ns:AddEntry(bar, entry) then addBox:SetText("") end
            else
                ns:Notify(err)
            end
        end
    end
    addBox:SetScript("OnEnterPressed", Adder("auto"))
    SetTooltip(addBox, "Add by name or ID",
        "Press Enter to add whatever matches first (spell, then item, then macro),",
        "or use a button to say which kind it is.")
    local addSpell = CreateButton(right, "Spell", 58)
    addSpell:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
    addSpell:SetScript("OnClick", Adder("spell"))
    local addItem = CreateButton(right, "Item", 58)
    addItem:SetPoint("LEFT", addSpell, "RIGHT", 4, 0)
    addItem:SetScript("OnClick", Adder("item"))
    local addMacro = CreateButton(right, "Macro", 58)
    addMacro:SetPoint("LEFT", addItem, "RIGHT", 4, 0)
    addMacro:SetScript("OnClick", Adder("macro"))

    -- feedback line
    frame.feedback = CreateLabel(right, "", "GameFontHighlightSmall")
    frame.feedback:SetPoint("TOPLEFT", 0, -382)
    frame.feedback:SetPoint("RIGHT", right, "RIGHT")
    frame.feedback:SetWordWrap(true)

    -- bottom buttons
    local pickup = CreateButton(right, "Pick Up Macro", 112)
    pickup:SetPoint("BOTTOMLEFT", 0, 4)
    pickup:SetScript("OnClick", Pickup)
    SetTooltip(pickup, "Pick Up Macro", "Puts the macro on your cursor. Click an action bar slot to place it.")
    local preview = CreateButton(right, "Show Popup", 96)
    ns.previewButton = preview
    frame.previewBtn = preview
    preview:SetPoint("LEFT", pickup, "RIGHT", 4, 0)
    preview:SetScript("OnClick", function()
        local bar = SelectedBar()
        if bar then ns:PreviewBar(bar) end
    end)
    SetTooltip(preview, "Show / Hide Popup",
        "Opens the popup next to the macro's action button, as if you'd clicked it.",
        "While this window is open, popups stay open, so you can see your changes on the bar as you make them.")
    local dup = CreateButton(right, "Duplicate", 80)
    dup:SetPoint("LEFT", preview, "RIGHT", 4, 0)
    dup:SetScript("OnClick", function()
        local bar = SelectedBar()
        local copy = bar and ns:DuplicateBar(bar)
        if copy then
            ns.selectedBarId = copy.id
            ns:RefreshConfig()
        end
    end)
    SetTooltip(dup, "Duplicate", "Creates a copy of this bar with the same contents and settings.")
    local delete = CreateButton(right, "Delete", 80)
    delete:SetPoint("BOTTOMRIGHT", 0, 4)
    delete:SetScript("OnClick", function()
        local bar = SelectedBar()
        if bar then StaticPopup_Show("FMD_DELETE_BAR", bar.name, nil, bar.id) end
    end)
    frame.editButtons = { renameBtn, addSpell, addItem, addMacro, pickup, preview, dup, delete, newBtn }

    -- cursor highlight for the grid
    local cursorWatcher = CreateFrame("Frame", nil, frame)
    pcall(cursorWatcher.RegisterEvent, cursorWatcher, "CURSOR_CHANGED")
    pcall(cursorWatcher.RegisterEvent, cursorWatcher, "CURSOR_UPDATE")
    cursorWatcher:SetScript("OnEvent", UpdateDropHint)

    return frame
end

StaticPopupDialogs["FMD_DELETE_BAR"] = {
    text = "Delete the popup bar \"%s\" and its macro?",
    button1 = DELETE or YES,
    button2 = CANCEL or NO,
    OnAccept = function(_, id)
        local bar = ns:GetBar(id)
        local name = bar and bar.name
        ns:DeleteBar(id)
        if name and not ns:GetBar(id) then ns:Notify("Deleted \"" .. name .. "\".", "info") end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

local STATUS_TEXT = {
    placed   = "|cff40ff40On your action bar.|r Click it to open the popup - it stays open while this window is open.",
    unplaced = "|cffffd040Not on a visible action bar.|r Drag the icon onto one.",
    missing  = "|cffff6040No macro on this character yet.|r Drag the icon onto an action bar to create it.",
}

function ns:RefreshConfig()
    if not frame or not frame:IsShown() then return end
    local bars = self.db.bars
    local inCombat = InCombatLockdown()

    if self.selectedBarId and not self:GetBar(self.selectedBarId) then self.selectedBarId = nil end
    if not self.selectedBarId and bars[1] then self.selectedBarId = bars[1].id end

    for i, bar in ipairs(bars) do
        local b = frame.listButtons[i] or CreateListButton(i)
        local sel = bar.id == self.selectedBarId
        b.barId = bar.id
        b.text:SetText(bar.name)
        b.sub:SetText(#bar.entries == 1 and "1 entry" or (#bar.entries .. " entries"))
        b.icon:SetTexture(self:BarIcon(bar))
        b.status:SetTexture(STATUS_INDICATOR[self:BarStatus(bar)])
        b.selected:SetShown(sel)
        b.selectedBar:SetShown(sel)
        b:Show()
    end
    for i = #bars + 1, #frame.listButtons do frame.listButtons[i]:Hide() end
    frame.listChild:SetHeight(math.max(1, #bars * ROW_H))
    frame.listEmpty:SetShown(#bars == 0)

    frame.combatText:SetShown(inCombat)
    frame.right:SetAlpha(inCombat and 0.5 or 1)
    for _, b in ipairs(frame.editButtons) do b:SetEnabled(not inCombat) end
    frame.minimapCheck:SetChecked(not self.db.minimap.hide)

    local bar = SelectedBar()
    frame.right:SetShown(bar ~= nil)
    frame.empty:SetShown(bar == nil)
    UpdateDropHint()
    if not bar then return end

    frame.macroBtn.icon:SetTexture(self:BarIcon(bar))
    frame.previewBtn:SetText(self:IsPopupShown(bar) and "Hide Popup" or "Show Popup")
    if not frame.nameBox:HasFocus() then frame.nameBox:SetText(bar.name) end
    for dir, b in pairs(frame.dirButtons) do b:SetSelected(dir == bar.direction) end
    frame.closeCheck:SetChecked(bar.closeOnUse)
    frame.bgCheck:SetChecked(bar.showBackground ~= false)
    frame.charCheck:SetChecked(bar.perCharacter)
    if not frame.hideBox:HasFocus() then frame.hideBox:SetText(tostring(bar.autoHide)) end
    if not frame.spacingBox:HasFocus() then frame.spacingBox:SetText(tostring(bar.spacing)) end
    if not frame.linesBox:HasFocus() then frame.linesBox:SetText(tostring(bar.lines or 1)) end
    frame.linesLabel:SetText((bar.direction == "LEFT" or bar.direction == "RIGHT") and "Rows" or "Columns")

    local n = #bar.entries
    frame.contentsHeader:SetText(("Contents  |cff808080%d / %d|r"):format(n, self.MAX_ENTRIES))
    for i, s in ipairs(frame.slots) do
        local e = bar.entries[i]
        if e then
            local _, icon = self:EntryInfo(e)
            s.icon:SetTexture(icon)
            s.icon:SetAlpha((ghost and ghost:IsShown() and ghost.from == i) and 0.3 or 1)
            s.icon:Show()
            s.num:SetText(i)
        else
            s.icon:Hide()
            s.num:SetText("")
        end
        s.plus:SetShown(i == n + 1)
        if i == 1 and e then SetBorderColor(s, 1, 0.82, 0, 1) else SetBorderColor(s, 0, 0, 0, 0) end
    end

    local status, idx = self:BarStatus(bar)
    local scope = idx and (self.IsCharacterMacro(idx) and "Character macro. " or "Account-wide macro. ") or ""
    frame.status:SetText(scope .. STATUS_TEXT[status])
end

function ns:ToggleConfig()
    self:CreateConfig()
    if frame:IsShown() then frame:Hide() else self:OpenConfig() end
end

---------------------------------------------------------------------------
-- Docking to Blizzard's macro window (/macro)
-- While the macro window is open, the editor sits against its right edge and opens/closes with it.
---------------------------------------------------------------------------

local function MacroWindow()
    local mf = _G.MacroFrame
    return mf and mf:IsShown() and mf or nil
end

-- Attach to the macro window if it is open (and docking is enabled), otherwise use the saved position.
function ns:ApplyDock()
    if not frame then return end
    local mf = self.db.dockToMacro ~= false and MacroWindow()
    frame.docked = mf and true or false
    frame:StopMovingOrSizing()
    if mf then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", mf, "TOPRIGHT", 2, 0)
    else
        RestorePosition()
    end
end

-- Select the bar whose macro is selected in the macro window.
local function SyncSelectionFromMacroWindow()
    if not frame or not frame:IsShown() then return end
    local fs = _G.MacroFrameSelectedMacroName
    local name = fs and fs:GetText()
    if not name then return end
    for _, bar in ipairs(ns.db.bars) do
        if bar.name == name then
            ns.selectedBarId = bar.id
            ns:RefreshConfig()
            return
        end
    end
end

local function HookMacroWindow()
    local mf = _G.MacroFrame
    if not mf or mf.fmdHooked then return end
    mf.fmdHooked = true

    mf:HookScript("OnShow", function()
        if ns.db.dockToMacro == false then return end
        ns:CreateConfig()
        if frame:IsShown() then
            frame.openedByDock = false
            ns:ApplyDock()
        else
            frame.openedByDock = true
            frame:Show()
        end
        SyncSelectionFromMacroWindow()
    end)
    mf:HookScript("OnHide", function()
        ns.openedMacroWindow = false
        if not frame or not frame:IsShown() or not frame.docked then return end
        if frame.openedByDock then
            frame:Hide()
        else
            ns:ApplyDock() -- was open before /macro: go back to its own position
        end
    end)

    if mf.SelectMacro then
        hooksecurefunc(mf, "SelectMacro", SyncSelectionFromMacroWindow)
    elseif _G.MacroFrame_SelectMacro then
        hooksecurefunc("MacroFrame_SelectMacro", SyncSelectionFromMacroWindow)
    end

    -- addon icon in the macro window's title bar: show / hide the docked editor
    local b = CreateFrame("Button", "ForeverMacroDropdownMacroWindowButton", mf)
    b:SetSize(18, 18)
    b:SetFrameLevel(mf:GetFrameLevel() + 10)
    local close = mf.CloseButton or _G.MacroFrameCloseButton
    if close then b:SetPoint("RIGHT", close, "LEFT", -2, 0) else b:SetPoint("TOPRIGHT", -28, -3) end
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexture(ns.ADDON_ICON)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", function()
        ns:CreateConfig()
        if frame:IsShown() then
            frame:Hide()
        else
            frame.openedByDock = true
            frame:Show()
            SyncSelectionFromMacroWindow()
        end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.TITLE, 1, 1, 1)
        GameTooltip:AddLine("Show or hide the popup bar editor next to this window.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
end

-- Blizzard_MacroUI is load-on-demand: hook it whenever it shows up.
local macroWatcher = CreateFrame("Frame")
macroWatcher:RegisterEvent("ADDON_LOADED")
macroWatcher:RegisterEvent("PLAYER_LOGIN")
macroWatcher:SetScript("OnEvent", function(self)
    if _G.MacroFrame then
        HookMacroWindow()
        self:UnregisterAllEvents()
    end
end)

function ns:SetDockToMacro(on)
    self.db.dockToMacro = on and true or false
    if frame and frame:IsShown() then self:ApplyDock() end
end

-- Blizzard_MacroUI is load-on-demand; load it so the macro window can be opened with the editor.
local function LoadMacroWindow()
    if not _G.MacroFrame then
        if UIParentLoadAddOn then
            pcall(UIParentLoadAddOn, "Blizzard_MacroUI")
        else
            local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
            if load then pcall(load, "Blizzard_MacroUI") end
        end
    end
    HookMacroWindow()
    return _G.MacroFrame
end

-- Open the editor. By default it opens together with the macro window, docked to its right edge.
-- In combat, or with docking turned off, it opens on its own.
function ns:OpenConfig()
    self:CreateConfig()
    local mf = self.db.dockToMacro ~= false and not InCombatLockdown() and LoadMacroWindow()
    if mf and not mf:IsShown() then
        ShowUIPanel(mf) -- the macro window's OnShow hook shows the docked editor
        if mf:IsShown() then self.openedMacroWindow = true end
    end
    if not frame:IsShown() then
        frame.openedByDock = mf and mf:IsShown() or false
        frame:Show()
    end
    self:ApplyDock()
    frame:Raise()
end

---------------------------------------------------------------------------
-- Shift-click links into the "add" box
---------------------------------------------------------------------------

local function OnInsertLink(link)
    if frame and frame.addBox and frame.addBox:HasFocus() and type(link) == "string" then
        frame.addBox:Insert(link)
    end
end

if ChatFrameUtil and ChatFrameUtil.InsertLink then
    hooksecurefunc(ChatFrameUtil, "InsertLink", OnInsertLink)
elseif ChatEdit_InsertLink then
    hooksecurefunc("ChatEdit_InsertLink", OnInsertLink)
end
