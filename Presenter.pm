package Data::Presenter;
$VERSION = 0.62;    # 4/13/03
use strict;
use warnings;
use List::Compare;
use Carp;

############################## Package Variables ##############################

our %fp = ();
our %fieldlabels = ();
our %reserved = map {$_ => 1} qw( fields parameters index options );

################################# Constructor #################################

sub new {
    my ($inputs, $class, $source, $fieldsref, $paramsref, 
        $index, $self, $dataref, $datapoints);
    $inputs = scalar(@_);

    if ($inputs == 5) {
        # regular Data::Presenter object immediately validates data
        ($class, $source, $fieldsref, $paramsref, $index) = @_;
        _validate_fields($fieldsref);
        _validate_parameters($fieldsref, $paramsref);
        _validate_index($fieldsref, $index);
    } elsif ($inputs == 2) {
        # Data::Presenter::Combo object:  data already validated
        ($class, $source) = @_;
    } else {
        my ($package) = caller;
        die 'Wrong number of inputs to ', $package, '::new', "$!";
    }

    # bless a ref to an empty hash into the invoking class
    # which is somewhere below this one in the hierarchy
    $self = bless {}, ref($class) || $class;

    # prepare the database by using &_init from package somewhere below 
    # this one
    if ($inputs == 5) {
        $dataref = $self->_init($source, $fieldsref, $paramsref, 
            $index, \%reserved);
    } else {
        $dataref = $self->_init($source);
    }

    # carp if, other than reserved words, the object has 0 elements
    foreach (keys %$dataref) {
        $datapoints++ unless $reserved{$_};
    }
    carp "The object you have initialized, $class,\n  contains 0 data elements; do you wish to continue?"
        unless ($datapoints);

    # prepare 2 hashes which will be needed in selecting rows and 
    # sorting columns
    _make_labels_params(
        \@{${$dataref}{'fields'}}, \@{${$dataref}{'parameters'}});

    # initialize the object from the prepared values (Damian, p. 98)
    %$self = %$dataref;
    return $self;
}

################################################################################
##### Subroutines called from with &new (constructor)
################################################################################

sub _validate_fields {
    my $fieldsref = shift;
    my %seen = ();
    foreach my $c (@$fieldsref) {
        if ($seen{$c}) {
            die "$c is a duplicated field in \@fields:  $!";
        } else {
            $seen{$c}= 1;
        }
    }    # Confirmed:  there exist no duplicated fields in @fields.
}

sub _validate_parameters {
    my ($fieldsref, $paramsref) = @_;
    my @fields = @$fieldsref;
    my %parameters = %$paramsref;
    my ($i, $badvalues);
    for ($i = 0; $i < scalar(@fields); $i++) {
        my @temp = @{$parameters{$fields[$i]}};
        $badvalues .= '    ' . $fields[$i] . "\n"
            if ($temp[0] !~ /^\d+$/    # 1st element must be numeric
                ||
                $temp[1] !~ /^[U|D]$/i  # 2nd element must be U or D (lc or uc)
                ||
                $temp[2] !~ /^[a|n|s]$/i    # 3rd element must be a, n or s
            );
    }
    die "Need corrected values for these keys:\n$badvalues:$!" if ($badvalues);
}

sub _validate_index {
    my ($fieldsref, $index) = @_;
    my @fields = @$fieldsref;
    die "\$index must be a numeral:  $!"
        unless ($index =~ /^\d+$/);
    die "\$index must be < number of elements in \@fields:  $!"
        unless ($index >= 0 && $index <= $#fields);
}

sub _make_labels_params {
     my ($fieldsref, $paramsref) = @_;
     my @fields = @$fieldsref;
     my @aryparams = @$paramsref;
     %fp = ();
     my %temp = ();
     for (my $i = 0; $i < scalar(@fields); $i++) {
         $fp{$fields[$i]} = [@{$aryparams[$i]}];
         $temp{$fields[$i]} = $i;
     }
     %fieldlabels = %temp;
}

################################################################################
##### Subroutines to get information on the Data::Presenter object
################################################################################

sub get_data_count {
    my $self = shift;
    _count_engine($self);
}

sub print_data_count {
    my $self = shift;
    print 'Current data count:  ', _count_engine($self), "\n";
}

sub _count_engine {
    my $self = shift;
    my %data = %$self;
    my ($count);
    foreach (keys %data) {
        $count++ unless ($reserved{$_});
    }
    $count ? $count : 0;
}

sub get_keys {
    my $self = shift;
    my %data = %$self;
    my @keys = ();
    foreach (keys %data) {
        push(@keys, $_) unless ($reserved{$_});
    }
    return [ sort @keys ];
}

################################################################################
##### &sort_by_column:  called from package main to select particular fields 
#####                   to be displayed in output 
##### Subroutines called from within &sort_by_column
################################################################################

sub sort_by_column {
    my ($self, $argsref) = @_;
    my %data = %$self;
    my @fields = @{$data{'fields'}};
    my $index = ${$data{'index'}}[0];
    my $sort_formula_ref = '';
    my @refs_to_sorted_fields = ();
    _validate_args($argsref, \%fp);
    $sort_formula_ref = _build_sort_formula($argsref, \@fields, $index);
    @refs_to_sorted_fields = 
        sort $sort_formula_ref (_key_constructor($self, $argsref));
    my %_sorted_fields = ();
    unlink ("dupes.txt") 
        if ("dupes.txt") || warn "having trouble deleting dupes.txt: $!";
    foreach my $p (@refs_to_sorted_fields) {
        my $q = join('!', @$p);
        $q =~ /^(.*)!(.*)$/;
        my $sorted_key = $1;
        my $unique_key = $2;
        if (exists $_sorted_fields{$sorted_key}) {
            warn "Some records have identical entries in the fields selected for output.\nPossible
duplicated entry; examine record $unique_key.\nConsider appending a field whose value is
unique to each record to the \nlist of arguments requested.\nError was";
            open(DUPES, ">>dupes.txt") 
                || die "Cannot open dupes.txt for appending:  $!";
            $sorted_key =~ /^(.*?)!/;
            my $start_sorted_key = $1;
            print DUPES "Duplicated record:  $unique_key\t\t",
                "First requested argument:  $start_sorted_key\n";
            close(DUPES) || die "Cannot close dupes.txt:  $!";
        } else {
            $_sorted_fields{$sorted_key} = $unique_key;
        }
    }
    return \%_sorted_fields;
}

sub _validate_args {
    my ($argsref, $fpref) = @_;
    my %seen = ();
    my ($c);
    foreach $c (@$argsref) {
        foreach my $d (keys %$fpref) {
            if ($c eq $d) {
                $seen{$c} = 1;
                last;
            }
        }
    }
    foreach $c (@$argsref) {
        print "Field '${c}' is not available as an argument to be passed to ", '&sort_by_column', "\n"
            unless (exists $seen{$c});
    }
    die "Invalid argument(s) to sub sort_by_column:  $!"
        unless (scalar(@$argsref) == scalar(keys %seen));
}

sub _build_sort_formula {
    my ($argsref, $fieldsref, $index) = @_;
    my @args = @$argsref;    # for convenience
    my @fields = @$fieldsref;    # for convenience
    my $formularef = sub {    # relies upon:  @args    %fp
        my $sorting_formula = '';
        my $m = 0;
        my @formula_components = ();
        foreach my $i (@args) {
            my $part_formula = _formula_engine($i, $m);
            push(@formula_components, $part_formula);
            $m++;
        }
        foreach (@formula_components) {
            $sorting_formula .= $_ . ' || ';
        }
        # now add on the sorting rule for the index: 
        # always numerical, ascending
        my $index_formula = _formula_engine($fields[$index], $m);
        $sorting_formula .= $sorting_formula . $index_formula;
        1;      # sort subroutine below needs to return a numeric value
    }; # end of anonymous sub
    return $formularef;
}

sub _formula_engine {
    my ($lh, $mid, $rh, $part_formula);
    my ($i, $m) = @_;
    if ($fp{$i}->[2] eq 'a' or $fp{$i}->[2] eq 's') {
        # a: alphabetical; s: ASCII-betical
        $mid = 'cmp';
    } elsif ($fp{$i}->[2] eq 'n')  {
        # n: numerical
        $mid = '<=>';
    } else {
        warn "Bad value for comparison operator:  $!";
    }
    if ($fp{$i}->[2] eq 'a') {
        # a: alphabetical (case-insensitive)
        if ($fp{$i}->[1] eq 'U') {
            # U: ascending sort
            $lh = 'lc($a->[' . $m . '])';
            $rh = 'lc($b->[' . $m . '])';
        } elsif ($fp{$i}->[1] eq 'D') {
            # D: descending sort
            $lh = 'lc($b->[' . $m . '])';
            $rh = 'lc($a->[' . $m . '])';
        } else {
            warn "Bad value for order of sort:  $!";
        }
    } elsif ($fp{$i}->[2] eq 'n' or $fp{$i}->[2] eq 's')  {
        # n or s:  numerical or ASCII-betical (case-sensitive)
        if ($fp{$i}->[1] eq 'U') {
            $lh = '$a->[' . $m . ']';
            $rh = '$b->[' . $m . ']';
        } elsif ($fp{$i}->[1] eq 'D'){
            $lh = '$b->[' . $m . ']';
            $rh = '$a->[' . $m . ']';
        } else {
            warn "Bad value for order of sort:  $!";
        }
    } else {
        warn "Bad value for type of sort:  $!";
    }
    $part_formula = $lh . ' ' . $mid . ' ' . $rh;
    return $part_formula;
}

sub _key_constructor {
    my ($self, $argsref) = @_;
    my @args = @$argsref;    # for convenience
    my @keys = ();
    foreach my $k (keys %$self) {
        unless ($reserved{$k}) {
            my @temp = ();
            foreach my $i (@args) {
                push @temp, ${%$self}{$k}->[$fieldlabels{$i}];
            }
            push @temp, $k;
            push(@keys, \@temp);
        }
    }
    return @keys;
}

################################################################################
##### &select_rows:  called from package main to select a particular range of 
#####                entries from data source 
##### Subroutines called within &select_rows
################################################################################

sub select_rows {
    my ($self, $column, $relation, $choicesref) = @_;
    my $dataref = '';
    $dataref = $self->_extract_rows(
        $column, $relation, $choicesref, \%fp, \%fieldlabels,
            \&_analyze_relation, \&_strip_non_matches);
    %$self = %$dataref;
    return $self;
}

sub _analyze_relation {    # Analysis of $relation:  passed by ref to subclass
    my ($relation, $sorttype) = @_;
    my %eq = map {$_ => 1} (
        'eq',
        'equals',
        'is',
        'is equal to',
        'is a member of',
        'is part of',
        '=',
        '==',
    );
    my %ne = map {$_ => 1} (
        'ne',
        'is not',
        'is not equal to',
        'is not a member of',
        'is not part of',
        'is less than or greater than',
        'is less than or more than',
        'is greater than or less than',
        'is more than or less than',
        'does not equal',
        'not',
        'not equal to  ',
        'not equals',
        '!=',
        '! =',
        '!==',
        '! ==',
        '<>',
    );
    my %lt = map {$_ => 1} (
        '<',
        'lt',
        'is less than',
        'is fewer than',
        'before',
    );
    my %gt = map {$_ => 1} (
        '>',
        'gt',
        'is more than',
        'is greater than',
        'after',
    );
    my %le = map {$_ => 1} (
        '<=',
        'le',
        'is less than or equal to',
        'is fewer than or equal to',
        'on or before',
        'before or on',
    );
    my %ge = map {$_ => 1} (
        '>=',
        'ge',
        'is more than or equal to',
        'is greater than or equal to',
        'on or after',
        'after or on',
    );
    my %gt_lt_ops = map {$_ => 1} (
        '<',
        'lt',
        '>',
        'gt',
        '<=',
        'le',
        '>=',
        'ge',
    );
    die "Relation \'$relation\' has not yet been added to\nData::Presenter's internal specifications. $!"
        unless ($eq{$relation} ||
                $ne{$relation} ||
                $lt{$relation} ||
                $gt{$relation} ||
                $le{$relation} ||
                $ge{$relation}   );
    if ($eq{$relation}) {
        if ($sorttype eq 'a' || $sorttype eq 's') {
            $relation = 'eq';
        } elsif ($sorttype eq 'n') {
            $relation = '==';
        } else {
            die "Problem with specification of sort type:  $!";
        }
    } elsif ($ne{$relation}) {
        if ($sorttype eq 'a' || $sorttype eq 's') {
            $relation = 'ne';
        } elsif ($sorttype eq 'n') {
            $relation = '!=';
        } else {
            die "Problem with specification of sort type:  $!";
        }
    } elsif ($lt{$relation}) {
        if ($sorttype eq 'a' || $sorttype eq 's') {
            $relation = 'lt';
        } elsif ($sorttype eq 'n') {
            $relation = '<';
        } else {
            die "Problem with specification of sort type:  $!";
        }
    } elsif ($gt{$relation}) {
        if ($sorttype eq 'a' || $sorttype eq 's') {
            $relation = 'gt';
        } elsif ($sorttype eq 'n') {
            $relation = '>';
        } else {
            die "Problem with specification of sort type:  $!";
        }
    } elsif ($le{$relation}) {
        if ($sorttype eq 'a' || $sorttype eq 's') {
            $relation = 'le';
        } elsif ($sorttype eq 'n') {
            $relation = '<=';
        } else {
            die "Problem with specification of sort type:  $!";
        }
    } elsif ($ge{$relation}) {
        if ($sorttype eq 'a' || $sorttype eq 's') {
            $relation = 'ge';
        } elsif ($sorttype eq 'n') {
            $relation = '>=';
        } else {
            die "Problem with specification of sort type:  $!";
        }
    } else {
        die "I can not handle this yet:  $!";
    }
    return ($relation, \%gt_lt_ops);
}

sub _strip_non_matches {
    my ($dataref, $flref, $column, $relation, $correctedref, $seenref) = @_;
    my %data = %$dataref;
    my %fieldlabels = %$flref;
    my @corrected = @$correctedref;
    my %seen = %$seenref;
    foreach (sort keys %data) {
        unless ($reserved{$_}) {
            my $item = $data{$_}[$fieldlabels{$column}];
            if ($relation eq 'eq' || $relation eq '==') {
                unless (exists $seen{$item}) {
                    delete $data{$_};
                }
            } elsif ($relation eq 'ne' || $relation eq '!=') {
                unless (! exists $seen{$item}) {
                    print "$item is not a valid index\n";
                    delete $data{$_};
                }
            } elsif ($relation eq 'lt') {
                unless ($item lt $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq '<') {
                unless ($item < $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq 'gt') {
                unless ($item gt $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq '>') {
                unless ($item > $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq 'le') {
                unless ($item le $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq '<=') {
                unless ($item <= $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq 'ge') {
                unless ($item ge $corrected[0]) {
                    delete $data{$_};
                }
            } elsif ($relation eq '>=') {
                unless ($item >= $corrected[0]) {
                    delete $data{$_};
                }
            } else {
                die "I cannot handle this yet:  $!";
            }
        }
    }
    return \%data;
}

################################################################################
##### Methods for simple output 
##### and subroutines called within those methods
################################################################################

sub print_to_screen {
    my $class = shift;
    my %data = %$class;
    _print_engine(\%data, \%reserved);
    return 1;
}

sub print_to_file {
    my ($class, $outputfile) = @_;
    my %data = %$class;
    my $oldfh = select OUT;
    open(OUT, ">$outputfile") 
        || die "Cannot open $outputfile for writing:  $!";
    _print_engine(\%data, \%reserved);
    close(OUT) || die "Cannot close $outputfile:  $!";
    select($oldfh);
    return 1;
}

sub _print_engine {
    my ($dataref, $reservedref) = @_;
    my %data = %$dataref;
    my %reserved = %$reservedref;
    foreach my $i (sort keys %data) {
        unless ($reserved{$i}) {
            print $_, ';' foreach (@{$data{$i}});
            print "\n";
        }
    }
}

sub print_with_delimiter {
    my ($class, $outputfile, $delimiter) = @_;
    my %data = %$class;
    open(OUT, ">$outputfile") 
        || die "Cannot open $outputfile for writing:  $!";
    foreach my $i (sort keys %data) {
        unless ($reserved{$i}) {
            my @fields = @{$data{$i}};
            for (my $j=0; $j < scalar(@fields); $j++) {
                if ($j < scalar(@fields) - 1) {
                    if ($fields[$j]) {
                        print OUT $fields[$j], "$delimiter";
                    } else {
                        print OUT "$delimiter";
                    }
                } else {
                    print OUT $fields[$j] if ($fields[$j]);
                }
            }
            print OUT "\n";
        }
    }
    close(OUT) || die "Cannot close $outputfile:  $!";
    return 1;
}

sub full_report {
    my ($class, $outputfile);
    my %data = ();
    my @fields = ();
    ($class, $outputfile) = @_;
    %data = %$class;
    @fields = @{$data{'fields'}};
    open(OUT, ">$outputfile") 
        || die "Cannot open $outputfile for writing:  $!";
    foreach my $i (sort keys %data) {
        unless ($reserved{$i}) {
            print OUT "$i\n";
            for (my $j=0; $j <= $#fields; $j++) {
                print OUT "    $fields[$j]", ' ' x (24 - length($fields[$j]));
                if (defined $data{$i}[$j]) {
                    print OUT "$data{$i}[$j]\n";
                } else {
                    print OUT "\n";
                }
            }
            print OUT "\n";
        }
    }
    close(OUT) || die "Cannot close $outputfile:  $!";
    return 1;
}

################################################################################
##### Methods which output data like Perl formats
##### and subroutines called from within those methods
################################################################################

sub writeformat {
    my ($self, $sorted_data, $argsref, $outputfile) = @_;
    my %data = %$self;
    my %sorted_data = %$sorted_data;
    my $picline = _format_picture_line($argsref);
    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    foreach my $k (sort keys %sorted_data) {
        my $u = $sorted_data{$k};
        my @list = ();
        $^A = '';
        foreach my $j (@$argsref) {
            push(@list, $data{$u}->[$fieldlabels{$j}]);
        }
        formline($picline, @list);
        print REPORT $^A, "\n";
    }
    $^A = '';
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub writeformat_plus_header {
    my ($self, $sorted_data, $argsref, $outputfile, $title_raw) = @_;
    my %data = %$self;
    my %sorted_data = %$sorted_data;
    my $title = _format_title($title_raw);
    my $argument_line_top_ref = _format_argument_line_top2($argsref);
    my $hyphen_line = _format_hyphen_line2($argsref);
    my $picline = _format_picture_line($argsref);
    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    print REPORT $title, "\n\n";
    print REPORT "$_\n" foreach (@{$argument_line_top_ref});
    print REPORT $hyphen_line, "\n";
    foreach my $k (sort keys %sorted_data) {
        my $u = $sorted_data{$k};
        my @list = ();
        $^A = '';
        foreach my $j (@$argsref) {
            push(@list, $data{$u}->[$fieldlabels{$j}]);
        }
        formline($picline, @list);
        print REPORT $^A, "\n";
    }
    $^A = '';
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub writeformat_with_reprocessing {
    my ($self, $sorted_data, $argsref, $outputfile, $reprocessref) = @_;
    my %data = %$self;
    my %sorted_data = %$sorted_data;

    my ($substr_data_ref, $picline) = _prepare_to_reprocess(
        $reprocessref, \%fp, \%data, $argsref);

    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    foreach my $k (sort keys %sorted_data) {
        my $u = $sorted_data{$k};
        my @list = ();
        $^A = '';
        foreach my $j (@{$argsref}) {
            push(@list, $data{$u}->[$fieldlabels{$j}]);
        }
        formline($picline, @list);
        my $line = $self->_reprocessor(
            $^A,            # the formed line
            $substr_data_ref,  # the points at which I have to splice out
                               # text from the formed line and amount thereof
            $u,             # the current groupID
            );
        print REPORT $line, "\n";
    }
    $^A = '';
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub writeformat_deluxe {
    my ($self, $sorted_data, $argsref, $outputfile, $title_raw, $reprocessref) 
        = @_;
    my %data = %$self;
    my %sorted_data = %$sorted_data;

    my ($substr_data_ref, $picline) = _prepare_to_reprocess(
        $reprocessref, \%fp, \%data, $argsref);

    my (@header, @accumulator);
    my $title = _format_title($title_raw);
    my $argument_line_top_ref = 
        _format_argument_line_top2($argsref, $reprocessref);
    my $hyphen_line = _format_hyphen_line2($argsref, $reprocessref);
    @header = ($title, '', @{$argument_line_top_ref}, $hyphen_line);

    foreach my $k (sort keys %sorted_data) {
        my $u = $sorted_data{$k};
        my @list = ();
        $^A = '';
        foreach my $j (@{$argsref}) {
            push(@list, $data{$u}->[$fieldlabels{$j}]);
        }
        formline($picline, @list);
        my $line = $self->_reprocessor(
            $^A,            # the formed line
            $substr_data_ref,  # the points at which I have to splice out
                               # text from the formed line and amount thereof
            $u,             # the current groupID
            );
        push @accumulator, $line;
    }
    $^A = '';
    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    print REPORT $_, "\n" foreach (@header, @accumulator);
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub _prepare_to_reprocess {
    my ($reprocessref, $fpref, $dataref, $argsref) = @_;
    my %reprocessing_info = %{$reprocessref};
    my %fp = %{$fpref};
    my %data = %{$dataref};
    my @args = @{$argsref};

    # We must validate the info passed in thru $reprocessref.  
    # This is a multi-stage process.
    # 1:  Verify that the fields requested for reprocessing exist as 
    #     fields in the configuration file.
    my @fields_for_reprocessing = sort keys %reprocessing_info;
    _validate_args(\@fields_for_reprocessing, \%fp);


    # 2:  Verify that there exists a subroutine named &reprocess_[field] 
    #     whose name has been stored as a key in defined in 
    #     %{$data{'options'}{'subs'}}.
    my @confirmed_subs = 
        grep {s/^reprocess_(.*)/$1/} keys %{$data{'options'}{'subs'}};
    my $lc = List::Compare->new(
        \@fields_for_reprocessing, \@confirmed_subs);
    my $LR = $lc->is_LsubsetR;
    die "You are trying to reprocess fields for which no reprocessing subroutines yet exist: $!"
        unless ($lc->is_LsubsetR);

    # 3:  Verify that we can tap into the data sources referenced in
    #     %{$data{'options'}{'sources'}} for each field needing reprocessing
    my @available_sources = sort keys %{$data{'options'}{'sources'}};
    my $lc1 = List::Compare->new(
        \@fields_for_reprocessing, \@available_sources);
    $LR = $lc1->is_LsubsetR;
    die "You are trying to reprocess fields for which no original data sources are available: $!"
        unless ($lc1->is_LsubsetR);

    # 4:  Verify that the file mentioned in the values-arrays of 
    #     %reprocessing_info exists, and that appropriate digits are entered 
    #     for the fixed-length of the replacement string.
    foreach (sort keys %reprocessing_info) {
        die "Fixed length of replacement string is misspecified;\n  Must be all digits:  $!"
            unless $reprocessing_info{$_} =~ /^\d+$/;
    }

    my %args_indices = ();
    for (my $h=0; $h<=$#args; $h++) {
        $args_indices{$args[$h]} = $h;
    }

    my %substr_data = ();
    foreach (sort keys %reprocessing_info) {
        # 1st:  Determine the position in the formed string where the 
        #       old field began, as well as its length
        # Given that I used a single whitespace to separate fields in 
        # the formed line, the starting position is the sum of the number of 
        # fields preceding the target field in the formed line 
        # PLUS the combined length of those fields
        my ($comb_length, $start);

        if ($args_indices{$_} == 0) {
            $start = $args_indices{$_};
        } else {
            for (my $j=0; $j<$args_indices{$_}; $j++) {
                $comb_length += $fp{$args[$j]}[0];
            }
            $start = $args_indices{$_} + $comb_length;
        }
        $substr_data{$start} = [
            $_,
            $fp{$_}[0],
            $reprocessing_info{$_},
            \%{ $data{'options'}{'sources'}{$_} },
            $dataref,    # new in v0.51
        ];
    }
    my $picline = _format_picture_line(\@args);
    return (\%substr_data, $picline);
}

################################################################################
##### Methods which output data with delimiters between fields
##### and subroutines called within those methods
################################################################################

sub writedelimited {
    my ($self, $sorted_data, $outputfile, $delimiter) = @_;
    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    print REPORT join("$delimiter", split(/!/, $_) ), "\n"
        foreach (sort keys %{$sorted_data});
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub writedelimited_plus_header {
    my ($self, $sorted_data, $argsref, $outputfile, $delimiter) = @_;
    my %data = %$self;
    my $header = _format_argument_line_top3($argsref, $delimiter);
    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    print REPORT "$header\n";
    print REPORT join("$delimiter", split(/!/, $_) ), "\n"
        foreach (sort keys %{$sorted_data});
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub writedelimited_with_reprocessing {
    my ($self, $sorted_data, $argsref, $outputfile, $reprocessref, $delimiter) 
        = @_;
    my %data = %$self;
    my %sorted_data = %$sorted_data;

    my $element_data_ref = _prepare_to_reprocess_delimit(
        $reprocessref, \%fp, \%data, $argsref);

    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    foreach my $k (sort keys %sorted_data) {
        my $u = $sorted_data{$k};
        my $tempref = [ split(/!/, $k) ];
        # do reprocessing for delimiter
        $tempref = $self->_reprocessor_delimit(
            $tempref,
            $element_data_ref,
            $u,
        );
        my $line = join("$delimiter", @{$tempref});
        print REPORT $line, "\n";
    }
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub writedelimited_deluxe {
    my ($self, $sorted_data, $argsref, $outputfile, $reprocessref, $delimiter) 
        = @_;
    my %data = %$self;
    my %sorted_data = %$sorted_data;

    my $element_data_ref = _prepare_to_reprocess_delimit(
        $reprocessref, \%fp, \%data, $argsref);

    my $header = _format_argument_line_top3($argsref, $delimiter);
    open(REPORT, ">$outputfile") || die "cannot create $outputfile: $!";
    print REPORT "$header\n";
    foreach my $k (sort keys %sorted_data) {
        my $u = $sorted_data{$k};
        my $tempref = [ split(/!/, $k) ];
        # do reprocessing for delimiter
        $tempref = $self->_reprocessor_delimit(
            $tempref,
            $element_data_ref,
            $u,
        );
        my $line = join("$delimiter", @{$tempref});
        print REPORT $line, "\n";
    }
    close(REPORT) || die "can't close $outputfile:$!";
    return 1;
}

sub _prepare_to_reprocess_delimit {
    my ($reprocessref, $fpref, $dataref, $argsref) = @_;
    my @reprocessing_info = @{$reprocessref};
    my %fp = %{$fpref};
    my %data = %{$dataref};
    my @args = @{$argsref};

    # We must validate the info passed in thru $reprocessref.  
    # This is a multi-stage process.
    # 1:  Verify that the fields requested for reprocessing exist as 
    #     fields in the configuration file.
    _validate_args(\@reprocessing_info, \%fp);

    # 2:  Verify that there exists a subroutine named &reprocess_[field] 
    #     whose name has been stored as a key in defined in 
    #     %{$data{'options'}{'subs'}}.
    my @confirmed_subs = 
        grep {s/^reprocess_delimit_(.*)/$1/} keys %{$data{'options'}{'subs'}};
    my $lc = List::Compare->new(\@reprocessing_info, \@confirmed_subs);
    die "You are trying to reprocess fields for which no reprocessing subroutines yet exist: $!"
        unless ($lc->is_LsubsetR);

    # 3:  Verify that we can tap into the data sources referenced in
    my @available_sources = sort keys %{$data{'options'}{'sources'}};
    my $lc1 = List::Compare->new(\@reprocessing_info, \@available_sources);
    die "You are trying to reprocess fields for which no original data sources are available: $!"
        unless ($lc1->is_LsubsetR);

    my %args_indices = ();
    for (my $h=0; $h<=$#args; $h++) {
        $args_indices{$args[$h]} = $h;
    }

    my %element_data = ();
    foreach (@reprocessing_info) {
        $element_data{$args_indices{$_}} = [
            $_,                                    # field being reprocessed
            \%{ $data{'options'}{'sources'}{$_} }, # data for that field
            $dataref,                              # overall data structure
        ];
    }
    return \%element_data;
}

sub _format_title {
    my $title_raw = shift;
    my $title = $title_raw;
    return $title;
}

sub _format_argument_line_top2 {
    my $argsref = shift;
    my $reprocessref = shift if $_[0];
    my @args = @$argsref;
    my @lines = ();
    my $j = '';    # index of the arg requested for printout currently 
                   # being processed
    for ($j = 0; $j < scalar(@args); $j++) {
        my $n = 0; # current line being assigned to, starting with 0
        my $label = $fp{$args[$j]}[3];    # easier to read
        my $max = defined ${$reprocessref}{$args[$j]}
                ? ${$reprocessref}{$args[$j]}
                : $fp{$args[$j]}[0];
        my $remain = $label;    # at the outset, the entire label
                                # remains to be allocated to the proper line
        my @overage = ();
        # first see if any words in $remain need to be truncated
        my @remainwords = split(/\s/, $remain);
        foreach my $word (@remainwords) {
            $word = substr($word, 0, $max) if (length($word) > $max);
        }
        $remain = join ' ', @remainwords;
        while ($remain) {
            if (length($remain) <= $max) {
                # entire remainder of label will be placed on current line
                $lines[$n][$j] = $remain . ' ' x ($max - length($remain));
                $remain = '';
            } else {
                # entire remainder of label cannot fit on current line
                my $word = '';
                my @labelwords = split(/\s/, $remain);
                until (length($remain) <= $max) {
                    $word = shift(@labelwords);
                    push (@overage, $word);
                    $remain = join ' ', @labelwords;
                }
                $lines[$n][$j] = $remain . ' ' x ($max - length($remain));
                $remain = join ' ', @overage ;
                @overage = ();
                $n++;
            }
        }
    }
    my (@column_heads);
    foreach my $p (reverse @lines) {
        for ($j = 0; $j < scalar(@args); $j++) {
            my $max = defined ${$reprocessref}{$args[$j]}
                    ? ${$reprocessref}{$args[$j]}
                    : $fp{$args[$j]}[0];
            if (! ${@$p}[$j]) {
                ${@$p}[$j] = ' ' x $max;
            }
        }
        my $part = join ' ', @$p;
        push @column_heads, $part;
    }
    return \@column_heads;
}

sub _format_argument_line_top3 {
    my ($argsref, $delimiter) = @_;
    my (@temp);
    push(@temp, $fp{$_}[3]) foreach (@{$argsref});
    my $header = join("$delimiter", @temp);
    return $header;
}

sub _format_hyphen_line2 {
    my $argsref = shift;
    my $reprocessref = shift if $_[0];
    my $hyphen_line_length = 0;
    my $hyphen_line = '';
    foreach my $h (@$argsref) {
        $hyphen_line_length += defined ${$reprocessref}{$h}
                             ? (${$reprocessref}{$h} + 1)
                             : ($fp{$h}->[0] + 1);
    }
    $hyphen_line = '-' x ($hyphen_line_length - 1);
    return $hyphen_line;
}

sub _format_picture_line {
    my $argsref = shift;
    my $line = '';
    my $g = 0;      # counter
    foreach my $h (@$argsref) {
        my $picture = '';
        if ($fp{$h}[2] eq 'n' || $fp{$h}[2] eq 'N') {
            $picture = '@' . '>' x ($fp{$h}[0] - 1);
        } else {
            $picture = '@' . '<' x ($fp{$h}[0] - 1);
        }
        if ($g < $#{$argsref}) {
            $line .= $picture . ' ';
            $g++;
        } else {
            $line .= $picture;
        }
    }
    return $line;
}

################################################################################
##### Subroutines involved in writing HTML
################################################################################

sub writeHTML {
    my ($self, $sorted_data, $argsref, $outputfile, $title) = @_;
    my @args = @$argsref;    # for convenience
    my %max = ();    # keys will be indices of @args;
                    # values will be max space allocated from %parameters
    for (my $j = 0; $j < scalar(@args); $j++) {
        $max{$j} = $fp{$args[$j]}[0];
    }
    die "Name of output file must end in .html or .htm  $!"
        unless ($outputfile =~ /\.html?$/);
    open(HTML, ">$outputfile") 
        || die "cannot open $outputfile for writing: $!";
    print HTML <<END_OF_HTML1;
<HTML>
    <HEAD>
    <TITLE>$title</TITLE>
    </HEAD>
    <BODY BGCOLOR="FFFFFF">
        <TABLE border=0  cellpadding=0 cellspacing=0 width=100%>
            <TR>
                <TD valign=middle width="100%"
                bgcolor="#cc0066"> <font face="sans-serif" size="+1"
                color="#ff99cc">&nbsp;&nbsp;&nbsp;$title</font>
                </TD>
            </TR>
        </TABLE>
END_OF_HTML1
        my $argument_line_top_ref = _format_argument_line_top2($argsref);
        my $hyphen_line = _format_hyphen_line2($argsref);
        print HTML '            <PRE>', "\n";
        print HTML $_, '<BK>', "\n" foreach (@{$argument_line_top_ref});
        print HTML "$hyphen_line",  '<BK>', "\n";
        foreach my $row (sort keys %$sorted_data) {
            my @values = split(/!/, $row);
            my @paddedvalues = ();
            for (my $j = 0; $j < scalar(@args); $j++) {
                $values[$j] = '' if (! defined $values[$j]);
                my $newvalue = '';
                if ($fp{$args[$j]}[2] eq 'n' || $fp{$args[$j]}[2] eq 'N') {
                    $newvalue = 
                        (' ' x ($max{$j} - length($values[$j]))) . 
                         $values[$j] . ' ';
                } else { #
                    $newvalue = 
                        $values[$j] . 
                        (' ' x ($max{$j} - length($values[$j]) + 1));
                }
                push(@paddedvalues, $newvalue);
            }
            chop $paddedvalues[(scalar(@args)) - 1];
            print HTML @paddedvalues, '<BK>', "\n";
        }
        print HTML '            </PRE>', "\n";
        print HTML <<END_OF_HTML2;
    </BODY>
</HTML>
END_OF_HTML2
    close(HTML) || die "cannot close $outputfile: $!";
    return 1;
}

1;

################################################################################
##### DOCUMENTATION
################################################################################

=head1 NAME

Data::Presenter

=head1 VERSION

This document refers to version 0.62 of Data::Presenter, which consists of Data::Presenter.pm and various packages subclassed thereunder, most notably Data::Presenter::Combo.pm and its subclasses Data::Presenter::Combo::Intersect.pm and Data::Presenter::Combo::Union.pm.  This version was released April 13, 2003.

=head1 SYNOPSIS

=over 4

=item *

Create a Data::Presenter::[Package1] object (where [Package1] is a Data::Presenter subclass):

    use Data::Presenter;
    use Data::Presenter::[Package1];
    our @fields = ();
    our %parameters = ();
    our $index = '';
    my ($sourcefile, $fieldsfile, $outputfile, $sorted_data, $delimiter);
    my @columns_selected = ();

    $sourcefile = 'in01.txt';
    $fieldsfile = 'fields01.data';
    do $fieldsfile;
    my $dp1 = Data::Presenter::[Package1]->new(
    $sourcefile, \@fields,\%parameters, $index);

=item *

Get information about the Data::Presenter::[Package1] object itself.

    my $data_count = $dp1->get_data_count();

    $dp1->print_data_count();

    my $keysref = $dp1->get_keys();

=item *

Call simple output methods on Data::Presenter::[Package1] object:

    $dp1->print_to_screen();

    $outputfile = 'out01.txt';
    $dp1->print_to_file($outputfile);

    $outputfile = 'delimited01.txt';
    $delimiter = '|||';
    $dp1->print_with_delimiter($outputfile, $delimiter);

    $outputfile = 'report01.txt';
    $dp1->full_report($outputfile);

=item *

Extract selected entries (rows) from Data::Presenter::[Package1] object:

    my ($column, $relation);
    my @choices = ();

    $column = 'datebirth';
    $relation = 'before';
    @choices = ('01/01/1970');
    $dp1->select_rows($column, $relation, \@choices);

    $column = 'lastname';
    $relation = 'is';
    @choices = ('Smith', 'Jones');
    $dp1->select_rows($column, $relation, \@choices);

=item *

Select particular fields (columns) from a Data::Presenter::[Package1] object and establish the order in which they will be sorted:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

=item *

Print data to a plain-text file with fields aligned with whitespace in a manner similar to Perl formats:

    my (%reprocessing_info, @reprocessing_info);

    $outputfile = 'format01.txt';
    $dp1->writeformat($sorted_data, \@columns_selected, $outputfile);

    $outputfile = 'format02.txt';
    $title = 'Agency Census Report';
    $dp1->writeformat_plus_header(
        $sorted_data, \@columns_selected, $outputfile, $title);

    $outputfile = 'format03.txt';
    %reprocessing_info = ( 'lastname'   => 17,
                           'firstname'  => 15,
                         );
    $dp1->writeformat_with_reprocessing(
        $sorted_data, \@columns_selected, $outputfile, \%reprocessing_info);

    $outputfile = 'format_04.txt';
    $title = 'Therapy Groups:  February 3-7, 10-14, 2003';
    %reprocessing_info = (
        'timeslot'   => 17,
        'instructor' => 15,
    );
    $dp1->writeformat_deluxe(
        $sorted_data, \@columns_selected, $outputfile, $title, \%reprocessing_info);

=item *

Print data to a plain-text file with fields aligned with delimiter characters suitable for further processing within a word processing program:

    $outputfile = 'format001.txt';
    $delimiter = "\t";
    $dp1->writedelimited($sorted_data, $outputfile, $delimiter);

    $outputfile = 'format002.txt';
    $delimiter = "\t";
    $dp1->writedelimited_plus_header(
        $sorted_data, \@columns_selected, $outputfile, $delimiter);

    $outputfile = 'format003.txt';
    $delimiter = "\t";
    @reprocessing_info = qw( instructor timeslot room );
    $dp1->writedelimited_with_reprocessing(
        $sorted_data, \@columns_selected, $outputfile, 
        \@reprocessing_info, $delimiter);

    $outputfile = 'format004.txt';
    $delimiter = "\t";
    @reprocessing_info = qw( instructor timeslot room );
    $dp1->writedelimited_deluxe(
        $sorted_data, \@columns_selected, $outputfile, 
        \@reprocessing_info, $delimiter);

=item *

Print data to an HTML file with fields aligned with whitespace in a manner similar to Perl formats:

    $outputfile = 'report.html';
    $title = 'Agency Census Report';
    $dp1->writeHTML(
        $sorted_data, \@columns_selected, $outputfile, $title);

=item *

Create a Data::Presenter::[Package2] object:

    use Data::Presenter;
    use Data::Presenter::[Package2];

    $sourcefile = 'in02.txt';
    $fieldsfile = 'fields02.data';
    do $fieldsfile;
    my $dp2 = Data::Presenter::[Package2]->new(
        $sourcefile, \@fields,\%parameters, $index);

=item *

Call simple and complex output methods, extract selected entries and establish column sorting order for Data::Presenter::[Package2] object:  as above for Data::Presenter::[Package1].

=item *

Create a Data::Presenter::Combo::Intersect object:

    my @objects = ($dp1, $dp2);
    my $dpC = Data::Presenter::Combo::Intersect->new(\@objects);

=item *

Create a Data::Presenter::Combo::Union object:

    my @objects = ($dp1, $dp2);
    my $dpC = Data::Presenter::Combo::Union->new(\@objects);

=item *

Call simple and complex output methods, extract selected entries and establish column sorting order for Data::Presenter::Combo::Intersect and Data::Presenter::Combo::Union objects:  as above for Data::Presenter::[Package1].

=back

=head1 PREREQUISITE

This module requires the List::Compare module by the same author from CPAN (L<http://search.cpan.org/author/JKEENAN/List-Compare/Compare.pm>).

=head1 DESCRIPTION

Data::Presenter is an object-oriented module designed to facilitate the manipulation of database reports.  If the data can be represented by a row-column matrix, where for each data entry (row) (a) there are one or more fields containing data values (columns) and (b) at least one of those fields can be used as an index to uniquely identify each entry, then the data structure is suitable for manipulation by Data::Presenter.  In Perl terms, if the data can be represented by a hash of arrays, it is suitable for manipulation by Data::Presenter.

Data::Presenter can be used to output some fields (columns) from a database while excluding others (see L<"&sort_by_column"> below).  It can also be used to select certain entries (rows) from the database for output while excluding other entries (see L<"&select_rows"> below).

In addition, if a user has two or more database reports, each of which has the same field serving as an index for the data, then it is possible to construct either a:

=over 4

=item *

L<Data::Presenter::Combo::Intersect|"Data::Presenter::Combo Objects"> object which holds data for those entries found in common in all the source databases (the I<intersection> of the entries in the source databases); or a

=item *

L<Data::Presenter::Combo::Union|"Data::Presenter::Combo Objects"> object which holds data for those entries found in any of the source databases (the I<union> of the entries in the source databases).

=back

Whichever flavor of Data::Presenter::Combo object the user creates, the module guarantees that each field (column) found in any of the source databases appears once and once only in the Combo object.

Data::Presenter is I<not> a database module I<per se>, nor is it an interface to databases in the manner of DBI.  It cannot used to enter data into a database, nor can it be used to modify or delete data.  Data::Presenter operates on I<reports> generated from databases and is designed for the user who:

=over 4

=item *

does not necessarily have direct access to a given database;

=item *

receives reports from that database generated by another user; but

=item *

needs to manipulate and re-output that data in simple, useful ways such as text files, Perl formats and HTML tables.

=back

Data::Presenter is most appropriate in situations where either has no access to (or chooses not to use) commercial desktop database programs such as I<Microsoft Access>(r) or open source database programs such as I<MySQL>(r).  Data::Presenter's installation and preparation require moderate knowledge of Perl, but the actual running of Data::Presenter scripts can be delegated to someone with less knowledge of Perl.

=head1 DEFINITIONS AND EXAMPLES

=head2 Definitions

I<Administrator>:  The individual in a workplace responsible for the installation of Data::Presenter on the system or network, analysis of sources, preparation of Data::Presenter configuration files and preparation of Data::Presenter subclass packages other than Data::Presenter::Combo and its subclasses.  (I<Cf.> L<"Operator">.)

I<Entry>:  A row in the L<source|"Source"> containing the values of the fields for one particular item.

I<Field>:  A column in the L<source|"Source"> containing a value for each entry.

I<Index>:  The column in the L<source|"Source"> whose values uniquely identify each entry in the source.  Also referred to as ''unique ID.''  (In the current implementation of Data::Presenter, an index must be a strictly numerical value.)

I<Index Field>:  The column in the L<source|"Source"> containing a unique value (L<"index">) for each entry.

I<Metadata>:  Entries in the Data::Presenter object's data structure which hold information prepared by the administrator about the data structure and output parameters.

In the current version of Data::Presenter, metadata is extracted from the variables C<@fields>, C<%parameters> and C<$index> found in the configuration file F<fields.data>.  The metadata is first stored in package variables in the invoking Data::Presenter subclass package and then entered into the Data::Presenter object as hash entries keyed by C<'fields'>, C<'parameters'> and C<$index>, respectively.  (The word 'options' has also been reserved for future use as the key of a metadata entry in the object's data structure.)

I<Object's Current Data Structure>:  Non-L<metadata|"Metadata"> entries found in the Data::Presenter object at the point a particular selection, sorting or output method is called.

The object's current data structure may be thought of as the result of the following calculations:

            construct a Data::Presenter::[Package1] object
    less:   entries excluded by application of selection criteria found
                in C<select_rows>
    less:   metadata entries in object keyed by 'fields', 'parameters' or 'fields'
    result: object's current data structure

I<Operator>:  The individual in a workplace responsible for running a Data::Presenter script, including:

=over 4

=item *

selection of sources;

=item *

selection of particular entries and fields from the source for presentation in the output; and

=item *

selection of output formats and names of output files.  (I<Cf.> L<"Administrator">.)

=back

I<Source>:  A report, typically saved in the form of a text file, generated by a database program which presents data in a row-column format.  The source may also contain other information such as page headers and footers and table headers and footers.  Also referred to herein as ''source report,'' ''source file'' or ''database source report.''

=head2 Examples

Sample files are included in the archive file in which this documentation is found.  Three source files, F<census.txt>, F<medinsure.txt> and F<hair.txt>, are included, as are the corresponding Data::Presenter subclass packages (F<Census.pm>, F<Medinsure.pm> and F<Hair.pm>) and configuration files (F<fields_census.data>, F<fields_medinsure.data> and F<fields_hair.data>).

=head1 USAGE:  Administrator

This section addresses those aspects of the usage of Data::Presenter which must be implemented by the L<administrator|"Administrator">:

=over 4

=item *

L<installation|"Installation"> of Data::Presenter on the system;

=item *

analysis of L<sources|"Analysis of Source Files">;

=item *

preparation of Data::Presenter L<configuration|"Preparation of Configuration File (fields.data)"> files; and

=item *

preparation of Data::Presenter L<subclass packages|"Preparation of Data::Presenter Subclasses"> other than Data::Presenter::Combo and its subclasses.

=back

If Data::Presenter has already been properly configured by your administrator and you are simply concerned with using Data::Presenter to generate reports, you may skip ahead to L<"USAGE: Operator">.

=head2 Installation

=over 4

=item 1

Determine the directory on your system in which you place user-created Perl modules, I<i.e.,> the directory you would use with the C<use lib> pragma.  Go to this directory and place F<Data::Presenter.pm> therein.

=item 2

Next, create a subdirectory called F<Data::Presenter>.  Place F<Data::Presenter::Combo.pm> therein.  For each database report you use as a source of data to be manipulated by Data::Presenter, you will also create a package corresponding to that source.  This package will in turn be placed in the Data::Presenter subdirectory.  If, for example, on a Win32 system you place user-created modules in:

    C:\Perl\usr\lib

the paths to F<Data::Presenter.pm> and F<Data::Presenter::Combo.pm>, respectively, will be:

    C:\Perl\usr\lib\Data::Presenter.pm

and

    C:\Perl\usr\lib\Data::Presenter\Combo.pm

Suppose that you have two data sources, C<census.txt> and C<medinsure.txt>, from which you would like to extract data.  (See the archive file in which this documentation is found for sample files.)  You would create a Data::Presenter subclass package for each.  These packages therefore go into the same subdirectory as F<Data::Presenter::Combo.pm>.  The paths for those packages would be:

    C:\Perl\usr\lib\Data::Presenter\Census.pm

and

    C:\Perl\usr\lib\Data::Presenter\medinsure.pm

=item 3

Next, within the F<Data::Presenter> directory create a subdirectory called F<Combo>.  Place Data::Presenter::Combo::Intersect and Data::Presenter::Combo::Union therein.  The paths for these packages would be:

    C:\Perl\usr\lib\Data::Presenter\Combo\Intersect.pm

and

    C:\Perl\usr\lib\Data::Presenter\Combo\Union.pm

=item 4

Now determine the directory on your system from which you will call a Perl script which uses Data::Presenter.  In this directory you will place:

=over 4

=item *

The calling script (for example, a program called F<Data::Presenter.pl>).

=item *

The database reports -- typically plain text files -- which you are using as source files for F<Data::Presenter.pl>.  (In the sample files enclosed in the archive accompanying this documentation, these source files are called F<census.txt> and F<medinsure.txt>.)

=item *

For each database report which you are using as a source file, a configuration file in text format containing two Perl variables, C<@fields> and C<%parameters>, the specification of which is described further below.  By convention, this configuration file is named by some variation on the theme of F<fields.data>.  (In the sample files enclosed in the archive accompanying this documentation, these configuration files are called F<fields_census.data> and F<fields_medinsure.data>).

=back

=back

=head2 Analysis of Source Files

Successful use of Data::Presenter assumes that the administrator is able to analyze a report generated from a database, distinguish key structural features of such a source report and write Perl code which will extract the most relevant information from the report.  A complete discussion of these issues is beyond the scope of this documentation.  What follows is a taste of the issues involved.

Structural features of a database report are likely to include the following:  report headers, page headers, table headers, data entries reporting values of a variety of fields, page footers and report footers.  Of these features, data entries and table headers are most important from the perspective of Data::Presenter.  The data entries are the data which will actually be manipulated by Data::Presenter, while table headers will provide the administrator guidance when writing the configuration file F<fields.data>.  Report and page headers and footers are generally irrelevant and will be stripped out.

For example, let us suppose that a portion of a client census looks like this:

    CLIENTS - AUGUST 1, 2001 - C O N F I D E N T I A L          PAGE  1
    SHRED WHEN NEW LIST IS RECEIVED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     LAST NAME      FIRST NAM   C. NO      BIRTH

     HERNANDEZ      HECTOR     456791 1963-07-16
     VASQUEZ        ADALBERTO  456792 1973-10-02
     WASHINGTON     ALBERT     906786 1953-03-31

The first two lines are probably report or page headers and should be stripped out.  The third line consists of table column names and may give clues as to how F<fields_census.data> should be written.  The fourth line is blank and should be stripped out.  The next three lines constitute actual rows of data; these will be the focus of Data::Presenter.

A moderately experienced Perl programmer will look at this report and say, ''Each row of data can be stored in a Perl array.  If each client's 'c. no' is unique, then it can be used as the key of an entry in a Perl hash where the entry's value is a reference to the array just mentioned.  A hash of arrays -- I can use Data::Presenter!''

Our Perl programmer would then say, ''I'll open a filehandle to the source file and read the file line-by-line into a C<while> loop.  I'll write lines beginning C<next if> to bypass the headers and the blank lines.''  For instance:

    next if (/^CLIENTS/);
    next if (/^SHRED/);
    next if (/^\s?LAST\sNAME/);
    next if (/^$/);

Our Perl hacker will then say, ''I could try to write regular expressions to handle the rows of data.  But since the data appears to be strictly columnar, I'll probably be better off using the Perl C<unpack> function.  I'll use the column headers to suggest names for my variables.''  For instance:

    my ($lastname, $firstname, $cno, $datebirth) =
    unpack("x A14 x A10 x A6 x A10", $_);

Having provided a taste of what to do with the rows of the data structure, we now turn to an analysis of the columns of the structure.

=head2 Preparation of Configuration File (fields.data)

For each data source, the administrator must prepare a configuration file, typically named as some variation on F<fields.data>.  F<fields.data> consists of three Perl variables:  C<@fields>, C<%parameters> and C<$index>.

I<@fields>:  C<@fields> has one element for each column (field) that appears in the data source.  The elements of C<@fields> I<must> appear in exactly the same order as they appear in the data source.  Each element should be a single Perl word, I<i.e.>, consist solely of letters, numerals or the underscore character '_'.

In the sample configuration file F<fields_census.data> included with this documentation, this variable reads:

    @fields = qw(
        lastname, firstname, cno, unit, ward, dateadmission, datebirth);

In another sample configuration file, F<fields_medinsure.data>, this variable reads:

    @fields = qw(lastname, firstname, cno, stateid, medicare, medicaid);

I<%parameters>:  C<%parameters> is a bit trickier.  There must be one entry in C<%parameters> for each element in C<@fields>.  Hence, there is one entry in C<%parameters> for each column (field) in the data source.  However, the keys of C<%parameters> are spelled C<$fields[0]>, C<$fields[1]>, and so on through the highest index number in C<@fields> (which is 1 less than the number of elements in C<@fields>).  Using the example above, we can begin to construct C<%parameters> as follows:

    %parameters = (
        $fields[0] =>
        $fields[1] =>
        $fields[2] =>
        $fields[3] =>
        $fields[4] =>
        $fields[5] =>
        $fields[6] =>
    );

The value for each entry in C<%parameters> consists of an array of 4 elements specified as follows:

=over 4

=item Element 0

A positive integer specifying the maximum number of characters which may be displayed in any output format for the given column (field).  In the example above, we will specify that column 'lastname' (C<$fields[0]>) may have a maximum of 14 characters.

    $fields[0]          => [14,

=item Element 1

An upper-case letter 'U' or 'D' (for 'Up' or 'Down') enclosed in single quotation marks indicating whether the given column should be sorted in ascending or descending order.  In the example above, 'lastname' sorts in ascending order.

    $fields[0]          => [14, 'U',

=item Element 2

A lower-case letter 'a', 'n' or 's' enclosed in single quotation marks indicating whether the given column should be sorted alphabetically (case-insensitive), numerically or ASCII-betically (case-sensitive).  In the example above, 'lastname' sorts in alphabetical order.  (Data::Presenter I<per se> does not yet have a facility for sorting in date or time order.  If dates are entered as pure numerals in 'MMDD' order, they may be sorted numerically.  If they are entered in the MySQL standard format '
YY-MM-DD', they may be sorted alphabetically.)

    $fields[0]          => [14, 'U', 'a',

=item Element 3

A string enclosed in single quotation marks to be used as a column header when the data is outputted in some table-like format such as a Perl format with a header or an HTML table.  The administrator may choose to use exactly the same words here that were used in C<@fields>, but a more natural language string is probably preferable.  In the example above, the first column will carry the title 'Last Name' in any output.

    $fields[0]          => [14, 'U', 'a', 'Last Name'],

=back

Using the same example as previously, we can now complete C<%parameters> as:

    %parameters = (
        $fields[0]          => [14, 'U', 'a', 'Last Name'],
        $fields[1]          => [10, 'U', 'a', 'First Name'],
        $fields[2]          => [ 7, 'U', 'n', 'C No.'],
        $fields[3]          => [ 6, 'U', 'a', 'Unit'],
        $fields[4]          => [ 4, 'U', 'n', 'Ward'],
        $fields[5]          => [10, 'U', 'a', 'Date of Admission'],
        $fields[6]          => [10, 'U', 'a', 'Date of Birth'],
    );

I<$index>:  C<$index> is the simplest element of I<fields.data>. It is the array index for the entry in C<@fields> which describes the field in the data source whose values uniquely identify each entry in the source.  If, in the example above, C<'cno'> is the L<index field|"Index Field"> for the data in I<census.txt>, then C<$index> is C<2>.  (Remember that Perl starts counting array elements with zero.)

=head2 Preparation of Data::Presenter Subclasses

F<Data::Presenter.pm>, F<Data::Presenter::Combo.pm>, F<Data::Presenter::Combo::Intersect.pm> and F<Data::Presenter::Combo::Union> are ready to use ''as is.''  They require no further modification by the administrator.  However, each report from which the operator draws data needs to have a package subclassed beneath Data::Presenter and written specifically for that report by the administrator.

Indeed, B<no object is ever constructed I<directly> from Data::Presenter.  All objects are constructed from subclasses of Data::Presenter.>

Hence:

    my $dp1 = Data::Presenter->new($source, \@fields, \%parameters, $index);
        # INCORRECT

    my $dp1 = Data::Presenter::[Package1]->new(
    $source, \@fields, \%parameters, $index);    # CORRECT

Data::Presenter::[Package1], however, does not contain a C<new> method.  It inherits Data::Presenter's C<new> method -- which then turns around and delegates the task of populating the object with data to Data::Presenter::[Package1]'s C<_init> method!

This C<_init> method must be customized by the administrator to properly handle the specific features of each source file.  This requires that the administrator be able to write a Perl script to 'clean up' the source file so that only lines containing meaningful data are written to the Data::Presenter object.  (See L<"Analysis of Source Files"> above.)  With that in mind, a Data::Presenter::[Package1] package must always include the following methods:

=over 4

=item *

C<_init>

This method is called from within the constructor and is used to populate the hash which is blessed into the new object.  It opens a filehandle to the source file and typically reads that source file line-by-line via a Perl C<while> loop.  Perl techniques and functions such as regular expressions, C<split> and C<unpack> are used to populate a hash of arrays and to strip out lines in the data source not needed in the object.  Should the administrator need to ''munge'' any of the incoming data so that it appears in a uniform format (I<e.g.>, '2001-07-02' rather than '7/2/2001' or '07/02/2001'), the administrator should write appropriate code within C<_init> or in a separate module imported into the main package.  A reference to this hash is returned to the constructor, which blesses it into the object.

=item *

C<_extract_rows>

This method is called from within the Data::Presenter C<select_rows> method.  In much the same manner as C<_init>, it permits the administrator to ''munge'' operator-typed data to achieve a uniform format.

=back

The packages F<Data::Presenter::Census> and F<Data::Presenter::Medinsure> accompanying this documentation provide examples of C<_init> and C<_extract_rows>.  Search for the lines of code which read:

    # DATA MUNGING STARTS HERE
    # DATA MUNGING ENDS HERE

Here is a simple example of data munging.  In the sample configuration file F<fields_census.data>, all elements of C<@fields> are entered entirely in lower-case.  Hence, it would be advisable to transform the operator-specified content of C<$column> to all lower-case so that the program does not fail simply because an operator types an upper-case letter.  See C<&_extract_rows> in the Data::Presenter::Census package included with this documentation for an example.

Sample file F<Data::Presenter::Medinsure> contains an example of a subroutine written to clean up repetitive coding within the data munging section.  Search for C<sub _prepare_record>.

=head1 USAGE:  Operator

Once the administrator has installed Data::Presenter and completed the preparation of configuration files and Data::Presenter subclass packages, the administrator may turn over to the operator the job of selecting particular source files, output formats and particular entries and fields from within the source files.

=head2 Construction of a Data::Presenter Object

Using the hospital census example included with this documentation, the operator would construct a Data::Presenter::Census object with the following code:

    use Data::Presenter;
    use Data::Presenter::Census;
    our @fields = ();
    our %parameters = ();
    our $index = '';
    my ($sourcefile, $fieldsfile, $outputfile, $sorted_data);

    $sourcefile = 'census.txt';
    $fieldsfile = 'fields_census.data';
    do $fieldsfile;
    my $dp1 = Data::Presenter::Census->new(
    $sourcefile, \@fields, \%parameters, $index);

=head2 Methods to Report on the Data::Presenter Object Itself

I<&get_data_count>:  Returns the current number of data entries in the specified Data::Presenter object.  This number does I<not> include those elements in the object whose keys are reserved words.  This method takes no arguments and returns one numerical scalar.

    my $data_count = $dp1->get_data_count();
    print 'Data count is now:  ', $data_count, "\n";

I<&print_data_count>:  Prints the current data count preceded by ''Current data count:  ''.  This number does I<not> include those elements in the object whose keys are reserved words.  This method takes no arguments and returns no values.

    $dp1->print_data_count();

I<&get_keys>:  Returns a reference to an array whose elements are an ASCII-betically sorted list of keys to the hash blessed into the Data::Presenter::[Package1] object.  This list does not include those elements whose keys are reserved words.  This method takes no arguments and returns only the array reference described.

    my $keysref = $dp1->get_keys();
    print "Current data points are:  @$keysref\n";

=head2 Data::Presenter Selection, Sorting and Output Methods

I<&select_rows>:  C<&select_rows> enables the operator to establish criteria by which specific entries from the data can be selected for output.  It does so I<not> by creating a new object but by striking out entries in the L<object's current data structure|"Object's Current Data Structure"> which do not meet the selection criteria.

If the operator were using Perl as an interface to a true database program, selection of entries would most likely be handled by a module such as DBI and an SQL-like query.  In that case, it would be possible to write complex selection queries which operate on more than one field at a time such as:

    select rows where 'datebirth' is before 01/01/1960
    AND 'lastname' equals 'Vasquez'
    # (NOTE:  This is generic code,
    #  not true Perl or Perl DBI code.)

Complex selection queries are not yet possible in Data::Presenter.  However, you could accomplish much the same objective with a series of simple selection queries that operate on only one field at a time,

    select rows where 'datebirth" is before 01/01/1960

then

    select rows where 'lastname' equals 'Vasquez'

each of which narrows the selection criteria.

How do we accomplish this within Data::Presenter?  For each selection query, the operator must define 3 variables:  C<$column>, C<$relation> and C<@choices>.  These variables are passed to C<&select_rows>, which in turn passes them to certain internal subroutines where their values are manipulated as follows.

=over 4

=item *

C<$column>

C<$column> must be an element of L<C<@fields>|"@fields"> found in the L<configuration file|"Preparation of Configuration File (fields.data)">.

=item *

C<$relation>

C<$relation> expresses the verb part of the selection query, I<i.e.,> relations such as ''equals'', ''is less than'',  ''>='', ''after'' and so forth.  In an attempt to add natural language flexibility to the selection query, Data::Presenter permits the operator to enter a wide variety of mathematical and English expressions here:

=over 4

=item *

equality

    'eq', 'equals', 'is', 'is equal to', 'is a member of',
    'is part of', '=', '=='

=item *

non-equality

    'is', 'is not', 'is not equal to', 'is not a member of',
    'is not part of', 'is less than or greater than',
    'is less than or more than', 'is greater than or less than',
    'is more than or less than', 'does not equal', 'not',
    'not equal to ', 'not equals', '!=', '! =', '!==', '! =='

=item *

less than

    '<', 'lt', 'is less than', 'is fewer than', 'before'

=item *

greater than

    '>', 'gt', 'is more than', 'is greater than', 'after'

=item *

less than or equal to

    '<=', 'le', 'is less than or equal to',
    'is fewer than or equal to', 'on or before', 'before or on'

=item *

greater than or equal to

    '>=', 'ge', 'is more than or equal to', 'is greater than or equal to',
    'on or after', 'after or on'

=back

As long as the operator selects a string from the category desired, Data::Presenter will convert it internally in an appropriate manner.

=item *

C<@choices>

If the relationship being tested is one of equality or non-equality, then the operator may enter more than one value here, any one of which may satisfy the selection criterion.

    my ($column, $relation);
    my @choices = ();

    $column = 'lastname';
    $relation = 'is';
    @choices = ('Smith', 'Jones');
    $dp1->select_rows($column, $relation, \@choices);

If, however, the relationship being tested is one of 'less than', 'greater than', etc., then the operator should enter only one value, as the value is establishing a limit above or below which the selection criterion will not be met.

    $column = 'datebirth';
    $relation = 'before';
    @choices = ('01/01/1970');
    $dp1->select_rows($column, $relation, \@choices);

=back

I<&sort_by_column>:  C<&sort_by_column> takes only 1 argument:  a reference to an array consisting of the fields the operator wishes to present in the final output, listed in the order in which those fields should be sorted.  All elements of this array must be elements in C<@fields>.  B<The index field must always be included as one of the columns selected,> though it may be placed last if it is not intrinsically important in the final output.  C<&sort_by_column> returns a reference to a hash of appropriately sorted data which will be used as input to Data::Presenter methods such as C<&writeformat>, C<&writeformat_plus_header> and C<&writeHTML>.

To illustrate:

    my @columns_selected = ();
    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

Suppose that the operator fails to include the index column in C<@columns_selected>.  This risks having two or more identical data entries, only the last of which would appear in the final output.  As a safety precaution, C<&sort_by_column> throws a warning and places duplicate entries in a text file called F<dupes.txt>.

Note:  If you want your output to report only selected entries from the source, and if you want to apply one of the complex Data::Presenter output methods which require application of C<&sort_by_column>, call C<select_rows> I<before> calling C<&sort_by_column>.  Otherwise your report may contain blank lines.

I<&print_to_screen>:  C<&print_to_screen> prints to the screen a semicolon-delimited display of all entries in the object's current data structure.  It takes no arguments and returns no values.

    $dp1->print_to_screen();

A typical line of output will look something like:

    VASQUEZ;JORGE;456787;LAVER;0105;1986-01-17;1956-01-13;

I<&print_to_file>:  C<&print_to_file> prints to an operator-specified file a semicolon-delimited display of all entries in the object's current data structure.  It takes 1 argument -- the user-specified output file -- and returns no values.

    $outputfile = 'census01.txt';
    $dp1->print_to_file($outputfile);

A typical line of output will look exactly like that produced by L<C<print_to_screen>|"&print_to_screen">.

I<&print_with_delimiter>:  C<&print_with_delimiter>, like C<&print_to_file>, prints to an operator-specified file. C<&print_with_delimiter> allows the operator to specify the character pattern which will be used to delimit display of all entries in the object's current data structure.  It does not print the delimiter after the final field in a particular data record.  It takes 2 arguments -- the user-specified output file and the character pattern to be used as delimiter -- and returns no values.

    $outputfile = 'delimited01.txt';
    $delimiter = '|||';
    $dp1->print_with_delimiter($outputfile, $delimiter);

The file created C<&print_with_delimiter> is designed to be used as an input to functions such as 'Convert text to tabs' or 'Convert text to table' found in commercial word processing programs.  Such functions require delimiter characters in the input.  A typical line of output will look something like:

    VASQUEZ|||JORGE|||456787|||LAVER|||0105|||1986-01-17|||1956-01-13

I<&full_report>:  C<&full_report> prints to an operator-specified file each entry in the object's current data structure, sorted by the index and explicitly naming each field name/field value pair.  It takes 1 argument -- the user-specified output file -- and returns no values.

    $outputfile = 'report01.txt';
    $dp1->full_report($outputfile);

The output for a given entry will look something like:

    456787
        lastname                VASQUEZ
        firstname               JORGE
        cno                     456787
        unit                    LAVER
        ward                    0105
        dateadmission           1986-01-17
        datebirth               1956-01-13

I<&writeformat>:  C<&writeformat> writes data via Perl's C<formline> function -- the function which internally powers Perl formats -- to an operator-specified file.  C<&writeformat> takes 3 arguments:

=over 4

=item *

C<$sorted_data>

C<$sorted_data> is a hash reference which is the return value of C<&sort_by_column>.  Hence, C<&writeformat> can only be called once C<&sort_by_column> has been called.

=item *

C<\@columns_selected>

C<\@columns_selected> is a reference to the array of fields in the data source selected for presentation in the output file.  It is the same variable which is used as the argument to C<&sort_by_column>.

=item *

C<$outputfile>

C<$outputfile> is the name of a file arbitrarily selected by the operator to hold the output of C<&writeformat>.

=back

Using the ''census'' example from above, the overall sequence of code needed to use C<&writeformat> would be:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $outputfile = 'format01.txt';
    $dp1->writeformat($sorted_data, \@columns_selected, $outputfile);

The result of the above call would look like:

    HERNANDEZ      HECTOR     1963-08-01 456791
    VASQUEZ        ADALBERTO  1973-08-17 786792
    VASQUEZ        ALBERTO    1953-02-28 906786

The columnar appearance of the data is governed by choices made by the administrator within the configuration file (here, within F<fields_census.data>).  The choice of columns themselves is controlled by the operator via C<\@columns_selected>.

I<&writeformat_plus_header>:  C<&writeformat_plus_header> writes data via Perl formats to an operator-specified file and writes a Perl format header to that file as well.  C<&writeformat_plus_header> takes 4 arguments:  C<$sorted_data>, C<\@columns_selected> and C<$outputfile> (just like C<&writeformat>) plus:

=over 4

=item *

C<$title>

C<$title> holds text chosen by the operator.

=back

The complete call to C<writeformat_plus_header> looks like this:

    @columns_selected = (
        'unit', 'ward', 'lastname', 'firstname',
        'datebirth', 'dateadmission', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $outputfile = 'format02.txt';
    $title = 'Hospital Census Report';
    $dp1->writeformat_plus_header(
        $sorted_data, \@columns_selected, $outputfile, $title);

and will produce a header and formatted data like this:

    Hospital Census Report

                                          Date       Date of
    Unit   Ward Last Name      First Name of Birth   Admission  C No.
    ------------------------------------------------------------------
    LAVER  0105 VASQUEZ        JORGE      1956-01-13 1986-01-17 456787
    LAVER  0107 VASQUEZ        LEONARDO   1970-15-23 1990-08-23 456788
    SAMSON 0209 VASQUEZ        JOAQUIN    1970-03-25 1990-11-14 456789

The wording of the column headers is governed by choices made by the administrator within the configuration file (here, within F<fields_census.data>).  If a particular word in a column header is too long to fit in the space allocated, it will be truncated.

I<&writeformat_with_reprocessing>:  C<&writeformat_with_reprocessing> is an advanced application of Data::Presenter and the reader may wish to skip this section until other parts of the module have been mastered.

C<&writeformat_with_reprocessing> permits a sophisticated administrator to activate ''last minute'' substitutions in the strings printed out from the format accumulator variable C<$^A>.  Suppose, for example, that a school administrator faced the problem of scheduling classes in different classrooms and in various time slots.  Suppose further that, for ease of programming or data entry, the time slots were identified by chronologically sequential numbers and that instructors were identified by a unique ID built up from their first and last names.  Applying an ordinary C<&writeformat> to such data might show output like this

    11 Arithmetic                       Jones        4044 4044_11
    11 Language Studies                 WilsonT      4054 4054_11
    12 Bible Study                      Eliade       4068 4068_12
    12 Introduction to Computers        Knuth        4086 4086_12
    13 Psychology                       Adler        4077 4077_13
    13 Social Science                   JonesT       4044 4044_13
    51 World History                    Wells        4052 4052_51
    51 Music Appreciation               WilsonW      4044 4044_51

where C<11> mapped to 'Monday, 9:00 am', C<12> to 'Monday, 10:00 am', C<51> to 'Friday, 9:00 am' and so forth and where the fields underlying this output were 'timeslot', 'classname', 'instructor', 'room' and 'sessionID'.  While this presentation is useful, a client might wish to have the time slots and instructor IDs decoded for more readable output:

    Monday, 9:00     Arithmetic                 E Jones        4044 4044_11
    Monday, 9:00     Language Studies           T Wilson       4054 4054_11
    Monday, 10:00    Bible Study                M Eliade       4068 4068_12
    Monday, 10:00    Introduction to Computers  D Knuth        4086 4086_12
    Monday, 11:00    Psychology                 A Adler        4077 4077_13
    Monday, 11:00    Social Science             T Jones        4044 4044_13
    Friday, 9:00     World History              H Wells        4052 4052_51
    Friday, 9:00     Music Appreciation         W Wilson       4044 4044_51

Time slots coded with chronologically sequential numbers can be ordered to sort numerically in the C<%parameters> established in the F<fields_[package1].data> file corresponding to a particular Data::Presenter::[package1].  Their human-language equivalents, however, will I<not> sort properly, as, for example, 'Friday' comes before 'Monday' in an alphabetical or ASCII-betical sort.  Clearly, it would be desirable to establish the sorting order by relying on the chronologically sequential time slots and yet have the printed output reflect more human-readable days of the week and times.  Analogously, for the instructor we might wish to display the first initial and last name in our printed output rather than his/her ID code.

The order in which data records appear in output is determined by C<&sort_by_column> I<before> C<&writeformat> is called.  How can we preserve this order in the final output?

Answer:  After we have stored a given formed line in C<$^A>, we I<reprocess> that line by calling an internal subroutine defined in the invoking class, C<&Data::Presenter::[package1]::_reprocessor>, which tells Perl to splice out certain portions of the formed line and substitute more human-readable copy.  The information needed to make C<&_reprocessor> work comes from two places.

First, from a hash passed by reference as an argument to C<&writeformat_with_reprocessing>.  C<&writeformat_with_reprocessing> takes four arguments, the first three of which are the same as those passed to C<&writeformat>.  The fourth argument to C<&writeformat_with_reprocessing> is a reference to a hash whose keys are the names of the fields in the data records where we wish to make substitutions and whose corresponding values are the number of characters the field will be allocated I<after> substitution.  The call to C<&writeformat_with_reprocessing> would therefore look like this:

    $outputfile = 'format04.txt';
    my %reprocessing_info = ( 'timeslot'   => 17,
                              'instructor' => 15,
                            );
    $dp2->writeformat_with_reprocessing(
        $sorted_data, \@columns_selected, $outputfile, \%reprocessing_info);

Second, C<&writeformat_with_reprocessing> takes advantage of the fact that Data::Presenter's package global hash C<%reserved> contains four keys -- C<'fields'>, C<'parameters'>, C<'index'> and C<'options'> -- only the first three of which are used in Data::Presenter's constructor or sorting methods.  Early in the development of Data::Presenter the keyword C<'options'> was deliberately left unused so as to be available for future use.

The sophisticated administrator can make use of the C<'options'> key to store metadata in a variety of ways.  In writing C<&Data::Presenter::[package1]::_init>, the administrator prepares the way for last-minute reprocessing by creating an C<'options'> key in the hash to be blessed into the C<&Data::Presenter::[package1]> object.  The value corresponding to the key C<'options'> is itself a hash with two elements keyed by C<'subs'> and C<'sources'>.  If C<$dp2> is the object and C<%data> is the hash blessed into the object, then we are looking at these two elements:

    $data{'options'}{'subs'}
    $data{'options'}{'sources'}

The values corresponding to these two keys are references to yet more hashes.  The hash which is the value for C<$data{'options'}{'subs'}> hash keys whose elements are the name of subroutines, each of which is built up from the string C<'reprocess_'> concatenated with the name of the field to be reprocessed, I<e.g.>

    $data{'options'}{'subs'} =
        { 'reprocess_timeslot'   => 1,
          'reprocess_instructor' => 1,
        };

These field-specific internal reprocessing subroutines may be defined by the administrator in C<&Data::Presenter::[package1]> or they may be imported from some other module.  C<&writeformat_with_reprocessing> verifies that these subroutines are actually present in C<&Data::Presenter::[package1]> regardless of where they were originally found.

What about C<$data{'options'}{'sources'}>?  This location stores all the original data from which substitutions are made.  Example:

    $data{'options'}{'sources'} =
        {
          'timeslot'   =>
            {
              11 => ['Monday', '9:00 am'  ],
              12 => ['Monday', '10:00 am' ],
              13 => ['Monday', '11:00 am' ],
              51 => ['Friday', '9:00 am'  ],
            },
          'instructor' => ,
            {
              'Jones'      => ['Jones',  'E' ],
              'WilsonT'    => ['Wilson', 'T' ],
              'Eliade'     => ['Eliade', 'M' ],
              'Knuth'      => ['Knuth',  'D' ],
              'Adler'      => ['Adler',  'A' ],
              'JonesT'     => ['Jones',  'T' ],
              'Wells'      => ['Wells',  'H' ],
              'WilsonW'    => ['Wilson', 'W' ],
            }
        };

The point at which this data gets into the object is, of course, C<&Data::Presenter::[package1]::_init>.  What the administrator does at that point is limited only by his/her imagination.  Data::Presenter seeks to bless a hash into its object.  That hash must meet the following requirements:

=over 4

=item *

With the exception of elements holding metadata, each element holds an array, each of whose elements must be a number or a string.

=item *

Three metadata elements keyed as follows must be present:

=over 4

=item *

C<'fields'>;

=item *

C<'parameters'>;

=item *

C<'index'>.

=back

The fourth metadata element keyed by C<'options'> is required only if some Data::Presenter method has been written which requires the information stored therein.  C<&writeformat_with_reprocessing> is the only such method currently present, but additional methods using the C<'options'> key may be added in the future.

=back

The author has used two different approaches to the problem of initializing Data::Presenter::[package1] objects.

=over 4

=item *

In the first, more standard approach, the name of a source file can be passed to the constructor, which passes it on to the initializer, which then opens a filehandle to the file and processes with regular expressions, C<unpack>, etc. to build an array for each data record.  Keyed by a unique ID, a reference to this array then becomes the value of an element of the hash which, once metadata is added, is blessed into the Data::Presenter::[package1] object.  The source for the metadata is the F<fields_[package1].data> file and the C<@fields>, C<%parameters> and C<$index> found therein.

=item *

A second approach asks:  ''Instead of having C<_init> do data munging on a file, why not directly pass it a hash of arrays?  Better still, why not pass it a hash of arrays which already has an C<'options'> key defined?  And better still yet, why not pass it an object produced by some other Perl module and containing a blessed hash of arrays with an already defined C<'options'> key?''  In this approach, C<&Data::Presenter::[package1]::_init> does no data munging.  It is mainly concerned with defining the three required metadata elements.

=back

I<&writeformat_deluxe>:  C<&writeformat_deluxe> is an advanced application of Data::Presenter and the reader may wish to skip this section until other parts of the module have been mastered.

C<&writeformat_deluxe> enables the user to have I<both> column headers (as in C<&writeformat_plus_header>) and dynamic, 'just-in-time' reprocessing of data in selected fields (as in C<&writeformat_with_reprocessing>).  Call it just as you would C<&writeformat_with_reprocessing>, but insert C<$title> immediately before C<\%reprocessing_info>.

    $outputfile = 'format_tally_deluxe.txt';
    $title = 'Therapy Groups:  February 3-7, 10-14, 2003';
    my %reprocessing_info = (
        'timeslot'   => 17,
        'instructor' => 15,
    );

    $dp2->writeformat_deluxe(
        $sorted_data, \@columns_selected, $outputfile, $title, \%reprocessing_info);

I<&writedelimited>:  The C<&Data::Presenter::writeformat...> family of subroutines discussed above write data to plain-text files in columns aligned with whitespace via Perl's C<formline> function -- the function which internally powers Perl formats.  This is suitable if the ultimate consumer of the data is satisfied to read a plain-text file.  However, in many business contexts data consumers are more accustomed to word processing files than to plain-text files.  In particular, data consumers are accustomed to data presented in tables created by commercial word processing programs. Such programs generally have the capacity to take text in which individual lines consist of data separated by delimiter characters such as tabs or commas and transform that text into rows in a table where the delimiters signal the borders between table cells.

To that end, the author has created the C<&Data::Presenter::writedelimited...> family of subroutines to print output to plain-text files intended for further processing within word processing programs.  The simplest method in this family, C<&writedelimited> takes 3 arguments:

=over 4

=item *

C<$sorted_data>

C<$sorted_data> is a hash reference which is the return value of C<&sort_by_column>.  Hence, C<&writeformat> can only be called once C<&sort_by_column> has been called.

=item *

C<$outputfile>

C<$outputfile> is the name of a file arbitrarily selected by the operator to hold the output of C<&writeformat>.

=item *

C<$delimiter>

C<$delimiter> is the user-selected delimiter character which will delineate fields within an individual record in the output file.  Typically, this character will be a tab (C<\t>), comma (C<,>) or similar character that a word processing program's 'convert text to table' feature can use to establish columns.

=back

Using the ''census'' example from above, the overall sequence of code needed to use C<&writedelimited> would be:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $outputfile = 'format001.txt';
    $delimiter = "\t";
    $dp1->writedelimited($sorted_data, $outputfile, $delimiter);

Note that, unlike C<&writeformat>, C<&writedelimited> does not require a reference to C<@columns_selected> to be passed as an argument.

Depending on the number of characters in a text editor's tab-stop setting, the result of the above call might look like:

    HERNANDEZ	HECTOR	1963-08-01	456791
    VASQUEZ	ADALBERTO	1973-08-17	786792
    VASQUEZ	ALBERTO	1953-02-28	906786

This is obviously less readable than the output of C<&writeformat> -- but since the output of C<&writedelimited> is intended for further processing by a word processing program rather than for final use, this is not a major concern.

I<&writedelimited_plus_header>:  Just as C<&writeformat_plus_header> extended C<&writeformat> to include column headers, C<&writedelimited_plus_header> extends C<&writedelimited> to include column headers, separated by the same delimiter character as the data, in a plain-text file intended for further processing by a word processing program.

C<&writedelimited_plus_header> takes four arguments:  C<$sorted_data>, C<\@columns_selected>, C<$outputfile>, and C<$delimiter>.  The complete call to C<writedelimited_plus_header> looks like this:

    @columns_selected = (
        'unit', 'ward', 'lastname', 'firstname',
        'datebirth', 'dateadmission', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);

    $outputfile = 'format002.txt';
    $delimiter = "\t";
    $dp1->writedelimited_plus_header(
        $sorted_data, \@columns_selected, $outputfile, $delimiter);

Note that, unlike C<&writeformat_plus_header>, C<&writedelimited_plus_header> does not take C<$title> as an argument.  It is felt that any title would be more likely to be supplied in the word-processing file which ultimately holds the data prepared by C<&writedelimited_plus_header> and that it's inclusion at this point might interfere with the workings of the word processing program's 'convert text to table' feature.

Depending on the number of characters in a text editor's tab-stop setting, the result of the above call might look like:

    				Date	Date of
    Unit	Ward	Last Name	First Name	of Birth	Admission	C No.
    LAVER	0105	VASQUEZ	JORGE	1956-01-13	1986-01-17	456787
    LAVER	0107	VASQUEZ	LEONARDO	1970-15-23	1990-08-23	456788
    SAMSON	0209	VASQUEZ	JOAQUIN	1970-03-25	1990-11-14	456789

Again, the readability of the delimited copy in the plain-text file here is not as important as how correctly the delimiter has been chosen in order to produce good results once the file is further processed by a word processing program.

Note that, unlike C<&writeformat_plus_header>, C<&writedelimited_plus_header> does not produce a hyphen line.  The author feels that the separation of header and body within the table is here better handled within the word processing file which ultimately holds the data prepared by C<&writedelimited_plus_header>.

Note further that, unlike C<&writeformat_plus_header>, C<&writedelimited_plus_header> does not truncate the words in column headers.  This is because the C<&writedelimited...> family of methods does not impose a maximum width on output fields as does the C<&writeformat...> family of methods.  Hence, there is no need to truncate headers to fit within specified column widths.  Column widths in the C<&writedelimited...> family are ultimately determined by the word processing program which produces the final output.

I<&writedelimited_with_reprocessing>:  C<&writedelimited_with_reprocessing> is an advanced application of Data::Presenter and the reader may wish to skip this section until other parts of the module have been mastered.

C<&writedelimited_with_reprocessing>, like C<&writeformat_with_reprocessing>, permits a sophisticated administrator to activate ''last minute'' substitutions in strings to be printed such that substitutions do not affect the pre-established sorting order.  For a full discussion of the rationale for this feature, see the discussion of L<"&writeformat_with_reprocessing"> above.

C<&writedelimited_with_reprocessing> takes five arguments, the first three and the last of which are the same arguments passed to C<&writeformat_with_reprocessing>.  The fourth argument is a reference to an array holding a list of those columns selected for output upon which the user chooses to perform reprocessing.

    $outputfile = 'format003.txt';
    $delimiter = "\t";
    @reprocessing_info = qw( instructor timeslot );
    $dp1->writedelimited_with_reprocessing(
        $sorted_data, \@columns_selected, $outputfile, 
        \@reprocessing_info, $delimiter);

Taking the classroom scheduling problem presented above, C<&writedelimited_with_reprocessing> would produce output looking something like this:

    Monday, 9:00	Arithmetic	E Jones	4044	4044_11
    Monday, 9:00	Language Studies	T Wilson	4054	4054_11
    Monday, 10:00	Bible Study	M Eliade	4068	4068_12
    Monday, 10:00	Introduction to Computers	D Knuth	4086	4086_12
    Monday, 11:00	Psychology	A Adler	4077	4077_13
    Monday, 11:00	Social Science	T Jones	4044	4044_13
    Friday, 9:00	World History	H Wells	4052	4052_51
    Friday, 9:00	Music Appreciation	W Wilson	4044	4044_51

Usage of C<&writedelimited_with_reprocessing> requires that the administrator appropriately define C<&Data::Presenter::[Package1]::_reprocess_delimit> and C<&Data::Presenter::[Package1]::_init> subroutines in the invoking package, along with appropriate subroutines specific to each argument capable of being reprocessed.  Again, see the discussion in L<"&writeformat_with_reprocessing">.

I<&writedelimited_deluxe>:  C<&writedelimited_deluxe> is an advanced application of Data::Presenter and the reader may wish to skip this section until other parts of the module have been mastered.

C<&writedelimited_deluxe> completes the parallel structure between the C<&writeformat...> and C<&writedelimited...> families of Data::Presenter methods by enabling the user to have I<both> column headers (as in C<&writedelimited_plus_header>) and dynamic, 'just-in-time' reprocessing of data in selected fields (as in C<&writedelimited_with_reprocessing>).  Except for the name of the method called, the call to C<&writedelimited_deluxe> is the same as for C<&writedelimited_with_reprocessing>:

    $outputfile = 'format004.txt';
    $delimiter = "\t";
    @reprocessing_info = qw( instructor timeslot );
    $dp1->writedelimited_deluxe(
        $sorted_data, \@columns_selected, $outputfile, 
        \@reprocessing_info, $delimiter);

Using the classroom scheduling example from above,the output from C<&writedelimited_deluxe> might look like this:

    Timeslot	Group	Instructor	Room	GroupID
    Monday, 9:00	Arithmetic	E Jones	4044	4044_11
    Monday, 9:00	Language Studies	T Wilson	4054	4054_11
    Monday, 10:00	Bible Study	M Eliade	4068	4068_12
    Monday, 10:00	Introduction to Computers	D Knuth	4086	4086_12
    Monday, 11:00	Psychology	A Adler	4077	4077_13
    Monday, 11:00	Social Science	T Jones	4044	4044_13
    Friday, 9:00	World History	H Wells	4052	4052_51
    Friday, 9:00	Music Appreciation	W Wilson	4044	4044_51

As with C<&writedelimited_with_reprocessing>, C<&writedelimited_deluxe> requires careful preparation on the part of the administrator.  See the discussion under L<"&writeformat_with_reprocessing"> above.

I<&writeHTML>:  In its current formulation, C<&writeHTML> works very much like C<&writeformat_plus_header>.  It  writes data to an operator-specified HTML file and writes an appropriate header to that file as well.  C<&writeHTML> takes the same 4 arguments as C<&writeformat_plus_header>:  C<$sorted_data>, C<\@columns_selected>, C<$outputfile> and C<$title>.  The body of the resulting HTML file is more similar to a Perl format than to an HTML table.  (This may be upgraded to a true HTML table in a future release.)

=head2 Data::Presenter::Combo Objects

It is quite possible that we may have 2 or more different database reports which present data on the same underlying universe or population.  If these reports share a common index field which can be used to uniquely identify each entry in the underlying population, then we would like to be able to combine these sources, manipulate the data and re-output them via the simple and complex Data::Presenter output methods described in the L<"Synopsis"> above.

In other words, if we have already created

    my $dp1 = Data::Presenter::[Package1]->new(
        $sourcefile, \@fields,\%parameters, $index);
    my $dp2 = Data::Presenter::[Package2]->new(
        $sourcefile, \@fields,\%parameters, $index);
    ...
    my $dpx = Data::Presenter::[Package2]->new(
        $sourcefile, \@fields,\%parameters, $index);

we would like to be able to define an array of the objects we have created and construct a new object combining the first two in an orderly manner:

    my @objects = ($dp1, $dp2, ... $dpx);
    my $dpC = Data::Presenter::[some subclass]->new(\@objects);

We would then like to be able to call all the Data::Presenter sorting, selecting and output methods discussed above on C<$dpC> B<without having to re-specify C<$sourcefile>, C<\@fields>, C<\%parameters> or C<$index>>.

Can we do this?  Yes, we can.  More precisely, we can create I<two> new types of objects:  one in which the data entries comprise those entries found in I<each> of the original sources, and one in which the data entries comprise those found in I<any> of the sources.  In mathematical terms, we can create either a new object which represents the I<intersection> of the sources or one which represents the I<union> of the sources.  We call these as follows:

    my $dpI = Data::Presenter::Combo::Intersect->new(\@objects);

and

    my $dpU = Data::Presenter::Combo::Union->new(\@objects);

Note the following:

=over 4

=item *

For Combo objects, unlike all other Data::Presenter::[Package1] objects, we pass only one variable -- a reference to an array of Data::Presenter objects -- to the constructor instead of three.

=item *

Combo objects are always called from a subclass of Data::Presenter::Combo such as Data::Presenter::Combo::Intersect or Data::Presenter::Combo::Union.  They are not called from Data::Presenter::Combo itself.

=item *

The regular Data::Presenter objects which are selected to make up a Data::Presenter::Combo object must share a field which serves as the L<index field|"Index Field"> for each object.  This field must carry the same name in C<@fields> in the I<fields.data> configuration files corresponding to each of the objects, though that field does not have to appear in the same element position in C<@fields> in each such file.  Similarly, the parameters on the value side of C<%parameters> for the index field must be specified identically in each configuration file.  If these conditions are not met, a Data::Presenter::Combo object cannot be constructed and the program will die with an error message.

Let us illlustrate this point.  Suppose that we have two configuration files, I<fields1.data> and I<fields2.data>, corresponding to two different Data::Presenter objects, C<$obj1> and C<$obj2>.  For I<fields1.data>, we have:

    @fields = qw(lastname, firstname, cno);

    %parameters = (
        $fields[0]          => [14, 'U', 'a', 'Last Name'],
        $fields[1]          => [10, 'U', 'a', 'First Name'],
        $fields[2]          => [ 7, 'U', 'n', 'C No.'],
    );

    $index = 2;

For I<fields2.data>, we have:

    @fields = qw(cno, dateadmission, datebirth);

    %parameters = (
        $fields[0]          => [ 7, 'U', 'n', 'C No.'],
        $fields[1]          => [10, 'U', 'a', 'Date of Admission'],
        $fields[2]          => [10, 'U', 'a', 'Date of Birth'],
    );

    $index = 0;

Can C<$obj1> and C<$obj2> be combined into a Data::Presenter::Combo object?  Yes, they can.  C<'cno'> is named as the index field in each configuration file, and the values assigned to C<$fields[$index]> in each are identical:  C<[ 7, 'U', 'n', 'C No.']>.

Suppose, however, that we had a third configuration file, I<fields3.data>, corresponding to yet another Data::Presenter object, C<$obj3>.  If the contents of I<fields3.data> were:

    @fields = qw(cno, dateadmission, datebirth);

    %parameters = (
        $fields[0]          => [ 7, 'U', 'n', 'Serial No.'],
        $fields[1]          => [10, 'U', 'a', 'Date of Admission'],
        $fields[2]          => [10, 'U', 'a', 'Date of Birth'],
    );

    $index = 0;

then C<$obj3> could not be combined with either C<$obj1> or C<$obj2> because the elements of C<$parameters{$fields[$index]}> in C<$obj3> are not identical to those in the first two objects.

=back

Here are some things to consider in using Data::Presenter::Combo objects:

=over 4

=item *

Q:  What happens if C<$dp1> has entries not found in C<$dp2> (or vice versa)?

A:  It depends on whether you are interested in only those entries found in each of the data sources (the mathematical intersection of the sources) or those found in any of the sources (the mathematical union).  Only those entries found in I<both> C<$dp1> and C<$dp2> are included in a Data::Presenter::Combo::Intersect object.  But if you are constructing a Data::Presenter::Combo::Union object, any entry found in either source file will be represented in the Union object.  These properties would hold no matter how many sources you used as arguments.

=item *

Q:  What happens if both C<$dp1> and C<$dp2> have fields named, for instance, C<'lastname'>?

A:  Left-to-right precedence determines which object's C<'lastname'> field is entered into C<$dpC>.  Assuming that C<$dp1> is listed first in C<@objects>, I<all> the fields in C<$dp1> will appear in C<$dpC>.  Only those fields in C<$dp2> I<not> found in C<$dp1> will be added to C<$dpC>.  If, however, C<@objects> were defined as C<($dp2, $dp1)>, then C<$dp2>'s fields would have precedence over those of C<$dp1>.  If a C<$dp3> object were constructed based on yet another data source, only those fields entries I<not> found in C<$dp1> or C<$dp2> would be included in the Combo object -- and so forth.  This left-to-right precedence rule governs both the data entries in C<$dpC> as well as the selection, sorting and output characteristics.

=back

=head1 INTERNAL FEATURES

If you are not interested in the internals of Data::Presenter you may skip this portion.  As much as anything, the author has written it as a reminder to himself of what he had to learn in order to write this module.  This section is arranged more or less by subroutine.

=over 4

=item *

C<&new>:

=over 4

=item *

What happens with the information contained in L<C<@fields>|"@fields">, L<C<%parameters>|"%parameters"> and L<C<%index>|"%index">?  First, the two variables are established as package global variables (''C<our>'' variables in Perl 5.6) within the calling script when the F<fields.data> file containing them is imported into the calling script via Perl's C<do> function.  References to C<@fields>, C<%parameters> and C<$index> are then passed to the constructor.  The content of the variables is then validated to rule out duplicate field names in C<@fields> or inaccurate specification of the entries in C<%parameters> or the value of C<$index>.  An empty hash is blessed into the invoking class.  References to C<@fields>, C<%parameters> and C<$index> are then passed to the C<_init> method of the Data::Presenter subclass from which the constructor was invoked.

Now comes the interesting part.  The C<_init> method of the invoking subclass does not merely populate the object with data drawn from the L<source file|"Source">; it creates three special entries -- keyed by C<'fields'>, C<'parameters'> and C<'index'> -- whose values hold the content of C<@fields>, C<%parameters> and C<$index>.  The newly constructed object thus holds both the data extracted from the source file and the L<metadata|"Metadata"> specified by the user in L<F<fields.data>|"Preparation of Configuration File (fields.data)"> to enable Data::Presenter's sorting, selecting and output methods to work.  B<The data and the metadata travel together inside the object.>

Provided that the sorting, selecting and output methods are written correctly, this process will be transparent to the operator.  The advantage of this approach only becomes apparent when 2 or more Data::Presenter objects are combined into a new L<Data::Presenter::Combo|"Data::Presenter::Combo Objects"> object.  When we create such an object, we do not have to re-specify the source files or re-type C<@fields> and C<%parameters>.

=item *

The technique of blessing of an empty hash into the class and delegating the task of initializing the object to C<&_init> is taken directly from L<Object Oriented Perl|"REFERENCES">), Chap. 3.

    $self = bless {}, ref($class) || $class;
    ...
    $dataref = $self->_init($source, $fieldsref, $paramsref);
    ...
    %$self = %$dataref;

=item *

The information contained in the configuration files is imported into the main package via C<do> rather than C<require> because it reloads the content of C<$fieldsfile> better than C<require>.  See L<Camel|"REFERENCES">, p. 702.

=back

=item *

C<&_validate_fields>:  Confirms that there exist no duplicated fields in C<@fields>.  Called within the constructor.  Uses the C<%seen> recipe found at various points in the L<Perl Cookbook|"REFERENCES">, I<e.g.,> Recipe 4.6.

=item *

C<&_validate_params>:  Checks to ensure that user has correctly written C<%parameters>.  Called within the constructor.  First instance of a technique used frequently in Data::Presenter:  stepping through an array by index with a 'for' loop than by element with a 'foreach' loop.

=item *

C<&_validate_index>:  Checks to ensure that the value of C<$index> is a non-negative number less than or equal to the highest index number in C<@fields>.

=item *

C<&_make_labels_params>:  As part of the construction of each Data::Presenter object, we prepare two Data::Presenter package variables, C<%fp> and C<%fieldlabels>, which make the information found in F<fields.data> available to all methods.

=item *

C<&_count_engine>:  Code used internally by both C<&get_data_count> and C<&print_data_count> to count entries in a Data::Presenter object, excluding entries keyed by reserved words.

=item *

C<&select_rows>:  Takes the hash of arrays contained in a Data::Presenter object and extracts those needed for current presentation objective.  The actual extraction process depends on the database report used as source.  Hence, it is delegated to the corresponding Data::Presenter subclass.  To avoid unnecessary duplication of code in those subclasses, two subroutines (C<&_analyze_relation> and C<&_strip_non_matches>) are defined in Data::Presenter, then passed by reference to the subclasses when called within C<%select_rows>.  As C<&select_rows> is a method call on a Data::Presenter object, it has been discussed more fully L<above|"&select_rows">.

This subroutine is a violation of the principle of Laziness insofar as establishing selection criteria is better handled by SQL as in Perl DBI.  But it is consistent with the principle of Hubris:  I wanted to figure it out myself.

=item *

C<&_analyze_relation>:  This subroutine is called from within C<&_extract_rows>, which is in turn called from within C<&select_rows>.  C<&_analyze_relation> was created largely to make those two subroutines' code easier to read.  Its function is to process C<$relation>, one of the arguments passed to C<&select_rows>.  C<&_analyze_relation> internally defines several hashes which normalize the various ways in which the operator can define C<$relation> (I<e.g.,> C<lt>, C<<>, C<less than>, etc.).  These various coding styles are internally translated into forms appropriate for alphabetical, numerical and ASCII-betical sorts.

The code in C<&_analyze_relation> is independent of the characteristics of any database report used as a source file for the construction of a Data::Presenter object.  Hence, it is defined in F<Data::Presenter.pm>.  It is I<used>, however, inside C<&_extract_rows>, a subroutine which is dependent on the characteristics of that source file and which is found in all regular I<subclass> modules, I<e.g.,> in F<Data::Presenter::Census.pm>.  When C<&select_rows> internally calls C<&_extract_rows>, a I<reference> to C<&_analyze_relation> is passed to C<&_extract_rows> as an argument.

=item *

C<&_strip_non_matches>:  Like C<&_analyze_relation>, this subroutine is called from within C<&_extract_rows>, which is in turn called from within C<&select_rows>.  C<&_strip_non_matches> was created largely to make those two subroutines' code easier to read.  Once all three variables passed to C<&select_rows> have been analyzed (C<$column, $relation, \@choices>), C<&_strip_non_matches> performs the task of stripping out rows from the Data::Presenter's object's data which the operator does not want to have appear in the final output.

As with C<&_analyze_relation>, the code in C<&_strip_non_matches> is independent of the characteristics of any database report used as a source file for the construction of a Data::Presenter object.  Hence, it is defined in F<Data::Presenter.pm>.  It is I<used>, however, inside C<&_extract_rows>, a subroutine which is dependent on the characteristics of that source file and which is found in all regular I<subclass> modules, I<e.g.,> in F<Data::Presenter::Census.pm>.  When C<&select_rows> internally calls C<&_extract_rows>, a I<reference> to C<&_strip_non_matches> is passed to C<&_extract_rows> as an argument.

=item *

C<&_extract_rows>:  This subroutine is called from within C<&select_rows>; hence, its operation is not visible to the operator.  It is located within a particular Data::Presenter subclass package because its exact coding will depend on the data source.  In any such subclass, C<&_extract_rows> has the following internal structure:

=over 4

=item 1

Definition of variables:  invariant

=item 2

Analysis of C<$column>.  Check to see that column names requested are valid, I<i.e.,> exist in C<@fields>.  For convenience, store parametric data in C<$sortorder> and C<$sorttype>.

=item 3

Analysis of C<$relation>.  Invariant.  Accomplished by calling C<&_analyze_relation>, which is passed by reference to the subclass.  Returns a normalized version of C<$relation> and a reference to C<%gtlt_ops>.

=item 4

Analysis of C<@choices>.

=over 4

=item *

Definition of variables:  invariant.

=item *

Test to see whether number of choices is appropriate for type of relation:  invariant.

=item *

Data munging:  varies.

=item *

Populate C<@corrected>, C<%seen>:  invariant.

=item *

Strip out rows not needed, via sub passed by reference:  invariant.

=back

=back

=item *

C<&_validate_args>:  This subroutine is called within C<&sort_by_column> to confirm that each of the operator-defined arguments to C<&sort_by_column> is a valid name of a field (column) in the data source, C<i.e.,> that each such argument is an element of C<@fields>.  The coding is of the format, ''Is each element of array X found in array Y?'' suggested by L<I<Perl Cookbook>|"REFERENCES">.

=item *

C<&_build_sort_formula>:  This subroutine is called within C<&sort_by_column> to construct the formula by which that subroutine prioritizes sorting by columns, decides whether a particular column is sorted ascending or descending and decides whether a particular column is sorted alphabetically, ASCII-betically or numerically.  C<&_build_sort_formula> returns a reference to an anonymous subroutine, so that this is a procedure which follows the ''sort SUBNAME LIST'' approach to sorting (see C<perldoc perlfunc> or L<Camel|"REFERENCES">, pp. 789-790.  One peculiarity discovered while writing this subroutine is the fact that the anonymous subroutine which holds the sorting formula needs to return 1; otherwise a warning will be thrown.

=item *

C<&_formula_engine>:  Code twice used internally within C<&_build_sort_formula>.

=item *

C<&_key_constructor>:  This subroutine is called within C<&sort_by_column>.  It builds the ''LIST'' in the ''sort SUBNAME LIST'' described in the preceding description of C<&_build_sort_formula>.  For a given entry in the data, C<&_key_constructor> extracts values from the columns chosen by the operator in C<@columns_selected> and places them in an array.  To guarantee the uniqueness of each entry, it then tacks on the value from the column which serves as the index or unique ID for the database.  A reference to this array is then placed in another array which is the input argument for C<&_build_sort_formula>.  Hence, if:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');

then the intermediate arrays built by C<&_key_constructor> will look like:

    VASQUEZ LEONARDO 1970-15-23 456788 456788
    VASQUEZ JOAQUIN 1970-03-25 456789 456789
    VASQUEZ ALBERTO 1953-02-28 906786 906786

Note that for C<&_key_constructor> to work properly, we first exclude the metadata in the object's data keyed by C<'fields'>, C<'parameters'> and C<'index'>.

=item *

C<&writeformat>:  Opens a filehandle (arbitrarily named 'REPORT') to the operator-supplied output file.  It then loops through the data records.  An internal subroutine, C<&_format_picture_line>, calculates the format picture line.  That formula and the data for a given record are passed to Perl's C<formline> function.  The results are stored in the format accumulator variable C<$^A>.  The contents of C<$^A> are then printed to the filehandle.

=item *

C<&_format_picture_line>:  This subroutine is called within C<&writeformat> and C<&writeformat_plus_header>.  As its name suggests, it writes the picture line which is required for a Perl format.  For simplicity, all information is written left-justified (I<i.e.,> using C<<> in the picture line).

=item *

C<&writeformat_plus_header>:  With a little extra effort, you can write column headers for Perl-formatted data.  (See, again, C<perldoc perlform> or L<Camel|"REFERENCES">, Chap. 7.)  You have to give the format a title, prepare column headers, and then prepare a line (typically, of hyphens) which separates the headers from the data.  C<&writeformat_plus_header> accomplishes this task.  In addition to the work done by C<&writeformat>, it assigns the preparation of the title line, top argument line (column headers) and hyphen line to three internal subroutines, C<&_format_title>, C<&_format_argument_line_top2> and C<&_format_hyphen_line2>.

=item *

C<&_format_title>:  This subroutine is called within C<&writeformat_plus_header>.  It simply takes the value supplied by the operator in C<$title> as an argument to C<&writeformat_plus_header> and returns that value.  In earlier versions of Data::Presenter, the words ''Selected fields from:  '' were prepended to the value, but such hard coding is no longer seen as desirable.  The subroutine is retained in case a particular administrator wishes to affix some standardized text to all title lines in an instance of C<&writeformat_plus_header>.

=item *

C<&_format_argument_line_top2>:  This subroutine is called within both C<&writeformat_plus_header> and C<&writeHTML> and writes the header above the Perl-formatted data, left-justified and bottom-aligned.  It uses the information contained in C<@columns_selected> as well as information contained in C<%parameters> in F<fields.data>.  For each column selected for output, the subroutine takes the column title stored by the user in C<%parameters> and tries to fit that title into a column whose width was also stored by the user in C<%parameters>.  If the title consists of more than one word and will not fit into that space, the subroutine breaks the title on the wordspace and, in effect, prints the title bottom up, so that the table header is properly bottom-aligned.  If any word in the title exceeds the allocated column width, it is truncated to fit.

=item *

C<&_format_hyphen_line2>:  Like C<&_format_argument_line_top>, this subroutine is called within both C<&writeformat_plus_header> and C<&writeHTML> and writes the line of hyphens between the Perl-formatted header and the Perl-formatted data itself.  It calculates the number of hyphens needed to pad each column (except the last) with one additional space.

=back

=head1 ASSUMPTIONS AND QUALIFICATIONS

The program was created with Perl 5.6 on a Win32 system.  If there is sufficient interest, the author will adopt this program to earlier versions of Perl (I<e.g.,> replacing C<our> package global variables with the C<use vars> pragma).

As far as the author can tell, there is no Windows-specific code in the program, so it should port without difficulty to other platforms.

=head1 BUGS

Version 0.32 corrected the only known bug in Data::Presenter.  See L<"HISTORY AND DEVELOPMENT"> below.

=head1 HISTORY AND DEVELOPMENT

Data::Presenter versions 0.3 through 0.39 incorporate the following corrections and improvements over version 0.2 which was released 10/28/2001.

=over 4

=item *

Introduced C<$index> as one of the variables specified in I<fields.data>, imported into the main package and used as metadata inside the Data::Presenter object.  This eliminates some hard-coding inside subroutines C<&_init> and C<&_extract_rows> inside Data::Presenter::[subclass] packages.  It also necessitated a revision of C<&_build_sort_formula>, a large part of which was extricated into the separate subroutine C<&_formula_engine>.  This for the first time permitted on index keys which were not entirely numerical.  So now one can sort on, say, product serial numbers such as C<'24TY-789'>.

=item *

Established a package global hash C<%reserved> within I<Data::Presenter.pm> and C<%reserved_partial> within I<Data::Presenter::Combo::Intersect.pm> and I<Data::Presenter::Combo::Union.pm>.  These are hashes of words such as 'fields', 'parameters', 'index' and 'options' which are reserved for current or future use as keys in the hash blessed into the Data::Presenter object.  These keys generally have to be excluded when preparing Data::Presenter selection, sorting and output methods.  The coding for this exclusion is must easier if one can write:

    unless $reserved{$i} {
        # do something
    }

in contrast to the earlier:

    unless ($i eq 'fields' || $i eq 'parameters') {
        # do something
    }

=item *

C<&_format_picture_line> and C<&writeHTML> now format numerical columns flush-right.

=item *

A bug was fixed in C<&_build_sort_formula> that was causing 'HERNANDEZ' to precede 'HERNAN' in alphabetical sorts.  This was caused by the internal use of C<'|'> as the delimiter between array entries.  C<'|'> has a higher ASCII position than any alphabetical or numerical character.  Hence 'HERNANDEZ|' has a lower sorting value position than 'HERNAN|'.  This has been corrected by substituting C<'!'> as the delimiter, since C<'!'> has a lower ASCII value than any alphabetical or numerical character.  One side effect is that the character C<'!'> may not appear in data being input into Data::Presenter objects.

=item *

Clarified error messages in C<&_validate_fields> and C<&_analyze_relation>.

=item *

Up through v0.31, if the operator were to call C<&writeformat>, C<&writeformat_plus_header> or any combination thereof I<more than once> in a particular Perl script I<and if> in so doing the operator used any of the entries in C<@fields> I<more than once> as an element in C<@columns_selected>, then a warning would have been printed to STDERR stating:

    Variable "[$some_variable]" is not imported at
    (eval 2 [or higher number]) line [some_line_number].

To illustrate using the previously discussed examples:

    @columns_selected = ('lastname', 'firstname', 'datebirth', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);
    $outputfile = 'format01.txt';
    $dp1->writeformat($sorted_data, \@columns_selected, $outputfile);

    @columns_selected =
        ('lastname', 'firstname', 'dateadmission', 'cno');
    $sorted_data = $dp1->sort_by_column(\@columns_selected);
    $outputfile = 'format01.txt';
    $dp1->writeformat($sorted_data, \@columns_selected, $outputfile);

would have generated warnings resembling these:

    Variable "$lastname" is not imported at (eval 2) line 10.
    Variable "$firstname" is not imported at (eval 2) line 10.
    Variable "$cno" is not imported at (eval 2) line 10.

The author had run the program on live data many times and these warnings were never indicators of any incorrect output.  This warning message is discussed in C<perldoc perldiag> and on page 975 of L<Camel|"REFERENCES"> at 'Variable ''%s'' is not imported%s'.  That discussion implies that this warning would not have appeared if C<use strict> were not in effect.  However, the author tested this by calling C<no strict> before C<&writeformat> and returning to C<use strict> therefafter.  The warnings continued to be thrown.

The author then ventured to post the problematic code on comp.lang.perl.misc and had his hand properly slapped for improper use of symbolic references.  In the course of the slapping, the slapper, Mark-Jason Dominus, suggested using the Perl C<formline> function and format accumulator variable C<$^A> -- which internally power Perl formats -- instead of formats I<per se>.  At the same time, MJD discovered a bug in Perl 5.6 which was enabling the author to get valid data out of C<&writeformat> despite improper use of symbolic references.  MJD subsequently reported to the author that the bug was patched, but since C<formline> was working well and throwing no warning messages, he left well enough alone.  This turned out to be providential, as the C<$^A> was later to play a key role in the creation of C<&writeformat_with_reprocessing>.

=item *

In v0.33 two errors in the specification of C<%ne> within C<&_analyze_relation> were corrected.

=item *

Output method C<&print_with_delimiter> was added in v0.34 to permit the operator to select the delimiter characters used when printing to file.  This method is designed to be used in situations where the operator intends to further manipulate the data with a word processor function such as 'Convert text to tabs'.

=item *

Method C<&get_keys> was added in v0.35 to permit operator to get an ASCII-betically sorted list of the indices of the data records currently stored in the Data::Presenter::[Package1] object.

=item *

In v0.36 code which was common to both C<&print_to_screen> and C<&print_to_file> was abstracted and placed in an internal subroutine called C<_print_engine>.

=item *

C<&writeformat_with_reprocessing> was introduced in v0.38.  This format uses uses CPAN module List::Compare.  In order to extend the applicability of C<_validate_args> to cover C<&writeformat_with_reprocessing>, it was modified so as to receive an additional argument, a reference to package variable C<%fp>.  As C<&_format_argument_line> is no longer used within <&writeformat> or C&writeformat_plus_header>, it was deleted.  The superfluous and potentially confusing C<<LINK>> tag is removed from C<&writeHTML>.

=item *

Prior to v0.39 &_format_picture_line was being called with each iteration of the 'foreach' loop over the output records.  As this was unnecessary, it was pulled out of that loop.  The requirement that the title line in C<&writeformat_plus_header> and C<&writeHTML> be preceded by the words ''Selected fields from:  '' has been dropped.

=item *

v0.40:  In preparation for an eventual release to CPAN, the module was renamed Data::Presenter.

=item *

v0.41:  Running Data::Presenter on Perl 5.8 for the first time, received warnings in &full_report and &print_with_sep.  Fixed sigils.

=item *

v0.42:  In many of the format-related subroutines, I was passing C<@args> as an array.  Changed this so that I was passing by reference, which meant that in certain cases I could eliminate C<@args> as a variable inside a subroutine.  (However, in other cases it was retained inside the subroutine for clarity.)

=item *

v0.43 (1/22/03):  Corrected a typo in C<&_analyze_relation> which was causing incorrect results when C<$relation = '>='>.

=item *

v0.44 (2/9/03):  Tightened up coding in C<&get_data_count>, C<&print_data_count> and C<&_count_engine>.

=item *

v0.45 thru v0.47 (2/19-21/03):  Introduced and refined C<&writeformat_deluxe> to permit both a format header and dynamic reprocessing of fields (columns).  As this shared repeated code with C<&writeformat_with_reprocessing>, extracted redundant code and placed it in C<&_prepare_to_reprocess> and C<&_prepare_substring_data_and_picline>.  Also, spotted an error in C<&writeformat_with_reprocessing>:  C<$lc> a 2nd time where I should have called C<$lc1>.

=item *

v0.48 (2/22/03):  Combined C<&_prepare_to_reprocess> and C<&_prepare_substring_data_and_picline> into C<&_prepare_to_reprocess>.

=item *

v0.49 (2/22/03):  Used C<map {$_ =E<gt> 1} LIST> to populate hashes such as C<%reserved> rather than assigning C<=E<gt> 1> for each individual key.

=item *

v0.50 (2/23/03):  Corrected C<&writeHTML> to use C<_format_argument_line_top2> and C<_format_hyphen_line_2>.

=item *

v0.51 (2/24/03):  Made changes in C<&writeformat_with_reprocessing>, C<&writeformat_deluxe>, C<&_prepare_to_reprocess>, C<&Data::Presenter::_Assorted::_reprocessor> and C<&Data::Presenter::_Assorted::reprocess_timeslot> to accommodate correct output of times for those groups that start later in the timeslot, I<e.g.>, a 10:45 start for certain Ward 10 and 11 groups in the second timeslot of the day.

=item *

v0.52 (3/3/03):  Began working on subroutines which, like the C<&writeformat...> family of subroutines, will dynamically output data from selected fields (columns) in the database, but with the fields separated by an operator-supplied delimiter.  (The delimiter will frequently be C<\t> to take advantage of word processing program features which convert tab-delimited copy to tables.)  So far I have created C<&writedelimited> and C<&writedelimited_plus_header> and, for internal use within the latter, C<_format_argument_line_top3>.  Also, eliminated C<my $LR = $lc-E<gt>is_LsubsetR;> from C<_prepare_to_reprocess>, as C<$LR> is not used anywhere.

=item *

v0.53 & v0.54 (3/6/03):  Continued work on the C<&writedelimited...> family of subroutines, adding C<&writedelimited_with_reprocessing> and other subroutines needed in the C<&Data::Presenter::[package1]> invoking subclass.  In a manner similar to C<&writeformat_with_reprocessing>, C<&writedelimited_with_reprocessing> enables the operator to do 'just-in-time' reprocessing of the data elements which will be joined by C<$delimiter> in output.

=item *

v0.55 (3/6/03):  Continued work on the C<&writedelimited...> family of subroutines, adding C<&writedelimited_deluxe>.  In a manner similar to C<&writeformat_deluxe>, C<&writedelimited_deluxe> enables the operator to provide column headers and do 'just-in-time' reprocessing of the data elements which will be joined by <$delimiter> in output.  Unlike C<&writeformat_deluxe>, however, C<&writedelimited_deluxe> is meant to provide input to a word processing program's 'convert text to table' feature, in which case a title line would be superfluous.  Hence C<&writedelimited_deluxe> does not take C<$title_raw> as an argument.

=item *

v0.56 (3/7/03):  Provided documentation for C<&writedelimited...> family of subroutines.

=item *

v0.57 (3/15/03):  Corrected error in header of C<&writeHTML>.  Included a carp warning in C<&new> to warn the operator if, after initialization, the Data::Presenter::[package1] object contains zero elements (other than metadata).  Similarly modified C<&_count_engine> to return 0 in same situation.

=item *

v0.58 (3/26/03):  Clarified the error message in C<&_validate_args> to indicate which arguments passed to C<&sort_by_column> are invalid.

=item *

v0.60 (4/6/03):  Preparation for distribution to CPAN.

=item *

v0.61 (4/12/03):  Corrected failure to list F<Data::Presenter::Combo> in MANIFEST.

=back

Possible future lines of development include:

=over 4

=item *

C<&writeHTML> could be rewritten or supplemented by a method which writes a true HTML table.

=item *

And if we were really I<au courant>, we'd have a C<&writeXML> method!

=item *

The hashes defined within C<&_analyze_relation> which offer the operator flexibility in defining C<$relation> could be expanded to include expressions in any human language using the ASCII character set.

=item *

Develop a Perl::TK GUI to make it easier for operators to build and run Data::Presenter scripts.

=item *

Add an additional, optional element to the arrays on the value side of C<%parameters>:  the name of a subroutine used by the administrator to massage the data entering through a given field.  It is not clear yet how this would work with a Data::Presenter::Combo object.

=back

=head1 REFERENCES

The fundamental reference for this program is, of course, the Camel book:  Larry Wall, Tom Christiansen, Jon Orwant.  <I<Programming Perl>, 3rd ed.  O'Reilly & Associates, 2000, L<http://www.oreilly.com/catalog/pperl3/>.

A careful reading of the code will tell any competent Perl hacker that many tricks were taken from the Ram book:  Tom Christiansen & Nathan Torkington. I<Perl Cookbook>.  O'Reilly & Associates, 1998, L<http://www.oreilly.com/catalog/cookbook/>.

The object-oriented programming skills needed to develop this program were learned via extensive re-reading of Chapters 3, 6 and 7 of Damian Conway's I<Object Oriented Perl>.  Manning Publications, 2000, L<http://www.manning.com/Conway/index.html>.

This program goes to great length to follow the principle of 'Repeated Code is a Mistake' L<http://www.perl.com/pub/a/2000/11/repair3.html> -- a specific application of the general Perl principle of Laziness.  The author grasped this principle best following a 2001 talk by Mark-Jason Dominus L<http://perl.plover.com/> to the New York Perlmongers L<http://ny.pm.org/>.

Most of the code in the C<_init> subroutines was written before the author read I<Data Munging with Perl> L<http://www.manning.com/cross/index.html> by Dave Cross.  Nonetheless, that is an excellent discussion of the problems involved in understanding the structure of data sources.

The discussion of bugs in this program benefitted from discussions on the Perl Seminar New York  mailing list L<http://groups.yahoo.com/group/perlsemny>, particularly with Martin Heinsdorf.

=head1 AUTHOR

James E. Keenan (jkeenan@cpan.org).

Creation date:  October 25, 2001.  Last modification date:  April 13, 2003.  Copyright (c) 2001-2003 James E. Keenan.  United States.  All rights reserved.

All data presented in this documentation or in the sample files in the archive accompanying this documentation are dummy copy.  The data was entirely fabricated by the author for heuristic purposes.  Any resemblance to any person, living or dead, is coincidental.

This is free software which you may distribute under the same terms as Perl itself.

=cut


