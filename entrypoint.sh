#!/bin/bash

chkconfig --level 2345 httpd on
chkconfig --level 2345 mysqld on
chkconfig --level 2345 munge on

cp -pr /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib64/mysql/plugin

cd /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/
mv oph_configuration oph_configuration.orig
mv oph_dim_configuration oph_dim_configuration.orig

(
cat <<'EOF'
MAPPER_DB_NAME=ophidiadb
MAPPERDB_HOST=127.0.0.1
MAPPERDB_PORT=3306
MAPPERDB_LOGIN=root
MAPPERDB_PWD=1OphiDia0
WEB_SERVER=http://127.0.0.1/ophidia
WEB_SERVER_LOCATION=/var/www/html/ophidia
MEMORY=2048
EOF
) > oph_configuration

(
cat <<'EOF'
MAPPER_DB_NAME=oph_dimensions
MAPPERDB_HOST=127.0.0.1
MAPPERDB_PORT=3306
MAPPERDB_LOGIN=root
MAPPERDB_PWD=1OphiDia0
EOF
) > oph_dim_configuration

cd /usr/local/ophidia/oph-server/etc/
mv ophidiadb.conf ophidiadb.conf.orig
(
cat <<'EOF'
MAPPER_DB_NAME=ophidiadb
MAPPERDB_HOST=127.0.0.1
MAPPERDB_PORT=3306
MAPPERDB_LOGIN=root
MAPPERDB_PWD=1OphiDia0
EOF
) > ophidiadb.conf


service mysqld start
service httpd start
service munge start

mysqladmin -u root password '1OphiDia0'
echo "[client]"> /root/.my.cnf
echo "password=1OphiDia0" >> /root/.my.cnf
mysql -u root password mysql < /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql

echo "create database ophidiadb;"|mysql -u root
echo "create database oph_dimensions;"|mysql -u root
mysql -u root ophidiadb < /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/ophidiadb.sql
echo "INSERT INTO host (hostname, cores, memory) VALUES ('127.0.0.1',4,1);" | mysql -u root ophidiadb
echo "INSERT INTO dbmsinstance (idhost, login, password, port) VALUES (1, 'root', '1OphiDia0', 3306);" | mysql -u root ophidiadb
echo "INSERT INTO hostpartition (partitionname) VALUES ('test');" | mysql -u root ophidiadb
echo "INSERT INTO hashost VALUES (1,1);" | mysql -u root ophidiadb

/usr/local/ophidia/oph-server/bin/oph_server -d > /dev/null 2> /dev/null &
/usr/local/ophidia/oph-terminal/bin/oph_term -H 127.0.0.1 -u oph-test -p abcd -P 11732

exec "$@"