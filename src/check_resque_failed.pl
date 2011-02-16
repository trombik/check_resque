#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  check_redis_failed.pl
#
#        USAGE:  ./check_redis_failed.pl --help
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
    help => "-H, --host=<host> ip.add.re.ss or FQDN\n\tdefault: none",
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
    help => "--queue <name_of_failed_queue\n\tdefault: failed",
    default => 'failed',
);
$p->add_arg(
    spec => 'timeout|t=i',
    help => "--timeout <sec> connect timeout in sec\n\tdefault: 10",
    default => 10,
);

$p->getopts;

my $r;

eval {
    local $SIG{ALRM} = sub { die "connection timeout\n"; };
    alarm $p->opts->timeout;
    $r = Redis->new(
        server => sprintf( "%s:%d", $p->opts->host, $p->opts->port ),
        debug  => $p->opts->verbose,
    );
    alarm 0;
};
if ($@) {
    my $message;
    if ($@ =~ /^(.+) at .+ line \d+/) {
        $message = $1;
    }
    else {
        $message = $@;
    }
    nagios_exit(UNKNOWN, $message);
}

if ( !$r->ping ) {
    nagios_exit( CRITICAL, "redis->ping failed" );
}

my $status = UNKNOWN;
my $len = $r->llen("queue:failed");
if ( $len >= $p->opts->critical ) {
    $status = CRITICAL;
}
elsif ( $len >= $p->opts->warning ) {
    $status = WARNING;
}
else {
    $status = OK;
}

my $message = sprintf "failed queue length is %d", $len;
nagios_exit($status, $message);

__END__

=head1 NAME

check_resque_failed -  Nagios/Icinga plugins to check resque's failed queue

=head1 SYNOPSIS

    check_resque_failed -H localhost --warning 10 --critical --20

=head1 DESCRIPTION

This Nagios/Icinga plugin checks resque's failed queue by querying to redis
key-value database.

This plugin shares most of options and others. See also check_resque.

=head1 OPTIONS

See check_resque.

=head1 SEE ALSO

check_resque

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

