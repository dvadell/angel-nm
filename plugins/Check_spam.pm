#------------------------------------------------------------------------------
#   Check_spam
#
#   This plugin will use rblcheck.pl to check if a IP address is in
#   a spam black list.
#
#------------------------------------------------------------------------------

package Check_spam;
require 5.002;
use strict;

sub Check_spam {
    # We bundle rblcheck.pl with angel, but you can change it if you want
    my $rblcheck = $main::Homedir . "/bin/rblcheck.pl";
    $rblcheck =~ /(.*)/;
    $rblcheck = $1;

    ## Parse the plugin parameters
    # If more than $max_num_timeouts tests time out, we return yellow
    my ($ip,$max_num_timeouts) = split('!',$_[0]);
    $ip =~ /(.*)/;
    $ip = $1;

    # Defaults
    $max_num_timeouts = 5 unless $max_num_timeouts;

    # Result
    my $res = {};
    $res->{units} = "blacklists";

    # Sample rblcheck.pl output:
    #200.68.86.25 RBL filtered by block.blars.org
    #200.68.86.25 not RBL filtered by dnsbl.ahbl.org
    #Check for filtering by relays.dorkslayers.com timed out (10 s).

    my @red;
    my @yellow;

    $res->{status}  = 1;
    $res->{message} = "Couldn't run rblcheck.pl: $!";
    open(my $rblc, "$rblcheck $ip 2>&1|") or return $res;
    
    while (<$rblc>) { 
        push(@red, $1) if (m/$ip RBL filtered by (.*)/);
        push(@yellow, $1) if (m/Check for filtering by (.*) timed out/);
    }

    close($rblc);
    
    if (@yellow > $max_num_timeouts) {
        $res->{status} = 1; 
        $res->{message} = "Too many lists (" . join(", ",@yellow). ") timed out.";
        $res->{graph_value} = undef;
        $res->{pretty_value} = "Unknown";
    }

    if (@red) {
        $res->{status}       = 2;
        $res->{message}      = "Host $ip is listed in " . scalar(@red). " blacklists: " . join(", ",@red);
        $res->{graph_value}  = scalar(@red);
        $res->{pretty_value} = $res->{graph_value} . " " . $res->{units};
    }

    $res->{status}       = 0; 
    $res->{message}      = "OK";
    $res->{graph_value}  = 0;
    $res->{pretty_value} = "Not blacklisted";

    return $res;
}
1;
