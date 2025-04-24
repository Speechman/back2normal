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
    echo -e "\n✅ Es wurde keine catalog.db erzeugt weil Dein System bereits genderfrei ist. Herzlichen Glückwunsch."
else
    echo -e "\n✅ Die Datei catalog.db wurde erzeugt."
fi

