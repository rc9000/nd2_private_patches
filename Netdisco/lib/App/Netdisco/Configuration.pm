package App::Netdisco::Configuration;

use App::Netdisco::Environment;
use Dancer ':script';

# set up database schema config from simple config vars
if (ref {} eq ref setting('database')) {
    my $name = (setting('database')->{name} || 'netdisco');
    my $host = setting('database')->{host};
    my $user = setting('database')->{user};
    my $pass = setting('database')->{pass};

    my $dsn = "dbi:Pg:dbname=${name}";
    $dsn .= ";host=${host}" if $host;

    # set up the netdisco schema now we have access to the config
    # but only if it doesn't exist from an earlier config style
    setting('plugins')->{DBIC}->{netdisco} ||= {
        dsn  => $dsn,
        user => $user,
        password => $pass,
        options => {
            AutoCommit => 1,
            RaiseError => 1,
            auto_savepoint => 1,
        },
        schema_class => 'App::Netdisco::DB',
    };

}

# static configuration for the in-memory local job queue
setting('plugins')->{DBIC}->{daemon} = {
    dsn => 'dbi:SQLite:dbname=:memory:',
    options => {
        AutoCommit => 1,
        RaiseError => 1,
        sqlite_use_immediate_transaction => 1,
    },
    schema_class => 'App::Netdisco::Daemon::DB',
};

# default queue model is Pg
setting('workers')->{queue} ||= 'PostgreSQL';

# force skipped DNS resolution, if unset
setting('dns')->{hosts_file} ||= '/etc/hosts';
setting('dns')->{no} ||= ['fe80::/64','169.254.0.0/16'];

# schedule expire used to be called expiry
setting('schedule')->{expire} ||= setting('schedule')->{expiry}
  if setting('schedule') and exists setting('schedule')->{expiry};

# set max outstanding requests for AnyEvent::DNS
$ENV{'PERL_ANYEVENT_MAX_OUTSTANDING_DNS'}
  = setting('dns')->{max_outstanding} || 50;
$ENV{'PERL_ANYEVENT_HOSTS'}
  = setting('dns')->{hosts_file} || '/etc/hosts';

true;
