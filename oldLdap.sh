#!/bin/sh
passwd=qwerty
dc1=isag22
dc2=ce
dc3=kmitl
dc4=ac
dc5=th
hash_pw=`slappasswd -s $passwd`
tmpdir=/tmp
#--------------------------------------------------------------#
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/misc.ldif
#——————————————————————-#
# database.ldif
#——————————————————————-#
cat <<EOF > $tmpdir/database.ldif
# Load dynamic backend modules
dn: cn=module{0},cn=config
objectClass: olcModuleList
cn: module{0}
olcModulePath: /usr/lib/ldap
olcModuleLoad: {0}back_hdb
 
# Create directory database
dn: olcDatabase={1}hdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: {1}hdb
olcDbDirectory: /var/lib/ldap
olcSuffix: dc=$dc1,dc=$dc2,dc=$dc3,dc=$dc4,dc=$dc5
olcRootDN: cn=admin,dc=$dc1,dc=$dc2,dc=$dc3,dc=$dc4,dc=$dc5
olcRootPW: $hash_pw
olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=admin,dc=$dc1,dc=$dc2,dc=$dc3,dc=$dc4,dc=$dc5" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=admin,dc=$dc1,dc=$dc2,dc=$dc3,dc=$dc4,dc=$dc5" write by * read
olcLastMod: TRUE
olcDbCheckpoint: 512 30
olcDbConfig: {0}set_cachesize 0 2097152 0
olcDbConfig: {1}set_lk_max_objects 1500
olcDbConfig: {2}set_lk_max_locks 1500
olcDbConfig: {3}set_lk_max_lockers 1500
olcDbIndex: uid pres,eq
olcDbIndex: cn,sn,mail pres,eq,approx,sub
olcDbIndex: objectClass eq
################################
#        Modifications
################################
 
dn: cn=config
changetype: modify
 
dn: olcDatabase={-1}frontend,cn=config
changetype: modify
delete: olcAccess
 
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootDN
olcRootDN: cn=admin,cn=config
 
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $hash_pw
 
dn: olcDatabase={0}config,cn=config
changetype: modify
delete: olcAccess
EOF
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f $tmpdir/database.ldif
####################################
#         Mini DIT
####################################
cat <<EOF> $tmpdir/dit.ldif
# Tree root
 
dn: dc=$dc1,dc=$dc2,dc=$dc3,dc=$dc4,dc=$dc5
objectClass: dcObject
objectclass: organization
o: $dc1.$dc2,dc=$dc3,dc=$dc4,dc=$dc5
dc: $dc1
description: Tree root
 
# Populating

EOF

cat <<EOF> $tmpdir/moo2ldif.pl
#!/usr/bin/perl -w

use MIME::Base64 qw(encode_base64);
use DBI;

# ----- Configure these values below to match your moodle setup -------#
$moodle_db = 'moodle19';
$moodle_user = 'root';
$moodle_password = 'qwerty';

# ----- Configure these values below to match your LDAP setup ------#
$ou = 'ou=moodleusers,dc=isag22,dc=ce,dc=kmitl,dc=ac,dc=th';
$objectClass = 'inetOrgPerson';

# ----------------------------------------------------------------------------- #

$dbh = DBI->connect('DBI:mysql:'.$moodle_db, $moodle_user, $moodle_password);

$sth = $dbh->prepare('select username, firstname, lastname, email, password from mdl_user where deleted = 0 and id > 2');
$sth->execute();

while (@row = $sth->fetchrow_array()) {
        print "dn: cn=$row[0],$ou\n";
        print "objectClass: $objectClass\n";
        print "uid: $row[0]\n";
        print "givenName: $row[1]\n";
        print "sn: $row[2]\n";
        print "mail: $row[3]\n";
        if ($row[4] ne '') {
                $password = '{MD5}'. encode_base64(pack ("H32", $row[4]));
#               $password = '{MD5}'.$row[4];
                print "userPassword: $password\n";
        }
        print "\n";
}
$sth->finish();
$dbh->disconnect();

EOF

sudo $tmpdir/moo2ldif.pl > $tmpdir/moodleusers.ldif
cat $tmpdir/moodleusers.ldif >> $tmpdir/dit.ldif

sudo ldapadd -x -D cn=admin,dc=$dc1,dc=$dc2,dc=$dc3,dc=$dc4,dc=$dc5 -W -f $tmpdir/dit.ldif