package Unicode::usprintf;

use v5.10;
use feature ':5.10';
use strict;
use warnings;
use utf8;

use Unicode::GCString;

require Exporter;
our @ISA       = qw(Exporter);

our @EXPORT    = qw/usprintf/;
our @EXPORT_OK = qw/upad/;

my $extract_sprintf_formats = qr{
	%
	(?: (?<format_parameter_index> [1-9][0-9]* ) \$ )?

	(?<flags>
		(?:
			[#] | # prefix with base for binary, octal, and hex
			[+] | # prefix with + for positive numbers
			[ ] | # prefix with a space for positive numbers
			[0] | # pad with zeros
			[-]   # left justify
		)*
	)

	(?:
		(?:
			(?<use_vector_index> [*] )
			(?<vector_index> [1-9][0-9]* )?
		)?
		(?<vector> v )
	)?

	(?:
		(?<use_min_width_index> [*])
		(?: (?<min_width_index> [1-9][0-9]* ) \$ )?
	)?

	(?<min_width> [1-9]+[0-9]* )?

	(?:
		[.]
		(?:
			(?<max_width> [0-9]+ ) |
			(?:
				(?<use_max_width_index> [*])
				(?: (?<max_width_index> [1-9][0-9]* ) \$ )?
			)
		)
	)?

	(?<size>
		hh | # char
		h  | # short
		j  | # intmax_t
		ll | # long long
		l  | # long
		q  | # long long
		L  | # long long
		t  | # ptrdiff_t
		z    # size_t size
	)?

	(?<conversion> 
		% | # literal %
		c | # character
		s | # string
		d | # signed integer
		u | # unsigned integer
		o | # octal
		x | # hexadecimal lowercase
		e | # scientific notation
		f | # fixed decimal
		g | # %e or %f notation depending on size
		X | # hexadecimal uppercase
		E | # %e, but E is uppercase
		G | # %g, but E is uppercase
		b | # binary
		B | # binary uppercase
		p | # pointer
		n | # internal size
		i | # %d
		D | # %ld
		U | # %lu
		O | # %lo
		F | # %f
		S   # unicode string
	)
}x;

=head1 NAME

Unicode::usprintf - Provides an sprintf interface that handles Unicode combining characters properly

=head1 VERSION

Version 0.0.2

=cut

use version; our $VERSION = version->declare("v0.0.2");

=head1 SYNOPSIS

Unicode::usprintf exports usprintf, a function that behaves exactly like
sprintf, but has a %S format that correctly handles Unicode combining
characters.  It also can export upad, a function that can pad strings
containing combining characters in a variety of ways.

   use Unicode::usprintf;

   # $wrong is now "[  e\x{301}]"
   my $wrong = usprintf "[%4s]", "e\x{301}";

   # $right is now "[   e\x{301}]"
   my $right = usprintf "[%4S]", "e\x{301}";

=head1 SUBROUTINES

=head2 upad STRING, MIN, MAX, PAD_CHAR, JUSTIFY

The upad function will pad a string with the PAD_CHAR (defaults to space) if
its length is less than MIN.  It will truncate the string if its length is
greater than MAX. If MAX is undef, it is the length of the string. The
justification (default "left") is one of "left", "right", or "center".

=cut

sub upad {
	my ($s, $min, $max, $pad_char, $justify) = @_;

	my $gcs    = Unicode::GCString->new($s);
	my $length = $gcs->columns;

	$min      //= 0;
	$max      //= $length;
	$pad_char //= " ";
	$justify  //= "left";

	if ($length > $max) {
		$gcs    = $gcs->substr(0, $max);
		$length = $max;
	}

	my $pad_length = $min - $length;

	if ($justify eq "center") {
		my $left  = $pad_char x int($pad_length/2);
		my $right = $pad_char x int($pad_length/2+.5);

		return "$left$gcs$right";
	}

	my $padding = $pad_char x $pad_length;

	return "$gcs$padding" if $justify eq 'left';
	return "$padding$gcs" if $justify eq 'right';
}

=head2 usprintf FORMAT, ARGS

The usprintf function behaves identically to sprintf, but it has an extra
format: %S.  It behaves exactly like %s, but correctly handles Unicode
combining characters.

=cut

sub _index {
	my ($parsed_format, $args, $auto_index_ref, $k) = @_;

	return $args->[$parsed_format->{$k} - 1] if exists $parsed_format->{$k};
	return $args->[$$auto_index_ref++];
}

sub usprintf($@) {
	my ($format, @args) = @_;

	#save a copy to modify so the regex doesn't get confused
	my $modified_format = $format;

	#index of the current arg if the format parameter index isn't used
	my $auto_index = 0;
	my $substr_modifier = 0; #amount the string has shrunk
	while ($format =~ /$extract_sprintf_formats/g) {
		my $min_width;
		my $max_width;
		my $vector_join;

		# if the format has the vector flag set and is an s or S
		# conversion then do nothing because that is what sprintf does
		if ($+{vector} and ($+{conversion} eq "s" or $+{conversion} eq "S")) {
			next;
		}	

		# we must calculate all of these because they can 
		# have an effect on the auto_index
		{
			my @b = (\%+, \@args, \$auto_index);
			$vector_join = _index(@b, "vector_index")    if $+{use_vector_index};
			$min_width   = _index(@b, "min_width_index") if $+{use_min_width_index};
			$max_width   = _index(@b, "max_width_index") if $+{use_max_width_index};
		}

		my $index = exists $+{format_parameter_index}
			? $+{format_parameter_index} - 1
			: $auto_index++;

		# if it isn't a Unicode string, then we don't have to do
		# anything more, the real sprintf will handle the rest
		next unless $+{conversion} eq "S";

		$min_width   //= $+{min_width};
		$max_width   //= $+{max_width};
		$vector_join //= ".";

		my %flags = map { $_ => 1 } split //, $+{flags} // ""; 

		my $pad_char = $flags{0} && ! $flags{"-"} ? 0 : " ";

		my $justify = $flags{"-"} ? "left" : "right";

		$args[$index] = upad $args[$index], $min_width, $max_width, $pad_char, $justify;

		# modify the format string to so it works with
		# traditional sprintf, remove all formatting 
		# info, we are going to do that ourselves
		my $format_substr_length = $+[0] - $-[0];

		my $format = "%" . ($index + 1) . '$s';

		substr $modified_format, $-[0] - $substr_modifier, $format_substr_length, $format;

		$substr_modifier += $format_substr_length - length $format;
	}

	return sprintf $modified_format, @args;
}

=head1 AUTHOR

Chas. J. Owens IV, C<< <chas.owens at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-unicode-usprintf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Unicode-usprintf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Unicode::usprintf

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unicode-usprintf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Unicode-usprintf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Unicode-usprintf>

=item * Search CPAN

L<http://search.cpan.org/dist/Unicode-usprintf/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Chas. J. Owens IV.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Unicode::usprintf
