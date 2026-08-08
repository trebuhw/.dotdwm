# Dokumentacja Konfiguracyjna DWM (Fedora + GDM/startx)

Ten plik zawiera mapę kluczowych plików konfiguracyjnych Twojego środowiska. 
Dzięki architekturze "jednego punktu startowego", edycja jest scentralizowana.

## 1. Główny Inicjalizator Sesji
*   **Plik:** `/usr/local/bin/start-dwm.sh`
*   **Cel:** Most między GDM/startx a środowiskiem DWM.
*   **Co tu edytować?**
    *   Dodawanie zmiennych środowiskowych istotnych dla sesji graficznej (np. `GDK_BACKEND`, tematy QT).
    *   Wstrzykiwanie zmiennych do `systemd` i `D-Bus` (nie usuwaj komend `import-environment`!).
    *   Tu startują demony sesyjne (np. `xfce-polkit`, `slstatus`).

## 2. Autostart Aplikacji (DWM)
*   **Plik:** `~/.config/suckless/scripts/autostart.sh` (lub ścieżka zdefiniowana w patchu autostartu)
*   **Cel:** Uruchamianie aplikacji "kosmetycznych" i użytkowych tła.
*   **Co tu edytować?**
    *   Tapeta (`feh`), kompozytor (`picom`), `numlockx`.
    *   Demony, które wymagają kontroli procesu (używaj funkcji `run`).
    *   Skrypty monitorujące (np. `bat-mon.sh`).

## 3. Zmienne Środowiskowe i Ścieżki (PATH)
*   **Pliki:** `~/.bashrc` oraz `~/.bash_profile`
*   **Cel:** Definiowanie `$PATH`, aliasy powłoki, ustawienia historii, `Zoxide`, `Starship`.
*   **Ważne:** Wszystkie zmiany tutaj są automatycznie "widoczne" w `start-dwm.sh` dzięki ładowaniu profili.
*   **Uwaga:** Nie eksportuj tutaj `DISPLAY` ani `XDG_SESSION_TYPE` – to jest zarządzane dynamicznie przez `start-dwm.sh`.

## 4. Wejście z konsoli (TTY)
*   **Plik:** `~/.xinitrc`
*   **Cel:** Tylko przekazanie sterowania.
*   **Co tu edytować?**
    *   Absolutnie nic, chyba że zmieniasz ścieżkę do głównego wrappera.

## 5. Logika Baterii
*   **Plik:** `~/.config/suckless/scripts/bat-mon.sh`
*   **Cel:** Monitorowanie stanu baterii.
*   **Co tu edytować?**
    *   Zmiana progów ostrzegania (15%, 10%, 5%).
    *   Dostosowanie nazwy baterii (`BAT0` vs `BAT1`).

---

### Dlaczego tak to zorganizowaliśmy? (Architektura)
1. **GDM -> start-dwm.sh**: Zapewnia poprawne środowisko D-Bus i systemd dla sesji.
2. **start-dwm.sh -> autostart.sh**: DWM uruchamia własne aplikacje dopiero, gdy sesja jest w pełni przygotowana.
3. **Brak "sztywnych" zmiennych**: Dzięki usuwaniu `DISPLAY=:0` z plików `.bashrc` i `.config/fish`, system jest odporny na zmianę numeru wyświetlacza przez GDM.