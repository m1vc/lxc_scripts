#!/bin/bash
if [ -z "$1" ] ; then
	echo "Missing host";
	exit 1;
fi

source "$1"
for Container in $operatorName $sentryaName $sentrybName 
do
	lxc exec stop $Container 
    lxc exec delete $Container
done