# cmux Setup Plan

> **For implementors:** Work through tasks using the executing-plans or subagent-driven-development skill.

**Goal:** Install cmux, configure it with tmux-style keybindings, and add Claude Code integration skills to `~/.agent-stuff`.  
**Architecture:** cmux config is tracked in dotfiles at `.config/cmux/settings.json` and symlinked to `~/.config/cmux/settings.json` by `bootstrap.sh`. Two skills are added to `~/.agent-stuff/skills/` — the bootstrap script already handles symlinking those into `~/.claude/skills/`.  
**Tech stack:** Homebrew (cmux), JSON config, npm (oh-my-claudecode)

---

### Task 1: Install cmux

**Files:** none (system install)

- [ ] **Step 1: Add the Homebrew tap and install**
  ```
  brew tap manaflow-ai/cmux
  brew install --cask cmux
  ```

- [ ] **Step 2: Verify the install**
  ```
  cmux --version
  ```
  Expected: a version string is printed without error.

- [ ] **Step 3: Commit** (nothing to commit — skip)

---

### Task 2: Add cmux config to dotfiles with tmux-style keybindings

**Files:**
- Create: `.config/cmux/settings.json` (inside `~/.dotfiles`)

The keybinding mapping from tmux → cmux:

| tmux binding | action | cmux binding |
|---|---|---|
| `C-s -` | split vertical | `["ctrl+s", "-"]` → `splitDown` |
| `C-s \` | split horizontal | `["ctrl+s", "\\"]` → `splitRight` |
| `C-h/j/k/l` | navigate panes | `ctrl+h/j/k/l` → `focusPaneLeft/Down/Up/Right` |
| `C-s c` | new window/tab | `["ctrl+s", "c"]` → `newSurface` |
| `C-s r` | reload config | `["ctrl+s", "r"]` → `reloadConfiguration` |
| `C-s z` | zoom pane | `["ctrl+s", "z"]` → `togglePaneZoom` |
| `C-s n/p` | next/prev window | `["ctrl+s", "n"]` / `["ctrl+s", "p"]` → `nextWorkspace` / `previousWorkspace` |
| `C-s b` | sidebar (new) | `["ctrl+s", "b"]` → `toggleSidebar` |

Note: tmux's `C-s H/J/K/L` pane resize has no direct cmux equivalent — omit for now.

- [ ] **Step 1: Create the config file**
  ```
  mkdir -p ~/.dotfiles/.config/cmux
  ```
  Create `~/.dotfiles/.config/cmux/settings.json`:
  ```json
  // cmux settings — keybindings mirror ~/.tmux.conf where possible
  {
    "keybindings": {
      // Pane splits (C-s prefix, like tmux)
      "splitDown": ["ctrl+s", "-"],
      "splitRight": ["ctrl+s", "\\"],

      // Pane navigation without prefix (mirrors vim-tmux-navigator)
      "focusPaneLeft": "ctrl+h",
      "focusPaneDown": "ctrl+j",
      "focusPaneUp": "ctrl+k",
      "focusPaneRight": "ctrl+l",

      // Tab/workspace management
      "newSurface": ["ctrl+s", "c"],
      "nextWorkspace": ["ctrl+s", "n"],
      "previousWorkspace": ["ctrl+s", "p"],
      "toggleSidebar": ["ctrl+s", "b"],
      "togglePaneZoom": ["ctrl+s", "z"],

      // App
      "reloadConfiguration": ["ctrl+s", "r"]
    }
  }
  ```

- [ ] **Step 2: Verify the file parses**
  ```
  python3 -c "import json; json.load(open('/Users/$USER/.dotfiles/.config/cmux/settings.json'.replace('// ', '')))" 2>/dev/null || echo "Note: JSON with comments — manual check only"
  ```
  The file uses JSON-with-comments format (cmux supports this). Visually confirm the file looks correct.

- [ ] **Step 3: Run bootstrap to symlink the config**
  ```
  cd ~/.dotfiles && ./bootstrap.sh
  ```
  Expected output includes: `Linked: ~/.dotfiles/.config/cmux/settings.json -> ~/.config/cmux/settings.json`

- [ ] **Step 4: Verify the symlink exists**
  ```
  ls -la ~/.config/cmux/settings.json
  ```
  Expected: a symlink pointing to `~/.dotfiles/.config/cmux/settings.json`.

- [ ] **Step 5: Open cmux and test key bindings manually**
  - `ctrl+s` then `-` → should split the pane horizontally
  - `ctrl+s` then `\` → should split the pane vertically
  - `ctrl+h/j/k/l` → should move focus between panes
  - `ctrl+s` then `c` → should open a new tab
  - `ctrl+s` then `r` → should reload cmux configuration

- [ ] **Step 6: Commit**
  ```
  cd ~/.dotfiles
  git add .config/cmux/settings.json
  git commit -m "Add cmux config with tmux-style keybindings"
  ```

---

### Task 3: Create the `cmux-claude-teams` skill

**Files:**
- Create: `~/.agent-stuff/skills/cmux-claude-teams/SKILL.md`

This skill teaches Claude how to launch and use `cmux claude-teams` to run Claude Code with multi-pane agent support.

- [ ] **Step 1: Create the skill directory and file**
  ```
  mkdir -p ~/.agent-stuff/skills/cmux-claude-teams
  ```
  Create `~/.agent-stuff/skills/cmux-claude-teams/SKILL.md`:
  ```markdown
  ---
  name: cmux-claude-teams
  description: "Launch Claude Code with multi-pane agent support inside cmux"
  ---

  Use this skill when starting a Claude Code session that will spawn subagents or
  teammate agents, and the terminal is cmux.

  ## How it works

  `cmux claude-teams` creates a tmux shim at `~/.cmuxterm/claude-teams-bin/tmux`
  that translates tmux commands into cmux API calls. Claude Code (and tools that
  use tmux internally) think they are running inside tmux, but agents appear as
  native cmux splits with sidebar metadata and notifications.

  ## Launching

  Start a new session:
  ```
  cmux claude-teams
  ```

  Continue a previous session:
  ```
  cmux claude-teams --continue
  ```

  Use a specific model:
  ```
  cmux claude-teams --model sonnet
  ```

  ## What gets created

  - `~/.cmuxterm/claude-teams-bin/tmux` — the translation shim
  - `~/.cmuxterm/tmux-compat-store.json` — buffer and hook state

  ## Pane navigation

  Once inside a session, use the standard cmux keybindings:
  - `ctrl+h/j/k/l` — move focus between agent panes
  - `ctrl+s` then `-` — split a new pane vertically
  - `ctrl+s` then `\` — split a new pane horizontally
  - `ctrl+s` then `z` — zoom the focused pane
  - `ctrl+s` then `b` — toggle the workspace sidebar

  ## Steps

  1. Confirm cmux is running (not a plain terminal).
  2. Run `cmux claude-teams` (or `--continue` to resume).
  3. Claude Code launches; subagents will open as native cmux splits.
  ```

- [ ] **Step 2: Run bootstrap to create the symlink**
  ```
  cd ~/.dotfiles && ./bootstrap.sh
  ```
  Expected output includes: `Linked skill: ~/.agent-stuff/skills/cmux-claude-teams -> ~/.claude/skills/cmux-claude-teams`

- [ ] **Step 3: Verify the symlink**
  ```
  ls -la ~/.claude/skills/cmux-claude-teams
  ```
  Expected: a symlink pointing to `~/.agent-stuff/skills/cmux-claude-teams`.

- [ ] **Step 4: Commit** (no git commit needed — `~/.agent-stuff` is outside the dotfiles repo; bootstrap handles the wiring)

---

### Task 4: Create the `cmux-workspaces` skill

**Files:**
- Create: `~/.agent-stuff/skills/cmux-workspaces/SKILL.md`

This skill teaches Claude how to manage cmux workspaces during development (creating, navigating, and organizing workspaces per project or feature).

- [ ] **Step 1: Create the skill directory and file**
  ```
  mkdir -p ~/.agent-stuff/skills/cmux-workspaces
  ```
  Create `~/.agent-stuff/skills/cmux-workspaces/SKILL.md`:
  ```markdown
  ---
  name: cmux-workspaces
  description: "Manage cmux workspaces for organizing development sessions"
  ---

  Use this skill when creating, navigating, or organizing cmux workspaces. Workspaces
  in cmux are roughly equivalent to tmux sessions — each holds a set of panes/tabs
  for a project or context.

  ## Keyboard shortcuts (configured in ~/.config/cmux/settings.json)

  | Action | Binding |
  |---|---|
  | New workspace | `ctrl+s` then `n` (cycles) — or use Command Palette |
  | Previous workspace | `ctrl+s` then `p` |
  | Next workspace | `ctrl+s` then `n` |
  | Toggle sidebar | `ctrl+s` then `b` |
  | New tab in workspace | `ctrl+s` then `c` |
  | Split pane down | `ctrl+s` then `-` |
  | Split pane right | `ctrl+s` then `\` |
  | Focus pane left/down/up/right | `ctrl+h` / `ctrl+j` / `ctrl+k` / `ctrl+l` |
  | Zoom focused pane | `ctrl+s` then `z` |
  | Reload config | `ctrl+s` then `r` |

  ## Suggested workspace layout for feature development

  One workspace per active project or feature branch:
  - Tab 1: editor / main terminal
  - Tab 2: test runner
  - Tab 3: git / scratch

  When using `cmux-claude-teams`, Claude Code and its subagents share the same
  workspace and appear as additional splits.

  ## Steps

  1. Open the Command Palette (`ctrl+s` then Command Palette shortcut, or via menu)
     to create a named workspace for the project.
  2. Use `ctrl+s c` to add tabs within the workspace.
  3. Use `ctrl+s -` and `ctrl+s \` to split panes as needed.
  4. Use `ctrl+s b` to show the sidebar and see workspace/agent metadata.
  ```

- [ ] **Step 2: Run bootstrap to create the symlink**
  ```
  cd ~/.dotfiles && ./bootstrap.sh
  ```
  Expected output includes: `Linked skill: ~/.agent-stuff/skills/cmux-workspaces -> ~/.claude/skills/cmux-workspaces`

- [ ] **Step 3: Verify the symlink**
  ```
  ls -la ~/.claude/skills/cmux-workspaces
  ```
  Expected: a symlink pointing to `~/.agent-stuff/skills/cmux-workspaces`.

---

### Task 5: Install oh-my-claudecode (optional — multi-agent orchestration)

**Files:** none (npm global install)

oh-my-claudecode provides 19 specialized agents with smart model routing. Install only if multi-agent orchestration is needed.

- [ ] **Step 1: Install**
  ```
  npm install -g oh-my-claude-sisyphus
  ```

- [ ] **Step 2: Verify**
  ```
  oh-my-claudecode --version
  ```
  Expected: a version string printed without error.

- [ ] **Step 3: Launch inside cmux**
  Run from inside a cmux workspace (not a plain terminal). oh-my-claudecode uses the same tmux-compat layer as `cmux claude-teams`, so agents appear as native splits.

- [ ] **Step 4: Commit** (no files to commit for a global npm install)
