#!/usr/bin/perl
# This is compiled with threading support

use strict;
use warnings;
use threads;
use threads::shared;

print "Starting main program\n";


my $cmd = "./htmlget localhost";
#my $cmd = "sftp -b /home/vincent/sftp_batch root\@10.1.112.1";

my @threads;
for ( my $count = 1; $count <= 100; $count++) {
        my $t = threads->new(\&sub1, $count);
        push(@threads,$t);
}
foreach (@threads) {
        my $num = $_->join;
        print "done with $num\n";
}
print "End of main program\n";

sub sub1 {
        my $num = shift;
        print "started thread $num\n";
	system($cmd);
#        sleep $num;
        print "done with thread $num\n";
        return $num;
}

