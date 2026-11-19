# herdr-mods

One person's Herdr setup, shared as inspiration: seven mods and a layout, one folder each. Nobody is expected to take it whole. The person asking decides what they want and how it should differ from what is here.

**The items:**

| Folder | What it is | Needs |
|---|---|---|
| `agent-cards` | The Agents list as cards with a robot avatar, a context bar and a timer | |
| `timed-tabs` | The tab bar with a timer on tabs whose agent is working | |
| `space-folders` | The Spaces list as a tree of folders | `project-picker` |
| `project-picker` | A picker that opens a project as a space with an agent running | |
| `shortcuts` | A side panel page with every keyboard shortcut | `timed-tabs` |
| `run-configurations` | A Run tab for JetBrains run configurations. Windows only | `timed-tabs` |
| `pr-inbox` | A bar with your open pull requests | GitHub CLI |
| `borderless` | The layout that has a place for all of the above | |

Each folder has its own `RECIPE.md`, which is the full description of that item, and a `README.md` with pictures to show the person.

**Given the URL of the repository itself ("add this layout: …/herdr-mods/tree/master"), asked for everything, or for "the mods" without naming them:**

Do not install the set in one go. Before copying anything:

1. Show the list above, with one line per item and the link to its `README.md` for the pictures.
2. Say per item what it changes that the person will notice: which part of the window it replaces, which keys it takes (`project-picker` takes `ctrl-shift-n` from "New space"), what it runs or fetches (`agent-cards` fetches avatars from `api.dicebear.com`, `pr-inbox` calls `gh` every five minutes, `run-configurations` starts programs).
3. Ask which items they want, and whether they want the `borderless` layout or the mods placed in the layout they already have. Wait for the answer.
4. For each chosen item, ask what its recipe says to ask (the avatar style of `agent-cards`, the folders of `project-picker`, the organisation of `pr-inbox`) before installing it.

Then install the chosen items one at a time, each by its own `RECIPE.md`, and check each before starting the next. Add what an item needs along with it, and say so.

**Given the URL of one folder, or asked for one item:**

Follow that folder's `RECIPE.md`. The person named it, so no further confirmation is needed beyond what the recipe itself tells you to ask.

**Changing instead of copying:**

A request such as "like agent-cards, but with my own avatars" or "the PR bar, but for GitLab" is the intended use. Build from the recipe and change what was asked. The files here are one working answer, not the only one.

**Watch out:**

- Switching the layout and rebinding a key are changes the person sees at once. Never do either without having asked.
- `Install.ps1` in this folder installs everything without asking. It is for the person at their own keyboard. Do not run it for a request that came to you unless they ask for the script by name.
- `config.js` files hold what differs per person and ship empty. Fill them from the person's answers, not from guesses.
