
#dba.checkInstanceConfiguration('root@localhost:3306');

#dba.configureLocalInstance('root@localhost:3306', {password: 'Secretqaz@wsx123'});

#shell.connect('root@192.168.44.10:3306', 'Secretqaz@wsx123');
#var cluster = dba.createCluster('myCluster');
#cluster.status();
#cluster.addInstance('root@192.168.44.11:3306', {password: 'Secretqaz@wsx123'});
#cluster.addInstance('root@192.168.44.12:3306', {password: 'Secretqaz@wsx123'});
#cluster.status();


var cluster = dba.getCluster('myCluster');
