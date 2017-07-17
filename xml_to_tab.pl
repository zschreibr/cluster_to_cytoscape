#!/usr/bin/perl -w

=head1 NAME
   xml_to_tab.pl

=head1 SYNOPSIS

    USAGE: xml_to_tab.pl -auth=/path/to/auth.txt -input_xml=/path/to/input_xml.xml -out_file=/path/to/outfile

=head1 OPTIONS

B<--auth_info, -auth>
    Required. Access info used to connect to mysql.

B<--input_library_id, -id>
    Required. Library ID that corresponds to a VIROME xml file. 

B<--database, -db>
    Required. Database name that will be queried. 

B<--output_file, -o>
    Required. Output path.

B<--help,-h>
    Help message

=head1  DESCRIPTION
	Converts xml file to tab while also adding various descriptors queried from the VIROME database. 

=head1  INPUT
	Access info, library ID, database name, out path.	
      
=head1  OUTPUT
        Tab file that contains various ORF ids and metadata from selected xml files. 

=head1  CONTACT
        Zach Schreiber @ zschreibr[at]gmail[dot]com

=head1 EXAMPLE

	xml_to_tab.pl -auth=auth.txt -id=12 -db=ACLAME -o=/home/
        
=cut


use warnings;
use strict;
use XML::DOM;
use Data::Dumper;
use DBI;
use Pod::Usage;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);
use List::Util qw(min max);
use File::Basename;


my %options = ();
my $results = GetOptions (\%options,
                                                  'auth_info|auth=s',
                                                  'input_library_id|id=s',
                                                  'output_file|o=s',
                                                  'database|db=s',
                                                  'help|h') || pod2usage();
#### display documentation
if( $options{'help'} ) {
  pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} );
}

##user input error flags
die "Missing auth file! -auth\n" unless $options{auth_info};
die "Missing a library id! -id\n" unless $options{input_library_id};
die "Missing file output location! -o\n" unless $options{output_file};
die "Missing database name! -db\n" unless $options{database};
##end error flags

## DATABASE INFO ###
open(ACCESS_INFO, "$options{auth_info}" ) || die "Can't access login credentials";
# assign the values in the accessDB file to the variables
my $userid = <ACCESS_INFO>;
my $passwd = <ACCESS_INFO>;
# the chomp() function will remove any newline character from the end of a string
chomp ($userid, $passwd);
# close the accessDB file
close(ACCESS_INFO);

my $libID = $options{input_library_id};
my $db = $options{database};
my $outpath = $options{output_file};

my $err;
my $xfile;
my $ifile;
my $parser;
my $xdoc;
my $idoc;
my $par;
my $filename = $libID . "_" . $db;


open(OUTPUT, ">$outpath" . $filename) or die "Could not open file '$filename' $!";

$xfile = "/data/wwwroot/virome/app/xDocs/" . $db . "_XMLDOC_$libID.xml";
$ifile = "/data/wwwroot/virome/app/xDocs/" . $db . "_IDDOC_$libID.xml";
 
if (-e $xfile){
  $parser = new XML::DOM::Parser;
  $xdoc = $parser->parsefile($xfile);
  $idoc = $parser->parsefile($ifile);
  &traverse_XML_tree2( $xdoc, "root" );
 }

 else {
    $err = print STDERR "No $xfile file for database $db and library ID[$libID]. \n";
  }

close OUTPUT;

#########################################################################
sub traverse_XML_tree2 {
    my ( $doc, $startingTag ) = @_;    #load passed in parameters.

    #### find all the <p> elements
    my $paras = $doc->getElementsByTagName($startingTag);

    for ( my $i = 0 ; $i < $paras->getLength ; $i++ ) {
        my $para = $paras->item($i);
        &traverse_XML_tree_recursive($para, "");
    }
}

#########################################################################
# Looking at a recursive way to traverse the XML::DOM tree.
sub traverse_XML_tree_recursive {
    my ($para, $str) = @_;                   # Reading in the parameters.
    $str .= "\t".$para->getAttribute('NAME');
    #### for each child of a <p>, if it is a text node, process it
    #### See (http://cpan.uwinnipeg.ca/htdocs/XML-DOM/XML/DOM.html)for constant definitions
    my @children = $para->getChildNodes;

    #### I'm checking to see if there's nothing in the array -- no children -- by counting the array size.
   my $numberOfChildren = ($#children) + 1;
   if ($db eq "GO"){
	$db = "UNIREF100P";
   }
   if ( $numberOfChildren <= 0 ) {
        my $idList = $idoc->getElementsByTagName($para->getAttribute('TAG'))->item(0)->getAttribute('IDLIST');
             foreach my $i (split /,/, $idList) {
	      my $additional_info = MySQL("select b.query_name, b.e_value, hd.description from blastp_tophit b inner join blast_database_lookup bdl on b.blast_db_lookup_id=bdl.id inner join hit_description hd on b.hit_description_id=hd.id where sequenceId=$i and fxn_topHit=1 and bdl.db_name='" .$db. "'");
	      #print $additional_info . "\n";
              $par = $additional_info . "\t" . $i . $str . "\n";
	      $par =~ s/\t{2,}/\t/g;
	      print OUTPUT $par;
        }
        
        return; 
 }

    foreach my $node (@children) {
        if ( $node->getNodeType eq ELEMENT_NODE ) {
            my $nodeTagName = $node->getTagName;
            &traverse_XML_tree_recursive($node, $str);
        }
    }
}

#########################################################################


sub MySQL
{
    # establish connection with 'serverDNA' database
    my $connection = DBI->connect("DBI:mysql:vir_data_devel",$userid,$passwd);
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


