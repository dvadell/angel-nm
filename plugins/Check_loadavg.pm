#------------------------------------------------------------------------------
#   Check_loadavg
#
#------------------------------------------------------------------------------

package Check_loadavg;
require 5.002;
use strict;
use Junior::Utils;

sub Check_loadavg {
    my ($max) = split('!',$_[0]);
    $max = 1000 if ( !defined($max) );

    # Execute 'uptime'
    my ($ret,$upoutput) = Junior::Utils::timeexec("3","5000","uptime");

    # Result
    my $res = {};
    $res->{units}  = "procs / 100";
    $res->{status} = 1; 
    $res->{max}    = $max;

    ## Check the return code.
    if ($ret != 0) {
        $res->{message} = "Check_load: Probable command timeout";
        return $res;
    }

    # 20:50:24 up 6 days, 10:54,  3 users,  load average: 2.02, 1.19, 0.98
    if ( ! ($upoutput =~ m/average:[ ]*(\d{1,3})\.(\d{1,2}),/)   ) {
        $res->{message}  = "Check_load: Cannot parse uptime output";
        return $res;
    }

    my $load_average = $1 * 100 + $2;

    if ($load_average >= $max) {
        $res->{status}      = 2; 
        $res->{message}     = "Load $load_average exceeds $max";
        $res->{graph_value} = $load_average;
        return $res;
    }

    # If we're here, no errors were found
    $res->{status}       = 0; 
    $res->{message}      = "OK";
    $res->{graph_value}  = $load_average;
    $res->{pretty_value} = $res->{graph_value};
    return $res;
}
1;
