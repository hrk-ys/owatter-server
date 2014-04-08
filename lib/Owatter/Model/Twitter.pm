package Owatter::Model::Twitter;

use strict;
use warnings;
use utf8;

sub get_authorize_url {
    my ( $class, $c, $args ) = @_;

	$args ||= {};

	$c->log->debugf($c->req->uri->host);
	my $query = $args->{is_login} ? '?login=1' : '';
    my $nt  = $c->twitter();
    my $url = $nt->get_authorization_url(
            callback => "http://app.owatter.hrk-ys.net/api/twitter/callback$query" );

    $c->session->set( 'request_token',        $nt->request_token );
    $c->session->set( 'request_token_secret', $nt->request_token_secret );

    return +{ redirect_url  => $url->as_string };
}

1;
