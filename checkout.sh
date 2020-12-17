#!/bin/bash
git add ./scripts
git add ./storage
git add ./
git commit -m 'Parametrised hostname in service files'
git push https://m1vc:dia1311nina@github.com/m1vc/lxc_scripts.git

#git pull -p

#curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_localPeerId"}' http://localhost:9933/ 

#!/bin/bash
#OPTIONS="Hello Quit"
#select opt in $OPTIONS; do
#    if [ "$opt" = "Quit" ]; then
#        echo done
#        exit
#    elif [ "$opt" = "Hello" ]; then
#        echo Hello World
#    else
#        clear
#        echo bad option
#    fi
#done
