KOALA_RECORD_TO_DIR=/tmp/ LD_PRELOAD=${V2PRO}/koala-libc/output/koala-libc.so KOALA_SO=${V2PRO}/koala/output/koala-tracer.so exec objs/nginx -c /tmp/koala-nginx/conf/nginx.conf
