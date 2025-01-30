FROM alpine:3.18

# 1. Install build dependencies (for NGINX) + Python3
RUN apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    curl \
    unzip \
    python3

# 2. Download NGINX source + ngx_cache_purge
ENV NGINX_VERSION="1.25.2"
WORKDIR /tmp
RUN curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxvf nginx-${NGINX_VERSION}.tar.gz \
    && curl -L -o ngx_cache_purge.zip https://github.com/FRiCKLE/ngx_cache_purge/archive/refs/heads/master.zip \
    && unzip ngx_cache_purge.zip

# 3. Configure and build NGINX with ngx_cache_purge
WORKDIR /tmp/nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/etc/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --add-module=/tmp/ngx_cache_purge-master \
    && make \
    && make install

# 4. Create cache folder + logs
RUN mkdir -p /var/cache/nginx
RUN mkdir -p /var/log/nginx

# 5. Copy your nginx.conf + html folder
COPY nginx.conf /etc/nginx/nginx.conf
COPY html /usr/share/nginx/html

# 6. Expose port 80
EXPOSE 80

# 7. Start python server on port 8001, then run nginx in foreground
CMD ["/bin/sh", "-c", "python3 -m http.server 8001 --directory /usr/share/nginx/html & /etc/nginx/sbin/nginx -g 'daemon off;'"]