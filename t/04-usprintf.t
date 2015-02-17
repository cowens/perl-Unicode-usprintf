#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'Unicode::usprintf' ) || print "Bail out!\n";
}

# parameter index

is usprintf('%4$S', "a" .. "z"), "d";

is usprintf('%S %S %S %1$S', "a" .. "z"), "a b c a";

is usprintf('%s %5$s %1$S %2$S %s', "a" .. "z"), "a e a b b";

# flags

is usprintf("%-5S", "e\x{301}"), "e\x{301}    ";
is usprintf("%0-5S", "e\x{301}"), "e\x{301}    ";
is usprintf("%05S", "e\x{301}"), "0000e\x{301}";

# vector

{
	# I don't see what can be done about this warning
	# you shouldn't get it under normal circumstances
	# only when you are doing something stupid that
	# sprintf doesn't like anyway
	local $SIG{__WARN__} = sub { ok $_[0] =~ /Invalid conversion in sprintf/ };
	is usprintf('%vS', "a" .. "z"), "%vS";
}

# min

is usprintf("%5S", "1"), "    1";
is usprintf("%5S", "e\x{301}"), "    e\x{301}";
is usprintf("%*S", 5, "e\x{301}"), "    e\x{301}";
is usprintf('%*2$S', "e\x{301}", 5), "    e\x{301}";

# max

is usprintf("%.2S", "123"), "12";
is usprintf("%.2S", "e\x{301}e\x{301}\x{302}\x{303}e\x{301}"), "e\x{301}e\x{301}\x{302}\x{303}";
is usprintf("%.*S", 2, "e\x{301}e\x{301}\x{302}\x{303}e\x{301}"), "e\x{301}e\x{301}\x{302}\x{303}";
is usprintf('%.*2$S', "e\x{301}e\x{301}\x{302}\x{303}e\x{301}", 2), "e\x{301}e\x{301}\x{302}\x{303}";

done_testing;
