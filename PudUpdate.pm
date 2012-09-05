# Copyright(C)2002 - Michael D. Stemle, Jr. (mstemle1024@msn.com)
#  
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

package PudUpdate;
use strict;
use vars qw($VERSION @ISA @EXPORT %TARGETS);
use lib qw(__DATA_PATH__);
use PudConfig;
use PudHTTP;
use Socket;
use POSIX qw(tmpnam);

$VERSION = "0.1.0";
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(getLatestVersionNumber getPudPackage);

# These are targets for auto installer
%TARGETS = ("SYSTEM_CONFIG" => "__SYSTEM_CONFIG__",
				"DATA_PATH"     => "__DATA_PATH__",
				"BIN_PATH"      => "__BIN_PATH__",
				"LOG_PATH"      => "__LOG_PATH__");

sub BEGIN {
	return 1;
}

sub END {
	return 1;
}

# Purpose of this function is to retrieve latestversion.txt from pud.sourceforge.net.
sub getLatestVersionNumber () {
	my $latestVersion = undef;
	my $temp = undef;
	my $socket = undef;
	my $http = new PudHTTP ({"host"=>"pud.sourceforge.net",
									 "uri"=>"/latestversion.txt"});

	$http->connect ();
	$http->request ();
	$socket = $http->getSocket ();
	$latestVersion = <$socket>;
	chomp ($latestVersion);
	($latestVersion, $temp) = split (';', $latestVersion);

	$http->disconnect ();

	# Do some error handling to make sure that we have the value we were expecting.
	if ($latestVersion !~ m/^\d\.\d\.\d(\s\w+)?$/) {
		print STDERR "Found error in value: " . $latestVersion . "\nHeaders:\n" . $http->getResponse () . "\n";
		doError ("Found error in value: " . $latestVersion . "\nHeaders:\n" . $http->getResponse ());
	}

	return $latestVersion;
}

sub getLatestFileName () {
	my $temp = undef;
	my $fname = undef;
	my $socket = undef;
	my $http = new PudHTTP ({"host" => "pud.sourceforge.net",
									 "uri"  => "/latestversion.txt"});

	$http->connect ();
	$http->request ();
	$socket = $http->getSocket ();
	$temp = <$socket>;
	chomp ($temp);
	($temp, $fname) = split (';', $temp);

	$http->disconnect ();

	return $fname;
}

sub getPudPackage () {
	my $fname = undef;
	my $uri = undef;
	my $host = undef;
	my $socket = undef;
	my $http = undef;
	my $dir = undef;
	my $offset = undef;
	my $temp = undef;
	my $foo = undef;

	($host, $uri) = split (':', getLatestFileName ());
	$offset = rindex ($uri, '/');
	$fname = substr ($uri, $offset, (length ($uri) - $offset));

	$http = new PudHTTP ({"host" => $host,
								 "uri"  => $uri});

	# Create the temp directory
	do {
		$dir = tmpnam ();
	} while (-e $dir);

	mkdir ($dir, 0777) or
		die ("Failed to create directory '" . $dir . "': " . $!);

	$http->connect ();
	$http->request ();
	$socket = $http->getSocket ();
	binmode ($socket);

	open (TMPFILE, ">" . $dir . $fname) or
		die ("Failed to open file '" . $dir . $fname . "' for writing: " . $!);
	binmode (TMPFILE);
	while ($temp = <$socket>) {
		print TMPFILE $temp;
	}

	close (TMPFILE);

	$http->disconnect ();

	return $dir . $fname;
}

return 1;
