# Jarkom Modul 2 Shadow Net Operation

**Kelompok K-68 (Group C) Praktikum Komunikasi Data dan Jaringan Komputer 2026**

| | |
|---|---|
| Domain | `K68.com` |
| Prefix IP | `192.245.0.0/16` |
| Image | `ardhptr21/debinet:latest` |
| Controller | GNS3 remote, Group C |

## Anggota dan Pembagian

| Nama | NRP | Soal |
|---|---|---|
| Ryan Adya Purwanto | 5027231046 | 1 – 9 |
| Made Gde Krisna Wangsa | — | 10 – 20 |

Laporan ini mencakup **soal 1 sampai 9**.

---

## Daftar Isi

- [Topologi](#topologi)
- [Pembagian IP](#pembagian-ip)
- [Catatan Teknis Penting](#catatan-teknis-penting)
- [Soal 1 — Topologi dan Pengalamatan IP](#soal-1--topologi-dan-pengalamatan-ip)
- [Soal 2 — WAN dan NAT](#soal-2--wan-dan-nat)
- [Soal 3 — Routing Internal dan Resolver Awal](#soal-3--routing-internal-dan-resolver-awal)
- [Soal 4 — Zona DNS Master dan Slave](#soal-4--zona-dns-master-dan-slave)
- [Soal 5 — Hostname dan Domain per Node](#soal-5--hostname-dan-domain-per-node)
- [Soal 6 — Verifikasi Zone Transfer](#soal-6--verifikasi-zone-transfer)
- [Soal 7 — Record vault, core, dan CNAME](#soal-7--record-vault-core-dan-cname)
- [Soal 8 — Reverse Zone dan PTR](#soal-8--reverse-zone-dan-ptr)
- [Soal 9 — Web Statis dan Autoindex](#soal-9--web-statis-dan-autoindex)
- [Struktur Repository](#struktur-repository)

---

## Topologi

![Topologi](screenshot/00-topologi-awal.png)

Tujuh switch, lima di antaranya tersambung langsung ke router `rootkit`:

```
rootkit --+-- eth1 -- Switch6 -- alpha, beta, gamma
          +-- eth2 -- Switch7 -- delta, epsilon
          +-- eth3 -- Switch4 -- abbey
          +-- eth4 -- Switch5 -- penny
          +-- eth5 -- Switch1 --+-- Switch2 -- prab, tedd
                                +-- Switch3 -- obladi, desmond, oblada, molly
eth0 -- NAT1 (DHCP)
```

Switch2 dan Switch3 tidak tersambung ke rootkit melainkan ke Switch1. Karena switch bekerja di layer 2 dan tidak memisahkan jaringan, ketiganya membentuk **satu broadcast domain**, sehingga prab, tedd, obladi, desmond, oblada, dan molly berada dalam **satu subnet** dan dilayani oleh satu interface router saja (`eth5`).

## Pembagian IP

| Interface rootkit | Switch | Subnet | Node |
|---|---|---|---|
| eth1 | Switch6 | 192.245.1.0/24 | alpha, beta, gamma |
| eth2 | Switch7 | 192.245.2.0/24 | delta, epsilon |
| eth3 | Switch4 | 192.245.3.0/24 | abbey |
| eth4 | Switch5 | 192.245.4.0/24 | penny |
| eth5 | Switch1+2+3 | 192.245.5.0/24 | prab, tedd, obladi, desmond, oblada, molly |

| Node | IP | Gateway |
|---|---|---|
| rootkit eth1 | 192.245.1.1 | — |
| rootkit eth2 | 192.245.2.1 | — |
| rootkit eth3 | 192.245.3.1 | — |
| rootkit eth4 | 192.245.4.1 | — |
| rootkit eth5 | 192.245.5.1 | — |
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

`eth0` rootkit memakai DHCP dari NAT dan memperoleh `192.168.122.69/24`.

---

## Catatan Teknis Penting

Tiga kendala lingkungan yang menentukan cara seluruh konfigurasi ditulis.

**1. Hanya `/root` dan `/etc/network/interfaces` yang bertahan saat node restart.**
Node Docker kembali ke kondisi image setiap kali dinyalakan ulang. Akibatnya `/etc/bind`, `/etc/apache2`, dan `/etc/resolv.conf` akan hilang. Karena itu seluruh konfigurasi tidak diketik langsung ke lokasi aslinya, melainkan ditulis oleh **script yang disimpan di `/root`**, lalu script itu dipanggil dari `/etc/network/interfaces` melalui baris `up`. Pendekatan ini sekaligus memenuhi aturan praktikum yang mewajibkan script instalasi dan konfigurasi diletakkan di `/root`.

**2. Editor "Edit network configuration" GNS3 membuang baris yang mengandung karakter `>`.**
Karena itu perintah pengalihan output tidak boleh ditulis langsung di `interfaces`. Solusinya, perintah tersebut disembunyikan di dalam file script (`dns.sh`, `nat.sh`), dan `interfaces` hanya memanggilnya dengan `up bash /root/dns.sh`.

**3. Jumlah adapter dinaikkan per node, bukan lewat template global.**
`rootkit` memerlukan enam interface (`eth0`–`eth5`), sementara template default hanya menyediakan lebih sedikit. Karena praktikum berjalan di **remote controller yang dipakai bersama seluruh kelompok**, mengubah template global akan berdampak ke kelompok lain. Perubahan dilakukan lewat klik kanan node → Configure → Network → Adapters = 8, hanya pada `rootkit`.

---

## Soal 1 — Topologi dan Pengalamatan IP

> Tetapkan alamat IP dan default gateway untuk seluruh Entitas sesuai dengan topologi pembagian switch yang dirancang.

### Pengerjaan

Empat belas node DebiNet, tujuh Ethernet switch, dan satu node NAT disusun sesuai gambar topologi. Adapter `rootkit` dinaikkan menjadi 8 agar `eth0`–`eth5` tersedia.

Urutan penyambungan kabel di sisi `rootkit` dijaga berurutan dari `eth0`, karena nama interface di dalam node ditentukan oleh nomor slot adapter di GNS3. Kabel yang tertukar menghasilkan konfigurasi yang benar secara sintaks tetapi terpasang di jaringan yang salah.

Konfigurasi ditulis melalui klik kanan node → **Edit network configuration** (node dalam keadaan mati), yang mengedit `/etc/network/interfaces`.

**rootkit** — [`config/rootkit/interfaces`](config/rootkit/interfaces)

```
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
	address 192.245.1.1
	netmask 255.255.255.0

... eth2 sampai eth5 dengan pola yang sama
```

Interface `eth1`–`eth5` sengaja **tidak diberi baris `gateway`**. Default gateway hanya boleh ada satu per host, dan bagi router jalur keluarnya adalah `eth0` yang sudah memperolehnya otomatis dari DHCP NAT. Menambahkan gateway di interface LAN akan membuat router mengarahkan trafik keluar ke jaringan internalnya sendiri.

**Node lain** — [`config/interfaces/`](config/interfaces/)

```
auto eth0
iface eth0 inet static
	address 192.245.1.2
	netmask 255.255.255.0
	gateway 192.245.1.1
```

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

> Pastikan antarmuka WAN di router rootkit aktif. Konfigurasikan NAT agar dapat meneruskan lalu lintas keluar bagi seluruh alamat internal.

### Pengerjaan

Node internal memakai alamat `192.245.x.x` yang tidak dikenal internet. Router harus menyamarkan alamat asal paket dengan alamat `eth0` miliknya sendiri — inilah yang dilakukan target `MASQUERADE`.

**rootkit** — [`config/rootkit/nat.sh`](config/rootkit/nat.sh)

```bash
#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

`ip_forward` mengizinkan kernel meneruskan paket antar interface. Tanpa ini node hanya bisa berbicara dengan tetangga sesubnet.

`MASQUERADE` dipilih daripada `SNAT` karena alamat `eth0` diperoleh lewat DHCP dan bisa berubah. `MASQUERADE` membaca alamat interface secara dinamis, sedangkan `SNAT` memerlukan alamat yang ditulis tetap.

### Pengujian

![Soal 2](screenshot/soal02-nat-masquerade.png)

| Uji | Hasil |
|---|---|
| `iptables -t nat -L POSTROUTING -n -v` | aturan `MASQUERADE ... out:eth0` terpasang |
| `ip a show eth0` | 192.168.122.69/24 diterima dari NAT |
| alpha → 8.8.8.8 | berhasil, ttl 110 |

---

## Soal 3 — Routing Internal dan Resolver Awal

> Pastikan seluruh Entitas dapat saling terhubung dan berkomunikasi lintas jalur. Pastikan setiap host non-router menambahkan resolver 192.168.122.1 **saat antarmukanya aktif**.

### Pengerjaan

Routing antar subnet tidak memerlukan konfigurasi tambahan: begitu `ip_forward=1` aktif di rootkit dan setiap node memiliki default gateway yang benar, router sudah mengenal kelima subnet secara langsung melalui interface-nya masing-masing.

Frasa **"saat antarmukanya aktif"** dalam soal menentukan cara pengerjaannya. `/etc/resolv.conf` termasuk file yang hilang setiap node restart, sehingga resolver tidak boleh diketik manual melainkan harus dipasang ulang otomatis setiap interface naik.

**13 node non-router** — [`config/dns.sh`](config/dns.sh)

```bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

dipanggil dari `/etc/network/interfaces`:

```
	up bash /root/dns.sh
```

Perintah pengalihan `>` sengaja ditempatkan di dalam file script, bukan langsung sebagai baris `up`, karena editor GNS3 akan membuang baris yang memuat karakter tersebut.

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

> Pada node prab, bangun zona `K68.com` sebagai authoritative dengan SOA yang menunjuk ke `prab.K68.com`, tambahkan NS untuk prab dan tedd, A record untuk keduanya, serta A record apex yang mengarah ke penny. Aktifkan notify dan allow-transfer ke tedd, set forwarders ke 192.168.122.1. Di tedd, tarik zona sebagai slave.

### Pengerjaan

Seluruh konfigurasi BIND ditulis melalui script di `/root`, bukan diketik ke `/etc/bind`, karena direktori tersebut hilang setiap node restart.

**prab (ns1, master)** — [`config/prab/setup-dns.sh`](config/prab/setup-dns.sh)

![Config prab](screenshot/soal04-config-prab.png)

`notify yes` membuat master mengabari slave setiap zona berubah, `also-notify` menyebut alamat slave secara eksplisit, dan `allow-transfer` memberi izin slave menarik salinan zona. Ketiganya harus ada — tanpa `allow-transfer`, notify tetap terkirim tetapi transfer akan ditolak.

`forwarders` mengarahkan pertanyaan di luar zona `K68.com` ke DNS milik NAT, sehingga node tetap dapat membuka alamat internet meski resolver-nya sudah diarahkan ke prab.

![Zona prab](screenshot/soal04-zona-prab.png)

**tedd (ns2, slave)** — [`config/tedd/setup-dns.sh`](config/tedd/setup-dns.sh)

![Config tedd](screenshot/soal04-config-tedd.png)

Baris `chown -R bind:bind /etc/bind/jarkom` bersifat wajib pada slave. File hasil zone transfer ditulis oleh proses `named` yang berjalan sebagai user `bind`; tanpa kepemilikan yang benar, transfer akan gagal dan zona tidak pernah termuat.

Setelah zona berdiri, resolver di seluruh node non-router diurutkan ulang menjadi prab, tedd, lalu 192.168.122.1.

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

> Namai semua Entitas sesuai glosarium dan verifikasi bahwa setiap host mengenali hostname tersebut secara system-wide. Buat domain untuk masing-masing node beserta IP-nya. Lakukan pengecualian untuk prab dan tedd.

### Pengerjaan

Hostname pendek setiap node sudah benar sejak awal karena GNS3 menetapkannya dari nama node, terbukti dari prompt `root@alpha:~#`.

Yang belum terpenuhi adalah pengenalan **system-wide**: `hostname -f` masih mengembalikan nama pendek. Penyebabnya, `/etc/hosts` bawaan container hanya memuat pasangan alamat dan nama pendek, dan `hostname -f` membaca `/etc/hosts` lebih dahulu daripada DNS. Menambahkan `search` saja tidak menolong karena berkas lokal selalu diperiksa lebih dulu.

Penyelesaiannya menambahkan penulisan `/etc/hosts` ke dalam `dns.sh` yang sudah terpasang — [`config/dns.sh`](config/dns.sh):

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

Selanjutnya dua belas A record ditambahkan ke zona. **prab dan tedd dikecualikan** karena keduanya sudah memiliki A record sejak soal 4; menambahkannya lagi akan menghasilkan duplikat. Serial dinaikkan dari `2026093001` menjadi `2026093002`.

![Zona lengkap](screenshot/soal05-zona-lengkap.png)

Perlu dibedakan: pengecualian ini hanya berlaku untuk A record di zona. Untuk `dns.sh`, prab dan tedd **tetap ikut** karena soal 4 meminta resolver diurutkan ulang pada seluruh Entitas non-router.

### Pengujian

![Hostname](screenshot/soal05-hostname.png)

![Dig node](screenshot/soal05-dig-node.png)

| Uji | Hasil |
|---|---|
| `hostname -f` di delta, penny, beta, abbey | mengembalikan FQDN lengkap |
| `dig <node>.K68.com +short` | seluruh node sesuai tabel alamat |

### Kendala yang ditemui

Setelah konfigurasi diperbarui, seluruh kueri DNS gagal dengan `connection refused` dari prab maupun tedd.

Pemeriksaan pertama di tedd menghasilkan ratusan baris `line 1: syntax error` dari `named-checkzone`. **Diagnosa ini menyesatkan.** File zona pada server slave disimpan BIND dalam format raw (biner), bukan teks, sehingga `named-checkzone` memang tidak dapat membacanya. Error tersebut normal dan bukan penyebab masalah.

Pemeriksaan ulang dilakukan di master. File zona terbukti sehat — 27 baris, `named-checkzone` mengembalikan `OK`, serial terbaca `2026093002`. Yang bermasalah adalah `service bind9 status` yang melaporkan `bind is not running`. Node sempat dimatikan untuk mengedit `interfaces`, dan BIND tidak menyala otomatis saat node dihidupkan kembali. Perbaikannya menjalankan `service bind9 start` di prab dan tedd.

Urutan diagnosa yang benar untuk kasus DNS mati: periksa status service di **master** lebih dahulu, jalankan `named-checkzone` hanya di master, baru periksa slave.

---

## Soal 6 — Verifikasi Zone Transfer

> Pastikan zone transfer berjalan dan tedd telah menerima salinan zona terbaru dari prab. Nilai serial SOA di keduanya harus sama.

### Pengerjaan

Soal ini tidak memerlukan konfigurasi baru. Seluruh mekanismenya sudah dipasang pada soal 4: `notify yes`, `also-notify`, dan `allow-transfer` di sisi master, serta `type slave` dan `masters` di sisi slave.

Yang dibuktikan adalah bahwa mekanisme tersebut benar-benar bekerja: serial di tedd ikut naik menjadi `2026093002` setelah zona diubah pada soal 5, **tanpa disentuh secara manual**.

### Pengujian

![Serial sama](screenshot/soal06-serial-sama.png)

```
dig @192.245.5.2 K68.com SOA +short
dig @192.245.5.3 K68.com SOA +short
```

Kedua server mengembalikan serial `2026093002`.

Log transfer tidak dapat dilampirkan karena container DebiNet tidak menjalankan syslog (`/var/log/syslog` tidak tersedia) maupun systemd (`journalctl` tidak tersedia). Hal ini normal untuk image tersebut. Kesamaan serial sudah merupakan bukti yang cukup, sebab nilai itu mustahil sama apabila transfer gagal.

---

## Soal 7 — Record vault, core, dan CNAME

> Tambahkan A record untuk `vault.K68.com` (IP obladi dan desmond) dan `core.K68.com` (IP oblada dan molly). Tetapkan CNAME `www` ke penny dan `static` ke abbey. Verifikasi dari dua klien berbeda.

### Pengerjaan

![Zona soal 7](screenshot/soal07-zona.png)

```
vault   IN      A       192.245.5.4
vault   IN      A       192.245.5.5
core    IN      A       192.245.5.6
core    IN      A       192.245.5.7

www     IN      CNAME   penny.K68.com.
static  IN      CNAME   abbey.K68.com.
```

`vault` dan `core` masing-masing memiliki **dua A record** karena kedua area tersebut terdiri dari sepasang node, bukan satu. Satu nama dengan dua A record membuat DNS memutar urutan jawaban setiap kali ditanya, dan inilah dasar pembagian beban yang dipakai pada soal 11.

Kedua CNAME **wajib diakhiri titik**. Tanpa titik penutup, BIND memperlakukan nilainya sebagai nama relatif dan menambahkan nama zona sekali lagi, sehingga `penny.K68.com` menjadi `penny.K68.com.K68.com`.

Serial dinaikkan menjadi `2026093003`.

### Pengujian

Soal meminta verifikasi dari dua klien berbeda, dilakukan dari **alpha** (subnet 1) dan **delta** (subnet 2).

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

> Deklarasikan reverse zone untuk segmen jaringan tempat abbey, penny, area vault, dan area core berada. Tarik sebagai slave di tedd, isi PTR untuk keempat hostname itu, dan pastikan query reverse dijawab authoritative.

### Pertimbangan

Soal menyebut "segmen" dalam bentuk tunggal, sementara keempat entitas tersebar di tiga subnet berbeda: abbey di `192.245.3.0/24`, penny di `192.245.4.0/24`, serta area vault dan core di `192.245.5.0/24`.

Diputuskan membuat **tiga reverse zone**, satu untuk setiap /24. Dasarnya, modul DNS mengajarkan pola reverse berbasis tiga byte pertama alamat, dan tiga zona memastikan seluruh alamat yang diminta tercakup.

Alternatif berupa satu zona pada level `245.192.in-addr.arpa` — mencakup seluruh `/16` sekaligus — secara teknis sah dan lebih literal terhadap kata "segmen" tunggal, namun menyimpang dari pola yang diajarkan modul sehingga tidak dipilih.

Record PTR diarahkan ke **nama node**, bukan ke `vault.K68.com` atau `core.K68.com`. Glosarium mendefinisikan area vault sebagai kelompok node obladi dan desmond, sehingga "PTR untuk area vault" berarti PTR bagi kedua node tersebut. Ini juga sesuai konvensi DNS: PTR menunjuk ke nama kanonik sebuah host, bukan ke nama bersama yang memiliki banyak A record.

### Pengerjaan

**prab** — [`config/prab/setup-dns.sh`](config/prab/setup-dns.sh)

![Config reverse prab](screenshot/soal08-config-prab.png)

![Zona reverse](screenshot/soal08-zona-reverse.png)

| Zona | Isi |
|---|---|
| `3.245.192.in-addr.arpa` | `2 → abbey.K68.com.` |
| `4.245.192.in-addr.arpa` | `2 → penny.K68.com.` |
| `5.245.192.in-addr.arpa` | `2 → prab`, `3 → tedd`, `4 → obladi`, `5 → desmond`, `6 → oblada`, `7 → molly` |

prab dan tedd turut dimasukkan ke zona `.5` meski tidak diminta soal, agar zona tersebut lengkap untuk seluruh penghuni subnetnya.

**tedd** — [`config/tedd/setup-dns.sh`](config/tedd/setup-dns.sh)

![Config reverse tedd](screenshot/soal08-config-tedd.png)

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

> Jalankan layanan web statis pada hostname di node area vault menggunakan Apache. Buka folder `/arsip/` dan aktifkan autoindex sehingga daftar file dapat ditelusuri dari browser. Akses pengujian harus melalui hostname, bukan IP address.

> **Koreksi soal.** Naskah soal menyebut "aktifkan fitur autoindex pada konfigurasi Nginx". Asisten (rootkids) mengoreksi hal ini di Discord: *"sorry pake apache yaa, belom diganti hehe"*. Pengerjaan menggunakan **Apache**.

### Pengerjaan

Area vault terdiri dari obladi dan desmond, dan keduanya dikonfigurasi.

**obladi dan desmond** — [`config/web/setup-web.sh`](config/web/setup-web.sh)

![Config obladi](screenshot/soal09-config-obladi.png)

![Config desmond](screenshot/soal09-config-desmond.png)

Script dibuat generik dengan membaca hostname node sendiri, sehingga perintah yang dijalankan di kedua node identik dan menghasilkan `ServerName` yang berbeda secara otomatis.

Kunci soal ini terletak pada pemisahan dua blok `Directory`:

```apache
<Directory /var/www/obladi>
    Options -Indexes
</Directory>

<Directory /var/www/obladi/arsip>
    Options +Indexes
</Directory>
```

Hanya `/arsip` yang menampilkan daftar isi. Apabila `-Indexes` pada blok DocumentRoot terlewat, halaman utama pun ikut menampilkan daftar direktori, dan itu tidak sesuai permintaan soal.

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

## Struktur Repository

```
.
├── README.md
├── config/
│   ├── dns.sh                    # resolver + /etc/hosts, identik di 13 node non-router
│   ├── interfaces/               # /etc/network/interfaces seluruh node
│   ├── rootkit/
│   │   ├── interfaces
│   │   ├── nat.sh                # ip_forward + MASQUERADE
│   │   └── hostname.sh           # FQDN rootkit di /etc/hosts
│   ├── prab/setup-dns.sh         # BIND master: zona forward + 3 reverse
│   ├── tedd/setup-dns.sh         # BIND slave
│   └── web/setup-web.sh          # Apache, identik di obladi dan desmond
└── screenshot/                   # bukti pengerjaan soal 1-9
```

### Letak script di dalam node

| Script | Node | Path | Dipanggil dari |
|---|---|---|---|
| `nat.sh` | rootkit | `/root/nat.sh` | `up` di `interfaces` |
| `hostname.sh` | rootkit | `/root/hostname.sh` | `up` di `interfaces` |
| `dns.sh` | 13 node non-router | `/root/dns.sh` | `up` di `interfaces` |
| `setup-dns.sh` | prab, tedd | `/root/setup-dns.sh` | manual |
| `setup-web.sh` | obladi, desmond | `/root/setup-web.sh` | manual |

`setup-dns.sh` dan `setup-web.sh` belum dipasang pemanggilan otomatisnya karena persistensi service setelah restart merupakan lingkup soal 20.
