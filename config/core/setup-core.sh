#!/bin/bash
# oblada dan molly (area core). Letak di node: /root/setup-core.sh
# Generik: membaca hostname sendiri.

NODE_NAME=$(hostname -s)
WEB_ROOT="/var/www/$NODE_NAME"

mkdir -p "$WEB_ROOT"

cat > "$WEB_ROOT/index.php" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Beranda Core</title></head>
<body>
    <h1>Selamat Datang di Area Core</h1>
    <p>Node: <?php echo gethostname(); ?></p>
    <p>Status: Web Dinamis PHP 8.4-FPM Aktif</p>
    <p><a href="/profil">Ke Halaman Profil (Clean URL)</a></p>
</body>
</html>
EOF

cat > "$WEB_ROOT/profil.php" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Profil Node Core</title></head>
<body>
    <h1>Halaman Profil Entitas</h1>
    <p>Identitas Hostname: <strong><?php echo gethostname(); ?>.K68.com</strong></p>
    <p>Waktu Server: <?php echo date('Y-m-d H:i:s'); ?></p>
    <p><a href="/">Kembali ke Beranda</a></p>
</body>
</html>
EOF

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

service php8.4-fpm start

cat > /etc/nginx/sites-available/core << EOF
server {
    listen 80;
    server_name ${NODE_NAME}.K68.com ${NODE_NAME}.k68.com core.K68.com core.k68.com;

    root $WEB_ROOT;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ \$uri.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/core /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

service php8.4-fpm restart
service nginx restart
