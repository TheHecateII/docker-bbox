# ── Stage 1 : compilation du programme eBPF ──────────────────────────────────
FROM debian:13@sha256:0d01188e8dd0ac63bf155900fad49279131a876a1ea7fac917c62e87ccb2732d AS ebpf-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        clang llvm libbpf-dev linux-libc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY ebpf/fix_dhcp.bpf.c .

RUN clang -O2 -g -target bpf \
        -I/usr/include/$(uname -m)-linux-gnu \
        -c fix_dhcp.bpf.c -o fix_dhcp.bpf.o

# ── Stage 2 : image runtime ───────────────────────────────────────────────────
FROM debian:13@sha256:0d01188e8dd0ac63bf155900fad49279131a876a1ea7fac917c62e87ccb2732d

RUN apt-get update && apt-get install -y supervisor iproute2 iptables gettext-base

RUN apt-get install -y build-essential git && \
    git clone https://github.com/Raraph84/dhclient-orange-patched /tmp/dhclient-orange-patched && \
    cd /tmp/dhclient-orange-patched && ./configure && make && make install && \
    cp /tmp/dhclient-orange-patched/client/scripts/linux /sbin/dhclient-script && \
    mkdir -p /var/lib/dhcp /etc/dhclient-enter-hooks.d /etc/dhclient-exit-hooks.d && \
    rm -rf /tmp/dhclient-orange-patched && \
    apt-get remove -y build-essential git && apt-get autoremove -y && apt-get clean

COPY --from=ebpf-builder /build/fix_dhcp.bpf.o /opt/ebpf/fix_dhcp.bpf.o

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY init.sh /usr/local/bin/init.sh
COPY up-fiber.sh /usr/local/bin/up-fiber.sh
COPY dhclient-bbox-v4.conf.template /etc/dhcp/dhclient-bbox-v4.conf.template
COPY dhclient-bbox-v6.conf /etc/dhcp/dhclient-bbox-v6.conf
COPY dhclient-bbox-generator.sh /etc/dhcp/dhclient-bbox-generator.sh
COPY no-dns-dhcp-enter-hook.sh /etc/dhclient-enter-hooks.d/no-dns
COPY ipv6-dhcp-exit-hook.sh /etc/dhclient-exit-hooks.d/setup-ipv6

RUN sed -i 's/\r//' \
        /usr/local/bin/init.sh \
        /usr/local/bin/up-fiber.sh \
        /etc/dhcp/dhclient-bbox-generator.sh \
        /etc/dhclient-enter-hooks.d/no-dns \
        /etc/dhclient-exit-hooks.d/setup-ipv6 \
    && chmod +x \
        /usr/local/bin/init.sh \
        /usr/local/bin/up-fiber.sh \
        /etc/dhcp/dhclient-bbox-generator.sh \
        /etc/dhclient-enter-hooks.d/no-dns \
        /etc/dhclient-exit-hooks.d/setup-ipv6

ENV LAN_INTERFACE=eth0
ENV WAN_INTERFACE=eth1
ENV LAN_SUBNET=192.168.1.0/24
ENV MTU=1500
ENV BBOX_MAC=
ENV BBOX_DEVICE_ID=
ENV BBOX_SERIAL=
ENV BBOX_HW_VERSION=

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
