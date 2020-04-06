#!/usr/bin/env perl

use warnings;
use strict;

my $threshold = 5;

sub count {
	my $f = shift;
	my %data;
	while(<$f>) {
		next unless /\-\>/;
		if (/\[([0-9.]+)s\]/) {
			my $n = (split / /)[0];
			my $t = $1;
			$data{$n} = $t;
		}
	}
	%data;
}

open(my $f1, "<$ARGV[0]") or die;
open(my $f2, "<$ARGV[1]") or die;

my %data1 = count($f1);
my %data2 = count($f2);
my @result;

while (my ($n, $t1) = each %data1) {
	next if not exists $data2{$n};
	my $t2 = $data2{$n};
	my $d = $t2 - $t1;
	if ($d > $threshold) {
		push @result, [$d, $n, $t1, $t2];
	}
}

foreach my $i (sort { $b->[0] <=> $a->[0] } @result) {
	my ($d, $n, $t1, $t2) = splice @$i;
	print "$n :\n";
	print "    $t1 <-> $t2\n"
}