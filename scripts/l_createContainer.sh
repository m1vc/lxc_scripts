#!/bin/bash
if [ -z "$1" ] && [ -z "$2" ]; then
	echo "input hostname, storage pool name"
else
       lxc init ubuntu-minimal:bionic $1 -s $2
       echo "$1 created  on $2"
       echo "run l_setNetwork.sh to configure the network and start the container"
fi


