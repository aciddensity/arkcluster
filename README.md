# ARK: Survival Evolved - Docker Cluster

Docker build for managing an **ARK: Survival Evolved** server cluster.

The code repository is [aciddensity/arkcluster](https://github.com/aciddensity/arkcluster). The Docker image is [aciddensity/arkcluster](https://hub.docker.com/r/aciddensity/arkcluster).

This image uses [Ark Server Tools](https://github.com/arkmanager/ark-server-tools) to manage an ark server and is a fork of / inspired by [r15ch13/arkcluster](https://github.com/r15ch13/arkcluster) which is forked from [boerngen-schmidt/Ark-docker](https://hub.docker.com/r/boerngenschmidt/ark-docker/).

Existing `/ark/arkmanager.cfg` files remain in place. Compare your configuration with `/ark/default/arkmanager.cfg` after an image update.

Use `docker pull aciddensity/arkcluster:latest` to download the most recent release image.
Alternatively you can pull from GHCR `docker pull ghcr.io/aciddensity/arkcluster:latest`.

## Features

- Easy install (no steamcmd / lib32... to install)
- Easy access to ark config file
- Mods handling (via Ark Server Tools)
- Arkmanager-managed shutdown and optional backups
- Arkmanager version fixed at image build time

The Debian 13 migration audit is in [MIGRATION-AUDIT.md](MIGRATION-AUDIT.md). It records the migration decisions, known limitations, and validation results.

## Usage

The Compose example uses published release images. Create the three password files in [Secrets](#secrets) before you start the services.

```yaml
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

The Compose example mounts three password files as secrets. Both example services use the same files and passwords. Create these files next to `docker-compose.yml` before you start Compose:

1. Create the `secrets/` directory with access limited to your account.
2. Create `secrets/server_password.txt`, `secrets/admin_password.txt`, and `secrets/spectator_password.txt`. Put one password in each file. Do not add quotes.
3. Limit access to the password files. For example, run `chmod 600 secrets/*.txt` on Linux.

The `secrets/` directory is ignored by Git. Compose mounts each file at `/run/secrets/<secret_name>` in the container. The matching `*_PASSWORD_FILE` setting tells `run.sh` which mounted file to read. The startup script removes trailing newline characters from the password.

To leave a password empty, remove its `*_PASSWORD_FILE` setting and its entry in `secrets:` from **each service**. Also remove its definition from the top-level `secrets:` section. If you remove all password secrets, remove both service-level `secrets:` sections and the top-level `secrets:` section.

The image supports `SERVER_PASSWORD_FILE`, `ADMIN_PASSWORD_FILE`, and `SPECTATOR_PASSWORD_FILE`. You can instead set `SERVER_PASSWORD`, `ADMIN_PASSWORD`, or `SPECTATOR_PASSWORD` directly. Do not set a password variable and its matching `_FILE` variable at the same time. The container exits if it cannot read a configured file or if both forms have nonempty values.

## Volumes

- **/ark** : Working directory :
  - `/ark/server` : Server files and data.
  - `/ark/log` : logs
  - `/ark/backup` : backups
  - `/ark/arkmanager.cfg` : config file for Ark Server Tools
  - `/ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini` : ark Game.ini config file
  - `/ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini` : ark GameUserSettings.ini config file
  - `/ark/default` : Default config files
  - `/ark/default/arkmanager.cfg` : default config file for Ark Server Tools
  - `/ark/staging` : default directory if you use the --downloadonly option when updating.
- **/cluster** : Cluster volume to share with other instances
  - `/cluster/myclusterid.Game.ini` : ark Game.ini config file which will be copied on every start
  - `/cluster/myclusterid.GameUserSettings.ini` : ark GameUserSettings.ini config file which will be copied on every start

## Releases

Image releases use CalVer tags in `YY.0M.MICRO` format, without a `v` prefix:

- `YY`: two-digit release year.
- `0M`: two-digit month, from `01` through `12`.
- `MICRO`: release number within that month, starting at `0`. Increment it for each release. Do not add leading zeros.

For example, September 2026 releases use `26.09.0`, `26.09.1`, and so on. October starts with `26.10.0`.

To publish a release:

1. Create a Git tag with the CalVer version on the commit to release.
2. Publish a GitHub release for that tag. Leave the prerelease option disabled.
3. Check that the image publication workflow succeeds for Docker Hub and GHCR.

CI builds images only when a GitHub release is published. Branch pushes, tag pushes alone, pull requests, and nightly schedules do not trigger builds. Drafts and prereleases do not publish images.

Each image receives the exact release tag, such as `aciddensity/arkcluster:26.09.0`. The workflow then updates `:latest` for the most recently published eligible release, ordered by publication time. An older release rerun cannot promote its image over a newer release. If publication fails, inspect the workflow and rerun it after correction. Updates to the two registries are separate operations.

Use a version tag in Compose to select a specific release. Use `:latest` to select the most recent published release image. A new release does not update running containers automatically.

For a local build, run `make build` from this repository. This command tags the local image as `aciddensity/arkcluster:latest`. Compose has no `build` section and does not build the image itself.

## Operator responsibilities

Before deployment, prepare imported saves and configuration files with ownership and permissions compatible with `USER_ID` and `GROUP_ID`. Both example services use `1000:1000`. All servers that write to the shared cluster directory need compatible access. Ownership migration during import is outside the project scope.

After each start, inspect the logs and verify server readiness, RCON where enabled, and game connections. Check scheduled backup and update logs. A running container or successful healthcheck does not establish that these operations work.

If cron fails to start, the container exits with an error. If cron later stops, the healthcheck reports unhealthy, including during installation. Recovery is manual. The healthcheck does not verify individual cron jobs or detect a hung cron process.

## Known limitations

- **Shutdown:** The project relies on Arkmanager. Custom timeout policy and startup-command cancellation remain outside scope. Signal handlers are installed after server startup. Docker can interrupt warning, save, or backup operations when its stop deadline expires. The Compose example does not set a grace period. See [Docker's stop grace-period documentation](https://docs.docker.com/reference/compose-file/services/#stop_grace_period).
- **Removed settings:** `KILL_PROCESS_TIMEOUT` and `KILL_ALL_PROCESSES_TIMEOUT` controlled the previous Phusion init system. They have no effect with Tini and are no longer exposed. Setting a value does not enable a timeout policy.
- **Startup failures:** Installation, mod installation, or server startup can fail while the container remains running. Operators must detect a stalled deployment and take corrective action. Automatic recovery remains outside scope.
- **Imported data:** Startup does not normalize all existing ownership. Files with unrelated numeric IDs can remain inaccessible until the operator corrects them before deployment.
- **Readiness:** With cron present, installation markers or a server PID can produce a successful healthcheck. Port checks are diagnostic only. Operators must verify readiness and connectivity.
- **Reproducibility:** Archive checksums are verified, but the Debian tag, APT packages, and SteamCMD updates can change between builds.
- **Cluster transfers:** Transfers between server instances remain unverified.

The operator reports that all other container acceptance checks passed. These manual results are recorded in [MIGRATION-AUDIT.md](MIGRATION-AUDIT.md). They do not remove the known limitations or verify the release publication workflow.
