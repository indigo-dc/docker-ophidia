#!/bin/bash

PASS=${UPASS:-1OphiDia0}

ldconfig -n /usr/local/ophidia/extra/lib/
echo -e "\n\nexport PATH=$PATH:/usr/local/ophidia/extra/bin/" >> ~/.bashrc

ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

chkconfig --level 2345 httpd on
chkconfig --level 2345 mysqld on
chkconfig --level 2345 munge on
chkconfig --level 2345 sshd on

OPH_DIR=/usr/local/ophidia

cp -pr ${OPH_DIR}/oph-cluster/oph-primitives/lib/liboph_*.so \
    /usr/lib64/mysql/plugin

cd ${OPH_DIR}/oph-cluster/oph-analytics-framework/etc/
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

cd ${OPH_DIR}/oph-server/etc/
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

mv server.conf server.conf.orig
(
cat <<'EOF'
TIMEOUT=3600
INACTIVITY_TIMEOUT=31536000
WORKFLOW_TIMEOUT=2592000
LOGFILE=/usr/local/ophidia/oph-server/log/server.log
CERT=/usr/local/ophidia/oph-server/etc/cert/myserver.pem
CA=/usr/local/ophidia/oph-server/etc/cert/cacert.pem
CERT_PASSWORD=1OphiDia0
RMANAGER_CONF_FILE=/usr/local/ophidia/oph-server/etc/rmanager.conf
AUTHZ_DIR=/usr/local/ophidia/oph-server/authz
TXT_DIR=/usr/local/ophidia/oph-server/txt
WEB_SERVER=http://127.0.0.1/ophidia
WEB_SERVER_LOCATION=/var/www/html/ophidia
OPERATOR_CLIENT=/usr/local/ophidia/oph-cluster/oph-analytics-framework/bin/oph_analytics_framework
IP_TARGET_HOST=127.0.0.1
SUBM_USER=root
SUBM_USER_PUBLK=/root/.ssh/id_dsa.pub
SUBM_USER_PRIVK=/root/.ssh/id_dsa
OPH_XML_URL=http://127.0.0.1/ophidia/operators_xml
OPH_XML_DIR=/usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/operators_xml
NOTIFIER=framework
SERVER_FARM_SIZE=2
QUEUE_SIZE=0
HOST=127.0.0.1
PORT=11732
PROTOCOL=https
EOF
) > server.conf

cd ${OPH_DIR}/oph-server/etc/cert
openssl req -newkey rsa:1024 \
    -passout pass:1OphiDia0 \
    -subj "/" -sha1 \
    -keyout rootkey.pem \
    -out rootreq.pem

openssl x509 -req -in rootreq.pem \
    -passin pass:1OphiDia0 \
    -sha1 -extensions v3_ca \
    -signkey rootkey.pem \
    -out rootcert.pem

cat rootcert.pem rootkey.pem  > cacert.pem
openssl req -newkey rsa:1024 \
    -passout pass:1OphiDia0 \
    -subj "/" -sha1 \
    -keyout serverkey.pem \
    -out serverreq.pem

openssl x509 -req \
    -in serverreq.pem \
    -passin pass:1OphiDia0 \
    -sha1 -extensions usr_cert \
    -CA cacert.pem  \
    -CAkey cacert.pem \
    -CAcreateserial \
    -out servercert.pem

cat servercert.pem serverkey.pem rootcert.pem > myserver.pem
cd ${OPH_DIR}/extra/etc/
touch slurm.conf

(
cat <<'EOF'
ControlMachine=localhost
ControlAddr=127.0.0.1
AuthType=auth/munge
CryptoType=crypto/munge
MpiDefault=none
ProctrackType=proctrack/pgid
ReturnToService=1
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=root
StateSaveLocation=/var/spool/slurmd
SwitchType=switch/none
TaskPlugin=task/none
# SCHEDULING
FastSchedule=1
SchedulerType=sched/backfill
SelectType=select/linear
# LOGGING AND ACCOUNTING
AccountingStorageType=accounting_storage/none
ClusterName=cluster
JobCompType=jobcomp/none
JobAcctGatherType=jobacct_gather/none
SlurmctldDebug=3
SlurmctldLogFile=/var/log/slurmctld.log
SlurmdDebug=3
SlurmdLogFile=/var/log/slurmd.log
# COMPUTE NODES
NodeName=localhost NodeAddr=127.0.0.1 CPUs=1 RealMemory=1024 Sockets=1 CoresPerSocket=1 ThreadsPerCore=1 State=UNKNOWN
PartitionName=debug Nodes=localhost Default=YES MaxTime=INFINITE State=UP
EOF
) > slurm.conf

id -u centos &>/dev/null || \
    useradd --create-home --shell /bin/bash --user-group --groups adm centos
echo "centos:$PASS" | chpasswd
echo "centos ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

service mysqld start
service httpd start
service munge start
service sshd start

${OPH_DIR}/extra/sbin/slurmd
${OPH_DIR}/extra/sbin/slurmctld

mysqladmin -u root password '1OphiDia0'
echo "[client]"> /root/.my.cnf
echo "password=1OphiDia0" >> /root/.my.cnf
mysql -u root mysql < ${OPH_DIR}/oph-cluster/oph-primitives/etc/create_func.sql

echo "create database ophidiadb;"|mysql -u root
echo "create database oph_dimensions;"|mysql -u root
mysql -u root ophidiadb < \
    ${OPH_DIR}/oph-cluster/oph-analytics-framework/etc/ophidiadb.sql
echo "INSERT INTO host (hostname, cores, memory) VALUES ('127.0.0.1',4,1);" | \
    mysql -u root ophidiadb
echo "INSERT INTO dbmsinstance (idhost, login, password, port) VALUES (1, 'root', '1OphiDia0', 3306);" | \
    mysql -u root ophidiadb
echo "INSERT INTO hostpartition (partitionname) VALUES ('test');" | \
    mysql -u root ophidiadb
echo "INSERT INTO hashost VALUES (1,1);" | \
    mysql -u root ophidiadb

${OPH_DIR}/oph-server/bin/oph_server -d > /dev/null 2> /dev/null &
sleep 2
${OPH_DIR}/oph-terminal/bin/oph_term -H 127.0.0.1 -u oph-test -p abcd -P 11732
exec "$@"
