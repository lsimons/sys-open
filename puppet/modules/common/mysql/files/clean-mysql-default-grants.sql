# no remote root, anonymous users or test db
DELETE FROM mysql.user WHERE User = 'root' AND Host != 'localhost';
DELETE FROM mysql.user WHERE User = '';
DELETE FROM mysql.db   WHERE Db = 'test';
DELETE FROM mysql.db   WHERE Db = 'test\_%';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
