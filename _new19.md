## Soal 1 — Topologi dan Pengalamatan IP

> Sebagai pusat kesadaran The Mesh, rootkit harus merentangkan koneksinya ke lima gerbang utama (Switch). Tetapkan alamat IP dan default gateway untuk seluruh Entitas, mulai dari para operator (alpha, beta, gamma), penjaga directory (prab, tedd), gerbang penyaring (abbey, penny), hingga repository (obladi, desmond, oblada, molly) sesuai dengan topologi pembagian switch yang dirancang.

### Langkah Pengerjaan

**1. Menyiapkan node dan switch.**
Empat belas node DebiNet, tujuh Ethernet switch, dan satu node NAT disusun sesuai gambar topologi.

**2. Menaikkan jumlah adapter rootkit menjadi 8.**
Dilakukan lewat klik kanan node → Configure → tab Network → Adapters, dalam keadaan node mati. Perubahan dilakukan **per node**, bukan lewat Edit → Preferences, karena template pada remote controller dipakai bersama seluruh kelompok.

**3. Menyambung kabel berurutan dari `eth0` di sisi rootkit.**
Nama interface di dalam node ditentukan oleh nomor slot adapter di GNS3. Kabel yang tertukar menghasilkan konfigurasi yang benar secara sintaks tetapi terpasang di jaringan yang salah.

| Port rootkit | Tujuan |
|---|---|
| eth0 | NAT1 |
| eth1 | Switch6 |
| eth2 | Switch7 |
| eth3 | Switch4 |
| eth4 | Switch5 |
| eth5 | Switch1 |

**4. Menulis konfigurasi IP** lewat klik kanan node → **Edit network configuration** (node dalam keadaan mati), yang mengedit `/etc/network/interfaces`.

### Script dan Konfigurasi

**rootkit** — `/etc/network/interfaces` — [`config/rootkit/interfaces`](config/rootkit/interfaces)

```
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
	address 192.245.1.1
	netmask 255.255.255.0

auto eth2
iface eth2 inet static
	address 192.245.2.1
	netmask 255.255.255.0

auto eth3
iface eth3 inet static
	address 192.245.3.1
	netmask 255.255.255.0

auto eth4
iface eth4 inet static
	address 192.245.4.1
	netmask 255.255.255.0

auto eth5
iface eth5 inet static
	address 192.245.5.1
	netmask 255.255.255.0
```

Interface `eth1`–`eth5` sengaja **tidak diberi baris `gateway`**. Default gateway hanya boleh ada satu per host, dan bagi router jalur keluarnya adalah `eth0` yang sudah memperolehnya otomatis dari DHCP NAT. Menambahkan gateway di interface LAN akan membuat router mengarahkan trafik keluar ke jaringan internalnya sendiri.

**13 node non-router** — `/etc/network/interfaces` — [`config/interfaces/`](config/interfaces/)

Pola yang sama di semua node, hanya `address` dan `gateway` yang berbeda. Contoh alpha:

```
auto eth0
iface eth0 inet static
	address 192.245.1.2
	netmask 255.255.255.0
	gateway 192.245.1.1
```

| Node | address | gateway |
|---|---|---|
| alpha | 192.245.1.2 | 192.245.1.1 |
| beta | 192.245.1.3 | 192.245.1.1 |
| gamma | 192.245.1.4 | 192.245.1.1 |
| delta | 192.245.2.2 | 192.245.2.1 |
| epsilon | 192.245.2.3 | 192.245.2.1 |
| abbey | 192.245.3.2 | 192.245.3.1 |
| penny | 192.245.4.2 | 192.245.4.1 |
| prab | 192.245.5.2 | 192.245.5.1 |
| tedd | 192.245.5.3 | 192.245.5.1 |
| obladi | 192.245.5.4 | 192.245.5.1 |
| desmond | 192.245.5.5 | 192.245.5.1 |
| oblada | 192.245.5.6 | 192.245.5.1 |
| molly | 192.245.5.7 | 192.245.5.1 |

> Pada soal 3 setiap blok `iface` ini ditambah baris `up bash /root/dns.sh`, dan pada soal 20 baris tersebut diganti menjadi `up bash /root/start-all.sh`.

### Pengujian

![Soal 1](screenshot/soal01-ip-dan-ping.png)

| Uji | Hasil |
|---|---|
| `ip a` di rootkit | eth1–eth5 memegang IP sesuai rancangan |
| alpha → 192.245.1.1 | berhasil, gateway terjangkau |
| alpha → beta | berhasil, komunikasi sesubnet |
| prab → obladi | berhasil, membuktikan cascade Switch1–2–3 benar-benar satu subnet |

---

## Soal 2 — WAN dan NAT

> Meskipun The Mesh beroperasi dalam bayang-bayang, Rootkit menyadari bahwa Entitas di dalamnya masih membutuhkan asupan paket dari dunia luar. Buka jalur menuju NAT dengan memastikan antarmuka WAN di router rootkit aktif. Konfigurasikan NAT agar dapat meneruskan lalu lintas keluar bagi seluruh alamat internal, sehingga semua host di dalam jaringan dapat menjangkau internet publik menggunakan IP address.

### Langkah Pengerjaan

**1. Memastikan `eth0` aktif dan memperoleh alamat dari NAT.**
Diperiksa dengan `ip a show eth0`, memperoleh `192.168.122.69/24`.

**2. Menulis script NAT di `/root/nat.sh`.**
Diletakkan di `/root` karena hanya direktori itu dan `/etc/network/interfaces` yang bertahan saat node restart.

**3. Menjalankan script dan memverifikasi aturan iptables.**

### Script dan Konfigurasi

**rootkit** — `/root/nat.sh` — [`config/rootkit/nat.sh`](config/rootkit/nat.sh)

```bash
#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

Perintah yang dijalankan di konsol rootkit:

```bash
cat > /root/nat.sh <<'EOF'
#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF
chmod +x /root/nat.sh
bash /root/nat.sh
```

`ip_forward` mengizinkan kernel meneruskan paket antar interface. Tanpa ini node hanya bisa berbicara dengan tetangga sesubnet.

`MASQUERADE` dipilih daripada `SNAT` karena alamat `eth0` diperoleh lewat DHCP dan bisa berubah. `MASQUERADE` membaca alamat interface secara dinamis, sedangkan `SNAT` memerlukan alamat yang ditulis tetap.

> Pada soal 20, baris `iptables -A` diganti menjadi pola `-C ... || -A` agar aturan tidak menumpuk setiap kali script dipanggil saat boot.

### Pengujian

![Soal 2](screenshot/soal02-nat-masquerade.png)

| Uji | Hasil |
|---|---|
| `iptables -t nat -L POSTROUTING -n -v` | aturan `MASQUERADE ... out:eth0` terpasang |
| `ip a show eth0` | 192.168.122.69/24 diterima dari NAT |
| alpha → 8.8.8.8 | berhasil, ttl 110 |

---

## Soal 3 — Routing Internal dan Resolver Awal

> Jaringan rahasia tidak akan berfungsi tanpa sinkronisasi antar divisi. Pastikan seluruh Entitas dapat saling terhubung dan berkomunikasi lintas jalur (routing internal via rootkit berfungsi). Untuk menghindari fragmentasi saat persiapan, pastikan setiap host non-router menambahkan resolver 192.168.122.1 saat antarmukanya aktif agar akses untuk mengunduh paket instalasi dari internet tersedia sejak awal beroperasi.

### Langkah Pengerjaan

**1. Routing antar subnet tidak memerlukan konfigurasi tambahan.**
Begitu `ip_forward=1` aktif di rootkit dan setiap node memiliki default gateway yang benar, router sudah mengenal kelima subnet secara langsung melalui interface-nya masing-masing.

**2. Membuat `/root/dns.sh` di 13 node non-router** (node dalam keadaan hidup).

**3. Memasang pemanggil di `/etc/network/interfaces`** (node dalam keadaan mati).

Frasa **"saat antarmukanya aktif"** pada soal menentukan cara pengerjaannya. `/etc/resolv.conf` termasuk file yang hilang setiap node restart, sehingga resolver tidak boleh diketik manual melainkan harus dipasang ulang otomatis setiap interface naik.

### Script dan Konfigurasi

**13 node non-router** — `/root/dns.sh` (versi soal 3)

```bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

Perintah yang dijalankan di konsol tiap node:

```bash
cat > /root/dns.sh <<'EOF'
echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
chmod +x /root/dns.sh
bash /root/dns.sh
```

**13 node non-router** — `/etc/network/interfaces`, satu baris ditambahkan di bawah `gateway`:

```
	up bash /root/dns.sh
```

Sehingga blok `iface` alpha menjadi:

```
auto eth0
iface eth0 inet static
	address 192.245.1.2
	netmask 255.255.255.0
	gateway 192.245.1.1
	up bash /root/dns.sh
```

**rootkit** — `/etc/network/interfaces`, pemanggil NAT ditambahkan:

```
auto eth0
iface eth0 inet dhcp
	up bash /root/nat.sh
```

Perintah pengalihan `>` sengaja ditempatkan **di dalam file script**, bukan langsung sebagai baris `up`. Editor "Edit network configuration" GNS3 membuang baris yang memuat karakter `>`, sehingga penulisan langsung akan hilang tanpa peringatan.

> Isi `dns.sh` diperluas pada soal 4 (urutan resolver prab → tedd → 192.168.122.1) dan soal 5 (penulisan `/etc/hosts`). Versi finalnya ada di [`config/dns.sh`](config/dns.sh).

### Pengujian

![Soal 3](screenshot/soal03-routing-resolver.png)

| Uji | Hasil |
|---|---|
| alpha → molly (subnet 1 ke 5) | berhasil, ttl 63 |
| alpha → abbey (subnet 1 ke 3) | berhasil, ttl 63 |
| molly → alpha | berhasil, arah sebaliknya |
| `cat /etc/resolv.conf` | resolver terpasang otomatis |

Nilai **ttl 63** menunjukkan paket melewati tepat satu router, sesuai rancangan.

---

## Soal 4 — Zona DNS Master dan Slave

> Penjaga Direktori mulai menuliskan hukum The Mesh. Pada node prab, bangun zona `K68.com` sebagai authoritative dengan SOA yang menunjuk ke `prab.K68.com`, serta tambahkan catatan NS untuk `prab.K68.com` dan `tedd.K68.com`. Buat A record untuk keduanya yang mengarah ke alamat IP mereka masing-masing, serta A record apex `K68.com` yang mengarah ke gerbang aplikasi dinamis (penny). Aktifkan fitur notify dan allow-transfer ke tedd, lalu set forwarders ke 192.168.122.1. Di node tedd, tarik zona dari master dan pastikan server menjawab secara authoritative. Setelah itu, perbarui urutan resolver pada seluruh Entitas non-router menjadi: IP prab, IP tedd, lalu 192.168.122.1.

### Langkah Pengerjaan

**1. Menulis seluruh konfigurasi BIND sebagai script di `/root/setup-dns.sh`,** bukan mengetik langsung ke `/etc/bind`. Direktori `/etc/bind` hilang setiap node restart, sehingga konfigurasi harus dapat dibangun ulang dari `/root`.

**2. Menjalankan script di prab, lalu memverifikasi dengan `named-checkconf` dan `named-checkzone`.**

**3. Menjalankan script serupa di tedd dengan `type slave`.**

**4. Memperbarui urutan resolver di 13 node non-router.**

### Script dan Konfigurasi

**prab (ns1, master)** — `/root/setup-dns.sh` — [`config/prab/setup-dns.sh`](config/prab/setup-dns.sh)

```bash
#!/bin/bash
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
                        2026093001 ; Serial
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
EOF

service bind9 restart
```

![Config prab](screenshot/soal04-config-prab.png)

`notify yes` membuat master mengabari slave setiap zona berubah, `also-notify` menyebut alamat slave secara eksplisit, dan `allow-transfer` memberi izin slave menarik salinan zona. Ketiganya harus ada — tanpa `allow-transfer`, notify tetap terkirim tetapi transfer akan ditolak.

`forwarders` mengarahkan pertanyaan di luar zona `K68.com` ke DNS milik NAT, sehingga node tetap dapat membuka alamat internet meski resolver-nya sudah diarahkan ke prab.

![Zona prab](screenshot/soal04-zona-prab.png)

**tedd (ns2, slave)** — `/root/setup-dns.sh` — [`config/tedd/setup-dns.sh`](config/tedd/setup-dns.sh)

```bash
#!/bin/bash
apt-get update -y
apt-get install -y bind9 dnsutils
ln -sf /etc/init.d/named /etc/init.d/bind9
mkdir -p /etc/bind/jarkom
chown -R bind:bind /etc/bind/jarkom

cat > /etc/bind/named.conf.local <<'EOF'
zone "K68.com" {
    type slave;
    masters { 192.245.5.2; };
    file "/etc/bind/jarkom/K68.com";
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
```

![Config tedd](screenshot/soal04-config-tedd.png)

Baris `chown -R bind:bind /etc/bind/jarkom` bersifat wajib pada slave. File hasil zone transfer ditulis oleh proses `named` yang berjalan sebagai user `bind`; tanpa kepemilikan yang benar, transfer akan gagal dan zona tidak pernah termuat.

**13 node non-router** — `/root/dns.sh` diperbarui, resolver diurutkan ulang:

```bash
echo "nameserver 192.245.5.2" > /etc/resolv.conf
echo "nameserver 192.245.5.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf
```

### Pengujian

![Dig prab dan tedd](screenshot/soal04-dig-prab-tedd.png)

![Dig via resolver](screenshot/soal04-dig-via-resolver.png)

| Uji | Hasil |
|---|---|
| `dig @192.245.5.2 K68.com` | apex → 192.245.4.2, flag `aa` |
| `dig @192.245.5.3 K68.com` | jawaban identik dari slave, flag `aa` |
| `dig K68.com` tanpa `@` | dijawab lewat resolver, flag `aa` |
| `dig prab.K68.com` / `dig tedd.K68.com` | sesuai alamat masing-masing |

Flag **`aa`** (authoritative answer) pada jawaban kedua server menandakan keduanya benar-benar memegang zona, bukan sekadar meneruskan atau menyajikan cache.

---

## Soal 5 — Hostname dan Domain per Node

> "Entitas tanpa identitas adalah anomali," pesan Rootkit. Namai semua Entitas (hostname) sesuai glosarium dan verifikasi bahwa setiap host mengenali hostname tersebut secara system-wide. Buat setiap domain untuk masing-masing node sesuai dengan namanya dan assign IP masing-masing juga. Lakukan pengecualian untuk node yang bertanggung jawab atas prab dan tedd.

### Langkah Pengerjaan

**1. Hostname pendek tidak perlu dikonfigurasi.**
GNS3 sudah menetapkannya dari nama node, terbukti dari prompt `root@alpha:~#`.

**2. Memperbaiki `hostname -f` yang masih mengembalikan nama pendek.**
Penyebabnya, `/etc/hosts` bawaan container hanya memuat pasangan alamat dan nama pendek, dan `hostname -f` membaca `/etc/hosts` lebih dahulu daripada DNS. Menambahkan `search` saja tidak menolong karena berkas lokal selalu diperiksa lebih dulu.

**3. Menambah 12 A record ke zona di prab dan menaikkan serial.**

### Script dan Konfigurasi

**13 node non-router** — `/root/dns.sh` versi final — [`config/dns.sh`](config/dns.sh)

```bash
echo "search K68.com" > /etc/resolv.conf
echo "nameserver 192.245.5.2" >> /etc/resolv.conf
echo "nameserver 192.245.5.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

NAME=$(hostname -s)
IP=$(hostname -I | awk '{print $1}')
grep -vw "$NAME" /etc/hosts > /root/hosts.tmp
echo "$IP $NAME.K68.com $NAME" >> /root/hosts.tmp
cat /root/hosts.tmp > /etc/hosts
```

Script dibuat generik — membaca hostname dan alamat node sendiri — sehingga isinya identik di ketiga belas node dan tidak perlu disesuaikan satu per satu.

> Pada soal 20, `hostname -I` diganti menjadi `ip -4 addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1` agar portabel di BusyBox maupun coreutils.

**rootkit** — `/root/hostname.sh` — [`config/rootkit/hostname.sh`](config/rootkit/hostname.sh)

rootkit memiliki banyak alamat sehingga tidak bisa memakai script generik di atas:

```bash
#!/bin/bash
grep -vw rootkit /etc/hosts > /root/hosts.tmp
echo "192.245.1.1 rootkit.K68.com rootkit" >> /root/hosts.tmp
cat /root/hosts.tmp > /etc/hosts
```

**prab** — tambahan pada `/etc/bind/jarkom/K68.com`, serial dinaikkan ke `2026093002`:

```
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
```

![Zona lengkap](screenshot/soal05-zona-lengkap.png)

**prab dan tedd dikecualikan** dari penambahan A record karena keduanya sudah memilikinya sejak soal 4; menambahkannya lagi akan menghasilkan duplikat.

Perlu dibedakan: pengecualian ini hanya berlaku untuk A record di zona. Untuk `dns.sh`, prab dan tedd **tetap ikut** karena soal 4 meminta resolver diurutkan ulang pada seluruh Entitas non-router.

### Pengujian

![Hostname](screenshot/soal05-hostname.png)

![Dig node](screenshot/soal05-dig-node.png)

| Uji | Hasil |
|---|---|
| `hostname -f` di delta, penny, beta, abbey | mengembalikan FQDN lengkap |
| `dig <node>.K68.com +short` | seluruh node sesuai tabel alamat |

### Kendala yang Ditemui

Setelah konfigurasi diperbarui, seluruh kueri DNS gagal dengan `connection refused` dari prab maupun tedd.

Pemeriksaan pertama di tedd menghasilkan ratusan baris `line 1: syntax error` dari `named-checkzone`. **Diagnosa ini menyesatkan.** File zona pada server slave disimpan BIND dalam format raw (biner), bukan teks, sehingga `named-checkzone` memang tidak dapat membacanya. Error tersebut normal dan bukan penyebab masalah.

Pemeriksaan ulang dilakukan di master. File zona terbukti sehat — 27 baris, `named-checkzone` mengembalikan `OK`, serial terbaca `2026093002`. Yang bermasalah adalah `service bind9 status` yang melaporkan `bind is not running`. Node sempat dimatikan untuk mengedit `interfaces`, dan BIND tidak menyala otomatis saat node dihidupkan kembali. Perbaikannya menjalankan `service bind9 start` di prab dan tedd.

Urutan diagnosa yang benar untuk kasus DNS mati: periksa status service di **master** lebih dahulu, jalankan `named-checkzone` hanya di master, baru periksa slave. Persistensi service inilah yang kemudian diselesaikan pada soal 20.

---

## Soal 6 — Verifikasi Zone Transfer

> Pastikan zone transfer berjalan, pastikan tedd telah menerima salinan zona terbaru dari prab. Nilai serial SOA di keduanya harus sama karena keduanya tidak bisa dipisahkan dan saling melengkapi.

### Langkah Pengerjaan

Soal ini **tidak memerlukan script atau konfigurasi baru**. Seluruh mekanismenya sudah dipasang pada soal 4:

| Sisi | Konfigurasi | Fungsi |
|---|---|---|
| prab (master) | `notify yes` | mengabari slave setiap zona berubah |
| prab (master) | `also-notify { 192.245.5.3; }` | menyebut alamat slave secara eksplisit |
| prab (master) | `allow-transfer { 192.245.5.3; }` | mengizinkan slave menarik salinan zona |
| tedd (slave) | `type slave` + `masters { 192.245.5.2; }` | menarik zona dari master |

Yang dibuktikan adalah bahwa mekanisme tersebut benar-benar bekerja: serial di tedd ikut naik menjadi `2026093002` setelah zona diubah pada soal 5, **tanpa disentuh secara manual**.

Apabila slave tertinggal, transfer dapat dipaksa dari tedd dengan:

```bash
rndc retransfer K68.com
```

### Pengujian

![Serial sama](screenshot/soal06-serial-sama.png)

```bash
dig @192.245.5.2 K68.com SOA +short
dig @192.245.5.3 K68.com SOA +short
```

Kedua server mengembalikan serial `2026093002`.

Log transfer tidak dapat dilampirkan karena container DebiNet tidak menjalankan syslog (`/var/log/syslog` tidak tersedia) maupun systemd (`journalctl` tidak tersedia). Hal ini normal untuk image tersebut. Kesamaan serial sudah merupakan bukti yang cukup, sebab nilai itu mustahil sama apabila transfer gagal.

---

## Soal 7 — Record vault, core, dan CNAME

> Tambahkan pada zona `K68.com` A record untuk `vault.K68.com` (IP obladi & desmond), dan `core.K68.com` (IP oblada & molly). Tetapkan CNAME `www.K68.com` → `penny.K68.com` dan `static.K68.com` → `abbey.K68.com`. Verifikasi dari dua klien berbeda bahwa seluruh hostname tersebut ter-resolve ke tujuan yang benar dan konsisten.

### Langkah Pengerjaan

**1. Menambahkan empat nama baru ke zona di prab.**
**2. Menaikkan serial ke `2026093003` dan menjalankan ulang `setup-dns.sh`.**
**3. Memastikan tedd ikut tersinkron.**
**4. Menguji dari dua klien berbeda** sesuai permintaan eksplisit soal.

### Script dan Konfigurasi

**prab** — tambahan pada `/etc/bind/jarkom/K68.com`:

```
vault   IN      A       192.245.5.4
vault   IN      A       192.245.5.5
core    IN      A       192.245.5.6
core    IN      A       192.245.5.7

www     IN      CNAME   penny.K68.com.
static  IN      CNAME   abbey.K68.com.
```

![Zona soal 7](screenshot/soal07-zona.png)

`vault` dan `core` masing-masing memiliki **dua A record** karena kedua area tersebut terdiri dari sepasang node, bukan satu. Satu nama dengan dua A record membuat DNS memutar urutan jawaban setiap kali ditanya, dan inilah dasar pembagian beban yang dipakai pada soal 11.

Kedua CNAME **wajib diakhiri titik**. Tanpa titik penutup, BIND memperlakukan nilainya sebagai nama relatif dan menambahkan nama zona sekali lagi, sehingga `penny.K68.com` menjadi `penny.K68.com.K68.com`.

### Pengujian

Dilakukan dari **alpha** (subnet 1) dan **delta** (subnet 2).

![Dig alpha](screenshot/soal07-dig-alpha.png)

![Dig delta](screenshot/soal07-dig-delta.png)

| Nama | Hasil |
|---|---|
| `vault.K68.com` | 192.245.5.4 dan 192.245.5.5 |
| `core.K68.com` | 192.245.5.6 dan 192.245.5.7 |
| `www.K68.com` | `penny.K68.com.` → 192.245.4.2 |
| `static.K68.com` | `abbey.K68.com.` → 192.245.3.2 |

Urutan kedua alamat pada `vault` berbeda antara alpha dan delta. Ini bukan ketidakkonsistenan melainkan **round-robin** DNS yang bekerja sebagaimana mestinya — himpunan jawabannya identik, hanya urutannya yang diputar.

---

## Soal 8 — Reverse Zone dan PTR

> Di prab (ns1) deklarasikan reverse zone untuk segmen jaringan tempat abbey, penny, area vault, dan area core berada. Di tedd (ns2) tarik reverse zone tersebut sebagai slave, isi PTR untuk keempat hostname itu agar pencarian balik IP address mengembalikan hostname yang benar, lalu pastikan query reverse untuk alamat abbey, penny, area vault, dan area core dijawab authoritative.

### Pertimbangan Sebelum Pengerjaan

Soal menyebut "segmen" dalam bentuk tunggal, sementara keempat entitas tersebar di tiga subnet berbeda: abbey di `192.245.3.0/24`, penny di `192.245.4.0/24`, serta area vault dan core di `192.245.5.0/24`.

Diputuskan membuat **tiga reverse zone**, satu untuk setiap /24. Dasarnya, modul DNS mengajarkan pola reverse berbasis tiga byte pertama alamat, dan tiga zona memastikan seluruh alamat yang diminta tercakup.

Alternatif berupa satu zona pada level `245.192.in-addr.arpa` — mencakup seluruh `/16` sekaligus — secara teknis sah dan lebih literal terhadap kata "segmen" tunggal, namun menyimpang dari pola yang diajarkan modul sehingga tidak dipilih.

Record PTR diarahkan ke **nama node**, bukan ke `vault.K68.com` atau `core.K68.com`. Glosarium mendefinisikan area vault sebagai kelompok node obladi dan desmond, sehingga "PTR untuk area vault" berarti PTR bagi kedua node tersebut. Ini juga sesuai konvensi DNS: PTR menunjuk ke nama kanonik sebuah host, bukan ke nama bersama yang memiliki banyak A record.

### Script dan Konfigurasi

**prab** — tambahan pada `/etc/bind/named.conf.local`:

```
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
```

![Config reverse prab](screenshot/soal08-config-prab.png)

**prab** — `/etc/bind/jarkom/3.245.192.in-addr.arpa`:

```
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
```

**prab** — `/etc/bind/jarkom/4.245.192.in-addr.arpa`:

```
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
```

**prab** — `/etc/bind/jarkom/5.245.192.in-addr.arpa`:

```
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
```

![Zona reverse](screenshot/soal08-zona-reverse.png)

prab dan tedd turut dimasukkan ke zona `.5` meski tidak diminta soal, agar zona tersebut lengkap untuk seluruh penghuni subnetnya.

**tedd** — tambahan pada `/etc/bind/named.conf.local`:

```
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
```

![Config reverse tedd](screenshot/soal08-config-tedd.png)

Script lengkap kedua node ada di [`config/prab/setup-dns.sh`](config/prab/setup-dns.sh) dan [`config/tedd/setup-dns.sh`](config/tedd/setup-dns.sh).

### Pengujian

![Dig reverse](screenshot/soal08-dig-reverse.png)

| Alamat | Hasil |
|---|---|
| 192.245.3.2 | `abbey.K68.com.` |
| 192.245.4.2 | `penny.K68.com.` |
| 192.245.5.4 | `obladi.K68.com.` |
| 192.245.5.5 | `desmond.K68.com.` |
| 192.245.5.6 | `oblada.K68.com.` |
| 192.245.5.7 | `molly.K68.com.` |

![Authoritative](screenshot/soal08-authoritative.png)

`dig @192.245.5.2 -x 192.245.5.4` dan `dig @192.245.5.3 -x 192.245.5.4` keduanya mengembalikan flag **`aa`**, membuktikan kueri reverse dijawab secara authoritative oleh master maupun slave.

---

## Soal 9 — Web Statis dan Autoindex

> Jalankan layanan web statis pada hostname di node area vault (menggunakan apache). Buka folder direktori `/arsip/` dan aktifkan fitur autoindex (directory listing) pada konfigurasi Apache sehingga seluruh daftar file di dalamnya dapat ditelusuri langsung dari browser. Akses pengujian harus dilakukan melalui hostname, bukan IP address.

> **Koreksi soal.** Naskah soal menyebut "aktifkan fitur autoindex pada konfigurasi Nginx". Asisten (rootkids) mengoreksi hal ini di Discord: *"sorry pake apache yaa, belom diganti hehe"*. Pengerjaan menggunakan **Apache**.

### Langkah Pengerjaan

**1. Menulis `/root/setup-web.sh` yang generik,** membaca hostname node sendiri sehingga perintah yang dijalankan di obladi dan desmond identik.

**2. Menjalankan script di kedua node area vault.**

**3. Menguji melalui hostname** menggunakan `curl` dan `lynx`, bukan melalui alamat IP.

### Script dan Konfigurasi

**obladi dan desmond** — `/root/setup-web.sh` — [`config/web/setup-web.sh`](config/web/setup-web.sh)

```bash
#!/bin/bash
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
```

Hasil akhir konfigurasi di kedua node:

![Config obladi](screenshot/soal09-config-obladi.png)

![Config desmond](screenshot/soal09-config-desmond.png)

Kunci soal ini terletak pada pemisahan dua blok `Directory`. Hanya `/arsip` yang menampilkan daftar isi; apabila `-Indexes` pada blok DocumentRoot terlewat, halaman utama pun ikut menampilkan daftar direktori dan itu tidak sesuai permintaan soal.

`ServerAlias vault.K68.com` ditambahkan agar kedua node juga menanggapi permintaan yang datang atas nama areanya, yang diperlukan untuk reverse proxy pada soal 11.

### Pengujian

Seluruh pengujian dilakukan **melalui hostname**, sesuai permintaan eksplisit soal.

![Curl hostname](screenshot/soal09-curl-hostname.png)

| Alamat | Hasil |
|---|---|
| `http://obladi.K68.com/` | halaman teks "Area Vault - obladi", bukan daftar direktori |
| `http://desmond.K68.com/` | halaman teks "Area Vault - desmond" |
| `http://obladi.K68.com/arsip/` | `Index of /arsip` berisi tiga berkas |
| `http://desmond.K68.com/arsip/` | `Index of /arsip` berisi tiga berkas |

Penelusuran dari browser menggunakan `lynx`:

![Lynx obladi](screenshot/soal09-lynx-arsip-obladi.png)

![Lynx desmond](screenshot/soal09-lynx-arsip-desmond.png)

Daftar berkas tampil sebagai tautan yang dapat dibuka, dan footer Apache menunjukkan server yang melayani adalah `obladi.k68.com` dan `desmond.k68.com` — bukan alamat IP.

---

