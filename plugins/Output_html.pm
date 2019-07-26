#------------------------------------------------------------------------------
#   Output_html
#          this plugin takes *the* angel structure carrying the probes'
#       descriptions and the results, and makes an HTML page from it.
#       se STRUCTURE for a small description of how is this structure,
#       or uncomment the firts line in Output_html: "print(Dumper(@_));"
#
#
#   LEGAL STUFF:
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
#   Revision log:
#
#------------------------------------------------------------------------------
package Output_html;
use English;
use strict;
use warning;
use Data::Dumper::Simple;

sub Output_html {
    # For debug, print what we are given.
    #print(Dumper(@_)); 

    # Get the structure with the probes and the results
    my $all_probes = shift;

    ## Open files
    open (INDEXP,">$main::Indexfile.$$") || die "angel: Cannot open $main::Indexfile ($OS_ERROR)";
    open (ERRORP,">$main::Errorfile.$$") || die "angel: Cannot open $main::Errorfile ($OS_ERROR)";

    # Generate the header of the html file..
    gen_header(\*INDEXP,\*ERRORP,$hosthash);
    
    # Write a table for every group in conf/hosts.conf. Always write the default (no group) first
    gen_table(\*INDEXP,\*ERRORP,\*LEDSCRIPTP,$hosthash->{'default'});
    delete $hosthash->{'default'};
    foreach my $tables (keys %$hosthash) {
            print INDEXP qq{<h1 style="color: white;">$tables</h1>};
            gen_table(\*INDEXP,\*ERRORP,\*LEDSCRIPTP,$hosthash->{$tables});
    }
    
    # Generate the end of the html file.
    gen_footer(\*INDEXP,\*ERRORP);
    
    close(INDEXP);
    close(ERRORP);
    
    ## Move the files to the original ones
    
    rename("$main::Indexfile.$$",  "$main::Indexfile") || die "angel: Cannot rename $main::Indexfile";
    rename("$main::Errorfile.$$",  "$main::Errorfile") || die "angel: Cannot rename $main::Errorfile";
    
    if ($main::Use_ledsign) {
            close(LEDSCRIPT);
            rename("$main::Ledscript.$$", "$main::Ledscript") || die "angel: Cannot rename $main::Ledscript";
    }



}


sub gen_header
{
        my($fpindex,$fperror,$hrhosts) = @ARG;

        my($keyhost,$keylabel,$label,$numcols,$numprt,$pct);
        my($htmltd,$error_host_td,$error_label_td,$error_col_td);

        ## TD designator for the host part of error entries
        $error_host_td  = ($main::Error_host_width   == -1) ? "<td>" : "<td width=\"$main::Error_host_width\">";
        $error_label_td = ($main::Error_label_width  == -1) ? "<td>" : "<td width=\"$main::Error_label_width\">";
        $error_col_td   = ($main::Error_column_width == -1) ? "<td>" : "<td width=\"$main::Error_column_width\">";

        ## Index and Error Headers
        print $fpindex $main::Index_html_header;
        print $fperror $main::Error_html_header;

        ## Should we use ledsign?
        print $fpindex $main::Ledsign_html_header if ($main::Use_ledsign);

        ## Localtime
        print $fpindex "<p>Last updated: " . localtime() . "</p>\n";
        print $fperror "<p>Last updated: " . localtime() . "</p>\n";

}


#-------------------------------------------------------------------------

sub gen_table
{
    my($fpindex,$fperror,$fpscript,$hrhosts) = @ARG;

    my($keyhost,$keylabel,$label,$numcols,$numprt,$pct);
    my($funcname,$funcparms,$ledcolor,$ledfirst);
    my $hrheader = {};
    my($htmltd,$error_host_td,$error_label_td,$error_col_td,$htmlvalue);
    my($funcopts);

    ## TD designator for the index entries
    $htmltd = ($main::Index_column_width == -1) ? "<td>" : "<td width=\"$main::Index_column_width\">";

    ## Index and Error Tables
    print $fpindex "<table border=${main::Index_html_border}>\n";
    print $fpindex "<tr align=center>\n";
    print $fpindex "${htmltd}&nbsp;</td>\n";
    print $fperror "<table border=${main::Error_html_border}>\n";
    print $fperror "<tr align=center>\n";
    print $fperror "${error_host_td}<b>Hostname</b></td>\n";
    print $fperror "${error_label_td}<b>Service</b></td>\n";
    print $fperror "${error_col_td}<b>Error message</b></td>\n";

    # We now create all table headers. hrhosts is a reference to a hash 
    # of hashes. The first hash is the hostname, and the second the label.
    $numcols = 0;

    ## Get all labels from keyhost{host}
    foreach $keyhost (sort keys %$hrhosts) {
        foreach $keylabel (keys %{$hrhosts->{$keyhost}}) {
            #if (!exists($hrheader->{$keylabel})) {
            if ( $hrhosts->{$keyhost}{$keylabel}{html} ne "no" ) {
                                $hrheader->{$keylabel} = 1; ## Set
                                $numcols++;                 ## One more unique column
            }
        }
    }

    ## Print the table. Regular string sort, but "PING" should be first.
    sub PING_first {
        return -1       if $a eq "PING";
        return  1       if $b eq "PING";
        return $a cmp $b;
    }

    foreach my $keylabel (sort PING_first keys %$hrheader ) {
        print $fpindex "${htmltd}$keylabel</td>\n";   ## Print column
    }

    ## TD designator for the host part of error entries
    $error_host_td  = ($main::Error_host_width   == -1) ? "<td>" : "<td width=\"$main::Error_host_width\">";
    $error_label_td = ($main::Error_label_width  == -1) ? "<td>" : "<td width=\"$main::Error_label_width\">";
    $error_col_td   = ($main::Error_column_width == -1) ? "<td>" : "<td width=\"$main::Error_column_width\">";

    ## Get all labels from keyhost{host}
    foreach $keyhost (sort keys %$hrhosts) {
        print $fpindex "<tr>\n";
        print $fpindex "${htmltd}<b>$keyhost</b></td>\n";

        ## If there's a label header matching this host, print
        foreach $keylabel (sort PING_first keys %$hrheader) {
            # Print if there's a match for this line. Skip if the html
            # option is "no" (see hosts.conf).
            if (exists($hrhosts->{$keyhost}{$keylabel}) && 
                $hrhosts->{$keyhost}{$keylabel}{html} ne "no" ) {
                    # 20060316 - DMV
                    # New output plugins infrastructure. Put results in the 
                    # hash then give hash to plugins so they can write
                    # whatever they want.
                    my $status  =   $hrhosts->{$keyhost}{$keylabel}{'status'};
                    my $message =   $hrhosts->{$keyhost}{$keylabel}{'message'};
                    my $title   =   $hrhosts->{$keyhost}{$keylabel}{'title'};
                    my $value   =   $hrhosts->{$keyhost}{$keylabel}{'graph_value'};
                    my $pretty  =   $hrhosts->{$keyhost}{$keylabel}{'pretty_value'};
                    $pretty = $value if (!defined($pretty));
                    my $title   =   $hrhosts->{$keyhost}{$keylabel}{'title'};
                    my $units   =   $hrhosts->{$keyhost}{$keylabel}{'units'};
                    my $id      =   $keyhost."_".$keylabel;

                    # Write the corresponding piece of html in the 
                    # status page (index.html)
                    ###############################################
                    # TODO: This should be taken from a config file
                    my $html_piece;
                    my $graph_url = $main::graph_url .
                                    qq{title=$title&rrdfile=$id}.
                                    qq{&title=$title&units=$units};

                    if ($status == 0) {
                        $html_piece = qq{<td class="green">
                                         <A target="_blank" HREF="$graph_url"> $pretty </A>
                                         </td>};
                    }
                    elsif ($status == 2) {
                        $html_piece = qq{<td class="red">
                                         <a target="_blank" href="$graph_url"> $pretty </a>
                                         </td>};
                    }
                    else {
                        $html_piece = qq{<td><a href="error.html">
                                         <img src="pics/yellow.gif" alt="$message">
                                         </a></td>};
                    }

                    # Print the index entry
                    print $fpindex "$html_piece\n";

                    # Print the error entry (if any)
                    if ($status != 0) {
                        print $fperror "<tr align=center>\n";
                        my (@a) = split('\n', $message);
                        my ($first) = 1;

                        while ($a[0]) {
                            if ($first == 1) {
                                print $fperror "${error_host_td}$keyhost</td>\n";
                                print $fperror "${error_label_td}$keylabel</td>\n";
                            }
                            else {
                                print $fperror "${error_host_td}</td>\n";
                                print $fperror "${error_label_td}</td>\n";
                            }

                            print $fperror "${error_col_td}$a[0]</td>\n";
                            shift @a;
                            print $fperror "</tr>\n";
                            $first++;
                        }
                    }

                    ## Print the ledsign info if we choose to use it
                    if ($main::Use_ledsign) {
                        if (!defined($ledfirst)) {
                            $ledfirst = 0;

                            ## First time, print headers
                            print $fpscript "Do\n";
                            print $fpscript "  ScrollUp delay=50 center=true text=\\gANGEL V$main::Version\n";
                            print $fpscript "  Sleep delay=1500\n";
                            print $fpscript "  ScrollUp delay=50 center=true text=\\b(C) 1998 by\n";
                            print $fpscript "  Sleep delay=1000\n";
                            print $fpscript "  ScrollUp delay=50 center=true text=\\bMarco Paganini\n";
                            print $fpscript "  Sleep delay=1500\n";
                            print $fpscript "  ScrollUp delay=50 center=true text=\\bpaganini\@paganini.net\n";
                            print $fpscript "  Sleep delay=2000\n\n";
                        }

                        if ($status != 0) {
                            ## Choose color
                            if    ($status == 2)    { $ledcolor = "\\r" }
                            elsif ($status == 1)    { $ledcolor = "\\y" }
                            else                    { $ledcolor = "\\r" }

                            print $fpscript "  ScrollLeft delay=30 startspace=1 endspace=80 ";
                            print $fpscript "text=${ledcolor}\[$keyhost/$keylabel]:$message\n";
                        }
                    }
                }
                else {
                    print $fpindex "${htmltd}<img src=\"pics/black.gif\" alt=\"OFF\"></td>";
                }
            }
        }
        print $fpindex "</table>\n";
        print $fperror "</table>\n";
        if ($main::Use_ledsign) {
                print $fpscript "Repeat times=5\n";
        }

}

#-------------------------------------------------------------------------

sub gen_footer {
    my($fpindex,$fperror) = @ARG;

    print $fpindex $main::Index_html_footer;
    print $fperror $main::Error_html_footer;
    return 0;
}

1;
