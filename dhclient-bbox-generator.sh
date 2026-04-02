#!/bin/bash

tohex() {
  for h in $(echo $1 | sed "s/\(.\)/\1 /g"); do printf %02x \'$h; done
}

addsep() {
  echo $(echo $1 | sed "s/\(.\)\(.\)/:\1\2/g")
}

if [ -n "$BBOX_DEVICE_ID" ] && [ -n "$BBOX_SERIAL" ] && [ -n "$BBOX_HW_VERSION" ]; then
    id_hex=$(tohex "$BBOX_DEVICE_ID")
    serial_hex=$(tohex "$BBOX_SERIAL")
    hwver_hex=$(tohex "$BBOX_HW_VERSION")

    id_len=$(printf '%02x' ${#BBOX_DEVICE_ID})
    serial_len=$(printf '%02x' ${#BBOX_SERIAL})
    hwver_len=$(printf '%02x' ${#BBOX_HW_VERSION})

    sub_data="01:${id_len}:$(addsep $id_hex):02:${serial_len}:$(addsep $serial_hex):03:${hwver_len}:$(addsep $hwver_hex)"
    sub_data_len=$(printf '%02x' $(( ${#BBOX_DEVICE_ID} + ${#BBOX_SERIAL} + ${#BBOX_HW_VERSION} + 6 )))

    export VIVSO_OPTION="send vivso 00:00:0d:e9:${sub_data_len}:${sub_data};"
else
    export VIVSO_OPTION=""
fi

envsubst < /etc/dhcp/dhclient-bbox-v4.conf.template > /etc/dhcp/dhclient-bbox-v4.conf
