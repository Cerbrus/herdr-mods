# Changes flat

The Changes side panel of Herdr without its rounded card, with a button that wraps long diff lines and a sideways scrollbar that is always there. Everything else is the shipped `changes` panel: the uncommitted files of the focused pane's repository, the diff of one of them, and a commit field.

![Changes flat](preview.png)

## What you see

A panel that fills its block, 13px text on the `background` colour, square, with no border of its own. Top to bottom:

- **Header**, 42px, 1px `border` line below: `Changes` in semibold, a small bordered count (`3 files`, 10px, `muted`), then on the right the **wrap button** and the totals `+12` in `ansi2` and `−4` in `ansi1` (11px).
  - The wrap button is a 22px square with 4px corners and a 1px border holding a 13px wrap icon. Off: `border`-coloured border, `muted` icon. On: both in `accent`.
- **File list**, 28px rows, at most as tall as its rows and at least 44px, 1px line below: the status letter (`A` in `ansi2`, `D` and `U` in `ansi1`, `M` in the `blocked` colour), the folder part of the path in `dim`, the file name, and that file's `+` and `−` counts. The open file has the `selected` background.
- **Diff**, terminal font (`settings().font_family`, else JetBrains Mono) at 11px, 20px rows: a 30px right-aligned line number in `dim`, then the text. Added rows have an `ansi2` tint, removed rows an `ansi1` tint (the colour plus `18` alpha). Hunk headers (`@@ ... @@`) are `dim` on `raised`. A horizontal scrollbar is always shown under the diff, and a vertical one over it.
- **Commit bar**, 1px line above, 10px padding: a 32px field with the placeholder "Commit message" (border turns `accent` while you type) and a `Commit` button, `solid` when it can be used.
- Messages in `dim`: "Loading changes…", "No uncommitted changes", "No folder", "Not a git repository", "Select a file to view its changes", "Showing the first 1,000 changed files". A failed commit shows its error in `ansi1` above the commit bar.

## How it behaves

Added by this clone:

- **Wrap button**: click to switch between wrapping and sideways scrolling. The tooltip reads "Wrap long lines" when off and "Long lines wrap. Click to scroll sideways instead" when on. The choice is remembered.
- With wrap on, a line longer than the panel is split into extra rows. A split falls after the last space in the line's second half, else in the middle of a word. Only the first row of a line has its line number; the others keep the tint. Hunk headers are never split. Resizing the panel wraps again.
- With wrap off, the diff is as wide as its longest line and scrolls sideways, as shipped.

As the shipped `changes` mod:

- It follows the focused pane's folder (else the space's) and shows that repository's changes against `HEAD`, untracked files included.
- The first file's diff shows until you pick another. Click a file to show its diff; click the open file to close it.
- Enter in the field or a click on `Commit` stages everything and commits it with the message. Escape leaves the field.
- It refreshes when the repository changes on disk and every 10 seconds.
- Rows show the `hover` background under the pointer. It draws no agent status.

## Built from

One mod, `changes-flat`, a clone of the shipped `changes` mod (0.1.16; `mod.json` has `"place": "none"` and `cloned_from`). It takes no `props`. Put it in a layout block: `"content": { "mod": "changes-flat" }`.

The whole difference from the shipped mod:

- The root element has no `.rounded(10)` and no `.border_1().border_color(t.border)`.
- `svg` is imported from `gpui-kit` and `text-wrap.svg` is added (a 24 by 24 line icon, stroke `currentColor`, read from `mods/changes-flat/text-wrap.svg`).
- `this.wrap` starts from `localStorage.getItem("wrap") === "1"`; `toggleWrap` flips it and stores `"1"` or `"0"`.
- The header gets the button `changes-wrap` between the spacer and the totals. Its `on_mouse_down("left")` stops propagation.
- The horizontal scroll container `changes-diff-x` gets `.mode("always")` and an `on_size_change` that keeps its size in `this.diffSize` and redraws when wrap is on.
- `shownRows()` returns the rows to draw. With wrap on it computes `columns = max(20, floor((width - 60) / 6.7))` (60px for the number gutter, 6.7px per character) and calls `wrapRows`, which splits each row whose text is longer into rows of at most `columns` characters. The result is cached per row set and column count.
- The virtual list (`v_virtual_list("changes-diff", rows.length, 20, ...)`) draws those rows, and the inner element's `min_w` is 0 with wrap on instead of the diff's width.

Unchanged from the shipped mod:

- `herdr` functions: `spaces`, `panes`, `focused`, `exec`, `readTextFile`, `watchFolder`, `theme`, `settings`. UI: `InputState`, `Input`, `Scrollbar`, `v_virtual_list`.
- Programs it runs: `git` only. Reads with `--no-optional-locks -c core.fsmonitor=false -c diff.autoRefreshIndex=false`: `rev-parse --show-toplevel`, `status --porcelain=v1 -z --no-renames --untracked-files=all`, `rev-parse --verify HEAD`, `diff HEAD --numstat -z --no-renames`, `diff HEAD --no-ext-diff --no-textconv --no-color -- <path>`. Writes: `git add -A`, then `git commit -m <message>`.
- It runs no commands.

## Watch out

- It runs `git`, and `Commit` stages every change in the repository (`git add -A`) before committing. It reads files outside its own folder. Tell the person before adding it.
- The diff is a virtual list with a fixed row height of 20px, so a row cannot grow. Wrapping therefore makes more rows, it does not let text flow.
- The width per character is an estimate (6.7px at 11px). With another font or size a row can still be a little too long; each row is truncated, so the overshoot is cut off, not drawn over its neighbour.
- Wrapping only starts after the diff area has reported its size once.
- A tab is drawn as nothing by text elements; the shipped code pads each to the next 4-column stop. Keep that, the wrap counts those characters.
- A panel without a border needs a layout that draws the lines: a `gap` of 1 between blocks over a `border`-coloured background.
- Do not edit the shipped `changes` mod; clone it (`mod.clone { name: "changes", as: "changes-flat" }`) and change the clone. Herdr never updates a clone, so merge shipped changes in after an app update.
- The tab bar's Changes button points at the layout block with id `changes`. Keep that block id.
- Limits: 1,000 files, 1,500 diff lines per file, 4,000 characters per line, 400,000 characters of a new file.

## Done when

- `herdr-app check` passes on `changes-flat`.
- In a layout block the panel has square corners and no line of its own around it.
- In a repository with a changed file, the file is listed and its diff shows without a click.
- With a diff line wider than the panel: the horizontal scrollbar is visible; a click on the wrap button turns it `accent` and the line continues on the next rows, with one line number.
- Making the panel narrower with wrap on splits the line into more rows.
- The wrap choice is still set after the app restarts.
- Typing a message and pressing Enter commits, and the list empties.
