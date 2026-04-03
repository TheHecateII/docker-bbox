#!/bin/bash
if [ -n "$new_ip6_prefix" ]; then
    prefix_root=$(echo "$new_ip6_prefix" | cut -d'/' -f1 | sed 's/::$//')
    ip -6 address flush dev $WAN_INTERFACE.100 scope global
    ip -6 address flush dev $LAN_INTERFACE scope global
    ip address add "${prefix_root%?}1::1/64" dev $WAN_INTERFACE.100
    ip address add "${prefix_root%?}2::1/64" dev $LAN_INTERFACE
    echo "IPv6 configurée sur le préfixe ${prefix_root}"
fi
