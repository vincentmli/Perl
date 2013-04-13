#!/usr/bin/perl
use strict;
use warnings;

my $bcm56xxd_total = 0;
my $bcm56xxd_count = 0;
my $bcm56xxd_average = 0;

my $csyncd_total = 0;
my $csyncd_count = 0;
my $csyncd_average = 0;

my $merged_total = 0;
my $merged_count = 0;
my $merged_average = 0;

my $tmm_total = 0;
my $tmm_count = 0;
my $tmm_average = 0;

my $mcpd_total = 0;
my $mcpd_count = 0;
my $mcpd_average = 0;


my $statsd_total = 0;
my $statsd_count = 0;
my $statsd_average = 0;

my $idlecpu_total = 0;
my $idlecpu_count = 0;
my $idlecpu_average = 0;

# top -cbn1 sample output 
#Cpu(s): 10.9%us,  3.1%sy,  0.1%ni, 83.6%id,  2.2%wa,  0.0%hi,  0.1%si,  0.0%st
# 5795 root      20   0 39904  29m  17m S  5.8  0.2   0:20.82 /usr/bin/bcm56xxd -f
#10327 root      RT   0 1888m  64m  63m S  7.8  0.4   0:19.95 tmm.4 --tmid 4 --npus 8 --platform A109 -m -s 1756
# 5429 root      20   0 22036  13m 6532 S  5.8  0.1   3:35.25 /usr/bin/csyncd
# 6314 root      25   5 16360 6256 2392 S  3.9  0.0   2:09.74 /usr/bin/merged -f

while (<>) {
  if(/^.*?[S|R]\s*?([0-9]+\.[0-9]+)\s*?.*?\/usr\/bin\/bcm56xxd/) {
      $bcm56xxd_total = $bcm56xxd_total + $1;
      $bcm56xxd_count = $bcm56xxd_count + 1;
  }

  elsif(/^.*?[S|R]\s*?([0-9]+\.[0-9]+)\s*?.*?\/usr\/bin\/csyncd/) {
      $csyncd_total = $csyncd_total + $1;
      $csyncd_count = $csyncd_count + 1;

  }
  elsif(/^.*?[S|R]\s*?([0-9]+\.[0-9]+)\s*?.*?\/usr\/bin\/merged/) {
      $merged_total = $merged_total + $1;
      $merged_count = $merged_count + 1;

  }
  elsif(/^.*?[S|R]\s*?([0-9]+\.[0-9]+)\s*?.*?\/usr\/bin\/mcpd/) {
      $mcpd_total = $mcpd_total + $1;
      $mcpd_count = $mcpd_count + 1;
  }

  elsif(/^.*?[S|R]\s*?([0-9]+\.[0-9]+)\s*?.*?\/usr\/bin\/statsd/) {
      $statsd_total = $statsd_total + $1;
      $statsd_count = $statsd_count + 1;
  }

  elsif(/[S|R]\s*?([0-9]+\.[0-9]+).*?tmm\.[0-9]/) {
      $tmm_total = $tmm_total + $1;
      $tmm_count = $tmm_count + 1;

  }
  elsif(/^Cpu.*?([0-9]+\.[0-9]+)%id/) {
     $idlecpu_total = $idlecpu_total + $1;
     $idlecpu_count = $idlecpu_count + 1;
  }
}

$bcm56xxd_average = $bcm56xxd_total / $bcm56xxd_count;
print "total sampled bcm56xxd cpu usage: $bcm56xxd_total\n";
print "bcm56xxd sample count: $bcm56xxd_count\n";
print "average sampled bcm56xxd cpu usage: $bcm56xxd_average <-----\n\n";

$csyncd_average = $csyncd_total / $csyncd_count;
print "total sampled csyncd cpu usage: $csyncd_total\n";
print "csyncd sample count: $csyncd_count\n";
print "average sampled csyncd cpu usage: $csyncd_average <-------\n\n";

$merged_average = $merged_total / $merged_count;
print "total sampled merged cpu usage: $merged_total\n";
print "merged sample count: $merged_count\n";
print "average sampled merged cpu usage: $merged_average <--------\n\n";

$mcpd_average = $mcpd_total / $mcpd_count;
print "total sampled mcpd cpu usage: $mcpd_total\n";
print "mcpd sample count: $mcpd_count\n";
print "average sampled mcpd cpu usage: $mcpd_average <-----\n\n";

$statsd_average = $statsd_total / $statsd_count;
print "total sampled statsd cpu usage: $statsd_total\n";
print "statsd sample count: $statsd_count\n";
print "average sampled statsd cpu usage: $statsd_average <-----\n\n";


$tmm_average = $tmm_total / $tmm_count;
print "total sampled tmm cpu usage: $tmm_total\n";
print "tmm sample count: $tmm_count\n";
print "average sampled tmm cpu usage: $tmm_average <----\n\n";

$idlecpu_average = $idlecpu_total / $idlecpu_count;
print "total sampled idle cpu : $idlecpu_total\n";
print "idle cpu sample count: $idlecpu_count\n";
print "average sampled idle cpu usage: $idlecpu_average <---- \n\n";
