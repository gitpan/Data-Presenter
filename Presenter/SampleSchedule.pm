package Data::Presenter::SampleSchedule;
$VERSION = 0.62; # 4/13/03
@ISA = qw(Data::Presenter);
use strict;

sub _init {
    my ($self, $msobject, $fieldsref, $paramsref, $index, $reservedref) = @_;
    my @fields = @$fieldsref;       # for convenience
    my %parameters = %$paramsref;   # for convenience
    my @paramvalues = ();
    my (%data, %reprocess_subs, %seen);
    my %reserved = %$reservedref;      # for convenience
    $data{'fields'} = [@fields];
    for (my $i = 0; $i < scalar(@fields); $i++) {
            push @paramvalues, \@{$parameters{$fields[$i]}};
    }
    $data{'parameters'} = [@paramvalues];
    $data{'index'} = [$index];
    
    my %events = %$msobject;
    my ($k, $v);
    
    # on a first pass we won't do any munging or correcting except to get rid of
    # the 'linecount' key
    while ( ($k, $v) = each %events ) {
        next if ($k eq 'linecount' or $k eq 'options');
        my @temp = ($k, @$v);
        my @corrected = ();
        foreach (@temp) {
            if (/!/) {
                die "The character '!' is reserved for internal use and cannot appear\nin data being processed by Data::Presenter:  $!";
            } else {
                push @corrected, $_;
            }
        }
        $seen{$corrected[$index]}++;
        die "You have attempted to use $corrected[$index] as the index key\n    for more than 1 entry in the data source.\n    Each entry in the data must have a unique value\n    in the index column:  $!"
            if $seen{$corrected[$index]} > 1;
        if (! $reserved{$corrected[$index]}) {
            $data{$corrected[$index]} = \@corrected;
        } else {
            die "The words 'fields', 'parameters', 'index' and 'options'\n    cannot be used as the unique index to a data record\n    in this program.  $!";
        }
    }
    my $pkg = __PACKAGE__;    # per Benjamin Goldberg on comp.lang.perl.misc 10/28/02
    {
        no strict 'refs';
        foreach (sort keys %{ $pkg . "::" } ) {  # per BG on c.l.p.m. 10/29/02
          $reprocess_subs{$_}++ if
             $_ =~ /^reprocess_/ and defined *{$_}{CODE};
        }
    }
    $data{'options'}{'subs'} = \%reprocess_subs;
    foreach (keys %{$events{'options'}{'sources'}}) {
        $data{'options'}{'sources'}{$_} = $events{'options'}{'sources'}{$_};
    }
    return \%data;    #  is now a hash of references to arrays, each of which stores the info for 1 record
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
    $column = lc($column);  # In 'fields_schedule.data', all elements of @fields are l.c.
    # DATA MUNGING ENDS HERE
    die "Column (field) name requested does not exist in \@fields:  $!"  
        unless (exists $fieldlabels{$column});
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
#        $choice = uc($choice);  # because all data in 'census.txt' is u.c.
        # DATA MUNGING ENDS HERE
        push(@corrected, $choice);
        $seen{$choice} = 1;
    }

    # Strip out non-matching rows:  &_strip_non_matches passed by reference from Data::Presenter
    $dataref = &$_strip_non_matches_subref(
        \%objdata, \%fieldlabels, $column, $relation, \@corrected, \%seen);
    return $dataref;
}

sub _reprocessor {
    my ($self, $line_raw, $sdref, $u) = @_;
    my ($line_temp);

    # for readability during development
    my %substr_data = %$sdref;
    
    $line_temp = $line_raw;
    
    # Need to apply the reprocessing right-to-left on the formed line 
    # Hence we need an array where the elements of @$reprocessref are arranged by decreasing
    # order of the insertion point

    foreach (sort {$b <=> $a} keys %substr_data) {
        my $line_temp1 = $line_temp;
        my $field = $substr_data{$_}[0];
        my $subname = 'reprocess_' . $field;
        my $initial_length = $substr_data{$_}[1];
        my $original = substr ($line_temp1, $_, $initial_length);
        my $fixed_length = $substr_data{$_}[2];
        my %this_source = %{$substr_data{$_}[3]};
        my %all_sources = %{$substr_data{$_}[4]};
        no strict 'refs';
        substr($line_temp, $_, $initial_length) = 
            &$subname($initial_length, $original, 
                $fixed_length, \%this_source, \%all_sources, $u);
    }
    return $line_temp;
}

sub reprocess_timeslot {
    my ($initial_length, $original, $fixed_length, $sourceref, $dataref, $u) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    my %data = %$dataref;
    if (exists $sources{$keyword}) {
    my $start_time = ${$sources{$keyword}}[1];
    if (defined $data{$u}[4]) {
        $start_time = refine_start_time(\@{$data{$u}}, $start_time);
    }
        $replacement = ${$sources{$keyword}}[0] . ', ' . $start_time;
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_instructor {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        if (${$sources{$keyword}}[1]) {
          # last name only
#            $replacement = ${$sources{$keyword}}[0];
               # last name, first name
            $replacement = ${$sources{$keyword}}[0] . ', ' . ${$sources{$keyword}}[1];
        } else {
            $replacement = ${$sources{$keyword}}[0];
        }
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_room {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        if (${$sources{$keyword}}[1]) {
            $replacement = ${$sources{$keyword}}[1] . ' ' .         # mall
                           ${$sources{$keyword}}[0];                # room no.
        } else {
            $replacement = ${$sources{$keyword}}[0];
        }
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_discipline {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|([\s\d]\d)\b\s*$|;
    my $temp = $1 if (defined $1);
    $temp =~ s|^\s+||;
    $keyword = $temp;
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        $replacement = ${$sources{$keyword}}[0];
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub reprocess_ward_department {
    my ($initial_length, $original, $fixed_length, $sourceref) = @_;
    my ($keyword, $replacement, $len);
    $original =~ m|(.*)\b\s*$|;
    $keyword = $1 if (defined $1);
    my %sources = %$sourceref;
    if (exists $sources{$keyword}) {
        $replacement = ${$sources{$keyword}}[0];
        $replacement = _length_adjuster($replacement, $fixed_length);
    } else {
        $replacement = _length_adjuster($original, $fixed_length);
    }
    return $replacement;
}

sub _length_adjuster {
    my ($replacement, $fixed_length) = @_;
    my $len = length($replacement);
    if ($len < $fixed_length) {
        $replacement .= ' ' x ($fixed_length - $len);
    } elsif ($len > $fixed_length) {
        $replacement = substr($replacement, 0, $fixed_length);
    }
    return $replacement;
}

sub _reprocessor_delimit {
    my ($self, $tempref, $elref, $u) = @_;
    # for readability during development
    # @temp:  the array whose elements will eventually be joined by a delimiter
    #         and printed to file
    # %element_data:  the information which each field to be reprocessed will 
    #         need
    # $u:     the current groupID
    my @temp = @{$tempref};
    my %element_data = %$elref;
    foreach (keys %element_data) {
        my $field = $element_data{$_}[0];
        my $subname = 'reprocess_delimit_' . $field;
        my %this_source = %{$element_data{$_}[1]};    # dimension being analyzed
        my %all_sources = %{$element_data{$_}[2]};  # the whole data structure
        no strict 'refs';
        $temp[$_] = &$subname($field, \%this_source, \%all_sources, $u);
    }
    return \@temp;
}

sub reprocess_delimit_instructor {
    my ($field, $sourceref, $allsourceref, $u) = @_;
    my ($replacement);
    my %sources = %$sourceref;
    my %data = %$allsourceref;
    my $insID = $data{$u}[6];    # instructor data for the current groupID
    $replacement = $sources{$insID}[0] . ', ' . $sources{$insID}[1];
    return $replacement;
}

sub reprocess_delimit_timeslot {
    my ($field, $sourceref, $allsourceref, $u) = @_;
    my %sources = %$sourceref;
    my %data = %$allsourceref;
    my $tsID = $data{$u}[2];    # timeslot data for the current groupID
    my ($day, $start_time) = @{$sources{$tsID}}[0..1];
    if (defined $data{$u}[4]) {  # if the group is a non-trans-ward group ...
        $start_time = refine_start_time(\@{$data{$u}}, $start_time);
    }
    my $replacement = $day . ', ' . $start_time;
    return $replacement;
}

sub reprocess_delimit_room {
    my ($field, $sourceref, $allsourceref, $u) = @_;
    my %sources = %$sourceref;
    my %data = %$allsourceref;
    my $rmID = $data{$u}[1];    # room data for the current groupID
    my ($room, $mall, $area) = @{$sources{$rmID}}[0..2];
    my $replacement = "$mall $room";
    return $replacement;
}

sub refine_start_time {
	my ($thisgroupref, $start_time) = @_;
	my @thisgroup = @{$thisgroupref};
        if ($thisgroup[4] eq '09') {
            if ($start_time eq '1:30') {
                 $start_time = '2:00';
            } elsif ($start_time eq '2:30') {
                 $start_time = '2:45';
            }
        } elsif ( ($thisgroup[4] eq '10' or $thisgroup[4] eq '11')
             && ($thisgroup[2] eq '12' or $thisgroup[2] eq '32' or $thisgroup[2] eq '52')
                ) {
                      $start_time = '10:45';
        }
	return $start_time;
}

1;

############################## DOCUMENTATION ##############################

=head1 NAME

Data::Presenter::SampleSchedule

=head1 VERSION

This document refers to version 0.62 of Data::Presenter::SampleSchedule, released April 13, 2003.

=head1 SYNOPSIS

Create a Data::Presenter::SampleSchedule object.  The first argument passed to the constructor for this object is a reference to an anonymous hash which has been created outside of Data::Presenter for heuristic purposes only.  For illustrative purposes, this variable is contained in a separate file which is C<require>d into the script.

    use Data::Presenter;
    use Data::Presenter::SampleSchedule;
	our ($ms);
	my $hashfile = 'reprocessible.txt';
	require $hashfile;

Then do the usual preparation for a Data::Presenter::[subclass] object.

    our @fields = ();
    our %parameters = ();
    our $index = '';
    my ($fieldsfile, $count, $outputfile, $title, $separator);
    my @columns_selected = ();
    my $sorted_data = '';
    my @objects = ();
    my ($column, $relation);
    my @choices = ();

    $fieldsfile = 'fields_schedule.data';
    do $fieldsfile;

Finally, create a Data::Presenter::SampleSchedule object, passing the hash reference as the first argument.

    my $dp = Data::Presenter::SampleSchedule->new(
                 $ms, \@fields, \%parameters, $index);

To use sorting, selecting and output methods on a Data::Presenter::SampleSchedule object, please consult the Data::Presenter documentation.

=head1 DESCRIPTION

This package is a subclass of Data::Presenter intended to illustrate how certain Data::Presenter methods provide additional functionality.  These subroutines include:

=over 4

=item *

C<&writeformat_with_reprocessing>

=item *

C<&writeformat_deluxe>

=item *

C<&writedelimited_with_reprocessing>

=item *

C<&writedelimited_deluxe>

=back

To learn how to use Data::Presenter::SampleSchedule, please first consult the Data::Presenter documentation.

=head1 INTERNAL FEATURES

=head2 The Data::Presenter::SampleSchedule Object

Unlike some other Data::Presenter::[package1] subclasses (I<e.g.,> Data::Presenter::Census), the source of the data processed by Data::Presenter::SampleSchedule is not a database report coming from a legacy database system through a filehandle.  Rather, it is a hash of arrays representing the current state of an object at a particular point in a script (suitably modified to carry Data::Presenter metadata).  The hash of arrays used for illustrative purposes in this distribution was generated by the author from a module, Mall::Schedule, which is not part of the Data::Presenter distribution.  Mall::Schedule schedules therapeutic treatment groups into particular rooms and time slots and with particular instructors.  The time slots and instructors are identified in the underlying database by unique IDs, but it is often preferable to have more human-readable strings appear in output rather than these IDs.  The IDs need to be 'reprocessed' into more readable strings.  This is the task solved by Data::Presenter::SampleSchedule.  Since we are not here concerned with the creation of a Mall::Schedule object, all we need is the anonymous hash blessed into that object and the reprocessing methods.

=head2 Data::Presenter::SampleSchedule Internal Subroutines

Like all Data::Presenter::[package1] classes, Data::Presenter::SampleSchedule necessarily contains two subroutines:

=over 4

=item *

C<&_init>:  Initializes the Data::Presenter::SampleSchedule object by processing data contained in the Mall::SampleSchedule object and returning a reference to a hash which is then further processed and blessed by the Data::Presenter constructor.

=item *

C<&_extract_rows>:  Customizes the operation of C<&Data::Presenter::select_rows> to the data found in the C<Data::Presenter::SampleSchedule> object.

=back

Like many Data::Presenter::[package1] classes, Data::Presenter::SampleSchedule offers the possibility of using C<&Data::Presenter::writeformat_with_reprocessing> and C<&Data::Presenter::writeformat_deluxe>.  As such Data::Presenter::SampleSchedule defines the following additional internal subroutines:

=over 4

=item *

C<&_reprocessor>:  Customizes the operation of C<&Data::Presenter::writeformat_with_reprocessing> to the data found in the C<Data::Presenter::SampleSchedule> object.

=item *

C<&reprocess_timeslot>:  Takes a timeslot code (as found in C<@{$ms{'options'}{'sources'}{'timeslot'}>) and substitutes for it a string containing the day of the week and the starting time.

=item *

C<&reprocess_instructor>:  Takes an instructor's unique ID (as found in C<@{$ms{'options'}{'sources'}{'instructor'}}>) and substitutes for it a string containing the instructor's last name and first name.

=item *

C<&reprocess_room>:  Takes a room number (as found in C<@{$ms{'options'}{'sources'}{'room'}}>) and substitutes for it a string containing mall number and the room number.

=item *

C<&reprocess_discipline>:  Takes the code number for a discipline (as found in C<@{$ms{'options'}{'sources'}{'discipline'}}>) and substitutes for it a string containing name of the discipline.

=item *

C<&reprocess_ward_department>:  Takes the code number for a ward or department (as found in C<@{$ms{'options'}{'sources'}{'ward_department'}}>) and substitutes for it a string containing name of the ward or department.

=back

In addition, Data::Presenter::SampleSchedule now offers the possibility of using C<&Data::Presenter::writedelimit_with_reprocessing>.  As such Data::Presenter::SampleSchedule defines the following additional internal subroutines:

=over 4

=item *

C<&_reprocessor_delimit>: Customizes the operation of C<&Data::Presenter::writedelimit_with_reprocessing> to the data found in the C<Data::Presenter::SampleSchedule> object.

=item *

C<&reprocess_delimit_instructor>:  Takes an instructor's unique ID (as found in C<@{$ms{'options'}{'sources'}{'instructor'}}>) and substitutes for it a string containing the instructor's last name and first name.

=item *

C<&reprocess_delimit_timeslot>:  Takes a timeslot code (as found in C<@{$ms{'options'}{'sources'}{'timeslot'}}>) and substitutes for it a string containing the day of the week and the starting time.

=item *

C<&reprocess_delimit_room>:  Takes a room number (as found in C<@{$ms{'options'}{'sources'}{'room'}}>) and substitutes for it a string containing mall number and the room number.

=back

=head1 PREREQUISITES

None.

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

Creation date:  October 18, 2002.  Last modification date:  April 13, 2003.  Copyright (c) 2002-3 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut 


