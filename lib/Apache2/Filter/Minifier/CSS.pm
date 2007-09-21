package Apache2::Filter::Minifier::CSS;

###############################################################################
# Required inclusions.
use strict;
use warnings;
use Apache2::Filter qw();           # $f
use Apache2::RequestRec qw();       # $r
use Apache2::RequestUtil qw();      # $r->dir_config
use Apache2::Log qw();              # $log->*()
use APR::Table qw();                # dir_config->get() and headers_out->unset()
use Apache2::Const -compile => qw(OK DECLINED);
use CSS::Minifier qw(minify);

###############################################################################
# Version number.
our $VERSION = '1.00';

###############################################################################
# MIME-Types we're willing to minify.
my %mime_types = (
    'text/css'      => 1,
    );

###############################################################################
# Subroutine:   handler($filter)
###############################################################################
# CSS minification output filter.
sub handler {
    my $f = shift;
    my $r = $f->r;
    my $log = $r->log;

    # assemble list of acceptable MIME-Types
    my %types = (
        %mime_types,
        map { $_=>1 } $r->dir_config->get('CssMimeType'),
        );

    # only process CSS documents
    unless (exists $types{$r->content_type}) {
        $log->info( "skipping request to ", $r->uri, " (not a CSS document)" );
        return Apache2::Const::DECLINED;
    }

    # gather up entire document
    my $ctx = $f->ctx;
    while ($f->read(my $buffer, 4096)) {
        $ctx .= $buffer;
    }

    # unless we're at the end, store the CSS for our next invocation
    unless ($f->seen_eos) {
        $f->ctx( $ctx );
        return Apache2::Const::OK;
    }

    # if we've got CSS to minify, minify it
    if ($ctx) {
        my $min = eval { minify( input=>$ctx ) };
        if ($@) {
            # minification failed; log error and send original CSS
            $log->error( "error minifying: $@" );
            $f->print( $ctx );
        }
        else {
            # minification ok; log results and send minified CSS
            my $l_min = length($min);
            my $l_css = length($ctx);
            $log->debug( "CSS minified $l_css to $l_min : URL ", $r->uri );
            $r->headers_out->unset( 'Content-Length' );
            $f->print( $min );
        }
    }

    return Apache2::Const::OK;
}

1;

=head1 NAME

Apache2::Filter::Minifier::CSS - CSS minifying output filter

=head1 SYNOPSIS

  <LocationMatch "\.css$">
      PerlOutputFilterHandler   Apache2::Filter::Minifier::CSS

      # if you need to supplement MIME-Type list
      PerlSetVar                CssMimeType  text/plain
  </LocationMatch>

=head1 DESCRIPTION

C<Apache2::Filter::Minifier::CSS> is a Mod_perl2 output filter which minifies
CSS using C<CSS::Minifier>.

Only CSS style-sheets are minified, all others are passed through
unaltered.  C<Apache2::Filter::Minifier::CSS> comes with a list of known
acceptable MIME-Types for CSS style-sheets, but you can supplement that list
yourself by setting the C<CssMimeType> PerlVar appropriately (use C<PerlSetVar>
for a single new MIME-Type, or C<PerlAddVar> when you want to add multiple
MIME-Types).

=head2 Caching

Minification does require additional CPU resources, and it is recommended that
you use some sort of cache in order to keep this to a minimum.

Being that you're already running Apache2, though, here's some examples of a
mod_cache setup:

Disk Cache

  # Cache root directory
  CacheRoot /path/to/your/disk/cache
  # Enable cache for "/css/" location
  CacheEnable disk /css/

Memory Cache

  # Cache size: 4 MBytes
  MCacheSize 4096
  # Min object size: 128 Bytes
  MCacheMinObjectSize 128
  # Max object size: 512 KBytes
  MCacheMaxObjectSize 524288
  # Enable cache for "/css/" location
  CacheEnable mem /css/

=head1 METHODS

=over

=item handler($filter)

CSS minification output filter. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

Many thanks to Geoffrey Young for writing C<Apache::Clean>, from which several
things were lifted. :)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<CSS::Minifier>,
L<Apache2::Filter::Minifier::JavaScript>,
L<Apache::Clean>.

=cut
