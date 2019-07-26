use strict;
use Data::Dumper::Simple;

sub Engine_serial {
    my ($all_probes,$old_probes,$stash) = @_;

    foreach my $id (keys %$all_probes) {
        my $current_probe = $all_probes->{$id};
        my $old_probe     = $old_probes->{$id};

        # Handle the "every" directive. It tells how often we have
        # to run the plugins. "every 1" means always. "every 30" 
        # means every 30 runs.
        print Dumper($old_probe);
    
        # If this is the first time we run, just plain run everything
        if (!defined($old_probe)) {
            $current_probe->run($old_probes,$stash);
            next;
        }

        my $every_count = 1 if ( !($current_probe->every) );
        if ( !defined($old_probe->{every_count}) ) {
            $every_count = $current_probe->every;
        }
        else {
            $every_count = $old_probe->{every_count};
        }

        # If we still have to skip this probe...
        if ($every_count > 1) {
            $all_probes->{$id} = $old_probes->{$id};
            $all_probes->{$id}->{every_count} = $every_count - 1;
        } 
        else {
            $current_probe->every_count($current_probe->every);
            $current_probe->run($old_probes,$stash);
        }
    }

    return $all_probes;
}

1;
