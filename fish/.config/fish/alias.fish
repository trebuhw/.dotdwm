# =========================
# ALIASY HUBERT - FEDORA / ARCH / XORG / HYPRLAND / OMARCHY
# =========================

# Listowanie plików (eza)
alias l='eza --tree --level 1 --group-directories-first --icons=auto' # lista katalogi i pliki bez .ukrytych
alias ls='eza --tree --level 1 --group-directories-first --icons=auto --all' # lista katalogi i pliki z .ukrytymi
alias la='eza --group-directories-first --icons=auto' # katalogi i pliki bez .ukrytuych
alias ll='eza --tree --level 1 -lha --group-directories-first --icons=auto' # pełna lista katalogi i pliki z .ukrytymi
alias ld='eza --tree --level 1 -lhD --icons=auto' # lista pełna tylko katalogi
alias lda='eza -a --sort name --icons=auto' # katalogi i pliki z ukrytymi
alias lt='eza --tree --level 1 --icons=auto' # lista bez ukrytych bez sortowania najpierw katalogi
alias lp='eza --sort name --icons=auto --tree -L' # lista bez ukrytych, podaj poziom i ścieżkę
alias lpa='eza --sort name --icons=auto --tree --all -L' # lista z ukrytymi, podaj poziom i ścieżkę

# Nawigacja (zoxide + cd)
alias ze='zoxide edit' # przejdź przez zoxide i pokaż katalog
alias cd..='cd ..' # literówka
alias e='exit' # wyjście z powłoki

# Tree / system
alias t='tree --sort name' # drzewo katalogów posortowane
alias tg='tree --sort name -L' # drzewo katalogów, podaj poziom głębokości
alias tk='tree --sort name -d' # drzewo tylko katalogów
alias ta='tree -aCsh --du --sort name' # drzewo z ukrytymi, kolorami i rozmiarami
alias df='df -h' # zajętość dysków w czytelnym formacie
alias rk='du -sh *' # rozmiar plików/katalogów w bieżącym folderze
alias free='free -mt' # zużycie pamięci RAM w MB z podsumowaniem
alias ws='watch sensors' # na bieżąco temperatury czujników
alias userlist='cut -d: -f1 /etc/passwd | sort' # lista użytkowników systemu
alias upfont='sudo fc-cache -fv' # odświeżenie cache czcionek
alias sefont='fc-list | grep -i' # wyszukiwanie czcionek

alias ns="nvidia-smi" # status karty graficznej Nvidia
alias pcinfo="inxi -Fxz" # pełne informacje o sprzęcie
alias hwi="hwinfo --short" # skrócone informacje o sprzęcie
alias batery='cat /sys/class/power_supply/BAT0/uevent' # stan baterii

alias power='powerprofilesctl' # zarządzanie profilami zasilania (systemctl enable/start power-profiles-daemon.service)
alias probe='sudo -E hw-probe -all -upload' # zebranie i wysłanie profilu sprzętowego
alias td='sudo hdparm -t' # test prędkości dysku użycie sudo hdparm -t /dev/sda

alias xwi='xwininfo' # informacje o otwartym oknie kliknąć na oknie
alias xwc='xprop | grep WM_CLASS' # class window, kliknąć na oknie
alias wget="wget -c" # pobieranie z możliwością wznowienia

# Systemd - systemctl
alias slu='systemctl list-units --type=service --state=running' # uruchomione
alias sla='systemctl list-units --type=service' # aktywne i nie aktywne
alias sls='systemctl list-unit-files --type=service --state=enabled' # startujące z systemem
alias sysfailed='systemctl list-units --failed' # lista usług, które zakończyły się błędem

# User systemd - systemctl
alias sluu='systemctl --user list-units --type=service --state=running' # user uruchomione
alias slau='systemctl --user list-units --type=service' # user aktywne i nie aktywne
alias slsu='systemctl --user list-unit-files --type=service --state=enabled' # user startujące z systemem

# Audio / jasność
alias am='alsamixer' # mikser audio w terminalu
alias vs='amixer sset "Master"' # ustaw głośność (np. 50%)
alias vs4='amixer sset "Master" 40%' # głośność 40%

alias bs='brightnessctl set' # ustaw jasność
alias bs3='brightnessctl set 30%' # jasność 30%
alias bi='brightnessctl i' # info o jasności

# Bezpieczne operacje na plikach (trash-cli)
alias cp='cp -riv' # kopiowanie z potwierdzeniem
alias mv='mv -iv' # przenoszenie z potwierdzeniem
alias rm='trash-put -rfv' # przenieś do kosza

alias tl='trash-list' # lista plików w koszu
alias te='trash-empty' # opróżnij kosz
alias tr='trash-restore' # przywróć plik
alias trm='trash-rm' # usuń z kosza na stałe

alias mkdir='mkdir -vp' # tworzenie katalogów z rodzicami

# Wyszukiwanie i logi
alias grep='grep --color=auto' # wyszukiwanie tekstu z kolorowaniem
alias egrep='egrep --color=auto' # wyszukiwanie rozszerzonymi wyrażeniami z kolorowaniem
alias fgrep='fgrep --color=auto' # wyszukiwanie zwykłego tekstu z kolorowaniem
alias rg='rg --sort path' # ripgrep - szybkie wyszukiwanie w plikach, posortowane po ścieżce
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl" # lista 200 ostatnio zainstalowanych pakietów (pacman)
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl" # lista 3000 ostatnio zainstalowanych pakietów (pacman)
alias fn='find -name' # szukanie plików po nazwie
alias locate='locate -b' # szukanie plików po nazwie pliku (bazowa nazwa)
alias jctl='journalctl -p 3 -xb' # błędy systemu
alias jctlcl='sudo journalctl --rotate && sudo journalctl --vacuum-time=1s' # clean jctl

# Shell / System / power / info
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'" # zmiana domyślnej powłoki na bash
alias tofish="sudo chsh $USER -s /usr/bin/fish && echo 'Now log out.'" # zmiana domyślnej powłoki na fish
alias upgrub="sudo grub-mkconfig -o /boot/grub/grub.cfg" # regeneracja konfiguracji GRUB

alias ff='fastfetch' # informacje o systemie (domyślny wygląd)
alias ffm='fastfetch -c $HOME/.dotdwm/fastfetch/.config/fastfetch/hw-config.jsonc' # fastfetch z konfiguracją hw
alias ffn='fastfetch -l none -c $HOME/.dotdwm/fastfetch/.config/fastfetch/no-logo-config.jsonc' # fastfetch bez logo
alias ffo='fastfetch -c $HOME/.dotdwm/fastfetch/.config/fastfetch/omarchy-config.jsonc' # fastfetch z konfiguracją Omarchy
alias ffs='fastfetch -l small -c $HOME/.dotdwm/fastfetch/.config/fastfetch/omarchy-small-config.jsonc' # fastfetch mała wersja Omarchy

alias po='sync ; systemctl poweroff' # wyłączenie komputera, synchronizacja bufora dla archiwum exFat
alias rb='sync ; systemctl reboot' # restart komputeras, synchronizacja bufora dla archiwum exFat
alias rh='sync ; hyprctl dispatch exit' # wylogowanie z sesji Hyprland, synchronizacja bufora dla archiwum exFat
alias logout='sync ; pkill -KILL -u hubert' # wymuszone wylogowanie użytkownika hubert, synchronizacja bufora dla archiwum exFat

# Bluetooth
alias bt='blueman-adapters' # zarządzanie adapterami Bluetooth (GUI)
alias br='sudo systemctl restart bluetooth' # restart usługi Bluetooth
alias btinfo="bluetoothctl info" # informacje o połączonym urządzeniu
alias think="bluetoothctl info | awk '/Name:/ || /Battery Percentage:/' | bat" # nazwa i stan baterii sparowanego urządzenia

# Sieć / diagnostyka
alias nm='nmtui' # interfejs tekstowy NetworkManager
alias nma='nm-applet' # applet NetworkManager w trayu
alias arp='sudo arp-scan --localnet' # ARP scan sieci lokalnej
alias nt='speedtest-cli' # test prędkości internetu
alias dns='systemd-resolve --status' # status DNS

# Programy / Skrypty
alias nv='nvim' # edytor nvim
alias y='yazi' # menedżer plików w terminalu
alias f='yazi' # menedżer plików w terminalu
alias bat='bat -l conf -p' # wyświetlenie pliku z podświetleniem jak conf, bez numeracji/nagłówka
alias ag='bat $HOME/.config/fish/alias.fish | sort | grep' # szukanie aliasu po słowie kluczowym
alias agy='bat $HOME/.config/yazi/keymap.toml | grep cd' # szukanie aliasu po słowie kluczowym
alias hg='history | grep ' # szukanie w historii poleceń
alias app='hyprctl clients' # lista otwartych okien w Hyprland
alias picker='hyprpicker -an' # wybór koloru piksela na ekranie (Hyprland)
alias bg='nsxiv -t /home/hubert/.dotdwm/backgrounds/.local/share/omarchy/themes/catppuccin/backgrounds/' # podgląd tapet w miniaturkach
alias fzf='fzf --preview "bat --color=always {}"' # fuzzy finder z podglądem pliku
alias nn='fzf-nn.sh' # !0 Inbox > nowa notatka
alias no='fzf-notes.sh' # Notes > ~/Documents/Notes
alias fe='fzf-nvim.sh' # wybór pliku przez fzf i otwarcie w nvim
alias fel='fzf-nvim.sh $(pwd)/' # jak fe, ale w bieżącym katalogu
alias mocp='mocp -C $HOME/.moc/config' # odtwarzacz muzyki z własną konfiguracją
alias ytd='yt-dlp --extract-audio --audio-format mp3 --audio-quality 0' # pobranie audio z YouTube jako mp3
alias pogoda='curl wttr.in/Swidnica' # pogoda dla Świdnicy w terminalu
alias c='cal -y' # kalendarz na cały bieżący rok
alias mpdf='gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=' # kompresja/łączenie PDF przez ghostscript
alias ptt='pdftotext -layout' # konwersja PDF do tekstu z zachowaniem układu
alias repho='rename-photos.sh' # skrypt do zmiany nazw zdjęć

# Foldery / szybka nawigacja
alias hom='cd $HOME/ && ls' # przejdź do katalogu domowego
alias in='cd $HOME/!0\ Inbox/ && ls' # przejdź do folderu Inbox
alias dok='cd $HOME/Documents/ && ls' # przejdź do folderu Dokumenty
alias cno='cd $HOME/Documents/Notes/ && ls' # przejdź do folderu Dokumenty
alias gh='cd $HOME/GitHub/ && ls' # przejdź do folderu GitHub
alias ghm='cd $HOME/GitHub/Moje/ && ls' # przejdź do folderu z własnymi repozytoriami
alias ghf='cd $HOME/GitHub/Moje/fedora/ && ls' # przejdź do folderu repozytorium fedora
alias ghp='cd $HOME/GitHub/Pobrane/ && ls' # przejdź do folderu z pobranymi repozytoriami
alias obr='cd $HOME/Pictures && ls' # przejdź do folderu Obrazy
alias wal='cd $HOME/Pictures/Wallpaper && yazi' # przejdź do folderu Wallpaper i otwórz yazi
alias muz='cd $HOME/Music && ls' # przejdź do folderu Muzyka
alias dot='cd $HOME/.dotdwm/ && ls' # przejdź do folderu dotfiles
alias con='cd $HOME/.config && ls' # przejdź do folderu konfiguracji
alias cbi='cd $HOME/.local/bin && ls' # przejdź do folderu z własnymi skryptami/binarkami
alias fis='cd $HOME/.config/fish && ls' # przejdź do folderu konfiguracji fish

# Clipboard - kopiowanie / historia schowka
alias ffcp='cliphist list | fzf | cliphist decode | wl-copy ' # historia schowka uruchamiana w terminalu
alias ch='rm /home/hubert/.cache/cliphist/db && chw' # clear list cliphist - historia kopiowania, numeracja elementów skopiowanych będzię kontynuowana
alias chwipe='cliphist wipe && chw' # clear list cliphist - historia kopiowania, numeracja elementów skopiowanych będzię kontynuowana
alias chdel='rm /home/hubert/.cache/cliphist/db && chw' # cliphist usunięcie  bazy - numeracja skopiowanych będzię kontynuowana od nowa

# RSYNC / backup / SSH
alias rs='rsync -av' # podstawowa synchronizacja: rekurencyjnie, z zachowaniem uprawnień/dat, verbose
alias rsd='rsync -av --delete' # jak wyżej, ale usuwa w celu pliki, których nie ma już w źródle (uważaj!)
alias rsp='rsync -avP' # synchronizacja z paskiem postępu i możliwością wznowienia przerwanego transferu
alias rsdry='rsync -avP --dry-run' # test na sucho - pokazuje co by się zsynchronizowało, bez kopiowania
alias rsbg='rsync -av --delete $HOME/Obrazy/bg/ $HOME/.local/share/omarchy/themes/catppuccin/backgrounds/' # synchronizacja tapet z motywem Catppuccin w Omarchy
alias backup='backup-tool.sh' # uruchomienie skryptu backupu

alias cpshh='scp -rv' # kopiowanie plików przez SSH (scp) rekurencyjnie, verbose
alias rsssh='rsync -avz -e ssh' # synchronizacja przez SSH z kompresją
alias rsdssh='rsync -avz --delete -e ssh' # jak wyżej, ale z usuwaniem plików nieobecnych w źródle (uważaj!)
alias rsdsshdry='rsync -avz --delete --dry-run -e ssh' # test na sucho dla synchronizacji SSH z usuwaniem

# GIT
alias mgc='$HOME/Documents/Git/my-git-clone.sh' # własny skrypt do klonowania repozytorium
alias gc='git clone --depth=1' # klonowanie repozytorium bez historii commitów
alias mga='git add .' # dodanie wszystkich zmian do commita
alias mgs='git status' # status repozytorium
alias mgcom='git commit -am' # commit wszystkich zmian z komunikatem
alias mgup='mgs
mga .
mgcom up
mgpush' # status + add + commit "up" + push za jednym razem
alias mgpush='$HOME/Documents/Git/my-git-push.sh' # własny skrypt do push
alias mgpull='$HOME/Documents/Git/my-git-pull.sh' # własny skrypt do pull
alias mgacp='$HOME/Documents/Git/my-git-acp.sh' # własny skrypt add+commit+push
alias gbf='/usr/bin/git --git-dir=$HOME/.dotdwm/ --work-tree=$HOME fetch origin' # fetch dla repozytorium dotfiles (bare repo)

# Fedora
alias fv='cat /etc/fedora-release' # wersja systemu Fedora

# Dnf
alias u='sudo dnf upgrade --refresh' # aktualizacja systemu z odświeżeniem repozytoriów
alias s='dnf search' # wyszukiwanie pakietów
alias i='sudo dnf install -y' # instalacja pakietu bez potwierdzenia
alias r='sudo dnf remove -y' # usunięcie pakietu bez potwierdzenia
alias pz='dnf list --installed | grep' # szukanie zainstalowanego pakietu po nazwie
alias pw='dnf list --installed' # lista wszystkich zainstalowanych pakietów
alias pi='dnf info' # informacje o pakiecie
alias oi='fedora-ostatnie-instalacje.sh' # skrypt pokazujący ostatnio zainstalowane pakiety
alias ar='sudo dnf autoremove -y' # usunięcie nieużywanych zależności
alias cl='sudo dnf clean all -y' # czyszczenie cache dnf
alias al='alias | grep dnf' # szukanie aliasów związanych z dnf

# Obsługa repozytoriów DNF
alias drl='dnf repolist' # dnf repo list
alias dra='dnf repolist --all' # dnf repo list all
alias dri='dnf repoinfo' # dnf repo info
alias drc='sudo dnf clean all && dnf makecache' # dnf repo clean
alias dre='sudo dnf config-manager setopt google-chrome.enabled=1' # dnf repo włączanie po setopt zamiast google-chrome wpisać nazwę repo
alias drd='sudo dnf config-manager setopt google-chrome.enabled=0' # dnf repo wyłączanie po setopt zamiast google-chrome wpisać nazwę repo
alias drad='sudo dnf config-manager --add-repo' # dnf repo add
alias drlk='rpm -q gpg-pubkey --qf "%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n"' # dnf repo list key - lista zaimportowanych kluczy GPG z opisem repozytorium
alias drdk='sudo rpm -e' # dnf repo del key - usunięcie klucza GPG, podać pełną nazwę klucza z drlk

# DWM
alias csu='cd $HOME/.config/suckless/ && l' # przejdź do folderu suckless
alias cdw='cd $HOME/.config/suckless/dwm/ && l' # przejdź do folderu dwm
alias csl='cd $HOME/.config/suckless/slstatus/ && l' # przejdź do folderu slstatus
alias cst='cd $HOME/.config/suckless/st/ && l' # przejdź do folderu st (terminal)
alias csc='cd $HOME/.config/suckless/scripts/ && l' # przejdź do folderu skryptów suckless
alias chromium-browser='chromium-browser --ozone-platform=x11' # uruchom chromium wymuszając X11
alias remake='rm -r ./config.h && make && sudo make clean install' # przebudowanie i instalacja programu suckless (usuwa config.h)
alias libreoffice='GTK_THEME=Adwaita:light libreoffice' # uruchom LibreOffice z jasnym motywem
alias st='st -e /usr/bin/fish 2>/dev/null' # uruchom terminal st z powłoką fish

# Flatpak
alias fin='flatpak install flathub' # szybka instalacja z Flathuba
alias fun='flatpak uninstall' # standardowe odinstalowanie
alias fpu='flatpak uninstall --delete-data' # odinstalowanie z czyszczeniem danych konfiguracyjnych
alias fla='flatpak list --app' # pokazuje tylko zainstalowane aplikacje
alias fal='flatpak list' # pokazuje wszystko (aplikacje, runtime, sterowniki)
alias fse='flatpak search' # wyszukiwanie programów w repozytoriach
alias fup='flatpak update' # aktualizacja wszystkich pakietów
alias fcl='flatpak remove --unused' # usuwanie osieroconych bibliotek i runtime'ów

# Cargo
alias csp='cargo search' # szukanie programów
alias cip='cargo install' # instalacja  programów podać nazwę
alias cil='cargo install --list' # lista programów zainstalowanych przez cargo
alias cul='cargo install-update -a -l' # lista programów z informacją o aktualizacji
alias cua='cargo install-update -a' # aktualizacja wszytkich programów
alias cup='cargo install-update' # aktualizacja wybranego programu podać nazwę

# Tuned
alias tprofile='tuned-adm active' # pokaż aktywny profil
alias tlist='tuned-adm list' # lista dostępnych profili
alias tset='sudo tuned-adm profile' # zmiana profilu, np: tset powersave

alias tstart='sudo systemctl start tuned' # uruchom usługę
alias tstop='sudo systemctl stop tuned' # zatrzymaj usługę
alias trestart='sudo systemctl restart tuned' # restart usługi
alias tstatus='systemctl status tuned' # status usługi

# Onedrive
alias od-status='onedrive --display-sync-status' # Działa bez zatrzymywania
alias od-sync='systemctl --user stop onedrive && onedrive --sync && systemctl --user start onedrive' # Automatyczny stop/start
alias od-mon='onedrive --monitor' # Działa bez zatrzymywania
alias od-dry="onedrive --sync --dry-run" # test na sucho ręcznej synchronizacji

alias od-resync='systemctl --user stop onedrive && onedrive --resync --sync && systemctl --user start onedrive' # Resync (konieczne zatrzymanie onedrive)

alias od-stop='systemctl --user stop onedrive' # zatrzymanie onedrive
alias od-start='systemctl --user start onedrive' # uruchomione onedrive
alias od-enable='systemctl --user enable onedrive' # wyłączenie onedrive
alias od-disable='systemctl --user disable onedrive' # wyłączenie onedrive
alias od-status="systemctl --user status onedrive" # status usługi onedrive działającej w tle

alias od-log='journalctl --user -u onedrive -f' # sprawdzenie logów onedrive
alias od-resume='cat ~/.config/onedrive/resume.json' # onedrive sprawdzenie pliku bazy

alias od-hard-reset="systemctl --user stop onedrive && rm ~/.config/onedrive/items.sqlite3 ~/.config/onedrive/resume.json && onedrive --resync --sync && systemctl --user start onedrive" # Hard reset (usuwa bazę i sesje uploadu) onedrive

#    onedrive > Jak tego używać w praktyce (workflow)
# 1. onedrive sprawdzasz status > od-status 
# 2. onedrive jeśli coś nie działa → restart > od-stop && od-start 
# 3. onedrive jeśli nadal nie działa → resync > od-resync 
# 4. onedrive jeśli klient zwariował → hard reset > od-hard-reset 
# 5. onedrive jeśli chcesz mieć ciągłą synchronizację > od-mon lub > od-enable (autostart) 

# Google Drive
alias gdm='gdrive-on-off.sh' # montowanie i odmontowanie Google Drive

# Johnny.Decimial - JDEX.md struktura korzeni (funkcja jd w .bashrc / jd.fish)
alias j="jd" # wyświetli korzenie i obszary
alias jh='jd hw' # po podaniu numeru wyświetli kategorię z korzenia HW
alias jj='jd jk' # po podaniu numeru wyświetli kategorię z korzenia JK
