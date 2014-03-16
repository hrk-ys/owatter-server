package Owatter::Web::C::Login;
use strict;
use warnings;
use utf8;

use URI;
use Furl;
use JSON::XS;
use Data::UUID;

sub index {
    my ( $class, $c ) = @_;

    my $token = $c->req->param('token');
    if ( !$token ) {
    	$c->debug("invalid param");
        return $c->render_json( +{ error => 'invalid param' } );
    }

    $c->debug("token : $token");

    my $uri = URI->new('https://graph.facebook.com/me');
    $uri->query_form( access_token => $token, );
    my $res = Furl->new( timeout => 5 )->get($uri);

    my $data = decode_json $res->body;

    $c->debug( "data:%s", $data );

    if ( $data->{error} ) {
        return $c->render_json($data);
    }

    my $facebook_id = $data->{id};

    my $user = $c->db->single( 'user', +{ facebook_id => $facebook_id } );
    if ( !$user ) {

        $user = $c->db->insert(
            'user',
            +{
                name        => $data->{name},
				login_hash  => Data::UUID->new->create_str,
                facebook_id => $facebook_id,
                created_at  => time,
            }
        );
    }
	$c->session->set('user_id' => $user->user_id);

    return $c->render_json( $user->get_columns );
}

1;
