sudo yum install -y openldap-clients nss-pam-ldapd
sudo authconfig --enableldap --enableldapauth --ldapserver="10.10.1.11"--ldapbasedn="dc=ldap,dc=devopslab,dc=local" --enablemkhomedir --update
systemctl restart nslcd
