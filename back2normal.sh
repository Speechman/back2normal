#!/bin/bash
#
#
# De-Gender Script (v3.1)
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

# Volumes in Array einlesen
volumes=()
while IFS= read -r line; do
    volumes+=("$line")
done < <(
    diskutil list |
    awk '/APFS Volume/ && !/VM|Recovery|Preboot|macOS Base System|- Data/ {
        sub(/.*APFS Volume[[:space:]]+/, "", $0)
        # nur bis vor die Größe (mehrere Leerzeichen vor GB, MB usw.)
        sub(/[[:space:]]+[0-9]+(\.[0-9]+)?[[:space:]]*(GB|MB|TB).*/, "", $0)
        print
    }'
)

if [ ${#volumes[@]} -eq 0 ]; then
    echo "⚠️ Kein System-Volume gefunden."
    exit 1
fi

# Falls nur eins gefunden → automatisch nehmen
if [ ${#volumes[@]} -eq 1 ]; then
    sys_part="${volumes[0]}"
    echo "✅ Gefunden: $sys_part"
else
    echo -e "🔍 Bitte wähle das System-Volume aus:\n"
    i=1
    for vol in "${volumes[@]}"; do
        printf "  %d) %s\n" "$i" "$vol"
        i=$((i+1))
    done
    echo
    read -rp "Nummer eingeben: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#volumes[@]} ]; then
        echo "❌ Ungültige Auswahl."
        exit 1
    fi
    sys_part="${volumes[$((choice-1))]}"
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

echo -e "📸 Erstelle Snapshot..."
if bless --mount /Volumes/"$sys_part" --bootefi --create-snapshot; then
	echo -e "\n✅ Änderungen wurden erfolgreich manifestiert!"
	echo -e "\n‼️ Hinweis: Sollten im System noch Fragmente der Gendersprache vorhanden sein, so führe mit dem Tool 'Onyx' unter 'Optimieren' alleinig Neuaufbau der Launch Services Datenbank aus. Alle anderen Optionen können dort ignoriert werden."
	echo -e "\n🔁 Starte den Mac nun aber erst einmal neu mit: reboot"
else
	echo -e "\n⚠️ Fehler beim Erstellen des Snapshots.\n"
fi
