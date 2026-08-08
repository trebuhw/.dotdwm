if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting
starship init fish | source
# set -g STARSHIP_COMMAND_TIMEOUT 10
#set -x DISPLAY :0 #Fedora > przeniesine do /usr/local/bin/start-dwm.sh
#set -x XDG_SESSION_TYPE x11 #Fedora > przeniesine do /usr/local/bin/start-dwm.sh
set -gx EDITOR nvim
set -gx GDK_BACKEND x11
set -gx COLORTERM truecolor
# set -gx QT_QPA_PLATFORMTHEME gnome
# set -Ux QT_QPA_PLATFORMTHEME kvantum
# set -Ux QT_QPA_PLATFORMTHEME qt5ct
# set -Ux QT_QPA_PLATFORMTHEME qt6ct
set -gx PATH $PATH /usr/bin
set -gx PATH $PATH /usr/local/share/bin
set -gx PATH $PATH ~/.config/suckless/scripts
set -gx PATH $PATH ~/.config/rofi/scripts
set -gx PATH $PATH ~/.local/bin
set -gx PATH $PATH ~/.local/share/bin
set -gx PATH $PATH ~/.cargo/bin
set -gx PATH $PATH ~/"!0 Inbox"

export "MICRO_TRUECOLOR=1"

# Dracula FZF color 

#set -Ux FZF_DEFAULT_OPTS "\
#--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 \
#--color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 \
#--color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 \
#--color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

# Catppucin Mocha FZF color

set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# fish_config theme save "Catppuccin Mocha" # Unhash jednorazowo potem zahaszofać z powrotem

### ALIASES ###

# Aliases
if [ -f $HOME/.dotdwm/fish/.config/fish/alias.fish ]
    source $HOME/.dotdwm/fish/.config/fish/alias.fish

    zoxide init fish | source
    zoxide init fish --hook prompt | source
    zoxide init fish --cmd j | source
end

# Alias do klonowania z github po ssh wpisać tylko właściciela i nazwę repo> zastosownie np: gcs trebuhw/.dotfiles.git 
function gcs
    set repo $argv[1]
    git clone --depth=1 git@github.com:$repo
end

# ustawienie na stale rodzaju cursora aby inne programy nie zmienialy go na block przy wyjściu
#  PsKursor
#  1 blinking block 
#  2 steady block
#  3 blinking underline _
#  4 steady underline _
#  5 blinking bar |
#  6 steady bar |

function postexec_cursor --on-event fish_postexec
    printf '\e[5 q'
end
