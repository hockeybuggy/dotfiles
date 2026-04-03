# Dotfiles

Personal config files for neovim, tmux, zsh, git, and friends.
Managed by `bootstrap.sh` which symlinks tracked files into `$HOME`.

The `.claude/` directory contains global Claude Code config. The
bootstrap script handles it specially — it symlinks `CLAUDE.md` and
merges `settings.json` with `settings.local.json` (if present).

Keep changes focused. Don't over-engineer things.
