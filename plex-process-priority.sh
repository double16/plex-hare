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

    AFFECTED_PIDS=()

    # Plex Tuner Service reads real time streams from the TV tuner
    pgrep -f "${TUNER}" | xargs -r renice -n -5 -p

    # Reads from tuner and produces mpegts
    for PID in $(pgrep -f "${TRANSCODER}.*/devices/"); do
      renice -n -4 -p "${PID}"
      AFFECTED_PIDS+=("${PID}")
    done

    # Reads from mpegts and streams to disk
    for PID in $(pgrep -f "${TRANSCODER}.*livetv/session"); do
        renice -n -4 -p "${PID}"
        ionice -c 1 -n 5 -p "${PID}"
        AFFECTED_PIDS+=("${PID}")
    done

    # On-demand transcode
    # captures tv recording too, so 'segment' isn't good enough
    pgrep -f "${TRANSCODER}.*segment" | while read PID; do
        # exclude if in pid array
        EXCLUDE=0
        for APID in "${AFFECTED_PIDS[@]}"
        do
          if [[ "${APID}" == "${PID}" ]]; then
            echo "Skipping affected pid ${APID}"
            EXCLUDE=1
          fi
        done
        [[ "${EXCLUDE}" == "0" ]] && renice -n -2 -p "${PID}"
    done

    # Plex Commercial Skipper use the lowest best-effort
    pgrep -f "${SKIPPER}" | xargs -r ionice -c 2 -n 7 -p

    sleep "${INTERVAL}"
done
