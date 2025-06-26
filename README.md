# GFWme

> **GFW yourself!**  
> A simple Bash script to block **all** traffic to and from China (CN) at the IP-tables level, for both IPv4 and IPv6.

## Features

- 🛠️ **One-line install** via `curl` & `bash`  
- 🌐 Blocks **TCP**, **UDP** and **ICMP** traffic to/from CN  
- 🗄️ Persists rules across reboots using `netfilter-persistent`  
- 🔄 Auto-builds and updates GeoIP database via `xtables-addons`

## Installation

```bash
# Download and run the installer script with root privileges
curl -sSL https://cdn.jsdelivr.net/gh/HappyLeslieAlexander/GFWme/GFWme.sh | sudo bash
```
