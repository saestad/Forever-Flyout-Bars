<img src="Media/Icon.png" width="64" align="left" alt="Flyout Bars icon">

# Flyout Bars

**Build your own flyouts.** Put one button on your action bar, click it, and a bar of spells, items, toys, mounts and macros pops out next to it, like the mage portal flyout. Click a button in it to use it. Works in combat.

<br clear="left">

Use it to free up action bar slots: all your mounts, portals, hearthstones, food, buffs or profession tools behind one button each.

**Looking for a macro dropdown, spell flyout or action bar popup menu?** That's what this does. Make a mount flyout, a portal or teleport menu, a toy and hearthstone menu, a food and buff bar, or a menu of profession tools, each opening from a single action button. Formerly known as **Forever Macro Dropdown**.

## Why another flyout addon?

I've tried several addons like this one, but none felt polished or easy enough to use, so I spun up my own version with ease of use in mind. A few guildmates liked it, so I put it up on CurseForge too.

## Features

- **Up to 24 buttons per flyout**, with as many flyouts as you have macro slots
- **Opens up, down, left or right**, as a single line or a grid with as many columns/rows as you want
- **Anything you can drag**: spells, items, toys, mounts and your own macros
- **Shows cooldowns and item counts**, and tints buttons when you lack mana or can't use them, just like Blizzard's action bars
- **Works in combat**: opening the flyout and casting from it are fully supported
- **Sits next to the action button you clicked** and matches its size, on Blizzard bars, Bartender4 and ElvUI
- **Closes the way you'd expect**: click the button again, press Escape, or click somewhere else. Auto-hide and close-after-use are on by default and can be turned off per flyout.
- **Account-wide or per character**: each flyout can be a general or character-specific macro

## Easy to set up

Type **/fbar** and the editor opens next to Blizzard's macro window.

1. Create a flyout and give it a name.
2. Drag spells, items, toys, mounts or macros into its grid. You can also type a name or ID.
3. Drag the flyout's icon onto your action bar.

While the editor is open, your flyouts stay open, so you can see every change on your action bar as you make it. Drag to reorder, right-click to remove. The first entry sets the button's icon and cooldown.

The editor makes room for the spellbook and professions windows, so you can drag spells straight across.

Good to know:
- Flyouts can only be edited outside combat, a Blizzard restriction. Using them works in combat.
- Each flyout uses one macro slot. The addon manages that macro's text, so don't edit it by hand.
- **Upgrading from Forever Macro Dropdown?** This is the same addon under its new name. Your existing bars and macros carry over.

The rest of this page is the full reference: every option, command and limit.

## Install

**Easiest:** install it from CurseForge with the CurseForge app, or download `FlyoutBars-<version>.zip` from the [Releases page](https://github.com/saestad/Forever-Flyout-Bars/releases) and unzip it into `World of Warcraft\_forever_\Interface\AddOns\`. Both already contain the right folder. Restart the game or type `/reload`.

**From the source code** (the latest, possibly unreleased, version):

1. On [GitHub](https://github.com/saestad/Forever-Flyout-Bars), choose **Code > Download ZIP**. (Not the "Source code" ZIPs on the Releases page: they have the same folder-name problem.)
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`.
3. **Rename the folder to `ForeverMacroDropdown`.** GitHub ZIPs unpack as `Forever-Flyout-Bars-main`, and WoW only loads the addon when the folder name matches `ForeverMacroDropdown.toc`. (The folder keeps the addon's original name, Forever Macro Dropdown, so existing settings carry over.)
4. Restart the game or type `/reload`.

Or clone it straight into the AddOns folder. Give the folder name at the end, as below: without it, git names the folder after the repo and WoW won't load the addon.

```
cd "World of Warcraft\_forever_\Interface\AddOns"
git clone https://github.com/saestad/Forever-Flyout-Bars.git ForeverMacroDropdown
```

The `.toc` targets WoW: Forever patch 1.60.1 (`## Interface: 16001`). After a game patch, if the addon shows as out of date or incompatible, run `/dump select(4, GetBuildInfo())` in game and put that number in the `## Interface:` line.

## Opening the addon

The bar editor always opens together with Blizzard's macro window, attached to its right side:

- `/fbar` opens the bar editor and the macro window, or closes them. `/fbar options` (or `/fbar option`, `/fbar config`) only opens them.
- **Minimap button**: left-click does the same as `/fbar`, right-click opens the settings page, drag to move it. If another addon has loaded LibDBIcon, the button is registered through it, so minimap button collectors and square minimaps work.
- **AddOns compartment** (the menu by the minimap): same clicks as the minimap button.
- **`/macro`**: opening the macro window yourself also opens the editor next to it. The addon icon in the macro window's title bar shows or hides the editor.

How the two windows go together:
- Closing either one closes both, when they were opened together. If you opened `/macro` yourself, closing the editor leaves the macro window open.
- If the editor was already open on its own before the macro window opened, it attaches while the macro window is open, then goes back to its own position.
- Selecting one of the addon's macros in the macro window selects that bar in the editor.
- **Change Name/Icon** in the macro window opens Blizzard's icon picker where the editor sits, so the editor steps aside while the picker is open and comes back when it closes.
- Other Blizzard windows (spellbook, professions, character, ...) open side by side with the macro window, and the editor moves to the right of the right-most one, clear of side tabs such as the professions window's. Nothing covers it, so you can drag spells and items straight into the grid.
- If your screen is too narrow for everything side by side, drag the editor by its title bar to put it somewhere else. It stays there until you close it, and attaches again the next time it opens.
- In combat the macro window can't be used, so the editor opens on its own.
- To always use the editor on its own, turn off "Open the bar editor together with the macro window" in the settings page.

**Settings page** (Options > AddOns > Flyout Bars, or `/fbar settings`; not in combat): an overview of your bars, a button that opens the editor, the minimap button, login message and macro window settings, the slash commands, and a copyable link to this GitHub page.

## Use

1. Type a name in **New bar** (max 16 characters, which is also the macro name) and click **Create**. This also creates the macro.
2. Drag spells, items, toys, mounts or macros into the grid. You can also type a name or ID, or shift-click a link into the box under the grid. Enter adds the first match (spell, then item, then macro). The **Spell**, **Item** and **Macro** buttons say which kind you mean. Use them when a name is both a spell and an item, such as Hearthstone.
3. Choose where the popup opens: **Up**, **Down**, **Left** or **Right**.
4. Drag the macro icon (top left of the editor), the bar in the list, or click **Pick Up Macro**, and drop it on an action bar.
5. Click that action button to open the popup, and click it again to close.

Grid:
- Drag an entry to another slot to reorder.
- Shift-click an entry to make it first. The first entry (gold frame) sets the macro's icon and cooldown.
- Right-click removes an entry.

The bar list shows each bar's icon, entry count and status: green check = on an action bar, yellow = macro exists but isn't on a visible bar, red = macro not created on this character yet. Hover a bar for details.

Messages about what you just did (added, removed, errors) show in the editor under the grid. When the editor is closed they go to chat.

Options per bar:
- **Columns / Rows**: how many columns a vertical popup has (or rows, for a horizontal one). Entries fill the line nearest the action button first, then the popup grows in its direction. For example, opening up with 3 columns puts entries 1-3 in the bottom row, 4-6 above them, and so on. 1 = a single line.
- **Spacing**: gap between the popup's buttons.
- **Close after use**: hides the popup after you click one of its buttons.
- **Background**: dark backdrop and border behind the popup.
- **Auto-hide**: closes the popup after the mouse has been away from it for N seconds (0 = off).
- **Character only**: puts the macro in the character's macros instead of the General (account-wide) ones. Switching moves an existing macro and keeps it on the same action bar slots. Bars are saved account-wide. Each character that uses a character-only bar gets its own macro the first time you place it on that character.

Managing bars:
- **Rename** renames the bar and its macro. The macro stays on the same action bar slots.
- **Duplicate** copies a bar's contents and settings under a new name ("Name 2").
- **Delete** removes the bar and its macro (after a confirmation).
- **Show Popup** / **Hide Popup** opens or closes the popup next to the macro's action button.

### Adjusting a popup on the action bar

While the editor is open, popups stay open: clicks elsewhere in the UI (the editor, spellbook, bags) don't close them and auto-hide is paused. Open the popup from its action button (or with **Show Popup**), then add, remove and reorder entries or change direction, columns/rows, spacing and background, and the popup updates in place. Clicking the macro again, Escape, and clicking the game world still close it. When the editor closes, auto-hide resumes.

Popup buttons show cooldowns, item counts, and are tinted like the default action bars: blue when you lack mana/power, grey when unusable.

Closing the popup:
- Click the macro again.
- Press Escape.
- Click outside the popup. Clicking the game world closes it, and that click is used up, so it doesn't target or turn the camera. Out of combat, clicking any other UI element also closes it, except while the editor is open (see above). In combat, clicks on other UI elements are left alone.

## Slash commands

`/flyoutbars` works everywhere `/fbar` does.

| Command | What it does |
| --- | --- |
| `/fbar` | Open or close the bar editor (with the macro window) |
| `/fbar options` | Open the bar editor (with the macro window). `/fbar option` and `/fbar config` do the same |
| `/fbar settings` | Open the settings page in Options > AddOns |
| `/fbar new <name>` | Create a bar (and its macro) |
| `/fbar list` | List your bars with entry count, direction, layout and whether the macro is on an action bar |
| `/fbar scan` | Re-find which action buttons hold your macros (if a popup opens in the wrong place) |
| `/fbar minimap` | Show or hide the minimap button |
| `/fbar help` | List these commands in chat |

On login a single chat line shows the version and the two main commands. Turn it off in Options > AddOns.

## Limits

- Up to 24 entries per bar.
- Bar names are macro names: at most 16 characters, unique, and not the name of a macro you made yourself.
- Each bar uses one macro slot. Blizzard allows 120 general (account-wide) and 18 character-specific macros. If they're full, the addon says so and you need to delete a macro first.
- Items can be added by name only if the game has seen them this session. Otherwise drag the item in, shift-click its link, or use its item ID.
- Bars can't be created or changed in combat. Popups still open, close and cast in combat.

## Troubleshooting

- **The addon isn't in the AddOns list, or is marked out of date.** Check the folder is named exactly `ForeverMacroDropdown`. After a game patch, update the `## Interface:` number (see Install).
- **The popup opens in the middle of the screen.** The macro isn't on a visible action button, or the addon hasn't noticed yet. Put the macro on a bar and run `/fbar scan`.
- **The bar list shows a red icon.** That character doesn't have the macro yet (for example a character-only bar on a new character). Drag the macro icon onto an action bar to create it.
- **"A macro named X exists but wasn't made by this addon."** You have your own macro with that name. Rename the bar or your macro.
- **I edited the macro text and my changes disappeared.** The addon manages the macro text and rewrites it. Put custom macros in the popup as macro entries instead.
- **Show Popup, or right-clicking the minimap button, does nothing.** Check you're not in combat: the editor's buttons are disabled then, and the settings page can't open.
- **The macro window didn't open with the editor.** You're in combat, or "Open the bar editor together with the macro window" is turned off in `/fbar settings`.

## Saved settings

Bars and settings are saved account-wide in `WTF\Account\<account>\SavedVariables\ForeverMacroDropdown.lua`. To start over, log out and delete that file. This doesn't delete the macros; remove them in `/macro` (each one's text is `/click FMDToggle<number>`).

## How it works

- Each bar has a hidden secure button `FMDToggle<id>`. The macro is `/click FMDToggle<id>`, which runs a secure snippet to show or hide the popup. The popup's buttons are `SecureActionButtonTemplate` buttons.
- The popup anchors to the action button that holds the macro, and its buttons match that button's size and scale. It supports Blizzard bars and LibActionButton bars (Bartender4, ElvUI). If the macro isn't on a visible bar, the popup opens near screen centre.
- Bars can't be edited during combat (a Blizzard restriction). The editor shows "In combat - editing paused" and greys out. Changes made by events during combat are applied when combat ends.
- The addon manages the macro text. Manual edits to the macro body are overwritten. The macro is `#showtooltip <first entry>` (for spells and items, which gives the icon and cooldown) followed by the `/click` line.
- While the editor is open, each popup has an `fmd-editing` attribute set. The secure toggle then skips registering auto-hide, and auto-hide on an already open popup is cancelled with `SecureHandlerExecute`. It is re-armed when the editor closes.
- Opening the editor loads `Blizzard_MacroUI` if needed and shows `MacroFrame` with `ShowUIPanel`. The editor attaches by hooking `MacroFrame`'s `OnShow`/`OnHide`. It is not itself a managed UI panel (that taints the panel layout code); instead it post-hooks `ShowUIPanel`, `HideUIPanel` and `UpdateUIPanelPositions` and anchors to the right-most window from `GetUIPanel("left"/"center"/"right"/"doublewide")`. It doesn't change the macro window itself, apart from adding a small button to its title bar.

## Files

| File | Purpose |
| --- | --- |
| `Core.lua` | Saved data, bar/entry management, macro creation, events, slash commands |
| `Popup.lua` | Secure toggle and popup frames, anchoring to action buttons |
| `Config.lua` | The bar editor window, docking to the macro window |
| `Launcher.lua` | Minimap button, AddOns compartment entry, Options > AddOns page |
| `Media/Icon.tga` | Addon icon used in game (128×128, 32-bit TGA) |
| `Media/Icon.png` | Same icon for GitHub |
| `LICENSE` | MIT license |
| `tools/build-release.ps1` | Builds the release ZIP (not shipped in the ZIP) |
| `tools/make-icon.ps1` | Draws the icon as TGA and PNG at any size (not shipped in the ZIP) |
| `dist/` | Build output: release ZIPs, the large icon (ignored by git) |

## Making a release

The version comes from the git tag. The `.toc` has `## Version: @project-version@`, which the CurseForge packager replaces with the tag name, so don't change that line.

1. Add a section for the new version at the top of `CHANGELOG.md` and commit it. Use a major version (3.0.0) when something players rely on stops working, such as a removed command.
2. Tag the commit and push both:
   ```
   git tag -a v<version> -m "Flyout Bars <version>"
   git push origin main
   git push origin v<version>
   ```
   CurseForge packages every new tag it sees. A tag containing `beta` or `alpha` (such as `v2.1.0-beta1`) becomes a Beta or Alpha file; anything else is a Release. `.pkgmeta` sets the folder name (`ForeverMacroDropdown`) and leaves `tools/` out of the package.
3. For the GitHub release, build the ZIP:
   ```
   powershell -ExecutionPolicy Bypass -File tools\build-release.ps1
   ```
   This writes `dist\FlyoutBars-<tag>.zip` with a single `ForeverMacroDropdown/` folder inside, taking the version from the latest tag. If you add a file the game needs, add it to the list at the top of the script too.
4. On GitHub, create a release from the tag, paste the changelog section, and attach the ZIP from `dist\`.

When running the addon straight from a git clone, the version shows as `@project-version@`; packaged downloads show the real one.

For a bigger project-page icon: `powershell -ExecutionPolicy Bypass -File tools\make-icon.ps1 -OutTga dist\big.tga -OutPng dist\FlyoutBars-icon-512.png -Size 512`.

## Bugs and ideas

Report bugs or suggest features in [GitHub issues](https://github.com/saestad/Forever-Flyout-Bars/issues). Please include:

- the addon version (shown in the editor's title bar and in Options > AddOns)
- what you did, what you expected, and what happened
- any Lua error text (turn on errors with `/console scriptErrors 1`, or use BugSack)

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## A note on AI

I use generative AI as a tool while making this addon, mostly to help write and review code and documentation the same way I use it in my day job. I decide what the addon should do and how it should behave, read every change, test thoroughly and adjust before releasing updates. I know it's a sore subject for many, so I'd rather say it plainly. If something is broken, that's on me, so please report it. I care about not adding to the pile of low-effort AI junk out there.

## Author

Made by [saestad](https://github.com/saestad).

## License

MIT. See [LICENSE](LICENSE).
