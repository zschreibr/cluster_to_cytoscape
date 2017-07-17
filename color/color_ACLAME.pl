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
"bacteriophage" => "#C71585",
"recombination process" => "#FFD700",
"integrated mobile genetic element" => "#00FF00",
"phage concatemer" => "#7CFC00",
"recombination activity" => "#FFB6C1",
"recombination component" => "#FF7F50",
"plasmid" => "#F0E68C",
"toxin activity" => "#BDB76B",
"virulent phage" => "#DDA0DD",
"temperate phage" => "#9370DB",
"phage capsid triangulation number" => "#4B0082",
"attachment site" => "#98FB98",
"cointegrate" => "#00FA9A",
"inverted repeat" => "#A0522D",
"protein secretion" => "#4169E1",
"phage genome" => "#DC143C",
"transposable phage" => "#B22222",
"nucleoid associated protein" => "#8B0000",
"origin of replication" => "#00FA9A",
"plasmid genome" => "#008000",
"pilin" => "#6B8E23",
"autoinducer synthesis" => "#00FFFF",
"lantibiotic biosynthesis" => "#D2691E",
"chaperon activity" => "#2F4F4F",
"genome segregation" => "#708090",
"cobalamin biosynthetic process" => "#C0C0C0",
"antibiotic resistance" => "#2E8B57",
);

my @head = split('_', $file);
my $db = $head[1];
my $libid = $head[0];

my $prefix = MySQL("select prefix from library_metadata where libraryId=$libid and in_mgol=1;");

my $filename = $prefix . "_" . $db . ".txt";

open(OUTPUT, '>', $filename) or die "Could not open file '$filename' $!";

print OUTPUT "query_name" . "\t" . "ACLAME_e_value" . "\t" . "top_hit_description" .  "\t" . "ACLAME_fxn_1" . "\t" . "ACLAME_fxn_2" . "\t" . "ACLAME_hexcolor" . "\t" . "ACLAME_fxn_3" . "\n";

open(my $fh, '<:encoding(UTF-8)', $file)
  or die "Could not open file '$file' $!";

while (my $row = <$fh>) {
  chomp $row;
  @a = split('\t', $row);
    foreach my $key (keys %color){
	if(lc($a[5]) eq lc($key)){
	print OUTPUT  $a[0] . "\t" .$a[1] . "\t" . $a[2] . "\t" . $a[4] . "\t" . $a[5] . "\t" . $color{$key} . "\t" . $a[6] . "\n";
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

