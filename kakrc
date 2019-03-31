
set-option global grepcmd "rg --column"

# Appearance
add-highlighter global/ number-lines -relative
set global ui_options ncurses_assistant=none
colorscheme solarized-dark-termcolors

# Commands
define-command -override -docstring "write-quit" x %{write-quit}

define-command -override -docstring "split tmux vertically" \
vsp -params .. -command-completion %{
    tmux-terminal-horizontal kak -c %val{session} -e "%arg{@}"
}
define-command -override  -docstring "split tmux horizontally" \
sp -params .. -command-completion %{
    tmux-terminal-vertical kak -c %val{session} -e "%arg{@}"
}

# Mappings
# Leader mappings
map global user -docstring "fuzzy find" f ":fzf-mode<ret>"
map global user -docstring "grep" g ":grep "

# Normal mode mappings
map global normal '#' :comment-line<ret> -docstring 'comment line'
map global normal '<a-#>' :comment-block<ret> -docstring 'comment block'

# File specific
hook global WinSetOption filetype=git-commit %{
    set window autowrap_column 72
    autowrap-enable
}
set global tabstop 4
set global indentwidth 4

hook global WinSetOption filetype=python %{
    set-option buffer formatcmd 'black -q -'
    hook buffer -group format BufWritePre .* format

    set-option buffer lintcmd 'pylint --msg-template="{path}:{line}:{column}: {category}: {msg}" -rn -sn'
    lint-enable
    lint
    hook buffer -group lint BufWritePost .* lint
}

hook global WinSetOption filetype=(javascript|typescript|css|scss|markdown) %{
    set-option buffer formatcmd "prettier --stdin-filepath=${kak_buffile}"
    hook buffer -group format BufWritePre .* format
}

# Plugins
# TODO get plug working
source "%val{config}/plugins/plug.kak/rc/plug.kak"

source "%val{config}/plugins/fzf.kak/rc/fzf.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-file.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-buffer.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-search.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-vcs.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/VCS/fzf-git.kak"
set-option global fzf_preview_width '40%'
set-option global fzf_file_command 'fd'
set-option global fzf_highlight_cmd 'bat'

source "%val{config}/plugins/powerline.kak/rc/powerline.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/bufname.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/client.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/filetype.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/git.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/line_column.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/mode_info.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/position.kak"
source "%val{config}/plugins/powerline.kak/rc/modules/session.kak"
source "%val{config}/plugins/powerline.kak/rc/themes/solarized-dark-termcolors.kak"
hook -once global WinCreate .* %{
    powerline-theme solarized-dark-termcolors
    powerline-separator arrow
    powerline-format git bufname filetype mode_info line_column position session
    powerline-toggle line_column off
    powerline-toggle line_column position
}

eval %sh{kak-lsp --kakoune -s $kak_session}
lsp-enable
