FROM debian

MAINTAINER Ilya Kogan <ikogan@flarecode.com>

RUN apt-get install --yes gnupg \
    && wget -O "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc" https://packages.openmediavault.org/public/archive.key \
    && apt-key add "/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.asc"
# Fix resolvconf issues with Docker
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

RUN cat <<EOF >> /etc/apt/sources.list.d/openmediavault.list \
    && deb https://packages.openmediavault.org/public shaitan main \
    && # deb https://downloads.sourceforge.net/project/openmediavault/packages shaitan main \
    && ## Uncomment the following line to add software from the proposed repository. \
    && # deb https://packages.openmediavault.org/public shaitan-proposed main \
    && # deb https://downloads.sourceforge.net/project/openmediavault/packages shaitan-proposed main \
    && ## This software is not part of OpenMediaVault, but is offered by third-party \
    && ## developers as a service to OpenMediaVault users. \
    && # deb https://packages.openmediavault.org/public shaitan partner \
    && # deb https://downloads.sourceforge.net/project/openmediavault/packages shaitan partner \
    && EOF

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

VOLUME /etc/openmediavault

ENTRYPOINT /usr/sbin/omv-startup
