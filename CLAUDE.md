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
links each into `~/.claude/skills/` for Claude and points
`~/.pi/agent/skills` at the directory for Pi.

Keep changes focused. Don't over-engineer things.

Please use Canadian spelling (e.g., colour, centre, travelling, defence) in your responses and when writing code/documentation.
