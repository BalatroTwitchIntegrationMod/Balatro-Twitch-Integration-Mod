-- Socket definitions

local ffi = require("ffi")

local C = ffi.C
local S = ffi.C

if ffi.os == "Windows" then
    C = ffi.load("ucrtbase.dll")
    S = ffi.load("Ws2_32.dll")

    ffi.cdef [[
        typedef int ssize_t;
        typedef unsigned int SOCKET;

        void *malloc (size_t);
        void free (void *);
        void *memmove (void *, const void *, size_t);
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
        typedef struct WSAData WSADATA;

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
        typedef void *PVOID;
        typedef char CHAR;
        typedef char *LPSTR;
        typedef long LONG;
        typedef unsigned long DWORD;
        typedef unsigned long long ULONG_PTR, *PULONG_PTR;
        typedef LONG HRESULT;
        typedef long SECURITY_STATUS;
        typedef CHAR SEC_CHAR;
        typedef struct _CERT_CONTEXT CERT_CONTEXT, *PCERT_CONTEXT;
        typedef const CERT_CONTEXT *PCCERT_CONTEXT;
        typedef void *HCERTSTORE;
        struct _HMAPPER;
        typedef unsigned int ALG_ID;
        typedef struct _SCHANNEL_CRED {
            DWORD dwVersion;
            DWORD cCreds;
            PCCERT_CONTEXT *paCred;
            HCERTSTORE hRootStore;
            DWORD cMappers;
            struct _HMAPPER **aphMappers;
            DWORD cSupportedAlgs;
            ALG_ID * palgSupportedAlgs;
            DWORD grbitEnabledProtocols;
            DWORD dwMinimumCipherStrength;
            DWORD dwMaximumCipherStrength;
            DWORD dwSessionLifespan;
            DWORD dwFlags;
            DWORD dwCredFormat;
        } SCHANNEL_CRED, *PSCHANNEL_CRED;
        typedef struct _SecHandle {
            ULONG_PTR dwLower;
            ULONG_PTR dwUpper;
        } SecHandle, *PSecHandle;
        typedef SecHandle CredHandle;
        typedef PSecHandle PCredHandle;
        typedef SecHandle CtxtHandle;
        typedef PSecHandle PCtxtHandle;
        typedef union _LARGE_INTEGER LARGE_INTEGER;
        typedef LARGE_INTEGER *PTimeStamp;
        typedef void (* SEC_GET_KEY_FN) (void *, void *, unsigned long, void **, SECURITY_STATUS *);
        typedef struct _SecBuffer {
            unsigned long cbBuffer;
            unsigned long BufferType;
            void *pvBuffer;
        } SecBuffer, *PSecBuffer;
        typedef struct _SecBufferDesc {
            unsigned long ulVersion;
            unsigned long cBuffers;
            PSecBuffer pBuffers;
        } SecBufferDesc, *PSecBufferDesc;
        typedef struct _SecPkgContext_StreamSizes {
            unsigned long cbHeader;
            unsigned long cbTrailer;
            unsigned long cbMaximumMessage;
            unsigned long cBuffers;
            unsigned long cbBlockSize;
        } SecPkgContext_StreamSizes, *PSecPkgContext_StreamSizes;

        SECURITY_STATUS AcquireCredentialsHandleA (LPSTR, LPSTR, unsigned long, void *, void *, SEC_GET_KEY_FN, void *, PCredHandle, PTimeStamp);
        SECURITY_STATUS FreeCredentialsHandle (PCredHandle);
        SECURITY_STATUS InitializeSecurityContextA (PCredHandle, PCtxtHandle, SEC_CHAR *, unsigned long, unsigned long, unsigned long, PSecBufferDesc, unsigned long, PCtxtHandle, PSecBufferDesc, unsigned long *, PTimeStamp);
        SECURITY_STATUS DeleteSecurityContext (PCtxtHandle);
        SECURITY_STATUS FreeContextBuffer (PVOID);
        SECURITY_STATUS QueryContextAttributesA (PCtxtHandle, unsigned long, void *);
        SECURITY_STATUS EncryptMessage (PCtxtHandle, unsigned long, PSecBufferDesc, unsigned long);
        SECURITY_STATUS DecryptMessage (PCtxtHandle, PSecBufferDesc, unsigned long, unsigned long *);
        SECURITY_STATUS ApplyControlToken (PCtxtHandle, PSecBufferDesc);
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
        -- General defines
        AF_INET = 2,
        AF_INET6 = ffi.os == "Windows" and 23 or ffi.os == "OSX" and 30 or 10,
        AF_UNSPEC = 0,
        AI_CANONNAME = 2,
        EINPROGRESS = ffi.os == "Windows" and 112 or ffi.os == "OSX" and 36 or 115,
        SOCK_STREAM = 1,

        -- libSSL defines
        SSL_CTRL_SET_MIN_PROTO_VERSION = 123,
        SSL_CTRL_SET_TLSEXT_HOSTNAME = 55,
        SSL_ERROR_NONE = 0,
        SSL_ERROR_WANT_READ = 2,
        SSL_ERROR_WANT_WRITE = 3,
        SSL_VERIFY_PEER = 1,
        TLS1_2_VERSION = 0x0303,
        TLSEXT_NAMETYPE_host_name = 0,

        -- Windows specific defines
        FIONBIO = 0x8004667E,
        INVALID_SOCKET = 4294967295,
        ISC_REQ_ALLOCATE_MEMORY = 0x00000100,
        ISC_REQ_CONFIDENTIALITY = 0x00000010,
        ISC_REQ_REPLAY_DETECT = 0x00000004,
        ISC_REQ_SEQUENCE_DETECT = 0x00000008,
        ISC_REQ_STREAM = 0x00008000,
        ISC_REQ_USE_SUPPLIED_CREDS = 0x00000080,
        SCH_CRED_AUTO_CRED_VALIDATION = 0x00000020,
        SCH_CRED_NO_DEFAULT_CREDS = 0x00000010,
        SCH_USE_STRONG_CRYPTO = 0x00400000,
        SCHANNEL_CRED_VERSION = 0x00000004,
        SCHANNEL_SHUTDOWN = 1,
        SEC_E_INCOMPLETE_MESSAGE = 0x80090318,
        SEC_E_OK = 0,
        SEC_I_CONTINUE_NEEDED = 0x90312,
        SECBUFFER_DATA = 1,
        SECBUFFER_EMPTY = 0,
        SECBUFFER_EXTRA = 5,
        SECBUFFER_MISSING = 4,
        SECBUFFER_STREAM_HEADER = 7,
        SECBUFFER_STREAM_TRAILER = 6,
        SECBUFFER_TOKEN = 2,
        SECBUFFER_VERSION = 0,
        SECPKG_ATTR_STREAM_SIZES = 4,
        SECPKG_CRED_OUTBOUND = 2,
        UNISP_NAME_A = "Microsoft Unified Security Protocol Provider",
        WSAENOTCONN = 10057,
        WSAEWOULDBLOCK = 10035,
    },
    S = S,
    SSL = SSL,
}
