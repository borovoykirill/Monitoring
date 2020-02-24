#!/bin/bash

# Install LDAP server, create passwd for admin and user
sudo yum update -y
sudo yum -y install epel-release
sudo yum -y install openldap openldap-servers openldap-clients

sudo systemctl enable slapd
sudo systemctl start slapd

sudo slappasswd -h {SSHA} -s qwerty123 > admldappasswd.txt
ADMPASS=$(cat "admldappasswd.txt")

sudo slappasswd -h {SSHA} -s qazWSX321 > usrldappasswd.txt
USRPASS=$(cat "usrldappasswd.txt")

# Configuring LDAP Server
cat <<EOF > ldaprootpasswd.ldif
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $ADMPASS
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ldaprootpasswd.ldif

# Configuring LDAP Database
sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat <<EOF > ldapdomain.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
  read by dn.base="cn=ldapadm,dc=epam,dc=devopslab,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=epam,dc=devopslab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=epam,dc=devopslab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $ADMPASS

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=ldapadm,dc=epam,dc=devopslab,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=ldapadm,dc=epam,dc=devopslab,dc=com" write by * read
EOF

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ldapdomain.ldif

cat <<EOF > ldapdomain.ldif
dn: dc=epam,dc=devopslab,dc=com
dc: epam
objectClass: top
objectClass: dcObject
objectClass: organization
o: epam devopslab com

dn: cn=ldapadm,dc=epam,dc=devopslab,dc=com
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager

dn: ou=People,dc=epam,dc=devopslab,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=epam,dc=devopslab,dc=com
objectClass: organizationalUnit
ou: Group
EOF

sudo ldapadd -x -w qwerty123 -D "cn=ldapadm,dc=epam,dc=devopslab,dc=com" -f ldapdomain.ldif

cat <<EOF > group.ldif
dn: cn=ldapadm,ou=Group,dc=epam,dc=devopslab,dc=com
objectClass: top
objectClass: posixGroup
gidNumber: 1005
EOF

sudo ldapadd -x -w qwerty123 -D "cn=ldapadm,dc=epam,dc=devopslab,dc=com" -f group.ldif

cat <<EOF > ldapuser.ldif
dn: uid=user,ou=People,dc=epam,dc=devopslab,dc=com
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: epamer
uid: epamer
uidNumber: 1005
gidNumber: 1005
homeDirectory: /home/epamer
userPassword: $USRPASS
loginShell: /bin/bash
gecos: user
shadowLastChange: 0
shadowMax: -1
shadowWarning: 0
EOF

ldapadd -x -D "cn=ldapadm,dc=epam,dc=devopslab,dc=com" -w qwerty123 -f ldapuser.ldif

# Install php_ldap_admin
sudo yum -y install phpldapadmin

sudo sed -i '397 s;// $servers;$servers;' /etc/phpldapadmin/config.php
sudo sed -i '398 s;$servers->setValue;// $servers->setValue;' /etc/phpldapadmin/config.php
sudo sed -i "s@// \$servers->setValue('login','attr','dn');@\$servers->setValue('login','attr','dn');@" /etc/phpldapadmin/config.php
sudo sed -i "s@\$servers->setValue('login','attr','uid');@// \$servers->setValue('login','attr','uid');@" /etc/phpldapadmin/config.php
sudo sed -i 's;Require local;Require all granted;' /etc/httpd/conf.d/phpldapadmin.conf
sudo sed -i 's;Allow from 127.0.0.1;Allow from 0.0.0.0;' /etc/httpd/conf.d/phpldapadmin.conf

sudo systemctl restart httpd
