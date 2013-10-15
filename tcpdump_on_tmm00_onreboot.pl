#!/usr/bin/perl

use Sys::Syslog;
use POSIX qw(strftime);
use Getopt::Long;

# Auto flush when printing
$| = 1;

my $ssh         = "/usr/bin/ssh -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o UserKnownHostsFile=/dev/null";
my $ruser = "root";
my $sPort     = "22";
my $string = "HA reports tmm ready";
my $now_string = strftime "%H:%M:%S", localtime;
my $active_string = "Active for traffic group";
my $SLOT_COUNT = 2; #how many slot vcmp deployed on
my $count = 0;
#----------------------------------------------------------------------------
# Validate Arguments, customer change end
#----------------------------------------------------------------------------

my $PID_FILE = "/var/run/boot_scan.pid";
my $program  = "boot_scan";
my $host = shift;

my $reboot_cmd = "$ssh -l $ruser $host 'clsh reboot ' ";
my $boot_cmd = "$ssh -l $ruser $host ' tail -f /var/log/ltm | grep --line-buffered boot_marker ' | ";
my $sod_cmd = "$ssh -l $ruser $host ' tail -f /var/log/ltm | grep --line-buffered \"$string\" ' | ";
my $tcpdump_tmm = "$ssh -l $ruser $host 'tcpdump -nn -i 0.0:nnn -s0 -w /var/tmp/tmm00-$now_string.pcap port 1026 or icmp or arp' ";
my $failover_cmd = "$ssh -l $ruser $host '/usr/libexec/bigpipe failover standby  ' ";
my $soddebug_on_cmd = "$ssh -l $ruser $host '/usr/bin/tmsh modify  sys db failover.debug value enable  ' ";
my $soddebug_off_cmd = "$ssh -l $ruser $host '/usr/bin/tmsh modify sys db failover.debug value disable  ' ";

use Time::HiRes
  qw( usleep ualarm gettimeofday tv_interval nanosleep clock_gettime clock_getres clock_nanosleep);


# the debug log variable is a bit mask
# debug = 0 NO LOGGING
# debug | 1 STDOUT
# debug | 2 syslog
# you can enable none, either or both
use constant DEBUG_STDOUT => 1;
use constant DEBUG_SYSLOG => 2;
my $debug = 2;

sub doDebug {
    my @args = @_;
    if ( $debug & DEBUG_STDOUT ) {
        print STDOUT @args;
    }
    if ( $debug & DEBUG_SYSLOG ) {
        syslog( 'LOG_LOCAL0|LOG_DEBUG', @args );
    }
}

openlog( 'boot_scan', 'pid', 'LOG_LOCAL0' );

####### DAEMONIZE #############

sub daemonize {
    use POSIX;
    POSIX::setsid or die "setsid: $!";
    my $pid = fork();
    if ( $pid < 0 ) {
        die "fork: $!";
    }
    elsif ($pid) {
        exit 0;
    }
    chdir "/";
    umask 0;
    foreach ( 0 .. ( POSIX::sysconf(&POSIX::_SC_OPEN_MAX) || 1024 ) ) {
        POSIX::close $_;
    }
    open( STDIN,  "</dev/null" );
    open( STDOUT, ">/dev/null" );
    open( STDERR, ">&STDOUT" );

}

# kill old self, write pid file
if ( -f $PID_FILE ) {
    open( PIDFILE, "<$PID_FILE" );
    kill( 15, <PIDFILE> );
    close(PIDFILE);
}

open( PIDFILE, ">$PID_FILE" );
syswrite( PIDFILE, $$ );
close(PIDFILE);


#main here to start the steps

#step 1, exchange ssh key between hypervisor and guest

my $ssh_pubkey  = "/var/ssh/root/identity.pub";
my $ssh_authkey = "/var/ssh/root/authorized_keys";


if ( $< ne "0" ) {
    print "You must have root privileges to execute the script\n";
    exit -1;
}

my $sshkey_cmd;

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

print "Enter $ruser password for $host if prompted\n";

$sshkey_cmd = "$ssh -l $ruser $host ' " .

# If the $ssh_pubkey exists just cat it into $their_key via the |
"if [ -e $ssh_pubkey ]; then "
. "cat $ssh_pubkey 2>/dev/null; " . "fi; "
.

# Prepend my ssh pub key remote $ssh_authkey
"cp $ssh_authkey /var/log/$ssh_authkey-$now_string 2> /dev/null; "
. "echo \"$my_sshpubkey\" >> $ssh_authkey; "
.  "' |";

unless ( open( REMOTE_KEY, $sshkey_cmd ) ) {
	print STDERR "ERROR: Can't read remote cert via $ssh.\n";
}
my $their_key = "";

while ( defined( $_ = <REMOTE_KEY>) ) {
      $their_key .= $_;
}
unless ( close REMOTE_KEY ) {
      print STDERR "ERROR: Can't read remote pub ssh key via $ssh.\n";
}

unless ( open( KEY, ">>$ssh_authkey" ) ) {
      print STDERR
     "ERROR: Can't open local server cert file $ssh_authkey.\n";
      exit -1;
}
print KEY $their_key;
close KEY;

print "-----------------------------------------------------\n\n";
print "\n==> SSH key exchange Done <==\n";
print "-----------------------------------------------------\n\n";

print "-----------------------------------------------------\n\n";
print"\n turn on sod debug log\n";
print "-----------------------------------------------------\n\n";
system($soddebug_on_cmd);


#exit(1);

#step 2, login guest to reboot all guest slot, sleep 5 seconds to start main loop
system($reboot_cmd);
sleep 5;



#put main loop in background

#daemonize();


#step 3, start the main loop

OUTER:

while (1) {
    my ( $seconds, $microseconds ) = gettimeofday;

    my $localtime = scalar localtime("$seconds");

    print "-----------------------------------------------------\n\n";

    print "time: $localtime, microseconds: $microseconds\n\n";
   


#2013-10-09T16:12:53-07:00 g2 notice boot_marker : ---===[ HD1.2 - BIG-IP 11.2.1 Build 1217.0 ]===---


	       unless ( open( SOD, $sod_cmd ) ) {
            		print STDERR "ERROR: Can't grep sod log \n";
            		next;
               }
               while (<SOD>) {
#Oct  9 19:06:22 slot1/g2 notice sod[5485]: 01140044:5: HA reports tmm ready.
        		if ( $_ =~ /^.*?$string/ ) {

				$count=$count+1;

				if ($count == $SLOT_COUNT) {
               				system($tcpdump_tmm);
					last OUTER;
				}
				
			}
		}
		close SOD;
          

    usleep(100);

}



#sleep 60 seconds again and force it to standby again if it becomes active to just make sure it stays standby

print "---SLEEP 60 SECONDS AND FORCE IT TO STANDBY AGAIN TO MAKE SURE IT STAYS STANDBY---------\n\n";

sleep 60;

print "force $host to standby again \n\n";

system($failover_cmd);

print "-----------------------------------------------------\n\n";
print"\n turn off sod debug log\n";
print "-----------------------------------------------------\n\n";
system($soddebug_off_cmd);




closelog();

exit;

