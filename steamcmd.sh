#!/usr/bin/env bash

# Set Steam root explicitly
STEAMROOT="/home/vadrigar/.steam"
mkdir -p "$STEAMROOT/Steam"
export STEAM_LOGDIR="$STEAMROOT/Steam/logs"
mkdir -p "$STEAM_LOGDIR"

STEAMCMD=$(basename "$0" .sh)

UNAME=$(uname)
if [ "$UNAME" == "Linux" ]; then
    PLATFORM="linux32"
    STEAMEXE="$STEAMROOT/$PLATFORM/$STEAMCMD"
    export LD_LIBRARY_PATH="$STEAMROOT/$PLATFORM:${LD_LIBRARY_PATH-}"
else
    STEAMEXE="$STEAMROOT/$STEAMCMD"
    if [ ! -x "$STEAMEXE" ]; then
        STEAMEXE="$STEAMROOT/Steam.AppBundle/Steam/Contents/MacOS/$STEAMCMD"
    fi
    export DYLD_LIBRARY_PATH="$STEAMROOT:${DYLD_LIBRARY_PATH-}"
    export DYLD_FRAMEWORK_PATH="$STEAMROOT:${DYLD_FRAMEWORK_PATH-}"
fi

ulimit -n 2048
MAGIC_RESTART_EXITCODE=42

# Optional debugger support
if [ "$DEBUGGER" == "gdb" ] || [ "$DEBUGGER" == "cgdb" ]; then
    ARGSFILE=$(mktemp "$USER.steam.gdb.XXXX")

    if [ "$LD_PRELOAD" ]; then
        echo set env LD_PRELOAD=$LD_PRELOAD >> "$ARGSFILE"
        echo show env LD_PRELOAD >> "$ARGSFILE"
        unset LD_PRELOAD
    fi

    $DEBUGGER -x "$ARGSFILE" "$STEAMEXE" "$@"
    rm "$ARGSFILE"
else
    $DEBUGGER "$STEAMEXE" "$@"
fi

STATUS=$?
if [ $STATUS -eq $MAGIC_RESTART_EXITCODE ]; then
    exec "$0" "$@"
fi

exit $STATUS

