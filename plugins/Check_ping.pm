#-----------------------------------------------------------------------------
#   Check_ping
#
#   Plug-in to report the ICMP roundtrip time to a given host
#
#   Parameters:
#
#       hostname:Check_ping:hostaddress!loss_yellow!loss_red
#
#       'hostname'
#           The host name
#
#       'loss_yellow' and 'loss_red'
#           The yellow and red thresholds for the percent of
#           packet loss.
#
#   Example parameters:
#
#       LABEL:100!200!5!15
#
#       Roundtrips above 100 (usually ms, depending on your
#       ping command output) will be flagged as yellow. Above
#       200ms will result in a red condition. Yellow for loss
#       rates above or equal to 5%, red above or equal to 15%.
#
#   LEGAL STUFF:
#
#   The Angel Network Monitor
#   Copyright (C) 1998 Marco Paganini (paganini@paganini.net)
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#   The Angel Network Monitor Copyright (C) 1998 Marco Paganini
#   This program comes with ABSOLUTELY NO WARRANTY; 
#   This is free software, and you are welcome
#   to redistribute it under certain conditions; refer to the COPYING
#   file for details.
#
#   0.7.3
#   Modified October 25 2002 by Matt A. Callihan
#   Fixed Check_Ping.pl to work with iputils-ss020124 and beyond.
#
#   20070303 - DMV
#   Plugins must return a hash for angel > 0.8.2
#   Removed all the avg tests, as I need to graph one value (lost)
#
#------------------------------------------------------------------------------

package Check_ping;
require 5.002;
use strict;
use warnings;

sub Check_ping {
    use Junior::Utils;

    ## Parse the commands...
    my ($hostname,$loss_yellow,$loss_red) = split("!", $_[0]);

    ##
    ##  Global values
    ##

    my($Default_tries)       = 10;  ## 10 tries
    my($Default_timeout)     = 10;  ## of 3 seconds each...

    $loss_red     = 100 if (!defined($loss_red));
    $loss_yellow  = 50  if (!defined($loss_yellow));
    
    ## Most OS/es use -c, as god wanted us to. Except, of course,
    ## for HP, which uses -n.

    my($Default_ping_cmd)    = "ping -c 3 \%s";

    my (@output,$avg,$loss,$param);
    my ($tmp,$ret);

    ## Format cmdline
    my $rcmdline = sprintf($Default_ping_cmd, $hostname);

    # The result has some fixed values
    my $res = {};
    $res->{units} = "% lost";
    
    ($ret,@output) = Junior::Utils::timeexec($Default_tries,$Default_timeout,$rcmdline);
    if ($ret != 0) {
        $res->{status}       = 1;
        $res->{message}      = "Probable command timeout";
        $res->{pretty_value} = "Unknown";
        return $res;
    }

    ## We now start looking for the "% loss" output and
    ## N/N/N values

    foreach $param (@output) {
        chomp($param);

        if (!defined($loss)) {
                # Deal with both ping format outputs
                # 3 packets transmitted, 3 received, 0% loss, time 2023ms
                # 3 packets transmitted, 3 packets received, 0% packet loss
            ($loss) = ($param =~ m/received, (\d+)\% (?:packet )?loss/i);
        }

    }
    ## Sanity check 
    if (!defined($loss)) {
        $res->{status}       = 1;
        $res->{message}      = "Cannot determine loss time";
        $res->{pretty_value} = "Unknown";
        return $res;
    }

    ## Check the limits

    if ($loss >= $loss_red) {
        $res->{status}       = 2;
        $res->{message}      = "Loss rate = $loss\% (red mark reached)";
        $res->{graph_value}  = $loss;
        $res->{pretty_value} = $res->{graph_value} . " " . $res->{units};
        return $res;
    }
    elsif ($loss >= $loss_yellow) {
        $res->{status}       = 1;
        $res->{message}      = "Loss rate = $loss\% (yellow mark reached)";
        $res->{graph_value}  = $loss;
        $res->{pretty_value} = $res->{graph_value} . " " . $res->{units};
        return $res;
    }
    else {
        $res->{status}       = 0;
        $res->{message}      = "OK";
        $res->{graph_value}  = $loss;
        $res->{pretty_value} = $res->{graph_value} . " " . $res->{units};
        return $res;
    }
}

1;
