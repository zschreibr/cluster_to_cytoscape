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
"Amino Acids and Derivatives" => "#C71585", 
"Carbohydrates" => "#FFD700",
"Cell Division and Cell Cycle" => "#00FF00",
"Cell Wall and Capsule" => "#7CFC00",
"Clustering-based subsystems" => "#FFB6C1",
"Cofactors, Vitamins, Prosthetic Groups, Pigments" => "#FF7F50",
"DNA Metabolism" => "#F0E68C",
"Dormancy and Sporulation" => "#BDB76B",
"Fatty Acids, Lipids, and Isoprenoids" => "#DDA0DD",
"Iron acquisition and metabolism" => "#9370DB",
"Membrane Transport" => "#4B0082",
"Metabolism of Aromatic Compounds" => "#98FB98",
"Miscellaneous" => "#000000",
"Motility and Chemotaxis" => "#00FA9A",
"Nitrogen Metabolism" => "#A0522D",
"Nucleosides and Nucleotides" => "#4169E1",
"Phages, Prophages, Transposable elements" => "#DC143C",
"Phages, Prophages, Transposable elements, Plasmids" => "#B22222",
"Phosphorus Metabolism" => "#8B0000",
"Photosynthesis" => "#00FA9A",
"Potassium metabolism" => "#008000",
"Protein Metabolism" => "#6B8E23",
"Regulation and Cell signaling" => "#00FFFF",
"Respiration" => "#D2691E",
"RNA Metabolism" => "#2F4F4F",
"Secondary Metabolism" => "#708090",
"Stress Response" => "#C0C0C0",
"Sulfur Metabolism" => "#2E8B57", 
"Virulence" => "#00FF7F",
"Virulence, Disease and Defense" => "#FFA500",
);

my @head = split('_', $file);
my $db = $head[1];
my $libid = $head[0];

my $prefix = MySQL("select prefix from library_metadata where libraryId=$libid and in_mgol=1;");

my $filename = $prefix . "_" . $db . ".txt";

open(OUTPUT, '>', $filename) or die "Could not open file '$filename' $!";

print OUTPUT "query_name" . "\t" . "SEED_e_value" . "\t" . "top_hit_description" . "\t" . "SEED_fxn_1" . "\t" . "SEED_hexcolor" . "\t" . "SEED_fxn_2" . "\t" . "SEED_fxn_3" . "\n";

open(my $fh, '<:encoding(UTF-8)', $file)
  or die "Could not open file '$file' $!";

while (my $row = <$fh>) {
  chomp $row;
  @a = split('\t', $row);
    foreach my $key (keys %color){
	if(lc($a[4]) eq lc($key)){
	print OUTPUT  $a[0] . "\t" . $a[1] . "\t" . $a[2] . "\t" . $a[4] . "\t" . $color{$key} . "\t" . $a[5] . "\t" . $a[6] . "\n";
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

