# Spaces folders

The Spaces list of the sidebar, with folders. Spaces you have not filed stay loose at the top; under them come the folders you made, each a header that folds, with its spaces and then its subfolders hanging from thin guide lines like a file tree. You file a space by dragging it onto a folder, and you make, rename, move and delete folders from a button in the header and a right-click menu. Everything else (avatars, git tail, worktrees, machines, the narrow rail) is Herdr's shipped `spaces` list.

![Spaces folders](preview.png)

## What you see

Top to bottom, in the sidebar, on the theme's `chrome` background:

- **Header**, 31px high, `Spaces` in 11.5px `dim`. On the right two 26px buttons with 14px icons and a 6px radius: `folder-plus` (tooltip "New folder") and `plus` (tooltip "Open a folder as a space").
- **Loose spaces**: the shipped space rows, 30px high, unchanged.
- **Folders**, in the order you gave them. A folder header is 28px high with a 7px radius: an 11px chevron (`chevron-down` open, `chevron-right` folded), a 13px `folder` icon, the name in 12px semibold `muted`, and at the right the number of spaces in it and under it in 11px `dim`.
- **Inside a folder**: first its spaces, then its subfolders. Each level is indented 16px. Guide lines are 1px wide in `dim` at 55% opacity, at x = 13px + 16px per level: a vertical line that stops halfway on the last child, and a 9px horizontal branch at half height to each child. Lines of the folders around it pass through while those have more children below.
- **Worktree rows** (28px, branch icon) stay under their checkout's row, inside the same folder, with the checkout's guide lines passing through.
- **Below the list**: empty space that fills the rest of the sidebar. While you drag a filed space it is at least 40px high and, under the pointer, shows a 2px `accent` line and "Out of its folder" in 11px `dim`.

The folder menu is a popup (210px wide, 12.8px text, 31px rows, 14px icons, 7px radius, 1px `border` rules): New space, New folder, a rule, Rename, Move to…, Move up, Move down, a rule, Delete. The "Move to…" list is a second popup, 240px wide, each target indented 14px per level. The name dialog is 420px wide: a 15px semibold title ("New folder" or "Rename folder") with "Esc" in 11px `dim`, a "Name" label in 11.5px, a 36px input with a 1px `accent` border and 9px radius, and Cancel and Save buttons (32px high, 8px radius, Save in the theme's `solid` colour).

When the sidebar is narrower than 160px the list is the shipped rail: numbered cells, no folders, and no folder button. The spaces keep the order the folders gave them.

## How it behaves

Agent status: space rows do not show it, as in the shipped list. A folded folder shows a `●` before its count when a space in it or under it is `blocked`, or else `done`, in the theme's colour for that status. `working` and `idle` show nothing on a folder. In the rail each cell shows `●` for `blocked` and `done` and `·` otherwise, as shipped.

- **Click a folder header**: folds or unfolds it. A folded folder hides its spaces and subfolders. Which folders are folded is remembered.
- **Going to a space or tab inside folded folders** (by any route) unfolds every folder around it.
- **Folder button in the header**: opens the name dialog for a new top-level folder. Enter or Save makes it, Esc or Cancel does not. An empty name does nothing.
- **Plus button in the header**: opens the `space-open` picker. The new space is loose.
- **Right-click a folder header**: its menu. Up and down move the selection, Enter chooses, Esc closes, a click chooses.
  - New space: opens the `space-open` picker as a dialog; the space opened from it lands in this folder.
  - New folder: names a folder inside this one. Not offered on a folder at the third level.
  - Rename: the name dialog with the current name selected.
  - Move to…: lists "Top level" (unless it is already there) and every folder it fits in; "Nowhere to move it to" when there is none.
  - Move up, Move down: one place among its siblings; each is only offered when there is a place to go.
  - Delete: only works when no open space is in the folder or under it; its empty subfolders go with it. Otherwise the item is dimmed with the hint "not empty".
- **Drag a space onto a folder header** (the header turns `selected`): it goes into that folder.
- **Drag a space onto a space row**: it goes into that row's folder, or out of every folder when that row is loose, and takes that row's place (the shipped 2px `accent` line shows where).
- **Drag a filed space below the list**: it becomes loose.
- **Drag a folder header onto another header**: the dragged header dims to 50%. The top 8px of the target puts it before that folder (2px `accent` line on top), the bottom 8px after it (line at the bottom), the middle 12px inside it (the header turns `selected`). A spot it does not fit in shows nothing and does nothing.
- **Order**: spaces are reordered in Herdr itself so loose spaces come first and each folder's spaces sit together, in the order the folders show.
- **First run**: the folders listed in `config.js` are made and the open spaces each one takes are filed. After that, folders only change by hand.
- Folders are for this computer's spaces: seeding, incoming spaces and drops on a space row skip other machines. With more than one machine the folders show under the "This computer" header.

Clicking, right-clicking and reordering spaces, the git tail, colours, machine headers and scrolling to the active space behave as the shipped list.

## Built from

A clone of the shipped `spaces` mod, version 0.1.16 (`mod.json`: `"place": "none"`, `"title": "Spaces"`, `"cloned_from": { "name": "spaces", "version": "0.1.16" }`). Start from `mod.clone { name: "spaces", as: "spaces-folders" }`, then put `{ "mod": "spaces-folders" }` in the layout block that held `spaces`. It needs the `space-open` mod.

- `main.js`: the shipped list plus the folder tree. `ordered()` tags each row with its folder and sorts groups (a checkout with its worktrees) by the folder's place in the tree before sending `space.move`. `foldered()` draws loose rows, headers, nested rows and the drop area; `guides()` draws the lines as absolutely placed 1px `div`s. `checkNew()` (the shipped 250ms timer) also seeds once and claims incoming spaces.
- `folders.js`: the data and every change to it. State is `{ folders: [{ id, name, parent }], of: { <space id>: <folder id> } }` in shared state under `spaces.folders`. `MAX_DEPTH = 3`. Sibling order is the order of `folders`. A folder whose parent is gone counts as top level; a space whose folder is gone counts as loose.
- `folder-edit.js`: the menu, the "Move to…" list and the name dialog. The list opens its own mod as an overlay and `init` hands that copy to this class when `props().mode` is set:
  - `{ mode: "menu", folder }`: popup, 210 x 290 at most.
  - `{ mode: "move", folder }`: popup, 240 x 320 at most.
  - `{ mode: "name", folder }` renames; `{ mode: "name", parent? }` names a new folder: dialog, 420 x 200.
- `config.js`: `export const SEED = []`, a list of `{ name, takes: (space) => boolean }`. It is the person's own file. When adding or updating the mod, keep an existing `config.js`.
- Shared state: `spaces.folders` (read by `space-open` for the folder's name), `spaces.folders.incoming` (`{ folder, path, at }`, written by `space-open`; the first loose local space whose `folder` equals `path` goes into `folder`, and the note is dropped then or after 20 seconds), `space.colors` (as shipped).
- `localStorage`: `spaces.folders.folded` (ids of folded folders), next to the shipped `machines.folded` and `machines.reconnecting`.
- `herdr`: `spaces`, `machines`, `panes`, `layout`, `window`, `theme`, `props`, `checking`, `shared`, `setShared`, `run`, `openOverlay`, `closeOverlay`, `exec`, `hc`, `watchFolder`.
- Commands: `space.move`, `space.select`, `mod.open { name: "space-open" }`, and the shipped `space.new { machine }` and `app.settings` on machine headers.
- Overlays of other mods: `space-open` as a dialog (560 wide, height 0.7, `props: { folder }`), the shipped `menu` for a space's right-click, the shipped `machine-add`.
- Programs, all from the shipped list: `git rev-parse`, `git symbolic-ref`, `git rev-list` per space, and `hc machine ls --json`, `hc machine rm`, `hc machine add`.
- Art: icons from the shipped `mods/workspace-chrome` (`folder`, `folder-plus`, `plus`, `chevron-down`, `chevron-right`, `branch`, `layers`, `square-pen`, `x`, `monitor`, `server`), plus its own `chevron-up.svg` (Lucide `chevron-up`, 24px, stroke 2) for "Move up".

## Watch out

- A mod cannot import from another mod's folder, so the menu and dialogs live inside this mod and it opens itself as an overlay. A copy opened with `props().mode` must return from `init` before any of the list's state and timers are set up, and `render` must hand over to the editor.
- A popup is as tall as its content; `height` is only the most. Do not put a scroll container inside the menu, it collapses to nothing.
- `cx.notify()` in a mouse-down handler redraws the element and swallows its `on_click`. Folder headers therefore fold on mouse-up, and only when the header released on is the one that was pressed.
- Elements only exist after a redraw: the before, inside and after spots on the other headers are drawn only while a header is held, so the press has to call `cx.notify()`.
- Seeding waits until there are spaces and `checking()` is false, and runs once: after `spaces.folders` exists `SEED` is never read again. An empty `SEED` seeds nothing, so a `SEED` filled in later still applies as long as no folder was made by hand.
- Folders nest three levels at most. A move that would push a subfolder past the third level is refused.
- Deleting only looks at open spaces. Entries in `of` for spaces that no longer exist stay until their folder is deleted.
- The shipped list's 14px bottom padding is gone; the drop area below the folders takes its place.
- The rail is detected from a layout node with the id `sidebar` narrower than 160px. In a layout without that id the list never turns into a rail.
- Path matching for incoming spaces lowercases and uses backslashes, as `space-open` writes them. It is written for Windows.
- It is a clone: Herdr does not update it. Changes to the shipped `spaces` mod have to be merged in by hand.

## Done when

- `herdr-app check` passes on the mod folder, and the sidebar shows `Spaces` with a folder button and a plus button.
- The folder button opens "New folder"; typing a name and pressing Enter adds a header with the count `0`.
- Dragging a space onto that header moves it under the header on a guide line, and the count becomes `1`.
- Clicking the header hides the space and turns the chevron right; selecting that space another way unfolds it again.
- Right-clicking the header shows the menu; Delete reads "not empty" while a space is inside and removes the folder once it is empty.
- "New folder" in the menu nests a folder; at the third level the item is no longer offered.
- Dragging one header onto another shows a line on its top or bottom edge, or highlights its middle, and the folder lands there.
- "New space" in the menu opens the picker titled "Open a space in <name>", and the space opened from it appears in that folder.
- Dragging a filed space below the list shows "Out of its folder" and makes it loose, above all folders.
- A folded folder with a blocked agent in it shows a `●` in the blocked colour.
- Restarting the app keeps the folders, their contents and which ones are folded.
