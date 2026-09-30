#!/bin/bash
# tedd = DNS slave (ns2). Letak di node: /root/setup-dns.sh

apt-get update -y
apt-get install -y bind9 dnsutils
ln -sf /etc/init.d/named /etc/init.d/bind9
mkdir -p /etc/bind/jarkom
# WAJIB: tanpa ini bind tidak bisa menulis file hasil zone transfer
chown -R bind:bind /etc/bind/jarkom

cat > /etc/bind/named.conf.local <<'EOF'
zone "K68.com" {
    type slave;
    masters { 192.245.5.2; };
    file "/etc/bind/jarkom/K68.com";
};

zone "3.245.192.in-addr.arpa" {
    type slave;
    masters { 192.245.5.2; };
    file "/etc/bind/jarkom/3.245.192.in-addr.arpa";
};

zone "4.245.192.in-addr.arpa" {
    type slave;
    masters { 192.245.5.2; };
    file "/etc/bind/jarkom/4.245.192.in-addr.arpa";
};

zone "5.245.192.in-addr.arpa" {
    type slave;
    masters { 192.245.5.2; };
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

service bind9 restart
