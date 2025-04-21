<h1 align="center">Genderfreies macOS!</h1>


<p align="center">
  <img src="https://user-images.githubusercontent.com/98193439/276884315-3c3efadf-b1a6-452e-b09a-eda1ff3a3eb8.png">
</p>

<h1 align="center">Wichtiger Hinweis im Voraus:</h1>
Bevor du fortfährst, beachte bitte, dass die erfolgreiche Ausführung dieses Skripts die Deaktivierung der SIP-Funktion "Filesystem Protections" erfordert. Falls dies bei dir bereits der Fall ist, kannst du direkt mit der Anleitung beginnen. Sollte SIP aktiviert sein, bedenke, dass das Abschalten dieser Funktion die Volumensignierung deaktiviert, ein wichtiges Sicherheitsmerkmal von Apple. Daher ist die Entscheidung zur Deaktivierung von SIP wohlüberlegt zu treffen.

## Beschreibung
Bist du es leid, dass macOS dir die deutsche Gendersprache aufzwingt, ohne eine alternative Option anzubieten? Mit diesem Skript kannst du im Recovery-Modus deine Systempartition von der Gendersprache befreien und zur altbekannten Sprache zurückkehren. Die einzige Voraussetzung ist, dass die SIP-Funktion "Filesystem Protections" deaktiviert ist. 

Dieses Skript funktioniert ab macOS Ventura (13.x).

## Schritt-für-Schritt-Anleitung:
1. Formatieren eines USB-Sticks oder nutze ein anderes Medium (Du kannst auch das User Verzeichnis des System Volumes verwenden) als FAT32 oder HFS+. Es müssen folgende 4 Dateien immer zusammen in einem Ordner sein:

- back2normal.sh
- suchbegriffe.txt
- scan.sh
  
2. Bevor Du ins Recovery startest musst Du noch eine catalog.db erzeugen. Dazu führst Du 'scan.sh' aus. Dies dauert ein paar Minuten. Die Datei catalog.db befindet sich danach ebenfalls in diesem Ordner. Es sind am Ende als 4 Dateien.
3. Starte deinen Mac im Recovery-Modus und öffne ein Terminal.
4. Führe den Befehl aus:
   

       bash /Volumes/NAME_DEINES_MEDIUMS/back2normal.sh
   

5. Der Rest des Vorgangs verläuft automatisch bzw. das Script fragt bei Bedarf nach. Nach etwa 5-10 Minuten ist der Prozess abgeschlossen.

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

EDIT:
Es hat sich herausgestellt, dass es nicht notwendig ist das Systen neu aufzusetzen. 
- Erstelle einen neuen User (z.b. "Update"). Logge Dich mit diesem User ein.
- Lade Dir einen Fullinstaller herunter und starte die Installation auf Dein bereits vorhandenes System. Keine Sorge, alle Deine Daten bleiben hierbei erhalten.
- Wenn die Installation durchgelaufen ist, melde Dich mit dem "Update" User an. NICHT mit Deinem regulären User!! Dann fährst Du das Gerät herunter und startest in den Recovery-Modus.
- Hier wie gewohnt das back2normal.sh Script ausführen.
- Et voila ist dein bereits vorhandenes altes System genderfrei.

Am besten ist es jedes zukünftige Update aus dem Update-User heraus zu starten. 

## Was ist der Haken an der Sache?
Die einzige Einschränkung ist, dass du die SIP-Funktion "Filesystem Protections" dauerhaft deaktiviert lassen musst, da die Signaturen der veränderten Dateien nicht mehr übereinstimmen.

## Fußnote
### Es sei ausdrücklich darauf hingewiesen, dass Eingriffe in das System auf eigene Gefahr geschehen. Es ist ratsam, stets ein Backup bereitzuhalten oder das Verfahren zuerst auf einem Testsystem auszuprobieren. Es besteht keine Haftung für Datenverlust. Zudem kann es nach einem Systemupdate erforderlich sein, das Skript erneut auszuführen. Alternativ steht jetzt auch die App "De-Genderizer" zur Verfügung, um die Patching-Operationen direkt im laufenden System durchzuführen.


