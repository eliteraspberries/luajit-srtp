/^#define/ {
    s/#define  *\([A-Za-z0-9_]*\)$/local \1 = 1/g
    s/#define  *\([A-Za-z0-9_]*\)  *\(.*\)/local \1 = \2\
srtp.\1 = \1/g
    /#define  *[A-Za-z0-9_]*(.*)/ {
        s/\([A-Za-z0-9_]*\)->\([A-Za-z0-9_]*\)/\1[0].\2/g
    }
    s/#define  *srtp_\([A-Za-z0-9_]*\)(\([^)]*\))  *\(.*\)*/local function srtp_\1(\2)\
    return \3\
end\
srtp.\1 = srtp_\1/g
    p
}
s/.* srtp_\([A-Za-z0-9_]*\)(.*);$/srtp.\1 = libsrtp.srtp_\1/pg
