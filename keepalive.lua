module("luci.controller.keepalive", package.seeall)

function index()
    entry({"admin", "services", "keepalive"}, 
          template("keepalive/manager"), 
          "Keep-Alive Ping", 
          20)
end