use lib '../lib';

my ($x,$y);
BEGIN {($x,$y)=(0,42)}

use Filter::Inject $x,$y; warn "after same line";
warn "+1 line";
warn "+2 line";
warn "$x $y";
