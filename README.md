# plex-hare
Modify the standard Plex docker images to use [media-hare](https://github.com/double16/plex-hare) tools.

## DVR post processing

Configure your Plex DVR post processing script to `/config/Library/Application Support/Plex Media Server/Scripts/dvr-post-process-wrapper.sh`.

If the container isn't available the DVR file will be added as-is.

## Commercial Processing

The built-in Plex commercial skipper is replaced by media-hare tools. Both use a version of comskip. As of this
writing the media-hare version is newer. media-hare doesn't call comskip directly, but uses a python program to
enhance comskip such as allowing show specific settings. See [media-hare](https://github.com/double16/plex-hare) for
details.

Plex background commercial scanning does not mark a file as processed. It seems to depend on commercials being found
to skip. So if a file has no commercials, a short one at the beginning is added to prevent re-processing.

If the container isn't available or the arguments can't be parsed as expected, the original Plex Commercial Skipper
program is called. So there is a safe fall back.

## Priorities

Not related to media-hare but very useful is that some Plex processes priorities are adjusted to improve results on
resource limited servers. See plex-process-priority.sh comments for details. Most importantly TV recording processes
are set to real-time to reduce missed/late recordings when the server is under load.

## Usage

docker-compose.yml looks like:

```yaml
version: "3.4"

volumes:
  plexoptimize:
  plexconfig:
  plexpreview:
  plextranscode:

services:

  media-hare:
    image: ghcr.io/double16/media-hare:latest
    restart: unless-stopped
    volumes:
      - plextranscode:/transcode
      - plexoptimize:/optimize
      - plexpreview:/preview
      - /path/to/media:/home/Dropbox
    devices:
      - /dev/dri:/dev/dri

  plex:
    build: plex
    restart: unless-stopped
    cap_add:
      - sys_nice
      # for ioprio_class_rt
      - sys_admin
    ports:
      - "32400:32400/tcp"
      - "3005:3005/tcp"
      - "8324:8324/tcp"
      - "32469:32469/tcp"
      - "1900:1900/udp"
      - "32410:32410/udp"
      - "32412:32412/udp"
      - "32413:32413/udp"
      - "32414:32414/udp"
    environment:
      - PLEX_UID=99
      - PLEX_GID=100
      - TZ=America/Chicago
      # Changing permissions is necessary to make the transcode volume correct
      - CHANGE_CONFIG_DIR_OWNERSHIP=true
    volumes:
      - plextranscode:/transcode
      - plexconfig:/config
      - plexoptimize:/optimize
      - plexpreview:/preview
      - /path/to/media:/home/Dropbox
      - /var/run/docker.sock:/var/run/docker.sock
    devices:
      - /dev/dri:/dev/dri
      - /dev/dvb:/dev/dvb
```
