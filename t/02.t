# 02.t
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 75;
	$| = 1; 
	print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use Data::Presenter;
use Data::Presenter::SampleCensus;
use Data::Presenter::SampleMedinsure;
use Data::Presenter::Combo;
use Data::Presenter::Combo::Intersect;
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

# 2.01:  Create a Data::Presenter::SampleMedinsure object:

$sourcefile = "$topdir/source/medinsure.txt";
$fieldsfile = "$topdir/config/fields_medinsure.data";
do $fieldsfile;
my $dp1 = Data::Presenter::SampleMedinsure->new($sourcefile, \@fields, \%parameters, $index);

ok($dp1->isa("Data::Presenter::SampleMedinsure"), 'D::P::SampleMedinsure object created');# 4
ok($dp1->can("get_data_count"), 'get_data_count');# 5
ok($dp1->can("print_data_count"), 'print_data_count');# 6
ok($dp1->can("get_keys"), 'get_keys');  # 7
ok($dp1->can("sort_by_column"), 'sort_by_column');# 8
ok($dp1->can("seen_one_column"), 'seen_one_column');# 9
ok($dp1->can("select_rows"), 'select_rows');# 10
ok($dp1->can("print_to_screen"), 'print_to_screen');# 11
ok($dp1->can("print_to_file"), 'print_to_file');# 12
ok($dp1->can("print_with_delimiter"), 'print_with_delimiter');# 13
ok($dp1->can("full_report"), 'full_report');# 14
ok($dp1->can("writeformat"), 'writeformat');# 15
ok($dp1->can("writeformat_plus_header"), 'writeformat_plus_header');# 16
ok($dp1->can("writedelimited"), 'writedelimited');# 17
ok($dp1->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 18
ok($dp1->can("writeHTML"), 'writeHTML');# 19

# 2.02:  Get information about the Data::Presenter::SampleMedinsure object itself.

ok( ($dp1->print_data_count), 'print_data_count');# 20
ok( ($dp1->get_data_count == 9), 'get_data_count');# 21
%seen = map { $_ => 1 } @{$dp1->get_keys};

ok($seen{210297}, 'key recognized');    # 22
ok($seen{392877}, 'key recognized');    # 23
ok($seen{399723}, 'key recognized');    # 24
ok($seen{399901}, 'key recognized');    # 25
ok($seen{456600}, 'key recognized');    # 26
ok($seen{456787}, 'key recognized');    # 27
ok($seen{456788}, 'key recognized');    # 28
ok($seen{456789}, 'key recognized');    # 29
ok($seen{456892}, 'key recognized');    # 30
ok(! $seen{987654}, 'key correctly not recognized');# 31
ok(! $seen{123456}, 'key correctly not recognized');# 32
ok(! $seen{333333}, 'key correctly not recognized');# 33
ok(! $seen{135799}, 'key correctly not recognized');# 34

# 3.01:  Beginning with the 1st object created above, create a 
#        Data::Presenter::Combo::Intersect object:

@objects = ($dp0, $dp1);
my $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);

ok($dpCI->isa("Data::Presenter::Combo::Intersect"), 'D::P::Combo::Intersect object created');# 35
ok($dpCI->can("get_data_count"), 'get_data_count');# 36
ok($dpCI->can("print_data_count"), 'print_data_count');# 37
ok($dpCI->can("get_keys"), 'get_keys'); # 38
ok($dpCI->can("sort_by_column"), 'sort_by_column');# 39
ok($dpCI->can("seen_one_column"), 'seen_one_column');# 40
ok($dpCI->can("select_rows"), 'select_rows');# 41
ok($dpCI->can("print_to_screen"), 'print_to_screen');# 42
ok($dpCI->can("print_to_file"), 'print_to_file');# 43
ok($dpCI->can("print_with_delimiter"), 'print_with_delimiter');# 44
ok($dpCI->can("full_report"), 'full_report');# 45
ok($dpCI->can("writeformat"), 'writeformat');# 46
ok($dpCI->can("writeformat_plus_header"), 'writeformat_plus_header');# 47
ok($dpCI->can("writedelimited"), 'writedelimited');# 48
ok($dpCI->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 49
ok($dpCI->can("writeHTML"), 'writeHTML');# 50

# 3.02:  Get information about the Data::Presenter::Combo object itself.

ok( ($dpCI->print_data_count), 'print_data_count');# 51
ok( ($dpCI->get_data_count == 3), 'get_data_count');# 52
%seen = map { $_ => 1 } @{$dpCI->get_keys};

ok($seen{456787}, 'key recognized');    # 53
ok($seen{456788}, 'key recognized');    # 54
ok($seen{456789}, 'key recognized');    # 55
ok(! $seen{210297}, 'key correctly not recognized');# 56
ok(! $seen{392877}, 'key correctly not recognized');# 57
ok(! $seen{399723}, 'key correctly not recognized');# 58
ok(! $seen{399901}, 'key correctly not recognized');# 59
ok(! $seen{456600}, 'key correctly not recognized');# 60

# 3.03:  Call simple output methods on Data::Presenter::Combo::Intersect object:

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 61

$outputfile = "$resultsdir/census10.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 62

$outputfile = "$resultsdir/census10_delimited.txt";
$delimiter = '|||';
$return = $dpCI->print_with_delimiter($outputfile,$delimiter);
ok( ($return == 1), 'print_with_delimiter');# 63

$outputfile = "$resultsdir/report10.txt";
$return = $dpCI->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 64

# 3.04:  Select particular fields (columns) from a Data::Presenter::Combo::Intersect 
#       object and establish the order in which they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare medicaid);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 65

# 3.04.1:  Select exactly one column from a Data::Presenter::Combo::Intersect
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCI->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 66

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCI->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 67

%seen = %{$dpCI->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 1), 'seen_one_column:  1 arg');# 68
ok( ($seen{'LAVER'}  == 2), 'seen_one_column:  1 arg');# 69
ok( (! exists $seen{'TRE'}), 'seen_one_column:  1 arg');# 70

# 3.05:  Call complex output methods on Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format10.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 71

$outputfile = "$resultsdir/format11.txt";
$title = 'Agency Census Report';
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 72

$outputfile = "$resultsdir/delimit10.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 73

$outputfile = "$resultsdir/delimit11.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 74

$outputfile = "$resultsdir/report10.html";
$title = 'Agency Census Report';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 75

