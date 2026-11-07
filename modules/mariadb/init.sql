-- Local development credentials only. Runs once on first initialisation.
CREATE DATABASE IF NOT EXISTS `dev`;

-- `localhost` is used for unix sockets, `127.0.0.1` for TCP connections.
CREATE USER IF NOT EXISTS 'dev'@'localhost' IDENTIFIED BY 'dev';
CREATE USER IF NOT EXISTS 'dev'@'127.0.0.1' IDENTIFIED BY 'dev';

GRANT ALL PRIVILEGES ON `dev`.* TO 'dev'@'localhost';
GRANT ALL PRIVILEGES ON `dev`.* TO 'dev'@'127.0.0.1';

FLUSH PRIVILEGES;
