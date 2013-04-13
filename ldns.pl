#!/usr/bin/perl
use strict;
use warnings;

my $file = './ldns-random1.txt';
my $fh;
my $src_ip;

open($fh, '+>>', $file) or die "couldn't open: $!";

for (my $i=0; $i < 2500000; $i++) {
	print "$i\n";
	#$src_ip = int(rand(255)) . "." . int(rand(255)) . "." . int(rand(255)) . "." . int(rand(255));
	$src_ip = 10 . "." . int(rand(255)) . "." . int(rand(255)) . "." . int(rand(255));

	print $fh <<EOF
path {
   address            $src_ip
   datacenter          "/Common/esnet_dc"
   cur_rtt             3344
   cur_completion_rate 10000
   probe_protocol      icmp
   last_used       1339093289
}
EOF
}
