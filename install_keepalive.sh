#!/bin/sh

# --- FUNGSI ---
log() {
    echo "=> $1"
}

# --- PROSES INSTALASI ---
log "Memulai instalasi Keep-Alive Ping Manager..."

# 1. Buat konfigurasi awal di UCI
log "Membuat file konfigurasi awal..."
uci set keepalive.settings='settings'
uci set keepalive.settings.enabled='0'
uci set keepalive.settings.target='8.8.8.8'
uci set keepalive.settings.interval='180'
uci commit keepalive

# 2. Buat skrip logika utama
log "Membuat skrip logika (/usr/bin/keepalive.sh)..."
cat <<'EOF' > /usr/bin/keepalive.sh
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
        
        if [ "$INTERVAL" -lt 5 ]; then
            INTERVAL=5
        fi

        log "Melakukan ping ke target: $TARGET"
        /bin/ping -c 1 -W 5 "$TARGET" > /dev/null 2>&1
        
        sleep "$INTERVAL"
    else
        log "Layanan dinonaktifkan. Tidur selama 300 detik."
        sleep 300
    fi
done
EOF
chmod +x /usr/bin/keepalive.sh

# 3. Buat skrip layanan init.d
log "Membuat skrip layanan (/etc/init.d/keepalive)..."
cat <<'EOF' > /etc/init.d/keepalive
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1
    
start_service() {
    procd_open_instance
    procd_set_param command /bin/sh "/usr/bin/keepalive.sh"
    procd_set_param respawn
    procd_close_instance
}
EOF
chmod +x /etc/init.d/keepalive

# 4. Buat file controller LuCI
log "Membuat file controller LuCI..."
mkdir -p /usr/lib/lua/luci/controller/
cat <<'EOF' > /usr/lib/lua/luci/controller/keepalive.lua
module("luci.controller.keepalive", package.seeall)

function index()
    entry({"admin", "services", "keepalive"}, 
          template("keepalive/manager"), 
          "Keep-Alive Ping", 
          20)
end
EOF

# 5. Buat file view LuCI (antarmuka web)
log "Membuat file antarmuka web LuCI..."
mkdir -p /usr/lib/lua/luci/view/keepalive/
cat <<'EOF' > /usr/lib/lua/luci/view/keepalive/manager.htm
<%+header%>

<%
    local http = require "luci.http"
    local sys = require "luci.sys"

    if http.source() == "post" then
        local target_from_form = http.formvalue("target") or "8.8.8.8"
        local interval_from_form = http.formvalue("interval") or "180"
        local enabled_from_form = http.formvalue("enabled") or "0"
        
        sys.call("uci set keepalive.settings.target='" .. target_from_form .. "'")
        sys.call("uci set keepalive.settings.interval='" .. interval_from_form .. "'")
        sys.call("uci set keepalive.settings.enabled='" .. enabled_from_form .. "'")
        sys.call("uci commit keepalive")

        if enabled_from_form == "1" then
            sys.call("/etc/init.d/keepalive enable > /dev/null 2>&1")
            sys.call("/etc/init.d/keepalive restart > /dev/null 2>&1 &")
        else
            sys.call("/etc/init.d/keepalive disable > /dev/null 2>&1")
            sys.call("/etc/init.d/keepalive stop > /dev/null 2>&1")
        end
    end

    local current_target = sys.exec("uci get keepalive.settings.target 2>/dev/null"):gsub('[\r\n]', '')
    local current_interval = sys.exec("uci get keepalive.settings.interval 2>/dev/null"):gsub('[\r\n]', '')
    local current_enabled = sys.exec("uci get keepalive.settings.enabled 2>/dev/null"):gsub('[\r\n]', '')

    local pid = sys.exec("pgrep -f '/usr/bin/keepalive.sh'")
    local status_text
    if pid and pid ~= "" and current_enabled == "1" then
        status_text = "<span style='color:green;'>Berjalan (PID: " .. pid:gsub('[\r\n]', '') .. ")</span>"
    else
        status_text = "<span style='color:red;'>Tidak Berjalan</span>"
    end
    
    local log_output = sys.exec("logread | grep 'KeepAlive' | tail -n 10")
%>

<div class="cbi-map">
    <h2>Keep-Alive Ping Manager</h2>
    <div class="cbi-section">
        <div class="cbi-section-node">
            <div class="cbi-value">
                <label class="cbi-value-title">Status Layanan</label>
                <div class="cbi-value-field"><%= status_text %></div>
            </div>
        </div>
    </div>

    <form method="post" action="<%= REQUEST_URI %>">
        <div class="cbi-section">
            <div class="cbi-section-node">
                <div class="cbi-value">
                    <label class="cbi-value-title" for="enabled">Kontrol Layanan</label>
                    <div class="cbi-value-field">
                        <select name="enabled" id="enabled">
                            <option value="1" <% if current_enabled == "1" then luci.http.write("selected='selected'") end %>>Enable</option>
                            <option value="0" <% if current_enabled == "0" then luci.http.write("selected='selected'") end %>>Disable</option>
                        </select>
                    </div>
                </div>
                <div class="cbi-value">
                    <label class="cbi-value-title" for="target">URL atau IP Tujuan</label>
                    <div class="cbi-value-field"><input type="text" style="width:400px;" name="target" id="target" value="<%= luci.http.write(current_target or '') %>" /></div>
                </div>
                <div class="cbi-value">
                    <label class="cbi-value-title" for="interval">Interval (detik)</label>
                    <div class="cbi-value-field"><input type="text" style="width:100px;" name="interval" id="interval" value="<%= luci.http.write(current_interval or '') %>" /></div>
                </div>
                <div class="cbi-value">
                    <div class="cbi-value-field">
                        <button type="submit" class="cbi-button cbi-button-apply" value="save">Simpan & Terapkan</button>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <div class="cbi-section">
        <h3>Log Terbaru</h3>
        <textarea readonly="readonly" style="width: 100%; height: 200px; background-color: #2b2b2b; color: #f0f0f0; font-family: monospace; font-size: 12px;"><%= luci.http.write(log_output or 'Log tidak tersedia.') %></textarea>
    </div>
</div>

<%+footer%>
EOF

# 6. Aktifkan layanan dan bersihkan cache
log "Menyelesaikan instalasi..."
/etc/init.d/keepalive enable > /dev/null 2>&1
rm -f /tmp/luci-indexcache

log "-----------------------------------------------------"
log "Instalasi Selesai!"
log "Sebuah entri menu baru 'Keep-Alive Ping' telah ditambahkan di bawah 'Services'."
log "Silakan segarkan browser Anda dan akses dari sana untuk mengaktifkannya."
log "-----------------------------------------------------"