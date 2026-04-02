# Docker BBox

A simple Docker image that transforms your host into a Bouygues Telecom BBox, allowing you to bypass the BBox router and use your own hardware with Bouygues fiber (FTTH) in France.

## Overview

This Docker container handles the connection process with Bouygues Telecom's network infrastructure by:

- Creating and configuring a VLAN 100 interface on your WAN interface
- Sending the required DHCP Option 60 (`BYGTELIAD`) vendor identifier
- Optionally cloning your BBox MAC address for seamless IP assignment
- Obtaining IPv4 and IPv6 addresses via DHCPv4 and DHCPv6
- Setting up NAT and forwarding rules for your LAN

## Requirements

- A Linux host with Docker installed
- Two network interfaces (one for LAN, one for WAN connected to the ONT)
- The MAC address of your BBox (recommended, for a smooth transition)
- The container must run in privileged mode with host networking

## Quick Start

```bash
docker run -d \
  --name bbox \
  --privileged \
  --network host \
  -e BBOX_MAC=xx:xx:xx:xx:xx:xx \
  -e LAN_INTERFACE=eth0 \
  -e WAN_INTERFACE=eth1 \
  -e LAN_SUBNET=192.168.1.0/24 \
  bbox
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BBOX_MAC` | *(empty)* | MAC address of your BBox to clone (recommended) |
| `LAN_INTERFACE` | `eth0` | The network interface connected to your local network |
| `WAN_INTERFACE` | `eth1` | The network interface connected to the ONT |
| `LAN_SUBNET` | `192.168.1.0/24` | Your local network subnet for NAT masquerading |
| `MTU` | `1500` | MTU for the VLAN interface |

## How to Get Your BBox MAC Address

Look on the label on the back of your BBox — it is listed as the WAN MAC address. Alternatively, check your Bouygues account or the BBox admin interface before switching.

## How It Works

1. **VLAN Setup**: Creates a VLAN 100 interface on the WAN interface (required by Bouygues)
2. **MAC Cloning**: Optionally sets the VLAN interface MAC to your BBox's MAC address
3. **QoS Configuration**: Sets up nftables rules to add CoS 6 priority for DHCP traffic (strongly recommended by Bouygues)
4. **DHCP**: Sends Option 60 `BYGTELIAD` and obtains an IPv4 address and IPv6 prefix delegation
5. **NAT/Forwarding**: Configures iptables rules for NAT and packet forwarding between LAN and WAN

## Network Setup

```
[Your Devices] <---> [LAN Interface] <---> [Docker Host] <---> [WAN Interface] <---> [ONT] <---> [Bouygues Network]
```

## Building from Source

```bash
git clone <this-repo>
cd docker-livebox
docker build -t bbox .
```

## Notes

- This container requires `--privileged` mode to manage network interfaces and iptables rules
- Host networking (`--network host`) is required to access and configure the host's network interfaces
- No Bouygues credentials are required — authentication is handled via DHCP Option 60 and MAC cloning
- VoIP is not supported: Bouygues Telecom does not provide SIP credentials to third-party equipment

## Acknowledgments

Special thanks to the **[lafibre.info](https://lafibre.info/)** community for their documentation on replacing the BBox with personal equipment.

## License

This project is provided as-is for educational and personal use.
