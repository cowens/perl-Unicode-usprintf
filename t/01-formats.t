#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'Unicode::usprintf' ) || print "Bail out!\n";
}

# %p and $n have testing problems
my @simple_formats = qw(
	%% %c %s %d %u %o %x %e %f %g
	%X %E %G %b %B
	%i %D %U %O %F
);

for my $f (@simple_formats) {
	is usprintf($f, 10.765), sprintf($f, 10.765), $f;
}

done_testing;

__DATA__

FIXME: make random formats

sub random_format_string {
}

sub random_format {
	my $format_parameter_index = int rand 2 ? int rand 3 : "";



	my $min_width       = int rand 2;
	my $min_width_index = $min_width && int rand 2 ? 6 + int rand 3 : 0;
	my $min_width_value = int rand 10;

	my $max_width       = int rand 2;
	my $max_width_index = $max_width && int rand 2 ? 9 + int rand 3 : 0;
	my $max_width_value = int rand 10;

	my $size = int rand 2 ? ( qw/ hh h j ll l q L t z / )[rand 9] : 0;

	my $conversion = ( qw/ % c s d u o x e f g X E G b B i D U O F / )[rand 19];

	my $format = "%";
	my @args;

	# use a parameter index
	if (int rand 2) {
		my $index = int rand 3;

		$format .= "$index\$";
		push @args, map { 5 + rand() } 1 .. 3;
	}

	#flags
	$format .= join "", map { ( " ", qw/ # + - 0 / )[rand 5] } 0 .. int rand 6

	# use a vector flag
	if (int rand 2) {
		# use an indexed vector separator
		if (int rand 2) {
			my $vector_index = @args + int rand 3;

		my $vector_string = int rand 2 ? ":" : "<->";


