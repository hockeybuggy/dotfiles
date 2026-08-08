# My dotfiles

This repository is for managing my configuration files.

## Installation

### 1. Clone this repo

Clone the repo. I like to put it at `~/.dotfiles`

    git clone git@github.com:hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Install the tools

`setup.sh` installs the dependencies listed below. It works on macOS (via
Homebrew) and Debian/Ubuntu (via apt plus a few official installers). It
only installs tools -- it does not link any config.

    ./setup.sh

### 3. Automagically Link the files

    ./bootstrap.sh

## Agent skills

The `agents/skills/` directory holds [Agent Skills](https://agentskills.io)
(one `SKILL.md` per subdirectory) shared by
[Claude Code](https://claude.ai/code), the
[Pi coding agent](https://shittycodingagent.ai), and Google's
[Antigravity CLI](https://antigravity.google/docs/cli/overview) (`agy`).
`bootstrap.sh` links each into `~/.claude/skills/` for Claude,
`~/.pi/agent/skills/` for Pi, and `~/.gemini/config/skills/` for agy.

Skills that only make sense for one agent go in a sibling directory instead:

| Directory | Linked into |
| --- | --- |
| `agents/skills/` | Claude, Pi, and agy |
| `agents/skills-claude/` | Claude Code only |
| `agents/skills-pi/` | Pi only |
| `agents/skills-local/` | Claude, Pi, and agy (untracked) |

agy has no agy-only sibling directory yet -- `use-agy-in-pane`, the skill that
drives it, is Claude-only by nature (it's Claude delegating to a headless
agy), so it lives in `agents/skills-claude/`.

Move a skill between them with `git mv`, then re-run `bootstrap.sh` — it prunes
the symlink the skill left behind in the agent that no longer gets it.

## Pi extensions

The `agents/extensions/` directory holds global Pi extensions. `bootstrap.sh`
symlinks each extension into `~/.pi/agent/extensions/`; reload Pi with `/reload`
after changing one.

## MCP servers

`.config/mcp/mcp.json` is the shared, tool-agnostic MCP server list; it links
to `~/.config/mcp/mcp.json`, the highest-precedence source for Pi's
[`pi-mcp-adapter`](https://pi.dev/packages/pi-mcp-adapter) package. Install the
adapter once per machine (it records itself in the untracked
`~/.pi/agent/settings.json`):

    pi install npm:pi-mcp-adapter

Claude Code does not read that file, so it gets the same servers through
plugins instead. `.claude/settings.json` declares the marketplaces and enabled
plugins, which means `bootstrap.sh` restores them on a new machine — Chrome
DevTools is wired up this way, per
[Chrome's agent docs](https://developer.chrome.com/docs/devtools/agents).

agy also reads `mcpServers` config directly (its own copy lives at
`~/.gemini/config/mcp_config.json`), so `bootstrap.sh` symlinks the same
`.config/mcp/mcp.json` there too.

## Agent hooks

The `agents/hooks/` directory holds the scripts that play notification sounds
and rename the tmux window as an agent works. `bootstrap.sh` links them into
both `~/.claude/hooks/` and `~/.pi/agent/scripts/`. Claude Code wires them up
through the hook table in `.claude/settings.json`; Pi has no such table, so
`agents/extensions/notifications.ts` subscribes to the equivalent events.

agy has its own lifecycle-hooks system (`hooks.json`), but only a couple of
its events map cleanly onto "agent is working" / "agent is done" —
`agents/agy/hooks.json` wires those two (`PreInvocation` and `Stop`) to
`agents/hooks/agy-working.sh` and `agents/hooks/agy-done.sh`, thin wrappers
that read agy's stdin JSON payload and call the same shared `tmux-title.sh`
and `done.sh` scripts. `bootstrap.sh` symlinks it to
`~/.gemini/config/hooks.json`.

## Antigravity CLI (agy)

`setup.sh` installs [agy](https://antigravity.google/docs/cli/overview)
alongside Claude Code and Pi. `bootstrap.sh` links `CLAUDE.md` to
`~/.gemini/config/GEMINI.md` (agy's name for the same global-rules file), so
all three agents follow the same conventions.

agy sandboxes file reads to the current project by default, and the shared
skills it gets from `~/.gemini/config/skills/` are symlinks that resolve
outside of it -- so `bootstrap.sh` also adds a `read_file()` allow-rule
scoped to this repo's path in agy's personal
`~/.gemini/antigravity-cli/settings.json`, alongside whatever prefs (colour
scheme, model, `trustedWorkspaces`) already live there.

To delegate a task to agy the way you'd delegate to Pi, use the
`use-agy-in-pane` skill (`agents/skills-claude/use-agy-in-pane/`) -- it runs
`agy --output-format stream-json` headless inside a visible, named tmux
window, mirroring `use-pi-in-pane`. See
[Antigravity's headless-mode docs](https://antigravity.google/docs/cli/headless)
for the underlying flags.

## Checking a machine with `doctor.sh`

Run the doctor after installation to check required tools, linked config,
shell setup, environment variables, Git configuration, and optional
dependencies:

    ./doctor.sh

Checks report OK, WARN, or FAIL with a suggested fix. The command exits
non-zero for any required failure. Use `--strict` to also treat warnings as
failures, or `--ci` to skip checks that only apply to a personal machine.

## Testing `setup.sh`

You can exercise `setup.sh` on a clean Debian container. This builds a minimal
image, runs `setup.sh` and `bootstrap.sh` inside it, then drives a tmux session
to confirm each tool actually runs:

    ./test/run.sh

Pass `--interactive` to provision the container and drop into a shell so you
can poke around in tmux yourself:

    ./test/run.sh --interactive

## Dependencies

1. Executables
    1. neovim - 11.0
    1. tmux - 3.5
    1. iterm2
1. command line utils
    1. zsh  - 5.0
    1. reattach-to-user-namespace
    1. Inconsolata font (nerdfont variant)
    1. starship
    1. zoxide
    1. uutils-coreutils
    1. [ripgrep](https://github.com/BurntSushi/ripgrep) -- Grep replacement
    1. [fd](https://github.com/sharkdp/fd) -- `find` replacement
    1. [fzf](https://github.com/junegunn/fzf) -- Fuzzy finder
    1. [bat](https://github.com/sharkdp/bat) -- `cat` replacement
    1. [eza](https://eza.rocks/) -- `ls` replacement
    1. [bottom](https://github.com/ClementTsang/bottom) -- `top` replacement (`btm`)
1. Language things
    1. rustup, cargo, rustc
    1. Python 3.14, ruff, ty, pgcli
    1. node, fnm, prettier
    1. luarocks, stylua
    1. rbenv, rubocop, solargraph
1. Coding agents
    1. [Claude Code](https://claude.com/claude-code)
    1. [Pi](https://pi.dev)
    1. [Antigravity CLI (agy)](https://antigravity.google/docs/cli/overview)
1. [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)
1. Git related
    1. gnupg
    1. gpg-agent
    1. diff-so-fancy
