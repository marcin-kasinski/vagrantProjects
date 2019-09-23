#!/bin/bash
apt-get update
apt-get install -y nginx docker.io vim lvm2
sudo lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL