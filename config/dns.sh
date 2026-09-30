#!/bin/bash
# Dipasang identik di 13 node non-router (/root/dns.sh)
# Generik: membaca hostname dan IP node sendiri, jadi isinya sama di semua node.

echo "search K68.com" > /etc/resolv.conf
echo "nameserver 192.245.5.2" >> /etc/resolv.conf
echo "nameserver 192.245.5.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

NAME=$(hostname -s)
IP=$(hostname -I | awk '{print $1}')
grep -vw "$NAME" /etc/hosts > /root/hosts.tmp
echo "$IP $NAME.K68.com $NAME" >> /root/hosts.tmp
cat /root/hosts.tmp > /etc/hosts
