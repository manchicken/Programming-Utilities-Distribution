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

# This module will install the latest version of pud.
package PudInstaller;
use strict;
use lib qw(__DATA_PATH__);
use vars qw($VERSION @ISA @EXPORT);
use PudConfig;
use PudUpdate;
use PudHTTP;
use Archive::Tar;

$VERSION = "0.1.0";
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(installLatestVersion);

sub BEGIN {
	return 1;
}

sub END {
	return 1;
}

sub installLatestVersion () {
	 my $pkg = getPudPackage ();
	 my $tar = new Archive::Tar ();
	 my $slashidx = rindex ($pkg, "/");
	 my $tmpdir = substr ($pkg, 0, $slashidx);
	 my $pkgdir = $pkg;

	 $pkgdir =~ s/\.tar\.gz//gi;

	 chdir ($tmpdir) or
		  die ("Failed to change into the temporary directory '" . $tmpdir . "': " . $!);

	 $tar->extract_archive ($pkg) or
		  die ("Failed to extract archive '" . $pkg . "': " . $tar->error ());

	 chdir ($pkgdir) or
		  die ("Failed to change into the package directory '" . $pkgdir . "': " . $!);

	 # Set this for the installer.
	 $ENV{"PWD"} = $pkgdir;

	 eval {
		  use lib qw($tmpdir);
		  require "install.pl";
		  main ();
	 };
	 if ($@) {
		  die ("Failed to install latest version: " . $@);
	 }

	 return 1;
}

return 1;
