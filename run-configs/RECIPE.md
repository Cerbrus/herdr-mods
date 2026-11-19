# Run configs

A tab named `Run` that lists the JetBrains run configurations (`.run\*.run.xml`) of the folder you are in, starts the one you pick and shows every process it started as a row you can unfold into its output. A compound configuration starts all its members; .NET projects are built once before they start. The `+` in the tab bar gets a "Start a run config…" row that opens the tab. Windows only.

![Run configs](preview.png)

## What you see

Top to bottom, 12px text on the `background` colour:

- **Toolbar**, 34px, `chrome` background, 1px `border` line below. Left: the picked run config as a button (24px high, at most 320px wide, `raised` background, semibold name, `▾` or `▴`); without a pick it reads "Pick a run config". Its tooltip is the folder that holds `.run`. Next to it `2/5 running` (`ansi2` when something runs, else `dim`), and while a job is under way a braille spinner in the `working` colour with the phase: `stopping`, `building` or `starting`. Right: `▶ Run`, `⟳ Restart all`, `■ Stop all`, `↻`, `>_ Terminal`. Buttons are 22px high, `muted` text, `border`-coloured when they cannot be used.
- **Picker** (shown when nothing is picked or after a click on the picked name): one 26px row per run configuration. A star (`★` in `ansi3`, or `☆`), the type in 11px `dim` in a 44px column (`group`, `.NET`, `exe`, `npm`, or `other`), the name, and for a compound `3 processes`. Starred rows come first, then a 1px line, then the rest; in each part compounds come before single configurations, by name. The picked row has the `selected` background. An unsupported type has a `dim` name. No configurations: "No run configurations found".
- **Process rows** (shown when a config is picked): one 26px header per process with a 1px line below. `▸` or `▾`, a status glyph, the name in semibold (200px column), then the status text; a folded row shows its last output line there instead, in the terminal font at 11px, coloured like the output. A `Build` row appears above the others once a build has run.
- **Output**, under an unfolded header: a box on the `surface` colour, terminal font (`settings().font_family`, else JetBrains Mono) at 11px, lines not wrapped, the newest 80 lines stuck to the bottom. Unfolded boxes share the height left; each is at least 48px.
- **Typing line**, 26px, under the output of a process you chose to type into: `›` and a field with the placeholder "Enter sends this to the process".
- At the bottom, when a compound has members of a type that is not supported: "Not supported, skipped: a, b" in `dim`.
- An error (no `.run` folder, unreadable files) replaces the picker and the rows, in `ansi1`.

In the `+` popup of the tab bar: a row `▶ Start a run config…` directly under `Terminal`, with the key bound to `tabs-timer.run` as its hint.

## How it behaves

Process status, shown by the glyph and the text of its row:

| State | Glyph | Text |
|---|---|---|
| Running | `●` in `ansi2` | `running` |
| Part of a job that has not started it yet | spinner in `working` | the job's phase |
| Never started | `○` in `border` | `not started` |
| Ended with a non-zero exit code | `●` in `ansi1` | `exit <code>` |
| Ended with 0, or stopped by you | `○` in `dim` | `stopped` |

- **Pick**: click a row in the picker. Click its star to keep it at the top. The pick and the stars are remembered per `.run` folder, also after the tab is closed.
- **▶ Run** starts what is not running. **⟳ Restart all** stops everything, then starts it. Both go through the same job: stop what must restart, run one `Build` for all .NET projects involved, then start. A failed build starts nothing and shows a "Build failed" notification; the `Build` row unfolds while it builds and folds again when it succeeds.
- **■ Stop all** stops every process and a running build, and cancels a job.
- **↻** reads the `.run` folder again. **>_ Terminal** splits a terminal in below, in the folder that holds `.run`.
- Row buttons: `▶` (start, builds first) or `⟳` (restart, builds first); on a running process also `■` (stop), `⌨` (opens the typing line and focuses it) and `>_` (opens the real terminal as a peek).
- Click a header to fold or unfold it. Folded rows keep showing their last line; one folded process is read per tick, in turn.
- Scroll up over an output box and it becomes a scroll area over the last 500 lines, for one process at a time; `↓ Follow` on its row returns to the newest lines.
- Output colours come from what a line says, not from the program's own colours: errors (`ERR`, `FTL`, `CRIT`, `error`, `fail`, `exception`) in `ansi1`, warnings in `ansi3`, debug and trace lines in `dim`, success lines ("Build succeeded", "Now listening on", "Compiled successfully", a check mark and the like) in `ansi2`, the rest `muted`. "0 errors" and "no warnings" do not count as errors or warnings. A leading timestamp is `dim`, a level token (`INF`, `WRN`, `info:`, `warn:`) has its own colour, and a URL is `ansi4`, underlined, and opens in the browser on click. `0.0.0.0`, `+` and `*` as host become `localhost`.
- A process of another run config that is still running stays listed after you pick a different one.
- `ctrl-shift-r` shows the space's `Run` tab, or opens one. It starts nothing.
- **Closing** stops the processes. With the tab's close button, a middle click on the tab or `ctrl-shift-w`, a tab with running processes shows "Stopping every process. This tab closes when they have ended; close it again to not wait." plus a notification, and closes itself once all have ended. Closing a second time, closing any other way, or quitting the app kills them at once.
- A new `Run` tab starts empty: ended processes and their output are removed when the tab closes after waiting, or else when a tab opens. Processes still running are picked up again.

## Built from

Two mods, both `"place": "none"`, plus the `tabs-timer` mod from this repo.

**`run-configs`** (`mod.json`: `{ "place": "none", "title": "Run configs" }`), opened as a tab with `tab.new { name: "Run", space, mod: "run-configs", props: { folder, space } }`.

- `props`: `folder` (where to look for `.run`; falls back to the focused pane's folder, the space's folder, then `home()`), `space` (the space id, needed for the waiting close), `config` (optional: a run config to pick).
- Reading the configurations: one `exec("powershell", ["-NoProfile", "-Command", ...])` that walks up from the folder to the first one with a `.run` folder, parses each `*.run.xml` (`/component/configuration`: `name`, `type`, `option` name/value pairs, `package-json`, `command`, `arguments`, `scripts/script`, `toRun`) and prints JSON. It also picks the package manager: `yarn` when `yarn.lock` sits beside `package.json`, `pnpm` for `pnpm-lock.yaml`, else `npm`.
- What a type runs, with `$PROJECT_DIR$` and `$USER_HOME$` filled in:
  - `LaunchSettings`: `dotnet run --no-build --project <LAUNCH_PROFILE_PROJECT_FILE_PATH> --launch-profile <LAUNCH_PROFILE_NAME>`, in the project's folder.
  - `RunNativeExe`: `EXE_PATH` with `PROGRAM_PARAMETERS`, in `WORKING_DIRECTORY`; a `.cmd` or `.bat` through `cmd.exe /d /c`.
  - `js.build_tools.npm`: `cmd.exe /d /c <manager> <command, default run> <scripts> <arguments>`, in the folder of `package.json`.
  - `CompoundRunConfigurationType`: its `toRun` members, nested compounds included.
  - Build: one `powershell.exe -NoProfile -Command` that runs `dotnet build <project> --nologo -v q -clp:ErrorsOnly` for each distinct project and stops at the first failure.
- Processes are herdr-core terminals without a pane: `hc run --bg --json --no-parent --no-notify --cwd <dir> --label runcfg.dir=<.run parent, lower case> --label runcfg.name=<name> -- <argv>`. They are found again with `hc ls --all --json --label runcfg.dir=...` and `hc get <address> --json`, read with `hc read <address> --lines 500`, stopped with `hc kill`, removed with `hc rm`, typed into with `hc send <address> -- <text>`.
- A 500 ms timer (`cx.timer.every`) lists the terminals, advances the job and reads output.
- Commands run: `terminal.open { folder, place: "down" }`, `terminal.peek { terminal }`, `terminal.kill { terminal }` (in `close()`), `tab.close { id }`. URLs open with `exec("explorer.exe", [url])`.
- Commands it accepts through `nextCommand()`: `run-configs.run`, `.restart`, `.stop`, `.expand`, `.collapse`. No key is bound to them.
- `herdr` functions: `exec`, `hc`, `home`, `theme`, `settings`, `run`, `props`, `shared`, `setShared`, `checking`, `spaces`, `panes`, `focused`, `notify`, `nextCommand`. UI: `InputState`, `Input`, `ScrollHandle`, `.frames()` for the spinner.
- Shared state: `run-configs.picks` (`{ <.run parent, lower case>: { selected, favorites } }`), `run-configs.live` (`{ <space id>: running count }`), `run-configs.close` (`{ space, tab, at }`, written by `tabs-timer`). `localStorage`: `open` (unfolded rows) and `folder`.

**`new-menu-run`**: a clone of the shipped `new-menu` (0.1.16). It adds one row, `Start a run config…`, which runs the `tab.new` above with the focused pane's folder (else the space's), and is 31px taller (`Math.min(522, 198 + rows * 31)`). Everything else is the shipped popup.

**`tabs-timer`** does three things for this: its `+` opens `new-menu-run` (popup, 250 by 543) when that mod is installed, else `new-menu`; `tabs-timer.run` selects the space's tab that shows `run-configs` or is named `Run`, or opens one; and its close button, middle click and `tabs-timer.close` write `run-configs.close` when `run-configs.live` has a count for that space and the tab shows `run-configs`, instead of running `tab.close`.

`keys.json`: `ctrl-shift-r` to `tabs-timer.run` in `global`, `ctrl-shift-w` to `tabs-timer.close` in `layout:main-folders`.

No art; every glyph is text.

## Watch out

- It runs programs: `powershell`, `dotnet`, `cmd.exe`, `explorer.exe`, `hc`, and whatever the run configurations name. Tell the person before adding it. It reads `.run` folders outside its own folder.
- Windows only. Paths are rebuilt with backslashes.
- Other run configuration types are listed in the picker as `other` and skipped.
- A mod cannot refuse to close and its `close()` gets 250 ms. That is why the waiting close goes through `tabs-timer` and shared state; `close()` only kills what is left.
- A key only reaches a mod that is on screen, so `ctrl-shift-r` is bound to the tab bar's command, not to `run-configs`.
- `ctrl-shift-w` is only bound in the `main-folders` layout. In another layout, bind `tabs-timer.close` there too, or the key closes the tab at once.
- `localStorage` is per mod copy and gone with the tab. The pick and the stars are in shared state for that reason; which rows are unfolded is not kept across tabs.
- Herdr does not hand a program's colours to a mod, so colouring is by pattern and can be wrong.
- `hc read` output contains `[hc] ` lines; they are dropped.
- A process you stop reports as `stopped`, not as a failure.
- Scrollback is 500 lines, the live view 80, and one process scrolls at a time.
- The "Start a run config…" row always opens a new tab. Two `Run` tabs in one space share one `run-configs.live` entry and both answer a close request.
- Without `tabs-timer` there is no way to open the tab from the tab bar and no waiting close.

## Done when

- `herdr-app check` passes on `run-configs` and `new-menu-run`.
- `+` in the tab bar shows `Start a run config…`; it opens a tab named `Run` listing the `.run\*.run.xml` files of the folder or its nearest parent that has them.
- In a folder without `.run` anywhere above, the tab says `No .run folder in <folder> or above`.
- Picking a compound and pressing `▶ Run` shows a `Build` row first when it has .NET members, then every member turns `running` with a green dot and the toolbar counts them.
- An npm configuration next to a `yarn.lock` starts through `yarn`.
- Scrolling up over an output shows older lines and `↓ Follow`; clicking a URL in the output opens the browser.
- A starred config is at the top of the picker in a new `Run` tab.
- `ctrl-shift-r` selects the existing `Run` tab instead of opening a second one.
- Closing the tab with its close button while processes run shows the stopping line, and the tab closes by itself when `hc ls --all --label runcfg.dir=...` has no live terminal left.
