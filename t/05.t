# 05.t
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { 
	$last_test_to_print = 158;
	$| = 1; 
	print "1..$last_test_to_print\n"; } 
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use Data::Presenter;
use Data::Presenter::SampleSchedule;
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
my ($keysref, $data_count);

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

# Name of variable holding the anonymous hash blessed into a Mall::SampleSchedule1 object
# which has some fields suitable for reprocessing
our ($ms);
# File holding this anonymous hash
my $hashfile = "$topdir/source/reprocessible.txt";
require $hashfile;

# 1.01:  Create a Data::Presenter::SampleSchedule object:

$fieldsfile = "$topdir/config/fields_schedule.data";
do $fieldsfile;
my $dp = Data::Presenter::SampleSchedule->new($ms, \@fields, \%parameters, $index);
ok($dp->isa("Data::Presenter::SampleSchedule"), 'D::P::SampleSchedule object created');# 3

ok($dp->can("get_data_count"), 'get_data_count');# 4
ok($dp->can("print_data_count"), 'print_data_count');# 5
ok($dp->can("get_keys"), 'get_keys');   # 6
ok($dp->can("sort_by_column"), 'sort_by_column');# 7
ok($dp->can("seen_one_column"), 'seen_one_column');# 8
ok($dp->can("select_rows"), 'select_rows');# 9
ok($dp->can("print_to_screen"), 'print_to_screen');# 10
ok($dp->can("print_to_file"), 'print_to_file');# 11
ok($dp->can("print_with_delimiter"), 'print_with_delimiter');# 12
ok($dp->can("full_report"), 'full_report');# 13
ok($dp->can("writeformat"), 'writeformat');# 14
ok($dp->can("writeformat_plus_header"), 'writeformat_plus_header');# 15
ok($dp->can("writedelimited"), 'writedelimited');# 16
ok($dp->can("writedelimited_plus_header"), 'writedelimited_plus_header');# 17
ok($dp->can("writeHTML"), 'writeHTML'); # 18
ok($dp->can("writeformat_with_reprocessing"), 'writeformat_with_reprocessing');# 19
ok($dp->can("writeformat_deluxe"), 'writeformat_deluxe');# 20
ok($dp->can("writedelimited_with_reprocessing"), 'writedelimited_with_reprocessing');# 21
ok($dp->can("writedelimited_deluxe"), 'writedelimited_deluxe');# 22

# 1.02:  Get information about the Data::Presenter::SampleSchedule object itself.

ok( ($dp->print_data_count), 'print_data_count');# 23
ok( ($dp->get_data_count == 83), 'get_data_count');# 24
%seen = map { $_ => 1 } @{$dp->get_keys};

ok($seen{'3022_54_001'}, 'key_recognized');# 25
ok($seen{'3024_44_001'}, 'key_recognized');# 26
ok($seen{'3030_11_001'}, 'key_recognized');# 27
ok($seen{'3030_21_001'}, 'key_recognized');# 28
ok($seen{'3030_24_001'}, 'key_recognized');# 29
ok($seen{'3030_33_001'}, 'key_recognized');# 30
ok($seen{'3030_42_001'}, 'key_recognized');# 31
ok($seen{'3030_51_001'}, 'key_recognized');# 32
ok($seen{'3031_11_001'}, 'key_recognized');# 33
ok($seen{'3031_21_001'}, 'key_recognized');# 34
ok($seen{'3031_24_001'}, 'key_recognized');# 35
ok($seen{'3031_31_001'}, 'key_recognized');# 36
ok($seen{'3031_33_001'}, 'key_recognized');# 37
ok($seen{'3031_51_001'}, 'key_recognized');# 38
ok($seen{'3032_11_001'}, 'key_recognized');# 39
ok($seen{'3032_22_001'}, 'key_recognized');# 40
ok($seen{'3032_31_001'}, 'key_recognized');# 41
ok($seen{'3032_34_001'}, 'key_recognized');# 42
ok($seen{'3032_42_001'}, 'key_recognized');# 43
ok($seen{'3032_51_001'}, 'key_recognized');# 44
ok($seen{'3032_54_001'}, 'key_recognized');# 45
ok($seen{'3038_11_001'}, 'key_recognized');# 46
ok($seen{'3038_22_001'}, 'key_recognized');# 47
ok($seen{'3038_31_001'}, 'key_recognized');# 48
ok($seen{'3038_34_001'}, 'key_recognized');# 49
ok($seen{'3038_42_001'}, 'key_recognized');# 50
ok($seen{'3038_51_001'}, 'key_recognized');# 51
ok($seen{'3044_12_001'}, 'key_recognized');# 52
ok($seen{'3044_54_001'}, 'key_recognized');# 53
ok($seen{'3047_12_001'}, 'key_recognized');# 54
ok($seen{'3047_22_001'}, 'key_recognized');# 55
ok($seen{'3047_31_001'}, 'key_recognized');# 56
ok($seen{'3047_34_001'}, 'key_recognized');# 57
ok($seen{'3047_42_001'}, 'key_recognized');# 58
ok($seen{'3047_52_001'}, 'key_recognized');# 59
ok($seen{'3048_12_001'}, 'key_recognized');# 60
ok($seen{'3048_22_001'}, 'key_recognized');# 61
ok($seen{'3048_32_001'}, 'key_recognized');# 62
ok($seen{'3048_34_001'}, 'key_recognized');# 63
ok($seen{'3048_43_001'}, 'key_recognized');# 64
ok($seen{'3048_52_001'}, 'key_recognized');# 65
ok($seen{'3049_12_001'}, 'key_recognized');# 66
ok($seen{'3049_23_001'}, 'key_recognized');# 67
ok($seen{'3049_32_001'}, 'key_recognized');# 68
ok($seen{'3049_41_001'}, 'key_recognized');# 69
ok($seen{'3049_43_001'}, 'key_recognized');# 70
ok($seen{'3049_52_001'}, 'key_recognized');# 71
ok($seen{'3050_13_001'}, 'key_recognized');# 72
ok($seen{'3050_23_001'}, 'key_recognized');# 73
ok($seen{'3050_32_001'}, 'key_recognized');# 74
ok($seen{'3050_41_001'}, 'key_recognized');# 75
ok($seen{'3050_43_001'}, 'key_recognized');# 76
ok($seen{'3050_52_001'}, 'key_recognized');# 77
ok($seen{'3051_13_001'}, 'key_recognized');# 78
ok($seen{'3051_23_001'}, 'key_recognized');# 79
ok($seen{'3051_32_001'}, 'key_recognized');# 80
ok($seen{'3051_41_001'}, 'key_recognized');# 81
ok($seen{'3051_43_001'}, 'key_recognized');# 82
ok($seen{'3052_13_001'}, 'key_recognized');# 83
ok($seen{'3052_23_001'}, 'key_recognized');# 84
ok($seen{'3052_33_001'}, 'key_recognized');# 85
ok($seen{'3052_41_001'}, 'key_recognized');# 86
ok($seen{'3052_44_001'}, 'key_recognized');# 87
ok($seen{'3054_13_001'}, 'key_recognized');# 88
ok($seen{'3054_24_001'}, 'key_recognized');# 89
ok($seen{'3054_33_001'}, 'key_recognized');# 90
ok($seen{'3054_41_001'}, 'key_recognized');# 91
ok($seen{'3054_44_001'}, 'key_recognized');# 92
ok($seen{'3054_53_001'}, 'key_recognized');# 93
ok($seen{'3068_54_001'}, 'key_recognized');# 94
ok($seen{'3069_14_001'}, 'key_recognized');# 95
ok($seen{'3069_24_001'}, 'key_recognized');# 96
ok($seen{'3069_33_001'}, 'key_recognized');# 97
ok($seen{'3069_42_001'}, 'key_recognized');# 98
ok($seen{'3069_44_001'}, 'key_recognized');# 99
ok($seen{'3069_53_001'}, 'key_recognized');# 100
ok($seen{'3071_14_001'}, 'key_recognized');# 101
ok($seen{'3071_53_001'}, 'key_recognized');# 102
ok($seen{'3072_14_001'}, 'key_recognized');# 103
ok($seen{'3072_53_001'}, 'key_recognized');# 104
ok($seen{'3077_14_001'}, 'key_recognized');# 105
ok($seen{'3078_21_001'}, 'key_recognized');# 106
ok($seen{'3086_21_001'}, 'key_recognized');# 107
ok(! $seen{210297}, 'key correctly not recognized');# 108
ok(! $seen{359962}, 'key correctly not recognized');# 109
ok(! $seen{392877}, 'key correctly not recognized');# 110
ok(! $seen{399723}, 'key correctly not recognized');# 111
ok(! $seen{399901}, 'key correctly not recognized');# 112
ok(! $seen{456600}, 'key correctly not recognized');# 113
ok(! $seen{456787}, 'key correctly not recognized');# 114
ok(! $seen{456788}, 'key correctly not recognized');# 115
ok(! $seen{456789}, 'key correctly not recognized');# 116
ok(! $seen{456790}, 'key correctly not recognized');# 117
ok(! $seen{456791}, 'key correctly not recognized');# 118
ok(! $seen{456792}, 'key correctly not recognized');# 119
ok(! $seen{456892}, 'key correctly not recognized');# 120
ok(! $seen{458732}, 'key correctly not recognized');# 121
ok(! $seen{498703}, 'key correctly not recognized');# 122
ok(! $seen{698389}, 'key correctly not recognized');# 123
ok(! $seen{786792}, 'key correctly not recognized');# 124
ok(! $seen{803092}, 'key correctly not recognized');# 125
ok(! $seen{906786}, 'key correctly not recognized');# 126

# 1.03:  Select the order in which fields should appear in output.

@columns_selected = ('timeslot', 'instructor', 'ward', 'groupname', 'room', 'groupid');
$sorted_data = $dp->sort_by_column(\@columns_selected);
ok( (1 == sdtest(\@columns_selected, $sorted_data)), 'valid sorted data hash');# 127

# 1.03.1:  Select exactly one column from a Data::Presenter::SampleSchedule
#          object and count frequency of entries in that column:
{
    local $SIG{__WARN__} = \&_capture;
    $return = $dp->seen_one_column();
}
ok( ($return == 0), 'seen_one_column: 0 args'); # 128

{
    local $SIG{__WARN__} = \&_capture;
    $return = $dp->seen_one_column('unit', 'ward');
}
ok( ($return == 0), 'seen_one_column: 2 args'); # 129

%seen = %{$dp->seen_one_column('room')};
ok( ($seen{'3038'} == 6), 'seen_one_column:  1 arg');# 130
ok( ($seen{'3054'} == 6), 'seen_one_column:  1 arg');# 131
ok( ($seen{'3071'} == 2), 'seen_one_column:  1 arg');# 132
ok( ($seen{'3047'} == 6), 'seen_one_column:  1 arg');# 133
ok( ($seen{'3072'} == 2), 'seen_one_column:  1 arg');# 134
ok( ($seen{'3048'} == 6), 'seen_one_column:  1 arg');# 135
ok( ($seen{'3049'} == 6), 'seen_one_column:  1 arg');# 136
ok( ($seen{'3068'} == 1), 'seen_one_column:  1 arg');# 137
ok( ($seen{'3077'} == 1), 'seen_one_column:  1 arg');# 138
ok( ($seen{'3069'} == 6), 'seen_one_column:  1 arg');# 139
ok( ($seen{'3078'} == 1), 'seen_one_column:  1 arg');# 140
ok( ($seen{'3086'} == 1), 'seen_one_column:  1 arg');# 141
ok( ($seen{'3030'} == 6), 'seen_one_column:  1 arg');# 142
ok( ($seen{'3022'} == 1), 'seen_one_column:  1 arg');# 143
ok( ($seen{'3031'} == 6), 'seen_one_column:  1 arg');# 144
ok( ($seen{'3024'} == 1), 'seen_one_column:  1 arg');# 145
ok( ($seen{'3032'} == 7), 'seen_one_column:  1 arg');# 146
ok( ($seen{'3050'} == 6), 'seen_one_column:  1 arg');# 147
ok( ($seen{'3051'} == 5), 'seen_one_column:  1 arg');# 148
ok( ($seen{'3044'} == 2), 'seen_one_column:  1 arg');# 149
ok( ($seen{'3052'} == 5), 'seen_one_column:  1 arg');# 150

# 1.04:  Data::Presenter output methods available for all D::P objects.

$outputfile = "$resultsdir/format001.txt";
$return = $dp->writeformat($sorted_data, \@columns_selected, $outputfile);
ok( ($return == 1), 'writeformat');     # 151

$outputfile = "$resultsdir/format002.txt";
$title = 'Here\'s a header!';
$return = $dp->writeformat_plus_header($sorted_data, \@columns_selected, $outputfile, $title);
ok( ($return == 1), 'writeformat_plus_header');# 152

$outputfile = "$resultsdir/format000.txt";
$delimiter = "\t";
$return = $dp->writedelimited($sorted_data, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited');  # 153

$outputfile = "$resultsdir/format0000.txt";
$delimiter = "\t";
$return = $dp->writedelimited_plus_header($sorted_data, \@columns_selected, $outputfile, $delimiter);
ok( ($return == 1), 'writedelimited_plus_header');# 154

# 1.05:  Data::Presenter output methods for reprocessing.

%reprocessing_info = (
	'timeslot'   => 26,
	'instructor' => 27,
);

$outputfile = "$resultsdir/format003.txt";
$return = $dp->writeformat_with_reprocessing(
    $sorted_data, \@columns_selected, $outputfile, \%reprocessing_info);
ok( ($return == 1), 'writeformat_with_reprocessing');# 155

$outputfile = "$resultsdir/format004.txt";
$title = 'Testing &writeformat_deluxe';
$return = $dp->writeformat_deluxe(
    $sorted_data, \@columns_selected, $outputfile, $title, \%reprocessing_info);
ok( ($return == 1), 'writeformat_deluxe');# 156

@reprocessing_info = qw( instructor timeslot room );

$outputfile = "$resultsdir/format00000.txt";
$delimiter = "\t";
$return = $dp->writedelimited_with_reprocessing(
    $sorted_data, \@columns_selected, $outputfile, \@reprocessing_info, $delimiter);
ok( ($return == 1), 'writedelimited_with_reprocessing');# 157

$outputfile = "$resultsdir/format000000.txt";
$delimiter = "\t";
@reprocessing_info = qw( instructor timeslot room );
$return = $dp->writedelimited_deluxe(
    $sorted_data, \@columns_selected, $outputfile, \@reprocessing_info, $delimiter);
ok( ($return == 1), 'writedelimited_deluxe');# 158

