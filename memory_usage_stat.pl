#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $s_column = "allocated";

my $help;

GetOptions(
    "help|?"   => \$help,
    "sort|s=s" => \$s_column,
);

usage() if ( defined $help or @ARGV < 0 );

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: $0
       --help|? \t\thelp message
       --sort|-s \t\tsort by which column, default is allocated
       \n";
    exit;
}

my %tmm_slab;

while (<>) {
    next if ( /^name/ || /^-/ );
    if (
        my (
            $tmm_cache,  $allocated,  $max_allocated, $held,
            $size,       $tot_allocs, $cur_allocs,    $other_alloc,
            $other_free, $remote_free
        )
        = $_ =~
/^(.*?)\s+(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+)\s*(\d+).*$/
      )
    {

        my $slab = $tmm_slab{$tmm_cache} ||= { tmm_cache => $tmm_cache };
        $slab->{'allocated'}     = $allocated;
        $slab->{'max_allocated'} = $max_allocated;
        $slab->{'held'}          = $held;
        $slab->{'size'}          = $size;
        $slab->{'tot_allocs'}    = $tot_allocs;
        $slab->{'cur_allocs'}    = $cur_allocs;
        $slab->{'other_alloc'}   = $other_alloc;
        $slab->{'other_free'}    = $other_free;
        $slab->{'remote_free'}   = $remote_free;
    }
}

printf( "%30s %15s %15s %15s %6s %15s %15s %6s %6s %6s\n",
    qw(name allocated max_allocated held size tot_allocs cur_allocs other_alloc other_free remote_free)
);

foreach
  my $slab ( sort { $b->{$s_column} <=> $a->{$s_column} } values %tmm_slab )
{
    printf(
        "%30s %15d %15d %15d %6d %15d %15d %6d %6d %6d\n",
        $slab->{'tmm_cache'},     $slab->{'allocated'},
        $slab->{'max_allocated'}, $slab->{'held'},
        $slab->{'size'},          $slab->{'tot_allocs'},
        $slab->{'cur_allocs'},    $slab->{'other_alloc'},
        $slab->{'other_free'},    $slab->{'remote_free'}
    );
}

