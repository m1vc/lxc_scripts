#!/bin/bash

if [ -z "$1" ] ; then
	echo "Missing host"
else
	lxc exec $1 -- groupadd --system polymesh 
	lxc exec $1 -- useradd -m -s /sbin/nologin --system -g polymesh polymesh 
	
	lxc exec $1 -- sh -c "echo HOSTNAME=$1 > /usr/local/etc/hostname" 
	lxc file push ../storage/polymesh $1/usr/local/bin/
	lxc file push ../storage/operator.service $1/etc/systemd/system/
	lxc file push ../storage/hostname.sh $1/usr/local/bin/

	lxc exec $1 -- systemctl daemon-reload
	lxc exec $1 -- systemctl enable operator 
	lxc exec $1 -- systemctl start operator
#        lxc config device add $1 p$2c30333 proxy listen=tcp:0.0.0.0:$2 connect=tcp:127.0.0.1:30333
#       ufw allow $2/tcp
	lxc start $1
	lxc list
	./l_showNetwork.sh
OUT=d_$1.sh
cat << EOF> $OUT
#!/bin/bash
ufw delete allow $2/tcp
EOF
echo $OUT
fi