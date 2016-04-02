FROM ubuntu:14.04

ENV NPS_VERSION 1.11.33.0
ENV NGINX_VERSION 1.9.13

RUN \
	apt-get update && \
	apt-get -y upgrade && \
	apt-get install -y build-essential software-properties-common curl git htop man unzip vim wget

RUN \
	add-apt-repository ppa:maxmind/ppa && \
	apt-get install -y aptitude && \
	aptitude update && \
	aptitude install libmaxminddb0 libmaxminddb-dev mmdb-bin

RUN apt-get install -y zlib1g-dev libpcre3 libpcre3-dev libssl-dev libxml2-dev libxslt-dev libgd2-xpm-dev geoip-database libgeoip-dev

RUN \
	wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip && \
	unzip release-${NPS_VERSION}-beta.zip && \
	rm release-${NPS_VERSION}-beta.zip && \
	cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
	wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
	tar -xzvf ${NPS_VERSION}.tar.gz && \
	rm ${NPS_VERSION}.tar.gz && \
	cd ../

RUN git clone https://github.com/leev/ngx_http_geoip2_module.git

RUN \
	wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
	tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
	rm -rf nginx-${NGINX_VERSION}.tar.gz && \
	cd nginx-${NGINX_VERSION}/ && \
    ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/etc/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-mail --with-mail_ssl_module --with-file-aio --with-http_v2_module --with-ipv6 --add-dynamic-module=/ngx_http_geoip2_module --add-dynamic-module=/ngx_pagespeed-release-${NPS_VERSION}-beta && \
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