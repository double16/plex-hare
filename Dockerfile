ARG CHANNEL
FROM plexinc/pms-docker:${CHANNEL}

RUN apt-get update &&\
    apt-get install -y software-properties-common apt-transport-https ca-certificates curl gnupg-agent &&\
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - &&\
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&\
    apt-get update &&\
    apt-get install -y docker-ce-cli parallel nano &&\
    apt-get clean
ADD --chown=plex:plex dvr-post-process-wrapper.sh dvr-post-process-sleep.sh plex-process-priority.sh comskip-wrapper.sh /opt/Scripts/
ADD 10-network-check 60-config-script /etc/cont-init.d/
RUN chmod +x /etc/cont-init.d/10-network-check /etc/cont-init.d/60-config-script /opt/Scripts/*
