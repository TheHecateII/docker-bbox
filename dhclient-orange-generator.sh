#!/bin/bash

tohex() {
  for h in $(echo $1 | sed "s/\(.\)/\1 /g"); do printf %02x \'$h; done
}

addsep() {
  echo $(echo $1 | sed "s/\(.\)\(.\)/:\1\2/g")
}

r=$(dd if=/dev/urandom bs=1k count=1 2>&1 | md5sum | cut -c1-16)
id=${r:0:1}
h=3c12$(tohex ${r})0313$(tohex ${id})$(echo -n ${id}${FIBER_PASSWORD}${r} | md5sum | cut -c1-32)

# vendor class
export VENDOR_CLASS_IDENTIFIER_4=sagem
export VENDOR_CLASS_IDENTIFIER_6=00:00:04:0e:00:05$(addsep $(tohex sagem))
echo "Vendor class has been generated"

# user class
export USER_CLASS_4=+FSVDSL_livebox.Internet.softathome.Livebox5
export USER_CLASS_6=00$(addsep $(tohex "+FSVDSL_livebox.Internet.softathome.Livebox5"))
echo "User class has been generated"

# option 90
export AUTHENTICATION_STR=00:00:00:00:00:00:00:00:00:00:00:1a:09:00:00:05:58:01:03:41:01:0d$(addsep $(tohex ${FIBER_LOGIN})${h})
echo "Option 90 has been generated"

# Generate DHCP client (ivp4 and ivp6) files
envsubst < /etc/dhcp/dhclient-orange-v4.conf.template > /etc/dhcp/dhclient-orange-v4.conf
envsubst < /etc/dhcp/dhclient-orange-v6.conf.template > /etc/dhcp/dhclient-orange-v6.conf
