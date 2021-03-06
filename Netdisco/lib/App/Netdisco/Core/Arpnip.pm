package App::Netdisco::Core::Arpnip;

use Dancer qw/:syntax :script/;
use Dancer::Plugin::DBIC 'schema';

use App::Netdisco::Util::Node 'check_mac';
use App::Netdisco::Util::DNS ':all';
use NetAddr::IP::Lite ':lower';
use Time::HiRes 'gettimeofday';
use NetAddr::MAC ();

use base 'Exporter';
our @EXPORT = ();
our @EXPORT_OK = qw/ do_arpnip store_arp /;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

App::Netdisco::Core::Arpnip

=head1 DESCRIPTION

Helper subroutines to support parts of the Netdisco application.

There are no default exports, however the C<:all> tag will export all
subroutines.

=head1 EXPORT_OK

=head2 do_arpnip( $device, $snmp )

Given a Device database object, and a working SNMP connection, connect to a
device and discover its ARP cache for IPv4 and Neighbor cache for IPv6.

Will also discover subnets in use on the device and update the Subnets table.

=cut

sub do_arpnip {
  my ($device, $snmp) = @_;

  unless ($device->in_storage) {
      debug sprintf ' [%s] arpnip - skipping device not yet discovered', $device->ip;
      return;
  }

  # get v4 arp table
  my $v4 = _get_arps($device, $snmp->at_paddr, $snmp->at_netaddr);
  # get v6 neighbor cache
  my $v6 = _get_arps($device, $snmp->ipv6_n2p_mac, $snmp->ipv6_n2p_addr);

  # get directly connected networks
  my @subnets = _gather_subnets($device, $snmp);
  # TODO: IPv6 subnets

  # would be possible just to use now() on updated records, but by using this
  # same value for them all, we _can_ if we want add a job at the end to
  # select and do something with the updated set (no reason to yet, though)
  my $now = 'to_timestamp('. (join '.', gettimeofday) .')';

  # update node_ip with ARP and Neighbor Cache entries
  store_arp($device->ip, \%$_, $now) for @$v4;
  debug sprintf ' [%s] arpnip - processed %s ARP Cache entries',
    $device->ip, scalar @$v4;

  store_arp($device->ip, \%$_, $now) for @$v6;
  debug sprintf ' [%s] arpnip - processed %s IPv6 Neighbor Cache entries',
    $device->ip, scalar @$v6;

  _store_subnet($_, $now) for @subnets;
  debug sprintf ' [%s] arpnip - processed %s Subnet entries',
    $device->ip, scalar @subnets;

  $device->update({last_arpnip => \$now});
}

# get an arp table (v4 or v6)
sub _get_arps {
  my ($device, $paddr, $netaddr) = @_;
  my @arps = ();

  while (my ($arp, $node) = each %$paddr) {
      my $ip = $netaddr->{$arp};
      next unless defined $ip;
      next unless check_mac($device, $node);
      push @arps, {
        node => $node,
        ip   => $ip,
        dns  => undef,
      };
  }

  debug sprintf ' resolving %d ARP entries with max %d outstanding requests',
      scalar @arps, $ENV{'PERL_ANYEVENT_MAX_OUTSTANDING_DNS'};
  my $resolved_ips = hostnames_resolve_async(\@arps);

  return $resolved_ips;
}

=head2 store_arp($device_ip, \%host, $now? )

Stores a new entry to the C<node_ip> table with the given MAC, IP (v4 or v6)
and DNS host name. Host details are provided in a Hash ref:

 {
    ip   => '192.0.2.1',
    node => '00:11:22:33:44:55',
    dns  => 'myhost.example.com',
 }

The C<dns> entry is optional. The update will mark old entries for this IP as
no longer C<active>.

Optionally a literal string can be passed in the second argument for the
C<time_last> timestamp, otherwise the current timestamp (C<now()>) is used.

=cut


sub store_arp {
  my ($device_ip, $hash_ref, $now) = @_;
  $now ||= 'now()';
  my $ip   = $hash_ref->{'ip'};
  my $mac  = NetAddr::MAC->new($hash_ref->{'node'});
  my $name = $hash_ref->{'dns'};


  return if !defined $mac or $mac->errstr;

  schema('netdisco')->txn_do(sub {
    my $current = schema('netdisco')->resultset('NodeIp')
      ->search(
        { ip => $ip, -bool => 'active'},
        { columns => [qw/mac ip/] })->update({active => \'false'});

    schema('netdisco')->resultset('NodeIp')
      ->update_or_create(
      {
        mac => $mac->as_ieee,
        ip => $ip,
        dns => $name,
        active => \'true',
        time_last => \$now,
      },
      {
        key => 'primary',
        for => 'update',
      });

    if (setting('arpnip_track_l3device')){

        # device_ip could actually be a hostname when passed from e.g. sshcollector
        # so we try to resolve it and use this value if necessary
        my $device_ip_resolved = ipv4_from_hostname($device_ip);

        schema('netdisco')->resultset('NodeIpL3device')
          ->update_or_create(
          {
            node_mac => $mac->as_ieee,
            node_ip => $ip,
            device_ip => $device_ip_resolved ? $device_ip_resolved : $device_ip,
            time_last => \$now,
          },
          {
            key => 'primary',
            for => 'update',
          });

        }
  });
}


#sub store_arp {
#  my ($hash_ref, $now) = @_;
#  $now ||= 'now()';
#  my $ip   = $hash_ref->{'ip'};
#  my $mac  = NetAddr::MAC->new($hash_ref->{'node'});
#  my $name = $hash_ref->{'dns'};
#
#  return if !defined $mac or $mac->errstr;
#
#  schema('netdisco')->txn_do(sub {
#    my $current = schema('netdisco')->resultset('NodeIp')
#      ->search(
#        { ip => $ip, -bool => 'active'},
#        { columns => [qw/mac ip/] })->update({active => \'false'});
#
#    schema('netdisco')->resultset('NodeIp')
#      ->update_or_create(
#      {
#        mac => $mac->as_ieee,
#        ip => $ip,
#        dns => $name,
#        active => \'true',
#        time_last => \$now,
#      },
#      {
#        key => 'primary',
#        for => 'update',
#      });
#  });
#}

# gathers device subnets
sub _gather_subnets {
  my ($device, $snmp) = @_;
  my @subnets = ();

  my $ip_netmask = $snmp->ip_netmask;
  my $localnet = NetAddr::IP::Lite->new('127.0.0.0/8');

  foreach my $entry (keys %$ip_netmask) {
      my $ip = NetAddr::IP::Lite->new($entry);
      my $addr = $ip->addr;

      next if $addr eq '0.0.0.0';
      next if $ip->within($localnet);
      next if setting('ignore_private_nets') and $ip->is_rfc1918;

      my $netmask = $ip_netmask->{$addr};
      next if $netmask eq '255.255.255.255' or $netmask eq '0.0.0.0';

      my $cidr = NetAddr::IP::Lite->new($addr, $netmask)->network->cidr;

      debug sprintf ' [%s] arpnip - found subnet %s', $device->ip, $cidr;
      push @subnets, $cidr;
  }

  return @subnets;
}

# update subnets with new networks
sub _store_subnet {
  my ($subnet, $now) = @_;

  schema('netdisco')->txn_do(sub {
    schema('netdisco')->resultset('Subnet')->update_or_create(
    {
      net => $subnet,
      last_discover => \$now,
    },
    { for => 'update' });
  });
}

1;
