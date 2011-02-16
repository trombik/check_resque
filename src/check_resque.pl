#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  check_redis.pl
#
#        USAGE:  ./check_redis.pl
#
#       AUTHOR:  Tomoyuki Sakurai, <tomoyukis@reallyenglish.com>
#      CREATED:  02/16/11 08:38:50
#===============================================================================

use strict;
use warnings;
our $VERSION = 1.0;
use Nagios::Plugin;
use Nagios::Plugin::Functions;
use File::Basename;
use Redis;

my $p = Nagios::Plugin->new(
    usage => "Usage; %s [ -v|--verbose ] [ -H <host> ] [ -t <timeout> ]\n"
      . "--warning <queue length> --critical <queue length> --queue [[queue1],...]",
    version => $VERSION,
    plugin  => basename $0,
    timeout => 10,
);
$p->add_arg(
    spec => 'host|hostname|H=s',
    help => "-H, --host=<host> ip.add.re.ss or FQDN\n\tdefault: localhost",
    default => 'localhost',
);
$p->add_arg(
    spec    => 'verbose|v',
    help    => "-v, --verbose be verbose\n\tdefault: off",
    default => 0,
);
$p->add_arg(
    spec    => 'port|p=i',
    help    => "-p, --port=<port> port\n\tdefault: 6379",
    default => 6379,
);
$p->add_arg(
    spec    => 'warning|w=i',
    help    => "-w, --warning <N> the length of queue\n\tdefault: 10",
    default => 10,
);
$p->add_arg(
    spec    => 'critical|c=i',
    help    => "-c, --critical <N> the length of queue\n\tdefault: 15",
    default => 15,
);
$p->add_arg(
    spec => 'queue|q=s',
    help => "--queue queue1,queue2 comma-separated list of queue(s) to monitor"
      . "\tdefault: high,low",
    default => 'high,low',
);

$p->add_arg(
    spec => 'timeout|t=i',
    help => "--timeout <sec> connect timeout in sec\n\tdefault: 10",
    default => 10,
);

$p->getopts;

my $r;

eval {
    # XXX Redis dies when connection refused (IO::Socket::INET->new)
    # XXX Redis doesn't handle timeout at all
    local $SIG{ALRM} = sub { die "connection timeout\n"; };
    alarm $p->opts->timeout;
    $r = Redis->new(
        server => sprintf( "%s:%d", $p->opts->host, $p->opts->port ),
        debug  => $p->opts->verbose,
    );
    alarm 0;
};
if ($@) {
    # XXX Redis doesn't handle $@ properly
    # Connection refused at /usr/local/lib/perl5/site_perl/5.10.1/Redis.pm line 49
    my $message;
    if ($@ =~ /^(.+) at .+ line \d+/) {
        $message = $1;
    }
    else {
        $message = $@;
    }
    nagios_exit(UNKNOWN, $message);
}

my @queues = split /,/, $p->opts->queue;
my %status;

if ( !$r->ping ) {
    nagios_exit( CRITICAL, "redis->ping failed" );
}

foreach my $q (@queues) {
    my $len = $r->llen( sprintf "queue:%s", $q );
    if ( $len >= $p->opts->critical ) {
        $status{$q} = CRITICAL;
    }
    elsif ( $len >= $p->opts->warning ) {
        $status{$q} = WARNING;
    }
    else {
        $status{$q} = OK;
    }
}

my @q_ok       = grep { $status{$_} == OK } keys %status;
my @q_warning  = grep { $status{$_} == WARNING } keys %status;
my @q_critical = grep { $status{$_} == CRITICAL } keys %status;
my $message = sprintf "ok=%s;warning=%s;critical=%s",
  join( ',', @q_ok ),
  join( ',', @q_warning ),
  join( ',', @q_critical );

my $exit_status = OK;
if (@q_critical > 0) {
    $exit_status = CRITICAL;
}
elsif (@q_warning > 0) {
    $exit_status = WARNING;
}
nagios_exit($exit_status, $message);

__END__

=head1 NAME

check_resque - Nagios/Icinga plugins to check resque's queue

=head1 SYNOPSIS

    check_resque -H localhost --warning 10 --critical --20

=head1 DESCRIPTION

This Nagios/Icinga plugin checks resque's job queue by querying to redis
key-value database.

=head1 REQUIREMENTS

The following Perl modules are required.

=over

=item * Nagios::Plugin

L<http://search.cpan.org/dist/Nagios-Plugin>

=item * Redis

L<http://search.cpan.org/dist/Redis>

=back

=head1 OPTIONS

=over

=item -H, --host <hostname>

The target redis server. FQDN or ip.add.re.ss. Default is localhost.

=item -p, --port <port>

TCP port number redis is listens on. Default is 6379.

=item -w, --warning <# of queue>

Returns WARNING state when number of any queues exceeds this limit. Default is
10.

=item -c, --critical <# of queues>

Returns CRITICAL state when number of any queues exceeds this limit. Default is
15.

=item -q, --queue queue1[,queue2, ...]

Comma-separated list of queue name to monitor. Default is "high,low".

=item -t, --timeout <sec>

TCP connection timeout. This is different from execution timeout. Default is 10
sec.

=back

=head1 BUGS AND LIMITATIONS

IPv6 is not supported because Redis Perl module is using only IO::Socket::INET
(or you can blame Perl).

=head1 SEE ALSO

L<Nagios::Plugin>, L<Redis>

=head1 AUTHOR

Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Tomoyuki Sakurai

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut

