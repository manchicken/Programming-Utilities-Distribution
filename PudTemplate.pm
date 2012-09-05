# PudTemplate.pm
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

package PudTemplate;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $SYSTEM_TEMPLATES $MY_TEMPLATES);
use lib qw(__DATA_PATH__);
use PudConfig;
use PudParsing;
use Data::Dumper;

# These constants are only for the Template namespace.
$SYSTEM_TEMPLATES = "__DATA_PATH__/templates/";
$MY_TEMPLATES = $ENV{"HOME"} . "/.pud/templates/";

$VERSION = "0.1.0";
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(grabTemplate);
@EXPORT_OK = qw();

# Call this file like grabTemplate("/home/mstemle/foo.pm", "C", "GPL", "0.1.0");
sub grabTemplate ($$$$) {
	my $file = shift;
	my $language = shift;
	my $template = shift;
	my $version = shift;

	my $line = undef;
	my @lines = ();
	my $fileName = $SYSTEM_TEMPLATES . lc($template) . ".template";
	my %tags = getAllTags ($file, $version);
	my %cdata = getCommentStyle ($language);
	my $content = undef;

	# Convert template name into template file name.

	open (INFILE, "<" . $fileName) or
		doError ("Failed to open file \"" . $fileName . "\" for reading: " . $!);
	while ($line = <INFILE>) {
		chomp ($line);
		$line = interpLine ($line, %tags);
		push (@lines, $line);
	}
	close (INFILE);

	$content = applyComments (\%cdata, \@lines);

	return $content . "\n";
}

return 1;
