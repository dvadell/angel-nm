use strict;
use Data::Dumper::Simple;
use Carp;

sub Output_file {
    # For debug. Print what we are given to a file.
    my ($all_probes,$old_probes) = @_;
    open(my $tmp, ">>", "/tmp/angel.tmp.out") || carp "Couldn't open the output: $@";

    foreach my $probe (keys %$all_probes) {
        my $current_object = $all_probes->{$probe};
        print {$tmp} Dumper($current_object->results);
        my $old_object = $all_probes->{$probe};
        print {$tmp} Dumper($old_object->results);
    }
    print {$tmp} "-------------------------------------------------------\n";
    close($tmp);

    return;
}

1;
