#!/bin/bash

if [ -n "$new_ip6_prefix" ]; then
    base_prefix=$(echo "$new_ip6_prefix" | sed -E 's/.{7}$//')

    ip -6 address flush dev $WAN_INTERFACE.100 scope global
    ip -6 address flush dev $LAN_INTERFACE scope global

    ip address add "$base_prefix"01::1/64 dev $WAN_INTERFACE.100
    ip address add "$base_prefix"02::1/64 dev $LAN_INTERFACE
    echo "Updated IPv6 addresses"
fi
