#!/bin/bash
# Dipasang identik di 13 node non-router (/root/dns.sh)
# Dipanggil oleh /root/start-all.sh saat interface naik.
# Generik: membaca hostname dan IP node sendiri, jadi isinya sama di semua node.

echo "search K68.com" > /etc/resolv.conf
echo "nameserver 192.245.5.2" >> /etc/resolv.conf
echo "nameserver 192.245.5.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

NAME=$(hostname -s)
# CATATAN: jangan pakai "hostname -I" di sini. Saat dipanggil dari hook "up" waktu boot,
# PATH-nya minimal dan "hostname" menunjuk ke BusyBox yang tidak mendukung flag -I,
# sehingga IP kosong dan baris /etc/hosts yang ditulis jadi cacat.
IP=$(ip -4 addr show eth0 | awk '/inet /{print $2}' | cut -d/ -f1)

grep -vw "$NAME" /etc/hosts > /root/hosts.tmp
if [ -n "$IP" ]; then
    echo "$IP $NAME.K68.com $NAME" >> /root/hosts.tmp
fi
cat /root/hosts.tmp > /etc/hosts
