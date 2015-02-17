#!./perl -w

# Tests for usprintf that do not fit the format of usprintf.t.

use Unicode::usprintf;

BEGIN {
    chdir 't' if -d 't';
}   

use strict;
use Config;
use Test::More;

is(
    usprintf("%.40g ",0.01),
    usprintf("%.40g", 0.01)." ",
    q(the usprintf "%.<number>g" optimization)
);
is(
    usprintf("%.40f ",0.01),
    usprintf("%.40f", 0.01)." ",
    q(the usprintf "%.<number>f" optimization)
);

# cases of $i > 1 are against [perl #39126]
for my $i (1, 5, 10, 20, 50, 100) {
    chop(my $utf8_format = "%-*s\x{100}");
    my $string = "\xB4"x$i;        # latin1 ACUTE or ebcdic COPYRIGHT
    my $expect = $string."  "x$i;  # followed by 2*$i spaces
    is(usprintf($utf8_format, 3*$i, $string), $expect,
       "width calculation under utf8 upgrade, length=$i");
}

# check simultaneous width & precision with wide characters
for my $i (1, 3, 5, 10) {
    my $string = "\x{0410}"x($i+10);   # cyrillic capital A
    my $expect = "\x{0410}"x$i;        # cut down to exactly $i characters
    my $format = "%$i.${i}s";
    is(usprintf($format, $string), $expect,
       "width & precision interplay with utf8 strings, length=$i");
}

# check overflows
for (int(~0/2+1), ~0, "9999999999999999999") {
    is(eval {usprintf "%${_}d", 0}, undef, "no usprintf result expected %${_}d");
    like($@, qr/^Integer overflow in format string for sprintf /, "overflow in usprintf");
}

# check %NNN$ for range bounds
{
    my ($warn, $bad) = (0,0);
    local $SIG{__WARN__} = sub {
	if ($_[0] =~ /missing argument/i) {
	    $warn++
	}
	else {
	    $bad++
	}
    };

    my $fmt = join('', map("%$_\$s%" . ((1 << 31)-$_) . '$s', 1..20));
    my $result = usprintf $fmt, qw(a b c d);
    is($result, "abcd", "only four valid values in $fmt");
    is($warn, 36, "expected warnings");
    is($bad,   0, "unexpected warnings");
}

{
    foreach my $ord (0 .. 255) {
	my $bad = 0;
	local $SIG{__WARN__} = sub {
	    if ($_[0] !~ /^Invalid conversion in sprintf/) {
		warn $_[0];
		$bad++;
	    }
	};
	my $r = eval {usprintf '%v' . chr $ord};
	is ($bad, 0, "pattern '%v' . chr $ord");
    }
}

sub myusprintf_int_flags {
    my ($fmt, $num) = @_;
    die "wrong format $fmt" if $fmt !~ /^%([-+ 0]+)([1-9][0-9]*)d\z/;
    my $flag  = $1;
    my $width = $2;
    my $sign  = $num < 0 ? '-' :
		$flag =~ /\+/ ? '+' :
		$flag =~ /\ / ? ' ' :
		'';
    my $abs   = abs($num);
    my $padlen = $width - length($sign.$abs);
    return
	$flag =~ /0/ && $flag !~ /-/ # do zero padding
	    ? $sign . '0' x $padlen . $abs
	    : $flag =~ /-/ # left or right
		? $sign . $abs . ' ' x $padlen
		: ' ' x $padlen . $sign . $abs;
}

# Whole tests for "%4d" with 2 to 4 flags;
# total counts: 3 * (4**2 + 4**3 + 4**4) == 1008

my @flags = ("-", "+", " ", "0");
for my $num (0, -1, 1) {
    for my $f1 (@flags) {
	for my $f2 (@flags) {
	    for my $f3 ('', @flags) { # '' for doubled flags
		my $flag = $f1.$f2.$f3;
		my $width = 4;
		my $fmt   = '%'."${flag}${width}d";
		my $result = usprintf($fmt, $num);
		my $expect = myusprintf_int_flags($fmt, $num);
		is($result, $expect, qq/usprintf("$fmt",$num)/);

	        next if $f3 eq '';

		for my $f4 (@flags) { # quadrupled flags
		    my $flag = $f1.$f2.$f3.$f4;
		    my $fmt   = '%'."${flag}${width}d";
		    my $result = usprintf($fmt, $num);
		    my $expect = myusprintf_int_flags($fmt, $num);
		    is($result, $expect, qq/usprintf("$fmt",$num)/);
		}
	    }
	}
    }
}

# test that %f doesn't panic with +Inf, -Inf, NaN [perl #45383]
foreach my $n (2**1e100, -2**1e100, 2**1e100/2**1e100) { # +Inf, -Inf, NaN
    eval { my $f = usprintf("%f", $n); };
    is $@, "", "usprintf(\"%f\", $n)";
}

# test %ll formats with and without HAS_QUAD
eval { my $q = pack "q", 0 };
my $Q = $@ eq '';

my @tests = (
  [ '%lld' => [qw( 4294967296 -100000000000000 )] ],
  [ '%lli' => [qw( 4294967296 -100000000000000 )] ],
  [ '%llu' => [qw( 4294967296  100000000000000 )] ],
  [ '%Ld'  => [qw( 4294967296 -100000000000000 )] ],
  [ '%Li'  => [qw( 4294967296 -100000000000000 )] ],
  [ '%Lu'  => [qw( 4294967296  100000000000000 )] ],
);

for my $t (@tests) {
  my($fmt, $nums) = @$t;
  for my $num (@$nums) {
    my $w; local $SIG{__WARN__} = sub { $w = shift };
    is(usprintf($fmt, $num), $Q ? $num : $fmt, "quad: $fmt -> $num");
    like($w, $Q ? qr'' : qr/Invalid conversion in sprintf: "$fmt"/, "warning: $fmt");
  }
}

# Overload count
package o { use overload '""', sub { ++our $count; $_[0][0]; } }
my $o = bless ["\x{100}"], o::;
() = usprintf "%1s", $o;
is $o::count, '1', 'sprinf %1s overload count';
$o::count = 0;
() = usprintf "%.1s", $o;
is $o::count, '1', 'sprinf %.1s overload count';

done_testing;
