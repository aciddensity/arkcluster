#!/usr/bin/env bash

function log { echo "$(date +%Y-%m-%dT%H:%M:%SZ): $*"; }

log "###########################################################################"
log "# Started  - $(date)"
log "# Server   - ${SESSION_NAME}"
log "# Cluster  - ${CLUSTER_ID}"
log "# User     - ${USER_ID}"
log "# Group    - ${GROUP_ID}"
log "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

rm -f /ark/server/.stopping-server
rm -f /ark/server/.installing-ark
rm -f /ark/server/.installing-mods

export TERM=linux

function stop {
    touch /ark/server/.stopping-server
    if [ "${BACKUPONSTOP}" -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks)" ]; then
        log "Creating Backup ..."
        arkmanager backup --cluster
    fi
    if [ "${WARNONSTOP}" -eq 1 ]; then
        arkmanager stop --warn
    else
        arkmanager stop
    fi
    rm -f /ark/server/.stopping-server
    exit
}

if ! [[ "$USER_ID" =~ ^[0-9]+$ ]] || ((10#$USER_ID == 0 || 10#$USER_ID > 2147483647)); then
    log "USER_ID must be an integer between 1 and 2147483647."
    exit 1
fi
if ! [[ "$GROUP_ID" =~ ^[0-9]+$ ]] || ((10#$GROUP_ID == 0 || 10#$GROUP_ID > 2147483647)); then
    log "GROUP_ID must be an integer between 1 and 2147483647."
    exit 1
fi

USER_ID=$((10#$USER_ID))
GROUP_ID=$((10#$GROUP_ID))
export USER_ID GROUP_ID

for secret_name in SERVER_PASSWORD ADMIN_PASSWORD SPECTATOR_PASSWORD; do
    secret_file_name="${secret_name}_FILE"
    secret_file="${!secret_file_name:-}"
    if [ -n "${!secret_name:-}" ] && [ -n "$secret_file" ]; then
        log "Set either $secret_name or $secret_file_name, not both."
        exit 1
    fi
    if [ -n "$secret_file" ]; then
        if [ ! -f "$secret_file" ] || [ ! -r "$secret_file" ]; then
            log "$secret_file_name must point to a readable file."
            exit 1
        fi
        printf -v "$secret_name" '%s' "$(<"$secret_file")"
        export "$secret_name"
    fi
done

existing_user=$(getent passwd "$USER_ID" | cut -d: -f1)
if [ -n "$existing_user" ] && [ "$existing_user" != steam ]; then
    log "USER_ID $USER_ID is already assigned to user '$existing_user'."
    exit 1
fi
existing_group=$(getent group "$GROUP_ID" | cut -d: -f1)
if [ -n "$existing_group" ] && [ "$existing_group" != steam ]; then
    log "GROUP_ID $GROUP_ID is already assigned to group '$existing_group'."
    exit 1
fi

old_user_id=$(id -u steam)
old_group_id=$(id -g steam)

# Change the primary group before changing the user ID.
if [ "$old_group_id" -ne "$GROUP_ID" ]; then
    log "Changing steam gid from $old_group_id to $GROUP_ID."
    groupmod -g "$GROUP_ID" steam
fi
if [ "$old_user_id" -ne "$USER_ID" ]; then
    log "Changing steam uid from $old_user_id to $USER_ID."
    usermod -u "$USER_ID" steam
fi

[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging
[ ! -d /ark/steam ] && mkdir /ark/steam
[ ! -d /ark/.steam ] && mkdir /ark/.steam

# Own the required directory roots, then migrate only files carrying the old
# steam IDs. This preserves files deliberately owned by other users.
chown steam:steam /ark /cluster /home/steam /ark/log /ark/backup /ark/staging /ark/steam /ark/.steam
if [ "$old_group_id" -ne "$GROUP_ID" ]; then
    find /ark /cluster /home/steam -xdev -gid "$old_group_id" -exec chgrp steam {} +
fi
if [ "$old_user_id" -ne "$USER_ID" ]; then
    find /ark /cluster /home/steam -xdev -uid "$old_user_id" -exec chown steam {} +
fi

if [ -f "/usr/share/zoneinfo/${TZ}" ]; then
    log "Setting timezone to ${TZ} ..."
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
fi

if [ ! -f /etc/cron.d/arkupdate ]; then
    log "Adding update cronjob (${CRON_AUTO_UPDATE}) ..."
    echo "$CRON_AUTO_UPDATE steam bash -l -c 'source /etc/container_environment.sh; arkmanager update --dots --update-mods --warn --ifempty --saveworld --backup >> /ark/log/ark-update.log 2>&1'" > /etc/cron.d/arkupdate
fi

if [ ! -f /etc/cron.d/arkbackup ]; then
    log "Adding backup cronjob (${CRON_AUTO_BACKUP}) ..."
    echo "$CRON_AUTO_BACKUP steam bash -l -c 'source /etc/container_environment.sh; arkmanager backup --cluster >> /ark/log/ark-backup.log 2>&1'" > /etc/cron.d/arkbackup
fi

# Cron starts with a minimal environment, so preserve Docker's environment for
# arkmanager jobs before starting the daemon.
: > /etc/container_environment.sh
while IFS= read -r variable_name; do
    [[ "$variable_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || continue
    case "$variable_name" in
        HOME | HOSTNAME | LOGNAME | PATH | PWD | SHELL | SHLVL | TERM | USER | _)
            continue
            ;;
    esac
    printf 'export %s=%q\n' "$variable_name" "${!variable_name}" >> /etc/container_environment.sh
done < <(compgen -e)
chown root:steam /etc/container_environment.sh
chmod 0640 /etc/container_environment.sh
/usr/sbin/cron

# We overwrite the default file each time
cp /home/steam/arkmanager-user.cfg /ark/default/arkmanager.cfg

# Copy default arkmanager.cfg if it doesn't exist
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager-user.cfg /ark/arkmanager.cfg
if [ ! -L /etc/arkmanager/instances/main.cfg ]; then
    rm /etc/arkmanager/instances/main.cfg
    ln -s /ark/arkmanager.cfg /etc/arkmanager/instances/main.cfg
fi

log "###########################################################################"

if [ ! -d /ark/server ] || [ ! -f /ark/server/version.txt ]; then
    log "No game files found. Installing..."
    mkdir -p /ark/server/ShooterGame/Saved/SavedArks
    mkdir -p /ark/server/ShooterGame/Content/Mods
    mkdir -p /ark/server/ShooterGame/Binaries/Linux
    touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
    chown -R steam:steam /ark/server
    touch /ark/server/.installing-ark
    arkmanager install --dots
    rm -f /ark/server/.installing-ark
else
    if [ "${BACKUPONSTART}" -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks/)" ]; then
        log "Creating Backup ..."
        arkmanager backup --cluster
    fi
fi

log "###########################################################################"
log "Installing Mods ..."
if ! arkmanager checkmodupdate --revstatus; then
    touch /ark/server/.installing-mods
    arkmanager installmods --dots
    rm -f /ark/server/.installing-mods
fi

log "###########################################################################"
log "Launching ark server ..."
if [ "${UPDATEONSTART}" -eq 1 ]; then
    arkmanager start
else
    arkmanager start --noautoupdate
fi

# Stop server in case of signal INT or TERM
log "###########################################################################"
log "Running ... (waiting for INT/TERM signal)"
trap stop INT
trap stop TERM

read -r < /tmp/FIFO &
wait
