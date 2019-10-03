#!/bin/bash
source /vagrant/scripts/centoslibs.sh


cat /etc/centos-release

installAnsible
installPacker
installTerraform

chmod u+x /vagrant/install/Rapid7Setup-Linux64.bin

echo I am controller...


exit

installDocker()
{
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt-cache policy docker-ce
sudo apt install docker-ce -y 
sudo usermod -aG docker vagrant


sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
}



sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
sudo apt-get install -y unzip

#generate key
#ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
#ssh-copy-id vagrant@192.168.1.12
#export ANSIBLE_HOST_KEY_CHECKING=False
#ansible -m ping all -i /vagrant/playbooks/inventory

#ansible-playbook -i /vagrant/playbooks/inventory /vagrant/playbooks/nginx_install.yml -b
#ansible-playbook -i /vagrant/playbooks/inventory /vagrant/playbooks/nginx_all.yml -b

#roles
#ansible-playbook -i /vagrant/playbooks/inventory /vagrant/playbooks/roles_example/main.yml --extra-vars env=dev -b --ask-vault-pass
#ansible-playbook -i /vagrant/playbooks/inventory /vagrant/playbooks/nexpose_example/main_console.yml
#ansible-playbook -i /vagrant/playbooks/inventory /vagrant/playbooks/nexpose_example/main_engine.yml


#EDITOR=nano ansible-vault create /vagrant/playbooks/roles_sexample/vault.yml

#Wprowadzić poniższą wartość
#vault_mysql_password: supersecretpassword



#disable host key checking

sudo sed -i -e "s/#host_key_checking = False/host_key_checking = False/g" /etc/ansible/ansible.cfg 
cat /etc/ansible/ansible.cfg | grep check

# -b run as root on target host
#ansible -m ping all -i /vagrant/playbooks/inventory -b 

#get fingerprint
#ssh-keygen -lf ~/.ssh/id_rsa.pub
#get fingerprint MD5
#ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub


#listowanie
#ssh-agent bash
#ssh-add ~/.ssh/id_rsa
#ssh-add -l
#ssh-add -l -E MD5
#ssh-add -l -E ECDSA



#ssh -i ./.ssh/id_rsa vagrant@192.168.1.12
#ssh vagrant@192.168.1.12

#list fingerprints
cd ~/.ssh
find . -type f -exec printf "\n{}\n" \; -exec ssh-keygen -E md5 -lf {} \;


installDocker

cd /vagrant/terraform/demo
terraform init
ssh-keygen -t rsa -N "" -f /vagrant/terraform/mykey
#terraform plan 
#terraform apply -auto-approve
#terraform destroy -auto-approve
#terraform graph | dot -Tsvg > graph.svg

#ssh -i /vagrant/terraform/mykey ubuntu@52.200.183.2

echo Controller finished...
