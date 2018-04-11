
	CREATE DATABASE test;
    use test;
	
	CREATE TABLE users (
	  id bigint(20) NOT NULL,
	  email varchar(255) DEFAULT NULL,
	  name varchar(255) DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;
	
	
	INSERT INTO users (id,email, name) VALUES (1 , 'x@x.com','Marcin');
	INSERT INTO users (id,email, name) VALUES (2 , 'z@fromlistener.com','Marcin from listener');
	INSERT INTO users (id,email, name) VALUES (2 , 'ajax@ajax.com','AJAX');
