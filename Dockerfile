ARG CHANNEL=latest
FROM plexinc/pms-docker:${CHANNEL}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&\
    apt-get install -y software-properties-common apt-transport-https ca-certificates curl gnupg-agent &&\
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - &&\
    add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&\
    apt-get update &&\
    apt-get install -y docker-ce-cli parallel nano &&\
    apt-get clean
ADD --chown=plex:plex dvr-post-process-wrapper.sh dvr-post-process-sleep.sh plex-process-priority.sh comskip-wrapper.sh /opt/Scripts/
ADD 10-network-check 60-config-script 65-hwaccel-drivers /etc/cont-init.d/
ADD 99force-overwrite /etc/apt/apt.conf.d/
RUN chmod +x /etc/cont-init.d/10-network-check /etc/cont-init.d/60-config-script /etc/cont-init.d/65-hwaccel-drivers /opt/Scripts/*
