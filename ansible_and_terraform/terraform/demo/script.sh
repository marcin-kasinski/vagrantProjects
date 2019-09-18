#!/bin/bash

displayPublicIP()
{
echo "tst" > /tmp/tst.txt
local PUBLIC_IP=$1

echo "$PUBLIC_IP" > /tmp/public_ip.txt
cat /tmp/public_ip.txt

ls -l /tmp/
echo "PUBLIC_IP $PUBLIC_IP"

echo "to connect run:"
echo "ssh -i /vagrant/terraform/mykey ubuntu@$PUBLIC_IP"

}

processnginx()
{
# install nginx
apt-get update
apt-get -y install nginx

# make sure nginx is started
service nginx start
curl http://localhost
}

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

processnginx
echo "executing displayPublicIP with input $1"
displayPublicIP $1