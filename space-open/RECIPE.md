# Space open

A picker that opens a folder as a space. It drops down from the top of the window with a search field and a list of your project folders; you type a few letters, press Enter, and the folder opens as a new space with your agent already started in it. If that folder is already open, you are taken to its space instead. A full path you type is offered as it is, so any folder can be opened.

![Space open](preview.png)

## What you see

A panel 560px wide, 40px below the top of the window, on the theme's `popover` background with 18px padding and 10px between its parts. Top to bottom:

- **Title row**: "Open a space" in 15px semibold `foreground`, or "Open a space in <folder name>" when it was opened from a folder of the `spaces-folders` list. At the right "Esc" in 11px `dim`.
- **Search field**: 36px high, 9px radius, a 1px `accent` border on the `background` colour. A 15px `search` icon in `dim`, then the input in 12.8px with the placeholder "Folder to open…".
- **List**: one row per folder, 32px high, 7px radius, 10px side padding: a 14px `folder` icon in `muted`, the folder's label in 13px `foreground` (cut off with an ellipsis when too long), and "open" in 11px `dim` at the right when a space is already open there. The chosen row has the `selected` background.
  - A folder's label is its name, or `<label>/<name>` when its root has a label.
  - A typed full path shows as the first row with a `folder-plus` icon and the path as typed.
  - The list is as tall as its rows, up to what fits in 70% of the window's height (at least 4 rows), and scrolls past that.
- **Instead of rows**, one line in `dim`:
  - "Looking for folders…" while the folders are being listed.
  - "No folder matches. Type a full path to open it." when nothing matches.
  - "Type a full path to open it. List your project folders in mods/space-open/config.js to pick from them." when no roots are set.

## How it behaves

The picker has nothing to do with agent status and shows none.

- **Opening**: `ctrl-shift-n`, or anything that runs `mod.open` for it. Running it again closes it. The search field has the keyboard at once.
- **Typing** narrows the list to labels that contain the text, ignoring case. Folders whose name starts with the text come first; within that the order is alphabetical by label. The first row is chosen again after every change.
- **A full path** (`C:\…`, `C:/…`, `\\server\…`, `~\…` or `~/…`) adds a row for exactly that path at the top, unless a listed folder already is that path.
- **Up and Down** move the chosen row and wrap around; the list scrolls to keep it in view.
- **Enter** opens the chosen row. **A click** opens the row clicked. Rows show the `hover` background under the pointer.
- **Esc** closes the picker without doing anything.
- **Opening a row** closes the picker, then:
  - if a space on this computer is already in that folder (compared without case, slash direction or a trailing slash), that space is shown;
  - otherwise a new space is made, named after the folder (its last path part, not its label), in that folder, running the command from `config.js` (`claude` as shipped).
- **Opened from a folder's menu** in `spaces-folders` ("New space"), the new space lands in that folder. Opened any other way, it is loose.

## Built from

One mod of its own, no layout changes.

- `mod.json`: `{ "place": "none", "title": "Open space", "overlay": { "kind": "popup", "at": "top", "offset": 40, "width": 560, "height": 0.7 } }`.
- `keys.json`, to merge into the person's own: `{ "global": { "ctrl-shift-n": "mod.open:space-open" } }`. This replaces Herdr's default `space.new` on that key. Ask before replacing a key the person uses.
- `config.js`, the person's own file:
  - `export const ROOTS = []`: a list of `{ path, label? }`, for example `{ path: "C:\\projects" }` or `{ path: "C:\\projects\\client", label: "client" }`. Shipped empty: the picker then only offers typed full paths.
  - `export const ARGV = ["claude"]`: what a new space starts.
  - When adding or updating the mod, keep an existing `config.js`. `main.js` falls back to `[]` and `["claude"]` when an export is missing.
- `main.js`: one `View`.
  - `init`: an `InputState` with `change` and `submit` handlers, a `ScrollHandle`, a focus handle, and one `cx.spawn` that lists each root in turn.
  - `rows()`: the filtered, sorted list plus the typed-path row.
  - `go(row)`: closes, then `space.select` or `space.new`.
  - Sizes: rows 32px; list height = `min(room, max(1, rows) * 32)` with `room = max(128, floor((window.viewport_size().height * 0.7 - 150) / 32) * 32)`.
- Program it runs: `cmd /d /c dir /b /ad <root path>` once per root when it opens, through `exec`. A root that fails is skipped.
- `herdr`: `spaces`, `run`, `exec`, `theme`, `props`, `closeOverlay`, `checking`, `shared`, `setShared`.
- Commands: `space.select { id }`, `space.new { name, folder, argv }`.
- `props`: `{ folder }`, the id of a `spaces-folders` folder (optional), and `overlay`, the id it closes itself with (`closeOverlay(props().overlay)`).
- Shared state: reads `spaces.folders` to find that folder's name for the title. Before `space.new` it writes `spaces.folders.incoming = { folder, path, at }` with `path` lowercased, with backslashes and no trailing slash, and `at` the time in milliseconds. `spaces-folders` picks that up and files the space.
- Art: `search`, `folder` and `folder-plus` from the shipped `mods/workspace-chrome`. None of its own.

## Watch out

- Windows only as written: folders are listed with `cmd` and `dir`, and paths are built and compared with backslashes.
- It runs a program (`cmd`) and reads folder names outside its own folder. Tell the person before adding it.
- A popup is as tall as its content, so a scroll container with only `min_h(0)` collapses and the picker shows empty. The list gets an explicit height in pixels instead.
- `herdr-app check` loads the mod: skip the `exec` calls when `checking()` is true.
- A mod cannot import from another mod's folder. The link with `spaces-folders` is shared state only, and the mod works without that mod: the note it leaves is then never read.
- The input is focused in `init` and once more after 600ms. Keep both calls.
- Only the folders directly under each root are listed, one level deep, once per opening. There is no cache and no refresh while it is open.
- A root's `path` must not end in a backslash: the folder's path is built as `<path>\<name>`.
- A typed path is handed to `space.new` as typed, with only `/` turned into `\`. Nothing checks that it exists, and `~` is not expanded by the mod, so a `~` path is not recognised as already open.
- Spaces on other machines are ignored when looking for an open one, and the picker only opens folders on this computer.
- The folder's menu in `spaces-folders` opens the picker with `kind: "dialog"`; `mod.open` uses the `popup` from `mod.json`. Both must work.
- "New space" in the tab bar's menu and the command palette is still Herdr's own `space.new`.

## Done when

- `herdr-app check` passes on the mod folder.
- `ctrl-shift-n` opens the picker at the top of the window with the cursor in the search field; pressing it again, or Esc, closes it.
- With empty `ROOTS` it shows the line about `config.js`; with a root set it lists that root's folders alphabetically, with the label and a slash in front where the root has one.
- Typing part of a name narrows the list, with names that start with the text on top.
- Down and Up move the highlight and wrap from the last row to the first.
- Enter on a folder makes a space named after it, in that folder, with `claude` (or your `ARGV`) running in its first terminal.
- Opening the picker again shows "open" on that folder's row, and Enter on it shows the existing space instead of making a second one.
- Typing a full path that is not in the list adds it as the first row with the `folder-plus` icon, and Enter opens it.
- "New space" in a `spaces-folders` folder menu titles the picker "Open a space in <name>", and the space it opens appears in that folder.
