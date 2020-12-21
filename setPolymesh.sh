#!/bin/bash
#!/bin/bash
if [ -z "$1" ] ; then
	echo "Missing config file";
	exit 1;
fi

source "$1"

# functions
startServices (){ 
	lxc exec $1 -- sh -c "systemctl daemon-reload" 
	lxc exec $1 -- sh -c "systemctl enable $2"
	lxc exec $1 -- sh -c "systemctl restart $2"
}

getpeerID () {
        lxc config device add $1 p9933 proxy listen=tcp:127.0.0.1:9933 connect=tcp:127.0.0.1:9933 -q
        peerId=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_networkState"}' http://localhost:9933/  | jq -r .result.peerId)
        lxc config device remove $1 p9933 -q
        echo "$peerId"
}

openPort () {
	 lxc config device add "$1" p"$2"c$3 proxy listen=tcp:0.0.0.0:"$2" connect=tcp:127.0.0.1:$3 -q
	 sudo ufw allow $2
}

executeInAll() {
# Usage: $ ./lxc-exec-all.sh apt update && apt upgrade
	for container in $(lxc list volatile.last_state.power=RUNNING -c n --format csv); do    
    	lxc exec "$container" "$@"
	done
}
## Create containers 
createContainers() {
	lxd sql global "SELECT b.name, a.value "Size" FROM storage_pools_config a left join storage_pools b WHERE a.storage_pool_id=b.id and key='size'"
	read -p "Select storage: " storage

	echo "Creating containers"
	for Container in $operatorName $sentryaName $sentrybName 
	do
		lxc init ubuntu-minimal:bionic $Container -s $storage
		lxc network attach lxdbr0 $Container eth0 eth0
	done
	echo "Containers created"
}

destroyContainers() {
	for Container in $operatorName $sentryaName $sentrybName 
	do
		lxc stop $Container 
    	lxc delete $Container
	done
	sudo ufw delete allow $sentryaP2Pport
	sudo ufw delete allow $sentrybP2Pport
}
## Configure network  
configureNetwork() {
	echo "Configuring Network"
	lxc config device set $operatorName eth0 ipv4.address $operatorIP 
	lxc config device set $sentryaName eth0 ipv4.address $sentryaIP 
	lxc config device set $sentrybName eth0 ipv4.address $sentrybIP 
	openPort $sentryaName $sentryaP2Pport $p2pPort
	openPort $sentrybName $sentrybP2Pport $p2pPort
	echo "Network configured"
}

## Start containers
startContainers(){
	echo "Starting the containers"
	for Container in $operatorName $sentryaName $sentrybName 
	do
		lxc start $Container 
	done
}
## Stop containers
stopContainers(){
	echo "Starting the containers"
	for Container in $operatorName $sentryaName $sentrybName 
	do
		lxc stop $Container 
	done
	echo "Containers started"
}

## Install binaries and create users
installBinaries(){
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
}
## Initialise Operator
initialiseOperator(){
	# create temporary systemd on operator to get peerId
	lxc exec $operatorName -- sh -c "echo '#!/bin/bash \n/usr/local/bin/polymesh --operator --name $operatorName' > /home/polymesh/operator.start" 
	lxc exec $operatorName -- sh -c "chown polymesh:polymesh /home/polymesh/*.start && chmod +x /home/polymesh/*.start"

	# Start services on operator to get the operator peerId
	startServices $operatorName operator
	operatorPeerID=$(getpeerID $operatorName)
	echo "Operator PeerId: ""$operatorPeerID"
}

# Reconfigure systemd services for the sentry nodes
initialiseSentry(){
	lxc exec $sentryaName  -- sh -c "echo '#!/bin/bash \n/usr/local/bin/polymesh --name $sentryaName --prometheus-external --sentry /ip4/$operatorIP/tcp/30333/p2p/$operatorPeerID' > /home/polymesh/sentry.start" 
	lxc exec $sentrybName  -- sh -c "echo '#!/bin/bash \n/usr/local/bin/polymesh --name $sentrybName --prometheus-external --sentry /ip4/$operatorIP/tcp/30333/p2p/$operatorPeerID' > /home/polymesh/sentry.start" 
	for Container in $sentryaName $sentrybName 
	do
		lxc exec $Container -- sh -c "chown polymesh:polymesh /home/polymesh/*.start && chmod +x /home/polymesh/*.start"
	done

	startServices $sentryaName sentry
	sentryaPeerID=$(getpeerID $sentryaName)
	echo "Sentrya PeerId: "$sentryaPeerID

	startServices $sentrybName sentry
	sentrybPeerID=$(getpeerID $sentrybName)
	echo "Sentryb PeerId: ""$sentrybPeerID"
}

## Configure Operator 
configureOperator(){
	echo "Configure OperatorID"
	echo "Operator PeerId: ""$operatorPeerID"
	echo "Sentrya PeerId: ""$sentryaPeerID"
	echo "Sentryb PeerId: ""$sentrybPeerID"
	lxc exec $operatorName -- sh -c "echo '#!/bin/bash \n/usr/local/bin/polymesh --operator --name $operatorName  --prometheus-external --reserved-only --reserved-nodes /ip4/$sentryaIP/tcp/30333/p2p/$sentryaPeerID /ip4/$sentrybIP/tcp/30333/p2p/$sentrybPeerID' > /home/polymesh/operator.start" 
	lxc exec $operatorName -- sh -c "chown polymesh:polymesh /home/polymesh/*.start && chmod +x /home/polymesh/*.start"
	startServices $operatorName operator
}

PS3="Select the step: "

select opt in 'Create containers' 'Destroy containers' 'Configure network' 'Start containers' 'Stop containers' 'Install binaries' 'Initialise operator' 'Initialise sentries' 'Configure operator' 'Quit'; do

  case $opt in
    'Create containers')
    	createContainers
		;;
	'Destroy containers')
		destroyContainers
		;;	
    'Configure network')
    	configureNetwork
		;;
    'Start containers')
    	startContainers
		;;
    'Stop containers')
    	stopContainers
		;;
	'Install binaries')
		installBinaries
    	;;
	'Initialise operator')
    	initialiseOperator
		;;
	'Initialise sentries')
    	initialiseSentry
		;;
	'Configure operator')
		configureOperator
		;;
    quit)
      break
      ;;
    *)
      echo "Invalid option $REPLY"
      ;;
  esac
done