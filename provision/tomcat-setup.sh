#!/bin/bash

sleep 60s

sudo yum update -y
sudo yum -y install wget

# Install Tomcat
sudo yum -y install java-1.8.0-openjdk-devel
sudo yum -y install tomcat
sudo yum -y install tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp tomcat-javadoc
sudo systemctl start tomcat
sudo systemctl enable tomcat

# Install logstash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat << EOF > /tmp/logstash.repo
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo cp /tmp/logstash.repo /etc/yum.repos.d/

sudo yum -y install logstash
sudo systemctl enable logstash
sudo systemctl start logstash

cat << END > /tmp/logstash.conf
input {
 file {
  path => "/opt/tomcat/logs/*"
  start_position => "beginning"
  }
 }
output {
 elasticsearch {
  hosts => ["10.10.1.11:9200"]
 }
 stdout { codec => rubydebug }
}
END

sudo cp /tmp/logstash.conf /etc/logstash/conf.d/

# Deploy application
sudo wget -P /usr/share/tomcat/webapps https://community.jboss.org/servlet/JiveServlet/download/588259-27006/clusterjsp.war

sudo systemctl restart tomcat
sudo systemctl restart logstash

# Apply configure and start push log
sudo /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/logstash.conf
