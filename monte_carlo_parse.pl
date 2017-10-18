#!/usr/bin/perl -w

=head1 NAME
   monte_carlo_parser.pl

=head1 SYNOPSIS

    USAGE: monte_carlo_parser.pl -i=orf_output.txt

=head1 OPTIONS

B<--input_cluster, -i1>
    Required. Results from orf_analysis pipeline. 

B<--help,-h>
    Help message

=head1  DESCRIPTION
        Creates a frequency table of functional terms vs how often they occur.

=head1  INPUT
        Cytoscape metadata file generated from the orf_analysis output.

=head1  CONTACT
        Zach Schreiber @ zschreib[at]gmail[dot]com

=head1 EXAMPLE
        orf_identifier.pl -i=ABC.txt

=cut

use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use List::Util qw(min max sum);

my %options = ();
my $results = GetOptions (\%options,
                                                  'input|i=s',
                                                  'help|h') || pod2usage();
#### display documentation
if( $options{'help'} ) {
  pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} );
}
##


## user input error flags
die "Missing input file! -i\n" unless $options{input};
##

## vars 
my $infile = $options{input};
my @arr = [];
my $freq;
my $term1;
my $term2;
my %hash = ();
my $total;
my $sc;
##

open(IN,"<$infile") || die "\n Cannot open the infile: $infile\n";
my $dummy=<IN>;

while(<IN>) {
    chomp $_;
    @arr = split(/\t/, $_);
    $freq = $arr[2];
    $term1 = $arr[4];
    $term2 = $arr[11];
    push ( @{$hash{$term1}{$term2}}, $freq);
}


foreach my $val (keys %hash){
        foreach my $val2 (keys %{$hash{$val}} ){
                my $count = sum (@{$hash{$val}{$val2}});
		#my $scale = scalar (@{$hash{$val}{$val2}});
		$total += $count;
		#$sc += $scale;
        }
}

foreach my $val (keys %hash){
	foreach my $val2 (keys %{$hash{$val}} ){
		my $count = sum (@{$hash{$val}{$val2}});
		my $avg = $count/$total;
		print "$val\t$val2\t$avg\n";
	}
}

#print Dumper(\%hash);
