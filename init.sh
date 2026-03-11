#!/bin/bash -e

echo "### Starting Bouygues Bypass Setup ###"

# 1. Setup VLAN 100 with Bbox MAC address
ip link set $WAN_INTERFACE up
ip link add link $WAN_INTERFACE name $WAN_INTERFACE.100 address $BBOX_MAC type vlan id 100
ip link set $WAN_INTERFACE.100 up

# 2. Set up surgical CoS 6 priority via nftables
# We only mark control traffic to keep maximum speed on data
nft add table netdev filter
nft add chain netdev filter egress { type filter hook egress device $WAN_INTERFACE.100 priority 0; }

# Mark DHCP (v4 & v6) and ARP with Priority 6
nft insert rule netdev filter egress udp dport { 67, 547 } meta priority set 0:6
nft insert rule netdev filter egress ether type arp meta priority set 0:6

# 3. Routing & NAT
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s $LAN_SUBNET -o $WAN_INTERFACE.100 -j MASQUERADE
iptables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE.100 -j ACCEPT
iptables -A FORWARD -i $WAN_INTERFACE.100 -o $LAN_INTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "### Networking ready, requesting IP... ###"
/usr/local/bin/up-fiber.sh