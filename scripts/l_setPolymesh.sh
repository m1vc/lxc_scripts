#!/bin/bash
if [ -z "$1" ] ; then
	echo "Missing host";
	exit 1;
fi

source "$1"
echo "$localDir"/polymesh
ls -lh "$localDir"/polymesh
# functions
startServices (){ 
	lxc exec $1 -- systemctl daemon-reload 
	lxc exec $1 -- systemctl enable $2
	lxc exec $1 -- systemctl start $2
}

stopServices (){ 
	lxc exec $1 -- systemctl stop $2 
}

getpeerID () {
        lxc config device add $1 p9933 proxy listen=tcp:127.0.0.1:9933 connect=tcp:127.0.0.1:9933 -q
        peerId=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_networkState"}' http://localhost:9933/  | jq -r .result.peerId)
        lxc config device remove $1 p9933 -q
        echo "$peerId"
}

openPort () {
	 lxc config device add "$1" p"$2"c30333 proxy listen=tcp:0.0.0.0:"$2" connect=tcp:127.0.0.1:30333 -q
}

# create containers 
lxd sql global "SELECT b.name, a.value "Size" FROM storage_pools_config a left join storage_pools b WHERE a.storage_pool_id=b.id and key='size'"
read -p "Select storage: " storage

echo "Creating containers"
for Container in $operatorName $sentryaName $sentrybName 
do
	lxc init ubuntu-minimal:bionic $Container -s $storage
	lxc network attach lxdbr0 $Container eth0 eth0
done
echo "Containers created"

# config network  
echo "Configuring Network"
lxc config device set $operatorName eth0 ipv4.address $operatorIP 
lxc config device set $sentryaName eth0 ipv4.address $sentryaIP 
lxc config device set $sentrybName eth0 ipv4.address $sentrybIP 
openPort $sentryaName $sentryaP2Pport
openPort $sentrybName $sentrybP2Pport
echo "Network configured"
# start the containers
echo "Starting the containers"
for Container in $operatorName $sentryaName $sentrybName 
do
	lxc start $Container 
done
echo "Containers started"
# create users and install files
echo "Copying files and creating users"
for Container in $operatorName $sentryaName $sentrybName 
do
	lxc exec $Container -- groupadd --system polymesh 
	lxc exec $Container -- useradd -m -s /sbin/nologin --system -g polymesh polymesh 
	lxc file push "$localDir"/polymesh $Container/usr/local/bin/
	lxc file push "$localDir"/operator.service $Container/etc/systemd/system/
	lxc file push "$localDir"/sentry.service $Container/etc/systemd/system/
	lxc exec $Container -- systemctl daemon-reload
done
echo "Files copied and users created"

# configure systemd services to generate peerId
operatorSystemd=$'#!/bin/bash\n/usr/local/bin/polymesh --operator --name '"$operatorName"
sentryaSystemd=$'#!/bin/bash\n/usr/local/bin/polymesh --sentry --name '"$sentryaName"
sentrybSystemd=$'#!/bin/bash\n/usr/local/bin/polymesh --sentry --name '"$sentrybName"

lxc exec $operatorName -- sh -c "echo $operatorSystemd > /home/polymesh/operator.start" 
lxc exec $sentryaName  -- sh -c "echo "$sentryaSystemd" > /home/polymesh/sentry.start" 
lxc exec $sentrybName  -- sh -c "echo "$sentrybSystemd" > /home/polymesh/sentry.start" 

for Container in $operatorName $sentryaName $sentrybName 
do
	lxc exec $Container -- sh -c "chown polymesh:polymesh /home/polymesh/*.start && chmod +x /home/polymesh/*.start"
done
# Start services to get the peerId
startServices $operatorName operator
operatorPeerID=$(getpeerID $operatorName)
echo "Operator PeerId: ""$operatorPeerID"
stopServices $operatorName operator

startServices $sentryaName sentry
sentryaPeerID=$(getpeerID $sentryaName)
echo "Sentrya PeerId: "$sentryaPeerID
stopServices $sentryaName sentry

startServices $sentrybName sentry
sentrybPeerID=$(getpeerID $sentrybName)
echo "Sentryb PeerId: ""$sentrybPeerID"
stopServices $sentrybName sentry

# reconfigure systemd services
operatorSystemd=$operatorSystemd" --prometheus-external --sentry-nodes /ip4/$sentryaIP/tcp/30333/p2p/$sentryaPeerID /ip4/$sentrybIP/tcp/30333/p2p/$sentrybPeerID"
sentryaSystemd=$sentryaSystemd" --prometheus-external --sentry /ip4/$operatorIP/tcp/30333/p2p/$operatorPeerID"
sentrybSystemd=$sentrybSystemd" --prometheus-external --sentry /ip4/$operatorIP/tcp/30333/p2p/$operatorPeerID"
 
lxc exec $operatorName -- sh -c 'echo "$operatorSystemd" > /home/polymesh/operator.start' 
lxc exec $sentryaName  -- sh -c "echo "$sentryaSystemd" > /home/polymesh/sentry.start" 
lxc exec $sentrybName  -- sh -c "echo "$sentrybSystemd" > /home/polymesh/sentry.start" 

for Container in $operatorName $sentryaName $sentrybName 
do
	lxc exec $Container -- sh -c "chown polymesh:polymesh /home/polymesh/*.start && chmod +x /home/polymesh/*.start"
done

restart services
startServices $operatorName operator
startServices $sentryaName sentry
startServices $sentrybName sentry

#lxc file push "$localDir"/keystore.tar.gz $operatorName/home/polymesh