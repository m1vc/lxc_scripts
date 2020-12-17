#!/bin/bash
sudo ufw status
lxd sql global "SELECT  c.name, a.name, b.value FROM instances_devices a LEFT JOIN instances_devices_config b LEFT JOIN instances c WHERE a.id=b.instance_device_id AND a.instance_id = c.id AND a.type=8 AND b.key='listen';"
#lxd sql global "SELECT * FROM instances;"
#lxd sql global "SELECT * FROM instances_devices WHERE type=8;"
#lxd sql global "SELECT * FROM instances_devices_config;"

lxd sql global "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%';"
lxd sql global "SELECT * FROM schema;"
lxd sql global "SELECT * FROM schema;"

lxd sql global "SELECT * FROM (SELECT storage_pool_id, [key], [value] FROM storage_pools_config) AS c left join storage_pools b WHERE c.storage_pool_id=b.id and key='size'"

lxd sql global "SELECT b.name, a.value "Size" FROM storage_pools_config a left join storage_pools b WHERE a.storage_pool_id=b.id and key='size'"
