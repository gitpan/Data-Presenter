# 01.t
# Revised 10/5/2003 for Data-Presenter-0.64
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
    $last_test_to_print = 90;
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
ok($dp0->can("get_keys_seen"), 'get_keys_seen');# 7
ok($dp0->can("sort_by_column"), 'sort_by_column');# 8
ok($dp0->can("seen_one_column"), 'seen_one_column');# 9
ok($dp0->can("select_rows"), 'select_rows');# 10
ok($dp0->can("print_to_screen"), 'print_to_screen');# 11
ok($dp0->can("print_to_file"), 'print_to_file');# 12
ok($dp0->can("print_with_delimiter"), 'print_with_delimiter');# 13
ok($dp0->can("full_report"), 'full_report');# 14
ok($dp0->can("writeformat"), 'writeformat');# 15
ok($dp0->can("writeformat_plus_header"), 'writeformat_plus_header');# 16
ok($dp0->can("writedelimited"), 'writedelimited');# 17
ok($dp0->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 18
ok($dp0->can("writeHTML"), 'writeHTML');# 19

# 1.02:  Get information about the Data::Presenter::SampleCensus object itself.

ok( ($dp0->print_data_count), 'print_data_count');# 20
ok( ($dp0->get_data_count == 11), 'get_data_count');# 21
%seen = map { $_ => 1 } @{$dp0->get_keys};
ok($seen{359962}, 'key recognized');    # 22
ok($seen{456787}, 'key recognized');    # 23
ok($seen{456788}, 'key recognized');    # 24
ok($seen{456789}, 'key recognized');    # 25
ok($seen{456790}, 'key recognized');    # 26
ok($seen{456791}, 'key recognized');    # 27
ok($seen{498703}, 'key recognized');    # 28
ok($seen{698389}, 'key recognized');    # 29
ok($seen{786792}, 'key recognized');    # 30
ok($seen{803092}, 'key recognized');    # 31
ok($seen{906786}, 'key recognized');    # 32
ok(! $seen{987654}, 'key correctly not recognized');# 33
ok(! $seen{123456}, 'key correctly not recognized');# 34
ok(! $seen{333333}, 'key correctly not recognized');# 35
ok(! $seen{135799}, 'key correctly not recognized');# 36

%seen = %{$dp0->get_keys_seen};
ok($seen{359962}, 'key recognized');    # 37
ok($seen{456787}, 'key recognized');    # 38
ok($seen{456788}, 'key recognized');    # 39
ok($seen{456789}, 'key recognized');    # 40
ok($seen{456790}, 'key recognized');    # 41
ok($seen{456791}, 'key recognized');    # 42
ok($seen{498703}, 'key recognized');    # 43
ok($seen{698389}, 'key recognized');    # 44
ok($seen{786792}, 'key recognized');    # 45
ok($seen{803092}, 'key recognized');    # 46
ok($seen{906786}, 'key recognized');    # 47
ok(! $seen{987654}, 'key correctly not recognized');# 48
ok(! $seen{123456}, 'key correctly not recognized');# 49
ok(! $seen{333333}, 'key correctly not recognized');# 50
ok(! $seen{135799}, 'key correctly not recognized');# 51

# 1.03:  Call simple output methods on Data::Presenter::SampleCensus object:

$return = $dp0->print_to_screen;
ok( ($return == 1), 'print_to_screen'); # 52

$outputfile = "$resultsdir/census00.txt";
$return = $dp0->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 53

$outputfile = "$resultsdir/census00_delimited.txt";
$delimiter = '|||';
$return = $dp0->print_with_delimiter($outputfile,$delimiter);
ok( ($return == 1), 'print_with_delimiter');# 54

$outputfile = "$resultsdir/report00.txt";
$return = $dp0->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 55

# 1.04:  Select particular fields (columns) from a Data::Presenter::SampleCensus 
#       object and establish the order in which they will be sorted:

@columns_selected = ('ward', 'lastname', 'firstname', 'datebirth', 'cno');
$sorted_data = $dp0->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 56

# 1.04.1:  Select exactly one column from a Data::Presenter::SampleCensus
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dp0->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 57

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dp0->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 58

%seen = %{$dp0->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');# 59
ok( ($seen{'LAVER'}  == 6), 'seen_one_column:  1 arg');# 60
ok( ($seen{'TRE'}    == 2), 'seen_one_column:  1 arg');# 61

# 1.05:  Call complex output methods on Data::Presenter::SampleCensus object:

$outputfile = "$resultsdir/format00.txt";
$return = $dp0->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 62

$outputfile = "$resultsdir/format01.txt";
$title = 'Agency Census Report';
$return = $dp0->writeformat_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 63

$outputfile = "$resultsdir/delimit00.txt";
$delimiter = "\t";
$return = $dp0->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 64

$outputfile = "$resultsdir/delimit01.txt";
$delimiter = "\t";
$return = $dp0->writedelimited_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 65

$outputfile = "$resultsdir/report_census.html";
$title = 'Agency Census Report';
$return = $dp0->writeHTML(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 66

# 1.06:  Extract selected entries (rows) from Data::Presenter::SampleCensus object, 
#       then call simple output methods on the now smaller object:

$column = 'ward';
$relation = '>=';
@choices = ('0200');
$dp0->select_rows($column, $relation, \@choices);

ok( ($dp0->print_data_count), 'print_data_count');# 67
ok( ($dp0->get_data_count == 3), 'get_data_count');# 68
%seen = map { $_ => 1 } @{$dp0->get_keys};
ok($seen{456789}, 'key recognized');    # 69
ok($seen{456791}, 'key recognized');    # 70
ok($seen{698389}, 'key recognized');    # 71
ok(! $seen{786792}, 'key correctly not recognized');# 72
ok(! $seen{803092}, 'key correctly not recognized');# 73
ok(! $seen{906786}, 'key correctly not recognized');# 74

%seen = %{$dp0->get_keys_seen};
ok($seen{456789}, 'key recognized');    # 75
ok($seen{456791}, 'key recognized');    # 76
ok($seen{698389}, 'key recognized');    # 77
ok(! $seen{786792}, 'key correctly not recognized');# 78
ok(! $seen{803092}, 'key correctly not recognized');# 79
ok(! $seen{906786}, 'key correctly not recognized');# 80

$outputfile = "$resultsdir/census_ward_200_plus.txt";
$return = $dp0->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 81

# 1.07:  Select particular fields (columns) from the now smaller 
#       Data::Presenter::SampleCensus  object and establish the order in which 
#       they will be sorted:

@columns_selected = ('ward', 'lastname', 'firstname', 'cno');
$sorted_data = $dp0->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 82

# 1.07.1:  Select exactly one column from the now smaller 
#          Data::Presenter::SampleCensus object and 
#          count frequency of entries in that column:
%seen = %{$dp0->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');# 83
ok( (! exists $seen{'LAVER'}), 'seen_one_column:  1 arg');# 84
ok( (! exists $seen{'TRE'}), 'seen_one_column:  1 arg');# 85

# 1.08:  Call complex output methods on the now smaller  
#       Data::Presenter::SampleCensus object:

$outputfile = "$resultsdir/format_ward_200_plus_00.txt";
$return = $dp0->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 86

$outputfile = "$resultsdir/format_ward_200_plus_01.txt";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dp0->writeformat_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 87

$outputfile = "$resultsdir/delimit_ward_200_plus_00.txt";
$delimiter = "\t";
$return = $dp0->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 88

$outputfile = "$resultsdir/delimit_ward_200_plus_01.txt";
$delimiter = "\t";
$return = $dp0->writedelimited_plus_header(
    $sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 89

$outputfile = "$resultsdir/report_ward_200_plus.html";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dp0->writeHTML(
    $sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 90

