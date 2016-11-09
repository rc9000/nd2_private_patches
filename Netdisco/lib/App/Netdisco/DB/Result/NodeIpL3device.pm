use utf8;
package App::Netdisco::DB::Result::NodeIpL3device;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Netdisco::DB::Result::NodeIpL3device

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<node_ip_l3device>

=cut

__PACKAGE__->table("node_ip_l3device");

=head1 ACCESSORS

=head2 node_mac

  data_type: 'macaddr'
  is_nullable: 0

=head2 node_ip

  data_type: 'inet'
  is_nullable: 0

=head2 device_ip

  data_type: 'inet'
  is_nullable: 0

=head2 time_first

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 time_last

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "node_mac",
  { data_type => "macaddr", is_nullable => 0 },
  "node_ip",
  { data_type => "inet", is_nullable => 0 },
  "device_ip",
  { data_type => "inet", is_nullable => 0 },
  "time_first",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "time_last",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</node_mac>

=item * L</node_ip>

=item * L</device_ip>

=back

=cut

__PACKAGE__->set_primary_key("node_mac", "node_ip", "device_ip");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2016-11-09 23:03:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eTQlbkByATRqTPO3W8Rosg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
