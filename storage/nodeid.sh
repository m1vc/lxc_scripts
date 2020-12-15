#!/bin/bash
curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_localPeerId"}' http://localhost:9933/ > /usr/local/etc/nodeid