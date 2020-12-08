#!/bin/bash

if [ -z "$1" ] ; then
	echo "Input host name"
else
#        lxc network attach lxdbr0 $1 eth0 eth0
#	lxc config device set $1 eth0 ipv4.address $2
#        lxc start $1

	lxc exec $1 -- mkdir -p /etc/prometheus/rules
	lxc exec $1 -- mkdir /etc/prometheus/rules.d
	lxc exec $1 -- mkdir /etc/prometheus/files_sd
	lxc exec $1 -- mkdir /etc/prometheus/consoles
	lxc exec $1 -- mkdir /etc/prometheus/console_libraries
	lxc exec $1 -- mkdir /var/lib/prometheus 
	lxc exec $1 -- groupadd --system prometheus
	lxc exec $1 -- useradd -s /sbin/nologin --system -g prometheus prometheus
	
	lxc file push ~/storage/prometheus*/prometheus $1/usr/local/bin/
	lxc file push ~/storage/prometheus*/promtool $1/usr/local/bin/
	lxc file push ~/storage/prometheus.service $1/etc/systemd/system/
	lxc file push ~/storage/prometheus.yml $1/etc/prometheus/		
	lxc file push ~/storage/prometheus*/consoles/* $1/etc/prometheus/consoles/
	lxc file push ~/storage/prometheus*/console_libraries/* $1/etc/prometheus/console_libraries/

	lxc exec $1 -- chown -R prometheus:prometheus /etc/prometheus/rules
	lxc exec $1 -- chown -R prometheus:prometheus /etc/prometheus/rules.d
	lxc exec $1 -- chown -R prometheus:prometheus /etc/prometheus/files_sd
	lxc exec $1 -- chown -R prometheus:prometheus /var/lib/prometheus/
	lxc exec $1 -- chmod -R 775 /etc/prometheus/rules
	lxc exec $1 -- chmod -R 775 /etc/prometheus/rules.d
	lxc exec $1 -- chmod -R 775 /etc/prometheus/files_sd
	
	lxc exec $1 -- systemctl daemon-reload
	lxc exec $1 -- systemctl enable prometheus
	lxc exec $1 -- systemctl start prometheus
fi
