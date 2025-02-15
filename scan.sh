#catalog.db Ersteller

script_path="$(dirname "$(realpath "$0")")"

if [ -f "$script_path/catalog.db_neu" ]; then
	rm "$script_path/catalog.db_neu"
fi

if [ -f /tmp/applications_b2n ]; then
	rm /tmp/applications_b2n
fi

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

echo "/System/Library/CoreServices/SystemFolderLocalizations/de.lproj/SystemFolderLocalizations.strings" >> /tmp/applications_b2n
echo "/System/Library/ExtensionKit/Extensions/UsersGroups.appex/Contents/Resources/InfoPlist.loctable" >> /tmp/applications_b2n
echo "/System/Library/PrivateFrameworks/StorageManagement.framework/PlugIns/OtherUsersStorageExtension.appex/Contents/Resources/InfoPlist.loctable" >> /tmp/applications_b2n

export LC_CTYPE=C
export LANG=C

input="/tmp/applications_b2n"

while IFS= read -r line; do
  # Konvertiere die Datei in XML und durchsuche sie direkt
  if sudo plutil -convert xml1 -o - "$line" | xmllint --format - | grep -q -F -f "$script_path/suchbegriffe.txt"; then
    echo "$line" >> "$script_path/catalog.db_neu"
  fi
done < "$input"

echo -e "Der Katalog wurde in diesem Verzeichnis als catalog.db_neu erzeugt. Um ihn zu verwenden ersetze ihn gegen die\nbestehende catalog.db Datei."
