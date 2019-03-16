use strict;
use warnings;
use Data::Dump qw/pp dd/;


use lib '../lib';



sub get_args {
   my $multi_lines = "";
   my $args;
   my $i = -1;
   my $a_lines = \@Filter::Inject::source;
   my $call_line = (caller(2))[2];
   warn "$call_line - ", 0+@$a_lines, "\n";
   for my $i (1..@$a_lines) {
      my $previous_line = $a_lines->[- $i];
      chomp($previous_line);
      $multi_lines = "$previous_line$multi_lines";

      last if
        ($args) = $multi_lines =~ m/use\s+_args_\s*(.*?)\s*;/s ;
   }
   #warn "<<<$multi_lines>>>\n";
   $args = $1                           # strip surrounding parens
     if $args =~ m/^ \( \s* (.*?) \s* \) $/x;
   return $args;
}






use Filter::Inject
  _args_ => sub {
     my $args_str = get_args(); 
     return <<"__EXPANSION__";
        warn '<<$args_str>>'."\n";
__EXPANSION__
  };


use _args_ $a,$b;
use _args_ ($a,$b);
use
  _args_
  $a,$b;

do{
   use _args_ $a,$b
}
;



