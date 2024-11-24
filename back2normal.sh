#!/bin/bash
#
#
# De-Gender Script (v2.0)
#
# Endlich wieder normales Deutsch für macOS!
#
# Das Script setzt voraus, dass Du dich bereits im Terminal des Recovery Modus Deins Mac/Hacks befindest.

if [ -f /usr/sbin/system_profiler ]; then
    echo -e "\nDieses Script ist nicht dafür konzipiert im laufenden, normalen System ausgeführt zu werden. Es ist ausschließlich für den Recovery Modus bestimmt. Vorgang bricht nun ab. Details sind hier zu finden:\n\nhttps://github.com/Speechman/back2normal\n"
    exit 1
fi

sys_version=$( sw_vers |grep ProductVersion | sed -e 's/.*://g' -e 's/\..*//g' |xargs )
if [ "$sys_version" -lt "13" ]; then
    echo -e "\nDiese macOS Version ($sys_version.x) wird nicht unterstützt. Vorgang bricht nun ab.\n"
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

script_path="$(dirname "$(realpath "$0")")"

if [ ! -f "$script_path"/catalog.db ] ;then
  echo "Die Datei 'catalog.db' fehlt. Bitte lege sie in den Ordner wo auch dieses Script liegt."
  exit 1
fi

echo -e "\nAnbei eine Übersicht mit den Volumes. Bitte wähle eines aus. '/Volumes/' musst Du nicht mit eintippen, bloß den Volumenamen"
echo -e "\nZ.B 'macOS'\n"

diskutil list |grep "APFS Volume" |sed 's/.*APFS\ Volume\ //g' |grep -v "VM" |grep -v "Recovery" |grep -v "Preboot" |grep -v "macOS Base System"

echo ""

printf 'Auf welcher Systempartition sollen die Änderungen erfolgen? '
read sys_part

if [ ! -d /Volumes/"$sys_part" ]; then
  echo -e "\nFehler! Die angegebene System Partition ist nicht vorhanden. Bitte prüfen."
  exit 1
fi

mount -uw /Volumes/"$sys_part"

if [ ! -w /Volumes/"$sys_part" ]; then
  echo -e "\nDie System Partition konnte nicht auf R/W gesetzt werden. Das Script bricht nun ab. SIP scheint nicht deaktiviert zu sein."
  echo "Besitzt Du einen originael Mac so gib nun folgendes ein:"
  echo ""
  echo "csrutil enable --without fs"
  echo "csrutil authenticated-root disable"
  echo ""
  echo "Solltes Du einen Hackintosh besitzen den Du via OpenCore bootest so schaue bitte bei dortania.github.io wie man die SIP deaktiviert."
  echo "Natürlich kannst Du aber auch wie oben für einen echten Mac beschrieben fortfahren."
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

rm Users/.localized >/dev/null 2>&1

echo -e "\nDateien manifestieren ..."

if bless --mount /Volumes/"$sys_part" --bootefi --create-snapshot; then
    echo -e "\nDie Änderungen wurden auf der System Partition gespeichert. Zum Neustarten gib folgendes ein:\n"
    echo -e "\nreboot\n"
else
    echo -e "Beim Blessen ist ein Fehler aufgetreten. Starte am besten den Rechner neu und versuche es erneut."
fi
