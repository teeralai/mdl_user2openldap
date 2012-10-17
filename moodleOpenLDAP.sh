#!/bin/bash
# Moodle2OpenLDAP
# Script for migrate Moodle users to OpenLDAP
#
# Platform: Ubuntu Server 12.04.1 LTS  
# Linux ubuntu 3.2.0-23-generic-pae i686 GNU/Linux
# Required files: 
#	mdl_user2LDIF.pl
#	backend.isag22.ce.kmitl.ac.th.ldif
#	init_isag22.ldif
#
# Test environment: 
#	domain: isag22.ce.kmitl.ac.th
#	Moodle 1.9 > Moodle 2.3
# 
# TODO
# - correct mdl_user2LDIF.pl to the latest configuration
# - syncing with moodle authentication (php_ldap),
#	configuration from Moodle's manual doesn't work (It's refer to MS AD)

# Unclean LDAP Configuration
#sudo apt-get purge slapd ldap-utils db5.1-util db-util
#sudo rm /var/lib/ldap/*
#sudo apt-get install slapd ldap-utils db5.1-util db-util


# Pull mdl_user from Moodle's MySQL Database into LDIF
sudo bash -c 'mdl_user2LDIF.pl > myldif'


# After pulled/edited LDIF files
# edit ~/ path where your ldif files are
 sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ~/backend.isag22.ce.kmitl.ac.th.ldif
 sudo ldapadd -x -D cn=admin,dc=isag22,dc=ce,dc=kmitl,dc=ac,dc=th -W -f ~/init_isag22.ldif

# Test OpenLDAP Query
 ldapsearch -D "cn=admin,dc=isag22,dc=ce,dc=kmitl,dc=ac,dc=th" -w qwerty -h localhost -b "dc=isag22,dc=ce,dc=kmitl,dc=ac,dc=th" "(objectClass=*)"
