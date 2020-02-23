#!/bin/bash

# Install LDAP client
sudo yum update -y
sudo yum -y install openldap-clients nss-pam-ldapd

# Timeout until the server is installed
sleep 99s

# Add client's VM in LDAP
sudo authconfig --enableldap --enableldapauth --ldapserver=10.10.1.11 --ldapbasedn="dc=epam,dc=devopslab,dc=com" --enablemkhomedir --update
sudo sed -i ' s;PasswordAuthentication no;PasswordAuthentication yes;' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo systemctl restart nslcd
