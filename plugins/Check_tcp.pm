package Check_tcp;
require 5.002;
use strict;
use warnings;
use IO::Socket;
use Proc::Simple;
use Time::HiRes qw(gettimeofday tv_interval);

sub Check_tcp {

    my ($Default_timeout) = 20;     ## 20 seconds to abort connection
    my ($remote,$service) = split("!", $_[0]);

    # Untaint 
    $remote =~ /([A-Za-z0-9\.\-]+)/;
    $remote = $1;
    $service =~ /([A-Za-z0-9\.\-]+)/;
    $service = $1;

    my $t0 = [gettimeofday];
    my $sock = IO::Socket::INET->new(
                                     PeerAddr => $remote,
                                     PeerPort => $service,
                                     Proto    => 'tcp',
                                     Timeout  => $Default_timeout,
               );
    my $elapsed = tv_interval($t0);

    # The result
    my $res = {};
    $res->{units}        = "secs";
    $res->{pretty_value} = "Unknown";
    $res->{name}       = "Elapsed Time";

    if (!defined($sock)) {
        $res->{status}     = 2;
        $res->{message}    = "Connection refused or timeout [$service/tcp]";
        return $res;
    }
    else {
        $res->{status}      = 0;
        $res->{message}     = "OK";
        $res->{graph_value} = $elapsed;
        $res->{pretty_value} = sprintf("%.3f", $elapsed) . " " . $res->{units};
        return $res;
    }
}
1;
