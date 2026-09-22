# ARK: Survival Evolved - Docker Cluster

Docker build for managing an **ARK: Survival Evolved** server cluster.

The code repository is [aciddensity/arkcluster](https://github.com/aciddensity/arkcluster). The Docker image is [aciddensity/arkcluster](https://hub.docker.com/r/aciddensity/arkcluster).

This image uses [Ark Server Tools](https://github.com/arkmanager/ark-server-tools) to manage an ark server and is a fork of / inspired by [r15ch13/arkcluster](https://github.com/r15ch13/arkcluster) which is forked from [boerngen-schmidt/Ark-docker](https://hub.docker.com/r/boerngenschmidt/ark-docker/).

_If you use an old volume, get the new arkmanager.cfg in the default directory._

**Don't forget to use `docker pull aciddensity/arkcluster:latest` to get the latest version of the image**

## Features

- Easy install (no steamcmd / lib32... to install)
- Easy access to ark config file
- Mods handling (via Ark Server Tools)
- `docker stop` is a clean stop
- Arkmanager version fixed at image build time

The Debian 13 migration audit is in [MIGRATION-AUDIT.md](MIGRATION-AUDIT.md). It records the compatibility gaps and required container tests.

## Usage

Fast & Easy cluster setup via docker compose:

```yaml
version: "3"

services:
  island:
    image: aciddensity/arkcluster:latest
    deploy:
      mode: global
    environment:
      CRON_AUTO_UPDATE: "0 */3 * * *"
      CRON_AUTO_BACKUP: "0 */1 * * *"
      UPDATEONSTART: 1
      BACKUPONSTART: 1
      BACKUPONSTOP: 1
      WARNONSTOP: 1
      USER_ID: 1000
      GROUP_ID: 1000
      TZ: "UTC"
      MAX_BACKUP_SIZE: 500
      SERVERMAP: "TheIsland"
      SESSION_NAME: "ARK Cluster TheIsland"
      MAX_PLAYERS: 15
      RCON_ENABLE: "True"
      QUERY_PORT: 15000
      GAME_PORT: 15002
      RCON_PORT: 15003
      SERVER_PVE: "False"
      SERVER_PASSWORD_FILE: "/run/secrets/server_password"
      ADMIN_PASSWORD_FILE: "/run/secrets/admin_password"
      SPECTATOR_PASSWORD_FILE: "/run/secrets/spectator_password"
      MODS: "731604991"
      CLUSTER_ID: "myclusterid"
      GAME_USERSETTINGS_INI_PATH: "/cluster/myclusterid.GameUserSettings.ini"
      GAME_INI_PATH: "/cluster/myclusterid.Game.ini"
      KILL_PROCESS_TIMEOUT: 300
      KILL_ALL_PROCESSES_TIMEOUT: 300
    volumes:
      - data_island:/ark
      - cluster:/cluster
    secrets:
      - server_password
      - admin_password
      - spectator_password
    ports:
      - "15000-15003:15000-15003/udp"
      - "15003:15003/tcp"

  valguero:
    image: aciddensity/arkcluster:latest
    deploy:
      mode: global
    environment:
      CRON_AUTO_UPDATE: "15 */3 * * *"
      CRON_AUTO_BACKUP: "15 */1 * * *"
      UPDATEONSTART: 1
      BACKUPONSTART: 1
      BACKUPONSTOP: 1
      WARNONSTOP: 1
      USER_ID: 1000
      GROUP_ID: 1000
      TZ: "UTC"
      MAX_BACKUP_SIZE: 500
      SERVERMAP: "Valguero_P"
      SESSION_NAME: "ARK Cluster Valguero"
      MAX_PLAYERS: 15
      RCON_ENABLE: "False"
      QUERY_PORT: 15010
      GAME_PORT: 15012
      RCON_PORT: 15013
      SERVER_PVE: "False"
      SERVER_PASSWORD_FILE: "/run/secrets/server_password"
      ADMIN_PASSWORD_FILE: "/run/secrets/admin_password"
      SPECTATOR_PASSWORD_FILE: "/run/secrets/spectator_password"
      MODS: "731604991"
      CLUSTER_ID: "myclusterid"
      GAME_USERSETTINGS_INI_PATH: "/cluster/myclusterid.GameUserSettings.ini"
      GAME_INI_PATH: "/cluster/myclusterid.Game.ini"
      KILL_PROCESS_TIMEOUT: 300
      KILL_ALL_PROCESSES_TIMEOUT: 300
    volumes:
      - data_valguero:/ark
      - cluster:/cluster
    secrets:
      - server_password
      - admin_password
      - spectator_password
    ports:
      - "15010-15013:15010-15013/udp"
      - "15013:15013/tcp"

volumes:
  data_island:
  data_valguero:
  cluster:

secrets:
  server_password:
    file: ./secrets/server_password.txt
  admin_password:
    file: ./secrets/admin_password.txt
  spectator_password:
    file: ./secrets/spectator_password.txt
```

### Secrets

The Compose example reads passwords from `secrets/server_password.txt`, `secrets/admin_password.txt`, and `secrets/spectator_password.txt`. The `secrets/` directory is ignored by Git. Remove an optional password's environment and secret entries to leave it empty.

`SERVER_PASSWORD_FILE`, `ADMIN_PASSWORD_FILE`, and `SPECTATOR_PASSWORD_FILE` are supported. Direct password variables remain available for compatibility, but do not set both forms for the same password.

## Volumes

- **/ark** : Working directory :
  - `/ark/server` : Server files and data.
  - `/ark/log` : logs
  - `/ark/backup` : backups
  - `/ark/arkmanager.cfg` : config file for Ark Server Tools
  - `/ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini` : ark Game.ini config file
  - `/ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSetting.ini` : ark GameUserSetting.ini config file
  - `/ark/default` : Default config files
  - `/ark/default/arkmanager.cfg` : default config file for Ark Server Tools
  - `/ark/staging` : default directory if you use the --downloadonly option when updating.
- **/cluster** : Cluster volume to share with other instances
  - `/cluster/myclusterid.Game.ini` : ark Game.ini config file which will be copied on every start
  - `/cluster/myclusterid.GameUserSetting.ini` : ark GameUserSetting.ini config file which will be copied on every start

## Known issues

Currently none
