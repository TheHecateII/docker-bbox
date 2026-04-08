// SPDX-License-Identifier: GPL-2.0
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/in.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <linux/pkt_cls.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

#define DHCP_PORT_SERVER 67
#define IP_0_0_255_255   bpf_htonl(0x0000FFFFu)

SEC("tc")
int fix_dhcp_egress(struct __sk_buff *skb)
{
    void *data     = (void *)(long)skb->data;
    void *data_end = (void *)(long)skb->data_end;

    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end)
        return TC_ACT_OK;

    if (eth->h_proto != bpf_htons(ETH_P_IP))
        return TC_ACT_OK;

    struct iphdr *iph = (void *)(eth + 1);
    if ((void *)(iph + 1) > data_end)
        return TC_ACT_OK;

    if (iph->protocol != IPPROTO_UDP)
        return TC_ACT_OK;

    if (iph->saddr != IP_0_0_255_255)
        return TC_ACT_OK;

    __u32 ip_hdrlen = iph->ihl * 4;
    if (ip_hdrlen < sizeof(struct iphdr))
        return TC_ACT_OK;

    struct udphdr *udph = (void *)iph + ip_hdrlen;
    if ((void *)(udph + 1) > data_end)
        return TC_ACT_OK;

    if (udph->dest != bpf_htons(DHCP_PORT_SERVER))
        return TC_ACT_OK;

    __u32 csum_off  = ETH_HLEN + __builtin_offsetof(struct iphdr, check);
    __u32 saddr_off = ETH_HLEN + __builtin_offsetof(struct iphdr, saddr);

    __be32 old_saddr = IP_0_0_255_255;
    __be32 new_saddr = 0;

    if (bpf_l3_csum_replace(skb, csum_off, old_saddr, new_saddr, sizeof(__be32)) < 0)
        return TC_ACT_OK;

    if (bpf_skb_store_bytes(skb, saddr_off, &new_saddr, sizeof(new_saddr), 0) < 0)
        return TC_ACT_OK;

    return TC_ACT_OK;
}

char _license[] SEC("license") = "GPL";
