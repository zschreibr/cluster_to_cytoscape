#!/usr/bin/perl -w

use warnings;
use strict;
use DBI;

## DATABASE INFO ###
open(ACCESS_INFO, ">") || die "Can't access login credentials";
# assign the values in the accessDB file to the variables
my $userid = <ACCESS_INFO>;
my $passwd = <ACCESS_INFO>;
# the chomp() function will remove any newline character from the end of a string
chomp ($userid, $passwd);
# close the accessDB file
close(ACCESS_INFO);

my $file = $ARGV[0];
my @a = [];
my %color = (
"ACLAME-based subsystems" => "#990000", 
"Bacteriophage integration/excision/lysogeny" => "#330000",
"Bacteriophage structural proteins" => "#FF0000",
"Clusters of unknown function" => "#FF330000",
"Experimental" => "#FF6600",
"Lysogenic conversion, toxin production" => "#FF9900",
"Nucleotide metabolism" => "#999900",
"Other" => "#000000",
"Oxidative stress" => "#FF33CC",
"Pathogenicity islands" => "#669900",
"Phage family-specific subsystems" => "#009900",
"Phage functional modules" => "#3300CC",
"Phage lysis" => "#000066",
"Phage replication" => "#0099FF",
"Phage virion proteins" => "#CC00FF",
"Phages, Prophages, Transposable elements" => "#660066", 
"Prophage, Transposon" => "#00FF66",
"Regulation of Expression" => "#006666",
"RNA processing and modification" => "#333300",
"Shiga toxin cluster" => "#00CCCC",
"Superinfection Exclusion" => "#3300FF",
"Toxins and superantigens" => "#FFFF00",
"Transcription" => "#00CC00",

);

my @head = split('_', $file);
my $db = $head[1];
my $libid = $head[0];

my $prefix = MySQL("select prefix from library_metadata where libraryId=$libid and in_mgol=1;");

my $filename = $prefix . "_" . $db . ".txt";

open(OUTPUT, '>', $filename) or die "Could not open file '$filename' $!";

print OUTPUT "query_name" . "\t" . "PHGSEED_e_value" . "\t" . "top_hit_description" . "\t" . "PHGSEED_fxn_1" . "\t" . "PHGSEED_fxn_2" . "\t" . "PHGSEED_hexcolor" . "\t" . "PHGSEED_fxn_3" . "\n";

open(my $fh, '<:encoding(UTF-8)', $file)
  or die "Could not open file '$file' $!";

while (my $row = <$fh>) {
  chomp $row;
  @a = split('\t', $row);
    foreach my $key (keys %color){
	if(lc($a[5]) eq lc($key)){
	print OUTPUT  $a[0] . "\t" . $a[1] . "\t" . $a[2] . "\t" . $a[4] . "\t" . $a[5] . "\t" . $color{$key} . "\t" . $a[6] . "\n";
	}
     }
} 

close $fh;

close OUTPUT;

unlink $file;




#########################################################################


sub MySQL
{
    # establish connection with 'serverDNA' database
    my $connection = DBI->connect("DBI:mysql:app_info_devel",$userid,$passwd);
    my $query = shift;  #assign argument to string
    my $statement = $connection->prepare($query);   #prepare query

    $statement->execute();   #execute query

    #loop to print MySQL results
    while (my @row = $statement->fetchrow_array)
    {       local $" = "\t";
            return "@row";
    }
}

########################################################################

