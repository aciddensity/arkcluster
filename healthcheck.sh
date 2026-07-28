#!/usr/bin/env bash

source /etc/arkmanager/arkmanager.cfg

SERVER_PID=$(pidof ShooterGameServer)

[[ -n "$SERVER_PID" ]] && echo -n "Running: Yes" || echo -n "Running: No"
if [ -e /ark/server/.installing-ark ]; then
    echo " | Status: Installing ARK"
    exit 0
fi
if [ -e /ark/server/.installing-mods ]; then
    echo " | Status: Installing Mods"
    exit 0
fi
[[ -n "$SERVER_PID" ]] && echo -n " | PID: ${SERVER_PID}"

[[ -n "$SERVER_PID" && $(runuser -l steam -c "lsof -wti udp:$QUERY_PORT") -eq "$SERVER_PID" ]] && echo -n " | Query Port: Open" || echo -n " | Query Port: Closed"
[[ -n "$SERVER_PID" && $(runuser -l steam -c "lsof -wti udp:$GAME_PORT") -eq "$SERVER_PID" ]] && echo -n " | Game Port: Open" || echo -n " | Game Port: Closed"
[[ -n "$SERVER_PID" && $(runuser -l steam -c "lsof -wti tcp:$RCON_PORT") -eq "$SERVER_PID" ]] && echo " | RCON Port: Open" || echo " | RCON Port: Closed"

if [ -e /ark/server/.stopping-server ]; then
    echo " | Status: Stopping"
    exit 0
fi

[[ -n "$SERVER_PID" ]] && exit 0 || exit 1
