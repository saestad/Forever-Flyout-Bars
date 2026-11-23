# Changelog

## 2.0.2

- Clearer addon description in the in-game AddOns list.

## 2.0.1

- Published automatically to CurseForge. The addon folder in the download stays `ForeverMacroDropdown`, and the version number comes from the release tag.

## 2.0.0

Renamed from Forever Macro Dropdown to **Flyout Bars**. The command is now `/fbar` (or `/flyoutbars`), replacing `/fmd`, `/ffm` and `/macrodropdown`. The folder name, saved settings and existing macros are unchanged.

New:
- Addon icon, minimap button (uses LibDBIcon when available), and an entry in the AddOns compartment menu.
- Settings page under Options > AddOns: bar overview, minimap button, login message and macro window settings, slash commands, GitHub link. `/fbar settings` opens it.
- The bar editor always opens together with Blizzard's macro window (`/macro`), attached to its right side, and they close together. `/fbar`, `/fbar options`, the minimap button and the compartment all open both. Selecting one of the addon's macros there selects that bar. Can be turned off in the settings page.
- Popups stay open while the editor is open (no auto-hide, UI clicks don't close them), so they can be adjusted on the action bar.
- Columns/rows setting: popups can be a grid instead of a single line.
- Spacing and Background settings in the editor.
- Duplicate bar.
- Drag entries in the grid to reorder them. Shift-click makes an entry first (the macro's icon).
- Bar list shows each bar's icon, entry count and whether its macro is on an action bar.
- Popup buttons are tinted when you lack power or can't use them.
- Feedback (added, removed, errors) shows in the editor instead of only in chat.
- Login message with version and commands (can be turned off).
- `/fbar minimap`, `/fbar options` (opens the editor), `/fbar settings` (opens the settings page).
- Licensed under MIT (see LICENSE).

Changed:
- Redesigned editor window: draggable macro icon, welcome screen, help tooltip, combat indicator, remembers its position.
- Plain left-click on a grid entry no longer moves it.
- "Preview" is now "Show Popup" / "Hide Popup".

Fixed:
- Dropping something on a grid slot could show "already on the bar" twice.
- The Show Popup button could open and immediately close the popup.
- The hint text under Contents overlapped the grid.
- The macro window's icon picker (Change Name/Icon) opened behind the editor. The editor now steps aside while it is open.
- Blizzard windows such as the spellbook and professions opened over or under the editor, so spells couldn't be dragged into it. The editor now uses the same layer as Blizzard's windows and moves to the right of whatever windows are open, including side tabs that stick out of them (professions). A docked editor can also be dragged elsewhere.

## 1.0.0

- First release: popup bars of spells, items, toys, mounts and macros, opened from an action-bar macro, working in combat.
