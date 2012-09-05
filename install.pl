#!/usr/bin/perl
# install.pl
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
use strict;
use POSIX qw(tmpnam unlink uname);
use Fcntl qw(:mode);

# Subroutines prototyped.
sub figureSources ();
sub getTargets ();
sub checkTargets ();
sub replaceTags ();
sub moveTheData ();
sub runCommand ($;);
sub runmakefile ();
sub cleanup ();

my $VERSION = "0.3.0";

my $PWD = undef;
$PWD = $ENV{"PWD"};
$PWD .= "/";

# Global variables
### %TARGETS, %TARGET_QUESTIONS, and %TARGET_MASKS **MUST** have the same keys!!
my %TARGETS = ("SYSTEM_CONFIG"	 => "/etc",
	       "DATA_PATH"	 => "/usr/share/pud",
	       "BIN_PATH"	 => "/usr/local/bin",
	       "LOG_PATH"	 => "/var/logs/pud",
	       "CLIB_PATH"	 => "/usr/local/lib",
	       "GLOBAL_CONFIG"	 => "/etc/pud.conf");
my %TARGET_QUESTIONS = ("SYSTEM_CONFIG" => "Where would you like to put the system configuration file?",
			"DATA_PATH"     => "Where would you like to put the PUD templates?",
			"BIN_PATH"      => "Where would you like to put the PUD executables?",
			"LOG_PATH"      => "Where would you like to put the PUD log files?",
			"PUD_VERSION"   => "IGNORE",
                        "LIB_PATH"      => "IGNORE",
			"CLIB_PATH"     => "Where would you like to put the PUD library files?",
			"GLOBAL_CONFIG"	=> "What is the path and location you desire for the PUD global config file?");
my %TARGET_MASKS = ("SYSTEM_CONFIG" => "0644",
		    "DATA_PATH"     => "0644",
		    "BIN_PATH"      => "0755",
		    "LOG_PATH"      => "0777",
		    "CLIB_PATH"     => "0644",
		    "GLOBAL_CONFIG" => "0644");

### Source file extensions
my @SOURCE_EXTS = qw(pl pm sh template);
### List of ALL source code files in PUD except the installer.
my @SOURCES = ("Makefile");

### Mapping of all perl scripts to symlinks in bin
my %PROG_MAP = ("newpod.pl"     => "newpod",
		"chgloged.pl"   => "chgloged",
		"pud-config.pl" => "pud-config",
		"latest.pl"     => "pud-latest");

# Main routine defined.
sub main ()
{
    my $pudVersion = undef;
    my $temp = undef;

    open (INVER, "<VERSION") or
	die ("Failed to open file 'VERSION' for reading: " . $!);
    while ($temp = <INVER>) {
	chomp ($temp);
	if (substr ($temp, 0, 1) ne "#") {
	    $pudVersion = $temp;
	}
    }
    close (INVER);
    if (!defined ($pudVersion)) {
	$pudVersion = $VERSION;
    }

    $TARGETS{"PUD_VERSION"} = $pudVersion;

    figureSources ();
    getTargets ();
    checkTargets ();
    replaceTags ();
    moveTheData ();
    runmakefile ();
    cleanup ();

    print "The PUD installer ($VERSION) is finished.  Enjoy the PUDy goodness.\n";

    return 0;
}

# Subroutines defined.
### Figure out which sources we're using...
sub figureSources () {
    my $one = undef;
    #	my @elements = ();
    my $ext = undef;

    opendir (SRCPATH, $PWD) or
	die ("Failed to open directory `" . $PWD . "' for reading: " . $!);
    while ($one = readdir (SRCPATH)) {
	foreach $ext (@SOURCE_EXTS) {
	    if ($one =~ m/\.$ext$/) {
		#print "Using source `" . $one . "'\n";
		push (@SOURCES, $one);
	    }
	}
    }
    closedir (SRCPATH);

    return;
}

### Ask user installing PUD where to put PUD stuff...
sub getTargets () {
    my $one = undef;
    my $resp = undef;
    my $question = undef;

    foreach $one (keys (%TARGETS)) {
	if ($TARGET_QUESTIONS{$one} eq "IGNORE") {
	    next;
	}
	$question = $TARGET_QUESTIONS{$one} . "[" . $TARGETS{$one} . "]: ";
	print STDOUT $question;
	$resp = <STDIN>;
	chomp ($resp);
	$resp =~ s/\/$//g;

	$TARGETS{$one} = $resp unless (length ($resp) < 1);
    }

    $TARGETS{"LIB_PATH"} = $TARGETS{"DATA_PATH"} . "/lib";

    return 1;
}

### Make sure that our targets exist, create them if they don't.
sub checkTargets () {
    my $one = undef;

    foreach $one (keys (%TARGETS)) {
	if (!(-d $TARGETS{$one})) {
	    if ($one ne "PUD_VERSION" && $one ne "GLOBAL_CONFIG") {
		mkdir ($TARGETS{$one}, $TARGET_MASKS{$one}) or
		    die ("Failed to create directory `" . $TARGETS{$one} . "': " . $!);
	    }
	}
    }

    return 1;
}

### Go through all the code and replace special tags with their proper values...
sub replaceTags () {
    #print "Entered replaceTags()\n";
    my $one = undef;
    my $source = undef;
    my $line = undef;
    my $fileName = undef;
    my $tag = undef;
    my $parsed = undef;
    my $input = undef;

    # Loop through sources
    foreach $source (@SOURCES) {
	print "Parsing $source.\n";
	# Clean out the output.
	undef ($input);
	# Open the source file
	open (CODE, "<" . $source) or
	    die ("Failed to open file `" . $source . "' for reads: " . $!);

	# The output file for the parsing.
	$parsed = $source . ".parsed";
	open (OUTCODE, ">" . $parsed) or
	    die ("Failed to open file `" . $parsed . "' for writes: " . $!);

	# Read the source file
	while ($line = <CODE>) {
	    $input .= $line;
	}

	# Close the input file once done reading it.
	close (CODE);

	# loop through tags.
	foreach $one (keys (%TARGETS)) {
	    $tag = "__" . $one . "__";
	    #print STDERR "Parsing " . $tag . " in " . $source . "\n";

	    # Replace the tags...
	    $input =~ s/$tag/$TARGETS{$one}/g;
	}

	# Write the output file
	print OUTCODE $input;

	# Close the output file
	close (OUTCODE);
    }

    return 1;
}

### Move the stuff into the data path
sub moveTheData () {
    my $one = undef;
    my $command = undef;
    my $realName = undef;
    my $targetName = undef;
    my $linkName = undef;

    # Move the templates
    $command = "cp -rf templates " . $TARGETS{"DATA_PATH"} . "/";
    runCommand ($command) or
	die ("Failed to move the templates: " . $!);
    $command = "cp -rf styles " . $TARGETS{"DATA_PATH"};
    runCommand ($command) or
	die ("Failed to move the styles: " . $!);
    opendir (DIR, $PWD) or
	die ("Failed to open directory `" . $PWD . "' for reading: " . $!);
    while ($one = readdir (DIR)) {
	#print "Read `" . $one . "'\n";
	if ($one !~ m/\.parsed$/) {
	    next;
	}
	$realName = $one;
	$realName =~ s/\.parsed//;
	$targetName = $TARGETS{"DATA_PATH"} . "/" . $realName;
	$command = "cp " . $one . " " . $targetName;
	runCommand ($command) or
	    die ("Failed to move " . $one . ": " . $!);
	if (defined ($PROG_MAP{$realName})) {
	    $linkName = $TARGETS{"BIN_PATH"} . "/" . $PROG_MAP{$realName};
	    $command = "ln -sf " . $targetName . " " . $linkName;
	    runCommand ($command) or
		die ("Failed to symlink " . $targetName . " to " . $linkName . ": " . $!);
	    $command = "chmod 755 " . $linkName;
	    runCommand ($command) or
		die ("Failed to chmod " . $linkName . ": " . $!);
	}
    }
    closedir (DIR);
    $command = "touch " . $TARGETS{"LOG_PATH"} . "/error.log";
    runCommand ($command) or
	die ("Failed to touch the log: " . $!);
    $command = "cp -f comment.index " . $TARGETS{"DATA_PATH"} . "/comment.index";
    runCommand ($command) or
	die ("Failed to touch the log: " . $!);

    return 1;
}

sub runCommand ($;) {
    my $command = shift;
    #print "Command == `" . $command . "'\n";
    system ($command) == 0 or
	return undef;

    return 1;
}

sub runmakefile () {
    runCommand ("cp -f global.config " . $TARGETS{"GLOBAL_CONFIG"});
    print STDOUT "Building PUD...\n";
    runCommand ("make -k all --makefile=Makefile.parsed") or die ("Make failed.");
    print STDOUT "Moving program files...\n";
    runCommand ("cp -f libpud.a " . $TARGETS{"CLIB_PATH"} . "/libpud.a");
    runCommand ("cp -f sizeof " . $TARGETS{"BIN_PATH"} . "/sizeof");
    runCommand ("cp -f newpl " . $TARGETS{"BIN_PATH"} . "/newpl");
    runCommand ("cp -f newpm " . $TARGETS{"BIN_PATH"} . "/newpm");
    runCommand ("cp -f newc " . $TARGETS{"BIN_PATH"} . "/newc");
    runCommand ("cp -f newcc " . $TARGETS{"BIN_PATH"} . "/newcc");
    runCommand ("cp -f newh " . $TARGETS{"BIN_PATH"} . "/newh");
    runCommand ("cp -f newphp " . $TARGETS{"BIN_PATH"} . "/newphp");
    runCommand ("cp -f pudconf " . $TARGETS{"BIN_PATH"} . "/pudconf");

    return;
}

sub cleanup () {
    print STDOUT "Cleaning up my mess...\n";
    runCommand ("rm -f *.parsed");

    return;
}

# Lines never to be touched.
my $returnValue = main ();
exit $returnValue;
