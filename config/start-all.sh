#!/bin/bash
# Dipasang di SEMUA node kecuali NAT dan switch. Letak di node: /root/start-all.sh
# Dipanggil otomatis dari /etc/network/interfaces lewat: up bash /root/start-all.sh

NODE=$(hostname -s)
LOG=/root/startup.log

echo "=== [$(date)] Bootstrap $NODE ===" >> $LOG

# Tunggu network sebentar
sleep 2

# Resolver + /etc/hosts
if [ -f /root/dns.sh ]; then
    bash /root/dns.sh >> $LOG 2>&1
fi

# Setup spesifik per node
case "$NODE" in
    rootkit)
        [ -f /root/nat.sh ] && bash /root/nat.sh >> $LOG 2>&1
        [ -f /root/hostname.sh ] && bash /root/hostname.sh >> $LOG 2>&1
        ;;
    prab|tedd)
        [ -f /root/setup-dns.sh ] && bash /root/setup-dns.sh >> $LOG 2>&1
        ;;
    obladi|desmond)
        [ -f /root/setup-web.sh ] && bash /root/setup-web.sh >> $LOG 2>&1
        ;;
    oblada|molly)
        [ -f /root/setup-core.sh ] && bash /root/setup-core.sh >> $LOG 2>&1
        ;;
    penny)
        [ -f /root/setup-penny.sh ] && bash /root/setup-penny.sh >> $LOG 2>&1
        ;;
    abbey)
        [ -f /root/setup-abbey.sh ] && bash /root/setup-abbey.sh >> $LOG 2>&1
        ;;
esac

echo "=== [$(date)] Selesai $NODE ===" >> $LOG
