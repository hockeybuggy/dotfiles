
set-option global grepcmd "rg --column"

# Appearance
add-highlighter global/ number-lines -relative
set global ui_options ncurses_assistant=none
colorscheme solarized-dark-termcolors

# Mappings

# Leader mappings
map global user -docstring "fuzzy find" f ":fzf-mode<ret>"
map global user -docstring "grep" g ":grep "

# Normal mode mappings
map global normal '#' :comment-line<ret> -docstring 'comment line'
map global normal '<a-#>' :comment-block<ret> -docstring 'comment block'

# Plugins
# TODO get plug working
source "%val{config}/plugins/plug.kak/rc/plug.kak"

source "%val{config}/plugins/fzf.kak/rc/fzf.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-file.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-buffer.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-search.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/fzf-vcs.kak"
source "%val{config}/plugins/fzf.kak/rc/modules/VCS/fzf-git.kak"

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
    powerline-format git bufname filetype mode_info line_column position
    powerline-toggle line_column off
    powerline-toggle line_column position
}
