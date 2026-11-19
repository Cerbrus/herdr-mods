# Tabs timer

The tab bar across the top of the window, with flat tabs that fill the bar's height and are separated by 1px lines. A tab whose agent is working shows how long it has been working. Dragging a tab shows where it will land, a middle click closes a tab, and next to Files and Changes there is a Keys button when the layout has the cheatsheet panel.

![Tabs timer](preview.png)

**What you see:**

Left to right, in a bar drawn for a 42px high block, on the `chrome` background with a 1px `border` line under it:

- The tabs of the active space, starting flush at the left edge. Each is as high as the bar, has 10px side padding, no rounded corners, no gap to the next, and a 1px `border` line on its right. The active tab has the `raised` background and `foreground` text, the others `chrome` and `muted`; hover gives `hover`. Type is 12.8px. Inside a tab, 7px apart:
  - the program's 14px icon, when it has one;
  - the name, cut off at 170px, with " Z" after it while the tab is zoomed;
  - the timer, 11px in `dim`, only while an agent in the tab is working: "<1m", "7m", "1h 4m";
  - the status: a 12px spinner in `working`, or a 6px dot in `blocked` or `done`;
  - on the active tab, a 12px close cross in `dim`.
- A 26px "+" button.
- Panel buttons, 26px high, 12px type, a 14px icon and a label: "Files", "Changes", and "Keys" when the layout has the cheatsheet panel. The button of the open panel has the `selected` background.
- Where the app draws its own window buttons in the bar (`window().buttons`): minimize, maximize or restore, close, 26px each. On Windows they are 16px line icons.

**How it behaves:**

- Working: the tab shows the timer and the spinner. The timer counts from the moment the tab's working agent last changed status when `agents-bots` is installed, otherwise from the moment this bar first saw the tab working. It disappears when the agent stops working and is redrawn every 30 seconds.
- Blocked and done: a 6px dot in that status colour, no timer. Idle: neither.
- Click a tab: selects it. Double click: renames it. Right click: the shipped tab menu.
- Middle click a tab, or click the cross on the active tab: closes it.
- Drag a tab: the dragged tab goes to 50% opacity and a 2px `accent` line marks the gap where it will land: after a tab when the pointer is over its right half, before it over its left half. Releasing moves it there; no line shows while the drop would leave it where it is. Releasing outside the tabs cancels.
- Scroll wheel over the bar: previous or next tab, as shipped.
- "+": opens the `new-menu-run` popup when that mod is installed, the shipped `new-menu` popup otherwise.
- Files, Changes, Keys: show that panel, or hide the panel when it is the one showing. Which panel a space had open is remembered per space, Keys included.
- `tabs-timer.close`: closes the active tab of the active space, the same way the cross does.
- Closing a Run tab (cross, middle click or `tabs-timer.close`): when the `run-configs` mod reports running processes for that space, the first close asks that tab to stop them and close itself; a second close of the same tab closes it at once. Any other tab closes at once.
- `tabs-timer.run`: only when `run-configs` is installed. Selects the active space's tab that holds `run-configs` or is named "Run", or opens a new tab named "Run" with that mod. It starts no process.
- Everything else (tab names following the agent's title, keeping the active tab in view, the macOS traffic light padding, the per-space panel memory) behaves as the shipped `tabs` mod 0.1.16.

**Built from:**

- One mod, `mods/tabs-timer/` (`main.js`, `win-min.svg`, `win-max.svg`, `win-restore.svg`, `win-close.svg`, `mod.json`), a clone of the shipped `tabs` mod 0.1.16. `mod.json`: `{ "place": "none", "title": "Tabs", "cloned_from": { "name": "tabs", "version": "0.1.16" } }`. It takes no `props`. Start from the shipped `tabs/main.js` and add what follows.
- Layout: the block where `tabs` was, `"content": { "mod": "tabs-timer" }`, with `"size": { "px": 42 }` (the shipped bar is 30px) and `"window_drag": true`. The Keys button needs a child block with id `cheatsheet` in the `panel-body` stack.
- Tabs: `.h_full()` in place of `h(29)`, no `rounded`, `.border_r(1)` in `border` in place of the 1px box (plus `.border_l(1)` on the first tab when the macOS padding applies), no `gap` on the `tab-scroll` row, and a left padding of 0 where the shipped bar uses 10.
- Timer: `agents().find(a => a.tab === tab.id && a.status === "working")`, then `shared("agents.changed")?.[address]?.at`, falling back to a time kept in memory per tab. `cx.timer.every(30000)` redraws.
- Drag: `on_mouse_move` on each tab works out the slot from `e.local_position.x` against `e.bounds.width / 2` and stores it; the line is an absolutely placed 2px `div` on the tab before the slot (on the left of the first tab for slot 0). The drop runs `tab.move` with the 1-based index of the tab at the landing place.
- Close: `on_mouse_down("middle")` and the cross call one function. It runs `tab.close` unless `shared("run-configs.live")?.[space.id]` is set, a pane with `mod === "run-configs"` is in the tab and `shared("run-configs.close")?.tab` is not this tab; in that case it does `setShared("run-configs.close", { space, tab, at: Date.now() })` and leaves the closing to `run-configs`.
- Commands, read in a `nextCommand()` loop: `run` and `close`. `run` uses `tab.select`, or `tab.new` with `{ name: "Run", space, mod: "run-configs", props: { folder, space } }`, where `folder` is the focused pane's `cwd` or the space's folder.
- Other mods: found once in `init` by reading `mods/new-menu-run/main.js` and `mods/run-configs/main.js` under `appHome()` with `readTextFile`. "+" opens `{ mod: "new-menu-run", kind: "popup", width: 250, height: 543 }` or `{ mod: "new-menu", kind: "popup", width: 250, height: 512 }`.
- Keys button: shown when `find(layout(), "panel-body")` has a child with id `cheatsheet`; `cheatsheet` is then added to the list from `shared("workspace.panels")` (default `["files", "changes"]`) that the per-space memory accepts. It runs `layout.select` with `{ stack: "panel-body", child: "cheatsheet" }` and `layout.show` with `{ id: "panel" }`, or `layout.hide`.
- Other `herdr` calls: `spaces`, `panes`, `theme`, `window`, `settings`, `openOverlay`; commands `tab.prev`, `tab.next`, `tab.rename`, `window.minimize`, `window.maximize`, `window.close`. `localStorage`: `panels`.
- Art: its own four 16px window icons with a 1px stroke in `currentColor`, at `mods/tabs-timer/win-*.svg`. From other mods: `mods/workspace-chrome/spinner.svg`, `mods/pane/close.svg`, `mods/files/file.svg`, `mods/changes/changes.svg`, `mods/cheatsheet/keyboard.svg`, and the shipped `menu` mod for the right-click menu.

**Watch out:**

- The flat tabs assume the 42px block. The shipped bar is 30px; set the block's size in the layout.
- A clone must point at its own art: the window icons are `mods/tabs-timer/win-*.svg`, not `mods/tabs/...`.
- The mod has no `keys.json`. `tabs-timer.run` and `tabs-timer.close` do nothing until a key is bound to them; in this repo the `run-configs` mod's `keys.json` binds `ctrl-shift-r` and `ctrl-shift-w`. A key only reaches a mod that is on screen, which is why these commands live in the tab bar and not in the Run tab.
- The check for installed mods runs once. A mod installed later is picked up when the bar reloads; until the check finishes "+" opens the shipped menu.
- Without `agents-bots` the timer starts at "<1m" when the bar first sees the tab working, also after a reload of the bar. With it, the time comes from `agents.changed` and survives restarts.
- With several agents in a tab the timer follows the first working one in `agents()`.
- `cx.notify()` is needed on mouse move and mouse up for the drop line to appear and go; only notify when the slot changes, or every pointer move redraws the bar.
- A tab can only be dropped on a tab. To move one to the end, release over the right half of the last tab.
- The waiting close only works with `run-configs`: it must keep `run-configs.live` up to date and act on `run-configs.close`. A stale `run-configs.live` entry would leave the first close without effect.
- The Keys icon is read from the `cheatsheet` mod's folder; the button shows by the layout node alone, so a layout with the block but without the mod shows a button whose icon file is missing.
- Dragging and the timer cannot be checked from `herdr-app shot`; they need a person.

**Done when:**

- `herdr-app check mods/tabs-timer` passes.
- In a 42px block the tabs touch the top and bottom of the bar, with 1px lines between them and no rounded corners.
- A tab whose agent is working shows "<1m" and after a minute "1m" next to the spinner; the timer goes when the agent stops.
- Dragging the first tab over the right half of the third shows a 2px line after the third and drops it there.
- A middle click on a tab that is not active closes it.
- With a `cheatsheet` child in `panel-body` a Keys button shows after Changes, opens that panel and hides it on a second click; without the child there is no button.
- With only this mod installed, "+" opens the shipped menu and `tabs-timer.run` does nothing.
