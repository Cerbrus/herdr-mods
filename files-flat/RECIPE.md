# Files flat

The Files side panel of Herdr without its rounded card: no 10px corners and no 1px border around it, so it sits flush against whatever the layout puts next to it. Everything else is the shipped `files` panel: a file tree of the focused pane's folder with git marks and a read-only preview.

![Files flat](preview.png)

## What you see

A panel that fills its block, 13px text on the `background` colour, square, with no border of its own.

- **Header**, 42px, 1px `border` line below: `Files` in semibold on the left; on the right, in 12px `dim`, the name of the folder shown, or the path of the file being previewed. While a file is previewed a `←` sits in front of the title.
- **Tree**, scrolling, 6px padding: 28px rows with 7px rounded corners. A folder row has a 12px chevron (right when folded, down when open) and a 14px folder icon; a file row has a 14px file icon. Each level is indented 18px. A changed file has a mark at the end in 11px: `A` in `ansi2`, `D` and `U` in `ansi1`, `M` in the `blocked` colour.
- **Preview**, in place of the tree: a read-only code editor at 12px in the terminal font with syntax colours from the theme.
- Messages in `dim`: "Loading files…", "No files", "No folder", an error text, or "File list limited to 500 entries per folder and 5,000 total".

## How it behaves

As the shipped `files` mod:

- It follows the focused pane: its folder, else the space's folder. Switching pane or space switches the tree, and coming back restores the open folders and the previewed file.
- Click a folder to open or fold it; folding forgets what was open inside it. Click a file to preview it; `←` returns to the tree.
- Rows show the `hover` background under the pointer.
- The tree refreshes when the folder changes on disk and every 10 seconds.
- `.git` is never listed. Folders come first, then files, by name.
- A file with a null byte shows "Binary file · no text preview"; a preview is cut at 400,000 characters.
- It draws no agent status.

## Built from

One mod, `files-flat`, a clone of the shipped `files` mod (0.1.16; `mod.json` has `"place": "none"` and `cloned_from`). It takes no `props`. Put it in a layout block: `"content": { "mod": "files-flat" }`.

The whole difference from the shipped mod:

- The root element has no `.rounded(10)` and no `.border_1().border_color(t.border)`. It keeps `.overflow_hidden()` and the `background` colour.
- The icons are read from the clone's own folder: `mods/files-flat/chevron-right.svg`, `chevron-down.svg`, `folder.svg`, `file.svg` (copies of the shipped ones).

Unchanged from the shipped mod:

- `herdr` functions: `spaces`, `panes`, `focused`, `exec`, `readTextFile`, `watchFolder`, `theme`, `settings`, `window`. UI: `Editor`, `EditorState` from `gpui-base`.
- Programs it runs: `powershell -NoProfile -Command` with `Get-ChildItem` to list a folder on Windows, `sh -c` elsewhere and on remote machines; `git rev-parse --show-toplevel` and `git --no-optional-locks -c core.fsmonitor=false status --porcelain=v1 -z --no-renames --untracked-files=all` for the marks.
- A 10,000 ms timer plus `watchFolder` on the folder (local folders only).
- It runs no commands.

## Watch out

- It runs `powershell` or `sh`, and `git`, and reads files outside its own folder (that is its job). Tell the person before adding it.
- A panel without a border needs a layout that draws the lines. With a `gap` of 1 between blocks over a `border`-coloured background the panel gets 1px seams; in a layout with padding around its panels it looks like a bare rectangle.
- Do not edit the shipped `files` mod: Herdr updates overwrite it. Clone it (`mod.clone { name: "files", as: "files-flat" }`), which rewrites the `mods/files/` asset paths, then remove the two calls.
- Herdr never updates a clone. After an app update, compare the shipped `files` mod with this one and merge what changed.
- The tab bar's Files button points at the layout block with id `files`, not at the mod name. Keep that block id when swapping the mod in.
- Limits: 500 entries per folder, 5,000 in total, 40 levels deep.

## Done when

- `herdr-app check` passes on `files-flat`.
- In a layout block the panel has square corners and no line of its own around it.
- The folder and file icons show (they load from `mods/files-flat/`).
- Clicking a folder opens it, clicking a file shows its preview and `←` returns to the tree.
- A file changed in a git repository gets an `M` at the end of its row within 10 seconds.
