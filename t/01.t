# 01.t
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
    $last_test_to_print = 68;
    $| = 1; 
    print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use Data::Presenter;
use Data::Presenter::SampleCensus;
use lib ("./t");
use Test::DataPresenterSpecial;
use Test::DataPresenterSpecial qw(:seen);

$loaded = 1;
ok($loaded);                            # 1

# Declare variables needed for testing:

my (%seen, $return);

my $cwd = cwd();
my $topdir = $cwd;
my $resultsdir = "$topdir/results";

ok($loaded, 'module loaded');           # 2

# 0.01:  Names of variables imported from config file when do-d:

our @fields = ();           # individual fields/columns in data
our %parameters = ();       # parameters describing how individual fields/columns 
                            # ... in data are sorted and outputted
our $index = '';            # field in data source which serves as unique ID for each record

# 0.02:  Declare most frequently used variables:

my ($sourcefile, $fieldsfile, $count, $outputfile, $title, $delimiter);
my @columns_selected = ();
my $sorted_data = '';
my @objects = ();

my ($column, $relation);
my @choices = ();

# 1.01:  Create a Data::Presenter::SampleCensus object:

$sourcefile = "$topdir/source/census.txt";
$fieldsfile = "$topdir/config/fields_census.data";
do $fieldsfile;
my $dp0 = Data::Presenter::SampleCensus->new($sourcefile, \@fields, \%parameters, $index);

ok($dp0->isa("Data::Presenter::SampleCensus"), 'D::P::SampleCensus object created');# 3
ok($dp0->can("get_data_count"), 'get_data_count');# 4
ok($dp0->can("print_data_count"), 'print_data_count');# 5
ok($dp0->can("get_keys"), 'get_keys');  # 6
ok($dp0->can("sort_by_column"), 'sort_by_column');# 7
ok($dp0->can("seen_one_column"), 'seen_one_column');# 8
ok($dp0->can("select_rows"), 'select_rows');# 9
ok($dp0->can("print_to_screen"), 'print_to_screen');# 10
ok($dp0->can("print_to_file"), 'print_to_file');# 11
ok($dp0->can("print_with_delimiter"), 'print_with_delimiter');# 12
ok($dp0->can("full_report"), 'full_report');# 13
ok($dp0->can("writeformat"), 'writeformat');# 14
ok($dp0->can("writeformat_plus_header"), 'writeformat_plus_header');# 15
ok($dp0->can("writedelimited"), 'writedelimited');# 16
ok($dp0->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 17
ok($dp0->can("writeHTML"), 'writeHTML');# 18

# 1.02:  Get information about the Data::Presenter::SampleCensus object itself.

ok( ($dp0->print_data_count), 'print_data_count');# 19
ok( ($dp0->get_data_count == 11), 'get_data_count');# 20
%seen = map { $_ => 1 } @{$dp0->get_keys};
ok($seen{359962}, 'key recognized');    # 21
ok($seen{456787}, 'key recognized');    # 22
ok($seen{456788}, 'key recognized');    # 23
ok($seen{456789}, 'key recognized');    # 24
ok($seen{456790}, 'key recognized');    # 25
ok($seen{456791}, 'key recognized');    # 26
ok($seen{498703}, 'key recognized');    # 27
ok($seen{698389}, 'key recognized');    # 28
ok($seen{786792}, 'key recognized');    # 29
ok($seen{803092}, 'key recognized');    # 30
ok($seen{906786}, 'key recognized');    # 31
ok(! $seen{987654}, 'key correctly not recognized');# 32
ok(! $seen{123456}, 'key correctly not recognized');# 33
ok(! $seen{333333}, 'key correctly not recognized');# 34
ok(! $seen{135799}, 'key correctly not recognized');# 35

# 1.03:  Call simple output methods on Data::Presenter::SampleCensus object:

$return = $dp0->print_to_screen;
ok( ($return == 1), 'print_to_screen'); # 36

$outputfile = "$resultsdir/census00.txt";
$return = $dp0->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 37

$outputfile = "$resultsdir/census00_delimited.txt";
$delimiter = '|||';
$return = $dp0->print_with_delimiter($outputfile,$delimiter);
ok( ($return == 1), 'print_with_delimiter');# 38

$outputfile = "$resultsdir/report00.txt";
$return = $dp0->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 39

# 1.04:  Select particular fields (columns) from a Data::Presenter::SampleCensus 
#       object and establish the order in which they will be sorted:

@columns_selected = ('ward', 'lastname', 'firstname', 'datebirth', 'cno');
$sorted_data = $dp0->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 40

# 1.04.1:  Select exactly one column from a Data::Presenter::SampleCensus
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dp0->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 41

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dp0->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 42

%seen = %{$dp0->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');# 43
ok( ($seen{'LAVER'}  == 6), 'seen_one_column:  1 arg');# 44
ok( ($seen{'TRE'}    == 2), 'seen_one_column:  1 arg');# 45

# 1.05:  Call complex output methods on Data::Presenter::SampleCensus object:

$outputfile = "$resultsdir/format00.txt";
$return = $dp0->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 46

$outputfile = "$resultsdir/format01.txt";
$title = 'Agency Census Report';
$return = $dp0->writeformat_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 47

$outputfile = "$resultsdir/delimit00.txt";
$delimiter = "\t";
$return = $dp0->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 48

$outputfile = "$resultsdir/delimit01.txt";
$delimiter = "\t";
$return = $dp0->writedelimited_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 49

$outputfile = "$resultsdir/report_census.html";
$title = 'Agency Census Report';
$return = $dp0->writeHTML(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 50

# 1.06:  Extract selected entries (rows) from Data::Presenter::SampleCensus object, 
#       then call simple output methods on the now smaller object:

$column = 'ward';
$relation = '>=';
@choices = ('0200');
$dp0->select_rows($column, $relation, \@choices);

ok( ($dp0->print_data_count), 'print_data_count');# 51
ok( ($dp0->get_data_count == 3), 'get_data_count');# 52
%seen = map { $_ => 1 } @{$dp0->get_keys};
ok($seen{456789}, 'key recognized');    # 53
ok($seen{456791}, 'key recognized');    # 54
ok($seen{698389}, 'key recognized');    # 55
ok(! $seen{786792}, 'key correctly not recognized');# 56
ok(! $seen{803092}, 'key correctly not recognized');# 57
ok(! $seen{906786}, 'key correctly not recognized');# 58

$outputfile = "$resultsdir/census_ward_200_plus.txt";
$return = $dp0->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 59

# 1.07:  Select particular fields (columns) from the now smaller 
#       Data::Presenter::SampleCensus  object and establish the order in which 
#       they will be sorted:

@columns_selected = ('ward', 'lastname', 'firstname', 'cno');
$sorted_data = $dp0->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 60

# 1.07.1:  Select exactly one column from the now smaller 
#          Data::Presenter::SampleCensus object and 
#          count frequency of entries in that column:
%seen = %{$dp0->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');# 61
ok( (! exists $seen{'LAVER'}), 'seen_one_column:  1 arg');# 62
ok( (! exists $seen{'TRE'}), 'seen_one_column:  1 arg');# 63

# 1.08:  Call complex output methods on the now smaller  
#       Data::Presenter::SampleCensus object:

$outputfile = "$resultsdir/format_ward_200_plus_00.txt";
$return = $dp0->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 64

$outputfile = "$resultsdir/format_ward_200_plus_01.txt";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dp0->writeformat_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 65

$outputfile = "$resultsdir/delimit_ward_200_plus_00.txt";
$delimiter = "\t";
$return = $dp0->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 66

$outputfile = "$resultsdir/delimit_ward_200_plus_01.txt";
$delimiter = "\t";
$return = $dp0->writedelimited_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 67

$outputfile = "$resultsdir/report_ward_200_plus.html";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dp0->writeHTML(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 68

