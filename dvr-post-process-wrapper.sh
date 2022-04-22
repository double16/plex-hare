#!/usr/bin/env bash

#
# Wrap dvr_post_process.py to keep a log of failures.
#
# Current GPU encoding corrupts files. We are optimizing to limit IOPS load by only performing low resource operations:
#     docker exec -e PRESET=copy
#     sem -j 1, was -j +0
#

finish() {
  [ -f "${LOG}" ] && rm -f "${LOG}"
  [ -f "${TARGET}" ] && rm -f "${TARGET}"
}
trap finish EXIT

LOG="$(mktemp)"
TARGET="$(mktemp)"
if command -v docker >/dev/null 2>/dev/null && [[ -e /var/run/docker.sock ]]; then
  MEDIA_CON="$(docker ps --format "{{.Names}}" | grep media-hare | head -n 1)"
else
  echo "Could not find media-hare container" >&2
  # We don't need to fail because Plex will use the original file
  exit 0
fi

cat >"${TARGET}" <<EOF
#!/usr/bin/env bash
exec docker exec -e PRESET=copy "${MEDIA_CON}" "/usr/local/bin/dvr_post_process.py" "$@" >"${LOG}" 2>&1
EOF
chmod +x "${TARGET}"

# sleep a random amount to prevent IOPS overload when transitioning time slots
sleep $((35 + RANDOM % 20))

# `sem` allows us to limit the concurrency. We've seen reboots of the machine under load. `sem` is in the GNU `parallel` package.
SEM="$(command -v sem)"
${SEM:+"${SEM}" --will-cite -j 1 --id dvr-post-process --fg --semaphoretimeout -1800} "${TARGET}"

if [[ $? -ne 0 ]]; then
    cat "${LOG}" >> /var/log/dvr/dvr-post-process.log
fi

# We don't need to fail because Plex will use the original file
exit 0
