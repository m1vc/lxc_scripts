#!/bin/bash

if [ -z "$1" ] ; then
	echo "Missing host"
else
	lxc exec $1 -- groupadd --system polymesh 
	lxc exec $1 -- useradd -m -s /sbin/nologin --system -g polymesh polymesh 
	
	lxc exec $1 -- sh -c "echo HOSTNAME=$1 > /usr/local/etc/hostname" 
	lxc file push ../storage/polymesh $1/usr/local/bin/
	lxc file push ../storage/sentry.service $1/etc/systemd/system/
	lxc file push ../storage/hostname.sh $1/usr/local/bin/

	lxc exec $1 -- systemctl daemon-reload
	lxc exec $1 -- systemctl enable sentry 
	lxc exec $1 -- systemctl start sentry
	lxc config device add $1 p$2c9100 proxy listen=tcp:0.0.0.0:$2 connect=tcp:127.0.0.1:9100
	lxc config device add $1 p$3c30333 proxy listen=tcp:0.0.0.0:$3 connect=tcp:127.0.0.1:30333
	sudo ufw allow $2/tcp
	sudo ufw allow $3/tcp
	OUT=d_$1.sh
cat << EOF> $OUT
#!/bin/bash
ufw delete allow $2/tcp
ufw allow $3/tcp
EOF
	echo $OUT

fi
