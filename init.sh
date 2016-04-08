#!/bin/bash

if [ ! "$(ls -A /etc/nginx)" ]; then
	cp -R $HOME/nginx-default-conf/* /etc/nginx
fi

if [ ! "$(ls -A /etc/nginx/modules)" ]; then
    cp -R $HOME/nginx-default-conf/modules /etc/nginx/modules
fi

exec nginx