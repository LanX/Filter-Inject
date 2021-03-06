package Filter::Inject;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dump qw/pp dd/;

use Filter::Util::Call ;

=head1 NAME

Filter::Inject - Inject code at compile time.

=head1 VERSION

Version 0.0.20

=cut

our $VERSION = '0.0.20';


=head1 WARNING: THIS IS EXPERIMENTAL CODE!!!

The API is evolving and may change at any moment!


=head1 SYNOPSIS

    use Filter::Inject  macro => sub { return "CODE" };

Installs a macro NAME as a pseudo module into @INC with an asociated sub-ref as callback.

Using

    use macro LIST;

will inject the code-string returned by the $subref->(LIST) at
compile-time and compile it right away.


=head1 EXAMPLE

    #--- define swap macro

    use Filter::Inject
      swap => sub {
         $swap::args = \@_;
         return <<'__EXPANSION__';
           $swap::tmp         = $swap::args->[0];
           $swap::args->[0] = $swap::args->[1];
           $swap::args->[1] = $swap::tmp;
    __EXPANSION__
      };

    #--- apply swap macro
    my ($a,$b) = (1,2);
    use swap $a,$b;
    warn pp [$a,$b];


Output

    [2, 1] at d:/LanX/perl-projects/Filter-Inject/exp/t_inject.pl line 23, <DATA> line 36.

For further examples see exp/t_inject.pl


=head1 DESCRIPTION

This is a prove of concept to implement a "swap" macro.


Here code is injected at compile time to swap the two arguments passed
after the use.

Care is taken to adjust the line-numbers after the injection, such
that the warn, the debugger and other tools don't get confused.
Check line number warnings to see what I mean.

Since a MACRO are implemented are technically modules they have an own
namespace in the package ::MACRO. This is used here in the example for
U<hygienic variables> which can't collide with the code surrounding
the injection.

Especially C<$swap::args = \@_> is a reference to aliases of the
passed arguments, hence making the swap possible.



=head1 CAVEATS

The new code is only injected after the line with the use statement.
I.e. code immidiately following the use statement in the same line will be
executed before the injected code.





=head1 EXPORT

No exports yet



=head1 Functions & Macros

=head2 use inject LIST;

Default macro to inject LIST right away.

=head2 upject(LIST)

Like inject, but when used inside an =import= method it's 
injecting into callers scope right after the use.


=cut

my $module_code = join "", <DATA>;

sub import {

   my $pkg = shift;
   unless (@_) {
      @_ =  ( inject => sub {
                 return join ";",@_;
              }
            );
   }

   my ($macro_name, $macro_code) = @_;

   my $module_code
     = "package $macro_name;\n"
     . $module_code;

   # warn pp $module_code;

   unshift @INC,
     pseudo_module_hook($macro_name,$module_code);

   no strict "refs";
   *{"${macro_name}::macro"} = $macro_code;

   my $call_line = (caller)[2];
   our @source = (undef) x $call_line; # previous source lines are unknown
   add_read_filter(\@source);

}



sub pseudo_module_hook {
   my ($module_name,$module_code)=@_;

   # --- loader hook for @INC
   my $c_loader = sub
     {
        my ( $this_sub, $file_name ) = @_;

        if ( $file_name eq $module_name.'.pm' ) {

           my $pre = '';
           #$pre .= qq{warn '*** Importing inject ***';};
           $pre .= $module_code;

           return (\$pre);
        }
        return;
     };

   return $c_loader;
}


sub add_read_filter {
   my $a_source = shift;
   filter_add
     (
      sub {
         my $status =
           filter_read();
         if ( $status  > 0) {
            push @$a_source , $_;
         }
         $status ;
      }
     );
}


sub upject {
   #warn "UPJECT: ";
#   my $package = shift;

   # --- expand macro
   my $injection  = shift;

   # --- exit if undef
   return unless defined $injection;

   # --- adjust line number to disguise injection
   my ($file,$line) = (caller)[1,2];
   $line++;
   $injection .= qq{\n# line $line "$file"\n};


   # --- add source filter
   filter_add
     (
      sub {
         my $status =
           filter_read_exact(1);        # read one char into $_
         if ( $status  > 0) {
            $_ = $injection .";".$_;    # prepend code once
            filter_del();               # delete source filter
         }
         $status ;
      }

     );


}


=head1 AUTHOR

Rolf Michael Langsdorf, C<< <lanxperl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-filter-inject at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filter-Inject>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Filter::Inject


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filter-Inject>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filter-Inject>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Filter-Inject>

=item * Search CPAN

L<http://search.cpan.org/dist/Filter-Inject/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Rolf Michael Langsdorf.

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

1;                                      # End of Filter::Inject

__DATA__
use Filter::Util::Call ;

sub import {
   #warn "IMPORT: ".(join',',@_);
   my $package = shift;

   # --- expand macro
   my $injection  = macro(@_);

   # --- exit if undef
   return unless defined $injection;

   # --- adjust line number to disguise injection
   my ($file,$line) = (caller)[1,2];
   $line++;
   $injection .= qq{\n# line $line "$file"\n};


   # --- add source filter
   filter_add
     (
      sub {
         my $status =
           filter_read_exact(1);        # read one char into $_
         if ( $status  > 0) {
            $_ = $injection .";".$_;    # prepend code once
            filter_del();               # delete source filter
         }
         $status ;
      }

     );


}



1;
