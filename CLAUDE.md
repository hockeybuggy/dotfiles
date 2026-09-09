# Dotfiles

Personal config files for neovim, tmux, zsh, git, and friends.
Use `bootstrap.sh --minimal`, `bootstrap.sh --work`, or
`bootstrap.sh --personal` to install that mode's dependencies, link
configuration, and record the mode in `~/.dotfiles_mode`. `setup.sh` accepts
the same required mode flags for installation-only use. Run `doctor.sh` after
setup or configuration changes; it reads the recorded mode and checks only
that profile's expected tools and configuration. Use `doctor.sh --strict` when
warnings should also fail. Use `doctor.sh --ci` for checks in CI.

The `.claude/` directory contains global Claude Code config. The
bootstrap script handles it specially — it symlinks `CLAUDE.md` and
merges `settings.json` with `settings.local.json` (if present).

The `agents/skills/` directory holds Agent Skills (one `SKILL.md` per
subdirectory) shared by Claude Code and the Pi coding agent. Bootstrap
links each into both `~/.claude/skills/` and `~/.pi/agent/skills/`.
Single-agent skills live in `agents/skills-claude/` or `agents/skills-pi/`
instead, and link into only that agent. Moving a skill between these
directories strips it from the other agent, so re-run `bootstrap.sh` after
a `git mv` to prune the symlink left behind.

[herdr](https://herdr.dev/) is being trialled as a replacement for tmux.
`setup.sh` installs it in `work` and `personal` modes, `.config/herdr/config.toml`
holds a deliberately minimal config, and `agents/skills/herdr/` teaches agents to
drive it. tmux's own config and skills are otherwise untouched — both are
installed, and outside herdr neither knows about the other.

The exception is nesting: `.tmux-herdr.conf` holds the extra bindings a tmux
needs to be usable *inside* a herdr pane, where herdr swallows `ctrl+s` and
`ctrl+h/j/k/l` before tmux sees them. `.tmux.conf` sources it when `$HERDR_ENV`
is set. It is purely additive, so keep it that way — it can load in a server
that is not inside herdr.

There are no agent notification hooks any more: the sound, tmux-title and
notification-log scripts under `agents/hooks/`, plus the Claude hook table,
`agents/extensions/notifications.ts` and agy's `hooks.json`, were removed once
herdr started surfacing agent state itself. Only the `gh api` permission guard
remains in `.claude/settings.json`. Don't reintroduce them without asking.

`.config/mcp/mcp.json` is the shared MCP server list, read by Pi through the
`pi-mcp-adapter` package (install with `pi install npm:pi-mcp-adapter`). Claude
Code ignores that file, so its equivalent servers come from plugins declared in
`.claude/settings.json` under `extraKnownMarketplaces` and `enabledPlugins`.
Adding a server usually means touching both.

`agents/agy/settings.json` holds portable agy defaults — colour scheme, model,
and an allowlist of read-only commands. agy reads only
`~/.gemini/antigravity-cli/settings.json` and rewrites it itself, so it can't be
symlinked; `bootstrap.sh` merges the tracked file in via
`lib/merge-agy-settings.py` instead. The merge only ever adds, so local keys
like `trustedWorkspaces` survive and anything already set wins. Keep home paths
and workspace lists out of the tracked file — `test/agy-settings-merge.sh`
enforces that.

This repo is public. Anything employer-specific — internal tool paths,
hostnames, ticket prefixes, private MCP servers — belongs in an
untracked local file, never in a tracked one:

- `~/.zshrc.local` for shell setup (sourced last by `.zshrc`)
- `~/.gitconfig.local` for Git identity and signing
- `.claude/settings.local.json` for Claude plugins and permissions
- `agents/skills-local/` for work-specific skills

Each has a tracked `.example` counterpart where one makes sense. When
writing a skill or config that a stranger will read, keep it generic:
use placeholder identifiers (`ABC-1234`) and describe tools by role
rather than hardcoding private namespaces.

Keep changes focused. Don't over-engineer things.

Please use Canadian spelling (e.g., colour, centre, travelling, defence) in your responses and when writing code/documentation.
