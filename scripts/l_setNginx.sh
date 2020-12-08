#!/bin/bash

if [ -z "$1" ] ; then
	echo "Missing host"
else
	lxc exec $1 -- bash -c "apt update"
	lxc exec $1 -- bash -c "apt upgrade -y"
	lxc exec $1 -- bash -c "apt install -y nginx"
	lxc exec $1 -- systemctl daemon-reload
	lxc exec $1 -- systemctl enable nginx 
	lxc exec $1 -- systemctl start nginx
	#lxc config device add $1 p3000c3000 proxy listen=tcp:0.0.0.0:3000 connect=tcp:127.0.0.1:3000
	#sudo ufw allow 3000/tcp
OUT=d_$1.sh
cat << EOF> $OUT
#!/bin/bash
ufw delete allow 3000/tcp
EOF
echo $OUT
fi
