#!/bin/bash

sleep 30s

sudo yum update -y
sudo yum -y install wget
sudo yum -y install epel-release

# Install Zabbix agent
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm

sudo yum -y install zabbix-agent
sudo systemctl start zabbix-agent
sudo systemctl enable zabbix-agent

# Configure Zabbix agent
sudo sed -i 's@Server=127.0.0.1@Server=10.10.1.11@' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's@ServerActive=127.0.0.1@ServerActive=10.10.1.11@' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's@Hostname=Zabbix server@Hostname=tomcat01@' /etc/zabbix/zabbix_agentd.conf

sudo systemctl restart zabbix-agent

# Install and configure Tomcat
sudo yum -y install java-1.8.0-openjdk-devel

sudo groupadd tomcat
sudo mkdir /opt/tomcat
sudo useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat
sudo wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.51/bin/apache-tomcat-8.5.51.tar.gz
sudo tar -axvf apache-tomcat-8.5.51.tar.gz -C /opt/tomcat --strip-components=1
sudo cd /opt/tomcat
sudo chown -R tomcat: /opt/tomcat

sudo cat << END > /etc/systemd/system/tomcat.service
[Unit]

Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]

Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID
User=tomcat
Group=tomcat

[Install]

WantedBy=multi-user.target
END

sudo sed -i 's+<Context>+<Context allowCasualMultipartParsing="true">+g' /opt/tomcat/conf/context.xml

sudo cat << EOF > /opt/tomcat/bin/setenv.sh
export JAVA_OPTS="-Dcom.sun.management.jmxremote=true \
					-Dcom.sun.management.jmxremote.port=12345 \
					-Dcom.sun.management.jmxremote.rmi.port=12346 \
					-Dcom.sun.management.jmxremote.ssl=false \
					-Dcom.sun.management.jmxremote.authenticate=false \
					-Djava.rmi.server.hostname=10.10.1.10"
EOF

sudo systemctl enable tomcat
sudo systemctl start tomcat

# Configure JMX for monitoring via Zabbix
sudo wget -P /opt/tomcat/lib/ http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.51/bin/extras/catalina-jmx-remote.jar

# Deploy application
sudo wget -P /opt/tomcat/webapps/ https://community.jboss.org/servlet/JiveServlet/download/588259-27006/clusterjsp.war

sudo sed -i '/<Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" \/>/a <Listener className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener" rmiRegistryPortPlatform="8097" rmiServerPortPlatform="8098" \/>' /opt/tomcat/conf/server.xml

sudo systemctl restart tomcat

# Autoregister host, use Linux template.
sleep 200s

# Zabbix server IP = 10.10.1.11
# Host ip = 10.10.1.10
# Name of new host = tomcat01
# URL zabbix server = http://10.10.1.11/zabbix/api_jsonrpc.php

# Take Token id
user_login=`curl -sS -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"params\": {\"password\": \"zabbix\", \"user\": \"Admin\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.login\", \"id\": 0}" "http://10.10.1.11/zabbix/api_jsonrpc.php"`
TOKEN=`echo $user_login | sed -n 's/.*result":"\(.*\)",.*/\1/p'`

# Take Group id
group_id=`curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.get\",\"params\":{\"output\":\"extend\",\"filter\":{\"name\":[\"Linux servers\"]}},\"auth\":\"$TOKEN\",\"id\":0}" "http://10.10.1.11/zabbix/api_jsonrpc.php"`
HOSTGROUPID=`echo $group_id | cut -d '"' -f 10 `

# Take Tempalte ID
template_id=`curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"template.get\",\"params\":{\"output\":\"extend\",\"filter\":{\"host\":[\"Template OS Linux by Zabbix agent\"]}},\"auth\":\"$TOKEN\",\"id\":0}" "http://10.10.1.11/zabbix/api_jsonrpc.php"`
TEMPLATEID=`echo $template_id | cut -d '"' -f 130 `

# Create new host: tomcat01
outs=`curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\":{\"host\":\"tomcat01\",\"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"10.10.1.10\",\"dns\":\"\",\"port\":\"10050\"}],\"groups\":[{\"groupid\":\"$HOSTGROUPID\"}],\"templates\":[{\"templateid\":\"$TEMPLATEID\"}]},\"auth\":\"$TOKEN\",\"id\":1}" "http://10.10.1.11/zabbix/api_jsonrpc.php"`
