#!/bin/bash

app_name="usb-auto-eject-daemon"

timeout=900

# Volumes to eject if there is no user or Time Machine activity for the last `timeout` seconds
# WARNING: All the other volumes on the same physical disks will be ejected as well
volumes=(
    "/Volumes/volume01" 
    "/Volumes/volume02"
)

# Logging
log_file="$HOME/Library/Logs/$app_name/usb-auto-eject-$(date +%Y%m%d).log"
if ! mkdir -p "$(dirname "$log_file")"; then
    echo "Failed to create log directory, exiting"
    exit 1
fi

log() {
    printf "$app_name: %s\n" "$(date)" "$1" >> "$log_file"
}

# Check if the volumes are mounted
for index in "${!volumes[@]}"; do
    if ! mount | grep -q "${volumes[index]}"; then
        log "$(printf "%s is not mounted, removing from list" "${volumes[index]}")"
        unset 'volumes[index]'
    fi
done
# Re-index the array
volumes=("${volumes[@]}")
if [ ${#volumes[@]} -eq 0 ]; then
    log "No volumes are mounted, exiting"
    exit 0
fi

# Check for user activity
idleTime=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {printf "%d", $NF/1000000000; exit}')
if (( idleTime < timeout )); then
    log "$(printf "User idle time %s not reached threshold %s, exiting", "$idleTime", "$timeout")"
    exit 0
fi
log "$(printf "User idle time %s reached threshold %s, checking Time Machine activity", "$idleTime", "$timeout")"

# Check for Time Machine activity
if [ "$(tmutil currentphase)" != "BackupNotRunning" ]; then
    log "Time Machine is running, exiting"
    exit 0
fi
log "Time Machine is not running, checking for open files on the volumes"

# Log volumes to be ejected
log "$(printf "Volumes to be ejected: %s" "${volumes[*]}")"

# Get the physical disks for the volumes
# bash 3 compatible
disk_names=()
disk_count=0
for volume in "${volumes[@]}"; do
    disk_info=$($(which diskutil) info "$volume")
    disk=$(echo "$disk_info" | awk '/Part of Whole/ {print $4}')
    if [ -n "$disk" ]; then
        disk_names+=("$disk")
        ((disk_count++))
    else
        log "Failed to get disk for volume $volume"
    fi
done

# Check if disks isn't empty
if [ ${#disk_names[@]} -eq 0 ]; then
    log "No physical disks to eject, exiting"
    exit 0
fi
log "$(printf "Physical disks to be ejected: %s" "${disk_names[@]}")"

# Eject disks
eject_fails=0
for disk in "${disk_names[@]}"; do
    log "$(printf "Attempting to eject %s" "$disk")"
    if ! $(which diskutil) eject "$disk"; then
        log "$(printf "Failed to eject %s" "$disk")"
        ((eject_fails++))
    fi
done
if [ $eject_fails -eq $disk_count ]; then
    log "Failed to eject all disks"
    exit 1
fi
if [ $eject_fails -gt 0 ]; then
    log "$(printf "Failed to eject %s disks of %s" "$eject_fails" "$disk_count")"
    exit 1
fi

log "$(printf "Successfully ejected %s" "${disk_names[@]}")"
