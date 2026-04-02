#!/bin/bash -e

dhclient -4 -i $WAN_INTERFACE.100 -cf /etc/dhcp/dhclient-bbox-v4.conf -df /var/lib/dhcp/dhclient-bbox.duid -lf /var/lib/dhcp/dhclient-bbox-v4.lease -v
sleep 2
dhclient -6 -P -D LL -i $WAN_INTERFACE.100 -cf /etc/dhcp/dhclient-bbox-v6.conf -df /var/lib/dhcp/dhclient-bbox.duid -lf /var/lib/dhcp/dhclient-bbox-v6.lease -v -e WAN_INTERFACE=$WAN_INTERFACE -e LAN_INTERFACE=$LAN_INTERFACE
