-- ForeverMacroDropdown - Core
-- Saved data, bar/entry management, macro creation and slash commands.

local ADDON, ns = ...
_G.ForeverMacroDropdown = ns

ns.QUESTION_ICON = 134400 -- INV_Misc_QuestionMark
ns.ADDON_ICON = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Icon"
ns.TITLE = "Forever Macro Dropdown"
local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata or function() end
ns.VERSION = GetMetadata(ADDON, "Version") or ""
ns.AUTHOR = GetMetadata(ADDON, "Author") or "saestad"
ns.WEBSITE = GetMetadata(ADDON, "X-Website") or "https://github.com/saestad/ForeverMacroDropdown"
ns.MAX_ENTRIES = 24
ns.MAX_NAME = 16 -- WoW macro name limit

local DEFAULTS = {
    direction = "UP", -- UP / DOWN = vertical, RIGHT / LEFT = horizontal
    spacing = 4,
    lines = 1, -- columns (vertical popups) or rows (horizontal popups)
    closeOnUse = true,
    autoHide = 3, -- seconds the mouse may be away before the popup closes; 0 = never
    perCharacter = false, -- create the macro under the character's macros instead of the account-wide ones
    showBackground = true, -- dark backdrop and border behind the popup's buttons
}
ns.DEFAULTS = DEFAULTS

local MAX_ACTION_SLOTS = 180
local GetActionInfo = GetActionInfo or (C_ActionBar and C_ActionBar.GetActionInfo)
local GetActionText = GetActionText or (C_ActionBar and C_ActionBar.GetActionText)

local function IsCharacterMacro(index)
    return index > (MAX_ACCOUNT_MACROS or 120)
end
ns.IsCharacterMacro = IsCharacterMacro

local function HasRoomForMacro(perCharacter)
    local numAccount, numCharacter = GetNumMacros()
    if perCharacter then
        return numCharacter < (MAX_CHARACTER_MACROS or 18), "character"
    end
    return numAccount < (MAX_ACCOUNT_MACROS or 120), "account-wide"
end

---------------------------------------------------------------------------
-- API compatibility helpers
---------------------------------------------------------------------------

local function GetSpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    return GetSpellInfo and (GetSpellInfo(id))
end

local function GetSpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    return GetSpellTexture and GetSpellTexture(id)
end

local function LookupSpellID(nameOrID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(nameOrID)
        return info and info.spellID
    end
    if GetSpellInfo then return select(7, GetSpellInfo(nameOrID)) end
end

local function LookupItemID(nameOrID)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    return f and (f(nameOrID))
end

local function GetItemName(id)
    if C_Item and C_Item.GetItemNameByID then return C_Item.GetItemNameByID(id) end
    return GetItemInfo and (GetItemInfo(id))
end

local function GetItemIcon(id)
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
    return _G.GetItemIcon and _G.GetItemIcon(id)
end

ns.GetSpellName = GetSpellName

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------

function ns:Print(...)
    print("|cff33ccffForeverMacroDropdown:|r", ...)
end

-- User-facing feedback. Shown inline in the config window when it is open, otherwise printed to chat.
-- level: "error" (default), "ok" or "info"
function ns:Notify(msg, level)
    if not msg then return end
    if self.ShowConfigFeedback and self:ShowConfigFeedback(msg, level or "error") then return end
    self:Print(msg)
end

function ns:CheckCombat()
    if InCombatLockdown() then
        self:Notify("Bars can't be changed in combat.")
        return false
    end
    return true
end

function ns.ToggleName(bar)
    return "FMDToggle" .. bar.id
end

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------

function ns:InitDB()
    local db = ForeverMacroDropdownDB or {}
    ForeverMacroDropdownDB = db
    db.bars = db.bars or {}
    db.nextId = db.nextId or 1
    db.minimap = db.minimap or {} -- LibDBIcon-compatible: { hide = bool, minimapPos = degrees }
    if db.minimap.minimapPos == nil then db.minimap.minimapPos = 200 end
    for _, bar in ipairs(db.bars) do
        for k, v in pairs(DEFAULTS) do
            if bar[k] == nil then bar[k] = v end
        end
        bar.entries = bar.entries or {}
        if bar.id >= db.nextId then db.nextId = bar.id + 1 end
    end
    self.db = db
end

function ns:GetBar(id)
    for _, bar in ipairs(self.db.bars) do
        if bar.id == id then return bar end
    end
end

---------------------------------------------------------------------------
-- Entries
---------------------------------------------------------------------------
-- An entry is one of:
--   { type = "spell", id = spellID }
--   { type = "item",  id = itemID }
--   { type = "toy",   id = itemID }
--   { type = "macro", name = macroName }

function ns:EntryInfo(e)
    if e.type == "spell" then
        return GetSpellName(e.id) or ("Spell #" .. e.id), GetSpellIcon(e.id) or self.QUESTION_ICON
    elseif e.type == "item" or e.type == "toy" then
        return GetItemName(e.id) or ("Item #" .. e.id), GetItemIcon(e.id) or self.QUESTION_ICON
    elseif e.type == "macro" then
        local _, icon = GetMacroInfo(e.name)
        return e.name, icon or self.QUESTION_ICON
    end
    return "?", self.QUESTION_ICON
end

function ns:SetEntryTooltip(tt, e)
    if e.type == "spell" then
        tt:SetSpellByID(e.id)
    elseif e.type == "toy" and tt.SetToyByItemID then
        tt:SetToyByItemID(e.id)
    elseif e.type == "item" or e.type == "toy" then
        tt:SetItemByID(e.id)
    elseif e.type == "macro" then
        tt:SetText(e.name)
        local _, _, body = GetMacroInfo(e.name)
        if body then tt:AddLine(body, 1, 1, 1, true) else tt:AddLine("Macro not found", 1, 0.2, 0.2) end
        tt:Show()
    end
end

local function SameEntry(a, b)
    return a.type == b.type and a.id == b.id and a.name == b.name
end

function ns:ItemEntry(itemID)
    if PlayerHasToy and PlayerHasToy(itemID) then
        return { type = "toy", id = itemID }
    end
    return { type = "item", id = itemID }
end

-- Build an entry from whatever is on the cursor (spellbook, bags, toy box, mount journal, macro UI).
function ns:EntryFromCursor()
    local kind, a, b, c, d = GetCursorInfo()
    if kind == "spell" then
        -- Retail: "spell", slotIndex, bookType, spellID, baseSpellID
        local id = c or d
        if type(id) == "number" then return { type = "spell", id = id } end
    elseif kind == "item" then
        if type(a) == "number" then return self:ItemEntry(a) end
    elseif kind == "mount" then
        local spellID
        if C_MountJournal then
            if C_MountJournal.GetMountInfoByID then spellID = select(2, C_MountJournal.GetMountInfoByID(a)) end
            if not spellID and C_MountJournal.GetDisplayedMountInfo and b then
                spellID = select(2, C_MountJournal.GetDisplayedMountInfo(b))
            end
        end
        if spellID then return { type = "spell", id = spellID } end
    elseif kind == "companion" then
        -- older clients: "companion", index, "MOUNT" | "CRITTER"
        if GetCompanionInfo and (b == "MOUNT" or b == "CRITTER") then
            local spellID = select(3, GetCompanionInfo(b, a))
            if spellID then return { type = "spell", id = spellID } end
        end
    elseif kind == "macro" then
        local name = GetMacroInfo(a)
        if name then return { type = "macro", name = name } end
    end
    return nil, kind and ("Can't add that (" .. tostring(kind) .. ").") or nil
end

-- kind: "spell", "item", "macro" or "auto" (tries spell, then item, then macro)
function ns:EntryFromText(kind, text)
    text = strtrim(text or "")
    if text == "" then return nil, "Type a name, ID or link first." end

    local spellLink = text:match("|Hspell:(%d+)")
    local itemLink = text:match("|Hitem:(%d+)") or text:match("^item:(%d+)$")

    if kind == "auto" then
        if spellLink then kind = "spell" elseif itemLink then kind = "item" end
    end

    if kind == "spell" or kind == "auto" then
        local id = tonumber(spellLink or text) or LookupSpellID(text)
        if id and GetSpellName(id) then return { type = "spell", id = id } end
        if kind == "spell" then return nil, "Unknown spell: " .. text end
    end
    if kind == "item" or kind == "auto" then
        local id = tonumber(itemLink or text)
        id = id and LookupItemID(id) or LookupItemID(text)
        if id then return self:ItemEntry(id) end
        if kind == "item" then
            return nil, "Unknown item: " .. text .. " (items must be cached - try the item ID, a link, or drag it in)"
        end
    end
    if kind == "macro" or kind == "auto" then
        local idx = GetMacroIndexByName(text)
        if idx and idx > 0 then return { type = "macro", name = (GetMacroInfo(idx)) } end
        if kind == "macro" then return nil, "No macro named " .. text end
    end
    return nil, "Couldn't find a spell, item or macro called " .. text
end

function ns:AddEntry(bar, entry, pos)
    if not self:CheckCombat() then return end
    if #bar.entries >= self.MAX_ENTRIES then
        self:Notify("A bar can hold at most " .. self.MAX_ENTRIES .. " entries.")
        return
    end
    for _, e in ipairs(bar.entries) do
        if SameEntry(e, entry) then
            self:Notify((self:EntryInfo(entry)) .. " is already on the bar.")
            return
        end
    end
    if not pos or pos > #bar.entries + 1 then pos = #bar.entries + 1 end
    tinsert(bar.entries, pos, entry)
    self:OnBarChanged(bar)
    self:Notify("Added " .. (self:EntryInfo(entry)) .. ".", "ok")
    return true
end

-- Move an entry to a new position (used by drag-to-reorder in the grid).
function ns:MoveEntryTo(bar, from, to)
    if not self:CheckCombat() then return end
    local n = #bar.entries
    if not bar.entries[from] then return end
    to = math.max(1, math.min(n, to))
    if to == from then return end
    local e = tremove(bar.entries, from)
    tinsert(bar.entries, to, e)
    self:OnBarChanged(bar)
    return true
end

function ns:RemoveEntry(bar, index)
    if not self:CheckCombat() then return end
    local e = bar.entries[index]
    if e then
        tremove(bar.entries, index)
        self:OnBarChanged(bar)
        self:Notify("Removed " .. (self:EntryInfo(e)) .. ".", "info")
    end
end

function ns:MoveEntry(bar, index, delta)
    if not self:CheckCombat() then return end
    local j = index + delta
    if not bar.entries[index] or j < 1 or j > #bar.entries then return end
    bar.entries[index], bar.entries[j] = bar.entries[j], bar.entries[index]
    self:OnBarChanged(bar)
end

function ns:OnBarChanged(bar)
    self:BuildBar(bar)
    self:SyncMacro(bar, false)
    self:RefreshConfig()
end

---------------------------------------------------------------------------
-- Bars
---------------------------------------------------------------------------

function ns:IsOurMacro(index, bar)
    local _, _, body = GetMacroInfo(index)
    if not body then return false end
    if bar then return body:find("/click " .. self.ToggleName(bar), 1, true) ~= nil end
    return body:find("/click FMDToggle%d") ~= nil
end

function ns:ValidateName(name, ignoreBar)
    name = strtrim(name or "")
    if name == "" then return nil, "Enter a name for the bar." end
    if #name > self.MAX_NAME then return nil, "Names can be at most " .. self.MAX_NAME .. " characters (macro name limit)." end
    for _, b in ipairs(self.db.bars) do
        if b ~= ignoreBar and b.name:lower() == name:lower() then
            return nil, "A bar named \"" .. b.name .. "\" already exists."
        end
    end
    local idx = GetMacroIndexByName(name)
    if idx and idx > 0 and not self:IsOurMacro(idx) then
        return nil, "You already have a macro named \"" .. name .. "\". Pick another name."
    end
    return name
end

function ns:CreateBar(name)
    if not self:CheckCombat() then return end
    local valid, err = self:ValidateName(name)
    if not valid then self:Notify(err) return end

    local bar = { id = self.db.nextId, name = valid, entries = {} }
    for k, v in pairs(DEFAULTS) do bar[k] = v end
    self.db.nextId = self.db.nextId + 1
    tinsert(self.db.bars, bar)

    self:BuildBar(bar)
    self:SyncMacro(bar, true)
    self:RefreshConfig()
    return bar
end

-- Copy a bar (entries and settings) under a free name like "Name 2".
function ns:DuplicateBar(src)
    if not self:CheckCombat() then return end
    local name
    for n = 2, 99 do
        local suffix = " " .. n
        local candidate = strtrim(src.name:sub(1, self.MAX_NAME - #suffix)) .. suffix
        if self:ValidateName(candidate) then name = candidate break end
    end
    if not name then self:Notify("Couldn't find a free name for the copy.") return end

    local bar = { id = self.db.nextId, name = name, entries = {} }
    self.db.nextId = self.db.nextId + 1
    for k in pairs(DEFAULTS) do bar[k] = src[k] end
    for i, e in ipairs(src.entries) do bar.entries[i] = { type = e.type, id = e.id, name = e.name } end
    tinsert(self.db.bars, bar)

    self:BuildBar(bar)
    self:SyncMacro(bar, true)
    self:Notify("Created \"" .. name .. "\" as a copy of \"" .. src.name .. "\".", "ok")
    self:RefreshConfig()
    return bar
end

function ns:RenameBar(bar, newName)
    if not self:CheckCombat() then return end
    local name, err = self:ValidateName(newName, bar)
    if not name then self:Notify(err) return end
    if name == bar.name then return true end

    local idx = GetMacroIndexByName(bar.name)
    bar.name = name
    if idx and idx > 0 and self:IsOurMacro(idx, bar) then
        EditMacro(idx, name, self:MacroIcon(bar), self:MacroBody(bar))
    end
    self:Notify("Renamed to \"" .. name .. "\".", "ok")
    self:RequestScan()
    self:RefreshConfig()
    return true
end

-- Icon shown for a bar in lists: the first entry's icon.
function ns:BarIcon(bar)
    local first = bar.entries[1]
    if first then return select(2, self:EntryInfo(first)) end
    return self.QUESTION_ICON
end

-- "missing" (no macro on this character), "unplaced" (macro exists, not on a visible bar) or "placed".
-- Second return: the macro index, if any.
function ns:BarStatus(bar)
    local idx = GetMacroIndexByName(bar.name)
    if not idx or idx == 0 then return "missing" end
    if self:IsBarOnActionBar(bar) then return "placed", idx end
    return "unplaced", idx
end

function ns:DeleteBar(id)
    if not self:CheckCombat() then return end
    for i, bar in ipairs(self.db.bars) do
        if bar.id == id then
            local idx = GetMacroIndexByName(bar.name)
            if idx and idx > 0 and self:IsOurMacro(idx, bar) then DeleteMacro(idx) end
            tremove(self.db.bars, i)
            self:ReleaseBar(id)
            break
        end
    end
    if self.selectedBarId == id then self.selectedBarId = nil end
    self:RefreshConfig()
end

---------------------------------------------------------------------------
-- Macros
---------------------------------------------------------------------------

-- The macro shows the first entry's icon/cooldown via #showtooltip and clicks the bar's secure toggle.
function ns:MacroBody(bar)
    local first, tip = bar.entries[1], nil
    if first then
        if first.type == "spell" then
            tip = GetSpellName(first.id)
        elseif first.type == "item" or first.type == "toy" then
            tip = "item:" .. first.id
        end
    end
    local body = "/click " .. self.ToggleName(bar)
    if tip then body = "#showtooltip " .. tip .. "\n" .. body end
    return body
end

function ns:MacroIcon(bar)
    local first = bar.entries[1]
    if first and first.type == "macro" then
        local _, icon = GetMacroInfo(first.name)
        if icon then return icon end
    end
    return self.QUESTION_ICON
end

-- Creates (if create is true) or updates the bar's macro. Returns the macro index.
function ns:SyncMacro(bar, create)
    if InCombatLockdown() then self.pendingRefresh = true return end
    local body = self:MacroBody(bar)
    local idx = GetMacroIndexByName(bar.name)
    if idx and idx > 0 then
        if not self:IsOurMacro(idx) then
            self:Notify("A macro named \"" .. bar.name .. "\" exists but wasn't made by this addon; leaving it alone.")
            return
        end
        local _, _, current = GetMacroInfo(idx)
        if strtrim(current or "") ~= body then
            idx = EditMacro(idx, bar.name, self:MacroIcon(bar), body) or idx
        end
        return idx
    elseif create then
        local ok, scope = HasRoomForMacro(bar.perCharacter)
        if not ok then
            self:Notify("Your " .. scope .. " macro slots are full. Delete a macro and try again.")
            return
        end
        return CreateMacro(bar.name, self:MacroIcon(bar), body, bar.perCharacter and true or nil)
    end
end

-- Switch a bar's macro between account-wide and character-specific.
-- An existing macro is recreated in the other list and put back on the same action bar slots.
function ns:SetBarScope(bar, perCharacter)
    if not self:CheckCombat() then return end
    perCharacter = perCharacter and true or false
    if bar.perCharacter == perCharacter then return end

    local idx = GetMacroIndexByName(bar.name)
    if idx and idx > 0 and self:IsOurMacro(idx, bar) and IsCharacterMacro(idx) ~= perCharacter then
        local ok, scope = HasRoomForMacro(perCharacter)
        if not ok then
            self:Notify("Your " .. scope .. " macro slots are full; can't move the macro.")
            self:RefreshConfig()
            return
        end

        local slots = {}
        for slot = 1, MAX_ACTION_SLOTS do
            if GetActionInfo(slot) == "macro" and GetActionText(slot) == bar.name then
                slots[#slots + 1] = slot
            end
        end

        bar.perCharacter = perCharacter
        DeleteMacro(idx)
        local newIdx = CreateMacro(bar.name, self:MacroIcon(bar), self:MacroBody(bar), perCharacter or nil)
        if newIdx then
            ClearCursor()
            for _, slot in ipairs(slots) do
                PickupMacro(newIdx)
                PlaceAction(slot)
                ClearCursor()
            end
        end
    else
        bar.perCharacter = perCharacter
    end

    self:Notify(("Macro \"%s\" is now %s."):format(bar.name, perCharacter and "character-specific" or "account-wide"), "ok")
    self:RequestScan()
    self:RefreshConfig()
end

function ns:SyncAllMacros()
    if InCombatLockdown() then self.pendingRefresh = true return end
    for _, bar in ipairs(self.db.bars) do self:SyncMacro(bar, false) end
end

function ns:PickupBarMacro(bar)
    if not self:CheckCombat() then return end
    local idx = self:SyncMacro(bar, true)
    if idx and idx > 0 then
        PickupMacro(idx)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
for _, e in ipairs({
    "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR",
    "UPDATE_MACROS", "EDIT_MODE_LAYOUTS_UPDATED",
}) do
    pcall(events.RegisterEvent, events, e) -- tolerate events that don't exist on this client
end

events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            ns:InitDB()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif not ns.db then
        return
    elseif event == "PLAYER_LOGIN" then
        ns:BuildAll()
        if ns.InitLauncher then ns:InitLauncher() end
        if ns.db.loginMessage ~= false then
            print(("|cff33ccff%s|r%s - |cffffd100/fmd|r to edit bars, |cffffd100/fmd options|r for settings."):format(
                ns.TITLE, ns.VERSION ~= "" and (" v" .. ns.VERSION) or ""))
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns:RefreshConfig()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- (not on UPDATE_MACROS: our own EditMacro calls fire that event)
        ns:SyncAllMacros()
        ns:RequestScan()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.pendingRefresh then
            ns.pendingRefresh = false
            ns:BuildAll()
            ns:SyncAllMacros()
            ns:ApplyEditMode()
        end
        ns:RefreshConfig()
        ns:RequestScan()
    else
        ns:RequestScan()
    end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

SLASH_FOREVERMACRODROPDOWN1 = "/fmd"
SLASH_FOREVERMACRODROPDOWN2 = "/macrodropdown"
SlashCmdList.FOREVERMACRODROPDOWN = function(msg)
    local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" or cmd == "config" then
        ns:ToggleConfig()
    elseif cmd == "options" or cmd == "settings" then
        ns:OpenOptions()
    elseif cmd == "new" then
        local bar = ns:CreateBar(rest)
        if bar then
            ns.selectedBarId = bar.id
            ns:Print("Created bar \"" .. bar.name .. "\". Open /fmd to add spells and items.")
        end
    elseif cmd == "list" then
        if #ns.db.bars == 0 then ns:Print("No bars yet.") end
        local statusText = { placed = "on action bar", unplaced = "not on a visible bar", missing = "macro missing" }
        for _, bar in ipairs(ns.db.bars) do
            local horizontal = bar.direction == "LEFT" or bar.direction == "RIGHT"
            ns:Print(("%s - %d entries, opens %s in %d %s, %s"):format(bar.name, #bar.entries, bar.direction:lower(),
                bar.lines, horizontal and (bar.lines == 1 and "row" or "rows") or (bar.lines == 1 and "column" or "columns"),
                statusText[ns:BarStatus(bar)]))
        end
    elseif cmd == "scan" then
        ns:ScanAnchors()
        ns:Print("Rescanned action bars.")
    elseif cmd == "minimap" then
        ns:SetMinimapShown(ns.db.minimap.hide)
        ns:Print("Minimap button " .. (ns.db.minimap.hide and "hidden" or "shown") .. ".")
    else
        ns:Print("Commands:")
        print("  /fmd - open the configuration window")
        print("  /fmd new <name> - create a new popup bar")
        print("  /fmd list - list your bars")
        print("  /fmd scan - re-find which action buttons hold your macros")
        print("  /fmd minimap - show or hide the minimap button")
        print("  /fmd options - open this addon's page in Options > AddOns")
    end
end
