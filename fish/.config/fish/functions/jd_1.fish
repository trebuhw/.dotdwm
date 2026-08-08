function jd --description 'System przeglądania Johnny.Decimal (JDEX)'
    set -l target $argv[1] # hw lub jk
    set -l num $argv[2]     # numer kategorii/modułu/szuflady (opcjonalny), np. 21, 21.40, 01.10, !0
    set -l file ~/JDEX.md

    if test -z "$target"
        echo "Użycie: jd [hw|jk] [numer]"
        return 1
    end

    set -l korzen_grep ""
    if test "$target" = "hw"
        set korzen_grep "# KORZEŃ: HW"
    else if test "$target" = "jk"
        set korzen_grep "# KORZEŃ: JK"
    else
        echo "Nieznany korzeń: '$target'. Użyj 'hw' lub 'jk'."
        return 1
    end

    if not test -r "$file"
        echo "Nie znaleziono pliku indeksu: $file"
        return 1
    end

    # Wytnij blok danego korzenia (od nagłówka korzenia do kolejnego "---" lub końca pliku)
    set -l blok (sed -n "/$korzen_grep/,/^---/p" $file)

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
