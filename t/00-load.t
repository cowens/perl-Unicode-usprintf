#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Unicode::usprintf' ) || print "Bail out!\n";
}

diag( "Testing Unicode::usprintf $Unicode::usprintf::VERSION, Perl $], $^X" );
