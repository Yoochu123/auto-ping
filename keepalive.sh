#!/bin/sh

LOG_TAG="KeepAlive"
CONFIG_FILE="keepalive"

log() {
    logger -t "$LOG_TAG" "$1"
}

uci_get_value() {
    uci get "$CONFIG_FILE.$1" 2>/dev/null
}

log "Layanan Keep-Alive dimulai."

while true; do
    ENABLED=$(uci_get_value 'settings.enabled')
    
    if [ "$ENABLED" = "1" ]; then
        TARGET=$(uci_get_value 'settings.target')
        INTERVAL=$(uci_get_value 'settings.interval')
        
        # Gunakan interval minimal 5 detik untuk keamanan
        if [ "$INTERVAL" -lt 5 ]; then
            INTERVAL=5
        fi

        log "Melakukan ping ke target: $TARGET"
        # Lakukan ping dengan 1 paket saja
        /bin/ping -c 1 -W 5 "$TARGET" > /dev/null 2>&1
        
        # Tidur sesuai interval
        sleep "$INTERVAL"
    else
        # Jika nonaktif, cek setiap 5 menit
        log "Layanan dinonaktifkan. Tidur selama 300 detik."
        sleep 300
    fi
done