FROM ubuntu:16.04

ENV NPS_VERSION 1.13.35.2-stable
ENV NGINX_VERSION 1.14.0

RUN \
	apt-get update && \
	apt-get -y upgrade && \
	apt-get install -y build-essential software-properties-common curl git htop man unzip vim wget

RUN \
	add-apt-repository -y ppa:maxmind/ppa && \
	apt-get install -y aptitude && \
	aptitude update && \
	aptitude install libmaxminddb0 libmaxminddb-dev mmdb-bin

RUN apt-get install -y zlib1g-dev libpcre3 libpcre3-dev libssl-dev libxml2-dev libxslt-dev libgd2-xpm-dev geoip-database libgeoip-dev uuid-dev

RUN \
	wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip && \
	unzip v${NPS_VERSION}.zip && \
	rm v${NPS_VERSION}.zip && \
	find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d && \
	nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) && \
	cd ${nps_dir} && \
	NPS_RELEASE_NUMBER=${NPS_VERSION%beta} && \
	NPS_RELEASE_NUMBER=${NPS_VERSION%stable} && \
	psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz [ -e scripts/format_binary_url.sh ] && \
	psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && \
	wget ${psol_url} && \
	tar -xzvf $(basename ${psol_url}) && \
	rm $(basename ${psol_url}) && \
	cd ../

RUN git clone https://github.com/leev/ngx_http_geoip2_module.git

RUN \
	nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) && \
	wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
	tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
	rm -rf nginx-${NGINX_VERSION}.tar.gz && \
	cd nginx-${NGINX_VERSION}/ && \
	./configure --prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/etc/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_xslt_module=dynamic \
	--with-http_image_filter_module=dynamic \
	--with-http_geoip_module=dynamic \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-http_slice_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--with-http_v2_module \
	--with-ipv6 \
	--add-dynamic-module=/ngx_http_geoip2_module \
	--add-dynamic-module=/${nps_dir} \
	${PS_NGX_EXTRA_FLAGS} && \
	make && \
	make install && \
	cd ../

RUN useradd -r nginx

RUN rm -rf ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
	rm -rf nginx-${NGINX_VERSION}/ && \
	rm -rf ngx_http_geoip2_module/ && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	aptitude clean && \
	apt-get clean

RUN \
	echo "daemon off;" >> /etc/nginx/nginx.conf && \
	mkdir -p ${HOME}/nginx-default-conf && \
	cp -R /etc/nginx/* ${HOME}/nginx-default-conf

ADD ["./init.sh", "/root/"]

VOLUME ["/var/cache/nginx", "/etc/nginx", "/var/www"]

WORKDIR /etc/nginx

EXPOSE 80 443

ENTRYPOINT ["sh", "-c", "${HOME}/init.sh"]
