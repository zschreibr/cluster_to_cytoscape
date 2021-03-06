#!/usr/bin/perl -w

=head1 NAME
   orf_identifier.pl

=head1 SYNOPSIS

    USAGE: orf_identifier.pl -i1=library.clstr -i2=metadata.txt -db=name_of_database -type=co

=head1 OPTIONS

B<--input_cluster, -i1>
    Required. Input cd-hit cluster file that will be used to generate a network.

B<--input_metadata, -i2>
    Required. Input metadata file. File should contain same library prefix as those in cluster file.

B<--output, -o>
    Required. Output file path. 

B<--database_type, -db>
    Required. Name of database (must be ACLAME,COG,KEGG,SEED,PHGSEED, or GO). This will generate the headers.

B<--analysis_type, -type>
    Required. Name of analysis (must be co, adj, or prox).

B<--aa_cutoff, -ac>
    Optional only for prox_L analysis. Changes length of amino acid cutoff between ORFs. Default is 1000.

B<--orf_cutoff, -oc>
    Optional only for prox_D analysis. Changes number of ORFs that will be counted either up or down stream of analysis. Default is 4.
    This number may vary depending on how large the input viral genomes are.  

B<--help,-h>
    Help message

=head1  DESCRIPTION
        Generates a cytoscape file with metadata tags assigned to source/target interactions

=head1  INPUT
	Cd-hit cluster file along with a metadata file containingg top hits for viral ORFS.

=head1  OUTPUT
	Source/Target/Edge interactions along with assigned metadata tags.

=head1  CONTACT
        Zach Schreiber @ zschreib[at]gmail[dot]com

=head1 EXAMPLE
	orf_identifier.pl -i1=clusterfile.clstr -i2=metadata.txt -o=/home/output/ -db=ACLAME -type=prox_D -oc=8

=cut

use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use List::Util qw(min max);
use File::Basename;

my %options = ();
my $results = GetOptions (\%options,
                                                  'input_cluster|i1=s',
                                                  'input_metadata|i2=s',
						  'output|o=s',
                                                  'database_type|db=s',
						  'analysis_type|type=s',
						  'aa_cutoff|ac:i',
						  'orf_cutoff|oc:i',
                                                  'help|h') || pod2usage();
#### display documentation
if( $options{'help'} ) {
  pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} );
}

##user input error flags
die "Missing input cluster file! -i1\n" unless $options{input_cluster};
die "Missing metadata file! -i2\n" unless $options{input_metadata};
die "Missing file output location! -o\n" unless $options{output};
die "Missing database name! -db\n" unless $options{database_type};
die "Missing analysis type! -type\n" unless $options{analysis_type}; 
##end error flags

##user input
my $infile = $options{input_cluster};
my $metadata = $options{input_metadata};
my $out_path = $options{output};
my $db = $options{database_type};
my $analysis = $options{analysis_type};
my $ac = $options{aa_cutoff};
my $oc = $options{orf_cutoff};
my $default;
my $id = fileparse($infile, qr/\.[^.]*/);

my $filename = $id . "_" . $analysis . "_" . $db;
## end user input

## analysis variables and header format
my ($orf_id, $stop_id, $start_id, $contig_id, $cluster_id, $whole_orf_id, @a, @orfs,);
my %eval = (); ## chooses lowest evalue for cluster set 
my %HoH = ();  ## Hash of hashes for orfs along a contig
## 'CNS_sngl100000048169' => {
##                            'START' => '1',
##                            'STOP' => '60',
##                            'POSITION' => '1',
##                            'CLUSTER' => '4'
##                           }

my %orfs = ();         # captures each orf in a cluster
my $rHoH = \%HoH;      #contig data
my %cyto_results = (); #cytoscape results
my %metadata = ();     #metadata tags

open(OUTPUT, ">$out_path" . $filename) or die "Could not open file '$filename' $!";
my $name = "Source\tTarget\tEdge\tORF_name\ttop_hit_description\t";

##Applies proper header to metadata file based off input DB
if($db =~ /aclame/i){
        print OUTPUT $name . "ACLAME_fxn_1" . "\t" . "ACLAME_fxn_2" . "\t" . "ACLAME_hexcolor" . "\t" . "ACLAME_fxn_3" . "\t" . "cluster_size" . "\t" .
		     "ORF_name" . "\t" . "top_hit_description" . "\t" . "ACLAME_fxn_1" . "\t" . "ACLAME_fxn_2" . "\t" . "ACLAME_hexcolor" . "\t" . "ACLAME_fxn_3" . "\t" . "cluster_size" . "\n";
}
elsif($db =~ /cog/i){
        print OUTPUT $name . "COG_fxn_1" . "\t" . "COG_fxn_2" . "\t" . "COG_hexcolor" . "\t" . "COG_fxn_3" . "\t" . "cluster_size" . "\t" .
		     "ORF_name" . "\t" . "top_hit_description" . "\t" . "COG_fxn_1" . "\t" . "COG_fxn_2" . "\t" . "COG_hexcolor" . "\t" . "COG_fxn_3" . "\t" . "cluster_size" . "\n";
}
elsif($db =~ /kegg/i){
        print OUTPUT $name . "KEGG_fxn_1" . "\t" . "KEGG_hexcolor" . "\t" . "KEGG_fxn_2" . "\t" . "KEGG_fxn_3" . "\t" . "cluster_size" . "\t" .
                     "ORF_name" . "\t" . "top_hit_description" . "\t" . "KEGG_fxn_1" . "\t" . "KEGG_hexcolor" . "\t" . "KEGG_fxn_2" . "\t" . "KEGG_fxn_3" . "\t" . "cluster_size" . "\n";
}
elsif($db =~ /^seed$/i){
        print OUTPUT $name . "SEED_fxn_1" . "\t" . "SEED_hexcolor" . "\t" . "SEED_fxn_2" . "\t" . "SEED_fxn_3" . "\t" . "cluster_size" . "\t" .
                     "ORF_name" . "\t" . "top_hit_description" . "\t" . "SEED_fxn_1" . "\t" . "SEED_hexcolor" . "\t" . "SEED_fxn_2" . "\t" . "SEED_fxn_3" . "\t" . "cluster_size" . "\t" . "cluster_size" . "\n";
}
elsif($db =~ /^phgseed$/i){
        print OUTPUT $name . "PHGSEED_fxn_1" . "\t" . "PHGSEED_fxn_2" . "\t" . "PHGSEED_hexcolor" . "\t" . "PHGSEED_fxn_3" . "\t" . "cluster_size" . "\t" .
                      "ORF_name" . "\t" . "top_hit_description" . "\t" . "PHGSEED_fxn_1" . "\t" . "PHGSEED_fxn_2" . "\t" . "PHGSEED_hexcolor" . "\t" . "PHGSEED_fxn_3" . "\t" . "cluster_size" . "\n";
}
elsif($db =~ /go/i){
        print OUTPUT $name . "GO_fxn_1" . "\t" . "GO_fxn_2" . "\t" . "GO_fxn_3" . "\t" . "GO_fxn_4" . "\t" . "cluster_size" . "\t" .
		     "ORF_name" . "\t" . "top_hit_description" . "\t" . "GO_fxn_1" . "\t" . "GO_fxn_2" . "\t" . "GO_fxn_3" . "\t" . "GO_fxn_4" . "\t" . "cluster_size" . "\n";
}
else{
	die "$db is not a valid database choice!\n"
}

open(IN,"<$infile") || die "\n Cannot open the infile: $infile\n";

## Parse input cluster file and save each header value of ORF on contig into hash
while(<IN>) {
    chomp $_;
    if ($_ =~ m/^>/) {
        $cluster_id = $_;
        $cluster_id =~ s/>Cluster //;      #Cluster number
    }

    else {
        $whole_orf_id = $_;
        $whole_orf_id =~ s/.*>//;
        $whole_orf_id =~ s/\.\.\..*//;
	push(@{$orfs{$cluster_id}}, $whole_orf_id);

        @a = split(/_/, $whole_orf_id);    #full header => ABC_ctg12352124134_23_430_1
        $orf_id = pop(@a);                 #orf position on the contig => 1
        $stop_id = pop(@a);                #stopping position of orf on contig => 430
        $start_id = pop(@a);               #starting position of orf on contig => 23
    	my $con = pop(@a);
	my $fakemgol = pop(@a);
	$fakemgol =~ s/\d//g;
	$fakemgol =~ s/[\-]//g;
	#$contig_id = join("_", @a);        #contig id => ABC_ctg12352124134
	$contig_id = $fakemgol . "_" . $con;        
#	print $contig_id . "\n";
	$HoH { $contig_id }{ 'POSITION' }[$orf_id-1] = $orf_id;
	$HoH { $contig_id }{ 'CLUSTER' }[$orf_id-1]  = $cluster_id;
	$HoH { $contig_id }{ 'START' }[$orf_id-1]    = $start_id;
	$HoH { $contig_id }{ 'STOP' }[$orf_id-1]     = $stop_id;
    }
}

close(IN);

## end input parser 

## end header format 

print "### STARTING $analysis ANALYSIS ### \n\n";

## processing stage for selected analysis type
if($analysis eq "co"){
	&co_occurence($rHoH);
}

elsif($analysis eq "adj"){
	&adj($rHoH);
}

elsif($analysis eq "prox_L"){
	if(defined $ac){
	&prox_L($rHoH, $ac);
	}
	elsif(!defined $ac){
		$default = 1000;
		print "Either no amino acid cutoff was selected for $analysis or an invalid integer was entered. The default value of $default will be used.\n"; 
		&prox_L($rHoH, $default);
	}
}

elsif($analysis eq "prox_D"){
        if(defined $oc){
        &prox_D($rHoH, $oc);
        }
        elsif(!defined $oc){
                $default = 2;
                print "Either no ORF distance cutoff was selected for $analysis or an invalid integer was entered. The default value of $default will be used.\n";
                &prox_D($rHoH, $default);
        }
}

else{
	die "$analysis is not a valid analysis type\n";
}

close(OUTPUT);
##end processing 


########################SUBROUTINES#################################

#### COOCCURENCE SUB ####
## INPUT  :: hash of hashes representing ORFS along a contig
## OUTPUT :: cytoscape formatted file representing ORFS that are co-occuring with eachother

sub co_occurence {

my %rHoH = %{$_[0]};

foreach my $ctgid (keys %$rHoH){
     for (my $i=0; $i < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $i++){
        if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
          for (my $j = $i+1; $j < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $j++) {
                if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
                   my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
                   my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];		   
                   $cyto_results{$a}{$b}++;
                }
          }
	}
    	
        else{
              print STDERR "\n Error: Missing ORF at position $i for $ctgid. This ORF will be removed from the list.\n";
        }

	for (my $j = $i-1; $j >= 0; $j--) {
               	if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
                      if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
                                       	my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
                                       	my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
                                        $cyto_results{$a}{$b}++;
                      }
                }
                else{
                 print STDERR "\n Error: Missing ORF at reverse search position $i for $ctgid. This ORF will be removed from the list.\n";
                }
        }
    }
}

&metadata(\%orfs);
&process(\%cyto_results);
}

#### END COOCCURENCE SUB ####

#### ADJ SUB ####
## INPUT  :: hash of hashes representing ORFS along a contig 
## OUTPUT :: cytoscape formatted file representing ORFS that are only adjacent to eachother

sub adj {

my %rHoH = %{$_[0]};

foreach my $ctgid (keys %$rHoH){
     for (my $i=0; $i < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $i++){
          if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
        	#print $ctgid . "\t" . $i . "\t" . $rHoH->{$ctgid}{'CLUSTER'}[$i] . "\n";
        	#print $ctgid . "\t" .  $rHoH->{$ctgid}->{'POSITION'} . "\n";
        	for (my $j = $i+1; $j < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $j++) {
			if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
               		my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
               		my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
               		#my $above = $rHoH->{$ctgid}->{'POSITION'}[$i] + 1;
               		#my $below = $rHoH->{$ctgid}->{'POSITION'}[$i] - 1;
			my $match = $rHoH->{$ctgid}->{'POSITION'}[$j];
               		my $ref = $rHoH->{$ctgid}->{'POSITION'}[$i];
        			if ($ref + 1 == $match || $ref -1 == $match){
              				$cyto_results{$a}{$b}++;
               			}
#			print "$a\t$b\t $match\t$ref\t UP \n";
			}
       	        }
          }
         else{
              print STDERR "\n Error: Missing ORF at position $i for $ctgid. This ORF will be removed from the list.\n";
         }

	for (my $j = $i-1; $j >= 0; $j--) {
          if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
             if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
                        my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
                        my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
                        #my $above = $rHoH->{$ctgid}->{'POSITION'}[$i] + 1;
                        #my $below = $rHoH->{$ctgid}->{'POSITION'}[$i] - 1;
                        my $match = $rHoH->{$ctgid}->{'POSITION'}[$j];
                        my $ref = $rHoH->{$ctgid}->{'POSITION'}[$i];
                                if ($ref +1 == $match || $ref - 1 == $match ){
                                        $cyto_results{$a}{$b}++;
                                }
		        #print "$a\t$b\t $match\t$ref\t DOWN \n";
             }
           }
            else{
             print STDERR "\n Error: Missing ORF at reverse search position $i for $ctgid. This ORF will be removed from the list.\n";
            }
	}

    }
}
&metadata(\%orfs);
&process(\%cyto_results);

}

#### END ADJ SUB ####

#### PROX SUB ####
## INPUT  :: hash of hashes representing ORFS along a contig
## OUTPUT :: cytoscape formatted file representing ORFS that are within the specified range or lenged depending on analysis chosen

## DUE TO FORWARD AND REVERSE TRANSCRIPTION FOR START AND STOP POSITIONS
## TEST CASE MUST BE MADE TO DETERMINE PROXIMAL CUTOFF
## + = forward (ex start_a 1 stop_a 300)
## - = reverse (ex start_a 300 stop_a 1)

## CASE 1:
        ## + + STOP_A to START_B
## CASE 2:
        ## - + START_A to START_B
## CASE 3:
        ## + - STOP_A to STOP_B
## CASE 4:
        ## - - START_A to STOP_B


##### PROXIMAL RANGE FOR AMINO ACID LENGTH ####

sub prox_L {

my %rHoH = %{$_[0]};
my $prox = $_[1];

foreach my $ctgid (keys %$rHoH){
     for (my $i=0; $i < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $i++){
        if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
        for (my $j = $i+1; $j < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $j++) {
	      if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
              my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
              my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
              my $start_a  = $rHoH->{$ctgid}->{'START'}[$i];
              my $stop_a   = $rHoH->{$ctgid}->{'STOP'}[$i];
              my $start_b  = $rHoH->{$ctgid}->{'START'}[$j];
              my $stop_b   = $rHoH->{$ctgid}->{'STOP'}[$j];

       			#++ forward forward
       			if($stop_a - $start_a >= 0 && $stop_b - $start_b >= 0){
          			if(abs($stop_a - $start_b) < $prox){
                 			$cyto_results{$a}{$b}++;
          			}
       			}
       			#-- reverse reverse
       			elsif($stop_a - $start_a <= 0 && $stop_b - $start_b <= 0){
          			if(abs($start_a - $stop_b) < $prox){
                 			$cyto_results{$a}{$b}++;
         			}
       			}
       			#+- forward reverse
       			elsif($stop_a - $start_a >= 0 && $stop_b - $start_b <= 0){
          			if(abs($stop_a - $stop_b) < $prox){
                 			$cyto_results{$a}{$b}++;
         			}
       			}
       			#-+ reverse forward
       			elsif($stop_a - $start_a <= 0 && $stop_b - $start_b >= 0){
          			if(abs($start_a - $start_b) < $prox){
                 			$cyto_results{$a}{$b}++;
         			}
       			}
			else{
				last;
			    }
		}
	    }     
	 }  
	
	else{
              print STDERR "\n Error: Missing ORF at forward search position $i for $ctgid. This ORF will be removed from the list.\n";
        }

      for (my $j = $i-1; $j >= 0; $j--) { 
	if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
	      if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
      	      my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
              my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
              my $start_a  = $rHoH->{$ctgid}->{'START'}[$i];
              my $stop_a   = $rHoH->{$ctgid}->{'STOP'}[$i];
              my $start_b  = $rHoH->{$ctgid}->{'START'}[$j];
              my $stop_b   = $rHoH->{$ctgid}->{'STOP'}[$j];
              #my $prox = 1000;

                        #++ forward forward
                       	if($stop_a - $start_a > 0 && $stop_b - $start_b > 0){
                               	if(abs($stop_a - $start_b) < $prox){                                         
                                       	$cyto_results{$a}{$b}++;
                               	}
                        }
                       	#-- reverse reverse
                       	elsif($stop_a - $start_a < 0 && $stop_b - $start_b < 0){
                                if(abs($start_a - $stop_b) < $prox){
                                       	$cyto_results{$a}{$b}++;
                                }
                       	}
                       	#+- forward reverse
                        elsif($stop_a - $start_a > 0 && $stop_b - $start_b < 0){
                                if(abs($stop_a - $stop_b) < $prox){
                                       	$cyto_results{$a}{$b}++;
                                }
                       	}
                        #-+ reverse forward
                        elsif($stop_a - $start_a < 0 && $stop_b - $start_b > 0){
                               	if(abs($start_a - $start_b) < $prox){
                                        $cyto_results{$a}{$b}++;
                                }
                        }
                       	else{
                             	last;
                            }
		}
	}
       	else{
              print STDERR "\n Error: Missing ORF at reverse search position $i for $ctgid. This ORF will be removed from the list.\n";
        }

      }
   }
}
&metadata(\%orfs);
&process(\%cyto_results);

}

#### END PROX LENGTH ####


#### PROX DISTANCE ####

sub prox_D {

my %rHoH = %{$_[0]};
my $dist = $_[1];

foreach my $ctgid (keys %$rHoH){
	for (my $i=0; $i < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $i++){
       		if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
        		for (my $j = $i+1; $j < scalar(@{$rHoH->{$ctgid}->{'CLUSTER'}}); $j++) {
              			if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
					my $orig = $rHoH->{$ctgid}->{'POSITION'}[$i];
                        		my $ref = $rHoH->{$ctgid}->{'POSITION'}[$j];
					my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
                   			my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
					if($ref <= $dist){
                                        #print "$ctgid\t$a\t$b\t$orig\t$ref\tUP\n";
					$cyto_results{$a}{$b}++;
					}
				}
			}
		}
	        else{
                 print STDERR "\n Error: Missing ORF at reverse search position $i for $ctgid. $ctgid. This ORF will be removed from the list.\n";
                }

	for (my $j = $i-1; $j >= 0; $j--) {
        	if(exists $rHoH->{$ctgid}->{'POSITION'}[$i]){
	              if(exists $rHoH->{$ctgid}->{'POSITION'}[$j]){
                                        my $orig = $rHoH->{$ctgid}->{'POSITION'}[$i];
                                        my $ref = $rHoH->{$ctgid}->{'POSITION'}[$j];
                                        my $a = $rHoH->{$ctgid}->{'CLUSTER'}[$i];
                                        my $b = $rHoH->{$ctgid}->{'CLUSTER'}[$j];
                                        if($orig <= $dist){
                                        #print "$ctgid\t$a\t$b\t$orig\t$ref\tDOWN\n";
					$cyto_results{$a}{$b}++;
                                        }
                      }
                }
                else{
                 print STDERR "\n Error: Missing ORF at reverse search position $i for $ctgid. $ctgid. This ORF will be removed from the list.\n";
                }
        }

	} 
}
&metadata(\%orfs);
&process(\%cyto_results);
}

#### END PROX DISTNACE ####


#### END PROX SUB ####

#### PROCESSING SUB  ####
## INPUT  ::  analysis results
## OUTPUT :: cluster number along with how often that cluster pair matches analysis type
## OUTPUT :: metadata tags for represtentative clusters

sub process {
  print "Results are now being processed into a cytoscape format ...\n\n";
  sleep 1;
  my %cyto_results = %{$_[0]};

  foreach my $a (keys %cyto_results) {
     foreach my $b (keys %{$cyto_results{$a}}){
             if ($cyto_results{$a}{$b} > 0 ){
                         if(exists $metadata{$a}){
				if(exists $metadata{$b}){
                                        foreach my $data_a (min keys %{$metadata{$a}}){
					  foreach my $data_b (min keys %{$metadata{$b}}){
                                                print  OUTPUT $a . "\t" . $b . "\t" . $cyto_results{$a}{$b} . "\t" . $metadata{$a}{$data_a} . "\t" . $metadata{$b}{$data_b} . "\n";
					  }
					}
			   	} 
			 }
			 else{
			 print STDERR "NO $metadata{$a} or $metadata{$b}" . "\n";
			 }
	     }
    }
  }
  print "Process finished ...\n\n";
  sleep 1;
}
#### METADATA SUB ####
## INPUT  :: array of orfs 
## OUTPUT :: single ORF that best represents that array of ORFS using lowest evalue 

sub metadata {

print "Metadata tags are being assigned to cd-hit results for $analysis analysis ...\n\n";
sleep 1;
my %orf = %{$_[0]};

open(META,"<$metadata") || die "\n Cannot open the infile: $infile\n";
     
     while(<META>){
		      chomp;
		      my @vals = split("\t", $_);
	              my $header = $vals[0];
		      my $evalue = $vals[1];
		      shift @vals;
		      shift @vals;  ##removes header and evalue from data
		      $eval{$header}{$evalue} = join("\t", @vals);
		      
     }

close(META);

     foreach my $orf (keys %orfs){
	foreach (@{$orfs{$orf}}){
	  my $count = scalar(@{$orfs{$orf}}); #counts number of ORFs in each cluster
	  my $new = $_;
	  my @arr = split ("_", $new);
          my $front = shift(@arr);
	  my $ctg = shift(@arr);
	  $front =~ s/\d//g;
          $front =~ s/[\-]//g;
	  my $tail = join("_", @arr);
	  $new = $front . "_" . $ctg . "_" . $tail;

	     if(exists $eval{$new}){
		  foreach my $eval (keys %{$eval{$new}}){
			#Saves ORF id and eval into metadata file 
			$metadata{$orf}{$eval} = $new . "\t" . $eval{$new}{$eval} . "\t" . $count;
		  }
	     }
	     else{      
			if($db =~ /aclame/i){
		  	$metadata{$orf}{1} = $new . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "#d3d3d3" . "\t" . "Unknown" . "\t" . $count;
		        }
			if($db =~ /cog/i){
                        $metadata{$orf}{1} = $new . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "#d3d3d3" . "\t" . "Unknown" . "\t" . $count;
                        }
			if($db =~ /kegg/i){
                        $metadata{$orf}{1} = $new . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "#d3d3d3" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . $count;
                        }
			if($db =~ /seed/i){
                        $metadata{$orf}{1} = $new . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "#d3d3d3" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . $count;
                        }
			if($db =~ /phgseed/i){
                        $metadata{$orf}{1} = $new . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "#d3d3d3" . "\t" . "Unknown" . "\t" . $count;
                        }
			if($db =~ /go/i){
                        $metadata{$orf}{1} = $new . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . "Unknown" . "\t" . $count;
                        }
	     }
	}
     }

print "Metadata tag assignment finished ...\n\n";
sleep 1;
}

########################SUBROUTINES END#################################
my $end_run = time();
my $run_time = $end_run - $^T;

print "### FINISHED ANALYSIS in $run_time seconds ### \n";

exit 0;
