#!/bin/bash
# penny (gerbang penyaring). Letak di node: /root/setup-penny.sh
# Mencakup soal 11 (reverse proxy + load balancer), 12 (basic auth /admin),
# 13 (redirect 301), dan 15 (jalur /eternal).
#
# ISI FILE INI DISALIN APA ADANYA DARI NODE.
# CATATAN: baris ServerName pada VirtualHost kedua masih memuat sintaks Markdown
# yang ikut tercopy, dan modul yang diaktifkan masih php8.2 padahal yang terpasang
# php8.4. Keduanya perlu diperbaiki oleh penanggung jawab soal 10-20.

apt-get update -y
apt-get install -y apache2 apache2-utils php libapache2-mod-php

# Aktifkan modul proxy, auth, rewrite, dan php
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers auth_basic authn_file rewrite php8.2

# Buat kredensial Basic Authentication
htpasswd -bc /etc/apache2/.htpasswd prabs "pakar_pinter_jadi_gob***"

# Buat direktori lokal untuk /admin agar ada isinya saat diakses
mkdir -p /var/www/html/admin
echo "<h1>Dokumen Rahasia Sindikat (Penny)</h1>" > /var/www/html/admin/index.html

# Buat direktori lokal untuk /eternal (Soal 15)
mkdir -p /var/www/eternal
cat > /var/www/eternal/index.php << 'HTML_EOF'
<?php
echo "<h1>Ruang Eternal (PHP Running)</h1>";
echo "<p>Waktu Server: " . date('Y-m-d H:i:s') . "</p>";
?>
HTML_EOF
chown -R www-data:www-data /var/www/eternal

cat > /etc/apache2/sites-available/penny-proxy.conf << 'CONFIG_EOF'
# Blok khusus untuk menangani akses via IP dan penny.K68.com (Redirect 301)
<VirtualHost *:80>
    ServerName penny.K68.com
    ServerAlias 192.245.4.2

    Redirect permanent / http://www.K68.com/
</VirtualHost>

# Blok utama untuk www.K68.com (Reverse Proxy)
<VirtualHost *:80>
    ServerName [www.K68.com](https://www.K68.com)

    ProxyPreserveHost On
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s

    <Proxy balancer://vaultcluster>
        BalancerMember http://192.245.5.4:80
        BalancerMember http://192.245.5.5:80
        ProxySet lbmethod=byrequests
    </Proxy>

    # Kecualikan /admin dari reverse proxy
    ProxyPass /admin !
    Alias /admin /var/www/html/admin

    <Directory /var/www/html/admin>
        AuthType Basic
        AuthName "Restricted Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>

    # Kecualikan /eternal dari reverse proxy (Soal 15)
    ProxyPass /eternal !
    Alias /eternal /var/www/eternal

    <Directory /var/www/eternal>
        Require all granted
    </Directory>

    ProxyPass / balancer://vaultcluster/
    ProxyPassReverse / balancer://vaultcluster/
</VirtualHost>
CONFIG_EOF

a2ensite penny-proxy.conf
a2dissite 000-default.conf
service apache2 restart
