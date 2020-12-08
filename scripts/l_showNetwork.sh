#!/bin/bash
sudo ufw status
lxd sql global "SELECT  c.name, a.name, b.value FROM instances_devices a LEFT JOIN instances_devices_config b LEFT JOIN instances c WHERE a.id=b.instance_device_id AND a.instance_id = c.id AND a.type=8 AND b.key='listen';"
#lxd sql global "SELECT * FROM instances;"
#lxd sql global "SELECT * FROM instances_devices WHERE type=8;"
#lxd sql global "SELECT * FROM instances_devices_config;"

