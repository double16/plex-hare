# plex-hare

[![GitHub Issues](https://img.shields.io/github/issues-raw/double16/plex-hare.svg)](https://github.com/double16/plex-hare/issues)
[![Build](https://github.com/double16/plex-hare/workflows/Build/badge.svg)](https://github.com/double16/plex-hare/actions?query=workflow%3ABuild)
[![](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/patDj)

Modify the standard Plex docker images to use [media-hare](https://github.com/double16/plex-hare) tools.

## DVR post-processing

Configure your Plex DVR post processing script to `/config/Library/Application Support/Plex Media Server/Scripts/dvr-post-process-wrapper.sh`. The script is designed to be nice to machines with low resources. No video or audio transcoding is done, unless post_process.profanity_filter is 'true', and in that case audio transcoding may be
necessary. The post-processing script does change the container to mkv (which reduces storage), one audio stream is kept that matches the configured language and has the highest bit-rate. If no audio stream with the configured language is found, the highest bit-rate stream is used.

If the container isn't available the DVR file will be added as if there were no post-processing script. We don't want to lose content if something goes wrong with the media-hare container.

If your machine don't perform well with this script, you can leave the post-processing script empty and the media-hare container will
transcode on a schedule.

## Commercial Processing

The built-in Plex commercial skipper is replaced by media-hare tools. Both use a version of comskip. As of this
writing the media-hare version is newer. media-hare doesn't call comskip directly, but uses a python program to
enhance comskip such as allowing show specific settings. See [media-hare](https://github.com/double16/media-hare) for
details.

Plex background commercial scanning does not mark a file as processed. It seems to depend on commercials being found
to skip. So if a file has no commercials, a short one at the beginning is added to prevent re-processing.

If the container isn't available or the arguments can't be parsed as expected, the original Plex Commercial Skipper
program is called. So there is a safe fall back.

## Priorities

Not related to media-hare but very useful is that some Plex processes priorities are adjusted to improve results on
resource limited machines. See plex-process-priority.sh comments for details. Most importantly, TV recording processes
are set to real-time priority to reduce missed/late recordings when the server is under load.

## Usage

docker-compose.yml looks like:

It is necessary that both the `media-hare` and `plex-hare` containers mount media into the same path. In the following
example, `/media`.

```yaml
volumes:
  plexoptimize:
  plexconfig:
  plexpreview:
  plextranscode:

services:

  media-hare:
    image: ghcr.io/double16/media-hare:main
    restart: unless-stopped
    volumes:
      - plextranscode:/transcode
      - plexoptimize:/optimize
      - plexpreview:/preview
      - /path/to/media:/media
    devices:
      - /dev/dri:/dev/dri

  plex:
    image: ghcr.io/double16/plex-hare:public
    restart: unless-stopped
    cap_add:
      - SYS_NICE
      # for ioprio_class_rt
      - SYS_ADMIN
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
      # nvidia-container-runtime will mount all necessary libs, caps "video" is necessary for encoder lib
      - HWACCEL_DRIVERS_INSTALL=false
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
    volumes:
      - plextranscode:/transcode
      - plexconfig:/config
      - plexoptimize:/optimize
      - plexpreview:/preview
      - /path/to/media:/media
      - /var/run/docker.sock:/var/run/docker.sock
    devices:
      - /dev/dri:/dev/dri
      - /dev/dvb:/dev/dvb
```
