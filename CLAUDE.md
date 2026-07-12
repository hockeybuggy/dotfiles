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

Keep changes focused. Don't over-engineer things.

Please use Canadian spelling (e.g., colour, centre, travelling, defence) in your responses and when writing code/documentation.
