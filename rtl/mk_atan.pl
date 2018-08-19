# Create table for arctan()

use strict;
use warnings;
use POSIX;
use Math::Trig;

my $width      = 17;
my $iterations = $width + 2;
my $guard_bits = $iterations - 1;
# my $guard_bits = ceil($iterations / 2);
# my $guard_bits = ceil(log($iterations) / log(2));


my @values;
my $atan_width = $width + $guard_bits;
for my $i (0..$iterations - 1) {
    push(@values, sprintf("%d'd%.0f",  $atan_width, (2**($width + $guard_bits - 1) / pi) * atan(2**(-$i))));
}

print "/* arctan() for $iterations iterations */\n";
print "const bit signed [width + guard_bits - 1:0] atan_z[iterations] = '{";
print join(', ', @values) . "};\n";
