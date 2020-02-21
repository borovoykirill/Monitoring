#!/bin/bash

sudo yum update -y
sudo yum -y install openldap openldap-servers openldap-servers-sql openldap-devel compat-openldap openldap-clients
sudo systemctl enable slapd
sudo systemctl start slapd
sudo slappasswd -h {SSHA} -s qwerty > passwd.txt
passwd=$(cat "passwd.txt")

cat <<EOF>database.ldif
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=ldap,dc=devopslab,dc=local

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=ldap,dc=devopslab,dc=local

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $passwd
EOF

sudo ldapmodify -Y EXTERNAL  -H ldapi:/// -f database.ldif

cat <<EOF>monitor.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=ldap,dc=devopslab,dc=local" read by * none
EOF

sudo ldapmodify -Y EXTERNAL  -H ldapi:/// -f monitor.ldif

sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
# sudo systemctl restart slapd

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat <<EOF>base.ldif
dn: dc=ldap,dc=devopslab,dc=local
dc: ldap
objectClass: top
objectClass: domain

dn: cn=ldapadm ,dc=ldap,dc=devopslab,dc=local
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager

dn: ou=Peoples,dc=ldap,dc=devopslab,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=ldap,dc=devopslab,dc=local
objectClass: organizationalUnit
ou: Group
EOF

sudo ldapadd -x -W -D "cn=ldapadm,dc=ldap,dc=devopslab,dc=local" -f base.ldif

sudo useradd admin
sudo passwd admin

cat <<EOF>group.ldif
dn: cn=Manager,ou=Group,dc=devopslab,dc=local
objectClass: top
objectClass: posixGroup
gidNumber: 1002
EOF

sudo ldapadd -Y EXTERNAL -x  -W -D "cn=Manager,dc=devopslab,dc=local" -f group.ldif

sudo -u super_user sudo groupadd -g "$((7000$i))" user$i
sudo -u super_user sudo useradd -p -U -u "$((9000$i))" -g "$((7000$i))" -s /bin/sh -m user$i -c "DevOps_Student_Lab"
