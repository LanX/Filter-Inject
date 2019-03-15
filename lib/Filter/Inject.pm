package Filter::Inject;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Filter::Inject - Inject code at compile time.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

THIS IS EXPERIMENTAL CODE!!!


    my ($x,$y);
    BEGIN {($x,$y)=(0,42)}

    use Filter::Inject $x,$y; warn "after same line";
    warn "+1 line";
    warn "+2 line";
    warn "$x $y";             # prints "42 0"

Output

    IMPORT(Filter::Inject 0 42) at ../lib/Filter/Inject.pm line 56.
    after same line at d:/Users/LanX/Filter-Inject/exp/t_inject.pl line 6.
    --- START MACRO swap at d:/Users/LanX/Filter-Inject/exp/t_inject.pl line 9.
    --- END MACRO swap at d:/Users/LanX/Filter-Inject/exp/t_inject.pl line 14.
    +1 line at d:/Users/LanX/Filter-Inject/exp/t_inject.pl line 7.
    +2 line at d:/Users/LanX/Filter-Inject/exp/t_inject.pl line 8.
    42 0 at d:/Users/LanX/Filter-Inject/exp/t_inject.pl line 9.


=head1 DESCRIPTION

This is a prove of concept to implement a "swap" macro.

Here code is injected at compile time to swap the two arguments passed
after the use.

Care is taken to adjust the line-numbers after the injection, such
that the warn, the debugger and other tools don't get confused.
Check line number warnings to see what I mean.

=head1 CAVEATS

The new code is only injected after the line with the use statement.
I.e. code immidiately following the use statement in the same line will be
executed before the injected code.


=head1 EXPORT

No exports yet

=cut


use Filter::Util::Call ;



sub import {
  warn "IMPORT(@_)";
  my $package = shift;

  my $inject  = inject(@_);

  # adjust line number to disguise injection
  my ($file,$line) = (caller)[1,2];
  $line++;
  $inject .= qq{\n# line $line "$file"\n};

  filter_add(
             sub 
             {
               my $status = filter_read_exact(1);
               if ( $status  > 0) {
                 $_= $inject .";".$_;
                 filter_del();
               }
               $status ;
             }

            )

}

sub inject {
  local $"=',';
  package swap;
  our $args = \@_;
  return q{
     {
       warn "--- START MACRO swap";
       package swap; our $args;
       my $tmp = $args->[0];
       $args->[0] = $args->[1];
       $args->[1] = $tmp;
       warn "--- END MACRO swap";
     }
  }
}


  
1 ;



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

1;                              # End of Filter::Inject
