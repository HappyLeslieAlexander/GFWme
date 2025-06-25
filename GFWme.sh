#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "[*] Updating packages and installing dependencies..."
apt update
apt install -y xtables-addons-common xtables-addons-source xtables-addons-dkms \
               build-essential libgeoip-dev libtext-csv-xs-perl \
               libmoosex-types-netaddr-ip-perl ipset-persistent netfilter-persistent

echo "[*] Locating xt_geoip tools..."
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

echo "[*] Downloading and building GeoIP database..."
mkdir -p /usr/share/xt_geoip
$GEOIP_DL
$GEOIP_BUILD -D /usr/share/xt_geoip

echo "[*] Loading xt_geoip kernel module..."
modprobe xt_geoip || { echo "[!] Module not found, trying dkms autoinstall..."; dkms autoinstall && modprobe xt_geoip; }

echo "[*] Inserting iptables rules to DROP China (CN) traffic..."

for proto in tcp udp icmp; do
    iptables -I INPUT  -p $proto -m geoip --src-cc CN -j DROP || true
    iptables -I OUTPUT -p $proto -m geoip --dst-cc CN -j DROP || true
done

for proto in tcp udp icmpv6; do
    ip6tables -I INPUT  -p $proto -m geoip --src-cc CN -j DROP || true
    ip6tables -I OUTPUT -p $proto -m geoip --dst-cc CN -j DROP || true
done

echo "[*] Saving iptables rules for persistence..."
netfilter-persistent save || true
netfilter-persistent reload || true

echo "[+] All done. CN traffic is blocked (IPv4 & IPv6, TCP/UDP/ICMP)."
