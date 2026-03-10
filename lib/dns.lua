---@diagnostic disable: assign-type-mismatch

local ffi = require("ffi")

local C = nil

if ffi.os == "Windows" then
    C = ffi.load("Ws2_32.dll")
else
    C = ffi.C
end

ffi.cdef [[
    typedef uint32_t socklen_t;
    typedef uint8_t sa_family_t;
    typedef uint16_t in_port_t;
    typedef uint32_t in_addr_t;

    typedef struct in_addr {
        in_addr_t s_addr;
    } in_addr_t;

    typedef struct in6_addr {
        union {
            uint8_t __u6_addr8[16];
            uint16_t __u6_addr16[8];
            uint32_t __u6_addr32[4];
        } __u6_addr;
    } in6_addr_t;
]]

if ffi.os == "Linux" then
    ffi.cdef [[
        struct addrinfo {
            int ai_flags;
            int ai_family;
            int ai_socktype;
            int ai_protocol;
            socklen_t ai_addrlen;
            struct sockaddr *ai_addr;
            char *ai_canonname;
            struct addrinfo *ai_next;
        };
    ]]
else
    ffi.cdef [[
        struct addrinfo {
            int ai_flags;
            int ai_family;
            int ai_socktype;
            int ai_protocol;
            socklen_t ai_addrlen;
            char *ai_canonname;
            struct sockaddr *ai_addr;
            struct addrinfo *ai_next;
        };
    ]]
end

if ffi.os == "OSX" then
    ffi.cdef [[
        struct sockaddr_in {
            uint8_t sin_len;
            sa_family_t sin_family;
            in_port_t sin_port;
            struct in_addr sin_addr;
        };

        struct sockaddr_in6 {
            uint8_t sin6_len;
            sa_family_t sin6_family;
            in_port_t sin6_port;
            uint32_t sin6_flowinfo;
            struct in6_addr sin6_addr;
            uint32_t sin6_scope_id;
        };
    ]]
else
    ffi.cdef [[
        struct sockaddr_in {
            sa_family_t sin_family;
            in_port_t sin_port;
            struct in_addr sin_addr;
        };

        struct sockaddr_in6 {
            sa_family_t sin6_family;
            in_port_t sin6_port;
            uint32_t sin6_flowinfo;
            struct in6_addr sin6_addr;
            uint32_t sin6_scope_id;
        };
    ]]
end

ffi.cdef [[
    int getaddrinfo (const char *, const char *, const struct addrinfo *, struct addrinfo **);
    void freeaddrinfo (struct addrinfo *);
    const char *inet_ntop(int, const void *, char *, socklen_t);
]]

---@class sockaddr_in
---@field sin_len integer
---@field sin_family integer
---@field sin_port integer
---@field sin_addr table

---@class sockaddr_in6
---@field sin6_len integer
---@field sin6_family integer
---@field sin6_port integer
---@field sin6_flowinfo integer
---@field sin6_addr table
---@field sin6_scope_id integer

---@class addrinfo
---@field ai_flags integer
---@field ai_family integer
---@field ai_socktype integer
---@field ai_protocol integer
---@field ai_addrlen integer
---@field ai_addr ffi.cdata*
---@field ai_canonname ffi.cdata*
---@field ai_next ffi.cdata*

local AF = {
    UNSPEC = 0,
    INET = 2,
    INET6 = 30
}

local SOCK = {
    STREAM = 1
}

local FLAGS = {
    CANONNAME = 2
}

---@param address addrinfo
---@return string?
local function convert_to_string(address)
    local addr = nil

    if address.ai_family == AF.INET then
        local sockaddr = ffi.cast("struct sockaddr_in *", address.ai_addr) ---@type sockaddr_in
        addr = sockaddr.sin_addr
    end

    if address.ai_family == AF.INET6 then
        local sockaddr = ffi.cast("struct sockaddr_in6 *", address.ai_addr) ---@type sockaddr_in6
        addr = sockaddr.sin6_addr
    end

    if not addr then
        return nil
    end

    local addrstr = ffi.new("char[128]")

    return ffi.string(C.inet_ntop(address.ai_family, addr, addrstr, 128))
end

---@class DNS
local DNS = {}

---@param hostname string
---@param ipv6 boolean?
---@return string?, "not found"?
function DNS:resolve(hostname, ipv6)
    local hints = ffi.new("struct addrinfo") ---@type addrinfo
    hints.ai_family = ipv6 and AF.INET6 or AF.INET
    hints.ai_socktype = SOCK.STREAM
    hints.ai_flags = FLAGS.CANONNAME

    local result = ffi.new("struct addrinfo *[1]")
    local err = C.getaddrinfo(hostname, nil, hints, result)

    if err < 0 then
        return nil, "not found"
    end

    local ip = nil
    local addrinfo = ffi.new("struct addrinfo *", result[0]) ---@type addrinfo

    while addrinfo ~= nil and ip == nil do
        ip = convert_to_string(addrinfo)
        addrinfo = addrinfo[0].ai_next
    end

    C.freeaddrinfo(result[0])

    if not ip then
        return nil, "not found"
    end

    return ip, nil
end

return DNS
