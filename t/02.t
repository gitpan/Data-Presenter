# 02.t
# Revised 10/5/2003 for Data-Presenter-0.64
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 98;
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
ok($dp1->can("get_keys_seen"), 'get_keys_seen');# 8
ok($dp1->can("sort_by_column"), 'sort_by_column');# 9
ok($dp1->can("seen_one_column"), 'seen_one_column');# 10
ok($dp1->can("select_rows"), 'select_rows');# 11
ok($dp1->can("print_to_screen"), 'print_to_screen');# 12
ok($dp1->can("print_to_file"), 'print_to_file');# 13
ok($dp1->can("print_with_delimiter"), 'print_with_delimiter');# 14
ok($dp1->can("full_report"), 'full_report');# 15
ok($dp1->can("writeformat"), 'writeformat');# 16
ok($dp1->can("writeformat_plus_header"), 'writeformat_plus_header');# 17
ok($dp1->can("writedelimited"), 'writedelimited');# 18
ok($dp1->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 19
ok($dp1->can("writeHTML"), 'writeHTML');# 20

# 2.02:  Get information about the Data::Presenter::SampleMedinsure object itself.

ok( ($dp1->print_data_count), 'print_data_count');# 21
ok( ($dp1->get_data_count == 9), 'get_data_count');# 22
%seen = map { $_ => 1 } @{$dp1->get_keys};
ok($seen{210297}, 'key recognized');    # 23
ok($seen{392877}, 'key recognized');    # 24
ok($seen{399723}, 'key recognized');    # 25
ok($seen{399901}, 'key recognized');    # 26
ok($seen{456600}, 'key recognized');    # 27
ok($seen{456787}, 'key recognized');    # 28
ok($seen{456788}, 'key recognized');    # 29
ok($seen{456789}, 'key recognized');    # 30
ok($seen{456892}, 'key recognized');    # 31
ok(! $seen{987654}, 'key correctly not recognized');# 32
ok(! $seen{123456}, 'key correctly not recognized');# 33
ok(! $seen{333333}, 'key correctly not recognized');# 34
ok(! $seen{135799}, 'key correctly not recognized');# 35

%seen = %{$dp1->get_keys_seen};
ok($seen{210297}, 'key recognized');    # 36
ok($seen{392877}, 'key recognized');    # 37
ok($seen{399723}, 'key recognized');    # 38
ok($seen{399901}, 'key recognized');    # 39
ok($seen{456600}, 'key recognized');    # 40
ok($seen{456787}, 'key recognized');    # 41
ok($seen{456788}, 'key recognized');    # 42
ok($seen{456789}, 'key recognized');    # 43
ok($seen{456892}, 'key recognized');    # 44
ok(! $seen{987654}, 'key correctly not recognized');# 45
ok(! $seen{123456}, 'key correctly not recognized');# 46
ok(! $seen{333333}, 'key correctly not recognized');# 47
ok(! $seen{135799}, 'key correctly not recognized');# 48

# 3.01:  Beginning with the 1st object created above, create a 
#        Data::Presenter::Combo::Intersect object:

@objects = ($dp0, $dp1);
my $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);

ok($dpCI->isa("Data::Presenter::Combo::Intersect"), 'D::P::Combo::Intersect object created');# 49
ok($dpCI->can("get_data_count"), 'get_data_count');# 50
ok($dpCI->can("print_data_count"), 'print_data_count');# 51
ok($dpCI->can("get_keys"), 'get_keys'); # 52
ok($dpCI->can("get_keys_seen"), 'get_keys_seen');# 53
ok($dpCI->can("sort_by_column"), 'sort_by_column');# 54
ok($dpCI->can("seen_one_column"), 'seen_one_column');# 55
ok($dpCI->can("select_rows"), 'select_rows');# 56
ok($dpCI->can("print_to_screen"), 'print_to_screen');# 57
ok($dpCI->can("print_to_file"), 'print_to_file');# 58
ok($dpCI->can("print_with_delimiter"), 'print_with_delimiter');# 59
ok($dpCI->can("full_report"), 'full_report');# 60
ok($dpCI->can("writeformat"), 'writeformat');# 61
ok($dpCI->can("writeformat_plus_header"), 'writeformat_plus_header');# 62
ok($dpCI->can("writedelimited"), 'writedelimited');# 63
ok($dpCI->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 64
ok($dpCI->can("writeHTML"), 'writeHTML');# 65

# 3.02:  Get information about the Data::Presenter::Combo object itself.

ok( ($dpCI->print_data_count), 'print_data_count');# 66
ok( ($dpCI->get_data_count == 3), 'get_data_count');# 67
%seen = map { $_ => 1 } @{$dpCI->get_keys};
ok($seen{456787}, 'key recognized');    # 68
ok($seen{456788}, 'key recognized');    # 69
ok($seen{456789}, 'key recognized');    # 70
ok(! $seen{210297}, 'key correctly not recognized');# 71
ok(! $seen{392877}, 'key correctly not recognized');# 72
ok(! $seen{399723}, 'key correctly not recognized');# 73
ok(! $seen{399901}, 'key correctly not recognized');# 74
ok(! $seen{456600}, 'key correctly not recognized');# 75

%seen = %{$dpCI->get_keys_seen};
ok($seen{456787}, 'key recognized');    # 76
ok($seen{456788}, 'key recognized');    # 77
ok($seen{456789}, 'key recognized');    # 78
ok(! $seen{210297}, 'key correctly not recognized');# 79
ok(! $seen{392877}, 'key correctly not recognized');# 80
ok(! $seen{399723}, 'key correctly not recognized');# 81
ok(! $seen{399901}, 'key correctly not recognized');# 82
ok(! $seen{456600}, 'key correctly not recognized');# 83

# 3.03:  Call simple output methods on Data::Presenter::Combo::Intersect object:

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 84

$outputfile = "$resultsdir/census10.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 85

$outputfile = "$resultsdir/census10_delimited.txt";
$delimiter = '|||';
$return = $dpCI->print_with_delimiter($outputfile,$delimiter);
ok( ($return == 1), 'print_with_delimiter');# 86

$outputfile = "$resultsdir/report10.txt";
$return = $dpCI->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 87

# 3.04:  Select particular fields (columns) from a Data::Presenter::Combo::Intersect 
#       object and establish the order in which they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare medicaid);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 88

# 3.04.1:  Select exactly one column from a Data::Presenter::Combo::Intersect
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCI->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 89

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCI->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 90

%seen = %{$dpCI->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 1), 'seen_one_column:  1 arg');# 91
ok( ($seen{'LAVER'}  == 2), 'seen_one_column:  1 arg');# 92
ok( (! exists $seen{'TRE'}), 'seen_one_column:  1 arg');# 93

# 3.05:  Call complex output methods on Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format10.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 94

$outputfile = "$resultsdir/format11.txt";
$title = 'Agency Census Report';
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 95

$outputfile = "$resultsdir/delimit10.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 96

$outputfile = "$resultsdir/delimit11.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 97

$outputfile = "$resultsdir/report10.html";
$title = 'Agency Census Report';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 98

