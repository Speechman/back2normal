#!/bin/bash
#
#
# De-Gender Script (v3.3)
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

# APFS-Rollen statt Volume-Namen verwenden (auch bei umbenannten Volumes).
plist_value() {
    plutil -extract "$1" raw -o - - 2>/dev/null
}

apfs_devices_with_role() {
    local role="$1" ci=0 vi prefix roles device
    while printf '%s' "$apfs_layout" | plist_value "Containers.$ci.ContainerReference" >/dev/null; do
        vi=0
        while :; do
            prefix="Containers.$ci.Volumes.$vi"
            device=$(printf '%s' "$apfs_layout" | plist_value "$prefix.DeviceIdentifier") || break
            roles=$(printf '%s' "$apfs_layout" | plutil -extract "$prefix.Roles" json -o - - 2>/dev/null)
            case "$roles" in
                *\""$role"\"*) printf '%s\n' "$device" ;;
            esac
            vi=$((vi+1))
        done
        ci=$((ci+1))
    done
}

# Nur das Data-Volume derselben APFS-Volume-Gruppe anbieten.
# unlockVolume entsperrt FileVault temporär; es deaktiviert keine Verschlüsselung.
prepare_data_volume() {
    local system_device="$1" system_info system_group device info group name
    local mounted locked status choice index selected_info
    local data_devices=() data_labels=()

    system_info=$(diskutil info -plist "$system_device") || return 1
    system_group=$(printf '%s' "$system_info" | plist_value APFSVolumeGroupID)
    if [ -z "$system_group" ]; then
        echo "⛔ Die APFS-Volume-Gruppe des Systems konnte nicht ermittelt werden."
        return 1
    fi

    while IFS= read -r device; do
        info=$(diskutil info -plist "$device") || return 1
        group=$(printf '%s' "$info" | plist_value APFSVolumeGroupID)
        [ "$group" = "$system_group" ] || continue
        name=$(printf '%s' "$info" | plist_value VolumeName)
        mounted=$(printf '%s' "$info" | plist_value MountPoint)
        locked=$(printf '%s' "$info" | plist_value Locked)
        if [ "$locked" = true ]; then
            status="verschlüsselt und gesperrt"
        elif [ -n "$mounted" ]; then
            status="eingehängt: $mounted"
        else
            status="nicht eingehängt"
        fi
        data_devices+=("$device")
        data_labels+=("$name — /dev/$device — $status")
    done < <(apfs_devices_with_role Data)

    if [ ${#data_devices[@]} -eq 0 ]; then
        echo "⛔ Kein zugehöriges APFS-Data-Volume gefunden. Abbruch."
        return 1
    fi

    # Bereits eingehängtes, eindeutig zugeordnetes Data-Volume unverändert nutzen.
    if [ ${#data_devices[@]} -eq 1 ]; then
        info=$(diskutil info -plist "${data_devices[0]}") || return 1
        mounted=$(printf '%s' "$info" | plist_value MountPoint)
        locked=$(printf '%s' "$info" | plist_value Locked)
        if [ -n "$mounted" ] && [ "$locked" = false ]; then
            data_mount="$mounted"
            echo "✅ Data-Volume bereits eingehängt: $mounted"
            return 0
        fi
    fi

    echo
    echo "🔍 Bitte wähle das Data-Volume für das gewählte System aus:"
    index=0
    while [ "$index" -lt ${#data_devices[@]} ]; do
        printf '  %d) %s\n' "$((index+1))" "${data_labels[$index]}"
        index=$((index+1))
    done
    echo "  0) Abbrechen"
    read -r -p "Nummer eingeben: " choice || return 1
    case "$choice" in
        0) echo "Abbruch."; return 1 ;;
        ''|*[!0-9]*) echo "❌ Ungültige Auswahl."; return 1 ;;
    esac
    # Führende Nullen nicht als Oktalzahlen interpretieren.
    if [ "${#choice}" -gt 6 ]; then
        echo "❌ Ungültige Auswahl."
        return 1
    fi
    index=$((10#$choice-1))
    if [ "$index" -lt 0 ] || [ "$index" -ge ${#data_devices[@]} ]; then
        echo "❌ Ungültige Auswahl."
        return 1
    fi
    device="${data_devices[$index]}"
    selected_info=$(diskutil info -plist "$device") || return 1
    locked=$(printf '%s' "$selected_info" | plist_value Locked)

    if [ "$locked" = true ]; then
        echo "🔐 Das Data-Volume /dev/$device muss vor dem Einhängen entsperrt werden."
        echo "FileVault bleibt aktiv. diskutil fragt das Passwort direkt ab."
        read -r -p "Jetzt entsperren? (j/n): " choice || return 1
        case "$choice" in
            j|J|ja|Ja) ;;
            *) echo "Abbruch: Data-Volume bleibt gesperrt."; return 1 ;;
        esac
        if ! diskutil apfs unlockVolume "$device"; then
            echo "⛔ Entsperren fehlgeschlagen. Abbruch."
            return 1
        fi
    elif [ "$locked" != false ]; then
        echo "⛔ Sperrstatus des Data-Volumes konnte nicht ermittelt werden."
        return 1
    fi

    info=$(diskutil info -plist "$device") || return 1
    mounted=$(printf '%s' "$info" | plist_value MountPoint)
    if [ -z "$mounted" ]; then
        if ! diskutil mount "$device"; then
            echo "⛔ Data-Volume konnte nicht eingehängt werden."
            return 1
        fi
    fi
    info=$(diskutil info -plist "$device") || return 1
    mounted=$(printf '%s' "$info" | plist_value MountPoint)
    locked=$(printf '%s' "$info" | plist_value Locked)
    if [ -z "$mounted" ] || [ ! -d "$mounted" ] || [ "$locked" != false ]; then
        echo "⛔ Data-Volume ist weiterhin gesperrt oder nicht eingehängt."
        return 1
    fi
    data_mount="$mounted"
    echo "✅ Data-Volume eingehängt: $mounted"
}

# Nur Bundle-Metadaten benötigen eine erneute Registrierung nach der Anmeldung.
registration_targets() (
    set -o pipefail
    local catalog="$1" system_root="$2" resource bundle
    while IFS= read -r resource || [ -n "$resource" ]; do
        resource="/${resource#/}"
        case "$resource" in
            /System/*/InfoPlist.loctable|/System/*/InfoPlist.strings) ;;
            *) continue ;;
        esac
        case "$resource" in */../*|*/./*) return 1 ;; esac
        [ -f "${system_root%/}$resource" ] || continue
        case "$resource" in
            *.appex/*) bundle="${resource%%.appex/*}.appex" ;;
            *.app/*) bundle="${resource%%.app/*}.app" ;;
            *) continue ;;
        esac
        printf '%s\n' "$bundle"
    done < "$catalog" | sort -u
)

write_registration_helper() {
    cat <<'B2N_LOGIN_HELPER'
#!/bin/bash
# Wird im angemeldeten Benutzerkonto ausgeführt, niemals im Recovery oder als root.
set -o pipefail
umask 077
label=local.back2normal.refresh-registration
state_dir=$(cd "$(dirname "$0")" && pwd -P) || exit 1
agent_plist="$1"
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
pluginkit=/usr/bin/pluginkit
launchctl=/bin/launchctl

[ "$(/usr/bin/id -u)" -ne 0 ] || exit 1
[ -f "$state_dir/targets.txt" ] || exit 1
[ -n "$agent_plist" ] || exit 1
exec >> "$state_dir/registration.log" 2>&1
printf '\n--- Registrierung: %s ---\n' "$(/bin/date)"
dump_file=$(/usr/bin/mktemp "$state_dir/.register.XXXXXX") || exit 1
trap '/bin/rm -f "$dump_file"' EXIT

localized_value() {
    local bundle="$1" key="$2" resources="$1/Contents/Resources"
    /usr/bin/plutil -extract "de.$key" raw -o - "$resources/InfoPlist.loctable" 2>/dev/null && return 0
    /usr/bin/plutil -extract "$key" raw -o - "$resources/de.lproj/InfoPlist.strings" 2>/dev/null
}

record_matches() {
    B2N_BUNDLE_PATH="$1" B2N_FIELD="$2" B2N_VALUE="$3" /usr/bin/awk '
        /^path:[[:space:]]/ {
            path = $0
            sub(/^path:[[:space:]]+/, "", path)
            sub(/ \(0x[[:xdigit:]]+\)$/, "", path)
            selected = (path == ENVIRON["B2N_BUNDLE_PATH"])
            if (selected && ENVIRON["B2N_FIELD"] == "") found = 1
        }
        selected && index($0, ENVIRON["B2N_FIELD"] ":") == 1 {
            wanted = "\"de\" = \"" ENVIRON["B2N_VALUE"] "\""
            if (index($0, wanted)) found = 1
        }
        END { exit(found ? 0 : 1) }
    ' "$dump_file"
}

failed=0
while IFS= read -r bundle || [ -n "$bundle" ]; do
    case "$bundle" in /System/*.appex|/System/*.app) ;; *) failed=1; continue ;; esac
    if [ ! -d "$bundle" ]; then
        printf 'Nicht mehr installiert, übersprungen: %s\n' "$bundle"
        continue
    fi
    printf 'Registriere: %s\n' "$bundle"
    case "$bundle" in
        *.appex) "$pluginkit" -a "$bundle" || failed=1 ;;
        *.app) "$lsregister" -f "$bundle" || failed=1 ;;
    esac
done < "$state_dir/targets.txt"

if ! "$lsregister" -dump > "$dump_file" || [ ! -s "$dump_file" ]; then
    echo 'Register konnte noch nicht gelesen werden. Erneuter Versuch in zwei Minuten.'
    exit 1
fi

while IFS= read -r bundle || [ -n "$bundle" ]; do
    [ -d "$bundle" ] || continue
    if ! record_matches "$bundle" '' ''; then
        printf 'Registrierung noch nicht sichtbar: %s\n' "$bundle"
        failed=1
        continue
    fi
    for key in CFBundleDisplayName CFBundleName; do
        if expected=$(localized_value "$bundle" "$key") && [ -n "$expected" ]; then
            case "$key" in
                CFBundleDisplayName) field=localizedNames ;;
                CFBundleName) field=localizedShortNames ;;
            esac
            if ! record_matches "$bundle" "$field" "$expected"; then
                printf 'Name noch nicht aktualisiert: %s (%s; erwartet: %s)\n' "$bundle" "$key" "$expected"
                failed=1
            fi
        fi
    done
done < "$state_dir/targets.txt"

if [ "$failed" -ne 0 ]; then
    echo 'Aktualisierung unvollständig. Erneuter Versuch in zwei Minuten.'
    exit 1
fi

echo 'Registrierung geprüft und abgeschlossen. Einmaligen LaunchAgent entfernen.'
/bin/rm -f "$dump_file"
# Protokoll bleibt für die Nachkontrolle erhalten.
if ! /bin/rm -f "$agent_plist" "$state_dir/targets.txt" "$state_dir/refresh.sh"; then
    echo 'Einmaliger Auftrag konnte nicht vollständig entfernt werden.'
    exit 1
fi
"$launchctl" bootout "gui/$(/usr/bin/id -u)/$label" >/dev/null 2>&1 || true
exit 0
B2N_LOGIN_HELPER
}

# Installation nur auf dem gewählten Data-Volume, nicht im Recovery-Benutzerkonto.
install_user_registration_agent() (
    local data_root="$1" user_home="$2" user_uid="$3" user_gid="$4" targets="$5"
    local offline_home="$data_root$user_home" directory state_dir agents_dir runtime_state
    local helper_tmp='' targets_tmp='' agent_tmp='' label=local.back2normal.refresh-registration
    state_dir="$offline_home/Library/Application Support/back2normal"
    agents_dir="$offline_home/Library/LaunchAgents"
    runtime_state="$user_home/Library/Application Support/back2normal"
    trap '[ -z "$helper_tmp" ] || rm -f "$helper_tmp"; [ -z "$targets_tmp" ] || rm -f "$targets_tmp"; [ -z "$agent_tmp" ] || rm -f "$agent_tmp"' EXIT

    # Beim Schreiben als Recovery-root keine Symlinks in Benutzerverzeichnissen verfolgen.
    for directory in "$offline_home" "$offline_home/Library" "$offline_home/Library/Application Support" "$state_dir" "$agents_dir"; do
        if [ -L "$directory" ] || { [ -e "$directory" ] && [ ! -d "$directory" ]; }; then
            echo "⛔ Kein reguläres Benutzerverzeichnis: $directory"
            return 1
        fi
        if [ ! -d "$directory" ]; then
            mkdir "$directory" && chown "$user_uid:$user_gid" "$directory" && chmod 700 "$directory" || return 1
        fi
    done
    for directory in "$state_dir/refresh.sh" "$state_dir/targets.txt" "$agents_dir/$label.plist"; do
        if [ -e "$directory" ] && [ ! -f "$directory" ]; then
            echo "⛔ Unerwartetes Installationsziel: $directory"
            return 1
        fi
    done
    helper_tmp=$(mktemp "$state_dir/.helper.XXXXXX") || return 1
    targets_tmp=$(mktemp "$state_dir/.targets.XXXXXX") || return 1
    agent_tmp=$(mktemp "$agents_dir/.back2normal.XXXXXX") || return 1
    write_registration_helper > "$helper_tmp" || return 1
    printf '%s\n' "$targets" > "$targets_tmp" || return 1
    /bin/bash -n "$helper_tmp" || return 1

    # plutil übernimmt XML-Escaping für Benutzernamen mit Sonderzeichen.
    plutil -create xml1 "$agent_tmp" || return 1
    plutil -insert Label -string "$label" "$agent_tmp" || return 1
    plutil -insert ProgramArguments -array "$agent_tmp" || return 1
    plutil -insert ProgramArguments.0 -string /bin/bash "$agent_tmp" || return 1
    plutil -insert ProgramArguments.1 -string "$runtime_state/refresh.sh" "$agent_tmp" || return 1
    plutil -insert ProgramArguments.2 -string "$user_home/Library/LaunchAgents/$label.plist" "$agent_tmp" || return 1
    plutil -insert RunAtLoad -bool true "$agent_tmp" || return 1
    plutil -insert StartInterval -integer 120 "$agent_tmp" || return 1
    plutil -insert LimitLoadToSessionType -string Aqua "$agent_tmp" || return 1
    plutil -insert ProcessType -string Background "$agent_tmp" || return 1
    plutil -lint "$agent_tmp" >/dev/null || return 1
    chmod 700 "$helper_tmp" && chmod 600 "$targets_tmp" && chmod 644 "$agent_tmp" || return 1
    chown "$user_uid:$user_gid" "$helper_tmp" "$targets_tmp" "$agent_tmp" || return 1
    mv -f "$helper_tmp" "$state_dir/refresh.sh" || return 1
    mv -f "$targets_tmp" "$state_dir/targets.txt" || return 1
    # Erst die vollständige Installation durch den Agent aktivieren.
    mv -f "$agent_tmp" "$agents_dir/$label.plist" || return 1
)

install_registration_agents() {
    local data_root="$1" targets="$2" user_record user_uid user_gid user_home installed=0
    [ -n "$targets" ] || { echo 'ℹ️ Keine Bundle-Metadaten zur Neuregistrierung im Katalog.'; return 0; }
    for user_record in "$data_root"/private/var/db/dslocal/nodes/Default/users/*.plist; do
        [ -f "$user_record" ] || continue
        user_uid=$(plutil -extract uid.0 raw -o - "$user_record" 2>/dev/null) || continue
        user_gid=$(plutil -extract gid.0 raw -o - "$user_record" 2>/dev/null) || continue
        case "$user_uid:$user_gid" in *[!0-9:]*|:*|*:) continue ;; esac
        [ "$user_uid" -ge 501 ] || continue
        user_home=$(plutil -extract home.0 raw -o - "$user_record" 2>/dev/null) || continue
        case "$user_home" in /Users/*) ;; *) continue ;; esac
        case "$user_home" in */../*|*/./*|*/..|*/.|*$'\n'*|*$'\t'*) continue ;; esac
        [ -d "$data_root$user_home" ] || continue
        if ! install_user_registration_agent "$data_root" "$user_home" "$user_uid" "$user_gid" "$targets"; then
            echo "⛔ Automatische Neuregistrierung für $user_home konnte nicht vorbereitet werden."
            return 1
        fi
        echo "✅ Einmalige Neuregistrierung bei der nächsten Anmeldung vorbereitet: $user_home"
        installed=$((installed+1))
    done
    if [ "$installed" -eq 0 ]; then
        echo '⛔ Kein lokales Benutzerkonto mit zugänglichem Benutzerordner gefunden.'
        return 1
    fi
}


if ! apfs_layout=$(diskutil apfs list -plist); then
    echo "⛔ APFS-Volumes konnten nicht ermittelt werden."
    exit 1
fi
volumes=()
while IFS= read -r device; do
    volumes+=("$device")
done < <(apfs_devices_with_role System)

if [ ${#volumes[@]} -eq 0 ]; then
    echo "⚠️ Kein System-Volume gefunden."
    exit 1
fi

if [ ${#volumes[@]} -eq 1 ]; then
    sys_device="${volumes[0]}"
else
    echo "🔍 Bitte wähle das System-Volume aus:"
    i=1
    for device in "${volumes[@]}"; do
        info=$(diskutil info -plist "$device") || exit 1
        name=$(printf '%s' "$info" | plist_value VolumeName)
        printf '  %d) %s — /dev/%s\n' "$i" "$name" "$device"
        i=$((i+1))
    done
    read -r -p "Nummer eingeben (0 = Abbruch): " choice || exit 1
    case "$choice" in
        ''|*[!0-9]*) echo "❌ Ungültige Auswahl."; exit 1 ;;
    esac
    [ "${#choice}" -le 6 ] || exit 1
    index=$((10#$choice-1))
    if [ "$index" -lt 0 ] || [ "$index" -ge ${#volumes[@]} ]; then
        echo "Abbruch: Keine gültige Auswahl."
        exit 1
    fi
    sys_device="${volumes[$index]}"
fi

info=$(diskutil info -plist "$sys_device") || exit 1
sys_part=$(printf '%s' "$info" | plist_value VolumeName)
echo "✅ System-Volume: $sys_part — /dev/$sys_device"

# Data wird auch zum Vorbereiten der benutzerspezifischen LaunchAgents benötigt.
prepare_data_volume "$sys_device" || exit 1

info=$(diskutil info -plist "$sys_device") || exit 1
sys_mount=$(printf '%s' "$info" | plist_value MountPoint)
if [ -z "$sys_mount" ]; then
    diskutil mount "$sys_device" || exit 1
    info=$(diskutil info -plist "$sys_device") || exit 1
    sys_mount=$(printf '%s' "$info" | plist_value MountPoint)
fi
if [ -z "$sys_mount" ] || [ ! -d "$sys_mount" ]; then
    echo "⛔ System-Volume ist nicht eingehängt."
    exit 1
fi

if ! mount -uw "$sys_mount" || [ ! -w "$sys_mount" ]; then
    echo "⛔ Konnte System-Volume nicht beschreibbar mounten. Prüfe SIP-Status!"
    exit 1
fi

# Erst jetzt prüfen: Der Katalog kann auf dem zuvor gesperrten Data-Volume liegen.
if [ ! -f "$script_path/catalog.db" ]; then
    echo "⛔ Datei 'catalog.db' fehlt im Skriptverzeichnis. Führe zuerst scan.sh im Live-System aus."
    exit 1
fi

export LC_TYPE=C
export LANG=C

cd "$sys_mount" || exit 1

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
if bless --mount "$sys_mount" --bootefi --create-snapshot; then
	echo -e "\n✅ Änderungen wurden erfolgreich manifestiert!"
    registration_list=$(registration_targets "$input" "$sys_mount") || exit 1
    if ! install_registration_agents "$data_mount" "$registration_list"; then
        echo "⚠️ Systemänderungen sind gespeichert, die automatische Neuregistrierung konnte jedoch nicht vollständig vorbereitet werden."
        exit 1
    fi
    echo "✅ Die Registrierung wird nach dem Neustart bei der nächsten Anmeldung automatisch aktualisiert."
    echo "ℹ️ Das Protokoll liegt im jeweiligen Benutzerordner unter Library/Application Support/back2normal/registration.log."
	echo -e "\n🔁 Starte den Mac nun aber erst einmal neu mit: reboot"
else
	echo -e "\n⚠️ Fehler beim Erstellen des Snapshots.\n"
fi
