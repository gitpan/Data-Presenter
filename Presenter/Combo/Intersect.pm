package Data::Presenter::Combo::Intersect;
$VERSION = 0.62; # 4/13/03
@ISA = qw(Data::Presenter::Combo);
use strict;
use warnings;
use lib "C:/Perl/usr/lib";

our %reserved_partial = (
    'fields'   => 1,
    'index'    => 1,
    'options'  => 1,
);

sub _merge_engine {
    my ($self, $baseref, $secref, $newbaseref, $secpresentflipref, 
        $secneededref) = @_;
    my %base = %$baseref;
    my %sec = %$secref;
    my %newbase = %$newbaseref;
    my %secpresentflip = %$secpresentflipref;
        # (Not actually used, but retain for uniformity of interface.)
    my %secneeded = %$secneededref;
    my @basekeys = (keys %base);
    my @seckeys = (keys %sec);
    my %seen = ();

    # Work thru the entries in the base ...
    foreach my $i (@basekeys) {
        # with the exception of the reserved entries 
        # (being built in parent Combo) ...
        unless ($reserved_partial{$i}) {
            # and build up a look-up table where each left-hand key is an entry
            # in the base found in BOTH base and sec (the intersection of base 
            # and sec)
            foreach my $j (@seckeys) {
                if ($i eq $j) {
                    $seen{$i} = 1;
                    last;
                }
            }
        }
    }
    
    # Work thru the look-up table ...
    my @values = my @temp = my @additions = ();
    my $null = '';
    foreach my $n (sort keys %seen) {
        # first assign the values found first in base
        @values = ();
        @temp = @{$base{$n}};
        for (my $q=0; $q < scalar(@temp); $q++) {
            if (exists $temp[$q]) {$values[$q] = $temp[$q];}
            else {$values[$q] = $null;}
        }
        # then assign the values found first in sec
        @additions = ();
        foreach my $g (sort {$a <=> $b} keys %secneeded) {
            if (exists $sec{$n}[$g]) {push @additions, $sec{$n}[$g];}
            else {push @additions, $null;}
        }
        $newbase{$n} = [@values, @additions];
    }
    return \%newbase;
    # Note:  This is actually newbase less the 'fields' and 'index' entries
}
            
1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Combo::Intersect

=head1 VERSION

This document refers to version 0.62 of Data::Presenter::Combo::Intersect, released April 13, 2003.

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter::Combo.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo::Intersect.

=head1 HISTORY AND DEVELOPMENT

=head2 History

=over 4

=item *

v0.60 (4/6/03):  Version number was advanced to 0.60 to be consistent with steps taken to prepare Data::Presenter for public distribution.

=item *

v0.61 (4/12/03):  First version uploaded to CPAN.

=back

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 28, 2001.  Last modification date:  April 13, 2003.  Copyright (c) 2001-3 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 


