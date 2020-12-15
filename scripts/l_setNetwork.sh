#!/bin/bash
if [ -z "$1" ] && [ -z "$2" ]; then
	echo "input hostname, ip address"
	lxc list
	./l_showNetwork.sh 
else
	lxc network attach lxdbr0 $1 eth0 eth0
	lxc config device set $1 eth0 ipv4.address $2
#	lxc config device add $1 p$3c30333 proxy listen=tcp:0.0.0.0:$3 connect=tcp:127.0.0.1:30333
#	ufw allow $3/tcp
	lxc start $1
	lxc exec $1 -- /usr/local/bin/hostname.sh
	lxc list
    ./l_showNetwork.sh
fi
