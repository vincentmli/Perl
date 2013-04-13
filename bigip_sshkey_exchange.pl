#!/usr/bin/perl
#
# Establish ssh key auth trust between  BIG-IP and change syncer and sync_zones
# to use ssh channel instead of iqsh, this may only work for 10.x as
# v11.x deprecated syncer script with iqsyncer.
# vli@f5.com
#

use strict;
use POSIX;

# Auto flush when printing
$| = 1;

my @remote      = ();
my $ruser       = "";
my $ssh_pubkey  = "/var/ssh/root/identity.pub";
my $ssh_authkey = "/var/ssh/root/authorized_keys";
my $ssh         = "/usr/bin/ssh";

my $now_string = strftime "%H:%M:%S", localtime;

################################################
#
# Start of processing
#
################################################

if ( $< ne "0" ) {
    print "You must have root privileges to execute the script\n";
    exit -1;
}

if ( @ARGV > 0 ) {
    @remote = @ARGV;
}
else {
    print "$0 <remote ip>\n";
    exit 0;
}

#print "\nWhat user should access the remote system? [root] ";
#my $ruser = <STDIN>;
#chomp $ruser;
$ruser = "root";

my $cmd;

my $my_sshpubkey = "\n\n";
unless ( open( KEY, "<$ssh_pubkey" ) ) {
    print STDERR "ERROR: Can't read local ssh pub key file $ssh_pubkey.\n";
    exit -1;
}
while ( defined( $_ = <KEY> ) ) {
    $my_sshpubkey .= $_;
}
close KEY;

print "Retrieving remote and installing local BIG-IP's ssh pub key ...\n";

while ( @remote > 0 ) {
    my @ips = split /\t/, shift @remote;

    while ( @ips > 0 ) {
        my $remote = shift @ips;
        chomp $remote;
        print "Enter $ruser password for $remote if prompted\n";

        $cmd = "$ssh -l $ruser $remote ' " .

          # If the $ssh_pubkey exists just cat it into $their_key via the |
          "if [ -e $ssh_pubkey ]; then "
          . "cat $ssh_pubkey 2>/dev/null; " . "fi; "
          .

          # Prepend my ssh pub key remote $ssh_authkey
          "cp $ssh_authkey $ssh_authkey-$now_string 2> /dev/null; "
          . "echo \"$my_sshpubkey\" >> $ssh_authkey; "
          .

          # edit remote syncer and sync_zone in place to use ssh
          "mount -o remount,rw /usr 2>/dev/null; "
          . "sed -i\".$now_string\" -e 's/iqsh/ssh/' /usr/local/bin/syncer 2>/dev/null; "
          . "sed -i\".$now_string\" -e 's/iqsh/ssh/' /usr/local/bin/sync_zones 2>/dev/null; "
          . "mount -o remount,ro /usr 2>/dev/null; "
          .

          # turn off remote selinux so gtm can fork ssh
          "setenforce permissive 2>/dev/null; " . "' |";
        unless ( open( REMOTE, $cmd ) ) {
            print STDERR "ERROR: Can't read remote cert via $ssh.\n";
            next;
        }
        my $their_key = "";
        while ( defined( $_ = <REMOTE> ) ) {
            $their_key .= $_;
        }
        unless ( close REMOTE ) {
            print STDERR "ERROR: Can't read remote pub ssh key via $ssh.\n";
            next;
        }

        # backup local auth key and append remote pub key to local auth key
        system("cp $ssh_authkey $ssh_authkey-$now_string");

        # edit local syncer and sync_zones in place to use ssh
        system("mount -o remount,rw /usr");
        system(
            "sed -i\".$now_string\" -e 's/iqsh/ssh/' /usr/local/bin/sync_zones"
        );
        system("sed -i\".$now_string\" -e 's/iqsh/ssh/' /usr/local/bin/syncer");
        system("mount -o remount,ro /usr");

        # turn off local selinux so gtm can fork ssh
        system("/usr/sbin/setenforce permissive");

        unless ( open( KEY, ">>$ssh_authkey" ) ) {
            print STDERR
              "ERROR: Can't open local server cert file $ssh_authkey.\n";
            exit -1;
        }
        print KEY $their_key;
        close KEY;
        last;
    }
}

print "\n==> Done <==\n";

__END__

