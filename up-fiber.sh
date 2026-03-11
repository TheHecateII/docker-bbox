#!/bin/bash -e

# Generate simple DHCP config for Bouygues
cat <<EOF > /etc/dhcp/dhclient-bouygues.conf
interface "$WAN_INTERFACE.100" {
    send vendor-class-identifier "BYGTELIAD";
    request subnet-mask, broadcast-address, time-offset, routers,
            domain-name, domain-name-servers, host-name,
            interface-mtu, rfc3442-classless-static-routes;
}
EOF

# Start DHCP client using the patched binary for CoS stability
dhclient -4 -v -i $WAN_INTERFACE.100 -cf /etc/dhcp/dhclient-bouygues.conf