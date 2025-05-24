#!/bin/bash
#
#
# De-Gender Script (v3.0)
#
# Endlich wieder normales Deutsch für macOS!
#
# Das Script setzt voraus, dass Du dich bereits im Terminal des Recovery Modus Deins Mac/Hacks befindest.

script_path="$(dirname "$(realpath "$0")")"

sys_version=$( sw_vers |grep ProductVersion | sed -e 's/.*://g' -e 's/\..*//g' |xargs )
if [ "$sys_version" -lt "13" ]; then
    echo -e "\n🚫 Diese macOS Version ($sys_version.x) wird nicht unterstützt.\n"
    exit 1
fi

if [ -f /usr/sbin/system_profiler ]; then
	echo -e "\n🚫 Dieses Skript darf nur im Recovery-Modus ausgeführt werden!\n"
	exit 1
fi

if [ ! -f "$script_path/catalog.db" ]; then
	echo -e "\n⛔ Datei 'catalog.db' fehlt im Skriptverzeichnis. Du musst im Live-System erst 'scan.sh' ausführen um diese Datei zu erzeugen."
	exit 1
fi

echo "🔍 Prüfe SIP-Status..."
fs_output=$(csrutil status)
ar_output=$(csrutil authenticated-root)

fs_needed=false
ar_needed=false

if echo "$fs_output" | grep "System Integrity Protection status: enabled."; then
	fs_needed=true
else
	echo -e "\n✅ SIP war bereits deaktiviert."
fi

if echo "$ar_output" | grep "Authenticated Root status: enabled"; then
	ar_needed=true
else
	echo -e "\n✅ Authenticated-Root war bereits deaktiviert.\n"
fi

if [ "$fs_needed" = true ]; then
	echo "➡️  Deaktiviere Filesystem Protection ..."
	csrutil enable --without fs
fi

if [ "$ar_needed" = true ]; then
	echo "➡️  Deaktiviere authenticated-root ..."
	csrutil authenticated-root disable
	echo -e "\n⚠️ Bitte boote Deinen Rechner erneut in den Recovery-Modus da mit die Änderung greift.\n"
	exit 1
fi

echo ""
echo "#######################################################"
echo "### Endlich wieder ein genderfreies Betriebssystem! ###"
echo "#######################################################"
echo ""

printf 'Soll das De-Gendern beginnen? (j/n) '
read answer

if [ "$answer" = "n" ] ;then
    echo -e "\nAbbruch ..."
    exit 0
elif [ "$answer" = "j" ] ;then
    echo -e "\nOk, los gehts!"
else
    echo -e "\nKeine gültige Eingabe. Nur j/n sind erlaubt."
    exit 1
fi

echo "📁 Ermittle System-Volume..."
sys_part=$(diskutil list | awk '/APFS Volume/ && !/VM|Recovery|Preboot|macOS Base System|- Data/ { sub(/.*APFS Volume[[:space:]]+/, "", $0); print }' | sed 's/\ \ .*//g')

if [ -z "$sys_part" ]; then
	echo "⚠️ System-Volume nicht gefunden. Liste möglicher Volumes:"
	diskutil list |grep "APFS Volume" |sed 's/.*APFS\ Volume\ //g' |grep -v "VM" |grep -v "Recovery" |grep -v "Preboot" |grep -v "macOS Base System" |grep -v "\- Data"
	read -rp echo -e "\nBitte wähle die System Festplatte aus. '/Volumes/' musst Du nicht mit eintippen, bloß den Volumenamen Z.B 'macOS'\n" sys_part
fi

if [ ! -d /Volumes/"$sys_part" ]; then
	echo -e "\n⛔ Volume /Volumes/$sys_part nicht gefunden! Das Script bricht nun ab. Bitte führe es erneut aus.\n"
	exit 1
fi

mount -uw /Volumes/"$sys_part"

if [ ! -w /Volumes/"$sys_part" ]; then
	echo "⛔ Konnte Volume nicht beschreibbar mounten. Prüfe SIP-Status!"
	exit 1
fi

export LC_TYPE=C
export LANG=C

cd /Volumes/"$sys_part"

echo -e "\nBearbeite Dateien ..."

input="$script_path/catalog.db"
count=$( wc -l "$input" | sed 's/\ a.*//g' |xargs )
counter=1

if [ ! -f usr/share/degenderizer_brain.db ]; then
    touch usr/share/degenderizer_brain.db
    chmod 777 usr/share/degenderizer_brain.db
else
    chmod 777 usr/share/degenderizer_brain.db
fi

while IFS= read -r line
do

  line=$( echo "$line" | sed 's/^\///' )

if [ -f "$line" ]; then
  
  hash_value=$( md5 "$line" | sed 's/.*=//g' | xargs )
  binary="0"

  if ! grep -x "$line""=""$hash_value" usr/share/degenderizer_brain.db >/dev/null 2>&1; then

  if [[ "$line" = *".loctable" ]] || [[ "$line" = *".strings" ]]; then
    binary="1"
    plutil -convert xml1 "$line" >/dev/null 2>&1
  fi

  sed -ib \
    -e 's/:INNEN//g' \
    -e 's/:IN//g' \
    -e 's/:innen//g' \
    -e 's/:in//g' \
    -e 's/:in|/|/g' \
    -e 's/:r|/r|/g' \
    -e 's/Aktuelle:r/Aktueller/g' \
    -e 's/aktuelle:n/aktuellen/g' \
    -e 's/Aktuelle:n/Aktuellen/g' \
    -e 's/ältere:r/älterer/g' \
    -e 's/ANDERE:R/ANDERER/g' \
    -e 's/angegebene:n/angegebenen/g' \
    -e 's/ausgewählte:r/ausgewählter/g' \
    -e 's/Beliebige:r/Beliebiger/g' \
    -e 's/Benutzer:in/Benutzer/g' \
    -e 's/Dein:e/Dein/g' \
    -e 's/dein:e/dein/g' \
    -e 's/deinem:deiner/deinem/g' \
    -e 's/deine:n/deinen/g' \
    -e 's/Delegierte:r/Delegierter/g' \
    -e 's/DEM:DER/DEM/g' \
    -e 's/dem:der/dem/g' \
    -e 's/den:die/den/g' \
    -e 's/Der:die/Der/g' \
    -e 's/Der:Die/Der/g' \
    -e 's/der:die/der/g' \
    -e 's/Der:die/Der/g' \
    -e 's/des:der/des/g' \
    -e 's/desselben:derselben/desselben/g' \
    -e 's/dessen:deren/dessen/g' \
    -e 's/diesem:dieser/diesem/g' \
    -e 's/Diese:n/Diesen/g' \
    -e 's/diese:n/diesen/g' \
    -e 's/Diese:r/Dieser/g' \
    -e 's/diese:r/dieser/g' \
    -e 's/dieses:dieser/dieses/g' \
    -e 's/ehemalige:r/ehemaliger/g' \
    -e 's/Ein:e/Ein/g' \
    -e 's/ein:e/ein/g' \
    -e 's/eine:n/einen/g' \
    -e 's/eines:einer/eines/g' \
    -e 's/einem:einer/einem/g' \
    -e 's/Empfohlene:r/Empfohlener/g' \
    -e 's/Entfernte:r/Entfernter/g' \
    -e 's/Erwachsene:r/Erwachsener/g' \
    -e 's/Erziehungsberechtigte:r/Erziehungsberechtigter/g' \
    -e 's/Erziehungsberechtigte:n/Erziehungsberechtigten/g' \
    -e 's/Gefangene:r/Gefangener/g' \
    -e 's/Gleiche:r/Gleicher/g' \
    -e 's/Hochgeladene:n/Hochgeladenen/g' \
    -e 's/jede:n/jeden/g' \
    -e 's/Jede:r/Jeder/g' \
    -e 's/jede:r/jeder/g' \
    -e 's/Jüngere:r/Jüngerer/g' \
    -e 's/Nächste:r/Nächster/g' \
    -e 's/NEUE:R/NEUER/g' \
    -e 's/Neue:r/Neuer/g' \
    -e 's/Selbe:r/Selber/g' \
    -e 's/Studierende:r/Studierender/g' \
    -e 's/Teilnehmende:r/Teilnehmender/g' \
    -e 's/Unbekanntem:unbekannter/Unbekanntem/g' \
    -e 's/Unbekannte:r/Unbekannter/g' \
    -e 's/Unterrichtende:r/Unterrichtender/g' \
    -e 's/Verwaltete:r/Verwalteter/g' \
    -e 's/vom:von/vom/g' \
    -e 's/Vorgesetzte:r/Vorgesetzter/g' \
    -e 's/Zahlungspflichtige:r/Zahlungspflichtiger/g' \
    "$line" >/dev/null 2>&1

	echo -ne " $counter von $count\r"
	((counter++))

	rm "$line"b >/dev/null 2>&1

	if [[ "$binary" = "1" ]]; then
    plutil -convert binary1 "$line" >/dev/null 2>&1
	fi

    hash_value=$( md5 "$line" | sed 's/.*=//g' | xargs )

	echo "$line""=""$hash_value" >> usr/share/degenderizer_brain.db

else
	echo -ne " $counter von $count war bereits gepatcht und wurde übersprungen\n"
	((counter++))
fi
fi

done < "$input"

chmod 444 usr/share/degenderizer_brain.db

if [ -f Users/.localized ]; then
	rm Users/.localized
fi

/Volumes/"$sys_part"/usr/bin/./xxd -p System/Library/CoreServices/com.apple.launchservices.lsd.csdb | tr -d '\n' > /private/tmp/com.apple.launchservices.lsd.csdb.dump

# "Benutzer:innen & Gruppen"
sed -i '' 's/42656e75747a65723a696e6e656e2026204772757070656e/42656e75747a65722026204772757070656e202020202020/g' /private/tmp/com.apple.launchservices.lsd.csdb.dump

# "Andere Benutzer:innen & Geteilte Dateien"
sed -i '' 's/416e646572652042656e75747a65723a696e6e656e20262047657465696c7465204461746569656e/416e646572652042656e75747a657220262047657465696c7465204461746569656e202020202020/g' /private/tmp/com.apple.launchservices.lsd.csdb.dump

# "Freund:innen"
sed -i '' 's/467265756e643a696e6e656e/467265756e64656e202020202020/g' /private/tmp/com.apple.launchservices.lsd.csdb.dump

/Volumes/"$sys_part"/usr/bin/./xxd -r -p /private/tmp/com.apple.launchservices.lsd.csdb.dump > System/Library/CoreServices/com.apple.launchservices.lsd.csdb

echo -e "📸 Erstelle Snapshot..."
if bless --mount /Volumes/"$sys_part" --bootefi --create-snapshot; then
	echo -e "\n✅ Änderungen wurden erfolgreich manifestiert!"
	echo -e "\n🔁 Starte den Mac neu mit: reboot"
else
	echo -e "\n⚠️ Fehler beim Erstellen des Snapshots.\n"
fi

