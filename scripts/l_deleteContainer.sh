#!/bin/bash
if [ -z "$1" ] && [ -z "$2" ]; then
	echo "input hostname, prometheus port (910x) and p2p port (3033x)"
else
        lxc stop $1
	lxc delete $1
	sudo ufw delete allow $2/tcp
	sudo ufw delete allow $3/tcp
fi


