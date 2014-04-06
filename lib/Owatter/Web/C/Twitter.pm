package Owatter::Web::C::Twitter;
use strict;
use warnings;
use utf8;

use Owatter::Model::Tweet;

sub callback {
    my ( $class, $c ) = @_;

    $c->debug('callback');

    my $nt = $c->twitter();

    my $oauth_verifier = $c->req->param('oauth_verifier');

    my $tweet = $c->session->get('tweet');
    my $reply = $c->session->get('reply');

    my $request_token        = $c->session->get('request_token');
    my $request_token_secret = $c->session->get('request_token_secret');

    $c->debug(
        +{
            tweet                => $tweet,
            reply                => $reply,
            oauth_verifier       => $oauth_verifier,
            request_token        => $request_token,
            request_token_secret => $request_token_secret,
        }
    );

    $c->session->remove('tweet');
    $c->session->remove('reply');
    $c->session->remove('request_token');
    $c->session->remove('request_token_secret');

    $nt->request_token($request_token);
    $nt->request_token_secret($request_token_secret);

    my ( $access_token, $access_token_secret ) =
      $nt->request_access_token( verifier => $oauth_verifier );

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

