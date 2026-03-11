FROM debian:13

# Installation des dépendances système
RUN apt-get update && apt-get install -y supervisor iproute2 iptables nftables gettext-base build-essential git

# Compilation du dhclient patché (indispensable pour le marquage CoS sur Linux moderne)
RUN git clone https://github.com/Raraph84/dhclient-orange-patched /tmp/dhclient-orange-patched \
    && cd /tmp/dhclient-orange-patched && ./configure && make && make install \
    && cp /tmp/dhclient-orange-patched/client/scripts/linux /sbin/dhclient-script \
    && chmod +x /sbin/dhclient-script \
    && rm -rf /tmp/dhclient-orange-patched

# Nettoyage pour réduire la taille de l'image
RUN apt-get remove -y build-essential git && apt-get autoremove -y && apt-get clean

# Copie des scripts de configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY init.sh /usr/local/bin/init.sh
COPY up-fiber.sh /usr/local/bin/up-fiber.sh
COPY no-dns-dhcp-enter-hook.sh /etc/dhclient-enter-hooks.d/no-dns

RUN chmod +x /usr/local/bin/init.sh /usr/local/bin/up-fiber.sh /etc/dhclient-enter-hooks.d/no-dns

# Variables par défaut (à overrider via docker run ou docker-compose)
ENV LAN_INTERFACE=eth0
ENV WAN_INTERFACE=eth1
ENV BBOX_MAC=00:00:00:00:00:00
ENV LAN_SUBNET=192.168.1.0/24

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
