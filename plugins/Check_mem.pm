#------------------------------------------------------------------------------
#   Check_mem
#
#------------------------------------------------------------------------------

package Check_mem;
require 5.002;
use strict;
#use Junior::Utils;

sub Check_mem {
    my ($cmdline, $old_probes, $stash) = @_;
    my ($memory_type, $max) = split('!',$cmdline);

    # We put the contets of /proc/meminfo into $meminfo
    # as we are only returning one value, we cache the rest in the stash.
    # also, we check if there is something already in the stash, and if it is old.
    my $meminfo = {};
    if ( $stash->{Check_mem}->{meminfo}->{timestamp} && 
         $stash->{Check_mem}->{meminfo}->{timestamp} > $main::start_time) {  # not old
             $meminfo = $stash->{Check_mem}->{meminfo};
    }
    else {
        open(my $fh, "<", "/proc/meminfo") or die "Couldn't open meminfo: $!";
        my @meminfo_lines = <$fh>;
        # MemTotal:      1026160 kB   # Mapped:          81972 kB
        # MemFree:         16412 kB   # Slab:            18768 kB
        # Buffers:         77728 kB   # Cached:         452656 kB
        # SwapCached:          0 kB   # Active:         565224 kB
        # Inactive:       309796 kB   # HighTotal:      121728 kB
        # HighFree:          248 kB   # LowTotal:       904432 kB
        # LowFree:         16164 kB   # SwapTotal:     1004020 kB
        # SwapFree:      1004020 kB   # Dirty:             188 kB
        # Writeback:           0 kB   # AnonPages:      344644 kB
        # SReclaimable:    10092 kB   # SUnreclaim:       8676 kB
        # PageTables:       3164 kB   # NFS_Unstable:        0 kB
        # Bounce:              0 kB   # CommitLimit:   1517100 kB
        # Committed_AS:   934076 kB   # VmallocTotal:   114680 kB
        # VmallocUsed:     60664 kB   # VmallocChunk:    53748 kB
        # HugePages_Total:     0      # HugePages_Free:      0
        # HugePages_Rsvd:      0      # Hugepagesize:     4096 kB

        map {
            chomp;
            my ($key, $value) = split(":");
            $value = $value + 0;
            $meminfo->{$key} = $value;
        } @meminfo_lines;

        # SwapUsed and MemUsed are two types that are not in /proc/meminfo but we calculate
        $meminfo->{MemUsed}  = $meminfo->{MemTotal} - $meminfo->{MemFree};
        $meminfo->{SwapUsed} = $meminfo->{SwapTotal} - $meminfo->{SwapFree};

        $stash->{Check_mem}->{meminfo} = $meminfo;
    }

    my $res = {};
    $res->{units} = "bytes";

    # Check if we got a bogus memory type, which does not appear in /proc/meminfo
    if (!defined($meminfo->{$memory_type})) {
        $res->{status} = 1;
        $res->{message} = "Unknown memory type $memory_type";
        $res->{pretty_value} = "Config ERR";
        return $res;
    }

    $meminfo->{$memory_type} = $meminfo->{$memory_type} * 1024; # bytes please
    $res->{graph_value}  = $meminfo->{$memory_type};
    $res->{pretty_value} = sprintf( "%.3f", $meminfo->{$memory_type} / (1024 * 1024) ) . "Mb";

    # If $max is not defined, then its because we just want to record
    # the value, without alarms.
    if ( defined($max) && ($meminfo->{$memory_type} >= $max) ) {
        $res->{status}      = 2; 
        $res->{message}     = "$memory_type exceeds $max";
        return $res;
    }

    # If we're here, no errors were found
    $res->{status}       = 0; 
    $res->{message}      = "OK";
    return $res;
}
1;
