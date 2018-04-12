
	CREATE DATABASE test;
    use test;
	
	CREATE TABLE test.users (
	  id bigint(20) NOT NULL,
	  email varchar(255) DEFAULT NULL,
	  name varchar(255) DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;
	
	
	INSERT INTO test.users (id,email, name) VALUES (1 , 'x@x.com','Marcin');
	INSERT INTO test.users (id,email, name) VALUES (2 , 'z@fromlistener.com','Marcin from listener');
	INSERT INTO test.users (id,email, name) VALUES (3 , 'ajax@ajax.com','AJAX');
