# syntax=docker/dockerfile:1
FROM debian:13-slim

LABEL org.opencontainers.image.authors="Acid Density <acid.density@gmail.com>" \
      org.opencontainers.image.title="ARK Cluster Image" \
      org.opencontainers.image.description="ARK Cluster Image" \
      org.opencontainers.image.url="https://github.com/aciddensity/arkcluster" \
      org.opencontainers.image.source="https://github.com/aciddensity/arkcluster"

RUN <<EOT bash # Install dependencies and clean up
    set -eux
    test "$(dpkg --print-architecture)" = amd64
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        adduser \
        bash \
        bzip2 \
        ca-certificates \
        coreutils \
        cron \
        curl \
        findutils \
        lib32gcc-s1 \
        libc6-i386 \
        libcompress-raw-zlib-perl \
        lsof \
        perl \
        procps \
        rsync \
        sed \
        systemd-standalone-sysusers \
        sysvinit-utils \
        tar \
        tini \
        tzdata \
        util-linux
    apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

# Update each checksum together with its corresponding archive/version.
ARG ARKMANAGER_VERSION=1.6.69
ARG ARKMANAGER_SHA256=29c541f040b6fa1beb1aefcd5b2e58701f01680a2cf8ae87783f18bcf45a0e55
ARG STEAMCMD_SHA256=cebf0046bfd08cf45da6bc094ae47aa39ebf4155e5ede41373b579b8f1071e7c

ENV USER_ID=1000 \
    GROUP_ID=1000

RUN <<EOT bash # Add steam user
    set -eux
    addgroup --gid "$GROUP_ID" steam
    adduser --disabled-password --gecos "" --uid "$USER_ID" --gid "$GROUP_ID" --home /home/steam --shell /bin/bash steam
EOT

RUN <<EOT bash # Install ark-server-tools
    set -eux
    curl -fsSL --retry 3 -o ark-server-tools.tar.gz "https://github.com/arkmanager/ark-server-tools/archive/refs/tags/v${ARKMANAGER_VERSION}.tar.gz"
    echo "${ARKMANAGER_SHA256}  ark-server-tools.tar.gz" | sha256sum --check --strict -
    tar xzf ark-server-tools.tar.gz
    pushd "./ark-server-tools-${ARKMANAGER_VERSION}/tools"
    ./install.sh steam --prefix=/usr
    popd
    rm -r ark-server-tools.tar.gz "ark-server-tools-${ARKMANAGER_VERSION}"
EOT

RUN <<EOT bash # Create required directories
    mkdir -p /ark/{log,backup,staging,default,steam,.steam}
    mkdir -p /cluster
EOT

# Setup arkcluster
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh
COPY arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager-user.cfg /home/steam/arkmanager-user.cfg

# Healthcheck
COPY healthcheck.sh /bin/healthcheck
RUN chmod +x /bin/healthcheck
HEALTHCHECK --interval=10s --timeout=10s --start-period=10s --retries=3 CMD ["/bin/healthcheck"]

# Fix permissions
RUN chown steam:steam -R /ark /cluster /home/steam

USER steam
RUN <<EOT bash # Install steamcmd
    set -eux
    ln -s /ark/steam /home/steam/Steam
    ln -s /ark/.steam /home/steam/.steam
    mkdir -p ~/steamcmd && cd ~/steamcmd
    curl -fsSL --retry 3 -o steamcmd_linux.tar.gz "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
    echo "${STEAMCMD_SHA256}  steamcmd_linux.tar.gz" | sha256sum --check --strict -
    tar xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
    ./steamcmd.sh +quit
EOT

# Expose environment variables
ENV CRON_AUTO_UPDATE="0 */3 * * *" \
    CRON_AUTO_BACKUP="0 */1 * * *" \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    TZ=UTC \
    MAX_BACKUP_SIZE=500 \
    SERVERMAP="TheIsland" \
    SESSION_NAME="ARK Docker" \
    MAX_PLAYERS=15 \
    RCON_ENABLE="True" \
    QUERY_PORT=15000 \
    GAME_PORT=15002 \
    RCON_PORT=15003 \
    SERVER_PVE="False" \
    MODS="" \
    CLUSTER_ID="keepmesecret" \
    GAME_USERSETTINGS_INI_PATH="" \
    GAME_INI_PATH="" \
    KILL_PROCESS_TIMEOUT=300 \
    KILL_ALL_PROCESSES_TIMEOUT=300

USER root
VOLUME /ark /cluster
WORKDIR /ark
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/run.sh"]
