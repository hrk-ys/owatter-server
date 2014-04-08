package Owatter::Web::C::Twitter;
use strict;
use warnings;
use utf8;

use Data::UUID;

use Owatter::Model::Tweet;
use Owatter::Model::Twitter;

sub login {
    my ( $class, $c ) = @_;

    $c->log->debugf('twitter login');

    my $ret =
      Owatter::Model::Twitter->get_authorize_url( $c, { is_login => 1 } );

    return $c->render_json($ret);
}

sub callback {
    my ( $class, $c ) = @_;

    $c->log->debugf('callback');

    my $nt = $c->twitter();

    my $oauth_verifier = $c->req->param('oauth_verifier');

    my $request_token        = $c->session->get('request_token');
    my $request_token_secret = $c->session->get('request_token_secret');

    $c->log->debugf(
        +{
            oauth_verifier       => $oauth_verifier,
            request_token        => $request_token,
            request_token_secret => $request_token_secret,
        }
    );

    $nt->request_token($request_token);
    $nt->request_token_secret($request_token_secret);

    my ( $access_token, $access_token_secret, $twitter_id, $screen_name ) =
      $nt->request_access_token( verifier => $oauth_verifier );

    if ( $c->req->param('login') ) {

        my $cred = $nt->verify_credentials();
        $c->log->debugf(
            {
                service_id => $cred->{id},
                account_id => $cred->{screen_name},
                name       => $cred->{name},
                photo_url  => $cred->{profile_image_url_https},
            }
        );

        my $db = $c->db;
        my $user = $db->single( 'user', +{ twitter_id => $twitter_id } );

        # twitter id が存在すれば、情報を更新
        if ( !$user ) {
            $user = $db->insert(
                'user',
                +{
                    name                => $cred->{name},
                    profile_image       => $cred->{profile_image_url_https},
                    login_hash          => Data::UUID->new->create_str,
					twitter_id          => $twitter_id,
                    twitter_oauth_token => $access_token,
                    twitter_oauth_token_secret => $access_token_secret,
                    created_at                 => time,
                }
            );
        }
        else {
            $user->update(
                +{
                    twitter_oauth_token        => $access_token,
                    twitter_oauth_token_secret => $access_token_secret,
                }
            );
        }

        $c->session->set( 'user_id' => $user->user_id );

        return $c->redirect('/');
    }

    my $tweet = $c->session->get('tweet');
    my $reply = $c->session->get('reply');

    $c->session->remove('tweet');
    $c->session->remove('reply');
    $c->session->remove('request_token');
    $c->session->remove('request_token_secret');

    my $user_id = $c->session->get('user_id') or die;
    my $user = $c->db->single( 'user', +{ user_id => $user_id } );
    $user->update(
        +{
            twitter_oauth_token        => $access_token,
            twitter_oauth_token_secret => $access_token_secret,
        }
    );

    my $ret = Owatter::Model::Tweet->tweet(
        $c, $user_id,
        +{
            tweet => $tweet,
            reply => $reply,
        }
    );

    my $url;
    if ( $ret->{error} ) {
        $url = '/create/message?error_message=' . $ret->{error_message};
    }
    else {
        $url = '/create/message/done';
    }
    return $c->redirect($url);
}

1;

