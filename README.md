# herdr-mods

Mods and a layout for the [Herdr](https://herdr.dev) desktop app. Each mod installs on its own.

## What is in here

Every folder is one item, laid out like the app's own folder (`~\.config\herdr-app`): `mods/<name>/`, a `keys.json` with the keys it expects, and a `RECIPE.md` that describes it.

| Item | What it is | Needs | Keys | Yours to fill in |
|---|---|---|---|---|
| `agent-cards` | Clone of the shipped `agents` list that shows each agent as a card: a robot avatar, a context bar, the time since its status changed and the status. | | `alt-a` | |
| `timed-tabs` | Clone of the shipped `tabs` bar with flat tabs, a timer on a tab whose agent is working, and a marker for where a dragged tab lands. | | | |
| `space-folders` | Clone of the shipped `spaces` list that draws the spaces as a tree of collapsible folders. | `project-picker` | | `config.js`: the folders a first run starts with |
| `project-picker` | Picker that opens a folder as a new space running an agent. | | `ctrl-shift-n` | `config.js`: where your projects are, what a space starts |
| `borderless-files`, `borderless-changes` | Clones of the shipped `files` and `changes` panels without their rounded border. Changes also has a Wrap toggle for long lines. | | | |
| `shortcuts` | Panel that lists every keyboard shortcut, opened with Keys in the tab bar. | `timed-tabs` | | |
| `run-configurations` | Tab that runs the JetBrains run configurations (`.run\*.run.xml`) of a folder and shows the output of each process. Comes with `run-menu`, the `+` menu with a "Start a run config…" row. Windows only. | `timed-tabs` | `ctrl-shift-r`, `ctrl-shift-w` | |
| `pr-inbox` | Bar under the terminals with your open pull requests: one summary line that unfolds into To review and Mine. Needs an authenticated `gh`. | | | `config.js`: organisation, repositories, where your projects are |
| `borderless` | Layout: a clone of the shipped `main` layout that shows all of the above, with square panes and panels that sit flush, 1px lines between them. | | | |

Mods are trusted code. `agent-cards` fetches avatars from `api.dicebear.com`, `pr-inbox` reaches GitHub through `gh`, and `run-configurations` runs your run configurations. The others only read: `git`, and folder listings through `cmd`, `powershell` or `sh`.

## Install

Clone the repository anywhere, then:

```powershell
.\Install.ps1                                  # everything, with the layout
.\Install.ps1 agent-cards, pr-inbox -Layout   # two mods, in the layout
.\Install.ps1 project-picker                       # one mod, your own layout
.\Install.ps1 -List                            # the items and what each needs
```

Non-elevated and idempotent: run it again after a `git pull` to update. What an item needs is installed with it.

- **The layout.** A mod only shows where a layout puts it. `-Layout` installs `borderless`, fitted to what you have: a block whose mod is not installed shows the shipped mod it was cloned from, and the Keys panel and the pull requests bar are left out. Once the layout is there, every later install fits it again. Show it with `herdr-app do layout.switch --name borderless`; `ctrl-shift-l` switches back. For your own layout, point a block at the mod: `"content": { "mod": "agent-cards" }`.
- **Keys.** The keys in an item's `keys.json` are added to the app's `keys.json`. A key that already does something else is reported and left alone; `-Rebind` hands it to the mod. That is only `ctrl-shift-n`, which Herdr binds to `space.new`.
- **`config.js`.** Copied once, never overwritten. `project-picker` and `pr-inbox` do little until you list your project folders in theirs. Saving the file applies it at once.

Without PowerShell, ask your agent in Herdr: "add the mod from `https://github.com/Cerbrus/herdr-mods/tree/master/agent-cards`". It reads the `RECIPE.md` and copies the files.

## The mods

### Spaces folders

Folders are made and filled by hand; a space outside every folder is loose and shows above them. Inside a folder its spaces come first, then its subfolders.

- **New folder**: the folder button next to `+` in the Spaces header, or "New folder" in a folder's right-click menu for one inside it. Folders nest three levels deep at most.
- **Right-click a folder header**: New space (opens the picker; the space lands in that folder), New folder, Rename, Move to, Move up, Move down, Delete. Delete is only offered when no space is in the folder or under it; its empty subfolders go with it.
- **Move a folder**: drag its header onto another header. The top or bottom edge puts it before or after that folder, the middle puts it inside.
- **Fold**: click a folder header; a folded folder hides everything under it. Folded folders open by themselves when you go to a space, tab or agent inside them.
- **Move a space**: drag it onto a folder header or onto a space inside that folder. Drag it onto a loose space, or below the list, to take it out of its folder.

Spaces are reordered so each folder's spaces sit together. The folders and which space is in which are app state (`spaces.folders` in `~\.config\herdr-app\shared.json`). `SEED` in `config.js` names folders to start with and which open spaces go into each; it is only used the first time the list runs.

### Opening a space

The `+` in the Spaces header and `ctrl-shift-n` open the `project-picker` picker: the folders under `ROOTS` in its `config.js`, narrowed as you type; a typed full path is offered as it is. Enter opens the folder as a space that runs `ARGV` from the same file (`claude`), or shows the space already open there. The new space is loose, unless the picker was opened from a folder's right-click menu.

### Agent cards

Each agent's avatar is a [DiceBear](https://www.dicebear.com) `voxel-bot`, the same one for the same space and tab. `agent-cards` fetches it once from `api.dicebear.com`, sending only a hash of the space and tab name as the seed, and keeps it in `~\.config\herdr-app\data\agent-cards\avatars\`. The avatar bobs while the agent works, shakes sideways in bursts when it needs you and is dimmed while it is idle. `alt-a` shows the agent at the top of the list.

The context bar reads `~\.config\herdr-app\data\claude-statusline\<terminal id>.json`. Nothing in this repository writes that file: a Claude Code status line script does, [this one](https://github.com/Cerbrus/utilities/tree/master/claude-statusline) for example. Without it the bar stays empty.

An agent that has been idle for more than 16 hours moves to a folded `Inactive` group at the bottom, unless it is pinned or shown; there its avatar lies in a bed, asleep. Sorting, pinning, sub-agents and the narrow rail work as in the shipped list.

### Tab bar

A working tab shows how long its agent has been working. With `agent-cards` installed that time survives a restart; without it the bar counts from when it first saw the tab working. The `+` opens `run-menu` when `run-configurations` is installed and the shipped menu otherwise, and the Keys button shows when the layout has the Keys panel.

### Run configs

`ctrl-shift-r` shows the space's `Run` tab, opening it when there is none; it starts nothing. "Start a run config…" in the tab bar's `+` menu opens one too. The tab lists the JetBrains run configurations of the folder, or of the nearest parent that has a `.run` folder: `LaunchSettings` ones run with `dotnet run` after one `dotnet build`, `RunNativeExe` ones as they are, npm ones as `yarn`, `pnpm` or `npm run <script>` (by the lock file next to `package.json`), and compounds of those; other types are listed as skipped.

The star in front of a run config keeps it at the top, above a line. `>_ Terminal` in the toolbar splits a terminal in under the run configs. On a running process, `⌨` opens a line under its output; Enter types that line into the process.

Output is coloured by what a line says, not by the program's own colours, which Herdr does not hand to a mod: errors red, warnings yellow, debug lines dim, success lines green, URLs blue. A URL opens in the browser when clicked. An unfolded process shows its newest lines; scrolling up over them turns the box into a scroll area over the last 500 lines, until `↓ Follow` on its row.

Closing a `Run` tab stops its processes. With the tab's close button, a middle click or `ctrl-shift-w` (bound to `timed-tabs.close` in the `borderless` layout) the tab says it is stopping and closes once every process has ended; closing it again does not wait. Closed any other way, or when the app quits, the processes are killed at once.

### Keys panel

Keys, next to Files and Changes in the tab bar, opens a panel with every shortcut from the app's `keys.json`, grouped by where it works and what it acts on, each with the command's own description. The filter narrows the list by description, command or key.

### Pull requests

The bar under the terminals counts your open pull requests by what they need from you; a click unfolds it into To review and Mine. A row opens the pull request in the browser. The icon in front of a row that needs something from you finds the repository's space (or opens it from `ROOTS`), starts a new agent tab there and pastes `Review #<number>`, or `Handle feedback on #<number>` for your own pull request. It refreshes every five minutes. `OWNER` and `REPOS` in `config.js` narrow it to one organisation and to repositories by name.

## After a Herdr update

`agent-cards`, `timed-tabs`, `space-folders`, `borderless-files`, `borderless-changes`, `run-menu` and the layout are clones of what Herdr 0.1.16 ships (`cloned_from` in the files). Herdr never updates clones, so its own changes have to be merged in:

```powershell
.\Merge-Upstream.ps1 -Check    # what changed, and how it would merge
.\Merge-Upstream.ps1           # merge it into the clones in the repo
```

`upstream/` holds every shipped file a clone was made from, as it was when the clone was last brought up to date. `Merge-Upstream.ps1` compares those with what the installed Herdr app ships now. A changed file is merged into its clone with a three-way merge (`git merge-file`), the copy in `upstream/` is renewed and the clone's `cloned_from` version is raised.

`Install.ps1` runs it first, so every install says whether the shipped files changed. A merge with conflicts leaves `<<<<<<<` markers in the repo file; `Install.ps1` skips such a file until the markers are resolved. If you only use these mods, update Herdr first and then pull this repository: the merge is then already in it.

## Changing things

The Herdr app reloads a mod or layout when its live file is saved, so edit the live file, check it, then pull it into the repo:

```powershell
herdr-app check $HOME\.config\herdr-app\mods\space-folders
.\Install.ps1 -Pull
```

`-Pull` copies the live files back over the repo's copies, including new `.js`, `.json` and `.svg` files in a mod folder that is already in the repo. `config.js` files stay where they are: what the repo ships is the empty one. The layout is only pulled when every mod it names is installed. A new mod gets a folder of its own here, `<name>\mods\<name>\`, copied by hand once.
