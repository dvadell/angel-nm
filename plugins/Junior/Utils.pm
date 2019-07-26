package Junior::Utils;
use Proc::Simple;
use Data::Dumper::Simple;

sub timeexec {
    my ($tries,$timeout,$cmd) = @_;
    my $tempfile = "/tmp/timeexec.$$";

    # Run the command. PATH should be set for taint mode (see perlsec)
    $ENV{PATH} = "/bin:/usr/bin";
    my $myproc = Proc::Simple->new();
    $myproc->start("$cmd >$tempfile 2>&1");

    while ($tries) {
        last if (! $myproc->poll());
        sleep($timeout);
        $tries--;
    }

    ## We timed out...
    if ($tries == 0) {
        $myproc->kill();
        unlink($tempfile);
        return(-1,());
    }

    ## Load the tempfile into out @cmd_output array
    open (my $tempfh, '<', "$tempfile") || return (-1, ());
    my @cmd_output = <$tempfh>;
    close($tempfh);

#    unlink($tempfile);
    return(0, @cmd_output);

}

1;
