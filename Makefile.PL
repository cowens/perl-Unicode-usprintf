use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Unicode::usprintf',
    AUTHOR           => q{Chas. Owens <chas.owens@gmail.com>},
    VERSION_FROM     => 'lib/Unicode/usprintf.pm',
    ABSTRACT_FROM    => 'lib/Unicode/usprintf.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
	'Unicode::GCString'   => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Unicode-usprintf-*' },
);
