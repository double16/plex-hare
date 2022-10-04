#!/usr/bin/env bash

#
# Maintains CPU and IO priority for specific Plex processes. This script must be run as root and cannot be converted to a wrapper
# because some operations, such as increasing priority, are not allowed as a user process.
#

TUNER="Plex Tuner Service"
TRANSCODER="Plex Transcoder"
SKIPPER="Plex Commercial Skipper"

INTERVAL="${INTERVAL:-2}"

while true; do

    # Plex Tuner Service reads real time streams from the TV tuner
    pgrep -f "${TUNER}" | xargs -r renice -n -5 -p

    # Reads from tuner and produces mpegts
    pgrep -f "${TRANSCODER}.*devices/dvb" | xargs -r renice -n -4 -p

    # Reads from mpegts and streams to disk
    pgrep -f "${TRANSCODER}.*livetv/session" | while read PID; do
        renice -n -4 -p ${PID}
        ionice -c 1 -n 5 -p ${PID}
    done

    # On-demand transcode
    pgrep -f "${TRANSCODER}.*segment_list" | xargs -r renice -n -2 -p

    # Plex Commercial Skipper use the lowest best-effort
    pgrep -f "${SKIPPER}" | xargs -r ionice -c 2 -n 7 -p

    sleep ${INTERVAL}
done
