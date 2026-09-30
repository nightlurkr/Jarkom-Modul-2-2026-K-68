#!/bin/bash
# prab = DNS master (ns1). Letak di node: /root/setup-dns.sh
# Semua config ditulis ulang oleh script ini karena /etc/bind HILANG tiap node restart.

apt-get update -y
apt-get install -y bind9 dnsutils
ln -sf /etc/init.d/named /etc/init.d/bind9
mkdir -p /etc/bind/jarkom

cat > /etc/bind/named.conf.local <<'EOF'
zone "K68.com" {
    type master;
    notify yes;
    also-notify { 192.245.5.3; };
    allow-transfer { 192.245.5.3; };
    file "/etc/bind/jarkom/K68.com";
};

zone "3.245.192.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 192.245.5.3; };
    allow-transfer { 192.245.5.3; };
    file "/etc/bind/jarkom/3.245.192.in-addr.arpa";
};

zone "4.245.192.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 192.245.5.3; };
    allow-transfer { 192.245.5.3; };
    file "/etc/bind/jarkom/4.245.192.in-addr.arpa";
};

zone "5.245.192.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 192.245.5.3; };
    allow-transfer { 192.245.5.3; };
    file "/etc/bind/jarkom/5.245.192.in-addr.arpa";
};
EOF

cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    dnssec-validation no;
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

cat > /etc/bind/jarkom/K68.com <<'EOF'
$TTL    604800
@       IN      SOA     prab.K68.com. root.K68.com. (
                        2026093003 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.K68.com.
@       IN      NS      tedd.K68.com.
@       IN      A       192.245.4.2

prab    IN      A       192.245.5.2
tedd    IN      A       192.245.5.3

rootkit IN      A       192.245.1.1
alpha   IN      A       192.245.1.2
beta    IN      A       192.245.1.3
gamma   IN      A       192.245.1.4
delta   IN      A       192.245.2.2
epsilon IN      A       192.245.2.3
abbey   IN      A       192.245.3.2
penny   IN      A       192.245.4.2
obladi  IN      A       192.245.5.4
desmond IN      A       192.245.5.5
oblada  IN      A       192.245.5.6
molly   IN      A       192.245.5.7

vault   IN      A       192.245.5.4
vault   IN      A       192.245.5.5
core    IN      A       192.245.5.6
core    IN      A       192.245.5.7

www     IN      CNAME   penny.K68.com.
static  IN      CNAME   abbey.K68.com.
EOF

cat > /etc/bind/jarkom/3.245.192.in-addr.arpa <<'EOF'
$TTL    604800
@       IN      SOA     prab.K68.com. root.K68.com. (
                        2026093001 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.K68.com.
@       IN      NS      tedd.K68.com.

2       IN      PTR     abbey.K68.com.
EOF

cat > /etc/bind/jarkom/4.245.192.in-addr.arpa <<'EOF'
$TTL    604800
@       IN      SOA     prab.K68.com. root.K68.com. (
                        2026093001 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.K68.com.
@       IN      NS      tedd.K68.com.

2       IN      PTR     penny.K68.com.
EOF

cat > /etc/bind/jarkom/5.245.192.in-addr.arpa <<'EOF'
$TTL    604800
@       IN      SOA     prab.K68.com. root.K68.com. (
                        2026093001 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.K68.com.
@       IN      NS      tedd.K68.com.

2       IN      PTR     prab.K68.com.
3       IN      PTR     tedd.K68.com.
4       IN      PTR     obladi.K68.com.
5       IN      PTR     desmond.K68.com.
6       IN      PTR     oblada.K68.com.
7       IN      PTR     molly.K68.com.
EOF

service bind9 restart
