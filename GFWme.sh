#!/bin/bash
set -e

echo "[*] Updating packages and installing dependencies..."
apt update
apt install -y xtables-addons-common xtables-addons-source xtables-addons-dkms \
               build-essential libgeoip-dev libtext-csv-xs-perl \
               libmoosex-types-netaddr-ip-perl ipset-persistent netfilter-persistent

echo "[*] Downloading GeoIP data..."
if [ -x /usr/libexec/xtables-addons/xt_geoip_dl ]; then
    GEOIP_DL=/usr/libexec/xtables-addons/xt_geoip_dl
    GEOIP_BUILD=/usr/libexec/xtables-addons/xt_geoip_build
elif [ -x /usr/lib/xtables-addons/xt_geoip_dl ]; then
    GEOIP_DL=/usr/lib/xtables-addons/xt_geoip_dl
    GEOIP_BUILD=/usr/lib/xtables-addons/xt_geoip_build
else
    echo "[-] xt_geoip_dl not found!"
    exit 1
fi

$GEOIP_DL
mkdir -p /usr/share/xt_geoip
$GEOIP_BUILD -D /usr/share/xt_geoip

echo "[*] Loading xt_geoip module..."
modprobe xt_geoip || dkms autoinstall && modprobe xt_geoip

echo "[*] Inserting IPv4 DROP rules for CN..."
for proto in tcp udp icmp; do
    iptables -I INPUT  -p $proto -m geoip --src-cc CN -j DROP
    iptables -I OUTPUT -p $proto -m geoip --dst-cc CN -j DROP
done

echo "[*] Inserting IPv6 DROP rules for CN..."
for proto in tcp udp icmpv6; do
    ip6tables -I INPUT  -p $proto -m geoip --src-cc CN -j DROP
    ip6tables -I OUTPUT -p $proto -m geoip --dst-cc CN -j DROP
done

echo "[*] Saving firewall rules..."
netfilter-persistent save
netfilter-persistent reload

echo "[+] All done. Chinese IP traffic is now blocked (IPv4 & IPv6, TCP/UDP/ICMP)."
