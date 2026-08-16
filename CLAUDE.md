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

The `agents/hooks/` directory holds the sound, tmux-title, and
notification-log scripts, also shared by both agents. `done.sh` and
`notify.sh` call `log-event.sh`, which appends a colour-coded line
(agent, project, `session:window.pane`, state) to
`~/devel/AGENT_NOTIFICATIONS.log`; the `agent-notifications` skill opens a
Ghostty window tailing it. Claude Code runs them from the hook table in
`.claude/settings.json`; Pi has no hook table, so
`agents/extensions/notifications.ts` binds the same scripts to the
equivalent Pi events.

`.config/mcp/mcp.json` is the shared MCP server list, read by Pi through the
`pi-mcp-adapter` package (install with `pi install npm:pi-mcp-adapter`). Claude
Code ignores that file, so its equivalent servers come from plugins declared in
`.claude/settings.json` under `extraKnownMarketplaces` and `enabledPlugins`.
Adding a server usually means touching both.

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
