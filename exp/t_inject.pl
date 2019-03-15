use strict;
use warnings;
use Data::Dump qw/pp dd/;


use lib '../lib';

#--- swap

use Filter::Inject
  swap => sub {
      $swap::args = \@_;

      return <<'__EXPANSION__';
       $swap::tmp       = $swap::args->[0];
       $swap::args->[0] = $swap::args->[1];
       $swap::args->[1] = $swap::tmp;
__EXPANSION__

  };


my ($a,$b) = (1,2);
use swap $a,$b;
warn pp [$a,$b];


#  --- dumper

use Filter::Inject
  pp => sub {
     return undef if $pp::OFF;
     my $expansion = "";
     for my $var (@_) {
        $expansion .= qq~
        warn '#pp $var => ', pp($var), "\n";
        ~;
     }
     return $expansion;
  };

my @x=[$a,$b];
use pp qw/@x $a $b/;



#  --- conditonal expand

BEGIN {$pp::OFF = 1}

use pp '[@x,$a,$b]';                    # string ist blÃ¶d
BEGIN {$pp::OFF = 0}



# --- plain inject

use Filter::Inject
  inject => sub {
     return join ";",@_;
  };

sub some_code {
   return
     'warn "INJECTING SOME CODE"',
}

use inject some_code();


# --- signature parsing

use Filter::Inject
  _ => sub {
     my $expansion =
       "warn 'too many arguments' if \@_ >".@_.";\n";

     my @args = @_;
     $expansion
       .= join "; ",
       map { s(=)(= shift //) or $_.='= shift;'; "my $_" }
       @args ;

     # $expansion .=
     #   q(use pp '[$x,$y,$z]';);

     #warn $expansion;

     return $expansion;
  };


sub test {
   use _ qw($x="X" $y="Y" $z);
}

# you can even slice lists ...

# sub defaults {
#   my ($d1,$d2,$d3) = ( @_ , (1,2,3)[@_ .. 2] );
#   print("$d1 $d2 $d3\n");
# }


test();
test(1);
test(1,2);
test(1,2,3);
test(1,2,3,4);

#  --- dual

use Filter::Inject
  dual => sub {
     my @symbols = @_;
     use Readonly;

     my $expansion;
     for (@symbols) {
        if ( my ($sigil,$ident) = m/([@%])(\w+)/ ) {
           #$expansion .= "my $_; my \$$ident = \\$_;\n";
           # TODO make $scalar readonly
           $expansion .= "my $_; Readonly my \$$ident => \\$_;\n";
        } else {
           die "Unknown var symbol $_";
        }
     }
     warn $expansion;

     return $expansion;
  };

# for aliasing @ and % to scalar
 # #     my $expansion = << "__CODE__";
 #     {
 #        use feature 'refaliasing';
 #        no warnings "experimental::refaliasing";
 #     }
 #     #__CODE__




use dual '@A','%H';

@A=(1..4);
pp $A;
%H= (a=>1,b=>2);
pp $H;
#$H={a=>2};








