#!/usr/bin/perl
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

# Paragmas
use strict;
use lib qw(__DATA_PATH__);

# Modules used
use PudUpdate;
use PudInstaller;

# Global variables
my $VERSION = "__PUD_VERSION__";

# Function prototypes
sub showHelp ();
sub showVersion ();
sub showLicense ();
sub showDatPath ();
sub showConfigPath ();
sub showBinPath ();
sub showLogPath ();
sub showVersionDifferences ();
sub updatePud ();

# Main function
sub main () {
	 foreach my $one (@ARGV) {
		  if ($one =~ m/-v/i) {
				showVersion ();
		  }
		  if ($one =~ m/-l/i) {
				showLicense ();
		  }
		  if ($one =~ m/(-h|-\?)/i) {
				showHelp ();
		  }
		  if ($one =~ m/-c/i) {
				showConfigPath ();
		  }
		  if ($one =~ m/-d/i) {
				showDataPath ();
		  }
		  if ($one =~ m/-b/i) {
				showBinPath ();
		  }
		  if ($one =~ m/-s/i) {
				showLogPath ();
		  }
		  if ($one =~ m/-p/i) {
				showVersionDifferences ();
		  }
		  if ($one =~ m/-u/i) {
				updatePud ();
		  }
	 }

	 return 0;
}

# Functions defined
sub showHelp () {
	 print STDOUT <<EOMSG
 pud-config --version |-v     Display version information
            --license |-l     Display the license informaion
            --help    |-h |-? Display this help information
            --config  |-c     Display the path to the system config file
            --data    |-d     Display the path to the data directory
            --bin     |-b     Display the path to the PUD executables
            --syslog  |-s     Display the PUD system log
            --update  |-u     Update PUD to the latest version
                       -p     Display the latest PUD version
EOMSG
;
	showVersion ();

	return;
}

sub showConfigPath () {
	print STDOUT "__SYSTEM_CONFIG__\n";

	return;
}

sub showDataPath () {
	print STDOUT "__DATA_PATH__\n";

	return;
}

sub showBinPath () {
	print STDOUT "__BIN_PATH__\n";

	return;
}

sub showLogPath () {
	print STDOUT "__LOG_PATH__\n";

	return;
}

sub showVersion () {
	 print STDOUT <<EOMSG
 PUD - Programmer Utilities Distribution (Version __PUD_VERSION__)
 Copyright(C)2000-2002 - Michael D. Stemle, Jr. (mstemle1024\@msn.com)
EOMSG
;

	return;
}

sub showLicense () {
	 showVersion ();
	 print STDOUT <<EOMSG
  
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
  
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
EOMSG
;

	return;
}

sub showVersionDifferences () {
	my $latestVersion = getLatestVersionNumber ();

	if ($latestVersion eq "__PUD_VERSION__") {
		print "Latest version is installed.\n";
	}
	else {
		print "Latest version is not installed.\n";
	}

	print "Latest version: " . $latestVersion . "\n";
	print "Current version: __PUD_VERSION__\n";

	return;
}

sub updatePud () {
	 installLatestVersion ();
}

# Don't touch!
exit (main ());
