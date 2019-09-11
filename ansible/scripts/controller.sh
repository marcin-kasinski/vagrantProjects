#!/bin/bash

echo I am controller...

sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

#generate key
#ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
#ssh-copy-id vagrant@192.168.1.12

#ansible -m ping all -i /vagrant/playbooks/inventory

#get fingerprint
ssh-keygen -lf ~/.ssh/id_rsa.pub
#get fingerprint MD5
ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub


#listowanie
ssh-agent bash
ssh-add ~/.ssh/id_rsa
ssh-add -l
ssh-add -l -E MD5
ssh-add -l -E ECDSA



#ssh -i ./.ssh/id_rsa vagrant@192.168.1.12
#ssh vagrant@192.168.1.12
