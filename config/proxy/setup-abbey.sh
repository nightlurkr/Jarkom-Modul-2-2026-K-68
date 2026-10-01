#!/bin/bash
# abbey (gerbang penyaring). Letak di node: /root/setup-abbey.sh
# Mencakup soal 11 (reverse proxy + load balancer), 13 (redirect 302), dan 15 (jalur /orion).
#
# ISI FILE INI DISALIN APA ADANYA DARI NODE, kecuali dua karakter nyasar "kk"
# sebelum shebang yang dihapus karena membuat baris #!/bin/bash tidak terbaca.

apt-get update -y
apt-get install -y nginx

# Buat direktori lokal untuk /orion (Soal 15)
mkdir -p /var/www/orion
echo "<h1>Ruang Orion (Murni Statis)</h1>" > /var/www/orion/index.html
chown -R www-data:www-data /var/www/orion

cat > /etc/nginx/sites-available/abbey-proxy << 'CONFIG_EOF'
upstream core_backend {
    server 192.245.5.6:80;
    server 192.245.5.7:80;
}

# Blok khusus untuk menangani akses via IP dan abbey.K68.com (Redirect 302)
server {
    listen 80;
    server_name abbey.K68.com 192.245.3.2;

    return 302 http://static.K68.com$request_uri;
}

# Blok utama untuk static.K68.com (Reverse Proxy)
server {
    listen 80;
    server_name static.K68.com;

    # Jalur khusus /orion secara murni statis (Soal 15)
    location /orion {
        alias /var/www/orion;
        index index.html;
    }

    location / {
        proxy_pass http://core_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
CONFIG_EOF

ln -sf /etc/nginx/sites-available/abbey-proxy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
service nginx restart
