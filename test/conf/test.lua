local ffi = require "ffi"

if not pcall(ffi.typeof, "struct in_addr") then
    ffi.cdef[[
        typedef uint16_t  sa_family_t;
        typedef	uint16_t  in_port_t;
        typedef	uint32_t  in_addr_t;
        typedef uint32_t  socklen_t;

        typedef long  ssize_t;
        typedef unsigned long  size_t;

        /*
         * Internet address (a structure for historical reasons)
         */
        struct in_addr {
            in_addr_t s_addr;
        };

        struct sockaddr_in {
            sa_family_t	sin_family;
            in_port_t	sin_port;
            struct	in_addr sin_addr;
            char		sin_zero[8];
        };

        struct sockaddr {
            sa_family_t	sa_family;	/* [XSI] address family */
            char		sa_data[14];	/* [XSI] addr value (actually larger) */
        };
        ssize_t sendto(int socket, const void *buffer, size_t length, int flags, const struct sockaddr_in *dest_addr, socklen_t dest_len);
        ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
    ]]
end

function send_to_koala(helper_type, helper_int_arg, helper_string_arg)
    local payload = helper_type .. "\n" .. helper_string_arg
    local payload_len = string.len(payload)
    local sa_dest_addr = ffi.new("struct sockaddr_in[1]")
    ffi.fill(sa_dest_addr, ffi.sizeof(sa_dest_addr))

    sa_dest_addr[0].sin_family = 2 -- AF_INET
    sa_dest_addr[0].sin_port = 32512 --127
    sa_dest_addr[0].sin_addr.s_addr = 2139062143 -- 127.127.127.127

    return ffi.C.sendto(0, payload, payload_len, helper_int_arg, sa_dest_addr, ffi.sizeof(sa_dest_addr))
end

function recv_from_koala()
    local buf = ffi.new("char[4096]")
    local n = ffi.C.recvfrom(0, ffi.cast('char *',buf),ffi.sizeof(buf), 127127, nil,nil)
    return ffi.string(buf,n)
end

send_to_koala("to-koala!set-trace-header-key", 0, "order_id\nhello")

local sock = ngx.socket.tcp()
local ok, err = sock:connect("127.0.0.1", 8777)
if not ok then
    ngx.say("failed to connect to baidu: ", err)
    return
end

local req_data = "GET /leaf HTTP/1.1\r\nHost: 127.0.0.1:8777\r\n\r\n"
local bytes, err = sock:send(req_data)
if err then
    ngx.say("failed to send to baidu: ", err)
    return
end

local data, err, partial = sock:receive()
if err then
    ngx.say("failed to recieve to baidu: ", err)
    return
end

sock:close()
send_to_koala("to-koala!get-trace-header-key", 0, "ti") -- ti is trace_id
local trace_id = recv_from_koala()
ngx.say("successfully talk to leaf! trace id: ", trace_id)