# This is the object that will contain one probe.

package Junior::Probe;

# This makes setters and getters automatically 
use base Class::Accessor;
Junior::Probe->mk_accessors( qw/module cmdline options long_description results id group tolerance every every_count/ );
use Data::Dumper::Simple;

# Make a new probe object
# It has 5 arguments
sub new {
    my ($class) = $_[0];
    my $self = {};
    bless $self, $class;

    $self->id($_[1]);
    $self->module($_[2]);
    $self->cmdline($_[3]);
    $self->options($_[4]);

    return $self;
}

# Run the probe!
sub run {
    my ($self,$old_probes,$stash) = shift;

    # 'require' the module (untainted).
    my $module = $self->module;
    $module =~ /(Check_[0-9a-zA-Z]+)/;
    require $1 . ".pm";

    print "About to run: $module(" . $self->cmdline . "): \n";
    print $self->long_description . "\n";

    # Name of the function (i.e. Check_ping::Check_ping).
    my $func = $self->module . "::" . $self->module;

    # Run
    no strict;
    my $res = &$func($self->cmdline,$old_probes,$stash);
    use strict;

    # Add to the results the misc options in $self->options
    foreach my $pair ( split("!", $self->options) ) {
        my ($key , $value) = split("=", $pair);
        $res->{$key} = $value if ( !defined($res->{$key}) )
    }
    

    # Save
    $res->{keyname}     = $self->id;
    $res->{module}      = $self->module;
    $res->{cmdline}     = $self->cmdline;
    $res->{options}     = $self->options;
    $res->{group}       = $self->group;
    $res->{tolerance}   = $self->tolerance;
    $res->{every}       = $self->every;
    $res->{every_count} = $self->every_count;

    # If the plugin does not return any status, status is yellow
    $res->{status} = 1 if ( !defined $res->{status} );
    $self->results($res);
}

1;
