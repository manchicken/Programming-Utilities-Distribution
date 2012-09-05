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

package Object;
use strict;
use vars qw($VERSION @ISA);

$VERSION = "0.1.0";
@ISA = qw();

sub BEGIN {
	return 1;
}

sub END {
	return 1;
}

sub new ($) {
	my $class = shift;

	my $this = {};

	bless ($this, $class);

	return $this;
}

sub _getOrSet ($$;$) {
	my $this = shift;
	my $name = shift;
	my $value = shift or undef;
	
	if (defined ($value)) {
		$this->{"_DATA_"}->{$name} = $value;
	}

	return $this->{"_DATA_"}->{$name};
}

sub _delete ($$) {
	my $this = shift;
	my $name = shift;

	undef ($this->{"_DATA_"}->{$name});

	return 1;
}

return 1;
