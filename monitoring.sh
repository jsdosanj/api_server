#!/bin/zsh -f
#
# $Header$
# Look for suspicious and self-signed SSL certificates
tcpdump -s 1500 -A '(tcp[((tcp[12:1] & 0xf0) >> 2)+5:1] = 0x01) and (tcp[((12:1] & 0xf0) >> 2) :1] = 0x16)'

# Use netcat to listen for scanning threats
nc -v -k -l 80
nc -v -k -l 443
nmap -p 80-443 192.168.0.1