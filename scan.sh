#catalog.db Ersteller

script_path="$(dirname "$(realpath "$0")")"

find /System/Applications /System/iOSSupport /System/Library -type f \( \
    -name "Localizable.strings" \
    -o -name "schema.strings" \
    -o -name "MainMenu.strings" \
    -o -name "MAPreferences.strings" \
    -o -name "*.loctable" \
    -o -name "*.searchTerms" \
    -o -name "InfoPlist.strings" \
    -o -name "InfoPlist.loctable" \) \
    -exec ls "{}" \; \
> /tmp/applications

echo "/System/Library/CoreServices/SystemFolderLocalizations/de.lproj/SystemFolderLocalizations.strings" >> /tmp/applications
echo "/System/Library/ExtensionKit/Extensions/UsersGroups.appex/Contents/Resources/InfoPlist.loctable" >> /tmp/applications
echo "/System/Library/PrivateFrameworks/StorageManagement.framework/PlugIns/OtherUsersStorageExtension.appex/Contents/Resources/InfoPlist.loctable" >> /tmp/applications

export LC_TYPE=C
export LANG=C

input="/tmp/applications"

while IFS= read -r line
do

  grep -lf "$script_path"/suchbegriffe.txt "$line"

done < "$input"
