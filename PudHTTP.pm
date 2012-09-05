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

#### Why reinvent the wheel? ####
# Since we want this to work in Cygwin without any fancy crap like MSVC
# and all that, there needs to be an HTTP transport mechanism for PUD
# written using only Socket.pm and HTTP protocol.  That's what PudHTTP.pm is.
# Unfortunately, we can't use LWP, because of the restrictions that we face
# with Cygwin, we can't use LWP.
#################################

package PudHTTP;
use strict;
use vars qw($VERSION @ISA);
use Socket;
use POSIX qw(uname);

$VERSION = "0.1.0";
@ISA = qw();

sub BEGIN {
	return 1;
}

sub END {
	return 1;
}

sub _getOrSet ($$;$) {
	my $this = shift;
	my $name = shift;
	my $value = shift or undef;

	if (defined ($value)) {
		$this->{"_VARS_"}->{$name} = $value;
	}

	return $this->{"_VARS_"}->{$name};
}

sub new ($;$) {
	my $class = shift;
	my $stash = shift or undef;

	my $this = {};
	my @osInfo = ();

	bless ($this, $class);
	$this->setAccept ($stash->{"accept"} or "text/plain */*");
	$this->setAcceptLanguage ($stash->{"accept-language"} or "en-us");
	$this->setUserAgent ($stash->{"user-agent"});
	$this->setHost ($stash->{"host"});
	$this->setPort ($stash->{"port"});
	$this->setUri ($stash->{"uri"});

	if (!defined ($this->getPort ())) {
		$this->setPort (80);
	}

	if (!defined ($this->getUserAgent ())) {
		@osInfo = uname ();
		$this->setUserAgent ("Mozilla/4.0 (compatible; PudHTTP.pm __PUD_VERSION; " .
			join ("; ", @osInfo[0,2,4]) . ")");
	}

	return $this;
}

sub setAccept ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("accept", $value);
}

sub getAccept ($) {
	my $this = shift;

	return $this->_getOrSet ("accept");
}

sub setAcceptLanguage ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("accept-language", $value);
}

sub getAcceptLanguage ($) {
	my $this = shift;

	return $this->_getOrSet ("accept-language");
}

sub setUserAgent ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("user-agent", $value);
}

sub getUserAgent ($) {
	my $this = shift;

	return $this->_getOrSet ("user-agent");
}

sub setHost ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("host", $value);
}

sub getHost ($) {
	my $this = shift;

	return $this->_getOrSet ("host");
}

sub setPort ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("port", $value);
}

sub getPort ($) {
	my $this = shift;

	return $this->_getOrSet ("port");
}

sub setUri ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("uri", $value);
}

sub getUri ($) {
	my $this = shift;

	return $this->_getOrSet ("uri");
}

sub setSocket ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("socket", $value);
}

sub getSocket ($) {
	my $this = shift;

	return $this->_getOrSet ("socket");
}

sub setResponse ($$) {
	my $this = shift;
	my $value = shift;

	return $this->_getOrSet ("response", $value);
}

sub getResponse ($) {
	my $this = shift;

	return $this->_getOrSet ("response");
}

sub connect ($) {
	my $this = shift;

	my $proto = getprotobyname ("tcp");
	my $addr = gethostbyname ($this->getHost ());
	my $port = $this->getPort ();
	my $sin = sockaddr_in ($port, $addr);
	my $socket = undef;

	socket ($socket, PF_INET, SOCK_STREAM, $proto) or
		die ("Failed to create socket: " . $!);
	connect ($socket, $sin) or
		die ("Failed to connect to host " . $this->getHost () . " on port " .
			  $this->getPort () . ": " . $!);

	$this->setSocket ($socket);

	return 1;
}

sub _produceHTTPHeader ($) {
	my $this = shift;

	my $header = "GET " . $this->getUri () . " HTTP/1.0\n";

	$header .= "Accept: " . $this->getAccept () . "\n";
	$header .= "Accept-Language: " . $this->getAcceptLanguage () . "\n";
	$header .= "User-Agent: " . $this->getUserAgent () . "\n";
	$header .= "Host: " . $this->getHost () . "\n";
	#	$header .= "Connection: keep-alive\n";
	$header .= "Accept-encoding: gzip, deflate\n\n";

	return $header;
}

sub request ($) {
	my $this = shift;

	my $socket = $this->getSocket ();
	my $responseHeader = undef;
	my $temp = undef;

	send ($socket, $this->_produceHTTPHeader (), 0) or
		die ("Failed to send request header: " . $!);
	while ($temp = <$socket>) {
		chomp ($temp);
		$temp =~ s/\r//g;
		$responseHeader .= $temp . "\n";
		if (length ($temp) == 0) {
			last;
		}
	}

	$this->setResponse ($responseHeader);

	return 1;
}

sub disconnect ($) {
	my $this = shift;

	my $socket = $this->getSocket ();

	close ($socket);

	return 1;
}

return 1;
