use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Presenter',
    'VERSION_FROM'	=> 'Presenter.pm', # finds $VERSION
    'PREREQ_PM'		=> { List::Compare => 0.15 }, 
);

