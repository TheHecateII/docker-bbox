<p align="center">
  <img width="500" height="500" src="https://github.com/user-attachments/assets/8c42cbdc-f317-4d2b-a72e-6097a781e043" />
</p>

A Docker image that transforms your host into a Bouygues Telecom BBox, allowing you to bypass the BBox router and use your own hardware with Bouygues fiber (FTTH) in France.

## ⚠️ Recommended: Bare Metal with compatible hardware

For the moment, **bare metal installation with compatible hardware is recommended**. Certain environments may encounter issues with DHCP packet handling (see [Hardware compatibility](#hardware-compatibility) below).

## What it does

- Creates a VLAN 100 interface on the WAN interface
- Applies CoS 6 priority to DHCP traffic (required for stable IP assignment)
- Sends DHCP Option 60 `BYGTELIAD` and optionally Option 125 (device fingerprint)
- Optionally clones the BBox MAC address
- Obtains an IPv4 address and IPv6 prefix delegation (/60)
- Sets up NAT and forwarding between LAN and WAN

## Hardware compatibility

There is a bug in the Linux kernel affecting nftables `netdev egress` hooks on VLAN interfaces with certain network drivers. The DHCP wildcard address shifts from `0.0.0.0` to `0.0.255.255`, which Bouygues rejects (Orange is more permissive and responds anyway).

**Affected drivers:**
- **VirtIO** — Virtual NICs on Proxmox, QEMU, KVM, etc.
- **bcmgenet** — Raspberry Pi 4 and 5 built-in Ethernet

**Not affected:**
- **Intel E1000/E1000e** — Physical or emulated Intel NICs

**Workarounds:**
- Use bare metal with an Intel NIC or compatible USB Ethernet adapter
- If virtualized: Switch the WAN NIC model to **Intel E1000** instead of VirtIO

> 🧪 **Experimental:** A hard patch using an eBPF TC egress program is currently being tested. It intercepts outgoing DHCP packets and corrects the corrupted source address before transmission, allowing the image to run on affected drivers (VirtIO, bcmgenet) without changing hardware. This may become the default fix once validated.

A bug report has been submitted to the netfilter developers.

## Limitations

- **TV not supported** — Bouygues TV requires IGMP Proxy configuration which is not handled by this container
- **VoIP not supported** — Bouygues does not provide SIP credentials to third-party equipment

## Requirements

- A Linux host with Docker installed
- Two network interfaces (LAN and WAN connected to the ONT)
- The MAC address of your BBox (recommended)
- `--privileged` mode and `--network host`

## Usage

> ⚠️ **WARNING:** Before starting, please ensure that the **IP Full-Stack** option is enabled in your customer portal. If it is not, your connection will use **MAP-T** or **CGNAT**, which will prevent this standard DHCP configuration from working properly.

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
| `BBOX_MAC` | *(empty)* | WAN MAC address of your BBox (label on the back) |
| `LAN_INTERFACE` | `eth0` | LAN-side network interface |
| `WAN_INTERFACE` | `eth1` | WAN-side network interface (connected to the ONT) |
| `LAN_SUBNET` | `192.168.1.0/24` | LAN subnet for NAT masquerading |
| `MTU` | `1500` | MTU for the VLAN interface |
| `BBOX_DEVICE_ID` | *(empty)* | Option 125 sub-option 1 (e.g. `001BBF`) |
| `BBOX_SERIAL` | *(empty)* | Option 125 sub-option 2 (e.g. `124235801379499`) |
| `BBOX_HW_VERSION` | *(empty)* | Option 125 sub-option 3 (e.g. `5330b-r1`) |

`BBOX_DEVICE_ID`, `BBOX_SERIAL` and `BBOX_HW_VERSION` are all required together to include Option 125. If any is missing, Option 125 is omitted. These values can be found by capturing the BBox DHCP traffic before replacing it.

## Build

```bash
docker build -t bbox .
```

## Acknowledgments

- [lafibre.info](https://lafibre.info/) community for their documentation on replacing the BBox
- [Raraph84/docker-livebox](https://github.com/Raraph84/docker-livebox) — original project this is based on
- [Raraph84/dhclient-orange-patched](https://github.com/Raraph84/dhclient-orange-patched) — patched dhclient fixing CoS tagging at socket level
