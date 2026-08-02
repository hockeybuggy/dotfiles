# Dotfiles

Personal config files for neovim, tmux, zsh, git, and friends.
Use `setup.sh` to install dependencies on macOS or Debian/Ubuntu. It
installs tools only; it does not link configuration. Use `bootstrap.sh`
to symlink tracked files into `$HOME`.

Run `doctor.sh` after setup or configuration changes to check tools,
symlinks, shell setup, environment variables, and Git configuration.
Use `doctor.sh --strict` when warnings should also fail. Use
`doctor.sh --ci` for checks in CI.

The `.claude/` directory contains global Claude Code config. The
bootstrap script handles it specially — it symlinks `CLAUDE.md` and
merges `settings.json` with `settings.local.json` (if present).

The `agents/skills/` directory holds Agent Skills (one `SKILL.md` per
subdirectory) shared by Claude Code and the Pi coding agent. Bootstrap
links each into both `~/.claude/skills/` and `~/.pi/agent/skills/`.

The `agents/hooks/` directory holds the sound and tmux-title scripts, also
shared by both agents. Claude Code runs them from the hook table in
`.claude/settings.json`; Pi has no hook table, so
`agents/extensions/notifications.ts` binds the same scripts to the
equivalent Pi events.

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
