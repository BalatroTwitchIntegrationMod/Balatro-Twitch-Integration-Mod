local ffi = require("ffi")

if ffi.os == "Windows" then
    return require("socket.wsocket")
else
    return require("socket.usocket")
end
