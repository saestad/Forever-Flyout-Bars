# Changelog

## 1.1.0

New:
- Addon icon, minimap button (uses LibDBIcon when available), and an entry in the AddOns compartment menu.
- Settings page under Options > AddOns: bar overview, minimap button, login message and macro window settings, slash commands, GitHub link. `/fmd settings` opens it.
- The bar editor always opens together with Blizzard's macro window (`/macro`), attached to its right side, and they close together. `/fmd`, `/fmd options`, the minimap button and the compartment all open both. Selecting one of the addon's macros there selects that bar. Can be turned off in the settings page.
- Popups stay open while the editor is open (no auto-hide, UI clicks don't close them), so they can be adjusted on the action bar.
- Columns/rows setting: popups can be a grid instead of a single line.
- Spacing and Background settings in the editor.
- Duplicate bar.
- Drag entries in the grid to reorder them. Shift-click makes an entry first (the macro's icon).
- Bar list shows each bar's icon, entry count and whether its macro is on an action bar.
- Popup buttons are tinted when you lack power or can't use them.
- Feedback (added, removed, errors) shows in the editor instead of only in chat.
- Login message with version and commands (can be turned off).
- `/fmd minimap`, `/fmd options` (opens the editor), `/fmd settings` (opens the settings page).

Changed:
- Redesigned editor window: draggable macro icon, welcome screen, help tooltip, combat indicator, remembers its position.
- Plain left-click on a grid entry no longer moves it.
- "Preview" is now "Show Popup" / "Hide Popup".

Fixed:
- Dropping something on a grid slot could show "already on the bar" twice.
- The Show Popup button could open and immediately close the popup.
- The hint text under Contents overlapped the grid.

## 1.0.0

- First release: popup bars of spells, items, toys, mounts and macros, opened from an action-bar macro, working in combat.
