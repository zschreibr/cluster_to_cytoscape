#!/usr/bin/perl -w

use warnings;
use strict;
use DBI;

## DATABASE INFO ###
open(ACCESS_INFO, "/home/zschreib/mmi_60/id_to_xml/Metadata/.accessDB") || die "Can't access login credentials";
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
"Amino acid transport and metabolism" => "#990000", 
"Carbohydrate transport and metabolism" => "#330000",
"Cell cycle control, cell division, chromosome partitioning" => "#FF0000",
"Cell motility" => "#FF33000",
"Cell wall/membrane/envelope biogenesis" => "#FF6600",
"Chromatin structure and dynamics" => "#FF9900",
"Coenzyme transport and metabolism" => "#999900",
"Cytoskeleton" => "#FF33CC",
"Defense mechanisms" => "#669900",
"Energy production and conversion" => "#009900",
"Function unknown" => "#000000",
"General function prediction only" => "#3300CC",
"Inorganic ion transport and metabolism" => "#000066",
"Intracellular trafficking, secretion, and vesicular transport" => "#0099FF",
"Lipid transport and metabolism" => "#CC00FF",
"Nuclear structure" => "#660066",
"Nucleotide transport and metabolism" => "#6600FF",
"Posttranslational modification, protein turnover, chaperones" => "#00FF66",
"Replication, recombination and repair" => "#006666",
"RNA processing and modification" => "#333300",
"Secondary metabolites biosynthesis, transport and catabolism" => "#00CCCC",
"Signal transduction mechanisms" => "#3300FF",
"Transcription" => "#00CC00",
"Translation, ribosomal structure and biogenesis" => "#FFFF00",
);

my @head = split('_', $file);
my $db = $head[1];
my $libid = $head[0];

my $prefix = MySQL("select prefix from library_metadata where libraryId=$libid and in_mgol=1;");

my $filename = $prefix . "_" . $db . ".txt";

open(OUTPUT, '>', $filename) or die "Could not open file '$filename' $!";

print OUTPUT "query_name" . "\t" . "COG_e_value" . "\t" . "top_hit_description" . "\t"  . "COG_fxn_1" . "\t" . "COG_fxn_2" . "\t" . "COG_hexcolor" . "\t" . "COG_fxn_3" . "\n";

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

