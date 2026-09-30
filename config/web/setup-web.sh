#!/bin/bash
# Dipasang identik di obladi dan desmond (area vault). Letak di node: /root/setup-web.sh
# Generik: membaca hostname sendiri.

NAME=$(hostname -s)
apt-get update -y
apt-get install -y apache2

mkdir -p /var/www/$NAME/arsip
echo "<h1>Area Vault - $NAME</h1><p>Repositori web statis K68</p>" > /var/www/$NAME/index.html
echo "catatan operasi the mesh" > /var/www/$NAME/arsip/catatan.txt
echo "log akses gerbang penyaring" > /var/www/$NAME/arsip/log-gerbang.txt
echo "daftar entitas the mesh" > /var/www/$NAME/arsip/entitas.txt

cat > /etc/apache2/sites-available/$NAME.conf <<EOF
<VirtualHost *:80>
    ServerName $NAME.K68.com
    ServerAlias vault.K68.com
    DocumentRoot /var/www/$NAME

    <Directory /var/www/$NAME>
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>

    <Directory /var/www/$NAME/arsip>
        Options +Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2dissite 000-default.conf
a2ensite $NAME.conf
service apache2 restart
