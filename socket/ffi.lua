-- Socket definitions

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
    int socket (int domain, int type, int protocol);
    int connect (int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    int close (int fd);
    ssize_t send (int, const void *, size_t, int);
    ssize_t recv (int, void *, size_t, int);
    int fcntl (int, int, ...);
]]

-- libSSL definitions

local libssl = nil ---@type ffi.namespace*?
local libssl_names = {
    "libssl.so.3",
    "libssl.48.dylib"
}

for _, name in ipairs(libssl_names) do
    local success, lib = pcall(ffi.load, name)
    if success then
        libssl = lib
        break
    end
end

ffi.cdef [[
    int BIO_socket_nbio (int fd, int mode);

    typedef struct ssl_method_st SSL_METHOD;

    SSL_METHOD *TLS_method (void);

    typedef struct ssl_ctx_st SSL_CTX;

    SSL_CTX *SSL_CTX_new (SSL_METHOD *meth);
    void SSL_CTX_free (SSL_CTX *ctx);
    typedef int (*SSL_verify_cb) (int preverify_ok, void *x509_ctx);
    void SSL_CTX_set_verify (SSL_CTX *ctx, int mode, SSL_verify_cb callback);
    int SSL_CTX_set_default_verify_paths (SSL_CTX *ctx);
    long SSL_CTX_ctrl (SSL_CTX *ctx, int cmd, long larg, void *parg);

    typedef struct ssl_st SSL;

    SSL *SSL_new (SSL_CTX *ctx);
    void SSL_free (SSL *ssl);
    int SSL_get_error (const SSL *ssl, int i);
    int SSL_set_fd (SSL *ssl, int fd);
    long SSL_ctrl (SSL *ssl, int cmd, long larg, void *parg);
    int SSL_connect (SSL *ssl);
    int SSL_write (SSL *ssl, const void *buf, int num);
    int SSL_read (SSL *ssl, void *buf, int num);
    int SSL_shutdown (SSL *ssl);
]]

return {
    C = C,
    D = {
        AF_INET = 2,
        AF_INET6 = 30,
        AF_UNSPEC = 0,
        AI_CANONNAME = 2,
        EINPROGRESS = ffi.os == "OSX" and 36 or 115,
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
    SSL = libssl,
}
