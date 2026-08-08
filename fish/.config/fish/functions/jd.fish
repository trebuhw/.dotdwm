function jd --description 'System przeglądania Johnny.Decimal (JDEX)'
    set -l target $argv[1] # nazwa korzenia, np. hw, jk (opcjonalny — bez tego pokazuje wszystkie korzenie)
    set -l num $argv[2]     # numer kategorii/modułu/szuflady (opcjonalny), np. 21, 21.40, 01.10, !0
    set -l file ~/.jd/JDEX.md

    if not test -r "$file"
        echo "Nie znaleziono pliku indeksu: $file"
        return 1
    end

    # Dynamicznie wykryj wszystkie korzenie w pliku (linie "# KORZEŃ: XXX", bierzemy tylko skrót przed spacją/nawiasem)
    set -l korzenie (grep -o '^# KORZEŃ: [A-Za-z0-9]*' $file | sed 's/^# KORZEŃ: //')

    if test (count $korzenie) -eq 0
        echo "Nie znaleziono żadnego korzenia (linii '# KORZEŃ: ...') w $file"
        return 1
    end

    # Brak podanego korzenia: pokaż WSZYSTKIE korzenie z ich głównymi obszarami
    if test -z "$target"
        for k in $korzenie
            echo "=== KORZEŃ: $k ==="
            sed -n "/# KORZEŃ: $k/,/^---/p" $file | grep '^## \['
            echo
        end
        return 0
    end

    # Dopasuj podany korzeń (bez rozróżniania wielkości liter) do wykrytej listy
    set -l target_upper (string upper -- $target)
    set -l dopasowany ""
    for k in $korzenie
        if test (string upper -- $k) = "$target_upper"
            set dopasowany $k
            break
        end
    end

    if test -z "$dopasowany"
        echo "Nieznany korzeń: '$target'. Dostępne: $korzenie"
        return 1
    end

    # Wytnij blok danego korzenia (od nagłówka korzenia do kolejnego "---" lub końca pliku)
    set -l blok (sed -n "/# KORZEŃ: $dopasowany/,/^---/p" $file)

    if test -z "$num"
        # Brak numeru: spis treści najwyższego poziomu (nagłówki "## [...]")
        printf '%s\n' $blok | grep '^## \['
        return 0
    end

    # Podano numer: wyciągnij tę linię i wszystko, co jest jej "dzieckiem",
    # niezależnie od tego, czy to nagłówek "## [XX]" czy zagnieżdżony punkt "- [XX.YY]".
    printf '%s\n' $blok | awk -v num="$num" '
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
end
