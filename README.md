<h1 align="center">Genderfreies macOS!</h1>


<p align="center">
  <img src="https://user-images.githubusercontent.com/98193439/276884315-3c3efadf-b1a6-452e-b09a-eda1ff3a3eb8.png">
</p>

<h1 align="center">Wichtiger Hinweis im Voraus:</h1>
Bevor du fortfährst, beachte bitte, dass die erfolgreiche Ausführung dieses Skripts die Deaktivierung der SIP-Funktion "Filesystem Protections" erfordert. Falls dies bei dir bereits der Fall ist, kannst du direkt mit der Anleitung beginnen. Sollte SIP aktiviert sein, bedenke, dass das Abschalten dieser Funktion die Volumensignierung deaktiviert, ein wichtiges Sicherheitsmerkmal von Apple. Daher ist die Entscheidung zur Deaktivierung von SIP wohlüberlegt zu treffen.

## Beschreibung
Bist du es leid, dass macOS dir die deutsche Gendersprache aufzwingt, ohne eine alternative Option anzubieten? Mit diesem Skript kannst du im Recovery-Modus deine Systempartition von der Gendersprache befreien und zur altbekannten Sprache zurückkehren. Die einzige Voraussetzung ist, dass die SIP-Funktion "Filesystem Protections" deaktiviert ist. Falls dies nicht der Fall ist, kannst du dies im Recovery-Modus mit den folgenden beiden Terminal-Befehlen erledigen:

    csrutil enable --without fs
    csrutil authenticated-root disable

Alternativ kannst du dies auch auf einem Hackintosh mit OpenCore durchführen.

Dieses Skript funktioniert ab macOS Ventura (13.x).

## Schritt-für-Schritt-Anleitung:
1. Formatieren eines USB-Sticks als FAT32 oder HFS+ und Speichern des Skripts "back2normal.sh" sowie der Datenbank "catalog.db" darauf.
2. Starte deinen Mac im Recovery-Modus und öffne ein Terminal.
3. Führe den Befehl aus:
   

       bash /Volumes/NAME_DEINES_STICKS/back2normal.sh
   

1. Das Skript wird nach dem Startvorgang und der Auswahl des zu bearbeitenden Volumes fragen. Beachte, nicht die Partition mit dem Namen "- Data" auszuwählen.
2. Der Rest des Vorgangs verläuft automatisch. Nach etwa 5-10 Minuten ist der Prozess abgeschlossen.
3. Gib am Ende "reboot" ein, und bei deinem nächsten Neustart erwartet dich ein macOS ohne genderbezogene Sprachanpassungen.

# Wiederherstellungsoption:
Falls während des Vorgangs etwas schiefgeht, kannst du im Recovery-Modus das letzte APFS-Snapshot wiederherstellen, um alles auf den Zustand vor der Ausführung des Skripts zurückzusetzen:

    bless --mount / --last-sealed-snapshot

# Anwendungsszenarien:

## 1. Frische Installation
- Lade die macOS-Installationsanwendung herunter und starte sie, um macOS auf einer neuen Partition zu installieren.
- Lasse die Installation durchlaufen und warte auf den Neustart.
- Starte im EFI-Startbildschirm das Volume "macOS Installer."
- Achte darauf, dass sich der Name des Zielvolumes im EFI-Startbildschirm zu dem Namen ändert den Du zuvor mit dem Festplattendienstprogramm vergeben hast.
- Starte in den Recovery-Modus und führe das Skript aus.
- Nach einem Neustart erwartet dich eine genderfreie Benutzeroberfläche.

## 2. Bereits bestehende Installation: 
- Starte das bestehende System im Recovery-Modus und führe das Skript aus.
- Starte das System neu. Ein Großteil der Sprachanpassungen wird übernommen.

Das war's! Im Wesentlichen verhält es sich wie bei einer frischen Installation, aber mit einer Besonderheit. Wenn du das System mit dem Skript von genderbezogener Sprache befreit hast und bereits ein oder mehrere Benutzer auf dem System vorhanden waren, wird ein Großteil der Sprachanpassungen nach einem Neustart übernommen. Es gibt jedoch drei Stellen, die weiterhin in genderbezogener Sprache verbleiben: Der "Benutzer:innen"-Ordner im Root-Verzeichnis und die Systemeinstellung "Benutzer:innen & Gruppen" sowie die dazugehörige Überschrift. Wenn dich das nicht stört, kannst du es so belassen. Wer jedoch darauf besteht, diese Sprachanpassungen zu entfernen, muss das System gemäß der Anleitung für eine "Frische Installation" auf einer anderen Partition neu aufsetzen und dann über den Migrations-Assistenten seine Daten zurückspielen. Danach kannst du sicher sein, dass die genderbezogene Sprache entfernt wurde.

## Was ist der Haken an der Sache?
Die einzige Einschränkung ist, dass du die SIP-Funktion "Filesystem Protections" dauerhaft deaktiviert lassen musst, da die Signaturen der veränderten Dateien nicht mehr übereinstimmen.

## Fußnote
### Es sei ausdrücklich darauf hingewiesen, dass Eingriffe in das System auf eigene Gefahr geschehen. Es ist ratsam, stets ein Backup bereitzuhalten oder das Verfahren zuerst auf einem Testsystem auszuprobieren. Es besteht keine Haftung für Datenverlust. Zudem kann es nach einem Systemupdate erforderlich sein, das Skript erneut auszuführen. Alternativ steht jetzt auch die App "De-Genderizer" zur Verfügung, um die Patching-Operationen direkt im laufenden System durchzuführen.

# Es gibt jetzt auch eine App (De-Genderizer) um das Patchen aus dem laufenden System heraus vorzunehmen
Hier kann man sie downloaden:

https://speechman.github.io/back2normal/app/degenderizer.zip
![grafik](https://github.com/Speechman/back2normal/assets/98193439/07c02f47-0ce9-4aee-92ca-b3758e00927b)

