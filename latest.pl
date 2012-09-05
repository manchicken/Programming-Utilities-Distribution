#!/usr/bin/perl

use lib qw(./);
use PudUpdate;

my $version = getLatestVersionNumber ();

print STDOUT "Latest Version: " . $version . "\n";
