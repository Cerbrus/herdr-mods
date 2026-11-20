# CLAUDE.md

Mods and a layout for the Herdr desktop app, public, shared with other people. `README.md` says what each mod does for the person using it; this file is for working on them.

## Layout of the repo

One folder per item, laid out like the app's home (`~\.config\herdr-app`), which is Herdr's own convention for sharing:

```
<item>/
  mods/<name>/     main.js, mod.json, assets, maybe config.js
  keys.json        the keys the item expects (optional)
  README.md        for people: what it does, pictures, setting it up, using it
  RECIPE.md        for agents: the brief another agent builds it from
  preview.png      plus any other picture the README shows
borderless/        the layout (layouts/borderless.json) with its own three mods
upstream/          shipped files the clones were made from; never edit by hand
Install.ps1        copies items to the app, merges keys, fits the layout; -Pull copies back
Merge-Upstream.ps1 three-way merges a Herdr update into the clones; Install.ps1 runs it first
```

Folders and mod ids are the readable names (`agent-cards` is Agent Cards). `run-configurations` holds two mods (`run-configurations` and `run-menu`), `borderless` three (`borderless-files`, `borderless-changes`, `borderless-tabs`). People install mostly through their Herdr agent, pointed at an item's folder on GitHub, so everything an agent needs to add an item must be in that folder. What an item needs is the `$needs` table at the top of `Install.ps1`; keep it, the README table and the recipes in step.

## Rules

- **Nothing personal in the repo.** Folders, organisation and repository names, and anything else that differs per person goes in the mod's `config.js`, shipped empty with a commented example. `main.js` reads it as `import * as config from "./config.js"` with a default for every value, so an older `config.js` keeps working when a value is added. `Install.ps1` copies `config.js` once and never overwrites or pulls it.
- **Each mod works without the others**, apart from what `$needs` names. A mod finds out what else is there at run time: a block in `layout()`, a key in `shared()`, or `readTextFile` on `mods/<name>/main.js` under `appHome()`. A mod cannot import from another mod's folder.
- **Keys go in the item's `keys.json`**, not in `Install.ps1`. A key in the `global` section must be free in Herdr's defaults or the installer leaves it alone without `-Rebind`.
- **Scripts are Windows PowerShell 5.1 compatible**, non-elevated and idempotent: no `&&`/`||`, no ternary or null-coalescing, `$PSScriptRoot` for paths. Test the installer against a copy of the app home: `$env:HERDR_APP_HOME = '<copy>'`.
- **Mod work happens in the live folder**, which the app hot-reloads, and is pulled afterwards with `Install.ps1 -Pull`. Verify with `herdr-app check <mod folder>` and `herdr-app shot`; the app's own reference is `~\.config\herdr-app\AGENTS.md`. `herdr-app` is at `%LOCALAPPDATA%\Programs\herdr-app\herdr-app.exe` when it is not on PATH.
- **A changed mod gets its `README.md` and `RECIPE.md` brought up to date** in the same change, and the root README when the change shows there.
- **The flat tab look exists twice**, in `borderless-tabs` and in `timed-tabs`. Change it in both.
- **Previews are public.** A screenshot of a real window shows space names, branch names and pull request titles. Take previews from a second Herdr with demo data: start `herdr-app` with `HERDR_APP_HOME` set to a short scratch folder (its socket path has a length limit) and `HC_SESSION` set to a name of its own, with the `HC_*` variables of the current terminal unset. It gets its own core and none of the real spaces. Install into it with `Install.ps1`, open spaces on scratch repositories with `herdr-app do space.new`, and fake an agent with a script that prints `ESC ] 7501 ; state=working:app=claude-code ESC \`. Stop it with `herdr-app do window.close` and `hc server stop`, both with the same variables set.

## How the mods fit together

- Clones of what Herdr ships: `space-folders` (`spaces`), `agent-cards` (`agents`), `timed-tabs` and `borderless-tabs` (`tabs`), `borderless-files` (`files`), `borderless-changes` (`changes`), `run-menu` (`new-menu`) and the `borderless` layout (`main`). The app never updates clones, and shipped mods must not be edited directly.
- `space-folders` keeps its folder menu and dialogs inside itself (`folder-edit.js`) and opens itself as an overlay with `props.mode`. `spaces.folders` in the shared state holds the folders; `spaces.folders.incoming` is how `project-picker` tells the list which folder a new space belongs in.
- `agent-cards` draws agents as cards with a DiceBear avatar and a context bar. The bar reads `data\claude-statusline\<HC_TERMINAL_ID>.json` under the app's folder, which a Claude Code status line script outside this repo writes. An agent idle for over 16 hours sleeps: its avatar is the upright SVG rewritten to lie in a bed under a sheet, cached as a second file, with Z's (`z.svg`) rising from its head. It puts `agents.changed` in the shared state.
- `timed-tabs` shows a timer per working tab from `agents.changed`, or from when it first saw the tab working. Its `+` opens `run-menu` when that is installed, else `new-menu`; its Keys button shows when `panel-body` has a `shortcuts` child, its Git button when it has a `graph` child.
- The `graph` block of the layout holds `git-graph`, a mod of https://github.com/rabeeh-ta/herdr-git-graph that is not in this repository. `Install.ps1` leaves the block out where the mod is missing. The mod draws a 1px border of its own, which doubles the layout's seam: after installing or updating it, take `.border_1().border_color(t.border)` off the root element in `render()` of its `graph.js`.
- `run-menu` adds a "Start a run config…" row that opens `run-configurations` as a tab. `run-configurations` reads the JetBrains run configurations (`.run\*.run.xml`) of the folder or the nearest parent that has them. Its processes are herdr-core terminals without a pane (`hc run --bg`), found again by their `runcfg.dir` and `runcfg.name` labels.
- A mod cannot refuse to close and its `close()` gets 250 ms, so the waiting close of a Run tab goes through `timed-tabs`: its close button, middle click and `timed-tabs.close` put `run-configs.close` in the shared state when `run-configs.live` says that space has running processes, and the copy with that `space` prop stops them and closes the tab itself. `close()` kills what is left on any other route.
- `localStorage` is per mod copy and gone with the tab, so the picked run config and the favorites live in the shared state (`run-configs.picks`).
- `ctrl-shift-r` is bound to `timed-tabs.run`, because a key only reaches a mod that is on screen: `timed-tabs` selects the space's tab named `Run` or opens one, and starts nothing.
- `pr-inbox` is the `prs` block between `work-body` and `status`: one `gh api graphql` call every five minutes. It folds by resizing its own block (`layout.resize`), so the block's height is the collapsed state; `work-main` wraps `work-body` and `prs` only so that edge can be dragged while `work` stays `resizable: false`. The icon in front of a row starts its agent with the prompt as the `task` of `tab.new` or `space.new`, which sends it at once; every task text starts with "When I say go," so the agent waits.
- `borderless-changes` wraps long diff lines on request by splitting them into extra rows of the fixed-height virtual list, from an estimated character width.

## Things the app's docs don't say

- A popup is as tall as its content, so a scroll container (`overflow_y_scrollbar` with `min_h(0)`) inside one collapses to nothing and the popup shows empty.
- `cx.notify()` in a mouse-down handler redraws the element and swallows its `on_click`. Folder headers therefore fold on mouse-up, comparing against the header that was pressed.
- Elements only exist after a redraw: the drop zones on folder headers are drawn while a header is held, so the press has to `cx.notify()`.
- A negative `gap` is ignored and touching 1px borders make a 2px seam. The layout gets 1px seams from a `gap` of 1 over a `border`-coloured `work-body` background, with no visible borders on panes or panels.
- A pane's `focus` ring takes space: without a `border` of the same width the terminal resizes when focus moves. The pane border is 1px in the `background` colour for that reason.
- `lone: false` drops the whole frame of a tab's only pane, header included, not just the border and focus ring.
- `image()` only shows files under the app's folder, not URLs, draws an animated SVG as a still, and caches by path: a rewritten file keeps its old picture until the app restarts, so the cached avatar's file name carries a hash of the style.
- Lines and curves are drawn with `PathBuilder` and `window.paint_path(path, color)` (the global `window`, not the one from `herdr`); the element needs a size and coordinates are relative to it. The builder mutates, and one path can hold several `move_to` strokes.
- A mod cannot see key presses or which command a shortcut ran: `on_key_down` only fires while the mod has the keyboard, and the only other route is binding a key to `<mod>.<command>`, which replaces what the key did.
- `herdr-app check` passes on mods that render nothing or mis-handle input; it only proves the mod loads. It also writes `jsconfig.json` and `.d.ts` files into the folder it checks (ignored by git). Clicking, dragging and popups need a person or a screenshot.
- `.transition()` only animates while Windows "Animation effects" (Settings > Accessibility > Visual effects) is on; with it off every change jumps to its end value. Several properties animate when each sits on its own nested element with its own `id`; several transitions on one element were never seen working. `.loop()` only swings back and forth, with no delay or phase, so a one-way motion that restarts is a transition plus a timer that resets it. The Z's over a sleeping bot work this way.
- `herdr-app shot` shows animated properties at their resting value, so motion cannot be checked from screenshots. It needs a person.
