#!/bin/bash

sleep 120s

sudo yum update -y

# Install Kibana
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat << EOF > /tmp/kibana.repo
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo cp /tmp/kibana.repo /etc/yum.repos.d/

sudo yum -y install kibana

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service

sudo systemctl start kibana.service

sudo sed -i 's@#server.host: "localhost"@server.host: "0.0.0.0"@' /etc/kibana/kibana.yml

sudo systemctl restart kibana.service

# Install Elastic
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat << EOF > /tmp/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF

sudo cp /tmp/elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo

sudo yum -y install --enablerepo=elasticsearch elasticsearch
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

sudo cat << EOF >> /etc/elasticsearch/elasticsearch.yml
network.host: 127.0.0.1
http.host: 0.0.0.0
action.auto_create_index: .monitoring*,.watches,.triggered_watches,.watcher-history*,.ml*
EOF

sudo systemctl restart elasticsearch
