package Data::Presenter::Combo::Union;
$VERSION = 0.68; # 10/23/2004
@ISA = qw(Data::Presenter::Combo);
use strict;
use warnings;

our %reserved_partial = (
    'fields'    => 1,
    'index'     => 1,
    'options'   => 1,
);

sub _merge_engine {
    my ($self, $baseref, $secref, $newbaseref, $secpresentflipref, 
        $secneededref) = @_;
    my %base = %$baseref;
    my %sec = %$secref;
    my %newbase = %$newbaseref;
    my %secpresentflip = %$secpresentflipref;
    my %secneeded = %$secneededref;
    my @basekeys = (keys %base);
    my @seckeys = (keys %sec);
    my %seen = ();

    my %seenbase = ();
    my %seensec = ();
    my %seenboth = ();
    my %seenbaseonly = ();
    my %seenseconly = ();
     my @basefields = @{$base{'fields'}};
    my @secfields = @{$sec{'fields'}};
    
    # Build 2 look-up tables showing fields found in base and sec
    foreach my $i (sort @basekeys) {
        # with the exception of the reserved entries 
        # (being built in parent Combo) ...
        unless ($reserved_partial{$i}) {
            $seenbase{$i} = 1;
        }
    }
    foreach my $j (sort @seckeys) {
        # with the exception of the reserved entries 
        # (being built in parent Combo) ...
        unless ($reserved_partial{$j}) {
            $seensec{$j} = 1;
        }
    }
    
    # Build 3 look-up tables showing whether fields were found in 
    # base, sec or both
    foreach my $k (sort keys %seenbase) {
        if (defined $seensec{$k}) {$seenboth{$k} = 1;}
        else {$seenbaseonly{$k} = 1;}
    }
    foreach my $m (sort keys %seensec) {
        $seenseconly{$m} = 1 unless ($seenboth{$m});
    }

    # Work thru the 3 look-up tables to assign values
    my (@values, @temp);
    my $null = '';
    foreach my $n (sort keys %seenbaseonly) {
        @values = ();
        @temp = @{$base{$n}};
        for (my $q=0; $q < scalar(@temp); $q++) {
            if (defined $temp[$q]) {$values[$q] = $temp[$q];}
            else {$values[$q] = $null;}
        }
        for (my $p=0; $p < scalar(keys %secneeded); $p++) {
            push(@values, $null);
        }
        $newbase{$n} = [@values];
    }
    foreach my $n (sort keys %seenseconly) {
        @values = ();
        for (my $q=0; $q < scalar(@basefields); $q++) {
            if (defined $secpresentflip{$basefields[$q]})
                {$values[$q] = $sec{$n}->[$secpresentflip{$basefields[$q]}[1]];}
            else {$values[$q] = $null;}
        }
        foreach my $r (sort keys %secneeded) {
            my $s = $sec{$n}->[$r];
            if ($s) {push(@values, $s);}
            else {push(@values, $null);}
        }
        $newbase{$n} = [@values];
    }
    foreach my $n (sort keys %seenboth) {
        @values = ();
        @temp = @{$base{$n}};
        for (my $q=0; $q < scalar(@temp); $q++) {
            if (defined $temp[$q]) {$values[$q] = $temp[$q];}
            else {$values[$q] = $null;}
        }
        foreach my $r (sort keys %secneeded) {
            my $s = $sec{$n}->[$r];
            if ($s) {push(@values, $s);}
            else {push(@values, $null);}
        }
        $newbase{$n} = [@values];
    }
    return \%newbase;
}
            
1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Combo::Union

=head1 VERSION

This document refers to version 0.68 of Data::Presenter::Combo::Union, released October 23, 2004. 

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter::Combo.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo::Union.

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

Creation date:  October 28, 2001.  Last modification date:  October 23, 2004.  Copyright (c) 2001-4 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 


