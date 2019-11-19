package FFI::Platypus::Lang::Rust;

use strict;
use warnings;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use File::Spec;
use Env qw( @PATH );

our $VERSION = '0.07';

=head1 NAME

FFI::Platypus::Lang::Rust - Documentation and tools for using Platypus with
the Rust programming language

=head1 SYNOPSIS

Rust:

 #![crate_type = "dylib"]
 
 // compile with: rustc add.rs
 
 #[no_mangle]
 pub extern "C" fn add(a:i32, b:i32) -> i32 {
   a+b
 }

Perl:

 use FFI::Platypus 1.00;
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
 $ffi->lib('./libadd.so');
 
 $ffi->attach( add => ['i32', 'i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head1 DESCRIPTION

This module provides native Rust types for L<FFI::Platypus> in order to
reduce cognitive load and concentrate on Rust and forget about C types.
This document also documents issues and caveats that I have discovered
in my attempts to work with Rust and FFI.

This module is somewhat experimental.  It is also available for adoption
for anyone either sufficiently knowledgeable about Rust or eager enough
to learn enough about Rust.  If you are interested, please send me a
pull request or two on the project's GitHub.

Note that in addition to using pre-compiled Rust libraries, you can
bundle Rust code with your Perl distribution using L<FFI::Build> and
L<FFI::Build::File::Cargo>.

=head2 name mangling

Rust names are "mangled" to handle features such as modules and the fact
that some characters in Rust names are illegal machine code symbol
names. For now that means that you have to tell Rust not to mangle the
names of functions that you are going to call from Perl.  You can
accomplish that like this:

 #[no_mangle]
 pub extern "C" fn foo() {
 }

You do not need to add this decoration to functions that you do not
directly call from Perl.  For example:

 fn bar() {
 }
 
 #[no_mangle]
 pub extern "C" fn foo() {
   bar();
 }

=head2 panics

Be careful about code that might C<panic!>.  A C<panic!> across an FFI
boundary is undefined behavior.  You will want to catch the panic
with a C<catch_unwind> and map to an appropriate result.

 use std::panic::catch_unwind;
 
 #[no_mangle]
 pub extern fn oopsie() -> u32 {
     let result = catch_unwind(|| {
         might_panic();
     });
     match result {
         OK(_) => 0,
         Err(_) -> 1,
     }
 }

=head1 METHODS

Generally you will not use this class directly, instead interacting with
the L<FFI::Platypus> instance.  However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Rust->native_type_map;

This returns a hash reference containing the native aliases for the Rust
programming languages.  That is the keys are native Rust types and the
values are libffi native types.

=cut

sub native_type_map
{
  require FFI::Platypus;
  {
    u8       => 'uint8',
    u16      => 'uint16',
    u32      => 'uint32',
    u64      => 'uint64',
    i8       => 'sint8',
    i16      => 'sint16',
    i32      => 'sint32',
    i64      => 'sint64',
    binary32 => 'float',    # need to check this is right
    binary64 => 'double',   #  "    "  "     "    "  "
    f32      => 'float',
    f64      => 'double',
    usize    => FFI::Platypus->type_meta('size_t')->{ffi_type},
    isize    => FFI::Platypus->type_meta('ssize_t')->{ffi_type},
  },
}

1;

=head1 EXAMPLES

See the above L</SYNOPSIS> or the C<examples> directory that came with
this distribution.

=head1 SUPPORT

If something does not work as advertised, or the way that you think it
should, or if you have a feature request, please open an issue on this
project's GitHub issue tracker:

L<https://github.com/Perl5-FFI/FFI-Platypus-Lang-Rust/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull reequest on this project's GitHub repository:

L<https://github.com/Perl5-FFI/FFI-Platypus-Lang-Rust/issues>

Caution: if you do this too frequently I may nominate you as the new
maintainer.  Extreme caution: if you like that sort of thing.

This project's GitHub issue tracker listed above is not Write-Only.  If
you want to contribute then feel free to browse through the existing
issues and see if there is something you feel you might be good at and
take a whack at the problem.  I frequently open issues myself that I
hope will be accomplished by someone in the future but do not have time
to immediately implement myself.

Another good area to help out in is documentation.  I try to make sure
that there is good document coverage, that is there should be
documentation describing all the public features and warnings about
common pitfalls, but an outsider's or alternate view point on such
things would be welcome; if you see something confusing or lacks
sufficient detail I encourage documentation only pull requests to
improve things.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<Module::Build::FFI::Rust>

Bundle Rust code with your FFI / Perl extension.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

