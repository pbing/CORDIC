# Create table for arctan()

use strict;
use warnings;
use POSIX;
use Math::Trig;

my $width      = 16;
my $iterations = $width + 1;
my $guard_bits = ceil(log($iterations) / log(2));

my @values;
for my $i (0..$iterations - 1) {
    push(@values, sprintf("%.0f", (2**($width + $guard_bits - 3) / pi) * atan(2**(-$i))));
}

print "/* arctan() for $iterations iterations */\n";
print "const bit signed [width + guard_bits - 3:0] atan_z[iterations] = '{";
print join(', ', @values) . "};\n";
