FROM debian:11.7

MAINTAINER Fazle Khan <fazleskhan@gmail.com>

# Add the OpenMediaVault repository
COPY openmediavault.list /etc/apt/sources.list.d/

RUN apt-get update \ 
    && apt-get install --yes gnupg \
    && apt-get install --yes wget \
    && wget -O "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc" https://packages.openmediavault.org/public/archive.key \
    && apt-key add "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc"
# Fix resolvconf issues with Docker
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

RUN export LANG=C.UTF-8 \
    && export DEBIAN_FRONTEND=noninteractive \
    && export APT_LISTCHANGES_FRONTEND=none \
    && apt-get update \
    && apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault-keyring openmediavault \
    && omv-confdbadm populate

# We need to make sure rrdcached uses /data for it's data
COPY defaults/rrdcached /etc/default

# Add our startup script last because we don't want changes
# to it to require a full container rebuild
COPY omv-startup /usr/sbin/omv-startup
RUN chmod +x /usr/sbin/omv-startup

EXPOSE 80 443 445 21 

VOLUME /data

ENTRYPOINT /usr/sbin/omv-startup
