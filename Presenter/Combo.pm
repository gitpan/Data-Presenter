package Data::Presenter::Combo;
$VERSION = 0.66; # 06/09/2004
@ISA = qw(Data::Presenter);
use strict;
use warnings;

sub _init {
    my ($self, $source) = @_;
    my @objects = @$source;
    die "Not enough sources to create a Combo data source:  $!" 
        if scalar(@objects) < 2;

    # Designate the first object named as the 'base'
    my $base = shift @objects;
     
    # Merge the second object into the first and repeat the process as many 
    # times as needed, with the result of the merging as the new base
    while (scalar(@objects)) {
        my $sec = shift @objects;
        $base = $self->_merge_into_base($base, $sec);
    }
    return $base;
}

################################################################################
##### &_merge_into_base:  Called from within &_init
##### Iteratively merges the data structures in the Data::Presenter 
##### objects passed as arguments
################################################################################

sub _merge_into_base {
    my ($self, $base, $sec) = @_;
    my %newbase = ();
        # Will become the hash of arrays blessed into the 
        # Combo::[subclass] object
    my %secpresentflip = ();
        # Look-up table:
        # LH (key) is field in sec also found in base
        # RH (value) contains index position of that field
    # for readability
    my %basehash = %$base;
    my %sechash = %$sec;
    my @basefields = @{$basehash{'fields'}};
    my @secfields = @{$sechash{'fields'}};
    my $baseindex = ${$basehash{'index'}}[0];
    my $secindex = ${$sechash{'index'}}[0];
    my @baseindexparams = @{${$basehash{'parameters'}}[$baseindex]};
    my @secindexparams = @{${$sechash{'parameters'}}[$secindex]};
    
    # Verify that all sources share a commonly named, identically specified 
    # index field
    die "All data sources must have an identically named index field\n    in the configuration file:  $!"
        unless ($basefields[$baseindex] eq $secfields[$secindex]);
    for (my $i=0; $i<scalar(@baseindexparams); $i++) {
        die "All data sources must have identically specified parameters\n    for the index field in the configuration file:  $!"
            unless ($baseindexparams[$i] eq $secindexparams[$i]);
    }

    # Build the new Combo::[subclass] object's 'fields' entry
    my ($newbasefieldsref, $secpresentref, $secneededref) = 
        _augment(\@basefields, \@secfields);
    foreach my $key (sort keys %$secpresentref) {
        $secpresentflip{${$secpresentref}{$key}} = [1, $key];
    }

    # pass variables to $self->_merge_engine();
    my $newbaseref = $self->_merge_engine(
        \%$base, \%$sec, \%newbase, \%secpresentflip, $secneededref);
    
    # populate the Combo::[subclass] object's data structure
    %newbase = %$newbaseref;
    $newbase{'fields'} = $newbasefieldsref;
    $newbase{'index'} = [$baseindex];
    return \%newbase;
}

################################################################################
##### &_augment: called from within &_merge_into_base
##### Prepares the 'fields' entry in the new Combo::[subclass] object
################################################################################

sub _augment {
    my @aryref = @_;
    my @basefields = @{$aryref[0]};
        # Array which is value of base's 'fields' entry
    my @secfields = @{$aryref[1]};
        # Array which is value of sec's 'fields' entry
    my %seen = ();
    my @additions = ();
    my @total = ();
    my %secneeded = ();
    my %secpresent = ();
    
    # Work thru sec's 'fields' array by array index number
    for (my $d = 0; $d < scalar(@secfields); $d++) {
        # Identify fields in base which are found in sec.
        # Along the way build a look-up table where right-hand value is
        # the name of a field in sec which is also found in base,
        # while the left-hand key is the index that value originally had in 
        # sec's 'fields' entry
        foreach my $c (@basefields) {
            if ($c eq $secfields[$d]) {
                $seen{$secfields[$d]} = 1;
                    # $secfields[$d] is member of @basefields
                $secpresent{$d} = $secfields[$d];
                last;
            }
        }
        # If a field in sec is not found in base, 
        # add field's name to list of fields to be added
        push @additions, $secfields[$d] unless ($seen{$secfields[$d]});
        
        # Build a look-up table where the right-hand value is 
        # the name of a field to be added, 
        # while the left-hand key is the index that value originally had in 
        # sec's 'fields' entry
        foreach my $j (@additions) {
            $secneeded{$d} = $j if ($j eq $secfields[$d]);
        }
    }
    
    # Add those fields that need to be added
    @total = (@basefields, @additions);

    # Return references to the combined list of 'fields' and to the 
    # look-up tables
    return (\@total, \%secpresent, \%secneeded);
}

sub _extract_rows {
    my ($self, $column, $relation, $choicesref, $fpref, $flref, 
        $_analyze_relation_subref, $_strip_non_matches_subref) = @_;
    my %data = %$self;
    my %fp = %$fpref;
    my %fieldlabels = %$flref;
    my ($inequality_ref, $dataref);

    # Analysis of $column
    # DATA MUNGING STARTS HERE
#    $column = lc($column);
    # DATA MUNGING ENDS HERE
    die "Column (field) name requested does not exist in \@fields:  $!"
        unless (exists $fieldlabels{$column});
    my $sortorder = $fp{$column}[1];
    my $sorttype = $fp{$column}[2];
    
    # Analysis of $relation:  
    # &_analyze_relation passed by reference from Data::Presenter
    ($relation, $inequality_ref) = 
        &$_analyze_relation_subref($relation, $sorttype);

    # Analysis of @choices (partial)
    my $choice = '';
    my @corrected = ();
    my %seen = ();
    die "Too many choices for less than\/greater than comparison:  $!"
        if (scalar(@$choicesref) > 1 && ${$inequality_ref}{$relation});
    foreach $choice (@$choicesref) {
        # DATA MUNGING STARTS HERE
#        $choice = uc($choice);  # because all data in 'census.txt' is u.c.
        # DATA MUNGING ENDS HERE
        push(@corrected, $choice);
        $seen{$choice} = 1;
    }

    # Strip out non-matching rows:  
    # &_strip_non_matches passed by reference from Data::Presenter
    $dataref = &$_strip_non_matches_subref(
        \%data, \%fieldlabels, $column, $relation, \@corrected, \%seen);
    return $dataref;
}

1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::Combo

=head1 VERSION

This document refers to version 0.66 of Data::Presenter::Combo, released June 9, 2004. 

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 25, 2001.  Last modification date:  June 9, 2004.  Copyright (c) 2001-4 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 


