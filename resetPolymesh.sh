#!/bin/bash
if [ -z "$1" ] ; then
	echo "Missing config file";
	exit 1;
fi

source "$1"
for Container in $operatorName $sentryaName $sentrybName 
do
	lxc stop $Container 
    lxc delete $Container
done

sudo ufw delete allow $sentryaP2Pport
sudo ufw delete allow $sentrybP2Pport