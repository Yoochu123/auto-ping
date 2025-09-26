#!/bin/sh

# --- FUNGSI ---
log() {
    echo "=> $1"
}

# --- PROSES UNINSTALL ---
log "Memulai proses uninstall Keep-Alive Ping Manager..."

# 1. Hentikan dan nonaktifkan layanan
if [ -f /etc/init.d/keepalive ]; then
    log "Menghentikan dan menonaktifkan layanan..."
    /etc/init.d/keepalive stop > /dev/null 2>&1
    /etc/init.d/keepalive disable > /dev/null 2>&1
fi

# 2. Hapus file-file
log "Menghapus file skrip..."
rm -f /usr/bin/keepalive.sh
rm -f /etc/init.d/keepalive
rm -f /usr/lib/lua/luci/controller/keepalive.lua
rm -rf /usr/lib/lua/luci/view/keepalive

# 3. Hapus konfigurasi UCI
log "Menghapus konfigurasi..."
rm -f /etc/config/keepalive

# 4. Bersihkan cache LuCI
log "Membersihkan cache LuCI..."
rm -f /tmp/luci-indexcache

log "-----------------------------------------------------"
log "Uninstall Selesai!"
log "Semua file dan konfigurasi Keep-Alive Ping Manager telah dihapus."
log "-----------------------------------------------------"