Keep-Alive Ping

Alat ini berguna untuk menjaga sesi login Anda tetap aktif dengan mengirimkan ping secara berkala. Ini mencegah portal me-logout Anda karena tidak ada aktivitas. Alat ini memiliki antarmuka web yang mudah digunakan.

### Tampilan
![Keep-Alive Manager UI](https://i.imgur.com/your-screenshot-url.png)
*(**Catatan**: Ganti link di atas dengan URL screenshot antarmuka web Keep-Alive Anda sendiri.)*

### Instalasi

Jalankan perintah ini di terminal SSH router OpenWrt Anda:
```sh
wget -O Installer.sh https://raw.githubusercontent.com/Yoochu123/auto-ping/main/install_keepalive.sh
```
```
sh Installer.sh
```

### Konfigurasi

Setelah instalasi, buka browser Anda dan navigasi ke antarmuka web LuCI. Menu baru akan muncul di:
**Services > Keep-Alive Ping**

Dari sana, Anda bisa mengaktifkan/menonaktifkan layanan, mengatur IP atau URL tujuan, dan menentukan interval ping.

### Uninstall

Untuk menghapus layanan dan antarmuka web Keep-Alive:
```sh
wget -O - [https://raw.githubusercontent.com/Yoochu123/autologin-openwrt/main/uninstall_keepalive.sh](https://raw.githubusercontent.com/Yoochu123/autologin-openwrt/main/uninstall_keepalive.sh) | sh
```

---
