# Cheatsheet

A side panel titled "Keys" that lists every keyboard shortcut the app currently has, read live from its key bindings. Shortcuts are grouped by where they work and by what they act on, each with a short description and the keys drawn as small key caps. A filter box at the top narrows the list as you type.

![Cheatsheet](preview.png)

**What you see:**

Top to bottom, on the `background` colour, 13px type in `foreground`:

- A 42px header with "Keys" in semibold, 14px from the left, and a 1px `border` line under it.
- The filter: a 30px high box with 8px corners and a 1px `border` outline, 10px away from the panel edges, with the placeholder "Filter shortcuts" and 12px text. A 1px `border` line under this region too.
- The list, scrolling, with 6px side padding and a scrollbar laid over its right edge:
  - A section heading in semibold for each place a binding applies, in the order the app lists them: "Everywhere" for `global`, "In a terminal" for `terminal`, "In the <name> layout" for `layout:<name>`, "In <name>" for `mod:<name>`.
  - Under it, group headings in 11px `dim`, always in this order and only when they have rows: "Spaces", "Tabs", "Panes", "Agents", "Terminal", "Layout", "App", "Mods", "Other".
  - One row per shortcut: at least 30px high, 8px side padding, 6px corners. On the left the description in `muted`, cut off when too long, followed by the command's argument in `dim` (at most 110px) when it has one. On the right the keys: one chip per modifier and one for the key, 3px apart. A chip is 20px high, at least 20px wide, with 5px side padding, 4px corners, a 1px `border` outline, the `raised` background and 11px text.
  - A shortcut bound to several key combinations shows them under each other, right-aligned, 3px apart.
- "No shortcut matches" in `dim` when the filter leaves nothing.

**How it behaves:**

- Typing in the filter narrows the list at once. It matches, without regard to case, the description, the argument, the command name (`tab.close`) and the keys written as sorted modifiers joined by `-`, then `+`, then the key (`ctrl-shift+w`). Sections and groups without matching rows disappear.
- Hovering a row gives it the `hover` background. Clicking a row does nothing.
- Chip text: `ctrl` "Ctrl", `alt` "Alt", `shift` "Shift", `cmd` "Win", `fn` "Fn"; arrows as "←" "→" "↑" "↓"; "PgUp", "PgDn", "Backspace", "Ins", "Del", "Esc", "Enter", "Tab", "Space"; a single character in upper case; any other key name with its first letter in upper case.
- Descriptions come from the app's own command list: the first clause of the command's text, up to the first ". ", " (", ", " or ` to the "`. A command the app does not describe shows its name.
- A binding that hands the key to the terminal reads "Goes to the program"; one that sends a sequence reads "Types a control sequence into the program". Both sit under "Terminal".
- A run of numbered bindings, where the key is one digit and the command's argument is that same digit (`ctrl-1` for `tab.select:1` up to `ctrl-9`), is folded into one row whose key chip reads "1–9": the lowest and highest digit with an en dash.
- Three mod commands have fixed descriptions: `agents-bots.top` "Show the agent at the top of the Agents list" (under Agents), `tabs-timer.close` "Close the tab; a Run tab stops its processes first" and `tabs-timer.run` "Show the Run tab of this space, with its run configs" (both under Tabs).
- It shows no agent status and nothing in it moves.

**Built from:**

- One mod, `mods/cheatsheet/` (`main.js`, `keyboard.svg`, `mod.json`). Not a clone. `mod.json`: `{ "place": "none", "title": "Keys" }`. It takes no `props`.
- Layout: a child block of the `panel-body` stack, next to the Files and Changes blocks: `{ "id": "cheatsheet", "type": "block", "content": { "mod": "cheatsheet" } }`.
- The button that selects it is not part of this mod. The `tabs-timer` mod draws a "Keys" button when `panel-body` has a child with id `cheatsheet`, and runs `layout.select` with `{ stack: "panel-body", child: "cheatsheet" }` and `layout.show` with `{ id: "panel" }`.
- `herdr` functions: `keys()` for the bindings (`{ section, keys, action }`), `commands()` for each command's `about`, `theme()`. It runs no commands, no programs, reads no files and does not reach the network.
- Parsing a binding: strip the prefixes `ctrl-`, `alt-`, `shift-`, `cmd-`, `fn-` off the front of `keys` one at a time, as long as something is left after the prefix; the rest is the key. Split `action` at the first `:` into command name and argument. The group is the part of the command name before the first `.` when it is one of `space`, `tab`, `pane`, `agent`, `terminal`, `layout`, `app`, `mod`, otherwise `other`.
- Rows are keyed by section plus action, so the same action bound twice in one section becomes one row with two key combinations.
- Components: `InputState.new({ placeholder })` with a `change` listener and `Input.new(state)` for the filter; the list is a `v_flex().id("cheatsheet-list").absolute().inset_0().overflow_y_scroll()` inside a `relative` `flex_1().min_h(0)` box, with `Scrollbar.vertical("cheatsheet-list").absolute().inset_0()` over it.
- Art: `keyboard.svg`, a 24 by 24 keyboard outline with a 1.5 stroke in `currentColor`. The mod does not draw it itself; `tabs-timer` uses it as the icon of the Keys button, from `mods/cheatsheet/keyboard.svg`.

**Watch out:**

- On its own the panel cannot be reached: nothing in the shipped tab bar selects a third child of `panel-body`. It assumes `tabs-timer`, or another control that runs `layout.select` for it.
- The block id must be `cheatsheet` and the mod folder must be `mods/cheatsheet`; `tabs-timer` looks for both names.
- The scroll area needs a parent with a size: `flex_1().min_h(0)` and `relative`, with the list absolutely filling it. A scroll container without `min_h(0)` grows with its content and never scrolls.
- The filter box stops `on_mouse_down("left")` from travelling up; keep that when rebuilding.
- `cmd` is labelled "Win". On macOS that label is wrong; change it there.
- The filter matches keys as `ctrl-shift+w`, modifiers in alphabetical order. Typing `ctrl+shift+w` or `shift-ctrl` finds nothing.
- The "Mods" group only catches commands whose name starts with `mod.` (such as `mod.open`). A mod's own command (`<mod>.<command>`) lands under "Other" with its bare name, unless it is one of the three in the fixed table. Add your own mods' commands to that table.
- The folded number row shows lowest to highest even when digits in between are not bound.
- A numbered run is only folded when all its bindings use the same modifiers; `ctrl-1` and `alt-2` for the same command make two rows.
- The description is cut at the first comma or bracket, which can shorten a command text more than intended; check the list after an app update changes those texts.
- The list is built from `keys()` on every draw. There is no paging or limit.

**Done when:**

- `herdr-app check mods/cheatsheet` passes.
- With the block in `panel-body` and `tabs-timer` in the tab bar, the Keys button opens a panel headed "Keys".
- The list starts with "Everywhere" and shows a row for every binding in the app's `keys.json`, with the same keys.
- Typing "tab" in the filter leaves only rows about tabs; typing "zzzz" shows "No shortcut matches".
- Bindings `ctrl-1` to `ctrl-9` for one command show as a single row with the chips "Ctrl" and "1–9".
- A binding added to `keys.json` shows up in the list the next time the panel draws after the app has loaded the file.
