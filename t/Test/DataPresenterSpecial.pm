package Test::DataPresenterSpecial;
# Contains test subroutines for distribution with Data::Presenter
# As of:  August 24, 2003
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw( $testnum ok );
our @EXPORT_OK   = qw( sdtest _capture ); 
our %EXPORT_TAGS = (
    seen => [ qw(  sdtest _capture  ) ],
);
$testnum = 1;

sub ok {
	my $condition = shift;
	my $message = shift if (defined $_[0]);
	print $condition ? "ok $testnum" : "not ok $testnum";
	print "\t$message" if (defined $message);
	print "\n";
	$testnum++;
}

# test for content of $sorted_data
sub sdtest {
	my ($aref, $sorted_data) = @_;
	foreach (sort keys %{$sorted_data}) {
		return 0 unless ( (scalar(@{$aref})-1) == tr/!//);
	}
	return 1;
}

sub _capture { my $str = $_[0]; }

1;

