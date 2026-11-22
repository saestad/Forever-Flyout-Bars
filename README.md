# Forever Macro Dropdown

Creates action-bar macros that open a popup bar (vertical or horizontal) of spells, items, toys, mounts and macros. Works in combat.

## Install

Copy this folder to `World of Warcraft\_<game folder>_\Interface\AddOns\ForeverMacroDropdown\`. The folder name must match `ForeverMacroDropdown.toc`.

The `.toc` targets WoW: Forever patch 1.60.1 (`## Interface: 16001`). After a game patch, if the addon shows as out of date or incompatible, run `/dump select(4, GetBuildInfo())` in game and put that number in the `## Interface:` line.

## Use

1. `/fmd` opens the config window.
2. Type a name (max 16 characters, which is also the macro name) and click **Create**.
3. Drag spells, items, toys, mounts or macros into the grid. You can also type a name or ID, or shift-click a link into the box.
4. Choose **Vertical Up/Down** or **Horizontal Right/Left**.
5. Drag the bar's name from the list onto an action bar, or click **Put Macro on Cursor**.
6. Click that action button to open the popup, and click it again to close.

Grid: left-click moves an entry earlier, shift-click moves it later, right-click removes it. The first entry sets the macro's icon and cooldown.

Options:
- **Close after use**: hides the popup after you click one of its buttons.
- **Auto-hide**: closes the popup after the mouse has been away from it for N seconds (0 = off).
- **Character only**: puts the macro in the character's macros instead of the General (account-wide) ones. Switching moves an existing macro and keeps it on the same action bar slots. Bars are saved account-wide. Each character that uses a character-only bar gets its own macro the first time you click **Put Macro on Cursor** on that character.

Closing the popup:
- Click the macro again.
- Press Escape.
- Click outside the popup. Clicking the game world closes it, and that click is used up, so it doesn't target or turn the camera. Out of combat, clicking any other UI element also closes it. In combat, clicks on other UI elements are left alone.

Slash commands: `/fmd`, `/fmd new <name>`, `/fmd list`, `/fmd scan`.

## How it works

- Each bar has a hidden secure button `FMDToggle<id>`. The macro is `/click FMDToggle<id>`, which runs a secure snippet to show or hide the popup. The popup's buttons are `SecureActionButtonTemplate` buttons.
- The popup anchors to the action button that holds the macro, and its buttons match that button's size and scale. It supports Blizzard bars and LibActionButton bars (Bartender4, ElvUI). If the macro isn't on a visible bar, the popup opens near screen centre.
- Bars can't be edited during combat (a Blizzard restriction). Changes made by events during combat are applied when combat ends.
- The addon manages the macro text. Manual edits to the macro body are overwritten.
