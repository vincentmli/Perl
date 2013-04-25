#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Net::Amazon::EC2;

my $ret;

my $ec2 = Net::Amazon::EC2->new(
    AWSAccessKeyId  => 'yourawsaccesskeyid',
    SecretAccessKey => 'yoursecretaccesskey',
    debug           => 1,
    region          => 'us-west-2',
);

#	print STDERR Dumper($ec2);

my $images = $ec2->describe_images( ImageId => 'ami-yourimageid' );

# Start 1 new instance from AMI: ami-XXXXXXXX

my $running_instances = $ec2->describe_instances;

foreach my $reservation (@$running_instances) {
    foreach my $instance ( $reservation->instances_set ) {
        print $instance->instance_id . "\n";
    }
}

$ret = $ec2->start_instances( InstanceId => 'i-yourinstanceid', );
print STDERR Dumper($ret);

$ret = $ec2->stop_instances( InstanceId => 'i-yourinstanceid', );
print STDERR Dumper($ret);
foreach my $state ( @{$ret} ) {
    print $state->{current_state}->{name} . "\n";
    print $state->{previous_state}->{name} . "\n";
    print $state->{instance_id} . "\n";
}

my $instance = $ec2->run_instances(
    ImageId       => 'ami-yourimageid',
    MinCount      => 1,
    MaxCount      => 1,
    InstanceType  => 't1.micro',
    SecurityGroup => 'quick-start-1',
    KeyName       => 'yourkeypair',
);

my $instance_id = $instance->instances_set->[0]->instance_id;

print "$instance_id\n";

# Terminate instance

my $result = $ec2->terminate_instances( InstanceId => $instance_id );

