# Jarkom Modul 2 - K68 - Bagian Ryan (Soal 1-9)

Prefix IP: 192.245.x.x
Domain: K68.com

## Topologi (sesuai gambar docs soal 1)
7 switch, 5 di antaranya nyambung langsung ke rootkit.
Switch2 & Switch3 cascade di bawah Switch1 -> SATU subnet (layer 2).

rootkit --+-- Switch6 -- alpha, beta, gamma
          +-- Switch7 -- delta, epsilon
          +-- Switch4 -- abbey
          +-- Switch5 -- penny
          +-- Switch1 --+-- Switch2 -- prab, tedd
                        +-- Switch3 -- obladi, desmond, oblada, molly

## Rencana IP
| rootkit | Switch | Subnet | Isi |
|---|---|---|---|
| eth1 | Switch6 | 192.245.1.0/24 | alpha, beta, gamma |
| eth2 | Switch7 | 192.245.2.0/24 | delta, epsilon |
| eth3 | Switch4 | 192.245.3.0/24 | abbey |
| eth4 | Switch5 | 192.245.4.0/24 | penny |
| eth5 | Switch1+2+3 | 192.245.5.0/24 | prab, tedd, obladi, desmond, oblada, molly |

eth0 rootkit = DHCP dari NAT
### IP final
| Node | IP | Gateway |
|---|---|---|
| rootkit eth1 | 192.245.1.1 | - |
| rootkit eth2 | 192.245.2.1 | - |
| rootkit eth3 | 192.245.3.1 | - |
| rootkit eth4 | 192.245.4.1 | - |
| rootkit eth5 | 192.245.5.1 | - |
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

File interfaces siap tempel: config/soal1-interfaces/

## Progress

- [x] **Soal 1 - topologi + IP semua node**
  - 14 node debinet, 7 switch, 1 NAT. rootkit adapters dinaikkan jadi 8 (per-node, BUKAN template global karena remote controller dipakai bersama).
  - Config di /etc/network/interfaces tiap node. Backup: config/soal1-interfaces/
  - Uji lolos: alpha->gateway, alpha->beta, prab->obladi (bukti cascade SW1-2-3 benar)
  - SS: soal01-ip-dan-ping.png

- [x] **Soal 2 - WAN + NAT**
  - /root/nat.sh di rootkit: sysctl ip_forward=1 + iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  - eth0 dapat 192.168.122.69/24 dari NAT
  - Uji lolos: alpha ping 8.8.8.8 (ttl 110)
  - SS: soal02-nat-masquerade.png

- [x] **Soal 3 - routing + resolver awal**
  - Routing antar-subnet otomatis jalan begitu ip_forward=1
  - /root/dns.sh di 13 node non-router, dipanggil lewat "up bash /root/dns.sh" di interfaces
  - ALASAN pakai file terpisah: editor network config GNS3 membuang baris ber-karakter '>'
  - Uji lolos: alpha->molly & alpha->abbey (ttl 63), molly->alpha, cat /etc/resolv.conf
  - SS: soal03-routing-resolver.png

- [x] **Soal 4 - zona K68.com di prab, slave di tedd**
  - prab = master. /root/setup-dns.sh menulis named.conf.local + named.conf.options + zona, lalu restart bind9
  - ALASAN semua config lewat script di /root: /etc/bind HILANG tiap node restart, cuma /root dan /etc/network/interfaces yang persist
  - named.conf.local prab: type master, notify yes, also-notify 192.245.5.3, allow-transfer 192.245.5.3
  - named.conf.options: forwarders 192.168.122.1, dnssec-validation no, allow-query any
  - Zona serial awal 2026093001. SOA -> prab.K68.com. NS prab + tedd. A apex -> 192.245.4.2 (penny)
  - tedd = slave. masters 192.245.5.2. WAJIB chown bind:bind /etc/bind/jarkom supaya bind bisa menulis hasil transfer
  - resolver 13 node diubah jadi prab, tedd, 192.168.122.1
  - Uji lolos: dig @prab, @tedd, dan tanpa @ - semua flag "aa", apex -> 192.245.4.2
  - SS: soal04-config-prab.png, soal04-zona-prab.png, soal04-config-tedd.png, soal04-dig-prab-tedd.png, soal04-dig-via-resolver.png, soal04-dig-master-slave.txt

- [x] **Soal 5 - hostname + domain per node**
  - Hostname pendek sudah benar otomatis dari GNS3 (prompt sudah root@alpha dst), tidak perlu dikonfigurasi
  - MASALAH: hostname -f masih keluar nama pendek. Sebabnya /etc/hosts bawaan Docker cuma punya "IP<tab>namapendek", dan hostname -f baca /etc/hosts lebih dulu daripada DNS. Menambah "search" saja tidak menolong.
  - SOLUSI: dns.sh ditambah "search K68.com" di resolv.conf + penulisan ulang /etc/hosts jadi "IP nama.K68.com nama".
    Script dibuat generik (baca hostname -s dan hostname -I sendiri) jadi isinya identik di 13 node.
  - Zona prab ditambah 12 A record: rootkit, alpha, beta, gamma, delta, epsilon, abbey, penny, obladi, desmond, oblada, molly
  - prab & tedd DIKECUALIKAN dari penambahan A record karena sudah dibuat di soal 4 (kalau ditambah = duplikat)
  - Serial dinaikkan 2026093001 -> 2026093002
  - CATATAN: pengecualian prab/tedd hanya untuk A record di zona. Untuk dns.sh, prab & tedd TETAP ikut (13 node), karena soal 4 minta resolver diurut ulang di "seluruh Entitas non-router"
  - rootkit: hostname pendek sudah benar, /etc/hosts FQDN-nya di-SKIP (rootkit punya banyak IP). A record rootkit.K68.com tetap dibuat di zona prab.
  - Uji lolos: hostname -f keluar FQDN di delta/penny/beta/abbey; dig semua node cocok dengan tabel IP
  - SS: soal05-hostname.png, soal05-zona-lengkap.png, soal05-dig-node.png

  ### Troubleshooting yang terjadi saat soal 5
  - GEJALA: dig dari alpha -> "communications error to 192.245.5.2#53: connection refused" di prab DAN tedd
  - Diagnosa yang MENYESATKAN: named-checkzone di tedd memuntahkan ratusan "line 1 syntax error".
    Itu PALSU -- file zona di slave disimpan BIND dalam format RAW (biner), bukan teks, jadi named-checkzone memang tidak bisa membacanya. Jangan panik lihat error ini di slave.
  - Diagnosa yang BENAR: cek di master (prab). wc -l = 27 baris, named-checkzone = OK, serial terbaca.
    Berarti file zona sehat. Yang bermasalah: "service bind9 status" -> "bind is not running".
  - PENYEBAB: node sempat di-stop untuk mengedit interfaces. BIND tidak otomatis nyala saat node start.
  - PERBAIKAN: service bind9 start di prab dan tedd.
  - PELAJARAN: kalau DNS mati, urutan cek = (1) status service di MASTER, (2) named-checkzone di MASTER saja,
    (3) baru lihat slave. Jangan mulai dari slave.
  - CATATAN UNTUK SOAL 20: supaya BIND nyala sendiri setelah restart, /root/setup-dns.sh perlu dipanggil dari
    "up bash /root/setup-dns.sh" di /etc/network/interfaces prab & tedd (pola yang sama dengan dns.sh)

- [x] **Soal 6 - zone transfer, serial SOA sama**
  - Tidak ada konfigurasi baru. Mekanismenya sudah dipasang di soal 4:
    di prab -> notify yes + also-notify 192.245.5.3 + allow-transfer 192.245.5.3
    di tedd -> type slave + masters 192.245.5.2
  - Soal ini murni pembuktian bahwa mekanisme itu jalan
  - Uji lolos: dig @192.245.5.2 dan @192.245.5.3 K68.com SOA +short -> kedua serial = 2026093002
    (naik otomatis dari 2026093001 setelah zona diubah di soal 5, tanpa disentuh manual di tedd)
  - CATATAN: log transfer TIDAK BISA diambil. Container DebiNet tidak menjalankan syslog
    (/var/log/syslog tidak ada) maupun systemd (journalctl tidak ada). Ini normal, bukan error.
    Serial yang sama sudah bukti cukup -- mustahil sama kalau transfer gagal.
  - SS: soal06-serial-sama.png
- [x] **Soal 7 - A vault/core, CNAME www/static**
  - vault.K68.com -> DUA A record: 192.245.5.4 (obladi) + 192.245.5.5 (desmond)
  - core.K68.com  -> DUA A record: 192.245.5.6 (oblada) + 192.245.5.7 (molly)
  - ALASAN dua A record: "area vault" itu sepasang node, bukan satu. Satu nama dengan dua A record
    bikin DNS membagi jawaban bergantian (round-robin) -- ini yang dipakai orang B untuk load balancing di soal 11.
  - www.K68.com    -> CNAME penny.K68.com.
  - static.K68.com -> CNAME abbey.K68.com.
  - PENTING: CNAME wajib diakhiri TITIK. Tanpa titik, BIND menambahkan nama zona lagi
    sehingga jadi penny.K68.com.K68.com
  - Serial dinaikkan 2026093002 -> 2026093003, tedd ikut tersinkron otomatis
  - Uji lolos dari DUA klien (soal minta eksplisit): alpha dan delta, hasil isinya sama.
    Urutan dua IP vault BERBEDA antara alpha dan delta -- itu bukan error, itu round-robin bekerja.
  - SS: soal07-zona.png, soal07-dig-alpha.png, soal07-dig-delta.png
- [x] **Soal 8 - reverse zone + PTR**
  - MASALAH TAFSIR: soal menulis "segmen" (tunggal), padahal abbey/penny/vault/core tersebar di 3 subnet:
    abbey 192.245.3.2 | penny 192.245.4.2 | vault+core 192.245.5.4-.7
  - KEPUTUSAN: buat TIGA reverse zone, satu per /24.
    ALASAN: modul DNS mengajarkan pola reverse per-3-byte (contoh modul: 1.91.10.in-addr.arpa untuk 10.91.1.x).
    Tiga zona mengikuti pola itu dan pasti mencakup semuanya.
    Alternatif yang TIDAK dipakai: satu zona di level 245.192.in-addr.arpa (mencakup seluruh /16 sekaligus) --
    secara teknis sah dan lebih literal terhadap kata "segmen" tunggal, tapi menyimpang dari pola modul.
  - Zona yang dibuat di prab (semuanya type master, notify + allow-transfer ke tedd):
    3.245.192.in-addr.arpa -> 2 PTR abbey.K68.com.
    4.245.192.in-addr.arpa -> 2 PTR penny.K68.com.
    5.245.192.in-addr.arpa -> 2 prab, 3 tedd, 4 obladi, 5 desmond, 6 oblada, 7 molly
  - prab & tedd ikut dimasukkan ke zona .5 walau tidak diminta soal -- gratis dan bikin zona lengkap
  - PTR menunjuk ke NAMA NODE (obladi.K68.com.), BUKAN ke vault.K68.com.
    ALASAN: glosarium mendefinisikan "area vault" = kelompok node obladi + desmond,
    jadi "PTR untuk area vault" artinya PTR untuk kedua node itu. Ini juga konvensi DNS yang benar --
    PTR menunjuk ke nama kanonik, bukan ke nama yang punya banyak A record.
  - tedd: 3 zona reverse ditambahkan sebagai type slave dengan masters 192.245.5.2
  - Uji lolos: 6x dig -x dari alpha semua benar; dig @prab dan @tedd -x 192.245.5.4 dua-duanya berflag "aa"
  - SS: soal08-config-prab.png, soal08-zona-reverse.png, soal08-config-tedd.png, soal08-dig-reverse.png, soal08-authoritative.png
- [x] **Soal 9 - Apache statis + autoindex /arsip**
  - KOREKSI SOAL: soal tertulis "aktifkan autoindex pada konfigurasi Nginx", itu salah ketik.
    Asisten (rootkids) koreksi di Discord: "sorry pake apache yaa, belom diganti hehe" -> pakai APACHE.
  - Area vault = obladi (192.245.5.4) + desmond (192.245.5.5), dua-duanya dikonfigurasi
  - /root/setup-web.sh: install apache2, buat /var/www/$NAME + /var/www/$NAME/arsip berisi 3 file txt,
    tulis virtual host, a2dissite 000-default, a2ensite, restart
  - Script GENERIK (baca hostname -s sendiri) jadi perintah yang ditempel di obladi dan desmond identik
  - Virtual host: ServerName <node>.K68.com, ServerAlias vault.K68.com, DocumentRoot /var/www/<node>
  - KUNCI SOAL: Options -Indexes di blok DocumentRoot, Options +Indexes HANYA di blok /arsip
    Kalau -Indexes lupa, halaman utama ikut menampilkan daftar direktori dan itu salah.
  - ServerAlias vault.K68.com ditambahkan supaya akses lewat nama area juga kena (dipakai orang B di soal 11)
  - Uji WAJIB lewat hostname, bukan IP (soal menyebut ini eksplisit)
  - Uji lolos: curl ke obladi.K68.com dan desmond.K68.com -> halaman teks (bukan listing);
    curl ke /arsip/ -> "Index of /arsip" berisi 3 file; lynx menampilkan daftar yang bisa diklik di kedua node
  - SS: soal09-config-obladi.png, soal09-config-desmond.png, soal09-curl-hostname.png,
        soal09-lynx-arsip-obladi.png, soal09-lynx-arsip-desmond.png

---

## STATUS: SOAL 1-9 (BAGIAN RYAN) SELESAI SEMUA

### Yang perlu diserahkan ke orang B (Made Gde Krisna Wangsa)
- Script yang sudah ada di tiap node, semua di /root:
  - rootkit: nat.sh, hostname.sh
  - 13 node non-router: dns.sh
  - prab & tedd: setup-dns.sh
  - obladi & desmond: setup-web.sh
- Nama DNS yang sudah siap dipakai: vault.K68.com (2 A record), core.K68.com (2 A record),
  www.K68.com -> penny, static.K68.com -> abbey
- Untuk soal 17-19 (TXT record, ubah A abbey, CNAME outbound): edit /root/setup-dns.sh di prab,
  naikkan serial, jalankan ulang scriptnya. JANGAN edit /etc/bind langsung -- hilang saat restart.
- Untuk soal 20 (autostart): pola yang sudah dipakai = panggil script dari "up bash /root/<script>.sh"
  di /etc/network/interfaces (node harus mati saat mengedit).
  Yang BELUM dipasang autostart-nya: setup-dns.sh (prab, tedd) dan setup-web.sh (obladi, desmond).
  Ini sengaja ditinggal karena soal 20 bagian orang B.

### Sisa pekerjaan Ryan
- [ ] Salin config dari tiap node ke folder config/ sebagai backup
- [ ] Susun README repo GitHub Jarkom-Modul-2-2026-K-68
- [ ] Atur jadwal demo dengan asisten (paling lambat Kamis 1 Oktober 2026)

## Catatan penting
- Soal 9: soal tertulis "Nginx" tapi asisten koreksi di Discord -> pakai APACHE
- Soal 8: abbey (subnet .3), penny (subnet .4), vault+core (subnet .5) = 3 subnet berbeda, padahal soal bilang "segmen" tunggal -> tentukan strategi reverse zone
- GOTCHA: editor "Edit network configuration" GNS3 membuang baris yang mengandung '>'
- GOTCHA: hanya /root dan /etc/network/interfaces yang bertahan saat node restart. Semua config lain harus ditulis ulang oleh script di /root.
- Pembagian: Ryan soal 1-9, Made Gde Krisna Wangsa soal 10-20
- Repo laporan: Jarkom-Modul-2-2026-K-68
