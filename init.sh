#!/bin/bash

if [ ! "$(ls -A /etc/nginx)" ]; then
	cp -R $HOME/nginx-default-conf/* /etc/nginx
fi

exec nginx