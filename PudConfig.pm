# PudConfig.pm
# Copyright (C) 2000 by Michael D. Stemle, Jr. and Gnurds Nurds
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

package PudConfig;
use strict;
use lib qw(__DATA_PATH__);
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $ERROR_LOG $CONFIG_FILE
				$MY_TEMPLATES $SYSTEM_TEMPLATES);

$VERSION = "0.2.0";
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(getCopyrightHolder getTimeString getEmailAddy doError getDefaultTemplate);
@EXPORT_OK = qw();

$ERROR_LOG   = "__LOG_PATH__/error.log";
$CONFIG_FILE = ".pudrc";

$SYSTEM_TEMPLATES = "__DATA_PATH__/templates/";
$MY_TEMPLATES = $ENV{"HOME"} . "/.pud/templates/";

sub BEGIN {
	# Make sure that things are all set up...
	if (! (-d $ENV{"HOME"} . "/.pud")) {
		mkdir ($ENV{"HOME"} . "/.pud") or
			die ("Failed to create directory '" . $ENV{"HOME"} . "/.pud': " . $!);
	}
	if (! (-d $ENV{"HOME"} . "/.pud/styles")) {
		mkdir ($ENV{"HOME"} . "/.pud/styles") or
			die ("Failed to create directory '" . $ENV{"HOME"} . "/.pud/styles': " . $!);
	}
	if (! (-d $ENV{"HOME"} . "/.pud/templates")) {
		mkdir ($ENV{"HOME"} . "/.pud/templates") or
			die ("Failed to create directory '" . $ENV{"HOME"} . "/.pud/templates': " . $!);
	}

	return 1;
}

sub _listAvailableTemplates () {
	my @list = ();
	my @allMyFiles = ();
	my @allSystemFiles = ();
	my $one = undef;

	# Read user templates...
	opendir (M_TPL_DIR, $MY_TEMPLATES) or
		die ("Failed to open directory '" . $MY_TEMPLATES . "' for read: " . $!);
	@allMyFiles = readdir (M_TPL_DIR);
	closedir (M_TPL_DIR);

	# Read system templates...
	opendir (S_TPL_DIR, $SYSTEM_TEMPLATES) or
		die ("Failed to open directory '" . $SYSTEM_TEMPLATES . "' for read: " . $!);
	@allSystemFiles = readdir (S_TPL_DIR);
	closedir (S_TPL_DIR);

	# Merge the two lists.
	@list = (@allMyFiles, @allSystemFiles);

	foreach $one (@list) {
		if ($one =~ m/\.template/) {
			$one = lc ($one);
			$one =~ s/\.template//;
		}
	}

	return @list;
}

sub doError ($)
{
	 my $msg = shift;

	 if (open (LOGFILE, ">>" . $ERROR_LOG))
	 {
		  print LOGFILE "[" . localtime () . "] " . $msg . "\n";
		  close (LOGFILE);
	 }
	 else
	 {
		  die ("Failed to open error log: " . $!);
	 }
	 print ("ERROR: " . $msg . "\n");
	 exit (0);
}

sub setConfig ($;$)
{
	my $key = shift;
	my $prompt = shift;
	my $value;
	my $file = $ENV{'HOME'} or doError ("\$HOME directory not set.");

	$file .= "/" . $CONFIG_FILE;
	if ($prompt)
	{
		print STDOUT $prompt . ": ";
	}
	else
	{
		print STDOUT "Input a value for " . $key . ": ";
	}
	$value = <STDIN>;
	chomp ($value);
	if (open (OUT_CONFIG, ">>" . $file))
	{
		print OUT_CONFIG $key . ":" . $value . "\n";
		close (OUT_CONFIG);
	}
	else
	{
		doError ("Failed to open \"" . $file . "\" for appending: " . $!);
	}
	return;
}

sub getConfig ($)
{
	my $which = shift;
#	my $home = $HOME or doError ("\$HOME directory not set.");
	my $home = $ENV{'HOME'} or doError ("\$HOME directory not set.");
	my $file = $home . "/" . $CONFIG_FILE;
	my $value = undef;
	my $temp;
	my $line;

	if (!(-e $file))
	{
		if (open (CFILE, ">" . $file))
		{
			print CFILE "version:" . $VERSION . "\n";
			close (CFILE);
		}
		else
		{
			doError ("Can't create file \"" . $file . "\":" . $!);
		}
	}
	if (open (CFILE, "<" . $file))
	{
		while ($line = <CFILE>)
		{
			chomp ($line);
			($temp->{'key'}, $temp->{'value'}) = split (/:/, $line);
			if ($temp->{'key'} eq $which)
			{
				if (!$value)
				{
					$value = $temp->{'value'};
				}
				else
				{
					doError ("Multiple values for \"" . $which . "\" in file \"" . $file . "\".");
				}
			}
		}
		close (CFILE);
	}
	else
	{
		doError ("Can't open config file \"" . $file . "\":" . $!);
	}
	return $value;
}

sub getCopyrightHolder ()
{
	my $ch = getConfig ("copyright_holder");
#	my $cfgfile = $HOME . "/" . $CONFIG_FILE;
	my $cfgfile = $ENV{"HOME"} . "/" . $CONFIG_FILE;
	
	if (!$ch)
	{
		print "Please enter the name of the copyright holder: ";
		$ch = <STDIN>;
		chomp ($ch);
		if (open (CFILE, ">>" . $cfgfile))
		{
			print CFILE "copyright_holder:" . $ch . "\n";
			close (CFILE);
		}
		else
		{
			doError ("Can't open file \"" . $cfgfile . "\" for writing: " . $!);
		}
	}
	$ch =~ s/(\r|\n)//g;

	return $ch;
}

sub getTimeString ()
{
	my $str = "[" . localtime () . "]";
	return $str;
}

sub getEmailAddy () {
	my $ch = getConfig ("email_address");
	my $cfgfile = $ENV{"HOME"} . "/" . $CONFIG_FILE;

	if (!$ch) {
		print "Please enter your email address: ";
		$ch = <STDIN>;
		chomp ($ch);
		if (open (CFILE, ">>" . $cfgfile)) {
			print CFILE "email_address:" . $ch . "\n";
			close (CFILE);
		}
		else {
			doError ("Can't open file \"" . $cfgfile . "\" for writing: " . $!);
		}
	}
	$ch =~ s/(\r|\n)//g;

	return $ch;
}

sub getDefaultTemplate () {
	my $ch = getConfig ("default_template");
	my $cfgfile = $ENV{"HOME"} . "/" . $CONFIG_FILE;
	my @list = ();
	my $x = undef;

	if (!$ch) {
		do {
			print "Please enter the template to use by default (? to list): ";
			$ch = <STDIN>;
			chomp ($ch);
			if ($ch eq "?") {
				@list = _listAvailableTemplates ();
				for ($x = 0; defined ($list[$x]); $x++) {
					print STDOUT $list[$x];
					if (($x % 3) == 0) {
						print STDOUT "\n";
					}
					else {
						print STDOUT "    ";
					}
				}
			}
		} while (!(-r $ENV{"HOME"} . "/.pud/templates/" . $ch . ".template") &&
					!(-r "__DATA_PATH__/templates/" . $ch . ".template"));
		if (open (CFILE, ">>" . $cfgfile)) {
			print CFILE "default_template:" . $ch . "\n";
			close (CFILE);
		}
		else {
			doError ("Can't open file \"" . $cfgfile . "\" for writing: " . $!);
		}
	}
	$ch =~ s/(\n|\r)//g;

	return $ch;
}

return 1;
