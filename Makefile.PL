use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Presenter',
    'VERSION_FROM'	=> 'lib/Data/Presenter.pm',
    'ABSTRACT_FROM'	=> 'lib/Data/Presenter.pm',
    'PREREQ_PM'		=> { 
        List::Compare           => 0.15,
        IO::Capture             => 0.05,
        IO::Capture::Extended   => 0.09,
        Tie::File               => 0,
    }, 
);

