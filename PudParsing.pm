# PudParsing.pm
# Copyright (C) Michael D. Stemle, Jr.
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
#

package PudParsing;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $COMMENT_INDEX $MY_TEMPLATES $MY_STYLES
				$SYSTEM_TEMPLATES $SYSTEM_STYLES);
use lib qw(__DATA_PATH__);
use PudConfig;
use Data::Dumper;

# These constants are only for the Template namespace.
$COMMENT_INDEX = "__DATA_PATH__/comment.index";

$VERSION = "0.1.0";
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(getAllTags interpLine listAvailableTemplates listAvailableStyles getCommentStyle applyComments makeSkeleton);
@EXPORT_OK = qw();

$SYSTEM_TEMPLATES = "__DATA_PATH__/templates/";
$MY_TEMPLATES = $ENV{"HOME"} . "/.pud/templates/";
$SYSTEM_STYLES = "__DATA_PATH__/styles/";
$MY_STYLES     = $ENV{"HOME"} . "/.pud/styles/";

sub getAllTags ($$) {
	my $fileName = shift;
	my $version = shift;

	my %tags = ();
	my $fileTitle = $fileName;
	my $length = undef;
	my $package = undef;
	my $temp = undef;
	my $x = 0;
	my $year = undef;
	my @blah = ();

	$tags{"VERSION_NUMBER"} = $version;
	$tags{"AUTHOR"} = getCopyrightHolder ();
	$tags{"TIME"} = getTimeString ();
	$tags{"EMAIL"} = getEmailAddy ();

	$fileTitle =~ s/.*\///g;
	$length = rindex ($fileTitle, ".");

	# Determine the package
	@blah = split (m/\//, $fileName);
	$package = join ("::", @blah);
	$package = substr ($package, 0, $length);

	# Make package directories...
	for ($x = 0; $x < ($#blah); $x++) {
		mkdir ($blah[$x]) or
			doError ("Failed to create directory \"$temp\": " . $!);	
	}
	@blah = ();

	$tags{"FILE"} = $fileTitle;
	$tags{"PACKAGE"} = $package;

	# Do the underline thing...
	$length = length ($fileTitle) + 2;
	for ($x = 0; $x < $length; $x++) {
		$temp .= "-";
	}
	$tags{"UNDERLINE_FILE"} = $temp;
	$length = length ($package) + 2;
	undef ($temp);
	for ($x = 0; $x < $length; $x++) {
		$temp .= "-";
	}
	$tags{"UNDERLINE_PACKAGE"} = $temp;
	undef ($temp);
	$length = length ($tags{"AUTHOR"}) + 2;
	for ($x = 0; $x < $length; $x++) {
		$temp .= "-";
	}
	$tags{"UNDERLINE_AUTHOR"} = $temp;

	# Get the year
	@blah = localtime (time ());
	$year = $blah[5] + 1900;
	$tags{"YEAR"} = $year;

	return %tags;
}

sub getCommentStyle ($) {
	my $name = shift;

	my $line = undef;
	my %elements = ();
	my $stopNow = undef;
	my $foundIt = undef;

	if (open (INFILE, "<" . $COMMENT_INDEX)
		 && !$stopNow) {
		while (($line = <INFILE>) && !$foundIt) {
			chomp ($line);
			if (substr ($line, 0, 1) ne '#') {
				@elements{"name","start","stop","single"} = split ('~', $line);
				if (!($elements{"start"} && $elements{"stop"}) &&
					 !$elements{"single"} ||
					 !$elements{"name"}) {
					# OH SHIT!  LEAVE!
					close (INFILE);
					doError ("INVALID COMMENT DEFINITIONS FILE!!!");
				}
				if (lc ($name) eq lc ($elements{"name"})) {
					$stopNow = 1;
					$foundIt = 1;
				}
				else {
					%elements = ();
				}
			}
		}
		close (INFILE);
	}
	else {
		doError ("Failed to open file " . $COMMENT_INDEX . " for reading: " . $!);
	}

	if (!$foundIt) {
		return undef;
	}

	return %elements;
}

sub interpLine ($%) {
	my $line = shift;
	my %tags = @_;

	my $one = undef;

	foreach $one (keys (%tags)) {
		$line =~ s/$one/$tags{$one}/g;
	}

	return $line;
}

sub applyComments ($$) {
	my $scdata = shift;
	my $slines = shift;

	my %cdata = %$scdata;
	my @lines = @$slines;
	my $one = undef;
	my $content = undef;

	if ($cdata{"start"} && $cdata{"stop"}) {
		$lines[0] =~ s/^(.*)/$cdata{"start"}$1/;
		$lines[-1] =~ s/(.*)$/$1$cdata{"stop"}/;
	}
	else {
		foreach $one (@lines) {
			$one = $cdata{"single"} . " " . $one;
		}
	}

	$content = join ("\n", @lines);

	return $content;
}

sub listAvailableTemplates () {
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

sub listAvailableStyles () {
	my @list = ();
	my @allMyFiles = ();
	my @allSystemFiles = ();
	my $one = undef;

	# Read user templates...
	opendir (M_STYLE_DIR, $MY_STYLES) or
		die ("Failed to open directory '" . $MY_STYLES . "' for read: " . $!);
	@allMyFiles = readdir (M_STYLE_DIR);
	closedir (M_STYLE_DIR);

	# Read system templates...
	opendir (S_STYLE_DIR, $SYSTEM_STYLES) or
		die ("Failed to open directory '" . $SYSTEM_STYLES . "' for read: " . $!);
	@allSystemFiles = readdir (S_STYLE_DIR);
	closedir (S_STYLE_DIR);

	# Merge the two lists.
	@list = (@allMyFiles, @allSystemFiles);

	foreach $one (@list) {
		$one = lc ($one);
		$one =~ s/\.style//;
	}

	return @list;
}

sub makeSkeleton ($$) {
	my $template = shift;
	my $style = shift;

	$style =~ s/TEMPLATE/$template/g;

	return $style;
}

return 1;
