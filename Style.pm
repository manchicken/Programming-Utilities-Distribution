# Style.pm
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

package Style;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $SYSTEM_STYLES $MY_STYLES);
use lib qw(__DATA_PATH__);
use PudParsing;

$SYSTEM_STYLES = "__DATA_PATH__/styles/";
$MY_STYLES     = $ENV{"HOME"} . "/.pud/styles/";

$VERSION = "0.1.0";
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(grabStyle);
@EXPORT_OK = qw();

# Call grabStyle() with only the name of the language the style is for.
sub grabStyle ($$$) {
	my $lang = shift;
	my $file = shift;
	my $version = shift;

	my $styleFile = undef;
	my $line = undef;
	my $output = undef;
	my %tags = ();
	
	# Figure out what style file to use (hey, that rhymes!)
	if (!(-r $MY_STYLES . $lang . ".style")) {
		if (!(-r $SYSTEM_STYLES . $lang . ".style")) {
			die ("No style defined for language '" . $lang . "'.  Please define in " . $MY_STYLES);
		}
		else {
			$styleFile = $SYSTEM_STYLES . $lang . ".style";
		}
	}
	else {
		$styleFile = $MY_STYLES . $lang . ".style";
	}

	# Get tag definitions
	%tags = getAllTags ($file, $version);

	# Open the file
	open (INFILE, "<" . $styleFile) or
		die ("Failed to open style file '" . $styleFile . "' for read: " . $!);

	# Read the file, and parse out the tags...
	while ($line = <INFILE>) {
		$output .= interpLine ($line, %tags);
	}

	# Close the file
	close (INFILE);

	# Return the output
	return $output;
}

return 1;
