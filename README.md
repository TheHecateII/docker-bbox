---

# Docker Bbox (Fork of Docker-Livebox)

* **Original Source**: [Raraph84/docker-livebox](https://github.com/Raraph84/docker-livebox)
* **Knowledge Base**: [LaFibre.info](https://lafibre.info/)

A simple Docker image that transforms your host into a Bouygues Telecom compatible router (FTTH), allowing you to bypass the Bbox and use your own hardware while keeping the original Huawei/Nokia ONT.

## Overview

This Docker container handles the connection and authentication process with Bouygues Telecom's network by:

* Creating and configuring a **VLAN 100** interface on your WAN interface.
* Using a patched `dhclient` binary to ensure proper Class of Service (CoS) marking.
* Setting up **CoS 6** marking via `nftables` on control traffic only (DHCP, ARP) to prevent any speed throttling.
* Cloning your Bbox's MAC address for immediate identification.
* Providing NAT and forwarding rules for your local area network (LAN).

## Requirements

* A Linux host (Debian 12/13 recommended) with Docker installed.
* Two network interfaces (one for LAN, one for WAN connected to the ONT).
* Your Bbox's MAC address (found on the device label).
* The container must run in `--privileged` mode with host networking (`--network host`).

## Quick Start

```bash
docker run -d \
--name bbox-bypass \
--privileged \
--network host \
-e BBOX_MAC=XX:XX:XX:XX:XX:XX \
-e LAN_INTERFACE=eth0 \
-e WAN_INTERFACE=eth1 \
-e LAN_SUBNET=192.168.1.0/24 \
your-repo/docker-bbox

```

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `BBOX_MAC` | N/A | Your original Bbox MAC address (Format `XX:XX:XX:XX:XX:XX`) |
| `LAN_INTERFACE` | `eth0` | The network interface connected to your local switch/network |
| `WAN_INTERFACE` | `eth1` | The network interface connected to the Bouygues ONT |
| `LAN_SUBNET` | `192.168.1.0/24` | Your local network subnet for NAT masquerading |
| `MTU` | `1500` | MTU for the VLAN interface |

## How It Works

1. **VLAN Setup**: Creates a VLAN 100 interface on the WAN interface, as required by Bouygues Telecom.
2. **MAC Cloning**: Applies the Bbox MAC address to the virtual interface for DHCP authentication.
3. **QoS Configuration**: Uses `nftables` to apply **CoS 6** (PCP) priority on DHCP requests and ARP packets.
4. **DHCP**: Obtains a public IPv4 address via DHCP by sending the Vendor Class ID `BYGTELIAD` (Option 60).
5. **NAT/Forwarding**: Configures `iptables` for NAT and packet forwarding between the LAN and WAN interfaces.

## Acknowledgments

This project is a fork adapted from work of:

* **[Raraph84](https://github.com/Raraph84)** for the original `docker-livebox` project and the `dhclient-orange-patched` which resolves network priority issues.
* The **[lafibre.info](https://lafibre.info/)** community for technical guides on Bbox replacement.

## License

This project is provided as-is for educational and personal use.

---
