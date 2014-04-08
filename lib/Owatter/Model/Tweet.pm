package Owatter::Model::Tweet;

use strict;
use warnings;
use utf8;

use Owatter;
use Owatter::Model::User;

use URI::Escape;
use String::Random;
use WWW::Curl::Easy;

sub tweet {
    my ( $class, $c, $user_id, $args ) = @_;

    my $tweet_message = $args->{'tweet'};
    my $reply_message = $args->{'reply'};

    my $error_message;
    if ( !$tweet_message || length($tweet_message) > 140 ) {
        $error_message = 'Owatterメッセージが不正です';
    }
    elsif ( !$reply_message || length($reply_message) > 140 ) {
        $error_message = 'Otsukareメッセージが不正です';
    }
    if ($error_message) {
        return +{ error => 1, error_message => $error_message };
    }

    my $db = $c->db;
    my $user = $db->single( 'user', +{ user_id => $user_id } );

    if ( !$user->twitter_oauth_token ) {
        my $nt  = $c->twitter();
        my $url = $nt->get_authorization_url(
            callback => 'http://app.owatter.hrk-ys.net/api/twitter/callback' );

        $c->session->set( 'request_token',        $nt->request_token );
        $c->session->set( 'request_token_secret', $nt->request_token_secret );

        $c->session->set( 'tweet', $tweet_message );
        $c->session->set( 'reply', $reply_message );

        return +{
            error_message => 'Twitter認証してください',
            redirect_url  => $url->as_string
        };
    }

    my $reply = $db->single(
        'reply',
        +{
            user_id  => +{ '!=' => $user_id },
            tweet_id => 0,
            sex_type => +{ '!=' => $user->sex_type },
        },
        +{ order_by => 'created_at' }
    );

    if ( !$reply ) {
        $reply = $db->single(
            'reply',
            +{
                user_id  => +{ '!=' => $user_id },
                tweet_id => 0,
            },
            +{ order_by => 'created_at' }
        );
    }

	my $hash_key = String::Random->new->randregex('[A-Z0-9]{10}');
    $db->txn_begin;
    my $tweet = $db->insert(
        'tweet',
        +{
            user_id     => $user_id,
            content     => $tweet_message,
            message_num => 1,
            created_at  => time(),
			hash_key    => $hash_key,
        }
    );

    $db->fast_insert(
        'reply',
        +{
            user_id    => $user_id,
            tweet_id   => 0,
            sex_type   => $user->sex_type,
            content    => $reply_message,
            location   => \"GeomFromText('POINT(139.762573 35.720253)')",
            created_at => time,
            updated_at => time,
        }
    );

    my $message;
    if ($reply) {
        $reply->update(
            +{ tweet_id => $tweet->tweet_id, updated_at => time() } );

        $message = $db->insert(
            'message',
            +{
                user_id    => $reply->user_id,
                tweet_id   => $tweet->tweet_id,
                content    => $reply->content,
                created_at => $reply->created_at,
            }
        );

    }

    $db->insert(
        'inbox',
        +{
            user_id    => $user_id,
            tweet_id   => $tweet->tweet_id,
            updated_at => time
        }
    );

    $db->txn_commit;

    my $ret = +{ tweet => $tweet->{row_data} };

	my $tweet_id = $tweet->tweet_id;
	my $url = $class->bitly_url( "http://app.owatter.hrk-ys.net/p/$hash_key" );
    my $nt = $c->twitter(
        access_token        => $user->twitter_oauth_token,
        access_token_secret => $user->twitter_oauth_token_secret,
    );
    $nt->update( $tweet_message . " " . $url );


    Owatter::Model::User->add_user_info( $ret->{tweet} );
    if ($message) {
        $ret->{message} = $message->{row_data};
        Owatter::Model::User->add_user_info( $ret->{message} );
    }
    else {
        $ret->{message} = +{ content => _random_reply_message() };
    }

    return $ret;
}

sub bitly_url {
    my ( $class, $url ) = @_;

    my $token = 'ceee16f1bc9c8553b4ce4d84ef677462f72e1f33';

    my $curl = WWW::Curl::Easy->new;

    $curl->setopt( CURLOPT_HEADER, 0 );
    $curl->setopt( CURLOPT_URL,
        "https://api-ssl.bitly.com/shorten?access_token=$token&longUrl="
          . uri_escape($url) );

    my $response_body;
    $curl->setopt( CURLOPT_WRITEDATA, \$response_body );

    # Starts the actual request
    my $retcode = $curl->perform;

    if ( !$retcode ) {
        my $ret = JSON::XS->new->utf8->decode($response_body);
        return $ret->{results}{$url}{shortUrl}
          if $ret->{results}{$url}{shortUrl};
    }

    return $url;
}

sub _random_reply_message {
    my @messages = (
"おつかれさま!今日も一日がんばったね。帰りにアイス買っていいよ！",
        "疲れたね。まぁそんな日もあるよね。",
    );

    return $messages[ int rand(@messages) ];
}

1;
