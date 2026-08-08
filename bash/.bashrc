# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
  for rc in ~/.bashrc.d/*; do
    if [ -f "$rc" ]; then
      . "$rc"
    fi
  done
fi
unset rc

# Import alias z fish
source ~/.dotdwm/fish/.config/fish/alias.fish

# === Historia ===
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT="%F %T "
shopt -s histappend

# === Wygoda powłoki ===
shopt -s autocd
shopt -s cdspell
shopt -s checkwinsize

# === Zmienne środowiskowe ===
export EDITOR=nvim
export VISUAL=nvim
export PAGER='less -R'
export COLORTERM=truecolor
export MICRO_TRUECOLOR=1
#export GDK_BACKEND=x11 jeśli chcę uruchamiać tylko aplikację to podać jej nazwę po x11

# export DISPLAY=:0 #Fedora > przeniesione do /usr/local/bin/start-dwm.sh
# export XDG_SESSION_TYPE=x11 #Fedora > przeniesione do /usr/local/bin/start-dwm.sh

# === PATH ===
export PATH="$PATH:/usr/bin"
export PATH="$PATH:/usr/local/share/bin"
export PATH="$PATH:$HOME/.config/suckless/scripts"
export PATH="$PATH:$HOME/.config/rofi/scripts"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.local/share/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/!0 Inbox"

# === FZF — Catppuccin Mocha ===
export FZF_DEFAULT_OPTS="\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# === Zoxide ===
eval "$(zoxide init bash)"
eval "$(zoxide init bash --cmd j)"

# === Starship ===
# eval "$(starship init bash)"

# === Funkcje ===
# Packer
mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
  case "$1" in
  *.tar.gz | *.tgz) tar xzf "$1" ;;
  *.tar.bz2) tar xjf "$1" ;;
  *.zip) unzip "$1" ;;
  *.7z) 7z x "$1" ;;
  *.rar) unrar x "$1" ;;
  *.tar.xz) tar xJf "$1" ;;
  *) echo "Nie wiem jak rozpakować: $1" ;;
  esac
}

# Struktura - Johnny.Decimal
jd() {
  local target=$1
  local num=$2
  local file=~/.jd/JDEX.md

  if [[ ! -r "$file" ]]; then
    echo "Nie znaleziono pliku indeksu: $file"
    return 1
  fi

  # Dynamicznie wykryj wszystkie korzenie w pliku (linie "# KORZEŃ: XXX", bierzemy tylko skrót przed spacją/nawiasem)
  local -a korzenie
  mapfile -t korzenie < <(grep -o '^# KORZEŃ: [A-Za-z0-9]*' "$file" | sed 's/^# KORZEŃ: //')

  if [[ ${#korzenie[@]} -eq 0 ]]; then
    echo "Nie znaleziono żadnego korzenia (linii '# KORZEŃ: ...') w $file"
    return 1
  fi

  # Brak podanego korzenia: pokaż WSZYSTKIE korzenie z ich głównymi obszarami
  if [[ -z "$target" ]]; then
    local k
    for k in "${korzenie[@]}"; do
      echo "=== KORZEŃ: $k ==="
      sed -n "/# KORZEŃ: $k/,/^---/p" "$file" | grep '^## \['
      echo
    done
    return 0
  fi

  # Dopasuj podany korzeń (bez rozróżniania wielkości liter) do wykrytej listy
  local target_upper dopasowany=""
  target_upper=$(echo "$target" | tr '[:lower:]' '[:upper:]')
  local k
  for k in "${korzenie[@]}"; do
    if [[ "$(echo "$k" | tr '[:lower:]' '[:upper:]')" == "$target_upper" ]]; then
      dopasowany=$k
      break
    fi
  done

  if [[ -z "$dopasowany" ]]; then
    echo "Nieznany korzeń: '$target'. Dostępne: ${korzenie[*]}"
    return 1
  fi

  # Wytnij blok danego korzenia (od nagłówka korzenia do kolejnego "---" lub końca pliku)
  local blok
  blok=$(sed -n "/# KORZEŃ: $dopasowany/,/^---/p" "$file")

  if [[ -z "$num" ]]; then
    # Brak numeru: spis treści najwyższego poziomu
    printf '%s\n' "$blok" | grep '^## \['
    return 0
  fi

  # Podano numer: wyciągnij tę linię i wszystko, co jest jej "dzieckiem",
  # niezależnie od tego, czy to nagłówek "## [XX]" czy zagnieżdżony punkt "- [XX.YY]".
  printf '%s\n' "$blok" | awk -v num="$num" '
    function get_bracket(line,   dummy) {
      if (match(line, /\[[^]]*\]/)) return substr(line, RSTART + 1, RLENGTH - 2)
      return ""
    }
    function get_indent(line,   i) {
      i = 0
      while (substr(line, i + 1, 1) == " ") i++
      return i
    }
    BEGIN { found = 0 }
    {
      line = $0
      is_heading = (line ~ /^## \[/)

      if (!found) {
        if (get_bracket(line) == num) {
          found = 1
          base_is_heading = is_heading
          base_indent = get_indent(line)
          print line
        }
        next
      }

      if (line ~ /^---/) { found = 0; next }

      if (base_is_heading) {
        if (is_heading) { found = 0; next }
        print line
      } else {
        if (is_heading) { found = 0; next }
        cur_indent = get_indent(line)
        if (cur_indent <= base_indent) { found = 0; next }
        print line
      }
    }
  '
}

# Klonowanie z GitHub po SSH — użycie: gcs trebuhw/.dotfiles.git
gcs() { git clone --depth=1 "git@github.com:$1"; }

# ~ ❯  (zielona/czerwona) Catppuccin Mocha
PS1='\n\[\e[38;2;203;166;247m\]\w\[\e[0m\] $([ $? -eq 0 ] && echo "\[\e[38;2;148;226;213m\]❯" || echo "\[\e[38;2;243;139;168m\]❯")\[\e[0m\] '

# ustawienie na stale rodzaju cursora aby inne programy nie zmienialy go na block przy wyjściu
# PsKursor
#  1 blinking block
#  2 steady block
#  3 blinking underline _
#  4 steady underline _
#  5 blinking bar |
#  6 steady bar |
#
## Ustaw kursor przy starcie basha
printf '\e[5 q'
# Przywracaj po każdym poleceniu
PROMPT_COMMAND='printf "\e[5 q"'
