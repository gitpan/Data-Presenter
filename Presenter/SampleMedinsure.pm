package Data::Presenter::SampleMedinsure;
$VERSION = 0.68; # 10/23/2004
@ISA = qw(Data::Presenter);
use strict;
use warnings;

our ($lastname, $firstname, $cno, $stateid, $medicare, $medicaid);
our %data = ();
our %reserved = ();

sub _init {
    my ($self, $sourcefile, $fieldsref, $paramsref, $index, $reservedref) = @_;
    my @fields = @$fieldsref;       # for convenience
    my %parameters = %$paramsref;   # for convenience
    my @paramvalues = ();
    my %seen = ();
    %reserved = %$reservedref;
    
    $data{'fields'} = [@fields];
    for (my $i = 0; $i < scalar(@fields); $i++) {
            push @paramvalues, \@{$parameters{$fields[$i]}};
    }
    $data{'parameters'} = [@paramvalues];
    $data{'index'} = [$index];

    open(MEDIDATA, $sourcefile) || die "cannot open $sourcefile for reading: $!";     
    while (<MEDIDATA>) {
        # DATA MUNGING STARTS HERE
        if (/^\s{4}\b[\w\s\d-]{35}\d{6}/) {    # NB:  would automatically bypass entry with cno eq 'fields' because it's not 6 digits
            $lastname = $firstname = $cno =
                $stateid = $medicare = $medicaid = '';
            my $balance = '';
            my @entries = ();
            die "The character '!' is reserved for internal use and cannot appear\nin data being processed by Data::Presenter:  $!"
                if (/!/);    # REQUIRED!
            ($lastname, $firstname, $cno, $balance) =
                    unpack("xxxx A16 x A16 xx A6 x A*", $_);
            # Do data munging here as needed
            # no stateid, medicare or medicaid number
            if ($balance eq '') {
                @entries = ($lastname, $firstname, $cno, '', '', '');
            }

            # stateid, but no medicare or medicaid number
            elsif ($balance =~ /^\s{4}([\s\d]\d{6})$/) {
                $stateid = $1;
                @entries = ($lastname, $firstname, $cno, $stateid, '', '');
            }
            # stateid, medicare, but no medicaid
            elsif ($balance =~ /^\s{4}([\s\d]\d{6})\s{5}(\d{9}(A|B|C\d{1,2}|D|M))$/) {
                $stateid = $1;
                $medicare = $2;
                @entries = ($lastname, $firstname, $cno, $stateid, $medicare, '');
            }
            # stateid, medicare and medicaid all present
            elsif ($balance =~ /^\s{4}([\s\d]\d{6})\s{5}(\d{9}(A|B\d{1,2}|C\d{1,2}|D|M))\s{5,7}(\w{2}\d{5}\w)/) {
                $stateid = $1;
                $medicare = $2;
                $medicaid = $4;
                @entries = ($lastname, $firstname, $cno, $stateid, $medicare, $medicaid);
            }
            # stateid and medicaid, but no medicare
            elsif ($balance =~ /^\s{4}([\s\d]\d{6})\s{22}(\w{2}\d{5}\w)/) {
                $stateid = $1;
                $medicaid = $2;
                @entries = ($lastname, $firstname, $cno, $stateid, '', $medicaid);
            }
            # medicare but no stateid or medicaid
            elsif ($balance =~ /^\s{4}\s{12}(\d{9}(A|B|C\d{1,2}|D|M))$/) {
                $medicare = $1;
                @entries = ($lastname, $firstname, $cno, '', $medicare, '');
            }
            # medicare and medicaid but no stateid
            elsif ($balance =~ /^\s{4}\s{12}(\d{9}(A|B|C\d{1,2}|D|M))\s{5,7}(\w{2}\d{5}\w)$/) {
                $medicare = $1;
                $medicaid = $3;
                @entries = ($lastname, $firstname, $cno, '', $medicare, $medicaid);
            }
            # medicaid but no stateid or medicare
            elsif ($balance =~ /^\s{4}\s{27}(\w{2}\d{5}\w)$/) {
                $medicaid = $1;
                @entries = ($lastname, $firstname, $cno, '', '', $medicaid);
            }
            # other cases not yet defined
            else {
                @entries = ($lastname, $firstname, $cno, 'DEFECT', 'DEFECT', 'DEFECT');
            }
            # DATA MUNGING ENDS HERE
            $seen{$entries[$index]}++;    # NEW!
            die "You have attempted to use $entries[$index] as the index key\n    for more than 1 entry in the data source.\n    Each entry in the data must have a unique value\n    in the index column:  $!"
                if $seen{$entries[$index]} > 1;    # NEW!
            if (! $reserved{$entries[$index]}) {
                $data{$entries[$index]} = \@entries;
            } else {
                die "The words 'fields', 'parameters', 'index' and 'options'\n    cannot be used as the unique index to a data record\n    in this program.  $!";
            }
        }
    }
    close (MEDIDATA) || die "can't close $sourcefile:$!";
    # %data is now a hash of references to arrays, each of which stores the info for 1 record
    return \%data;
}

sub _extract_rows {
    my ($self, $column, $relation, $choicesref, $fpref, $flref, 
        $_analyze_relation_subref, $_strip_non_matches_subref) = @_;
    my %objdata = %$self;
    my %fp = %$fpref;
    my %fieldlabels = %$flref;
    my ($inequality_ref, $dataref);

    # Analysis of $column
    # DATA MUNGING STARTS HERE
    $column = lc($column);  # In 'fields_medinsure.data', all elements of @fields are l.c.
    # DATA MUNGING ENDS HERE
    die "Column (field) name requested does not exist in \@fields:  $!"  unless (exists $fieldlabels{$column});
    my $sortorder = $fp{$column}[1];
    my $sorttype = $fp{$column}[2];
    
    # Analysis of $relation:  &_analyze_relation passed by reference from Data::Presenter
    ($relation, $inequality_ref) = &$_analyze_relation_subref($relation, $sorttype);

    # Analysis of @choices (partial)
    my $choice = '';
    my @corrected = ();
    my %seen = ();
    die "Too many choices for less than\/greater than comparison:  $!"
        if (scalar(@$choicesref) > 1 && ${$inequality_ref}{$relation});
    foreach $choice (@$choicesref) {
        # DATA MUNGING STARTS HERE
        # Do data munging here as needed
        $choice = uc($choice);  # because all data in 'in.txt' is u.c.
        # DATA MUNGING ENDS HERE
        push(@corrected, $choice);
        $seen{$choice} = 1;
    }

    # Strip out non-matching rows:  &_strip_non_matches passed by reference from Data::Presenter
    $dataref = &$_strip_non_matches_subref(\%objdata, \%fieldlabels, $column, $relation, \@corrected, \%seen);
    return $dataref;
}

1;

############################## DOCUMENTATION ############################## 

=head1 NAME

Data::Presenter::SampleMedinsure

=head1 VERSION

This document refers to version 0.68 of Data::Presenter::SampleMedinsure, released October 23, 2004. 

=head1 DESCRIPTION

This package is a sample subclass of, and inherits from, Data::Presenter.  Please see the Data::Presenter documentation to learn how to use Data::Presenter::SampleMedinsure.

As a sample package, Data::Presenter::SampleMedinsure is intended to be used with the following files contained in this distribution:

=over 4

=item *

F<medinsure.txt>

=item *

F<fields.medinsure.data>

=back

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

Creation date:  October 25, 2001.  Last modification date:  October 23, 2004.  Copyright (c) 2001-4 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 


