#!/bin/bash

sleep 99s

sudo yum -y update

# Disable SELINUX only for current session
sudo setenforce 0

# Install the required PHP extensions
sudo yum -y install php php-pear php-cgi php-common php-mbstring php-snmp php-gd php-xml php-mysql php-gettext php-bcmath

# Set PHP timezone
sudo sed -i "s/^;date.timezone =$/date.timezone = \"Europe\/Minsk\"/" /etc/php.ini

# Configure Zabbix repository
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm

# Install Zabbix
sudo yum -y install -y zabbix-server-mysql zabbix-web-mysql zabbix-agent

# Timezone for Zabbix
sudo sed -i 's@# php_value date.timezone Europe/Riga@php_value date.timezone Europe/Minsk@' /etc/httpd/conf.d/zabbix.conf

# Install MariaDB
sudo yum install -y mariadb-server mariadb

sudo systemctl enable mariadb
sudo systemctl start mariadb

# Create DB for Zabbix and DB connection
export zabbix_db_pass="zabbix"
mysql -uroot <<MYSQL_SCRIPT
    create database zabbix character set utf8 collate utf8_bin;
    grant all privileges on zabbix.* to zabbix@'localhost' identified by '${zabbix_db_pass}';
    FLUSH PRIVILEGES;
MYSQL_SCRIPT

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix

sudo sed -i 's@# DBPassword=@DBPassword=zabbix@' /etc/zabbix/zabbix_server.conf

# Disable pre-instalattion
DB='$DB'
ZBX_SERVER='$ZBX_SERVER'
ZBX_SERVER_PORT='$ZBX_SERVER_PORT'
ZBX_SERVER_NAME='$ZBX_SERVER_NAME'
IMAGE_FORMAT_DEFAULT='$IMAGE_FORMAT_DEFAULT'

cat <<EOF>/etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file
global $DB;

$DB['TYPE']     = 'MYSQL';
$DB['SERVER']   = 'localhost';
$DB['PORT']     = '0';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'zabbix';

// SCHEMA is relevant only for IBM_DB2 database
$DB['SCHEMA'] = '';

$ZBX_SERVER      = 'localhost';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = 'zabbix';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF

# Launch Web for Zabbix
sudo systemctl restart httpd

# Launch Zabbix
sudo systemctl restart zabbix-server

# Disable SeLinux after launch zabbix, after that you have to reboot Gest OS
sudo sed -i 's/^SELINUX=.*/SELINUX=disable/g' /etc/selinux/config
