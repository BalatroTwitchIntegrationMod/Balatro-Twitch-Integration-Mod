-- Socket definitions

local ffi = require("ffi")

local C = ffi.C
local S = ffi.C

if ffi.os == "Windows" then
    C = ffi.load("ucrtbase.dll")
    S = ffi.load("Ws2_32.dll")

    ffi.cdef [[
        typedef unsigned int SOCKET;
        typedef int ssize_t;
        typedef struct WSAData WSADATA;

        void *malloc (size_t);
        void free (void *);
    ]]
else
    ffi.cdef [[
        typedef int SOCKET;
    ]]
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

---@class addrinfo
---@field ai_flags integer
---@field ai_family integer
---@field ai_socktype integer
---@field ai_protocol integer
---@field ai_addrlen integer
---@field ai_addr ffi.cdata*
---@field ai_canonname ffi.cdata*
---@field ai_next ffi.cdata*

if ffi.os == "OSX" then
    ffi.cdef [[
        struct sockaddr_in {
            uint8_t sin_len;
            sa_family_t sin_family;
            in_port_t sin_port;
            struct in_addr sin_addr;
	        char sin_zero[8];
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
	        char sin_zero[9];
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

ffi.cdef [[
    int getaddrinfo (const char *, const char *, const struct addrinfo *, struct addrinfo **);
    void freeaddrinfo (struct addrinfo *);
    const char *inet_ntop (int, const void *, char *, socklen_t);
    int inet_pton (int, const char *, void *);
    uint16_t htons (uint16_t);
    SOCKET socket (int, int, int);
    int connect (SOCKET, const struct sockaddr *, socklen_t);
    int close (SOCKET);
    ssize_t send (SOCKET, const void *, size_t, int);
    ssize_t recv (SOCKET, void *, size_t, int);
]]

if ffi.os == "Windows" then
    ffi.cdef [[
        int WSAStartup (unsigned short, WSADATA *);
        int WSACleanup (void);
        int closesocket (SOCKET);
        int shutdown (SOCKET, int);
        int ioctlsocket (SOCKET, unsigned long, unsigned long *);
        int WSAGetLastError (void);
    ]]
end

-- SSL definitions

local SSL = nil ---@type ffi.namespace*?
local ssl_names = {
    "Secur32.dll",
    "libssl.48.dylib",
    "libssl.so.3",
}

for _, name in ipairs(ssl_names) do
    local success, lib = pcall(ffi.load, name)
    if success then
        SSL = lib
        break
    end
end

if ffi.os == "Windows" then
    ffi.cdef [[

    ]]
else
    ffi.cdef [[
        int BIO_socket_nbio (int, int);

        typedef struct ssl_method_st SSL_METHOD;

        SSL_METHOD *TLS_method (void);

        typedef struct ssl_ctx_st SSL_CTX;

        SSL_CTX *SSL_CTX_new (SSL_METHOD *);
        void SSL_CTX_free (SSL_CTX *);
        typedef int (*SSL_verify_cb) (int, void *);
        void SSL_CTX_set_verify (SSL_CTX *, int, SSL_verify_cb);
        int SSL_CTX_set_default_verify_paths (SSL_CTX *);
        long SSL_CTX_ctrl (SSL_CTX *, int , long , void *);

        typedef struct ssl_st SSL;

        SSL *SSL_new (SSL_CTX *);
        void SSL_free (SSL *);
        int SSL_get_error (const SSL *, int);
        int SSL_set_fd (SSL *, int);
        long SSL_ctrl (SSL *, int, long, void *);
        int SSL_connect (SSL *);
        int SSL_write (SSL *, const void *, int);
        int SSL_read (SSL *, void *, int);
        int SSL_shutdown (SSL *);
    ]]
end

return {
    C = C,
    D = {
        AF_INET = 2,
        AF_INET6 = ffi.os == "Windows" and 23 or ffi.os == "OSX" and 30 or 10,
        AF_UNSPEC = 0,
        AI_CANONNAME = 2,
        EINPROGRESS = ffi.os == "OSX" and 36 or 115,
        FIONBIO = 0x8004667E,
        INVALID_SOCKET = 4294967295,
        SOCK_STREAM = 1,
        SSL_CTRL_SET_MIN_PROTO_VERSION = 123,
        SSL_CTRL_SET_TLSEXT_HOSTNAME = 55,
        SSL_ERROR_NONE = 0,
        SSL_ERROR_WANT_READ = 2,
        SSL_ERROR_WANT_WRITE = 3,
        SSL_VERIFY_PEER = 1,
        TLS1_2_VERSION = 0x0303,
        TLSEXT_NAMETYPE_host_name = 0,
    },
    S = S,
    SSL = SSL,
}
