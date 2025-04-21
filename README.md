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
- catalog.db (erzeugst Du im nachfolgenden 2. Schritt)
  
2. Bevor Du ins Recovery startest musst Du noch eine catalog.db erzeugen. Dazu führst Du 'scan.sh' aus. Dies dauert ein paar Minuten. Die Datei catalog.db befindet sich danach ebenfalls in diesem Ordner.
3. Starte deinen Mac im Recovery-Modus und öffne ein Terminal.
4. Führe den Befehl aus:
   

       bash /Volumes/NAME_DEINES_MEDIUMS/back2normal.sh
   

5. Der Rest des Vorgangs verläuft automatisch bzw. das Script fragt bei Bedarf nach. Nach etwa 5-10 Minuten ist der Prozess abgeschlossen.

# Wiederherstellungsoption:
Falls während des Vorgangs etwas schiefgeht, kannst du im Recovery-Modus das letzte APFS-Snapshot wiederherstellen, um alles auf den Zustand vor der Ausführung des Skripts zurückzusetzen:

    bless --mount / --last-sealed-snapshot

# Anwendungsszenarien:

## 1. Frische Installation
- Nachdem die frische Installation durchgelaufen ist lege als erstes einen "Update"-User an (dieser muss Admin-Rechte haben). Bei mir heisst er sinnigerweise "Update". (-:
- Damit loggst Du Dich dann erstmal ein.
- Erzeuge mit scan.sh gemäß obenstehender Anleitung die notwendige catalog.db Datei.
- Fahre das Gerät herunter und starte unmittelbar ins Recovery
- Lass back2normal.sh durchlaufen
- Nach einem Reboot kannst Du dann Deine(n) Reguläre(n) User in macOS anlegen

## 2. Was tun bei einem Update: 
- Erstelle einen neuen User (z.b. "Update") sofern Du das nicht schon bei einer Neuinstallation getan hast. Logge Dich mit diesem User ein.
- Lasse das Update vom System einspielen.
- Neustart und direkter Reboot ins Recovery.
- Hier wie gewohnt das back2normal.sh Script ausführen.
 
## 3. Was tun wenn man das Update nicht mit dem "Updater"-User durchgeführt hat:    
- Lade Dir einen Fullinstaller herunter. (z.B. mit AnyMACOs oder GibMacOS). Starte die Installation auf Dein bereits vorhandenes System. Keine Sorge, alle Deine Daten bleiben hierbei erhalten. Es ist lediglich wie ein Update.
- Wenn die Installation durchgelaufen ist, melde Dich mit dem "Update" User an. NICHT mit Deinem regulären User!! Dann fährst Du das Gerät herunter und startest in den Recovery-Modus.
- Hier wie gewohnt das back2normal.sh Script ausführen.
- Danach kannst Du Dich mit dem regulären User wieder einloggen.

Am besten ist es jedes zukünftige Update aus dem "Update"-User heraus zu starten und danach im Recovery wie gehabt vorzugehen. Dann sollte künftig nichts mehr anbrennen.

## Warum das ganze Prozedere mit dem "Update"-User?
Beim erstmaligen Einloggen nach einem Update legt macOS irgendwelche Cache-Dateien des Users neu an. Darunter auch ein Teil der Lokalisation. Diese Cache-Dateien habe ich bis heute nirgends im System finden können. Evtl. sind diese auch verschlüsselt. Keine Ahnung. Demzufolge kann man sie auch nicht manuell verändern.


## Was ist der Haken an der Sache?
Die einzige Einschränkung ist, dass du die SIP-Funktion "Filesystem Protections" dauerhaft deaktiviert lassen musst, da die Signaturen der veränderten Dateien nicht mehr übereinstimmen.

## Fußnote
### Es sei ausdrücklich darauf hingewiesen, dass Eingriffe in das System auf eigene Gefahr geschehen. Es ist ratsam, stets ein Backup bereitzuhalten oder das Verfahren zuerst auf einem Testsystem auszuprobieren. Es besteht keine Haftung für Datenverlust. Zudem kann es nach einem Systemupdate erforderlich sein, das Skript erneut auszuführen. Alternativ steht jetzt auch die App "De-Genderizer" zur Verfügung, um die Patching-Operationen direkt im laufenden System durchzuführen.


