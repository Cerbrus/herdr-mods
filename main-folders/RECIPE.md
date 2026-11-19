# Main folders

Herdr's `main` layout with everything flush: square panes and panels separated by 1px lines instead of rounded cards with 8px between them. A tab with one pane is only the terminal, without a header or frame. The sidebar shows spaces in folders and agents as cards, the tab bar times working agents, the side panel has a third page with the keyboard shortcuts, and a bar with your pull requests sits between the terminals and the status bar.

![Main folders](preview.png)

## What you see

Left to right, on the `canvas` background, with a 1px `border`-coloured divider between sidebar and work area and no system title bar:

- **Sidebar**, 268px wide (44 to 480), `chrome` background. Top to bottom:
  - the brand row, 46px; dragging it moves the window;
  - the spaces list and the agents list, sharing the height equally (weight 1 each, at least 90px each);
  - the footer, 69px.
- **Work area**, the rest of the width. Top to bottom:
  - the tab bar, 42px; dragging it moves the window;
  - the terminals of the active tab, and to their right the side panel, 368px wide (280 to 900), hidden until you open it. One 1px line separates them;
  - the pull requests bar, 29px when folded;
  - the status bar, 28px.

The terminals: panes are square, 1px apart, with the line between them in the `border` colour. Each pane of a split tab has a 30px header on top. The focused pane has a 1px `accent` ring; the others have a 1px edge in the `background` colour, so nothing shifts when focus moves. Terminal text is padded 14px left and right and 12px top and bottom.

The side panel has three pages, one shown at a time: Files, Changes and Keys. None has a border or rounded corners of its own.

## How it behaves

The layout itself has no behaviour; its mods do. Agent statuses (working, blocked, done, idle) are drawn by the agents list, the tab bar and the spaces list; see the recipes of `agents-bots`, `tabs-timer` and `spaces-folders`.

- `Files`, `Changes` and `Keys` in the tab bar open the side panel on that page; the button of the open page closes it. The panel's left edge can be dragged between 280px and 900px.
- A tab with a single pane shows no header, border or focus ring. Split it and every pane gets its header.
- The pull requests bar folds and unfolds by changing its own height; its top edge can be dragged.
- The sidebar and the work column have fixed sizes among their siblings (`resizable: false`), as in the shipped layout.

## Built from

`layouts/main-folders.json`, a clone of the shipped `main` layout (0.1.16, recorded in `cloned_from`).

Root look: `"background": "canvas"`, `"terminal_padding": [14, 12]`, `"divider": { "width": 1, "color": "border" }`, `"titlebar": "none"`, `"traffic_lights": [12, 16]`.

Node tree (`id`: type, size, content):

```
root: row
  sidebar: column, 268px, min 44, max 480, background chrome, resizable false
    brand: block, 46px, window_drag, mod workspace-chrome
    sidebar-lists: column
      spaces: block, weight 1, min 90, mod spaces-folders
      agents: block, weight 1, min 90, mod agents-bots
    sidebar-footer: block, 69px, mod workspace-chrome, props { footer: true }
  work: column, resizable false
    tabs: block, 42px, window_drag, mod tabs-timer
    work-main: column
      work-body: row, padding 0, gap 1, background border
        main: block, tab active (pane frame below)
        panel: column, 368px, min 280, max 900, hidden
          panel-body: stack, active files
            files: block, mod files-flat
            changes: block, mod changes-flat
            cheatsheet: block, mod cheatsheet
      prs: block, 29px, min 29, mod prs-panel
    status: block, 28px, mod workspace-status
```

Pane frame of `main`: `"header": { "content": { "mod": "pane" }, "reveal": "always", "height": 30, "position": "top" }`, `"background": "background"`, `"border": { "width": 1, "color": "background" }`, `"focus": { "width": 1, "color": "accent" }`, `"radius": 0`, `"gap": 1`, `"lone": false`.

What differs from the shipped `main`:

- Mods swapped: `spaces` to `spaces-folders`, `agents` to `agents-bots`, `tabs` to `tabs-timer`, `files` to `files-flat`, `changes` to `changes-flat`.
- `work-body`: `padding` 8 to 0, `gap` 8 to 1, and a `background` of `border`.
- Pane frame: `gap` 8 to 1, `radius` 10 to 0, border colour `border` to `background`, `lone` true to false.
- `panel-body` has a third child, `cheatsheet`.
- `work-main` is new: a column around `work-body` and the new `prs` block.

Mods from this repo, each a sibling folder with its own recipe: `spaces-folders`, `agents-bots`, `tabs-timer`, `files-flat`, `changes-flat`, `cheatsheet`, `prs-panel`. Shipped mods used as they are: `workspace-chrome` (twice, the footer with `props.footer`), `pane`, `workspace-status`. The layout passes no other `props`, runs no programs and has no art.

Fitting it to what is installed: the repo's `Install.ps1 -Layout` writes the layout so that a block whose mod is not installed shows the shipped mod it was cloned from (`spaces`, `agents`, `tabs`, `files`, `changes`), and leaves the `cheatsheet` and `prs` blocks out when those mods are missing, as they have no shipped original. An agent adding the layout by hand does the same.

## Watch out

- A negative `gap` is ignored, and two touching 1px borders make a 2px seam. The 1px lines come from a `gap` of 1 over a `border`-coloured `work-body` background, with no visible border on panes or panels. That only works with panels that draw no border themselves: `files-flat` and `changes-flat`, not the shipped `files` and `changes`, which keep their rounded border.
- A pane's `focus` ring takes space. Without a `border` of the same width the terminal resizes each time focus moves; hence the 1px border in the `background` colour.
- `lone: false` drops the whole frame of a tab's only pane, header included, not only the border and the ring. The header's buttons (split, zoom, close) are then only reachable by key or menu.
- `work` is `resizable: false`, so nothing directly inside it can be dragged. `work-main` exists only so the edge between the terminals and `prs` can be.
- `prs-panel` folds by resizing the block with id `prs`, so that block needs a pixel size and `"min": 29`. Rename the block and the mod needs `props.block`.
- The tab bar's `Files` and `Changes` buttons select the stack children by the ids `files` and `changes`, and `tabs-timer` shows `Keys` only when `panel-body` has a child with id `cheatsheet`. Keep the ids `panel`, `panel-body`, `files`, `changes`, `cheatsheet`.
- Leaving the `cheatsheet` block in without the mod gives a `Keys` button that opens an empty page; leave the block out instead.
- `spaces-folders` needs the `space-open` mod, and the timer in `tabs-timer` reads `agents.changed`, which `agents-bots` writes: with the shipped `agents` list the timer starts counting when the tab bar first sees the agent working.
- It is a clone: Herdr never updates it. After an app update, merge what changed in the shipped `main` layout.
- `traffic_lights` only matters on macOS.

## Done when

- `layout.switch { name: "main-folders" }` shows the layout without a warning about an unknown mod.
- A tab with one terminal shows the terminal only: no header, no rounded corners, no gap around it.
- After a split, each pane has a 30px header, the panes are 1px apart, and moving focus between them does not change the size of either terminal.
- `Files`, `Changes` and `Keys` in the tab bar each open the side panel on their page, with one 1px line between the terminals and the panel.
- The pull requests bar is 29px high under the terminals and unfolds on a click.
- `ctrl-shift-l` switches back to the previous layout, which is unchanged.
