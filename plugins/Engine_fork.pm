use strict;
use Parallel::ForkManager;

sub Engine_fork {
    my ($all_probes) = @_;

    # Max 30 processes 
    my $pm = new Parallel::ForkManager(30); 

    foreach my $id (keys %$all_probes) {
        $pm->start and next; # do the fork

        my $current_probe = $all_probes->{$id};
        $current_probe->run();

        $pm->finish; # do the exit in the child process
    }

    $pm->wait_all_children;

    return $all_probes;
}

1;
