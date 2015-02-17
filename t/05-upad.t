#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Unicode::usprintf qw/upad/;

is upad("e\x{301}", 10, undef, "*", "left"), "e\x{301}*********";
is upad("e\x{301}", 10, undef, "*", "right"), "*********e\x{301}";
is upad("e\x{301}", 9, undef, "*", "center"), "****e\x{301}****";
is upad("e\x{301}", 10, undef, "*", "center"), "****e\x{301}*****";

is upad("e\x{301}e\x{301}", 1), "e\x{301}e\x{301}";
is upad("e\x{301}e\x{301}", 3), "e\x{301}e\x{301} ";
is upad("e\x{301}e\x{301}", 3, 2), "e\x{301}e\x{301} ";
is upad("e\x{301}e\x{301}", 3, 1), "e\x{301}  ";

is upad("abcd"), "abcd";
is upad("e\x{301}" x 9, undef, 3), "e\x{301}" x 3;

is upad("abc", 5.5), "abc  ";
is upad("abc", 5.5, undef, undef, "center"), " abc ";
is upad("a" x 10, undef, 5.5), "a" x 5;

done_testing;
