#!/usr/bin/perl
use strict;
use warnings;

my @installed;
my @list;
my @remove;
my %seen;
my $fh1;
my $fh2;

open($fh1, '<', "/home/centos_rebuild/rpm_installed-sort.txt") or die $!;
open($fh2, '<', "/home/centos_rebuild/list.txt") or die $!;

while(<$fh1>) {
  chomp($_);
#  print "$_" . ".rpm" . "\n";
  push @installed, "$_" . ".rpm";
}

while(<$fh2>) {
  chomp($_);
  push @list, "$_";
}


foreach(@installed) {
  $seen{$_} = 1;
}


foreach (@list) {
  if ( ! exists $seen{$_} ) {
	print "/home/centos_rebuild/kickstart_build/CentOS/$_\n";
	push @remove, "/home/centos_rebuild/kickstart_build/CentOS/" . "$_";
  }
}

unlink @remove;

