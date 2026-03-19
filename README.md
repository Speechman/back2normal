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
1. Formatieren eines USB-Sticks oder nutze ein anderes Medium (Du kannst auch das User Verzeichnis des System Volumes verwenden) als FAT32, EXFat, APFS oder HFS+. Es müssen folgende 4 Dateien immer zusammen in einem Ordner sein:

- back2normal.sh
- suchbegriffe.txt
- scan.sh
- catalog.db (erzeugst Du im nachfolgenden 2. Schritt)
  
2. Bevor Du ins Recovery startest musst Du noch eine catalog.db erzeugen. Dazu führst Du 'scan.sh' im Live-System aus. Dies dauert ein paar Minuten. Die Datei catalog.db befindet sich danach ebenfalls in diesem Ordner.
3. Starte deinen Mac im Recovery-Modus und öffne ein Terminal.
4. Führe den Befehl aus:
   

       bash /Volumes/NAME_DEINES_MEDIUMS/back2normal.sh
   

5. Gibt es mehrere Volumes kommt eine Abfrage welches genutzt werden soll. Gibt es nur eins wird dieses automatisch genommen. Der Rest des Vorgangs verläuft automatisch bzw. das Script fragt bei Bedarf nach. Nach etwa 5-10 Minuten ist der Prozess abgeschlossen.

# Wiederherstellungsoption:
Falls während des Vorgangs etwas schiefgeht (war bei mir noch nie der Fall aber man weiss ja nie), kannst du im Recovery-Modus das letzte APFS-Snapshot wiederherstellen, um alles auf den Zustand vor der Ausführung des Skripts zurückzusetzen:

    bless --mount / --last-sealed-snapshot

## Hinweis
Falls z.b. "Benutzer:innen & Gruppen" in den Einstellungen noch übriggeblieben ist kann man mittels diesem kostenlosen Programm: 

[OnyX](https://www.titanium-software.fr/en/onyx.html)

unter der Funktion

<img width="92" height="62" alt="image" src="https://github.com/user-attachments/assets/2da2bbfc-c36d-42c5-b635-6869be226c6f" />

mit dieser Option

<img width="871" height="68" alt="image" src="https://github.com/user-attachments/assets/54f000d4-b494-48e0-aad1-dc6705c16683" />

den Cache des LaunchServices neu aufbauen. Danach sind die Gender-Restspuren nach einem Neustart verschwunden.

## Was ist der Haken an der ganzen Sache?
Der einzige Nachteil ist, dass du die SIP-Funktion "Filesystem Protections" dauerhaft deaktiviert lassen musst, da die Signaturen der veränderten Dateien nicht mehr übereinstimmen.

## Fußnote
### Es sei ausdrücklich darauf hingewiesen, dass Eingriffe in das System auf eigene Gefahr geschehen. Es ist ratsam, stets ein Backup bereitzuhalten oder das Verfahren zuerst auf einem Testsystem auszuprobieren. Es besteht keine Haftung für Datenverlust. Zudem kann es nach einem Systemupdate erforderlich sein, das Skript erneut auszuführen. 

