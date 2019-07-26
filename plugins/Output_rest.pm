use strict;
use Data::Dumper::Simple;
use Carp;
use LWP::UserAgent;
use JSON;

sub Output_rest {
    my ($all_probes,$old_probes) = @_;
    my $ua = LWP::UserAgent->new;

    foreach my $probe (keys %$all_probes) {
        my $current_object = $all_probes->{$probe};
        my $json = objToJson($current_object->results);
        my $req = HTTP::Request->new("POST", 'http://this.enterprise.com.ar:3000/incoming/test');

        $req->content_type('text/x-json');
        $req->content($json);

        my $res = $ua->request($req);

        # Check the outcome of the response
        if ($res->is_success) {
            print $res->content . "\n";
        }
        else {
            print $res->status_line, "\n";
        }
    }
    return;
}

1;
