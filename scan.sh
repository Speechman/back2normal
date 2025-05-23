#catalog.db Ersteller

script_path="$(dirname "$(realpath "$0")")"

sys_version=$(sw_vers |grep ProductVersion | sed -e 's/.*://g' -e 's/\..*//g' |xargs)
if [ "$sys_version" -lt 13 ]; then
	echo -e "\n🚫 Diese macOS Version ($sys_version.x) wird nicht unterstützt.\n"
	exit 1
fi

if [ ! -f /usr/sbin/system_profiler ]; then
        echo -e "\n🚫 Dieses Skript darf nur im Live-System ausgeführt werden!\n"
        exit 1
fi

if [ -f /tmp/applications_b2n ]; then
	rm /tmp/applications_b2n
fi

if [ -f "$script_path/catalog.db" ]; then
	rm "$script_path/catalog.db"
fi

echo -e "\nErstellen von catalog.db (bitte hab etwas Geduld). Parser Fehler einfach ignorieren ...\n"

sudo find /System/Applications /System/iOSSupport /System/Library -type f \( \
    -name "Localizable.strings" \
    -o -name "schema.strings" \
    -o -name "MainMenu.strings" \
    -o -name "MAPreferences.strings" \
    -o -name "*.loctable" \
    -o -name "*.searchTerms" \
    -o -name "InfoPlist.strings" \
    -o -name "InfoPlist.loctable" \) \
    -exec ls "{}" \; \
> /tmp/applications_b2n

echo "/System/Library/PrivateFrameworks/StorageManagement.framework/PlugIns/OtherUsersStorageExtension.appex/Contents/Resources/InfoPlist.loctable" >> /tmp/applications_b2n

# Entfernt alle .lproj Ordner die nicht "de" enthalten
{ grep -v '\.lproj' /tmp/applications_b2n; grep '/de\.lproj/' /tmp/applications_b2n; } > /tmp/applications_b2n_n
rm /tmp/applications_b2n
mv /tmp/applications_b2n_n /tmp/applications_b2n

export LC_CTYPE=C
export LANG=C

input="/tmp/applications_b2n"

while IFS= read -r line; do
  # Konvertiere die Datei in XML und durchsuche sie direkt um diese Datei in den catalog zu schreiben
  if sudo plutil -convert xml1 -o - "$line" | xmllint --format - | grep -q -F -f "$script_path/suchbegriffe.txt"; then
    echo "$line" >> "$script_path/catalog.db"
  fi
done < "$input"

clear

if [ ! -f "$script_path/catalog.db" ]; then
    if [ -f /usr/share/degenderizer_brain.db ]; then
        cat /usr/share/degenderizer_brain.db | sed -e 's/=.*//g' -e 's/System\/Library/\/System\/Library/g' > "$script_path/catalog.db"
        echo -e "\n✅ Das Degendern schien schon einmal erfolgt zu sein. Damit Du es nochmal wiederholen kannst (z. B. nach einem Update), wurde die catalog.db aus dem vorherigen Degenderprozess wiederhergestellt."
        exit 0
    else
        echo -e "\n⚠️ Keine catalog.db vorhanden und auch keine Sicherung in /usr/share gefunden."
        exit 1
    fi
else
    echo -e "\n✅ Die Datei catalog.db wurde erzeugt oder ist bereits vorhanden."
fi

