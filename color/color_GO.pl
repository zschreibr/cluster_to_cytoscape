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

my @head = split('_', $file);
my $db = $head[1];
my $libid = $head[0];

my $prefix = MySQL("select prefix from library_metadata where libraryId=$libid and in_mgol=1;");

my $filename = $prefix . "_" . $db . ".txt";

open(OUTPUT, '>', $filename) or die "Could not open file '$filename' $!";

print OUTPUT "query_name" . "\t" . "GO_e_value" . "\t" . "top_hit_description" . "\t". "GO_fxn_1" . "\t" . "GO_fxn_2" . "\t" . "GO_fxn_3" . "\t" . "GO_fxn_4" . "\n";

open(my $fh, '<:encoding(UTF-8)', $file)
  or die "Could not open file '$file' $!";

while (my $row = <$fh>) {
  chomp $row;
  @a = split('\t', $row);
	if(defined $a[8]){
	print OUTPUT  $a[0] . "\t" . $a[1] . "\t" . $a[2] . "\t" . $a[5] . "\t" . $a[6] . "\t" . $a[7] . "\t" . $a[8] . "\n";
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

