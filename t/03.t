# 03.t
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 97;
	$| = 1; 
	print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use Data::Presenter;
use Data::Presenter::SampleCensus;
use Data::Presenter::SampleMedinsure;
use Data::Presenter::SampleHair;
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

# 3.01:  Create a Data::Presenter::SampleHair object:

$sourcefile = "$topdir/source/hair.txt";
$fieldsfile = "$topdir/config/fields_hair.data";
do $fieldsfile;
my $dp2 = Data::Presenter::SampleHair->new($sourcefile, \@fields, \%parameters, $index);

ok($dp2->isa("Data::Presenter::SampleHair"), 'D::P::SampleHair object created');# 5
ok($dp2->can("get_data_count"), 'get_data_count');# 6
ok($dp2->can("print_data_count"), 'print_data_count');# 7
ok($dp2->can("get_keys"), 'get_keys');  # 8
ok($dp2->can("sort_by_column"), 'sort_by_column');# 9
ok($dp2->can("seen_one_column"), 'seen_one_column');# 10
ok($dp2->can("select_rows"), 'select_rows');# 11
ok($dp2->can("print_to_screen"), 'print_to_screen');# 12
ok($dp2->can("print_to_file"), 'print_to_file');# 13
ok($dp2->can("print_with_delimiter"), 'print_with_delimiter');# 14
ok($dp2->can("full_report"), 'full_report');# 15
ok($dp2->can("writeformat"), 'writeformat');# 16
ok($dp2->can("writeformat_plus_header"), 'writeformat_plus_header');# 17
ok($dp2->can("writedelimited"), 'writedelimited');# 18
ok($dp2->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 19
ok($dp2->can("writeHTML"), 'writeHTML');# 20

# 3.02:  Get information about the Data::Presenter::SampleHair object itself.

ok( ($dp2->print_data_count), 'print_data_count');# 21
ok( ($dp2->get_data_count == 9), 'get_data_count');# 22
%seen = map { $_ => 1 } @{$dp2->get_keys};

ok($seen{456787}, 'key recognized');    # 23
ok($seen{456788}, 'key recognized');    # 24
ok($seen{456789}, 'key recognized');    # 25
ok($seen{456790}, 'key recognized');    # 26
ok($seen{456791}, 'key recognized');    # 27
ok($seen{456792}, 'key recognized');    # 28
ok($seen{458732}, 'key recognized');    # 29
ok($seen{498703}, 'key recognized');    # 30
ok($seen{906786}, 'key recognized');    # 31
ok(! $seen{456892}, 'key correctly not recognized');# 32
ok(! $seen{987654}, 'key correctly not recognized');# 33
ok(! $seen{123456}, 'key correctly not recognized');# 34
ok(! $seen{333333}, 'key correctly not recognized');# 35
ok(! $seen{135799}, 'key correctly not recognized');# 36

# 4.01:  Beginning with the 1st object created above, create a 
#        Data::Presenter::Combo::Intersect object:

@objects = ($dp0, $dp1, $dp2);
my $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);

ok($dpCI->isa("Data::Presenter::Combo::Intersect"), 'D::P::Combo::Intersect object created');# 37
ok($dpCI->can("get_data_count"), 'get_data_count');# 38
ok($dpCI->can("print_data_count"), 'print_data_count');# 39
ok($dpCI->can("get_keys"), 'get_keys'); # 40
ok($dpCI->can("sort_by_column"), 'sort_by_column');# 41
ok($dpCI->can("seen_one_column"), 'seen_one_column');# 42
ok($dpCI->can("select_rows"), 'select_rows');# 43
ok($dpCI->can("print_to_screen"), 'print_to_screen');# 44
ok($dpCI->can("print_to_file"), 'print_to_file');# 45
ok($dpCI->can("print_with_delimiter"), 'print_with_delimiter');# 46
ok($dpCI->can("full_report"), 'full_report');# 47
ok($dpCI->can("writeformat"), 'writeformat');# 48
ok($dpCI->can("writeformat_plus_header"), 'writeformat_plus_header');# 49
ok($dpCI->can("writedelimited"), 'writedelimited');# 50
ok($dpCI->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 51
ok($dpCI->can("writeHTML"), 'writeHTML');# 52

# 4.02:  Get information about the Data::Presenter::Combo::Intersect object itself.

ok( ($dpCI->print_data_count), 'print_data_count');# 53
ok( ($dpCI->get_data_count == 3), 'get_data_count');# 54
%seen = map { $_ => 1 } @{$dpCI->get_keys};

ok($seen{456787}, 'key recognized');    # 55
ok($seen{456788}, 'key recognized');    # 56
ok($seen{456789}, 'key recognized');    # 57
ok(! $seen{456790}, 'key correctly not recognized');# 58
ok(! $seen{456791}, 'key correctly not recognized');# 59
ok(! $seen{456792}, 'key correctly not recognized');# 60
ok(! $seen{458732}, 'key correctly not recognized');# 61
ok(! $seen{498703}, 'key correctly not recognized');# 62
ok(! $seen{906786}, 'key correctly not recognized');# 63

# 4.03:  Call simple output methods on Data::Presenter::Combo::Intersect object:

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 64

$outputfile = "$resultsdir/census20.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 65

$outputfile = "$resultsdir/census20_delimited.txt";
$delimiter = '|||';
$return = $dpCI->print_with_delimiter($outputfile, $delimiter);
ok( ($return == 1), 'print_with_delimiter');# 66

$outputfile = "$resultsdir/report20.txt";
$return = $dpCI->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 67

# 4.03.1:  Select exactly one column from a Data::Presenter::Combo::Intersect
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCI->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 68

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCI->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 69

%seen = %{$dpCI->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 1), 'seen_one_column:  1 arg');# 70
ok( ($seen{'LAVER'}  == 2), 'seen_one_column:  1 arg');# 71
ok( (! exists $seen{'TRE'}), 'seen_one_column:  1 arg');# 72

# 4.04:  Select particular fields (columns) from a Data::Presenter::Combo::Intersect 
#       object and establish the order in which they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare haircolor);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 73

# 4.05:  Call complex output methods on Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format20.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 74

$title = "$resultsdir/Agency Census Report";
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 75

$outputfile = "$resultsdir/delimit20.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 76

$outputfile = "$resultsdir/delimit21.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 77

$outputfile = "$resultsdir/report20.html";
$title = 'Agency Census Report';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 78

# 4.06:  Extract selected entries (rows) from Data::Presenter::Combo::Intersect object, 
#       then call simple output methods on the now smaller object:

$column = 'ward';
$relation = '>=';
@choices = ('0200');
$dpCI->select_rows($column, $relation, \@choices);

%seen = ();
ok( ($dpCI->print_data_count), 'print_data_count');# 79
ok( ($dpCI->get_data_count == 1), 'get_data_count');# 80
%seen = map { $_ => 1 } @{$dpCI->get_keys};

ok(! $seen{456787}, 'key correctly not recognized');# 81
ok(! $seen{456788}, 'key correctly not recognized');# 82
ok($seen{456789}, 'key recognized');    # 83
ok(! $seen{456790}, 'key correctly not recognized');# 84
ok(! $seen{456791}, 'key correctly not recognized');# 85
ok(! $seen{456792}, 'key correctly not recognized');# 86
ok(! $seen{458732}, 'key correctly not recognized');# 87
ok(! $seen{498703}, 'key correctly not recognized');# 88
ok(! $seen{906786}, 'key correctly not recognized');# 89

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 90

$outputfile = "$resultsdir/combo_ward_200_plus.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 91

# 4.07:  Select particular fields (columns) from the now smaller 
#       Data::Presenter::Combo::Intersect  object and establish the order in which 
#       they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare medicaid);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 92

# 4.08:  Call complex output methods on the now smaller  
#       Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format_combo_ward_200_plus_20.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 93

$outputfile = "$resultsdir/format_combo_ward_200_plus_21.txt";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 94

$outputfile = "$resultsdir/delimit_combo_ward_200_plus_20.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 95

$outputfile = "$resultsdir/delimit_combo_ward_200_plus_21.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 96

$outputfile = "$resultsdir/report_combo_ward_200_plus.html";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 97

