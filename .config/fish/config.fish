set -g fish_greeting
fish_add_path --move --prepend ~/.local/bin
if status is-interactive
    command -q starship; and starship init fish | source
    alias ff fastfetch

    # подсветка набираемой команды — номера цветов палитры kitty (меняются вместе с обоями)
    set -g fish_color_command brblue --bold          # команда — светлый основной
    set -g fish_color_keyword magenta --bold         # if / for / and
    set -g fish_color_param normal                   # аргументы
    set -g fish_color_option brcyan                  # --флаги
    set -g fish_color_quote green                    # "строки" — третичный (сиреневый)
    set -g fish_color_redirection yellow             # > | &
    set -g fish_color_end yellow                     # ; &&
    set -g fish_color_operator brmagenta             # $ * ~
    set -g fish_color_escape brcyan
    set -g fish_color_error red --bold               # несуществующая команда
    set -g fish_color_autosuggestion brblack --italics  # подсказка из истории
    set -g fish_color_comment brblack --italics
    set -g fish_color_valid_path --underline         # существующий путь подчёркнут
    set -g fish_color_selection --reverse
    set -g fish_color_search_match --background=brblack
    set -g fish_pager_color_prefix brblue --bold
    set -g fish_pager_color_completion normal
    set -g fish_pager_color_description brblack --italics
    set -g fish_pager_color_selected_background --background=blue
    alias dots "git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
    # fastfetch при открытии нового терминала (только в kitty, не во вложенных шеллах)
    if test "$TERM" = xterm-kitty; and not set -q RICE_FF_SHOWN; and command -q fastfetch
        set -gx RICE_FF_SHOWN 1
        if test $COLUMNS -lt 110; fastfetch --logo none; else; fastfetch; end
    end
end

# opencode
fish_add_path /home/p1ckq/.opencode/bin
