#!/usr/bin/perl
# chgloged.pl
# Copyright(c) Michael D. Stemle, Jr.
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

# Modules used.
use lib qw(__DATA_PATH__);
use PudConfig;

# Subroutines prototyped.
sub init ();
sub addTimeStamp ($$$$);

# Main routine defined.
sub main ()
{
	my $stash;
	my $cmd;
	my $value;

	$stash = init ();
	addTimeStamp ($stash->{'change_log'}, $stash->{'time_stamp'}, $stash->{'user_name'}, $stash->{'email_address'});
	$cmd = $stash->{'pud_editor'} . " + " . $stash->{'change_log'};
	$value = system ($cmd);
	return $value;
}

# Subroutines defined.
sub init ()
{
	my $stash;
	my $tstr;
	my $change_log;
	my $dir;
	my $temp;
	my $current_dir;

	$tstr = getTimeString ();

	$temp = `pwd`;
	chomp ($temp);
	$current_dir = $temp;
	if (opendir (CURRENT_DIR, $temp))
	{
		while ($temp = readdir (CURRENT_DIR))
		{
			chomp ($temp);
			if ($temp =~ /changelog/i)
			{
				$change_log = $temp;
			}
		}
		closedir (CURRENT_DIR);
	}
	else
	{
		doError ("Can't get CWD.");
	}

	if (!$change_log)
	{
		$change_log = $current_dir . "/ChangeLog";
	}

	$stash = {
		'user_name'      => $ENV{'USER'},
		'email_address' => getConfig ("email_address"),
		'pud_editor'    => getConfig ("pud_editor"),
		'time_stamp'    => $tstr,
		'change_log'    => $change_log
	};
	return $stash;
}

sub addTimeStamp ($$$$)
{
	my $file = shift;
	my $time_stamp = shift;
	my $user_name = shift;
	my $email_address = shift;

	if (open (CHANGE_LOG, ">>" . $file))
	{
		print CHANGE_LOG $time_stamp . "   " . $user_name . " <" . $email_address . ">\n";
		close (CHANGE_LOG);
	}
	else
	{
		doError ("Failed to open " . $file . " for appending: " . $!);
	}
}

# Lines never to be touched.
my $returnValue = main ();
exit $returnValue;
