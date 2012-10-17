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