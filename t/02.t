# 02.t
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 67;
	$| = 1; 
	print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}
use Data::Presenter;
use Data::Presenter::SampleCensus;
use Data::Presenter::SampleMedinsure;
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
ok($dp1->can("get_data_count"), 'get_data_count');# 4
ok($dp1->can("print_data_count"), 'print_data_count');# 5
ok($dp1->can("get_keys"), 'get_keys');  # 6
ok($dp1->can("sort_by_column"), 'sort_by_column');# 7
ok($dp1->can("select_rows"), 'select_rows');# 8
ok($dp1->can("print_to_screen"), 'print_to_screen');# 9
ok($dp1->can("print_to_file"), 'print_to_file');# 10
ok($dp1->can("print_with_delimiter"), 'print_with_delimiter');# 11
ok($dp1->can("full_report"), 'full_report');# 12
ok($dp1->can("writeformat"), 'writeformat');# 13
ok($dp1->can("writeformat_plus_header"), 'writeformat_plus_header');# 14
ok($dp1->can("writedelimited"), 'writedelimited');# 15
ok($dp1->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 16
ok($dp1->can("writeHTML"), 'writeHTML');# 17

# 2.02:  Get information about the Data::Presenter::SampleMedinsure object itself.

ok( ($dp1->print_data_count), 'print_data_count');# 18
ok( ($dp1->get_data_count == 9), 'get_data_count');# 19
%seen = map { $_ => 1 } @{$dp1->get_keys};

ok($seen{210297}, 'key recognized');    # 20
ok($seen{392877}, 'key recognized');    # 21
ok($seen{399723}, 'key recognized');    # 22
ok($seen{399901}, 'key recognized');    # 23
ok($seen{456600}, 'key recognized');    # 24
ok($seen{456787}, 'key recognized');    # 25
ok($seen{456788}, 'key recognized');    # 26
ok($seen{456789}, 'key recognized');    # 27
ok($seen{456892}, 'key recognized');    # 28
ok(! $seen{987654}, 'key correctly not recognized');# 29
ok(! $seen{123456}, 'key correctly not recognized');# 30
ok(! $seen{333333}, 'key correctly not recognized');# 31
ok(! $seen{135799}, 'key correctly not recognized');# 32

# 3.01:  Beginning with the 1st object created above, create a 
#        Data::Presenter::Combo::Intersect object:

@objects = ($dp0, $dp1);
my $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);

ok($dpCI->isa("Data::Presenter::Combo::Intersect"), 'D::P::Combo::Intersect object created');# 33
ok($dpCI->can("get_data_count"), 'get_data_count');# 34
ok($dpCI->can("print_data_count"), 'print_data_count');# 35
ok($dpCI->can("get_keys"), 'get_keys'); # 36
ok($dpCI->can("sort_by_column"), 'sort_by_column');# 37
ok($dpCI->can("select_rows"), 'select_rows');# 38
ok($dpCI->can("print_to_screen"), 'print_to_screen');# 39
ok($dpCI->can("print_to_file"), 'print_to_file');# 40
ok($dpCI->can("print_with_delimiter"), 'print_with_delimiter');# 41
ok($dpCI->can("full_report"), 'full_report');# 42
ok($dpCI->can("writeformat"), 'writeformat');# 43
ok($dpCI->can("writeformat_plus_header"), 'writeformat_plus_header');# 44
ok($dpCI->can("writedelimited"), 'writedelimited');# 45
ok($dpCI->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 46
ok($dpCI->can("writeHTML"), 'writeHTML');# 47

# 3.02:  Get information about the Data::Presenter::Combo object itself.

ok( ($dpCI->print_data_count), 'print_data_count');# 48
ok( ($dpCI->get_data_count == 3), 'get_data_count');# 49
%seen = map { $_ => 1 } @{$dpCI->get_keys};

ok($seen{456787}, 'key recognized');    # 50
ok($seen{456788}, 'key recognized');    # 51
ok($seen{456789}, 'key recognized');    # 52
ok(! $seen{210297}, 'key correctly not recognized');# 53
ok(! $seen{392877}, 'key correctly not recognized');# 54
ok(! $seen{399723}, 'key correctly not recognized');# 55
ok(! $seen{399901}, 'key correctly not recognized');# 56
ok(! $seen{456600}, 'key correctly not recognized');# 57

# 3.03:  Call simple output methods on Data::Presenter::Combo::Intersect object:

$return = $dpCI->print_to_screen();
ok( ($return == 1), 'print_to_screen'); # 58

$outputfile = "$resultsdir/census10.txt";
$return = $dpCI->print_to_file($outputfile);
ok( ($return == 1), 'print_to_file');   # 59

$outputfile = "$resultsdir/census10_delimited.txt";
$delimiter = '|||';
$return = $dpCI->print_with_delimiter($outputfile,$delimiter);
ok( ($return == 1), 'print_with_delimiter');# 60

$outputfile = "$resultsdir/report10.txt";
$return = $dpCI->full_report($outputfile);
ok( ($return == 1), 'full_report');     # 61

# 3.04:  Select particular fields (columns) from a Data::Presenter::Combo::Intersect 
#       object and establish the order in which they will be sorted:

@columns_selected = qw(ward lastname firstname datebirth cno medicare medicaid);
$sorted_data = $dpCI->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 62

# 3.05:  Call complex output methods on Data::Presenter::Combo::Intersect object:

$outputfile = "$resultsdir/format10.txt";
$return = $dpCI->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 63

$outputfile = "$resultsdir/format11.txt";
$title = 'Agency Census Report';
$return = $dpCI->writeformat_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 64

$outputfile = "$resultsdir/delimit10.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 65

$outputfile = "$resultsdir/delimit11.txt";
$delimiter = "\t";
$return = $dpCI->writedelimited_plus_header(
	$sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 66

$outputfile = "$resultsdir/report10.html";
$title = 'Agency Census Report';
$return = $dpCI->writeHTML(
	$sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeHTML');       # 67

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

