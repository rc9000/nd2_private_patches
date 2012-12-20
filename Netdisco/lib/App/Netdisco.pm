package App::Netdisco;

use strict;
use warnings FATAL => 'all';
use 5.010_000;

use File::ShareDir 'dist_dir';
use Path::Class;

our $VERSION = '2.00_009';

BEGIN {
  if (not length ($ENV{DANCER_APPDIR} '')
      or not -f file($ENV{DANCER_APPDIR}, 'config.yml')) {

      my $auto = dir(dist_dir('App-Netdisco'))->absolute;

      $ENV{DANCER_APPDIR}  ||= $auto->stringify;
      $ENV{DANCER_CONFDIR} ||= $auto->stringify;

      $ENV{DANCER_ENVDIR} ||= $auto->subdir('environments')->stringify;
      $ENV{DANCER_PUBLIC} ||= $auto->subdir('public')->stringify;
      $ENV{DANCER_VIEWS}  ||= $auto->subdir('views')->stringify;
  }
}

=head1 NAME

App::Netdisco - An open source web-based network management tool.

=head1 Introduction

The contents of this distribution is the next major version of the Netdisco
network management tool. See L<http://netdisco.org/> for further information
on the project.

So far L<App::Netdisco> provides a web frontend and a backend daemon to handle
interactive requests such as changing port or device properties. There is not
yet a device poller, so please still use the old Netdisco's discovery, arpnip,
and macsuck.

If you have any trouble getting the frontend running, please speak to someone
in the C<#netdisco> IRC channel (on freenode).

=head1 Dependencies

Netdisco has several Perl library dependencies which will be automatically
installed. However it's I<strongly> recommended that you first install
L<DBD::Pg> and L<SNMP> using your operating system packages. The following
commands will test for the existence of them on your system:

 perl -MDBD::Pg\ 999
 perl -MSNMP\ 999

With those two installed, we can proceed...

Create a user on your system called C<netdisco> if one does not already exist.
We'll install Netdisco and its dependencies into this user's home area, which
will take about 200MB including MIB files.

Netdisco uses the PostgreSQL (Pg) database server. Install Pg and then change
to the PostgreSQL superuser (usually C<postgres>). Create a new database and
Pg user for the Netdisco application:

 postgres:~$ createuser -DRSP netdisco
 Enter password for new role:
 Enter it again:
  
 postgres:~$ createdb -O netdisco netdisco

=head1 Installation

To avoid muddying your system, use the following script to download and
install Netdisco and its dependencies into the C<netdisco> user's home area
(C<~netdisco/perl5>).

 su - netdisco
 curl -L http://cpanmin.us/ | perl - --notest --quiet \
     --local-lib ~/perl5 \
     App::cpanminus \
     App::local::lib::helper \
     App::Netdisco

Link some of the newly installed apps into the C<netdisco> user's C<$PATH>,
e.g. C<~netdisco/bin>:

 ln -s ~/perl5/bin/{localenv,netdisco-*} ~/bin/

Test the installation by running the following command, which should only
produce some help text (and throw up no errors):

 localenv netdisco-daemon

=head1 Configuration

Make a directory for your local configuration and copy the configuration
template from this distribution:

 mkdir ~/environments
 cp ~/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/development.yml ~/environments
 chmod +w ~/environments/development.yml

Edit the file and change the database connection parameters to match those for
your local system (that is, the C<dsn>, C<user> and C<pass>).

Optionally, in the same file uncomment and edit the C<domain_suffix> setting
to be appropriate for your local site.

=head1 Bootstrap

The database either needs configuring if new, or updating from the current
release of Netdisco (1.x). You also need vendor MAC address prefixes (OUI
data) and some MIBs if you want to run the daemon. The following script will
take care of all this for you:

 DANCER_ENVDIR=~/environments localenv netdisco-deploy

If you don't want that level of automation, check out the database schema diff
from the current release of Netdisco, and apply it yourself:

 ~/perl5/lib/perl5/App/Netdisco/DB/schema_versions/Netdisco-DB-2-3-PostgreSQL.sql

=head1 Startup

Run the following command to start the web server:

 DANCER_ENVDIR=~/environments localenv plackup ~/bin/netdisco-web

Other ways to run and host the web application can be found in the
L<Dancer::Deployment> page. See also the L<plackup> documentation.

Run the following command to start the daemon:

 DANCER_ENVDIR=~/environments localenv netdisco-daemon start

=head1 Tips and Tricks

The main black navigation bar has a search box which is smart enough to work
out what you're looking for in most cases. For example device names, node IP
or MAC addreses, VLAN numbers, and so on.

For SQL debugging try the following command:

 DBIC_TRACE_PROFILE=console DBIC_TRACE=1 \
   DANCER_ENVDIR=~/environments plackup ~/bin/netdisco-web

=head1 Future Work

The intention is to support "plugins" for additonal features, most notably
columns in the Device Port listing, but also new menu items and tabs. The
design of this is sketched out but not implemented. The goal is to avoid
patching core code to add localizations or less widely used features.

Bundled with this app is a L<DBIx::Class> layer for the Netdisco database.
This could be a starting point for an "official" DBIC layer. Helper functions
and canned searches have been added to support the web interface.

=head1 Caveats

Some sections are not yet implemented, e.g. the I<Device Module> tab.

Menu items on the main black navigation bar go nowhere, except Home.

None of the Reports yet exist (e.g. searching for wireless devices, or duplex
mismatches). These might be implemented as a plugin bundle.

The Wireless, IP Phone and NetBIOS Node properies are not yet shown.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2012 by The Netdisco Developer Team.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Netdisco Project nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE NETDISCO DEVELOPER TEAM BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;