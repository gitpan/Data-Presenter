# 04.t
# Revised 10/5/2003 for Data-Presenter-0.64
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 124;
	$| = 1; 
	print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use Data::Presenter;
use Data::Presenter::SampleCensus;
use Data::Presenter::SampleMedinsure;
use Data::Presenter::SampleHair;
use Data::Presenter::Combo;
use Data::Presenter::Combo::Union;
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

# 4.01:  Beginning with the 1st object created above, create a 
#        Data::Presenter::Combo::Union object:

@objects = ($dp0, $dp1, $dp2);
my $dpCU = Data::Presenter::Combo::Union->new(\@objects);

ok($dpCU->isa("Data::Presenter::Combo::Union"), 'D::P::Combo::Union object created');# 5
ok($dpCU->can("get_data_count"), 'get_data_count');# 6
ok($dpCU->can("print_data_count"), 'print_data_count');# 7
ok($dpCU->can("get_keys"), 'get_keys'); # 8
ok($dpCU->can("get_keys_seen"), 'get_keys_seen');# 9
ok($dpCU->can("sort_by_column"), 'sort_by_column');# 10
ok($dpCU->can("seen_one_column"), 'seen_one_column');# 11
ok($dpCU->can("select_rows"), 'select_rows');# 12
ok($dpCU->can("print_to_screen"), 'print_to_screen');# 13
ok($dpCU->can("print_to_file"), 'print_to_file');# 14
ok($dpCU->can("print_with_delimiter"), 'print_with_delimiter');# 15
ok($dpCU->can("full_report"), 'full_report');# 16
ok($dpCU->can("writeformat"), 'writeformat');# 17
ok($dpCU->can("writeformat_plus_header"), 'writeformat_plus_header');# 18
ok($dpCU->can("writedelimited"), 'writedelimited');# 19
ok($dpCU->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 20
ok($dpCU->can("writeHTML"), 'writeHTML');# 21

# 4.02:  Get information about the Data::Presenter::Combo::Union object itself.

ok( ($dpCU->print_data_count), 'print_data_count');# 22
ok( ($dpCU->get_data_count == 19), 'get_data_count');# 23
%seen = map { $_ => 1 } @{$dpCU->get_keys};
ok($seen{210297}, 'key recognized');    # 24
ok($seen{359962}, 'key recognized');    # 25
ok($seen{392877}, 'key recognized');    # 26
ok($seen{399723}, 'key recognized');    # 27
ok($seen{399901}, 'key recognized');    # 28
ok($seen{456600}, 'key recognized');    # 29
ok($seen{456787}, 'key recognized');    # 30
ok($seen{456788}, 'key recognized');    # 31
ok($seen{456789}, 'key recognized');    # 32
ok($seen{456790}, 'key recognized');    # 33
ok($seen{456791}, 'key recognized');    # 34
ok($seen{456792}, 'key recognized');    # 35
ok($seen{456892}, 'key recognized');    # 36
ok($seen{458732}, 'key recognized');    # 37
ok($seen{498703}, 'key recognized');    # 38
ok($seen{698389}, 'key recognized');    # 39
ok($seen{786792}, 'key recognized');    # 40
ok($seen{803092}, 'key recognized');    # 41
ok($seen{906786}, 'key recognized');    # 42
ok(! $seen{987654}, 'key correctly not recognized');# 43
ok(! $seen{123456}, 'key correctly not recognized');# 44
ok(! $seen{333333}, 'key correctly not recognized');# 45
ok(! $seen{135799}, 'key correctly not recognized');# 46

%seen = %{$dpCU->get_keys_seen};
ok($seen{210297}, 'key recognized');    # 47
ok($seen{359962}, 'key recognized');    # 48
ok($seen{392877}, 'key recognized');    # 49
ok($seen{399723}, 'key recognized');    # 50
ok($seen{399901}, 'key recognized');    # 51
ok($seen{456600}, 'key recognized');    # 52
ok($seen{456787}, 'key recognized');    # 53
ok($seen{456788}, 'key recognized');    # 54
ok($seen{456789}, 'key recognized');    # 55
ok($seen{456790}, 'key recognized');    # 56
ok($seen{456791}, 'key recognized');    # 57
ok($seen{456792}, 'key recognized');    # 58
ok($seen{456892}, 'key recognized');    # 59
ok($seen{458732}, 'key recognized');    # 60
ok($seen{498703}, 'key recognized');    # 61
ok($seen{698389}, 'key recognized');    # 62
ok($seen{786792}, 'key recognized');    # 63
ok($seen{803092}, 'key recognized');    # 64
ok($seen{906786}, 'key recognized');    # 65
ok(! $seen{987654}, 'key correctly not recognized');# 66
ok(! $seen{123456}, 'key correctly not recognized');# 67
ok(! $seen{333333}, 'key correctly not recognized');# 68
ok(! $seen{135799}, 'key correctly not recognized');# 69

# 4.03:  Call simple output methods on Data::Presenter::Combo::Union object:
$return = $dpCU->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 70

$outputfile = "$resultsdir/census30.txt";
$return = $dpCU->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 71

$outputfile = "$resultsdir/census30_delimited.txt";
$delimiter = '|||';
$return = $dpCU->print_with_delimiter($outputfile, $delimiter);
ok( ($return == 1), 'print_with_delimiter');# 72

$outputfile = "$resultsdir/report30.txt";
$return = $dpCU->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 73

# 4.04:  Select particular fields (columns) from a Data::Presenter::Combo::Union 
#       object and establish the order in which they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare haircolor);
$sorted_data = $dpCU->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 74

# 4.04.1:  Select exactly one column from a Data::Presenter::Combo::Union
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCU->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 75

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dpCU->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 76

%seen = %{$dpCU->seen_one_column('unit')};
ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');# 77
ok( ($seen{'LAVER'}  == 6), 'seen_one_column:  1 arg');# 78
ok( ($seen{'TRE'}    == 2), 'seen_one_column:  1 arg');# 79

# 4.05:  Call complex output methods on Data::Presenter::Combo::Union object:

$outputfile = "$resultsdir/format30.txt";
$return = $dpCU->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 80

$title = 'Agency Census Report';
$outputfile = "$resultsdir/format31.txt";
$return = $dpCU->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 81

$outputfile = "$resultsdir/delimit30.txt";
$delimiter = "\t";
$return = $dpCU->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 82

$outputfile = "$resultsdir/delimit31.txt";
$delimiter = "\t";
$return = $dpCU->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 83

$outputfile = "$resultsdir/report30.html";
$title = 'Agency Census Report';
$return = $dpCU->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 84

# 4.06:  Extract selected entries (rows) from Data::Presenter::Combo::Union object, 
#       then call simple output methods on the now smaller object:

$column = 'lastname';
$relation = '>=';
@choices = ('M');
$dpCU->select_rows($column, $relation, \@choices);

%seen = ();
ok( ($dpCU->print_data_count), 'print_data_count');# 85
ok( ($dpCU->get_data_count == 12), 'get_data_count');# 86
%seen = map { $_ => 1 } @{$dpCU->get_keys};
ok($seen{359962}, 'key recognized');    # 87
ok($seen{392877}, 'key recognized');    # 88
ok($seen{456600}, 'key recognized');    # 89
ok($seen{456787}, 'key recognized');    # 90
ok($seen{456788}, 'key recognized');    # 91
ok($seen{456789}, 'key recognized');    # 92
ok($seen{456790}, 'key recognized');    # 93
ok($seen{456792}, 'key recognized');    # 94
ok($seen{498703}, 'key recognized');    # 95
ok($seen{698389}, 'key recognized');    # 96
ok($seen{786792}, 'key recognized');    # 97
ok($seen{906786}, 'key recognized');    # 98
ok(! $seen{210297}, 'key correctly not recognized');# 99
ok(! $seen{399723}, 'key correctly not recognized');# 100
ok(! $seen{399901}, 'key correctly not recognized');# 101

%seen = %{$dpCU->get_keys_seen};
ok($seen{359962}, 'key recognized');    # 102
ok($seen{392877}, 'key recognized');    # 103
ok($seen{456600}, 'key recognized');    # 104
ok($seen{456787}, 'key recognized');    # 105
ok($seen{456788}, 'key recognized');    # 106
ok($seen{456789}, 'key recognized');    # 107
ok($seen{456790}, 'key recognized');    # 108
ok($seen{456792}, 'key recognized');    # 109
ok($seen{498703}, 'key recognized');    # 110
ok($seen{698389}, 'key recognized');    # 111
ok($seen{786792}, 'key recognized');    # 112
ok($seen{906786}, 'key recognized');    # 113
ok(! $seen{210297}, 'key correctly not recognized');# 114
ok(! $seen{399723}, 'key correctly not recognized');# 115
ok(! $seen{399901}, 'key correctly not recognized');# 116

$return = $dpCU->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 117

$outputfile = "$resultsdir/combo_u_ward_200_plus.txt";
$return = $dpCU->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 118

# 4.07:  Select particular fields (columns) from the now smaller 
#       Data::Presenter::Combo::Union  object and establish the order in which 
#       they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare medicaid);
$sorted_data = $dpCU->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 119

# 4.08:  Call complex output methods on the now smaller  
#       Data::Presenter::Combo::Union object:

$outputfile = "$resultsdir/format_combo_u_ward_200_plus_20.txt";
$return = $dpCU->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 120

$outputfile = "$resultsdir/format_combo_u_ward_200_plus_21.txt";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dpCU->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 121

$outputfile = "$resultsdir/delimit_combo_u_ward_200_plus_20.txt";
$delimiter = "\t";
$return = $dpCU->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 122

$outputfile = "$resultsdir/delimit_combo_u_ward_200_plus_21.txt";
$delimiter = "\t";
$return = $dpCU->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 123

$outputfile = "$resultsdir/report_combo_u_ward_200_plus.html";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dpCU->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 124

