#!/bin/bash

rrdtool fetch $1 AVERAGE -s -1h | perl -ne 'my $line = $_; my ($time, $rest) = split(": ", $line); print "$time " . localtime($time) . " " . $rest;'
