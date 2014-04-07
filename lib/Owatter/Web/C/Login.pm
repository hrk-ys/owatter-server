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

    my $db = $c->db;
    my $user = $db->single( 'user', +{ facebook_id => $facebook_id } );
    if ( !$user ) {

        $user = $db->insert(
            'user',
            +{
                name                 => $data->{name},
                login_hash           => Data::UUID->new->create_str,
                facebook_id          => $facebook_id,
                facebook_oauth_token => $token,
                sex_type             => $data->{gender} eq 'male' ? 'M' : 'F',
                created_at           => time,
            }
        );
    }
    elsif ( !$user->facebook_oauth_token
        || $user->facebook_oauth_token ne $token )
    {
        $user->update( +{ facebook_oauth_token => $token } );
    }
    $c->session->set( 'user_id' => $user->user_id );

    return $c->render_json( $user->get_columns );
}

sub update_session {
    my ( $class, $c ) = @_;

    my $login_hash = $c->req->param('login_hash');

    my $user = $c->db->single( 'user', +{ login_hash => $login_hash } );
    if ( !$user ) {
        return $c->render_json(
            +{ error_message => '不正なアクセスです' } );
    }

    $c->session->set( 'user_id' => $user->user_id );
    return $c->render_json( +{ ok => 1 } );

}

sub token {
    my ( $class, $c ) = @_;

    my $token = $c->req->param('token') or die;
    my $is_debug = $c->req->param('is_debug') || 0;
    my $user_id = $c->session->get('user_id') or die;

    my $device = $c->db->single( 'device', +{ user_id => $user_id } );
    if ($device) {
        if ( $device->token ne $token ) {
            $c->db->update(
                'device',
                +{ token   => $token, is_debug => $is_debug },
                +{ user_id => $user_id },
            );
        }
    }
    else {
        $c->db->fast_insert(
            'device',
            +{
                user_id    => $user_id,
                token      => $token,
                is_debug   => $is_debug,
                updated_at => time(),
            }
        );
    }

    return $c->render_json( +{ ok => 1 } );
}

1;
