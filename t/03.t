# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 89; 			# 04/08/2003
	$| = 1; 
	print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}
use Data::Presenter;
use Data::Presenter::SampleCensus;
use Data::Presenter::SampleMedinsure;
use Data::Presenter::SampleHair;
use Data::Presenter::Combo;
use Data::Presenter::Combo::Intersect;
use Cwd;

# Declare variables needed for testing:

my $testnum = $loaded = 1;	# $loaded must be a global
my (%seen);
my ($return);

my $cwd = cwd();
my $topdir = $cwd;
my $resultsdir = "$topdir/results";

ok($loaded, 'module loaded');           # 1

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
ok($dp0->isa("Data::Presenter::SampleCensus"), 'D::P::SampleCensus object created');# 2

# 2.01:  Create a Data::Presenter::SampleMedinsure object:

$sourcefile = "$topdir/source/medinsure.txt";
$fieldsfile = "$topdir/config/fields_medinsure.data";
do $fieldsfile;
my $dp1 = Data::Presenter::SampleMedinsure->new($sourcefile, \@fields, \%parameters, $index);
ok($dp1->isa("Data::Presenter::SampleMedinsure"), 'D::P::SampleMedinsure object created');# 3

# 3.01:  Create a Data::Presenter::SampleHair object:

$sourcefile = "$topdir/source/hair.txt";
$fieldsfile = "$topdir/config/fields_hair.data";
do $fieldsfile;
my $dp2 = Data::Presenter::SampleHair->new($sourcefile, \@fields, \%parameters, $index);

ok($dp2->isa("Data::Presenter::SampleHair"), 'D::P::SampleHair object created');# 4
ok($dp2->can("get_data_count"), 'get_data_count');# 5
ok($dp2->can("print_data_count"), 'print_data_count');# 6
ok($dp2->can("get_keys"), 'get_keys');  # 7
ok($dp2->can("sort_by_column"), 'sort_by_column');# 8
ok($dp2->can("select_rows"), 'select_rows');# 9
ok($dp2->can("print_to_screen"), 'print_to_screen');# 10
ok($dp2->can("print_to_file"), 'print_to_file');# 11
ok($dp2->can("print_with_delimiter"), 'print_with_delimiter');# 12
ok($dp2->can("full_report"), 'full_report');# 13
ok($dp2->can("writeformat"), 'writeformat');# 14
ok($dp2->can("writeformat_plus_header"), 'writeformat_plus_header');# 15
ok($dp2->can("writedelimited"), 'writedelimited');# 16
ok($dp2->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 17
ok($dp2->can("writeHTML"), 'writeHTML');# 18

# 3.02:  Get information about the Data::Presenter::SampleHair object itself.

ok( ($dp2->print_data_count), 'print_data_count');# 19
ok( ($dp2->get_data_count == 9), 'get_data_count');# 20
%seen = map { $_ => 1 } @{$dp2->get_keys};

ok($seen{456787}, 'key recognized');    # 21
ok($seen{456788}, 'key recognized');    # 22
ok($seen{456789}, 'key recognized');    # 23
ok($seen{456790}, 'key recognized');    # 24
ok($seen{456791}, 'key recognized');    # 25
ok($seen{456792}, 'key recognized');    # 26
ok($seen{458732}, 'key recognized');    # 27
ok($seen{498703}, 'key recognized');    # 28
ok($seen{906786}, 'key recognized');    # 29
ok(! $seen{456892}, 'key correctly not recognized');# 30
ok(! $seen{987654}, 'key correctly not recognized');# 31
ok(! $seen{123456}, 'key correctly not recognized');# 32
ok(! $seen{333333}, 'key correctly not recognized');# 33
ok(! $seen{135799}, 'key correctly not recognized');# 34

# 4.01:  Beginning with the 1st object created above, create a 
#        Data::Presenter::Combo::Intersect object:

@objects = ($dp0, $dp1, $dp2);
my $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);

ok($dpCI->isa("Data::Presenter::Combo::Intersect"), 'D::P::Combo::Intersect object created');# 35
ok($dpCI->can("get_data_count"), 'get_data_count');# 36
ok($dpCI->can("print_data_count"), 'print_data_count');# 37
ok($dpCI->can("get_keys"), 'get_keys'); # 38
ok($dpCI->can("sort_by_column"), 'sort_by_column');# 39
ok($dpCI->can("select_rows"), 'select_rows');# 40
ok($dpCI->can("print_to_screen"), 'print_to_screen');# 41
ok($dpCI->can("print_to_file"), 'print_to_file');# 42
ok($dpCI->can("print_with_delimiter"), 'print_with_delimiter');# 43
ok($dpCI->can("full_report"), 'full_report');# 44
ok($dpCI->can("writeformat"), 'writeformat');# 45
ok($dpCI->can("writeformat_plus_header"), 'writeformat_plus_header');# 46
ok($dpCI->can("writedelimited"), 'writedelimited');# 47
ok($dpCI->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 48
ok($dpCI->can("writeHTML"), 'writeHTML');# 49

# 4.02:  Get information about the Data::Presenter::Combo::Intersect object itself.

ok( ($dpCI->print_data_count), 'print_data_count');# 50
ok( ($dpCI->get_data_count == 3), 'get_data_count');# 51
%seen = map { $_ => 1 } @{$dpCI->get_keys};

ok($seen{456787}, 'key recognized');    # 52
ok($seen{456788}, 'key recognized');    # 53
ok($seen{456789}, 'key recognized');    # 54
ok(! $seen{456790}, 'key correctly not recognized');# 55
ok(! $seen{456791}, 'key correctly not recognized');# 56
ok(! $seen{456792}, 'key correctly not recognized');# 57
ok(! $seen{458732}, 'key correctly not recognized');# 58
ok(! $seen{498703}, 'key correctly not recognized');# 59
ok(! $seen{906786}, 'key correctly not recognized');# 60

# 4.03:  Call simple output methods on Data::Presenter::Combo::Intersect object:

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 61

$outputfile = "$resultsdir/census20.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 62

$outputfile = "$resultsdir/census20_delimited.txt";
$delimiter = '|||';
$return = $dpCI->print_with_delimiter($outputfile, $delimiter);
ok( ($return == 1), 'print_with_delimiter');# 63

$outputfile = "$resultsdir/report20.txt";
$return = $dpCI->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 64

# 4.04:  Select particular fields (columns) from a Data::Presenter::Combo::Intersect 
#       object and establish the order in which they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare haircolor);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 65

# 4.05:  Call complex output methods on Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format20.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 66

$title = "$resultsdir/Agency Census Report";
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 67

$outputfile = "$resultsdir/delimit20.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 68

$outputfile = "$resultsdir/delimit21.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 69

$outputfile = "$resultsdir/report20.html";
$title = 'Agency Census Report';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 70

# 4.06:  Extract selected entries (rows) from Data::Presenter::Combo::Intersect object, 
#       then call simple output methods on the now smaller object:

$column = 'ward';
$relation = '>=';
@choices = ('0200');
$dpCI->select_rows($column, $relation, \@choices);

%seen = ();
ok( ($dpCI->print_data_count), 'print_data_count');# 71
ok( ($dpCI->get_data_count == 1), 'get_data_count');# 72
%seen = map { $_ => 1 } @{$dpCI->get_keys};

ok(! $seen{456787}, 'key correctly not recognized');# 73
ok(! $seen{456788}, 'key correctly not recognized');# 74
ok($seen{456789}, 'key recognized');    # 75
ok(! $seen{456790}, 'key correctly not recognized');# 76
ok(! $seen{456791}, 'key correctly not recognized');# 77
ok(! $seen{456792}, 'key correctly not recognized');# 78
ok(! $seen{458732}, 'key correctly not recognized');# 79
ok(! $seen{498703}, 'key correctly not recognized');# 80
ok(! $seen{906786}, 'key correctly not recognized');# 81

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 82

$outputfile = "$resultsdir/combo_ward_200_plus.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 83

# 4.07:  Select particular fields (columns) from the now smaller 
#       Data::Presenter::Combo::Intersect  object and establish the order in which 
#       they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare medicaid);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 84

# 4.08:  Call complex output methods on the now smaller  
#       Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format_combo_ward_200_plus_20.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 85

$outputfile = "$resultsdir/format_combo_ward_200_plus_21.txt";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 86

$outputfile = "$resultsdir/delimit_combo_ward_200_plus_20.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 87

$outputfile = "$resultsdir/delimit_combo_ward_200_plus_21.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 88

$outputfile = "$resultsdir/report_combo_ward_200_plus.html";
$title = 'Agency Census Report:  Wards 200 and Over';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 89

#################### SUBROUTINES ##################

# test for content of $sorted_data
sub sdtest {
	my ($aref, $sorted_data) = @_;
	foreach (sort keys %{$sorted_data}) {
		return 0 unless ( (scalar(@{$aref})-1) == tr/!//);
	}
	return 1;
}

# testing subroutine
sub ok {
	my $condition = shift;
	my $message = shift if (defined $_[0]);
	print $condition ? "ok $testnum" : "not ok $testnum";
	print "\t$message" if (defined $message);
	print "\n";
	$testnum++;
}

