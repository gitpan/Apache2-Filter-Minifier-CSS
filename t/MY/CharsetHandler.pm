package MY::CharsetHandler;

use strict;
use warnings;
use Apache2::RequestIO qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::Const -compile => qw(OK);
use File::Spec::Functions qw(catfile);
use MY::slurp;

sub handler {
    my $r = shift;
    $r->content_type('text/css; charset=iso-8859-1');
    $r->print( slurp(catfile($r->document_root,'test.css')) );
    return Apache2::Const::OK;
}

1;
