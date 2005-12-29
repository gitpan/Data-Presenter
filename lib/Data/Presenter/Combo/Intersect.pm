package Data::Presenter::Combo::Intersect;
$VERSION = 1.01; # 12-28-2005
@ISA = qw(Data::Presenter::Combo);
use strict;
use warnings;
use Data::Dumper;

our %reserved_partial = (
    'fields'   => 1,
    'index'    => 1,
    'options'  => 1,
);

sub _merge_engine {
    my ($self, $mergeref) = @_;

    my %base                = %{${$mergeref}{base}};
    my %sec                 = %{${$mergeref}{secondary}};
    my %newbase             = %{${$mergeref}{newbase}};
    my %secneeded           = %{${$mergeref}{secfieldsneeded}};
    
    my %seenboth = ();

    # Work thru the entries in the base ...
    foreach my $i (keys %base) {
        # reserved entry qw| parameters | gets built here without any fuss
        # reserved entries qw| fields index options | get built in Combo.pm
        unless ($reserved_partial{$i}) {
            # and build up a look-up table %seenboth where each key is an entry
            # in the base found in BOTH base and sec 
            # i.e., the intersection of base and sec
            foreach my $j (keys %sec) {
                if ($i eq $j) {
                    $seenboth{$i} = 1;
                    last;
                }
            }
        }
    }
    
    # Work thru the look-up table ...
    my $null = q{};
    foreach my $rec (keys %seenboth) {
        my (@basevalues, @secvalues);
        # 1.  Assign the values encountered first in base
        my @record = @{$base{$rec}};
        for (my $q=0; $q < scalar(@record); $q++) {
#            if (defined $record[$q]) {
                $basevalues[$q] = $record[$q];
#            } else {
#                $basevalues[$q] = $null;
#            }
        }
        # 2.  Assign the values encountered first in sec
        # (%secneeded's keys are numbers:  field's subscripts in sec
        foreach my $i (sort {$a <=> $b} keys %secneeded) {
#            if (defined $sec{$rec}[$i]) {
                push @secvalues, $sec{$rec}[$i];
#            } else {
#                push @secvalues, $null;
#            }
        }
        $newbase{$rec} = [@basevalues, @secvalues];
    }
    return \%newbase;
    # Note:  This is actually newbase less the 'fields' and 'index' entries
}
            
1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Combo::Intersect

=head1 VERSION

This document refers to version 1.01 of Data::Presenter::Combo::Intersect, released December 28, 2005. 

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter::Combo.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo::Intersect.

=head1 HISTORY AND DEVELOPMENT

=head2 History

=over 4

=item *

v0.60 (4/6/03):  Version number was advanced to 0.60 to be consistent with steps taken to prepare Data::Presenter for public distribution.

=item *

v0.61 (4/12/03):  First version uploaded to CPAN.

=item *

v0.65 (6/2/04):  Changed line of code to avoid "Bizarre array assignment error when installing on Darwin on Perl 5.8.4.

=back

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 25, 2001.  Last modification date:  December 28, 2005.  Copyright (c) 2001-4 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 

__END__

#                my $sort_type = $newbasefp{$newbasefields[$q]}[2];
#                $basevalues[$q] = 
#                    ($sort_type eq 'a' or $sort_type eq 's')
#                        ? q{}
#                        : 0;

#                my $sort_type = $newbasefp{$newbasefields[$g]}[2]; #????
#                ($sort_type eq 'a' or $sort_type eq 's')
#                    ? push @secvalues, q{}
#                    : push @secvalues, 0;
