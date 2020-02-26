#!/bin/bash

sleep 99s

sudo yum update -y
sudo yum -y install wget

# Install Zabbix agent
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm

sudo yum -y install zabbix-agent
sudo systemctl start zabbix-agent
sudo systemctl enable zabbix-agent

# Configure Zabbix agent
sudo sed -i 's@Server=127.0.0.1@Server=10.10.1.11@' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's@ServerActive=127.0.0.1@ServerActive=10.10.1.11@' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's@Hostname=Zabbix server@Hostname=host01@' /etc/zabbix/zabbix_agentd.conf

sudo systemctl restart zabbix-agent

# Install Tomcat
sudo yum -y install java-1.8.0-openjdk-devel
sudo yum -y install tomcat
sudo yum -y install tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp tomcat-javadoc
sudo systemctl start tomcat
sudo systemctl enable tomcat

# Deploy application
sudo wget -P /usr/share/tomcat/webapps https://community.jboss.org/servlet/JiveServlet/download/588259-27006/clusterjsp.war

sudo systemctl restart tomcat
