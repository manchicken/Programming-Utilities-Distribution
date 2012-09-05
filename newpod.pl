#!/usr/bin/perl 
# newpod - Create a new perl plain old documentation file from the template.
# Copyright (C) 2000-2002 by Michael D. Stemle, Jr.
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
# 
# Michael D. Stemle, Jr. - mikes@gnurds.org

use strict;
use lib qw(__DATA_PATH__);
use PudConfig;
use Style;
use PudTemplate;

sub doHelp ();

my $fileName = $ARGV[0];
my $template = $ARGV[1];
my $version = $ARGV[2] || "0.1.0";
my $temp = undef;
my $output = undef;
my $x = 0;
my @templates = ();

if ($fileName =~ m/(-h|-\?|--help)/)
{
	doHelp ();
	exit (0);
}
elsif ($fileName =~ m/(-l|--list)/) {
	@templates = listAvailableTemplates ();
	for ($x = 0; $templates[$x]; $x++) {
		print STDOUT $templates[$x];
		if (($x % 3) == 0) {
			print STDOUT "\n";
		}
		else {
			print STDOUT "    ";
		}
	}
}
else {
	if (!$template) {
		$template = getDefaultTemplate ();
	}
}

if (-e $fileName && -w $fileName)
{
	 print STDOUT "File \"" . $fileName . "\" already exists.  Overwrite? ";
	 $temp = <STDIN>;
	 if (!($temp =~ /y/i))
	 {
		  print STDOUT "Exiting...\n";
		  exit (0);
	 }
}
elsif (-e $fileName && !(-w $fileName))
{
	 doError ("File " . $fileName . " exists but cannot be written to.");
}

if (open (OUTFILE, ">" . $fileName))
{
	$output = grabTemplate ($fileName, "perl", $template, $version);
	$output .= grabStyle ("pod", $fileName, $version);
	print OUTFILE $output;
	close (OUTFILE);
}
else
{
	 doError ("Failed to open file \"" . $fileName . "\" for writting: " . $!);
}
exit (0);

sub doHelp ()
{
	print STDOUT "Usage: $0 [FILE] [TEMPLATE] [VERSION]\n";
	print STDOUT "       $0 -h|-?|--help   Show this message\n";
	print STDOUT "       $0 -l|--list      List available templates\n";

	return;
}
