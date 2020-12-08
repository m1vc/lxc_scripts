#!/bin/bash

if [ -z "$1" ] ; then
	echo "Missing host"
else
	lxc exec $1 -- groupadd --system node_exporter
	lxc exec $1 -- useradd -s /sbin/nologin --system -g node_exporter node_exporter 
	
	lxc file push ~/storage/node_exporter $1/usr/local/bin/
	lxc file push ~/storage/node_exporter.service $1/etc/systemd/system/

	lxc exec $1 -- systemctl daemon-reload
	lxc exec $1 -- systemctl enable node_exporter 
	lxc exec $1 -- systemctl start node_exporter
fi
