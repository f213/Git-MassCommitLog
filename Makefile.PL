use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Git::MassCommitLog',
    AUTHOR              => q{Fedor A Borshev <fedor@shogo.ru>},
    VERSION_FROM        => 'lib/Git/MassCommitLog.pm',
    ABSTRACT_FROM       => 'lib/Git/MassCommitLog.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Badger::Base' => 0,
	'IO::Dir' => 0,
	'Class::Date' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Git-MassCommitLog-*' },
);
