#!/usr/bin/env bash

#
# Use comskip in the media container to get better tuning. Calls look like:
#	  "/usr/lib/plexmediaserver/Plex Commercial Skipper"
#	  --ini=/usr/lib/plexmediaserver/Resources/comskip.ini
#	  "--output=/home/Dropbox/Media/DVRShows/Stargate SG-1 (1997)/Season 06"
#	  -t
#	  --quiet
#	  "/home/Dropbox/Media/DVRShows/Stargate SG-1 (1997)/Season 06/Stargate SG-1 (1997) - S06E08 - The Other Guys.mkv"
#

ORIGINAL_COMSKIP="/usr/lib/plexmediaserver/Plex Commercial Skipper.orig"

if command -v docker >/dev/null 2>/dev/null && [[ -e /var/run/docker.sock ]]; then
  MEDIA_CON="$(docker ps --format "{{.Names}}" | grep media-hare | head -n 1)"
else
  exec "${ORIGINAL_COMSKIP}" "$@"
fi

# Find the file in the arguments
for I in "$@"; do
  if [[ -f "${I}" ]]; then
    FILE="${I}"
  fi
done

if [[ -z "${FILE}" ]]; then
  exec "${ORIGINAL_COMSKIP}" "$@"
fi

docker exec "${MEDIA_CON}" "/usr/local/bin/comchap.py" --keep-edl --backup-edl "${FILE}" >/dev/null 2>/dev/null

# If no commercials found, add one second at the beginning so Plex will mark this file as processed.
EDLFILE="${FILE%.*}.edl"
if ! grep -q '^[0-9]' "${EDLFILE}" 2>/dev/null; then
  echo "0    1.00    0" > "${EDLFILE}"
fi
