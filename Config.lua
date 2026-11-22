-- ForeverMacroDropdown - Config window (/fmd)

local ADDON, ns = ...

local frame

local function SelectedBar()
    return ns.selectedBarId and ns:GetBar(ns.selectedBarId)
end

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

local function CreateEditBox(parent, width, numeric)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    if numeric then
        e:SetNumeric(true)
        e:SetMaxLetters(3)
    end
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return e
end

---------------------------------------------------------------------------
-- Drag & drop
---------------------------------------------------------------------------

function ns:ConfigDrop(index)
    local bar = SelectedBar()
    if not bar or not GetCursorInfo() then return end
    local entry, err = self:EntryFromCursor()
    if entry then
        if self:AddEntry(bar, entry, index) then ClearCursor() end
    elseif err then
        self:Print(err)
    end
end

---------------------------------------------------------------------------
-- Bar list
---------------------------------------------------------------------------

local function CreateListButton(i)
    local b = CreateFrame("Button", nil, frame.listChild)
    b:SetSize(146, 20)
    b:SetPoint("TOPLEFT", 0, -(i - 1) * 22)

    b.selected = b:CreateTexture(nil, "BACKGROUND")
    b.selected:SetAllPoints()
    b.selected:SetColorTexture(0.2, 0.5, 1, 0.35)

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.text:SetPoint("LEFT", 6, 0)
    b.text:SetPoint("RIGHT", -4, 0)
    b.text:SetJustifyH("LEFT")

    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
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
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.text:GetText())
        GameTooltip:AddLine("Drag onto an action bar to place the macro.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    frame.listButtons[i] = b
    return b
end

---------------------------------------------------------------------------
-- Entry grid slot
---------------------------------------------------------------------------

local GRID_COLS, SLOT, SLOT_GAP = 8, 36, 4

local function CreateSlot(parent, i)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(SLOT, SLOT)
    local col, row = (i - 1) % GRID_COLS, math.floor((i - 1) / GRID_COLS)
    s:SetPoint("TOPLEFT", 3 + col * (SLOT + SLOT_GAP), -(3 + row * (SLOT + SLOT_GAP)))

    s.bg = s:CreateTexture(nil, "BACKGROUND")
    s.bg:SetAllPoints()
    s.bg:SetColorTexture(1, 1, 1, 0.07)

    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.icon:SetAllPoints()
    s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    s.num = s:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    s.num:SetPoint("TOPLEFT", 2, -2)

    s:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    s.index = i
    s:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    s:SetScript("OnReceiveDrag", function(self) ns:ConfigDrop(self.index) end)
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
            ns:MoveEntry(bar, self.index, 1)
        else
            ns:MoveEntry(bar, self.index, -1)
        end
    end)
    s:SetScript("OnEnter", function(self)
        local bar = SelectedBar()
        local e = bar and bar.entries[self.index]
        if not e then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        ns:SetEntryTooltip(GameTooltip, e)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: move earlier", 0.5, 0.8, 1)
        GameTooltip:AddLine("Shift-click: move later", 0.5, 0.8, 1)
        GameTooltip:AddLine("Right-click: remove", 0.5, 0.8, 1)
        GameTooltip:Show()
    end)
    s:SetScript("OnLeave", GameTooltip_Hide)
    return s
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

function ns:CreateConfig()
    if frame then return frame end

    frame = CreateFrame("Frame", "ForeverMacroDropdownConfig", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 450)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function() ns:RefreshConfig() end)
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName()) -- close with Escape

    if frame.TitleText then
        frame.TitleText:SetText("Forever Macro Dropdown")
    else
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
        title:SetText("Forever Macro Dropdown")
    end

    -------------------------------------------------------------- left side
    CreateLabel(frame, "Bars"):SetPoint("TOPLEFT", 16, -32)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -50)
    scroll:SetSize(150, 300)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(150, 1)
    scroll:SetScrollChild(child)
    frame.listChild = child
    frame.listButtons = {}

    CreateLabel(frame, "New bar (max " .. ns.MAX_NAME .. " chars):", "GameFontNormalSmall"):SetPoint("TOPLEFT", 16, -362)
    local newBox = CreateEditBox(frame, 112)
    newBox:SetPoint("TOPLEFT", 22, -378)
    newBox:SetMaxLetters(ns.MAX_NAME)
    local newBtn = CreateButton(frame, "Create", 60)
    newBtn:SetPoint("LEFT", newBox, "RIGHT", 6, 0)
    local function DoCreate()
        local bar = ns:CreateBar(newBox:GetText())
        if bar then
            newBox:SetText("")
            newBox:ClearFocus()
            ns.selectedBarId = bar.id
            ns:RefreshConfig()
        end
    end
    newBtn:SetScript("OnClick", DoCreate)
    newBox:SetScript("OnEnterPressed", DoCreate)

    -------------------------------------------------------------- right side
    local right = CreateFrame("Frame", nil, frame)
    right:SetPoint("TOPLEFT", 200, -28)
    right:SetPoint("BOTTOMRIGHT", -12, 10)
    frame.right = right

    frame.emptyText = CreateLabel(frame, "Create a bar on the left to get started.", "GameFontDisable")
    frame.emptyText:SetPoint("CENTER", right, "CENTER")

    -- name
    local nameLabel = CreateLabel(right, "Name:")
    nameLabel:SetPoint("TOPLEFT", 0, -8)
    local nameBox = CreateEditBox(right, 130)
    nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 12, 0)
    nameBox:SetMaxLetters(ns.MAX_NAME)
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

    -- direction / orientation
    frame.dirButtons = {}
    local function DirButton(dir, text, anchorTo, x)
        local b = CreateButton(right, text, 48)
        b:SetPoint("LEFT", anchorTo, "RIGHT", x, 0)
        b:SetScript("OnClick", function()
            local bar = SelectedBar()
            if bar and ns:CheckCombat() then
                bar.direction = dir
                ns:OnBarChanged(bar)
            end
        end)
        frame.dirButtons[dir] = b
        return b
    end
    local vLabel = CreateLabel(right, "Vertical:")
    vLabel:SetPoint("TOPLEFT", 0, -40)
    local up = DirButton("UP", "Up", vLabel, 8)
    local down = DirButton("DOWN", "Down", up, 4)
    local hLabel = CreateLabel(right, "Horizontal:")
    hLabel:SetPoint("LEFT", down, "RIGHT", 14, 0)
    local rightBtn = DirButton("RIGHT", "Right", hLabel, 8)
    DirButton("LEFT", "Left", rightBtn, 4)

    -- options
    local closeCheck = CreateFrame("CheckButton", nil, right, "UICheckButtonTemplate")
    closeCheck:SetSize(24, 24)
    closeCheck:SetPoint("TOPLEFT", -4, -66)
    frame.closeCheck = closeCheck
    local closeLabel = CreateLabel(right, "Close after use", "GameFontHighlight")
    closeLabel:SetPoint("LEFT", closeCheck, "RIGHT", 2, 0)
    closeCheck:SetScript("OnClick", function(self)
        local bar = SelectedBar()
        if bar and ns:CheckCombat() then
            bar.closeOnUse = self:GetChecked() and true or false
            ns:OnBarChanged(bar)
        else
            ns:RefreshConfig()
        end
    end)

    local function NumberOption(label, anchorTo, key, min, max, tooltip)
        local l = CreateLabel(right, label, "GameFontHighlight")
        l:SetPoint("LEFT", anchorTo, "RIGHT", 16, 0)
        local box = CreateEditBox(right, 32, true)
        box:SetPoint("LEFT", l, "RIGHT", 8, 0)
        box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        box:HookScript("OnEditFocusLost", function(self)
            local bar = SelectedBar()
            if not bar then return end
            local v = tonumber(self:GetText())
            if v and not InCombatLockdown() then
                v = math.max(min, math.min(max, math.floor(v)))
                if v ~= bar[key] then
                    bar[key] = v
                    ns:OnBarChanged(bar)
                end
            end
            self:SetText(tostring(bar[key]))
        end)
        box:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", GameTooltip_Hide)
        return box
    end
    frame.hideBox = NumberOption("Auto-hide:", closeLabel, "autoHide", 0, 30,
        "Seconds the mouse can be away from the popup before it closes. 0 = stay open until toggled.")

    local charCheck = CreateFrame("CheckButton", nil, right, "UICheckButtonTemplate")
    charCheck:SetSize(24, 24)
    charCheck:SetPoint("LEFT", frame.hideBox, "RIGHT", 14, 0)
    frame.charCheck = charCheck
    CreateLabel(right, "Character only", "GameFontHighlight"):SetPoint("LEFT", charCheck, "RIGHT", 2, 0)
    charCheck:SetScript("OnClick", function(self)
        local bar = SelectedBar()
        if bar then ns:SetBarScope(bar, self:GetChecked()) end
        ns:RefreshConfig()
    end)
    charCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Character-specific macro", 1, 1, 1)
        GameTooltip:AddLine("Checked: the macro goes in this character's macros.", nil, nil, nil, true)
        GameTooltip:AddLine("Unchecked: it goes in the account-wide (General) macros.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    charCheck:SetScript("OnLeave", GameTooltip_Hide)

    -- entries grid
    CreateLabel(right, "Popup contents"):SetPoint("TOPLEFT", 0, -104)
    local hint = CreateLabel(right,
        "Drag spells, items, toys, mounts or macros into the grid. The first entry is the macro's icon.",
        "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 0, -120)
    hint:SetWidth(380)

    local grid = CreateFrame("Button", nil, right)
    grid:SetPoint("TOPLEFT", 0, -148)
    grid:SetSize(GRID_COLS * (SLOT + SLOT_GAP) + 2, 3 * (SLOT + SLOT_GAP) + 2)
    grid.bg = grid:CreateTexture(nil, "BACKGROUND")
    grid.bg:SetAllPoints()
    grid.bg:SetColorTexture(0, 0, 0, 0.3)
    grid:SetScript("OnReceiveDrag", function() ns:ConfigDrop() end)
    grid:SetScript("OnMouseUp", function() ns:ConfigDrop() end)
    frame.slots = {}
    for i = 1, ns.MAX_ENTRIES do frame.slots[i] = CreateSlot(grid, i) end

    -- add by text
    CreateLabel(right, "Or add by name, ID, or shift-clicked link:", "GameFontHighlightSmall"):SetPoint("TOPLEFT", 0, -278)
    local addBox = CreateEditBox(right, 170)
    addBox:SetPoint("TOPLEFT", 6, -294)
    frame.addBox = addBox
    local function Adder(kind)
        return function()
            local bar = SelectedBar()
            if not bar then return end
            local entry, err = ns:EntryFromText(kind, addBox:GetText())
            if entry then
                if ns:AddEntry(bar, entry) then addBox:SetText("") end
            else
                ns:Print(err)
            end
        end
    end
    addBox:SetScript("OnEnterPressed", Adder("auto"))
    local addSpell = CreateButton(right, "Spell", 56)
    addSpell:SetPoint("LEFT", addBox, "RIGHT", 8, 0)
    addSpell:SetScript("OnClick", Adder("spell"))
    local addItem = CreateButton(right, "Item", 56)
    addItem:SetPoint("LEFT", addSpell, "RIGHT", 4, 0)
    addItem:SetScript("OnClick", Adder("item"))
    local addMacro = CreateButton(right, "Macro", 56)
    addMacro:SetPoint("LEFT", addItem, "RIGHT", 4, 0)
    addMacro:SetScript("OnClick", Adder("macro"))

    -- status
    frame.status = CreateLabel(right, "", "GameFontHighlightSmall")
    frame.status:SetPoint("TOPLEFT", 0, -328)
    frame.status:SetWidth(380)

    -- bottom buttons
    local pickup = CreateButton(right, "Put Macro on Cursor", 150)
    pickup:SetPoint("BOTTOMLEFT", 0, 4)
    pickup:SetScript("OnClick", function()
        local bar = SelectedBar()
        if bar then ns:PickupBarMacro(bar) end
    end)
    local preview = CreateButton(right, "Preview", 80)
    ns.previewButton = preview
    preview:SetPoint("LEFT", pickup, "RIGHT", 6, 0)
    preview:SetScript("OnClick", function()
        local bar = SelectedBar()
        if bar then ns:PreviewBar(bar) end
    end)
    local delete = CreateButton(right, "Delete Bar", 90)
    delete:SetPoint("BOTTOMRIGHT", 0, 4)
    delete:SetScript("OnClick", function()
        local bar = SelectedBar()
        if bar then StaticPopup_Show("FMD_DELETE_BAR", bar.name, nil, bar.id) end
    end)

    return frame
end

StaticPopupDialogs["FMD_DELETE_BAR"] = {
    text = "Delete the popup bar \"%s\" and its macro?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, id) ns:DeleteBar(id) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

function ns:RefreshConfig()
    if not frame or not frame:IsShown() then return end
    local bars = self.db.bars

    if self.selectedBarId and not self:GetBar(self.selectedBarId) then self.selectedBarId = nil end
    if not self.selectedBarId and bars[1] then self.selectedBarId = bars[1].id end

    for i, bar in ipairs(bars) do
        local b = frame.listButtons[i] or CreateListButton(i)
        b.barId = bar.id
        b.text:SetText(bar.name)
        b.selected:SetShown(bar.id == self.selectedBarId)
        b:Show()
    end
    for i = #bars + 1, #frame.listButtons do frame.listButtons[i]:Hide() end
    frame.listChild:SetHeight(math.max(1, #bars * 22))

    local bar = SelectedBar()
    frame.right:SetShown(bar ~= nil)
    frame.emptyText:SetShown(bar == nil)
    if not bar then return end

    if not frame.nameBox:HasFocus() then frame.nameBox:SetText(bar.name) end
    for dir, b in pairs(frame.dirButtons) do
        if dir == bar.direction then b:LockHighlight() else b:UnlockHighlight() end
    end
    frame.closeCheck:SetChecked(bar.closeOnUse)
    frame.charCheck:SetChecked(bar.perCharacter)
    if not frame.hideBox:HasFocus() then frame.hideBox:SetText(tostring(bar.autoHide)) end

    for i, s in ipairs(frame.slots) do
        local e = bar.entries[i]
        if e then
            local _, icon = self:EntryInfo(e)
            s.icon:SetTexture(icon)
            s.icon:Show()
            s.num:SetText(i)
        else
            s.icon:Hide()
            s.num:SetText("")
        end
    end

    local idx = GetMacroIndexByName(bar.name)
    if not idx or idx == 0 then
        frame.status:SetText("|cffff8040Macro missing" .. (bar.perCharacter and " on this character" or "") ..
            ".|r Click \"Put Macro on Cursor\" to create it.")
    else
        local scope = self.IsCharacterMacro(idx) and "character" or "general"
        if self:IsBarOnActionBar(bar) then
            frame.status:SetText("|cff40ff40Macro \"" .. bar.name .. "\" (" .. scope .. ") is on your action bar.|r The popup opens next to it.")
        else
            frame.status:SetText("|cffffd040Macro \"" .. bar.name .. "\" (" .. scope .. ") is not on a visible action bar.|r Drag it there (or drag the bar name on the left).")
        end
    end
end

function ns:ToggleConfig()
    self:CreateConfig()
    frame:SetShown(not frame:IsShown())
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
