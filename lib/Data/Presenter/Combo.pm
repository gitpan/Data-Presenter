package Data::Presenter::Combo;
$VERSION = 1.01; # 12-28-2005
@ISA = qw(Data::Presenter);
use strict;
use warnings;
use Carp;
use Data::Dumper;

sub _init {
    my ($self, $source) = @_;
    my @objects = @$source;
    croak "Not enough sources to create a Combo data source:  $!" 
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

    # for readability
    my %basehash        = %$base;
    my %sechash         = %$sec;
    my @basefields      = @{$basehash{fields}};
    my @secfields       = @{$sechash{fields}};
    my @baseparameters  = @{$basehash{parameters}};
    my @secparameters   = @{$sechash{parameters}};
    my $baseindex       = $base->{index};
    my $secindex        = $sec->{index};
    my @baseindexparams = @{$baseparameters[$baseindex]};
    my @secindexparams  = @{$secparameters[$secindex]};
    
    # Verify that all sources share a commonly named, identically specified 
    # index field
    croak "All data sources must have an identically named index field\n    in the configuration file:  $!"
        unless ($basefields[$baseindex] eq $secfields[$secindex]);
    for (my $i=0; $i<scalar(@baseindexparams); $i++) {
        croak "All data sources must have identically specified parameters\n    for the index field in the configuration file:  $!"
            unless ($baseindexparams[$i] eq $secindexparams[$i]);
    }

    # Build the new Combo::[subclass] object's 'fields' entry
    my $augmented_fields_ref = _augment_fields(\@basefields, \@secfields);
    my $newbasefieldsref    = ${$augmented_fields_ref}{newfields};
    my $secfieldspresentref = ${$augmented_fields_ref}{secfieldspresent};
    my $secfieldsneededref  = ${$augmented_fields_ref}{secfieldsneeded};

    # Build the new Combo::[subclass] object's replacement for %fieldlabels
    my %newbasefieldlabels;
    for (my $i = 0; $i < scalar(@{$newbasefieldsref}); $i++) {
        $newbasefieldlabels{${$newbasefieldsref}[$i]} = $i;
    }
     
    # Build the new Combo::[subclass] object's replacement for %fp
    my %newbasefp;
    for (my $i = 0; $i < scalar(@basefields); $i++) {
         $newbasefp{$basefields[$i]} = \@{ $baseparameters[$i] };
    }
    foreach my $el (keys %{$secfieldsneededref}) {
        $newbasefp{$secfields[$el]} = \@{ $secparameters[$el] };
    }
     
    # %secpresentflip:  Look-up table listing keys in sec also found in base;
    # value contains index position of that field;
    # needed because I don't want a key eq '0'.
    my %secpresentflip = ();

    foreach my $key (keys %$secfieldspresentref) {
        $secpresentflip{${$secfieldspresentref}{$key}} = [1, $key];
    }

    my %basefieldlabels;    # Example:   'cno'  => '2'
    my %secfieldlabels;     # Example:   'cno'  => '4'
    for (my $i = 0; $i < scalar(@basefields); $i++) {
        $basefieldlabels{$basefields[$i]} = $i;
    }
    for (my $i = 0; $i < scalar(@secfields); $i++) {
        $secfieldlabels{$secfields[$i]} = $i;
    }
    my %basefields = map {$_,1} @basefields;
    my %secfields = map {$_,1} @secfields;
    my %sharedfields;       # Example:  'cno'   => [ 2, 4 ]
    foreach my $field (keys %basefields) {
        $sharedfields{$field} = [ 
            $basefieldlabels{$field},
            $secfieldlabels{$field} 
        ] if ($secfields{$field});
    }

    # %newbase will become the hash of arrays blessed into the 
    # Combo::[subclass] object;
    # a reference to it will be _merge_into_base's return value.
    # Since its population is iterative, I have to start with an 
    # empty hash reference.
    my $newbaseref = {};

    # pass variables to $self->_merge_engine();
    $newbaseref = $self->_merge_engine(
        {
           base             => $base,
           basefieldlabels  => \%basefieldlabels,
           secondary        => $sec,
           secfieldlabels   => \%secfieldlabels,
           secpresentflip   => \%secpresentflip, 
           secfieldsneeded  => $secfieldsneededref,
           newbase          => $newbaseref,
           newbasefields    => $newbasefieldsref,
           newfp            => \%newbasefp,
           newfieldlabels   => \%newbasefieldlabels,
           sharedfields     => \%sharedfields,
        }
    );
    
    # populate the Combo::[subclass] object's data structure
    my %newbase = %$newbaseref;
    $newbase{'fields'} = $newbasefieldsref;
    $newbase{'index'}  = $baseindex;
    return \%newbase;
}

################################################################################
##### &_augment_fields: called from within &_merge_into_base
##### Prepares the 'fields' entry in the new Combo::[subclass] object
################################################################################

sub _augment_fields {
    my @basefields = @{+shift};
    my @secfields  = @{+shift};
    my %seen = ();
    my @additions = ();
    my @total = ();
    my %secneeded = ();
    my %secpresent = ();
    
    # Work thru sec's @fields by index 
    for (my $d = 0; $d < scalar(@secfields); $d++) {
        # Identify fields in base which are found in sec; store in seen-hash.
        # Along the way build a look-up table %secpresent whose 
        # value is the name of a field in sec which is *also* found in base,
        # and whose 
        # key is the index that that value *originally* had in sec's @fields
        foreach my $c (@basefields) {
            if ($c eq $secfields[$d]) {
                $seen{$secfields[$d]} = 1;
                    # $secfields[$d] is member of @basefields
                $secpresent{$d} = $secfields[$d];
                last;
            }
        }
        # If a field in sec is *not* found in base, 
        # add field's name to list of fields to be added
        push @additions, $secfields[$d] unless ($seen{$secfields[$d]});
        
        # Build a look-up table %secneeded whose 
        # value is the name of a field to be added, 
        # and whose key is the index that that value 
        # *originally* had in sec's @fields
        foreach my $j (@additions) {
            $secneeded{$d} = $j if ($j eq $secfields[$d]);
        }
    }
    
    # Add those fields that need to be added
    @total = (@basefields, @additions);

    # Return references to the combined list of 'fields' and to the 
    # two look-up tables
    my $augmented_fields_ref = {
        newfields           => \@total,
        secfieldspresent    => \%secpresent,
        secfieldsneeded     => \%secneeded,
    };
    return $augmented_fields_ref;
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
    croak "Column (field) name requested does not exist in \@fields:  $!"
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
    croak "Too many choices for less than\/greater than comparison:  $!"
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

This document refers to version 1.01 of Data::Presenter::Combo, released December 28, 2005. 

=head1 DESCRIPTION

This package is a subclass of, and inherits from, Data::Presenter.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::Combo.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 25, 2001.  Last modification date:  December 28, 2005.  Copyright (c) 2001-4 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 

__END__
=pod iterative_building_of_fp_and_fieldlabels

# Note 12/4/2005:  I can build these two hashes up here, but I don't know what
# to do with them yet.  They cannot currently be passed to
# $self->_merge_engine(), and the Data::Presenter constructor is going to 
# rebuild them after $self->_init() has run.  

# But they may be useful in solving the
# problem of getting the right null value in Intersect or Union.
# Suppose the fully merged object's hash is $data and a given record is $key.
#     $data{$key} = [ $alpha, $beta, ..., $omega ];
# The sort type for the ith element index in that array is:
#       $sort_type = $newbasefp{$newbasefields[$i]}[2];

=cut

